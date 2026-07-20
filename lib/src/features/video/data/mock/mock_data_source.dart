import 'package:vidra/src/features/video/domain/category.dart';
import 'package:vidra/src/features/video/domain/video_collection.dart';
import 'package:vidra/src/features/video/data/video_data_source.dart';

class MockDataSource implements VideoDataSource {
  MockDataSource();

  @override
  String get id => 'mock';

  @override
  String get name => '模拟数据源';

  @override
  Future<List<Category>> getCategories() async {
    return [
      const Category(id: 1, name: '电影', enName: 'movie'),
      const Category(id: 2, name: '剧集', enName: 'series'),
    ];
  }

  @override
  Future<VideoResponse> fetchVideos({
    required int categoryId,
    int? subTypeId,
    String? area,
    String? year,
    int page = 1,
  }) async {
    final videos = List.generate(10, (index) {
      return Video(
        apiId: 9000 + index,
        title: '模拟视频 ${index + 1} (Source: Mock)',
        coverUrl: 'https://picsum.photos/seed/${9000 + index}/200/300',
        rating: 8.5,
        type: categoryId == 1 ? 'movie' : 'series',
        sourceId: id,
      );
    });

    return VideoResponse(list: videos, total: 10, page: 1);
  }

  @override
  Future<Video?> getVideoDetail(int id) async {
    return Video(
      apiId: id,
      title: '模拟视频 Detail (Source: Mock)',
      coverUrl: 'https://picsum.photos/seed/$id/200/300',
      content: '这是一个模拟视频的数据，用于测试数据源切换功能。',
      rating: 9.0,
      type: 'movie',
      sourceId: this.id,
      urls: const [
        VideoEpisode(
          title: '第1集',
          qualities: [
            VideoQuality(
              name: '大兔子',
              url: 'https://www.w3school.com.cn/example/html5/mov_bbb.mp4',
            ),
            VideoQuality(
              name: '大灰熊',
              url: 'https://www.w3schools.com/html/movie.mp4',
            ),
            VideoQuality(
              name: '大白兔',
              url: 'https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8',
            ),
          ],
        ),
      ],
    );
  }

  @override
  Future<List<Video>> searchVideos(String keyword) async {
    return [
      Video(
        apiId: 9999,
        title: '搜索结果: $keyword (Source: Mock)',
        coverUrl: 'https://picsum.photos/seed/search/200/300',
        rating: 8.0,
        type: 'movie',
        sourceId: id,
      ),
    ];
  }

  @override
  String resolveUrl(String url) => url;

  @override
  Future<String?> resolveEpisodeUrl(String url) async => url;

  @override
  Future<String?> getDownloadUrl(Video video, {VideoEpisode? episode}) async {
    return episode?.qualities?.firstOrNull?.url ??
        video.urls?.firstOrNull?.qualities?.firstOrNull?.url;
  }
}
