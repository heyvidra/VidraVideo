import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'play_history_provider.dart';
import '../domain/play_history.dart';
import '../domain/video_collection.dart';
import '../../../common/skeleton/video_card_skeleton.dart';
import 'widgets/cards/popular_video_card.dart';
import 'package:vidra/src/window/player_window_launcher.dart';

class RecentListScreen extends ConsumerStatefulWidget {
  const RecentListScreen({super.key});

  @override
  ConsumerState<RecentListScreen> createState() => _RecentListScreenState();
}

class _RecentListScreenState extends ConsumerState<RecentListScreen> {
  @override
  void initState() {
    super.initState();
    // Manual refresh when entering the screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(playHistoryProvider.notifier).manualRefresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(playHistoryProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(tr('recent.title')),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                ref.read(playHistoryProvider.notifier).manualRefresh(),
            tooltip: tr('common.refresh'),
          ),
          TextButton(
            onPressed: () => _confirmClearAll(context, ref),
            child: Text(
              tr('recent.clear_all'),
              style: const TextStyle(color: Colors.red),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: historyAsync.when(
        data: (history) {
          if (history.isEmpty) {
            return Center(
              child: Text(
                tr('recent.empty'),
                style: const TextStyle(color: Colors.grey),
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(24),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 220,
              childAspectRatio: 0.7,
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
            ),
            itemCount: history.length,
            itemBuilder: (context, index) {
              final entry = history[index];
              final item = entry.video;

              try {
                // Map VideoHistory to Video model for PopularVideoCard
                final video = Video(
                  apiId: item.videoId,
                  title: item.videoTitle,
                  coverUrl: item.coverUrl,
                  rating: double.tryParse(item.rating ?? '') ?? 0.0,
                  type: item.type,
                  region: item.region,
                  year: item.year,
                  actor: item.actor,
                  version: item.version,
                  hits: item.hits,
                  remarks: item.remarks,
                  blurb: item.blurb,
                  sourceId: item.sourceId,
                );

                // A film is located by its timestamp; only episodic content
                // has a meaningful "which one". See isEpisodicType — sources
                // file a film's audio tracks and mirrors under the episode
                // list, so its "episode title" is 立即播放 / 粤语播放.
                final String? watchLabel;
                if (isEpisodicType(item.type)) {
                  final episodeLabel =
                      item.lastEpisodeTitle ??
                      tr(
                        'video.detail.episode_prefix',
                        args: [(item.lastEpisodeIndex + 1).toString()],
                      );
                  watchLabel = tr('recent.watched_to', args: [episodeLabel]);
                } else if (entry.position > Duration.zero) {
                  watchLabel = tr(
                    'recent.watched_to',
                    args: [_formatPosition(entry.position)],
                  );
                } else {
                  watchLabel = null;
                }

                return Stack(
                  key: ValueKey('history_${item.id}'),
                  children: [
                    PopularVideoCard(
                      video: video,
                      // Straight back into the episode they left. This list
                      // exists precisely because they intend to keep watching;
                      // routing it through the detail page made the shortcut
                      // longer than the long way round.
                      onTap: () => PlayerWindowLauncher.open(
                        videoId: item.videoId,
                        episodeIndex: item.lastEpisodeIndex,
                        sourceId: item.sourceId,
                      ),
                      watchLabel: watchLabel,
                      watchProgress: entry.progress,
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: IconButton(
                        icon: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 16,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.black45,
                          padding: EdgeInsets.zero,
                        ),
                        onPressed: () {
                          ref
                              .read(playHistoryProvider.notifier)
                              .deleteVideoHistory(item.id);
                        },
                      ),
                    ),
                  ],
                );
              } catch (e) {
                return const SizedBox.shrink();
              }
            },
          );
        },
        loading: () => GridView.builder(
          padding: const EdgeInsets.all(24),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 220,
            childAspectRatio: 0.7,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
          ),
          itemCount: 10,
          itemBuilder: (context, index) => const VideoCardSkeleton(),
        ),
        error: (err, stack) =>
            Center(child: Text(tr('common.error', args: [err.toString()]))),
      ),
    );
  }

  static String _formatPosition(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final sec = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$sec' : '${d.inMinutes}:$sec';
  }

  /// "Clear all" wipes far more than the list it sits above — watch positions,
  /// cached episode data, and every show's intro/outro skip points all go with
  /// it, irreversibly. Name what is being destroyed before doing it.
  Future<void> _confirmClearAll(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(tr('video.list.clear_history_title')),
        content: Text(tr('video.list.clear_history_body')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(tr('common.cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            child: Text(tr('video.list.clear_history_confirm')),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      ref.read(playHistoryProvider.notifier).clearHistory();
    }
  }
}
