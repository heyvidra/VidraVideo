import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:vidra/src/features/video/data/history_repository.dart';
import 'package:vidra/src/features/video/domain/video_collection.dart';
import 'package:vidra/src/features/video/domain/play_history.dart';
import 'package:vidra/src/features/download/data/download_provider.dart';
import 'package:vidra/src/window/player_window_launcher.dart';

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    if (history != null) {
      return _buildContent(context, ref, theme, history!);
    }

    return FutureBuilder<EpisodeHistory?>(
      future: ref
          .read(historyRepositoryProvider)
          .getEpisodeHistory(videoId, originalIndex, video.sourceId),
      builder: (context, snapshot) {
        return _buildContent(context, ref, theme, snapshot.data);
      },
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    EpisodeHistory? historyData,
  ) {
    final hasWatched =
        historyData != null &&
        historyData.positionMillis > 0 &&
        historyData.durationMillis > 0;
    final watchProgress = hasWatched
        ? (historyData.positionMillis / historyData.durationMillis).clamp(
            0.0,
            1.0,
          )
        : 0.0;

    // Check if this episode is in download tasks
    final downloadTasksAsync = ref.watch(downloadTasksProvider);
    final isInDownloadTasks = downloadTasksAsync.when(
      data: (tasks) => tasks.any(
        (task) =>
            task.videoId == videoId &&
            task.episodes.any((e) => e.index == originalIndex),
      ),
      loading: () => false,
      error: (_, _) => false,
    );

    return InkWell(
      onTap: onTap ?? () => _handleTap(context, ref),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 100,
        height: 50,
        decoration: BoxDecoration(
          color: isSelected && !isDownloadMode
              ? theme.colorScheme.primary.withValues(alpha: 0.5)
              : theme.cardTheme.color?.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected && !isDownloadMode
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurface.withAlpha(30),
            width: isSelected && !isDownloadMode ? 2 : 1,
          ),
        ),
        child: Stack(
          children: [
            if (hasWatched && watchProgress > 0.05)
              _buildProgressBar(watchProgress),
            _buildCenterContent(theme),
            if (episode.isNew == true) _buildNewBadge(theme),
            if (hasWatched && watchProgress > 0.9) _buildWatchedCheck(),
            if (isInDownloadTasks) _buildDownloadIndicator(),
          ],
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
            'title':
                episode.title ??
                tr(
                  'video.detail.episode_prefix',
                  args: [(originalIndex + 1).toString()],
                ),
            'url': episode.url ?? '',
          },
        ],
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tr(
              'video.detail.download_added',
              args: [
                episode.title ??
                    tr(
                      'video.detail.episode_prefix',
                      args: [(originalIndex + 1).toString()],
                    ),
              ],
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

  Widget _buildProgressBar(double progress) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        height: 3,
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(8),
            bottomRight: Radius.circular(8),
          ),
          color: Colors.white.withAlpha(30),
        ),
        child: FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: progress,
          child: Container(
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(8),
                bottomRight: Radius.circular(8),
              ),
              color: Color(0xFF00E5FF),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCenterContent(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isSelected && !isDownloadMode)
            const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 20),
          Text(
            episode.title ??
                tr(
                  'video.detail.episode_prefix',
                  args: [(originalIndex + 1).toString()],
                ),
            style: TextStyle(
              color: isSelected && !isDownloadMode
                  ? Colors.white
                  : theme.colorScheme.onSurface,
              fontSize: 13,
              fontWeight: isSelected && !isDownloadMode
                  ? FontWeight.bold
                  : FontWeight.normal,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildNewBadge(ThemeData theme) {
    return Positioned(
      top: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFFFF6B00),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          tr('video.detail.new_badge'),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 8,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildWatchedCheck() {
    return Positioned(
      top: 4,
      left: 4,
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: const BoxDecoration(
          color: Color(0xFF00E5FF),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.check, color: Colors.black, size: 10),
      ),
    );
  }

  Widget _buildDownloadIndicator() {
    return Positioned(
      bottom: 4,
      right: 4,
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: const Color(0xFF4CAF50),
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Icon(Icons.download_done, color: Colors.white, size: 10),
      ),
    );
  }
}
