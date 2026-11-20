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
import '../data/cast_web_server.dart';
import '../../video/presentation/widgets/cross_source_watch_badge.dart'
    show crossSourceWatchFor;
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

  /// An AirPlay receiver as a row in the picker.
  ///
  /// Our discovery cannot see these; the Mac's own Bonjour can, and names
  /// them. Choosing the row opens the system's route menu, where the viewer
  /// picks the same set — the one step Apple keeps for itself.
  static CastDevice airPlayDevice(String name) => CastDevice(
    id: 'airplay:$name',
    name: name,
    address: 'airplay://${Uri.encodeComponent(name)}',
    protocol: DeviceProtocol.airPlay,
  );

  /// The televisions in [devices] that a machine at [lanAddress] could
  /// actually reach.
  ///
  /// A remembered device is offered the instant the picker opens, before
  /// anything has confirmed it — that is what makes the list appear at once
  /// instead of after a scan. It is also how a television from another
  /// network ends up on screen offering a cast that cannot work: the flat
  /// before this one, the office, a hotel. Discovery drops the ones it can
  /// prove are gone, but proving takes seconds and cannot prove anything at
  /// all about a subnet this machine is not on.
  ///
  /// The /24 is the same crude rule the proxy picks its own interface with,
  /// and it is right for the same reason: home networks are /24, and this
  /// only has to tell "the network I am on" from "somewhere else". No
  /// address of our own means nothing is reachable, which is the honest
  /// answer while the machine is off the network.
  ///
  /// Public because it is the rule, and a rule is worth asserting on
  /// directly rather than through a dialog.
  static List<CastDevice> devicesOn(
    Iterable<String> lanAddresses,
    List<CastDevice> devices,
  ) {
    final mine = {for (final a in lanAddresses) ?_subnetOf(a)};
    return [
      for (final d in devices)
        if (mine.contains(_subnetOf(Uri.tryParse(d.address)?.host))) d,
    ];
  }

  static String? _subnetOf(String? host) {
    final parts = host?.split('.') ?? const <String>[];
    return parts.length == 4 ? parts.take(3).join('.') : null;
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
  ///
  /// "The same rule" includes the one that outranks every local row: a newer
  /// viewing of this show on ANOTHER catalog. Without it the button beside
  /// this one offered 第21集 while this one cast 第20集 — the same show, the
  /// same page, two different answers.
  ///
  /// The episode NUMBER is what crosses, not the catalog: progress is shared
  /// by number everywhere else on this page, and casting this catalog's own
  /// episode keeps the cast attached to the page — the badge and the hint
  /// above the grid both read the page's video, and handing the television a
  /// different catalog's copy would make them vanish the moment it started.
  /// A number this catalog does not reach is no use, so that falls back.
  ({int index, int seconds}) _resume(WidgetRef ref) {
    final key = (videoId: video.apiId, sourceId: video.sourceId);
    final histories =
        ref.read(episodeHistoriesProvider(key)).value ??
        const <int, EpisodeHistory>{};
    final videoHistory = ref.read(videoHistoryProvider(key)).value;
    final episodes = video.urls ?? const <VideoEpisode>[];

    final newer = isEpisodicType(video.type)
        ? crossSourceResumeOverride(
            match: crossSourceWatchFor(ref, video),
            histories: histories,
            lastWriteAt: videoHistory?.updatedAt,
          )
        : null;
    if (newer != null && newer.lastEpisodeIndex < episodes.length) {
      final rows =
          ref
              .read(
                episodeHistoriesProvider((
                  videoId: newer.videoId,
                  sourceId: newer.sourceId,
                )),
              )
              .value ??
          const <int, EpisodeHistory>{};
      final row = rows[newer.lastEpisodeIndex];
      return (
        index: newer.lastEpisodeIndex,
        seconds: row == null || row.durationMillis <= 0
            ? 0
            : (row.positionMillis / 1000).round(),
      );
    }

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

    // Where the system's AirPlay menu should hang from: this button. This
    // context is the button's own element, so its render box is its bounds,
    // in the same top-left coordinates the native side converts from.
    Rect? anchor;
    if (context.mounted) {
      final box = context.findRenderObject();
      if (box is RenderBox && box.hasSize) {
        anchor = box.localToGlobal(Offset.zero) & box.size;
      }
    }
    final resume = _resume(ref);
    try {
      await controller.cast(
        device: device,
        video: video,
        episodeIndex: resume.index,
        startPositionSeconds: resume.seconds,
        airPlayAnchor: anchor,
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
    if (text.contains('airplay cancelled')) {
      return tr('cast.failed_airplay_cancelled');
    }
    if (text.contains('airplay not picked')) {
      return tr('cast.failed_airplay_pick');
    }
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

  /// This machine's address on the LAN, which decides which remembered
  /// televisions are worth offering — see [_reachable].
  List<String> _lan = const [];

  /// The AirPlay receivers the system sees right now, by name.
  List<String> _airplay = const [];
  Timer? _airplayRefresh;

  @override
  void initState() {
    super.initState();
    _timer = Timer(_hintAfter, () {
      if (mounted) setState(() => _slow = true);
    });
    CastWebServer.lanAddresses().then((a) {
      if (mounted) setState(() => _lan = a);
    });
    // Asked again every second for as long as the picker is open, not once:
    // Bonjour answers a beat after launch, and a list read before it had
    // spun forever on a network whose only television was an AirPlay one —
    // until the picker was closed and opened again, which asked again.
    _refreshAirPlay();
    _airplayRefresh = Timer.periodic(const Duration(seconds: 1), (_) {
      _refreshAirPlay();
    });
  }

  Future<void> _refreshAirPlay() async {
    final names = await AirPlaySender.receivers();
    if (!mounted) return;
    if (names.length != _airplay.length ||
        !names.asMap().entries.every((e) => _airplay[e.key] == e.value)) {
      setState(() => _airplay = names);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _airplayRefresh?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = VidraTokens.of(context);
    final devices = [
      ...CastButton.devicesOn(
        _lan,
        ref.watch(castDevicesProvider).value ?? const <CastDevice>[],
      ),
      for (final name in _airplay) CastButton.airPlayDevice(name),
    ];

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
                                          d.protocol == DeviceProtocol.airPlay
                                              ? tr('cast.airplay_hint')
                                              : Uri.parse(d.address).host,
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
              // Kept below the list, not only in place of it. Discovery has
              // no "finished", and a remembered television answers the picker
              // in milliseconds — so with one on screen the only sign that a
              // scan was still running disappeared, and a set switched on a
              // moment ago looked like a set the app could not see.
              if (devices.isNotEmpty) ...[
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 11,
                        height: 11,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.6,
                          color: t.fg3,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        tr('cast.searching'),
                        style: TextStyle(fontSize: 11.5, color: t.fg3),
                      ),
                    ],
                  ),
                ),
              ],
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
