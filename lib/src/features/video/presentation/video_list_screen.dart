import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:vidra/src/features/video/presentation/widgets/list/category_filter.dart';
import 'package:vidra/src/features/video/presentation/video_list_provider.dart';
import 'package:vidra/src/features/video/presentation/widgets/cards/popular_video_card.dart';
import 'package:vidra/src/common/skeleton/video_card_skeleton.dart';
import 'package:vidra/src/features/video/domain/category.dart';
import 'package:vidra/src/features/video/data/video_repository.dart';

class VideoListScreen extends HookConsumerWidget {
  const VideoListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    context.locale; // Ensure rebuild on locale change
    final listState = ref.watch(videoListProvider);
    final filter = ref.watch(videoListFilterProvider);
    final videos = listState.videos;

    // Infinite Scroll Controller
    final scrollController = useScrollController();
    useEffect(() {
      scrollController.addListener(() {
        if (scrollController.position.pixels >=
            scrollController.position.maxScrollExtent - 200) {
          ref.read(videoListProvider.notifier).loadNextPage();
        }
      });
      return null;
    }, [scrollController]);

    final categoriesAsync = ref.watch(categoriesProvider);
    final categories = categoriesAsync.maybeWhen(
      data: (data) => data,
      orElse: () => <Category>[],
    );

    // Scrollbars already hidden app-wide via NoScrollbarBehavior in main.dart
    return CustomScrollView(
      controller: scrollController,
      slivers: [
        // Header (Category Filter)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: CategoryFilter(
                    selectedCategory: filter.category,
                    categories: categories,
                    selectedSubType: filter.subType,
                    selectedArea: filter.area,
                    selectedYear: filter.year,
                    onCategoryChanged: (Category cat) {
                      // Category change resets all sub-filters to "all"
                      ref.read(videoListFilterProvider.notifier).state =
                          VideoListFilter(category: cat);
                    },
                    onFilterChanged: (subType, area, year) {
                      ref
                          .read(videoListFilterProvider.notifier)
                          .state = VideoListFilter(
                        category: filter.category,
                        subType: subType,
                        area: area,
                        year: year,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),

        // Loading State Skeleton
        if (listState.isLoading && videos.isEmpty)
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 220,
                childAspectRatio: 0.7,
                mainAxisSpacing: 20,
                crossAxisSpacing: 20,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) => const VideoCardSkeleton(),
                childCount: 12, // Show a reasonable number of skeletons
              ),
            ),
          ),

        if (videos.isNotEmpty) ...[
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 220, // Adjusted for responsiveness
                childAspectRatio: 0.7,
                mainAxisSpacing: 20,
                crossAxisSpacing: 20,
              ),
              delegate: SliverChildBuilderDelegate((context, index) {
                return PopularVideoCard(video: videos[index]);
              }, childCount: videos.length),
            ),
          ),

          // Loading footer - use skeletons instead of spinner
          if (listState.isLoading)
            SliverPadding(
              padding: const EdgeInsets.only(
                left: 16,
                right: 16,
                top: 20,
                bottom: 20,
              ),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 220,
                  childAspectRatio: 0.7,
                  mainAxisSpacing: 20,
                  crossAxisSpacing: 20,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) => const VideoCardSkeleton(),
                  childCount: 4, // Show a row of loading items at bottom
                ),
              ),
            ),
        ] else if (!listState.isLoading && videos.isEmpty) ...[
          // Distinguish "request failed" from "genuinely no results"
          SliverFillRemaining(
            child: Center(
              child: listState.error != null
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          tr(
                            'video.detail.error',
                            args: [listState.error.toString()],
                          ),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () =>
                              ref.read(videoListProvider.notifier).refresh(),
                          child: Text(tr('common.refresh')),
                        ),
                      ],
                    )
                  : Text(
                      tr('search.no_results'),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
            ),
          ),
        ],
      ],
    );
  }
}
