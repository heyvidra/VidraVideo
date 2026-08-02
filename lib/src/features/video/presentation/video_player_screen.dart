import 'dart:io';

import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:vidra_player/vidra_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../../core/services/window.dart';
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
  final int initialEpisodeIndex;
  final VideoPlayerWindowCloseController? closeController;

  const VideoPlayerScreen({
    super.key,
    required this.videoId,
    this.sourceId,
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
          ve.qualities
              ?.map((q) {
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
              })
              .toList() ??
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

    try {
      if (_controller != null) {
        await _controller!.dispose();
        _controller = null;
      }
    } catch (e) {
      logD('VideoPlayerScreen', 'Error disposing player controller during close: $e');
    }

    // Give native texture threads time to spin down before killing the engine
    await Future.delayed(const Duration(milliseconds: 200));

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
      leading: IconButton(
        icon: const Icon(Icons.close),
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

    return PlayerController(
      config: config,
      video: metadata,
      episodes: episodes,
      windowDelegate: BitsdojoWindowDelegate(),
      mediaRepository: _mediaRepository,
    );
  }

  /// A message screen (not found / no episodes / error) that still carries a
  /// close button — the player window hides its native title-bar buttons, so
  /// without this a broken open (e.g. the file was deleted) can't be closed.
  Widget _infoScreen(String message) {
    return Stack(
      children: [
        Positioned.fill(
          child: Center(
            child: Text(
              message,
              style: const TextStyle(color: Colors.white70),
            ),
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
          if (video != null && video.urls != null && video.urls!.isNotEmpty) {
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
