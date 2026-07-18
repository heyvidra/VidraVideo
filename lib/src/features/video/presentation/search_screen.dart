import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/video_repository.dart';
import 'package:vidra/src/features/video/presentation/widgets/list/search_video_list_tile.dart';
import '../../../common/netflix_loading.dart';

class SearchScreen extends ConsumerWidget {
  final String keyword;

  const SearchScreen({super.key, required this.keyword});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // If keyword is empty, just show empty or search prompt
    if (keyword.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(
            tr('search.prompt'),
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    final searchAsync = ref.watch(searchVideosProvider(keyword));

    return Scaffold(
      // backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(tr('search.title', args: [keyword])),
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: searchAsync.when(
        data: (videos) {
          if (videos.isEmpty) {
            return Center(
              child: Text(
                tr('search.no_results'),
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Text(
                  tr(
                    'search.count_format',
                    args: [keyword, videos.length.toString()],
                  ),
                  style: const TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: videos.length,
                  separatorBuilder: (c, i) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final video = videos[index];
                    return SearchVideoListTile(video: video, keyword: keyword);
                  },
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: NetflixLoading()),
        error: (error, stack) => Center(
          child: Text(
            tr('search.error', args: [error.toString()]),
            style: const TextStyle(color: Colors.white70),
          ),
        ),
      ),
    );
  }
}
