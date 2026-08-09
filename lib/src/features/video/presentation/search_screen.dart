import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/video_repository.dart';
import 'package:vidra/src/features/video/presentation/widgets/list/search_video_list_tile.dart';
import '../../../common/netflix_loading.dart';
import '../../../common/screen_chrome.dart';

class SearchScreen extends ConsumerWidget {
  final String keyword;

  const SearchScreen({super.key, required this.keyword});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // If keyword is empty, just show empty or search prompt
    if (keyword.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: ScreenEmpty(
          icon: Icons.search_rounded,
          title: tr('search.prompt'),
        ),
      );
    }

    final searchAsync = ref.watch(searchVideosProvider(keyword));

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          ScreenHeader(
            title: tr('search.title', args: [keyword]),
            count: searchAsync.value?.isNotEmpty == true
                ? '${searchAsync.value!.length}'
                : null,
          ),
          Expanded(
            child: searchAsync.when(
              data: (videos) {
                if (videos.isEmpty) {
                  return ScreenEmpty(
                    icon: Icons.search_off_rounded,
                    title: tr('search.no_results'),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                    kContentGutter,
                    0,
                    kContentGutter,
                    24,
                  ),
                  itemCount: videos.length,
                  separatorBuilder: (c, i) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final video = videos[index];
                    return SearchVideoListTile(video: video, keyword: keyword);
                  },
                );
              },
              loading: () => const Center(child: NetflixLoading()),
              error: (error, stack) => ScreenEmpty(
                icon: Icons.error_outline_rounded,
                title: tr('search.error', args: [error.toString()]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
