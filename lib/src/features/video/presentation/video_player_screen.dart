import 'dart:async';
import 'dart:io';

import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:vidra_player/vidra_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../../core/services/window.dart';
import '../../../core/telemetry/telemetry.dart';
import '../../../core/utils/log.dart';
import '../../../core/services/vidra_media_repository.dart';
import '../../download/data/download_provider.dart';
import '../../download/domain/download_task.dart';
import '../data/history_repository.dart';
import '../data/video_repository.dart';
import '../domain/video_collection.dart' hide VideoEpisode, VideoQuality;
import '../../../common/netflix_loading.dart';
import '../../../window/video_player_window.dart';

class VideoPlayerScreen extends ConsumerStatefulWidget {
  final String videoId;
  final String? sourceId;

  /// Play this address directly instead of resolving [videoId] in the catalog.
  ///
  /// For a pasted link that has been parsed but not downloaded: nothing in the
  /// repository describes it, so the title, cover and address arrive with the
  /// launch. Only a MUXED format can come through here — a video-only stream
  /// is half a file, and the HD options are merge selectors that are playable
  /// only after the muxer has run.
  final String? directUrl;
  final String? directTitle;
  final String? directCoverUrl;
  final int initialEpisodeIndex;
  final VideoPlayerWindowCloseController? closeController;

  const VideoPlayerScreen({
    super.key,
    required this.videoId,
    this.sourceId,
    this.directUrl,
    this.directTitle,
    this.directCoverUrl,
    this.initialEpisodeIndex = 0,
    this.closeController,
  });

  @override
  ConsumerState<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends ConsumerState<VideoPlayerScreen>
    with TickerProviderStateMixin {
  PlayerController? _controller;
  VidraMediaRepository? _mediaRepository;
  bool _isClosing = false;

  /// Constructed with the State, which is the moment the screen opened — the
  /// startup clock has to start before initState, not after the player exists.
  final _PlaybackHealth _health = _PlaybackHealth();

  // Memoize episode mapping: build() runs on every locale/setting change, but
  // the mapped list only changes when the underlying Video does.
  Video? _lastMappedVideo;
  List<VideoEpisode>? _cachedEpisodes;

  List<VideoEpisode> _episodesFor(Video video) {
    if (identical(_lastMappedVideo, video) && _cachedEpisodes != null) {
      return _cachedEpisodes!;
    }
    _lastMappedVideo = video;
    return _cachedEpisodes = _mapEpisodes(video);
  }

  @override
  void didUpdateWidget(VideoPlayerScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.closeController != widget.closeController) {
      oldWidget.closeController?.unbind(_handleWindowCloseRequest);
      widget.closeController?.bind(_handleWindowCloseRequest);
    }

    if (oldWidget.videoId != widget.videoId ||
        oldWidget.sourceId != widget.sourceId) {
      if (_controller != null) {
        final ctrl = _controller!;
        _controller = null;
        Future.microtask(() async {
          try {
            await ctrl.dispose();
          } catch (e) {
            logD('VideoPlayerScreen', 'Dispose on update error: $e');
          }
        });
      }
    } else if (oldWidget.initialEpisodeIndex != widget.initialEpisodeIndex) {
      if (_controller != null &&
          _controller!.media.currentEpisodeIndex !=
              widget.initialEpisodeIndex) {
        _controller!.switchEpisode(widget.initialEpisodeIndex);
      }
    }
  }

  VideoMetadata _mapMetadata(Video video) {
    return VideoMetadata(
      id: "${video.apiId}_${widget.sourceId}",
      title: video.title,
      coverUrl: video.coverUrl,
    );
  }

  List<VideoEpisode> _mapEpisodes(Video video) {
    final localByUrl = _downloadedFilesByUrl();
    return video.urls!.asMap().entries.map((entry) {
      final key = entry.key;
      final ve = entry.value;
      final qualities =
          ve.qualities?.map((q) {
            final localPath = localByUrl[q.url];
            return VideoQuality(
              label: q.name ?? "Auto",
              // Prefer the downloaded local file — a downloaded episode
              // plays from disk (offline, no CDN re-stream) instead of
              // hitting the network again.
              source: localPath != null
                  ? VideoSource.file(localPath)
                  : VideoSource.network(q.url!),
            );
          }).toList() ??
          [];

      return VideoEpisode(
        title: ve.title ?? "",
        index: key,
        qualities: qualities,
      );
    }).toList();
  }

  /// Maps each completed-download URL to its on-disk file (when the file still
  /// exists), so [_mapEpisodes] can play a downloaded episode locally.
  Map<String, String> _downloadedFilesByUrl() {
    final map = <String, String>{};
    for (final task in ref.read(downloadManagerProvider).allTasks) {
      for (final ep in task.episodes) {
        final url = ep.url;
        final path = ep.outputPath;
        if (ep.status == DownloadStatus.completed &&
            url != null &&
            path != null &&
            File(path).existsSync()) {
          map[url] = path;
        }
      }
    }
    return map;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WakelockPlus.enable();
  }

  @override
  void initState() {
    super.initState();

    WakelockPlus.enable();
    widget.closeController?.bind(_handleWindowCloseRequest);
  }

  @override
  void dispose() {
    widget.closeController?.unbind(_handleWindowCloseRequest);
    _cleanup();
    super.dispose();
  }

  void _cleanup() {
    // Before the controller goes: the session's numbers come off its streams.
    _health.dispose();

    WakelockPlus.disable();

    final ctrl = _controller;
    _controller = null;
    if (ctrl != null) {
      Future.microtask(() async {
        try {
          await ctrl.dispose();
        } catch (e) {
          logD('VideoPlayerScreen', 'Dispose on cleanup error: $e');
        }
      });
    }

    _mediaRepository?.dispose();
  }

  Future<void> _handleSafeClose() async {
    if (_isClosing) return;
    _isClosing = true;

    // First, while the engine is still alive to queue the send on. Deliberately
    // not awaited: nothing on this path may push the close past the grace
    // window below.
    _health.finish(_PlaybackEnd.windowClosed);

    try {
      if (_controller != null) {
        await _controller!.dispose();
        _controller = null;
      }
    } catch (e) {
      logD(
        'VideoPlayerScreen',
        'Error disposing player controller during close: $e',
      );
    }

    // Give native texture threads time to spin down before killing the
    // engine. This must outlast the sprite sweeper's 300ms teardown settle —
    // closing inside that window strands a parked native player that nothing
    // can reclaim afterwards.
    await Future.delayed(const Duration(milliseconds: 600));

    // The wakelock must be released here, not in dispose: closing the window
    // kills the engine, so State.dispose never runs, and the controller path
    // only disables it when playback actually started. Without this, a window
    // opened and closed without ever playing leaves the display awake.
    await WakelockPlus.disable();

    // Immediately close the window. Native side handles the rest.
    appWindow.close();
  }

  Future<bool> _handleWindowCloseRequest() async {
    if (_isClosing) {
      return true;
    }
    await _handleSafeClose();
    return false;
  }

  /// Build episodes straight from a download task's on-disk files, for videos
  /// that aren't in the catalog (e.g. pasted-URL / link downloads). Each
  /// completed episode plays its local file.
  List<VideoEpisode> _episodesFromTask(DownloadTask task) {
    final eps = <VideoEpisode>[];
    for (final ep in task.episodes) {
      final path = ep.outputPath;
      if (ep.status == DownloadStatus.completed &&
          path != null &&
          File(path).existsSync()) {
        eps.add(
          VideoEpisode(
            title: ep.title ?? '',
            index: eps.length,
            qualities: [
              VideoQuality(
                label: ep.title ?? 'Auto',
                source: VideoSource.file(path),
              ),
            ],
          ),
        );
      }
    }
    return eps;
  }

  PlayerController newController(
    VideoMetadata metadata,
    List<VideoEpisode> episodes,
    VidraLocale currentVidraLocale,
  ) {
    final config = PlayerConfig(
      initialEpisodeIndex: widget.initialEpisodeIndex,
      episodesSort: false,
      theme: const PlayerUITheme.netflix(),
      features: const PlayerFeatures.all(),
      behavior: PlayerBehavior(
        autoHideDelay: const Duration(seconds: 3),
        mouseHideDelay: const Duration(seconds: 2),
        hoverShowDelay: const Duration(milliseconds: 300),
        autoPlay: true,
        hideMouseWhenIdle: true,
        muteOnStart: false,
        // Thumbnails were retired here when previews were macOS-native-only;
        // the player's sprite sweep (v1.3.0) serves hover previews on every
        // platform now, so the default (enabled) is back.
      ),
      // White, explicitly. The player's chrome is always dark over video, so
      // it must not inherit the app's icon colour — in the light theme that is
      // near-black, and this button vanished into the title bar.
      leading: IconButton(
        icon: const Icon(Icons.close, color: Colors.white),
        tooltip: tr('common.close'),
        onPressed: _handleSafeClose,
      ),
      locale: currentVidraLocale,
    );

    // Dispose the previous repository before replacing it — otherwise a
    // re-created controller (video switch) leaks the old repo's progress-save
    // throttle Timer.
    _mediaRepository?.dispose();
    _mediaRepository = VidraMediaRepository(
      ref.read(videoRepositoryProvider),
      ref.read(historyRepositoryProvider),
    );

    final controller = PlayerController(
      config: config,
      video: metadata,
      episodes: episodes,
      windowDelegate: BitsdojoWindowDelegate(),
      mediaRepository: _mediaRepository,
    );

    // Health binds here rather than in initState: the controller is what
    // exposes buffering and lifecycle, and a video switch builds a new one.
    _health.attach(controller);

    return controller;
  }

  /// A message screen (not found / no episodes / error) that still carries a
  /// close button — the player window hides its native title-bar buttons, so
  /// without this a broken open (e.g. the file was deleted) can't be closed.
  Widget _infoScreen(String message) {
    return Stack(
      children: [
        Positioned.fill(
          child: Center(
            child: Text(message, style: const TextStyle(color: Colors.white70)),
          ),
        ),
        Positioned(
          top: 10,
          left: 10,
          child: IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            tooltip: tr('common.close'),
            onPressed: _handleSafeClose,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isClosing) {
      return const Scaffold(backgroundColor: Colors.black);
    }

    final id = int.tryParse(widget.videoId) ?? -1;
    final videoAsync = ref.watch(
      cachedVideoByIdProvider((id: id, sourceId: widget.sourceId)),
    );

    return Scaffold(
      backgroundColor: Colors.black,
      body: videoAsync.when(
        data: (video) {
          final currentVidraLocale = context.locale.languageCode == 'zh'
              ? VidraLocale.zhCN
              : VidraLocale.en;

          VideoMetadata? metadata;
          List<VideoEpisode> episodes = const [];
          final direct = widget.directUrl;
          if (direct != null && direct.isNotEmpty) {
            // A parsed link, not a catalog entry: nothing to resolve, so build
            // the one-episode playlist straight from what the launch carried.
            metadata = VideoMetadata(
              id: 'direct_${widget.videoId}',
              title: widget.directTitle ?? '',
              coverUrl: widget.directCoverUrl ?? '',
            );
            episodes = [
              VideoEpisode(
                index: 0,
                title: widget.directTitle ?? '',
                qualities: [
                  VideoQuality(
                    label: tr('download.url.preview'),
                    source: VideoSource.network(direct),
                  ),
                ],
              ),
            ];
          } else if (video != null &&
              video.urls != null &&
              video.urls!.isNotEmpty) {
            metadata = _mapMetadata(video);
            episodes = _episodesFor(video);
          } else {
            // Not a catalog video (e.g. a pasted-URL download) — play the
            // downloaded local file(s) instead of showing "no episodes".
            final matches = ref
                .read(downloadManagerProvider)
                .allTasks
                .where((t) => t.videoId == id);
            if (matches.isNotEmpty) {
              final task = matches.first;
              episodes = _episodesFromTask(task);
              if (episodes.isNotEmpty) {
                metadata = VideoMetadata(
                  id: '${task.videoId}',
                  title: task.videoTitle,
                  coverUrl: task.coverUrl ?? '',
                );
              }
            }
          }

          if (metadata == null || episodes.isEmpty) {
            return _infoScreen(
              tr(
                video == null
                    ? 'video.detail.not_found'
                    : 'video.player.no_episodes',
              ),
            );
          }

          // Initialize controller only if needed to prevent multiple instances
          if (_controller == null) {
            _controller = newController(metadata, episodes, currentVidraLocale);
          } else {
            if (_controller!.config.locale != currentVidraLocale) {
              _controller!.setLocale(currentVidraLocale);
            }
            // Sync episodes if count differs (e.g. new episodes added)
            if (_controller!.media.episodes.length != episodes.length) {
              _controller!.updateEpisodes(episodes);
            }
          }

          return VideoPlayerWidget(controller: _controller!);
        },
        loading: () => const Center(child: NetflixLoading(size: 50)),
        error: (e, st) =>
            _infoScreen(tr('video.detail.error', args: [e.toString()])),
      ),
    );
  }
}

/// Why a playback session stopped.
///
/// A closed vocabulary, and it must stay closed: these names ship as
/// diagnostics, so nothing derived from the media may ever join them.
enum _PlaybackEnd {
  loadFailed,
  episodeEnded,
  playlistEnded,
  episodeSwitched,
  videoSwitched,
  windowClosed,
  screenDisposed,
}

/// Playback and decode health for one session, reported as shapes on teardown.
///
/// A session is one episode's playback: it ends when the episode changes, when
/// the window closes, or when the screen is torn down. What a report may carry
/// is deliberately tiny — durations, counts, booleans, enum names — because
/// this is the one code path in the app that knows what a person is watching.
/// No title, id, episode, quality label or address reaches [Telemetry] from
/// here, and no session-scoped identifier either: two reports must not be
/// linkable back into one evening's viewing.
///
/// Every method swallows its own failures and none of them block. Diagnostics
/// that can break or delay playback are worse than no diagnostics.
class _PlaybackHealth {
  /// Screen open, captured when the State is created. The first session's
  /// startup latency is measured from here, so the number matches what a
  /// person actually waited through — catalog lookup and player construction
  /// included, not just the decoder.
  final DateTime _screenOpenedAt = DateTime.now();
  bool _screenOpenUsed = false;

  PlayerController? _controller;
  StreamSubscription<PlayerLifecycleEvent>? _eventsSub;
  StreamSubscription<BufferingState>? _bufferingSub;

  DateTime? _sessionStartedAt;
  DateTime? _firstPlayingAt;
  bool _fromScreenOpen = false;

  int _rebuffers = 0;
  int _stalledMs = 0;
  DateTime? _stallStartedAt;

  bool? _local;
  String? _errorCode;
  _PlaybackEnd? _end;

  /// Player error codes are constants (`OPEN_FAILED`, `NETWORK_ERROR`, …), but
  /// they come from a package this repo does not own. Only a constant-shaped
  /// code is passed through; anything else — a message, an address that leaked
  /// into the field — is reported as `other` rather than trusted to Scrub.
  static final _codeShape = RegExp(r'^[A-Z][A-Z0-9_]{0,31}$');

  /// Binds to [controller]'s health streams and opens a session on it.
  ///
  /// Also the single point where a replaced controller (video switch) closes
  /// the outgoing session — the accumulated numbers live here, not on the
  /// controller, so reporting at rebind time loses nothing.
  void attach(PlayerController controller) {
    try {
      finish(_PlaybackEnd.videoSwitched);
      _detach();
      _controller = controller;
      final firstEver = !_screenOpenUsed;
      _screenOpenUsed = true;
      _begin(
        startedAt: firstEver ? _screenOpenedAt : DateTime.now(),
        fromScreenOpen: firstEver,
      );
      // The controller was just built at the target episode, so its source is
      // already the one that will open.
      _local = _readIsLocal();
      _eventsSub = controller.lifecycleEvents.listen(
        _onEvent,
        onError: (Object _) {},
      );
      _bufferingSub = controller.bufferingStream.listen(
        _onBuffering,
        onError: (Object _) {},
      );
    } catch (e) {
      logD('VideoPlayerScreen', 'Playback health attach error: $e');
    }
  }

  /// Sends the live session's report and closes it, using [fallback] when no
  /// more specific reason was observed.
  ///
  /// Idempotent, synchronous and non-throwing: the window-close path calls it
  /// before the controller and then the engine go away, and must not wait.
  void finish(_PlaybackEnd fallback) {
    final startedAt = _sessionStartedAt;
    if (startedAt == null) return;
    try {
      final now = DateTime.now();
      final stallStartedAt = _stallStartedAt;
      if (stallStartedAt != null) {
        _stalledMs += now.difference(stallStartedAt).inMilliseconds;
      }
      final firstPlayingAt = _firstPlayingAt;
      Telemetry.report(
        'playback',
        data: {
          'end_reason': (_end ?? fallback).name,
          'started': firstPlayingAt != null,
          if (firstPlayingAt != null)
            'startup_ms': firstPlayingAt.difference(startedAt).inMilliseconds,
          // Startup is only comparable across sessions that measured the same
          // thing: the first one waits for the catalog, later ones do not.
          'from_screen_open': _fromScreenOpen,
          'rebuffers': _rebuffers,
          'stalled_ms': _stalledMs,
          if (_local != null) 'local': _local,
          if (_errorCode != null) 'error_code': _errorCode,
          // Floored to a 10s bucket. An exact watch length sitting next to an
          // event timestamp identifies an episode about as well as its title
          // would; the bucket still answers "did they bail in the first
          // minute".
          'duration_s': (now.difference(startedAt).inSeconds ~/ 10) * 10,
        },
      );
    } catch (e) {
      logD('VideoPlayerScreen', 'Playback health report error: $e');
    } finally {
      _reset();
    }
  }

  void dispose() {
    finish(_PlaybackEnd.screenDisposed);
    _detach();
  }

  void _begin({required DateTime startedAt, required bool fromScreenOpen}) {
    _reset();
    _sessionStartedAt = startedAt;
    _fromScreenOpen = fromScreenOpen;
  }

  void _reset() {
    _sessionStartedAt = null;
    _firstPlayingAt = null;
    _stallStartedAt = null;
    _rebuffers = 0;
    _stalledMs = 0;
    _local = null;
    _errorCode = null;
    _end = null;
  }

  void _detach() {
    _eventsSub?.cancel();
    _bufferingSub?.cancel();
    _eventsSub = null;
    _bufferingSub = null;
    _controller = null;
  }

  void _onEvent(PlayerLifecycleEvent event) {
    try {
      switch (event) {
        case EpisodeStarted():
          // The switch has landed, so this is the new episode's source — and
          // it is readable even if playback never gets going.
          _local = _readIsLocal() ?? _local;
        case PlaybackStarted():
          // Fires on every resume too, so only the first one is startup. The
          // source is re-read here because this is where the quality that
          // actually opened is settled, and a downloaded episode counts as
          // local only on the quality that has a file.
          if (_firstPlayingAt == null) {
            _firstPlayingAt = DateTime.now();
            _local = _readIsLocal() ?? _local;
          }
        case MediaLoadFailed(:final error):
          // An error outranks whatever end reason follows it.
          _end = _PlaybackEnd.loadFailed;
          _errorCode = _safeErrorCode(error);
        case PlaylistEnded():
          _latch(_PlaybackEnd.playlistEnded);
        case EpisodeEnded():
          _latch(_PlaybackEnd.episodeEnded);
        case EpisodeChanged():
          // The session boundary. Emitted before the next episode opens, so
          // the outgoing numbers are complete and the incoming startup clock
          // starts at the switch rather than at screen open.
          finish(_PlaybackEnd.episodeSwitched);
          _begin(startedAt: DateTime.now(), fromScreenOpen: false);
        default:
          break;
      }
    } catch (e) {
      logD('VideoPlayerScreen', 'Playback health event error: $e');
    }
  }

  /// The adapter re-emits buffering state on every tick (~10/s) with the same
  /// value, so this counts EDGES, not events. Stalls before the first playing
  /// state are startup, not rebuffering — they are already in `startup_ms`.
  void _onBuffering(BufferingState state) {
    if (_sessionStartedAt == null || _firstPlayingAt == null) return;
    if (state.isBuffering) {
      if (_stallStartedAt == null) {
        _stallStartedAt = DateTime.now();
        _rebuffers++;
      }
      return;
    }
    final stallStartedAt = _stallStartedAt;
    if (stallStartedAt != null) {
      _stalledMs += DateTime.now().difference(stallStartedAt).inMilliseconds;
      _stallStartedAt = null;
    }
  }

  /// Latches the most specific end reason seen, without letting a natural end
  /// overwrite an error.
  void _latch(_PlaybackEnd reason) {
    if (_end == _PlaybackEnd.loadFailed) return;
    _end = reason;
  }

  /// Whether playback is coming off disk. A bool, never the path.
  bool? _readIsLocal() {
    try {
      final type = _controller?.media.currentSource?.type;
      return type == null ? null : type != VideoSourceType.network;
    } catch (_) {
      return null;
    }
  }

  static String _safeErrorCode(PlayerError error) =>
      _codeShape.hasMatch(error.code) ? error.code : 'other';
}
