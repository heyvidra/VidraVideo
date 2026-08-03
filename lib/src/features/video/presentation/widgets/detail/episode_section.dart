import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shimmer_animation/shimmer_animation.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:vidra/src/features/video/domain/video_collection.dart';
import 'package:vidra/src/features/video/domain/play_history.dart'
    show EpisodeHistory;
import 'package:vidra/src/features/download/data/download_provider.dart';
import 'package:vidra/src/features/video/presentation/widgets/detail/episode_item.dart';
import 'package:vidra/src/features/video/presentation/play_history_provider.dart';
import 'package:vidra/src/features/video/data/video_repository.dart';
import 'package:vidra/src/features/video/presentation/widgets/cross_source_watch_badge.dart';
import 'package:vidra/src/features/subscription/presentation/subscription_provider.dart';

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
    // Which catalog the EPISODE LIST comes from. Everything else on the page
    // (title, blurb, subscription) stays the detail page's own show; only the
    // grid switches, because that is the part that differs between sources —
    // one is often episodes ahead of the other.
    final altSelected = useState(false);
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
                const SizedBox(width: 12),
                _SubscribeButton(video: video),
              ],
            ),
            _buildControls(context, ref, lastRefresh),
          ],
        ),
        _SourcePicker(video: video, altSelected: altSelected),
        const SizedBox(height: 16),
        if (!altSelected.value)
          historiesAsync.when(
            data: (histories) =>
                _episodeGrid(gridVideo: video, histories: histories),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Text('Error: $error'),
          )
        else
          _AltEpisodes(video: video, buildGrid: _episodeGrid),
        const SizedBox(height: 48),
      ],
    );
  }

  /// One grid for either source. [gridVideo] decides whose ids, whose
  /// sourceId and therefore whose playback and progress the tiles carry.
  Widget _episodeGrid({
    required Video gridVideo,
    required Map<int, EpisodeHistory> histories,
  }) {
    return ValueListenableBuilder2<bool, bool>(
      first: isAscending,
      second: isDownloadMode,
      builder: (context, ascending, downloadMode, _) {
        final urls = gridVideo.urls ?? const <VideoEpisode>[];
        final episodes = ascending ? urls : urls.reversed.toList();
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: episodes.asMap().entries.map((entry) {
            final originalIndex = ascending
                ? entry.key
                : urls.length - 1 - entry.key;
            return EpisodeItem(
              videoId: gridVideo.apiId,
              video: gridVideo,
              originalIndex: originalIndex,
              episode: entry.value,
              isDownloadMode: downloadMode,
              history: histories[originalIndex],
            );
          }).toList(),
        );
      },
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

/// Follow this show. Sits by the episode heading because that is where the
/// question arises — you subscribe to a thing that gains episodes, and the
/// episode list is that thing.
class _SubscribeButton extends ConsumerWidget {
  const _SubscribeButton({required this.video});

  final Video video;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final following = ref.watch(
      isSubscribedProvider((sourceId: video.sourceId, videoId: video.apiId)),
    );

    return OutlinedButton.icon(
      onPressed: () => ref.read(subscriptionsProvider.notifier).toggle(video),
      icon: Icon(
        following ? Icons.notifications_active : Icons.notifications_none,
        size: 16,
      ),
      label: Text(
        following
            ? tr('subscription.subscribed')
            : tr('subscription.subscribe'),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: following
            ? theme.colorScheme.primary
            : theme.colorScheme.onSurfaceVariant,
        side: BorderSide(
          color: following
              ? theme.colorScheme.primary.withValues(alpha: 0.6)
              : theme.colorScheme.outline.withValues(alpha: 80 / 255),
        ),
        textStyle: const TextStyle(fontSize: 12.5),
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

/// Chooses which catalog feeds the episode grid.
///
/// Rendered only when the cross-source index has actually matched this show on
/// another catalog (title + year, from watch history) — an unmatched show gets
/// no picker rather than a control that cannot do anything.
class _SourcePicker extends ConsumerWidget {
  const _SourcePicker({required this.video, required this.altSelected});

  final Video video;
  final ValueNotifier<bool> altSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final match = crossSourceWatchFor(ref, video);
    if (match == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Align(
        alignment: Alignment.centerLeft,
        child: DefaultTabController(
          length: 2,
          initialIndex: altSelected.value ? 1 : 0,
          child: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            dividerColor: Colors.transparent,
            labelColor: theme.colorScheme.primary,
            unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
            indicatorColor: theme.colorScheme.primary,
            indicatorSize: TabBarIndicatorSize.label,
            labelStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            onTap: (i) => altSelected.value = i == 1,
            tabs: [
              Tab(
                height: 36,
                text: sourceDisplayName(ref, video.sourceId ?? ''),
              ),
              Tab(height: 36, text: sourceDisplayName(ref, match.sourceId)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Placeholder grid while the other catalog's detail loads.
///
/// Shaped like the real tiles (100x50 rounded rects in a wrap) so the switch
/// reads as "the same list, arriving" rather than a page change. Count is a
/// plausible middle — the real episode count is precisely what is still
/// loading.
class _EpisodeGridSkeleton extends StatelessWidget {
  const _EpisodeGridSkeleton();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Shimmer(
      duration: const Duration(seconds: 2),
      interval: const Duration(milliseconds: 500),
      color: isDark ? Colors.white.withAlpha(70) : Colors.black.withAlpha(20),
      enabled: true,
      direction: const ShimmerDirection.fromLTRB(),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: List.generate(
          12,
          (_) => Container(
            width: 100,
            height: 50,
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[850] : Colors.grey[300],
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
    );
  }
}

/// The other catalog's episode list, loaded on demand.
///
/// Only the GRID switches: playback, per-episode progress and downloads all
/// key on the grid video's own (sourceId, videoId), so watching episode 9 over
/// there records progress over there — the two catalogs stay two histories,
/// exactly like the subscription side of this feature.
class _AltEpisodes extends ConsumerWidget {
  const _AltEpisodes({required this.video, required this.buildGrid});

  final Video video;
  final Widget Function({
    required Video gridVideo,
    required Map<int, EpisodeHistory> histories,
  })
  buildGrid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final match = crossSourceWatchFor(ref, video);
    if (match == null) return const SizedBox.shrink();

    final altAsync = ref.watch(
      videoByIdProvider((id: match.videoId, sourceId: match.sourceId)),
    );
    return altAsync.when(
      loading: () => const _EpisodeGridSkeleton(),
      error: (e, _) => Text('$e'),
      data: (alt) {
        if (alt == null || alt.urls == null || alt.urls!.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(tr('video.player.no_episodes')),
          );
        }
        final historiesAsync = ref.watch(
          episodeHistoriesProvider((
            videoId: alt.apiId,
            sourceId: alt.sourceId,
          )),
        );
        return historiesAsync.when(
          data: (histories) => buildGrid(gridVideo: alt, histories: histories),
          loading: () => const _EpisodeGridSkeleton(),
          error: (e, _) => Text('$e'),
        );
      },
    );
  }
}
