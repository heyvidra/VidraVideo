import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'play_history_provider.dart';
import '../domain/video_collection.dart';
import '../../../common/skeleton/video_card_skeleton.dart';
import 'widgets/cards/popular_video_card.dart';

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
            onPressed: () {
              ref.read(playHistoryProvider.notifier).clearHistory();
            },
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
              final item = history[index];

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

                return Stack(
                  key: ValueKey('history_${item.id}'),
                  children: [
                    PopularVideoCard(video: video),
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
}
