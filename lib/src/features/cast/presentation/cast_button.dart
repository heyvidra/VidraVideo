import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:vidra_cast/vidra_cast.dart';

import '../../../config/design_tokens.dart';
import '../../video/domain/play_history.dart';
import '../../video/domain/resume_target.dart';
import '../../video/domain/video_collection.dart';
import '../../video/presentation/play_history_provider.dart';
import '../../video/presentation/widgets/detail/video_detail_header.dart'
    show ActionButton;
import 'cast_provider.dart';

/// Send this show to a television.
///
/// Sits beside 播放 / 下载 / 订阅 / 想看 on the detail page rather than in the
/// player: the player runs in its own engine with its own providers, so a
/// cast started there could neither be seen nor stopped from anywhere else.
class CastButton extends ConsumerWidget {
  const CastButton({super.key, required this.video});

  final Video video;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cast = ref.watch(castStateProvider);
    // Only THIS show. A cast is app-wide state, so without the check every
    // other show's page also claimed to be casting — and its stop button
    // would have stopped whatever was actually playing on the television.
    final mine =
        cast.video?.apiId == video.apiId &&
        cast.video?.sourceId == video.sourceId;
    final casting = cast.isCasting && mine;
    final connecting = cast.connecting && mine;
    final button = ActionButton(
      amber: casting,
      busy: connecting,
      icon: casting ? Icons.cast_connected_rounded : Icons.cast_rounded,
      label: connecting
          ? tr('cast.connecting_to', args: [_shortName(cast.device?.name)])
          : casting
          ? _castingLabel(cast)
          : tr('cast.title'),
      onTap: () => casting
          ? ref.read(castStateProvider.notifier).stop()
          : _pickDevice(context, ref),
    );
    // The television's name moves to the tooltip while an episode is named:
    // one button cannot hold both, and on a series page "which episode" is
    // the question being asked — the TV is in the room, visibly playing.
    if (!casting) return button;
    return Tooltip(
      message: tr('cast.casting_on', args: [_shortName(cast.device?.name)]),
      child: button,
    );
  }

  /// Whether a tap on an episode would go to the television rather than the
  /// local player. Mirrors the check in `EpisodeItem._onTap` — the two must
  /// agree, because this is what tells the viewer that gesture exists.
  static bool castsEpisodes(CastState cast, Video video) =>
      cast.isCasting &&
      cast.video?.apiId == video.apiId &&
      cast.video?.sourceId == video.sourceId;

  /// "第 12 集 · 投屏中", or the television's name when there is no episode
  /// to name — a film, or the moment before the TV's first progress report.
  String _castingLabel(CastState cast) {
    final episode = cast.episodeIndex;
    if (episode == null) {
      return tr('cast.casting_on', args: [_shortName(cast.device?.name)]);
    }
    return tr('cast.casting_episode', args: ['${episode + 1}']);
  }

  /// A television's advertised name is written for a network, not a button:
  /// "[TV] Samsung 9 Series (65)". Trim it to something that fits beside
  /// four other actions.
  static String _shortName(String? name) {
    var n = (name ?? '').replaceFirst(RegExp(r'^\[[^\]]*\]\s*'), '').trim();
    if (n.isEmpty) return tr('cast.this_tv');
    if (n.length > 12) n = '${n.substring(0, 12)}…';
    return n;
  }

  /// Where playback should pick up — the same rule the play button uses, so
  /// the TV opens where the viewer left off rather than at episode one.
  ({int index, int seconds}) _resume(WidgetRef ref) {
    final key = (videoId: video.apiId, sourceId: video.sourceId);
    final histories =
        ref.read(episodeHistoriesProvider(key)).value ??
        const <int, EpisodeHistory>{};
    final videoHistory = ref.read(videoHistoryProvider(key)).value;
    final episodes = video.urls ?? const <VideoEpisode>[];
    final target = resolveResumeTarget(
      histories: histories,
      lastEpisodeIndex: videoHistory?.lastEpisodeIndex,
      episodeCount: episodes.isEmpty ? null : episodes.length,
    );
    final row = histories[target.episodeIndex];
    // Only resume mid-episode when the target is where they actually were;
    // an advanced target points at an episode never opened.
    final seconds = target.advanced || row == null
        ? 0
        : (row.positionMillis / 1000).round();
    return (index: target.episodeIndex, seconds: seconds);
  }

  Future<void> _pickDevice(BuildContext context, WidgetRef ref) async {
    final controller = ref.read(castStateProvider.notifier);
    // Captured before the dialog: the page can be gone by the time the cast
    // resolves, and reaching back through a dead context is how a snack bar
    // takes the app down with it.
    final messenger = ScaffoldMessenger.of(context);
    unawaited(controller.startDiscovery());
    final device = await showDialog<CastDevice>(
      context: context,
      builder: (_) => const _DevicePickerDialog(),
    );
    unawaited(controller.stopDiscovery());
    if (device == null) return;

    final resume = _resume(ref);
    try {
      await controller.cast(
        device: device,
        video: video,
        episodeIndex: resume.index,
        startPositionSeconds: resume.seconds,
      );
      messenger.showSnackBar(
        SnackBar(content: Text(tr('cast.sent_to', args: [device.name]))),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(_readableError(e))));
    }
  }

  /// What went wrong, in the language of someone holding a remote.
  ///
  /// The raw exception is a SocketException or a SOAP fault with a UPnP
  /// error code in it — true, and useless to the person whose television
  /// stayed dark. Each of these maps to something they can act on.
  static String _readableError(Object e) {
    final text = '$e';
    if (text.contains('no playable episode')) {
      return tr('cast.failed_no_episode');
    }
    if (text.contains('no LAN address')) return tr('cast.failed_no_network');
    if (text.contains('TV browser')) return tr('cast.failed_browser');
    if (text.contains('never opened the page')) {
      return tr('cast.failed_no_page');
    }
    if (text.contains('already starting')) return tr('cast.failed_busy');
    if (text.contains('did not answer') || text.contains('SocketException')) {
      return tr('cast.failed_unreachable');
    }
    // 716 is what a renderer says when it could not fetch what we handed it.
    if (text.contains('716') || text.contains('SOAP')) {
      return tr('cast.failed_refused');
    }
    return tr('cast.failed', args: [text.split('\n').first]);
  }
}

/// The televisions on this network, as they are found.
///
/// Discovery is not instant and has no "done" — devices trickle in over a
/// few seconds — so the list says it is still looking rather than showing an
/// empty state that reads as "you have no TV".
class _DevicePickerDialog extends ConsumerStatefulWidget {
  const _DevicePickerDialog();

  @override
  ConsumerState<_DevicePickerDialog> createState() =>
      _DevicePickerDialogState();
}

class _DevicePickerDialogState extends ConsumerState<_DevicePickerDialog> {
  /// Discovery has no "finished", so nothing can say the network is empty —
  /// but a wait this long with nothing found almost always means the OS is
  /// refusing local-network access rather than that there is no television.
  static const _hintAfter = Duration(seconds: 8);
  bool _slow = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(_hintAfter, () {
      if (mounted) setState(() => _slow = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = VidraTokens.of(context);
    final devices =
        ref.watch(castDevicesProvider).value ?? const <CastDevice>[];

    return Dialog(
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380, maxHeight: 420),
        child: Container(
          decoration: BoxDecoration(
            color: t.barBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: t.edge),
            boxShadow: t.drop2,
          ),
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tr('cast.pick_device'),
                style: TextStyle(
                  fontSize: 15,
                  height: 1.4,
                  fontWeight: FontWeight.w700,
                  color: t.fg,
                ),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: devices.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: t.cyan,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  tr('cast.searching'),
                                  style: TextStyle(fontSize: 13, color: t.fg3),
                                ),
                              ],
                            ),
                            if (_slow) ...[
                              const SizedBox(height: 14),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                child: Text(
                                  tr('cast.nothing_found_hint'),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 12,
                                    height: 1.5,
                                    color: t.fg3,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: devices.length,
                        itemBuilder: (context, i) {
                          final d = devices[i];
                          return InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onTap: () => Navigator.of(context).pop(d),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 10,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.tv_rounded,
                                    size: 18,
                                    color: t.fg2,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          d.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 13.5,
                                            color: t.fg,
                                          ),
                                        ),
                                        Text(
                                          // The device's own address field is
                                          // the description XML URL, not
                                          // something to show a human.
                                          Uri.parse(d.address).host,
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            color: t.fg3,
                                            fontFeatures: VidraType.data,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(tr('common.cancel')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Says that, right now, tapping an episode sends it to the television.
///
/// It is the one thing on this page nobody would guess: the same tap that
/// opens the local player every other time silently changes meaning once a
/// cast is running, and nothing on screen said so.
///
/// Shown under EXACTLY the condition that makes it true — this show on the
/// television, and not in download mode — because the rule it states is false
/// the rest of the time. Stated while a different show is casting, or while
/// the grid is queueing downloads, it would teach a gesture that does
/// something else.
class CastEpisodeHint extends ConsumerWidget {
  const CastEpisodeHint({
    super.key,
    required this.video,
    required this.isDownloadMode,
  });

  final Video video;

  /// The grid's other mode. A tap there queues a download and never reaches
  /// the cast path, so the hint has to go while it is on.
  final ValueNotifier<bool> isDownloadMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cast = ref.watch(castStateProvider);
    if (!CastButton.castsEpisodes(cast, video)) {
      return const SizedBox.shrink();
    }
    return ValueListenableBuilder<bool>(
      valueListenable: isDownloadMode,
      builder: (context, downloading, _) {
        if (downloading) return const SizedBox.shrink();
        final t = VidraTokens.of(context);
        return ConstrainedBox(
          // Wraps onto its own line rather than squeezing the buttons, and
          // stops short of the full width so it reads as a note beside them
          // and not as a paragraph of its own.
          constraints: const BoxConstraints(maxWidth: 260),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Amber, matching the button it follows: the two are one state.
              Text(
                '→',
                style: TextStyle(fontSize: 12, height: 1.5, color: t.amber),
              ),
              const SizedBox(width: 9),
              Flexible(
                child: Text(
                  tr('cast.episode_hint'),
                  style: TextStyle(fontSize: 12, height: 1.5, color: t.fg3),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
