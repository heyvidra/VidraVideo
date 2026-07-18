import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vidra/src/features/video/domain/video_collection.dart';
import 'package:vidra/src/features/video/data/video_repository.dart';
import 'package:vidra/src/features/video/domain/category.dart';

// Filter state. null means "all" — display labels live in the UI layer,
// never in filter logic.
class VideoListFilter {
  final Category category;
  final String? subType;
  final String? area;
  final String? year;

  VideoListFilter({required this.category, this.subType, this.area, this.year});
}

// State for the list
class VideoListState {
  final List<Video> videos;
  final bool isLoading;
  final int page;
  final bool hasMore;
  final Object? error;

  VideoListState({
    required this.videos,
    this.isLoading = false,
    this.page = 1,
    this.hasMore = true,
    this.error,
  });

  VideoListState copyWith({
    List<Video>? videos,
    bool? isLoading,
    int? page,
    bool? hasMore,
    Object? error,
  }) {
    return VideoListState(
      videos: videos ?? this.videos,
      isLoading: isLoading ?? this.isLoading,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      error: error,
    );
  }
}

// Notifier
class VideoListNotifier extends Notifier<VideoListState> {
  VideoRepository get _repository => ref.read(videoRepositoryProvider);
  VideoListFilter get _filter => ref.read(videoListFilterProvider);

  bool _isFetching = false;

  @override
  VideoListState build() {
    // Watch filter and repository here to ensure we rebuild when they change.
    // This triggers a fresh state and a new initial load.
    ref.watch(videoRepositoryProvider);
    ref.watch(videoListFilterProvider);

    Future.microtask(() => loadNextPage());
    return VideoListState(videos: [], isLoading: true);
  }

  Future<void> loadNextPage() async {
    if (_isFetching || !state.hasMore) return;

    _isFetching = true;
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Find subTypeId from filter.subType name (null = all)
      int? subTypeId;
      final subTypeName = _filter.subType;
      if (subTypeName != null) {
        final child = _filter.category.children.firstWhere(
          (c) => c.name == subTypeName,
          orElse: () => Category(id: 0, name: ''),
        ); // 0 if not found
        if (child.id != 0) {
          subTypeId = child.id;
        }
      }

      final result = await _repository.fetchVideos(
        categoryId: _filter.category.id,
        subTypeId: subTypeId,
        area: _filter.area,
        year: _filter.year,
        page: state.page,
      );

      if (!ref.mounted) {
        _isFetching = false;
        return;
      }

      final newVideos = result['list'] as List<Video>;
      // final total = result['total'] as int;
      // If list is empty or we have loaded all, hasMore = false
      // Simple logic: if newVideos is empty, done.
      // Or check total vs current length?
      final hasMore = newVideos.isNotEmpty;
      // && (state.videos.length + newVideos.length < total); (API total might include all pages)

      state = state.copyWith(
        videos: [...state.videos, ...newVideos],
        isLoading: false,
        page: state.page + 1,
        hasMore: hasMore,
      );
    } catch (e) {
      if (!ref.mounted) {
        _isFetching = false;
        return;
      }
      state = state.copyWith(isLoading: false, error: e);
    } finally {
      _isFetching = false;
    }
  }

  Future<void> refresh() async {
    state = VideoListState(videos: []);
    await loadNextPage();
  }
}

// Providers
final videoListFilterProvider =
    NotifierProvider<VideoListFilterNotifier, VideoListFilter>(
      VideoListFilterNotifier.new,
      isAutoDispose: true,
    );

class VideoListFilterNotifier extends Notifier<VideoListFilter> {
  @override
  VideoListFilter build() {
    final categoriesAsync = ref.watch(categoriesProvider);

    return categoriesAsync.maybeWhen(
      data: (categories) {
        if (categories.isEmpty) {
          return VideoListFilter(category: const Category(id: 0, name: '无分类'));
        }
        // Try to keep previous selected category if it exists in new categories,
        // otherwise default to first. (Simple for now: just pick first)
        return VideoListFilter(category: categories.first);
      },
      orElse: () =>
          VideoListFilter(category: const Category(id: 0, name: '加载中...')),
    );
  }

  @override
  set state(VideoListFilter value) => super.state = value;
}

final videoListProvider = NotifierProvider<VideoListNotifier, VideoListState>(
  VideoListNotifier.new,
  isAutoDispose: true,
);
