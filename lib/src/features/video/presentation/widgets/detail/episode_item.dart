import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:vidra/src/config/design_tokens.dart';
import 'package:vidra/src/features/video/data/history_repository.dart';
import 'package:vidra/src/features/video/domain/video_collection.dart';
import 'package:vidra/src/features/video/presentation/widgets/cross_source_watch_badge.dart'
    show sourceDisplayName;
import 'package:vidra/src/features/video/domain/episode_number.dart';
import 'package:vidra/src/features/video/domain/play_history.dart';
import 'package:vidra/src/features/video/presentation/widgets/key_art.dart';
import 'package:vidra/src/features/download/data/download_provider.dart';
import 'package:vidra/src/features/download/domain/download_task.dart';
import 'package:vidra/src/window/player_window_launcher.dart';

/// `.ep` — one episode, in two halves.
///
/// The upper half is where the frame goes: number bottom-left, state
/// top-right, progress along the bottom edge. The lower half is the caption —
/// what this episode is called, and where its progress was borrowed from. A
/// single flat box with a number floating in the middle of it, which is what
/// this was, reads as a button rather than as a piece of a series.
class EpisodeItem extends ConsumerWidget {
  final int videoId;
  final Video video;
  final int originalIndex;
  final VideoEpisode episode;
  final bool isDownloadMode;
  final bool isSelected;
  final VoidCallback? onTap;
  final EpisodeHistory? history;

  const EpisodeItem({
    super.key,
    required this.videoId,
    required this.video,
    required this.originalIndex,
    required this.episode,
    required this.isDownloadMode,
    this.isSelected = false,
    this.onTap,
    this.history,
  });

  /// `.ep .th` — the frame's half.
  static const _thumb = 58.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (history != null) return _content(context, ref, history);

    return FutureBuilder<EpisodeHistory?>(
      future: ref
          .read(historyRepositoryProvider)
          .getEpisodeHistory(videoId, originalIndex, video.sourceId),
      builder: (context, snapshot) => _content(context, ref, snapshot.data),
    );
  }

  Widget _content(BuildContext context, WidgetRef ref, EpisodeHistory? h) {
    final t = VidraTokens.of(context);
    final watched = h != null && h.positionMillis > 0 && h.durationMillis > 0;
    final progress = watched
        ? (h.positionMillis / h.durationMillis).clamp(0.0, 1.0)
        : 0.0;
    final done = watched && progress > 0.9;

    // The badge reports THIS episode's own download status. It used to be a
    // green "download_done" for anything merely present in the task list, so a
    // queued, still-downloading or outright failed episode all claimed to be
    // saved offline — the one state the badge exists to communicate.
    final downloadStatus = ref
        .watch(downloadTasksProvider)
        .maybeWhen(
          data: (tasks) {
            for (final task in tasks) {
              if (task.videoId != videoId) continue;
              for (final e in task.episodes) {
                if (e.index == originalIndex) return e.status;
              }
            }
            return null;
          },
          orElse: () => null,
        );

    final number = episodeNumberOf(
      episode.title,
      index: originalIndex,
      episodic: isEpisodicType(video.type),
    );
    final selected = isSelected && !isDownloadMode;

    // Progress that came from ANOTHER catalog, which is the one thing on this
    // page nobody would guess: a tick on a catalog you have never played is
    // either magic or a bug until the tile says where it came from.
    final borrowedFrom = (h != null && h.sourceId != null &&
            h.sourceId != video.sourceId)
        ? sourceDisplayName(ref, h.sourceId!)
        : null;

    // Hover reveals what the one-line caption had to cut: variety-show
    // episodes carry date + full segment names ("20260602(先导片:...)") that
    // no tile width can hold.
    return Tooltip(
      message: episodeLabel(episode.title, index: originalIndex),
      waitDuration: const Duration(milliseconds: 350),
      child: Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap ?? () => _handleTap(context, ref),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: t.glass2,
            ),
            border: Border.all(
              color: selected ? t.cyan.withValues(alpha: 0.6) : t.edgeSoft,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: _thumb,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    KeyArt(seed: (number ?? originalIndex + 1) - 1),
                    if (number != null)
                      Positioned(
                        left: 9,
                        bottom: 5,
                        child: Text(
                          number < 10 ? '0$number' : '$number',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            height: 1,
                            fontWeight: FontWeight.w600,
                            fontFeatures: VidraType.data,
                            shadows: [
                              Shadow(
                                color: Color(0xE6000000),
                                blurRadius: 9,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (done)
                      Positioned(top: 6, right: 6, child: _Check(t))
                    else if (episode.isNew == true)
                      Positioned(top: 6, right: 6, child: _NewFlag(t)),
                    if (watched && progress > 0.02)
                      Positioned(
                        left: 0,
                        bottom: 0,
                        right: 0,
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: done ? 1.0 : progress,
                          child: Container(
                            height: 3,
                            decoration: BoxDecoration(
                              color: t.cyan,
                              boxShadow: [
                                BoxShadow(color: t.cyanGlow, blurRadius: 10),
                              ],
                            ),
                          ),
                        ),
                      ),
                    if (downloadStatus != null)
                      Positioned(
                        bottom: 6,
                        right: 6,
                        child: _DownloadDot(downloadStatus),
                      ),
                  ],
                ),
              ),
              // `.ep .cap`
              Padding(
                padding: const EdgeInsets.fromLTRB(9, 6, 9, 8),
                child: Row(
                  children: [
                    // The episode's own name gets the room; the source label
                    // is capped instead of sharing the shortfall, or a
                    // two-character caption ends up elided beside it.
                    Expanded(
                      child: Text(
                        episodeLabel(episode.title, index: originalIndex),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.5,
                          height: 1.25,
                          color: selected ? t.cyan : t.fg2,
                        ),
                      ),
                    ),
                    if (borrowedFrom != null) ...[
                      const SizedBox(width: 5),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 52),
                        child: Text(
                          borrowedFrom,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.end,
                          style: TextStyle(
                            fontSize: 9,
                            height: 1.4,
                            color: t.cyan,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  Future<void> _handleTap(BuildContext context, WidgetRef ref) async {
    if (isDownloadMode) {
      final manager = ref.read(downloadManagerProvider);
      manager.addTask(
        videoId: video.apiId,
        videoTitle: video.title,
        coverUrl: video.coverUrl,
        episodes: [
          {
            'index': originalIndex,
            'title': episodeLabel(episode.title, index: originalIndex),
            'url': episode.url ?? '',
          },
        ],
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tr(
              'video.detail.download_added',
              args: [episodeLabel(episode.title, index: originalIndex)],
            ),
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 1),
        ),
      );
    } else {
      await PlayerWindowLauncher.open(
        videoId: video.apiId,
        episodeIndex: originalIndex,
        sourceId: video.sourceId,
      );
    }
  }
}

/// `.ep .ck` — seen it.
class _Check extends StatelessWidget {
  const _Check(this.t);
  final VidraTokens t;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 17,
      height: 17,
      decoration: BoxDecoration(
        color: t.cyan,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: t.cyanGlow, blurRadius: 14)],
      ),
      child: Icon(Icons.check_rounded, size: 11, color: t.onCyan),
    );
  }
}

/// `.ep .flag` — landed since you last looked.
class _NewFlag extends StatelessWidget {
  const _NewFlag(this.t);
  final VidraTokens t;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: t.amber,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [BoxShadow(color: t.amberGlow, blurRadius: 14)],
      ),
      child: Text(
        tr('video.detail.new_badge'),
        style: TextStyle(
          color: t.onAmber,
          fontSize: 8.5,
          height: 1.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _DownloadDot extends StatelessWidget {
  const _DownloadDot(this.status);
  final DownloadStatus status;

  @override
  Widget build(BuildContext context) {
    final (color, icon) = switch (status) {
      DownloadStatus.completed => (
        const Color(0xFF4CAF50),
        Icons.download_done_rounded,
      ),
      DownloadStatus.downloading => (
        const Color(0xFF2196F3),
        Icons.downloading_rounded,
      ),
      DownloadStatus.queued => (const Color(0xFF8A8A8A), Icons.schedule),
      DownloadStatus.paused => (const Color(0xFF8A8A8A), Icons.pause),
      DownloadStatus.failed => (
        const Color(0xFFE53935),
        Icons.error_outline_rounded,
      ),
      // Cancelled leaves nothing on disk; treat it as "not downloaded".
      DownloadStatus.cancelled => (null, null),
    };
    if (color == null || icon == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Icon(icon, color: Colors.white, size: 10),
    );
  }
}
