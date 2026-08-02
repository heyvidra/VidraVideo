import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:vidra/src/features/video/domain/video_collection.dart';
import 'package:vidra/src/features/download/data/download_provider.dart';
import 'package:vidra/src/features/video/presentation/widgets/detail/episode_item.dart';
import 'package:vidra/src/features/video/presentation/play_history_provider.dart';
import 'package:vidra/src/features/video/data/video_repository.dart';
import 'package:vidra/src/features/video/presentation/widgets/cross_source_watch_badge.dart';

class EpisodeSection extends HookConsumerWidget {
  final Video video;
  final ValueNotifier<bool> isAscending;
  final ValueNotifier<bool> isDownloadMode;

  const EpisodeSection({
    super.key,
    required this.video,
    required this.isAscending,
    required this.isDownloadMode,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lastRefresh = useState<DateTime?>(null);
    if (video.urls == null || video.urls!.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24.0),
        child: Center(
          child: Text(
            tr('video.player.no_episodes'),
            style: const TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    final theme = Theme.of(context);

    final historiesAsync = ref.watch(
      episodeHistoriesProvider((
        videoId: video.apiId,
        sourceId: video.sourceId,
      )),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  tr('video.section.episodes'),
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(width: 16),
                // Beside the heading rather than under the hero title: over a
                // backdrop image it competed with the artwork for contrast and
                // read as decoration. Here it sits next to the thing it is
                // about — the episode list.
                CrossSourceWatchBadge(video: video),
              ],
            ),
            _buildControls(context, ref, lastRefresh),
          ],
        ),
        const SizedBox(height: 16),
        historiesAsync.when(
          data: (histories) {
            return ValueListenableBuilder2<bool, bool>(
              first: isAscending,
              second: isDownloadMode,
              builder: (context, ascending, downloadMode, _) {
                final episodes = ascending
                    ? video.urls!
                    : video.urls!.reversed.toList();
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: episodes.asMap().entries.map((entry) {
                    final originalIndex = ascending
                        ? entry.key
                        : video.urls!.length - 1 - entry.key;
                    return EpisodeItem(
                      videoId: video.apiId,
                      video: video,
                      originalIndex: originalIndex,
                      episode: entry.value,
                      isDownloadMode: downloadMode,
                      history: histories[originalIndex],
                    );
                  }).toList(),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Text('Error: $error'),
        ),
        const SizedBox(height: 48),
      ],
    );
  }

  Widget _buildControls(
    BuildContext context,
    WidgetRef ref,
    ValueNotifier<DateTime?> lastRefresh,
  ) {
    return Row(
      children: [
        ValueListenableBuilder<bool>(
          valueListenable: isDownloadMode,
          builder: (context, downloadMode, _) {
            if (!downloadMode) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ElevatedButton.icon(
                onPressed: () => _downloadAll(context, ref),
                icon: const Icon(Icons.download, size: 16),
                label: Text(tr('video.detail.download_all')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2196F3),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
              ),
            );
          },
        ),
        ValueListenableBuilder<bool>(
          valueListenable: isAscending,
          builder: (context, ascending, _) {
            return Row(
              children: [
                HookBuilder(
                  builder: (context) {
                    final now = DateTime.now();
                    final isCooldown =
                        lastRefresh.value != null &&
                        now.difference(lastRefresh.value!).inSeconds < 30;
                    return IconButton(
                      tooltip: tr('common.refresh'),
                      icon: Icon(
                        Icons.refresh,
                        size: 20,
                        color: isCooldown
                            ? Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.3)
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                      onPressed: () {
                        final clickTime = DateTime.now();
                        if (lastRefresh.value != null &&
                            clickTime.difference(lastRefresh.value!).inSeconds <
                                30) {
                          final remaining =
                              30 -
                              clickTime
                                  .difference(lastRefresh.value!)
                                  .inSeconds;
                          ScaffoldMessenger.of(context).removeCurrentSnackBar();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '刷新太频繁，请在 $remaining 秒后重试',
                                style: const TextStyle(color: Colors.white),
                              ),
                              backgroundColor: Colors.orange,
                              duration: const Duration(seconds: 1),
                            ),
                          );
                          return;
                        }
                        lastRefresh.value = clickTime;
                        ref.invalidate(
                          videoByIdProvider((
                            id: video.apiId,
                            sourceId: video.sourceId,
                          )),
                        );
                        ref.invalidate(
                          episodeHistoriesProvider((
                            videoId: video.apiId,
                            sourceId: video.sourceId,
                          )),
                        );
                        ref.read(playHistoryProvider.notifier).manualRefresh();
                      },
                    );
                  },
                ),
                Text(
                  ascending
                      ? tr('video.detail.sort_asc')
                      : tr('video.detail.sort_desc'),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(
                    ascending ? Icons.arrow_upward : Icons.arrow_downward,
                    size: 20,
                  ),
                  onPressed: () => isAscending.value = !isAscending.value,
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  void _downloadAll(BuildContext context, WidgetRef ref) {
    final manager = ref.read(downloadManagerProvider);
    final episodes = video.urls!;
    manager.addTask(
      videoId: video.apiId,
      videoTitle: video.title,
      coverUrl: video.coverUrl,
      episodes: episodes
          .asMap()
          .entries
          .map(
            (e) => {
              'index': e.key,
              'title':
                  e.value.title ??
                  tr(
                    'video.detail.episode_prefix',
                    args: [(e.key + 1).toString()],
                  ),
              'url': e.value.url ?? '',
            },
          )
          .toList(),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          tr(
            'video.detail.download_batch_added',
            args: [episodes.length.toString()],
          ),
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
    isDownloadMode.value = false;
  }
}

// Helper for listening to two value listenables
class ValueListenableBuilder2<A, B> extends StatelessWidget {
  final ValueListenable<A> first;
  final ValueListenable<B> second;
  final Widget Function(BuildContext context, A a, B b, Widget? child) builder;
  final Widget? child;

  const ValueListenableBuilder2({
    super.key,
    required this.first,
    required this.second,
    required this.builder,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<A>(
      valueListenable: first,
      builder: (context, a, _) {
        return ValueListenableBuilder<B>(
          valueListenable: second,
          builder: (context, b, _) {
            return builder(context, a, b, child);
          },
        );
      },
    );
  }
}
