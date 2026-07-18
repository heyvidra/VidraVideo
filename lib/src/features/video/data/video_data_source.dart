import 'package:vidra/src/features/video/domain/video_collection.dart';
import 'package:vidra/src/features/video/domain/category.dart';

class VideoResponse {
  final List<Video> list;
  final int total;
  final int page;

  VideoResponse({required this.list, required this.total, required this.page});
}

abstract class VideoDataSource {
  String get id;
  String get name;

  /// Returns the categories provided by this data source.
  Future<List<Category>> getCategories();

  /// Fetches a list of videos based on categories and filters.
  Future<VideoResponse> fetchVideos({
    required int categoryId,
    int? subTypeId,
    String? area,
    String? year,
    int page = 1,
  });

  /// Fetches the details of a specific video by ID.
  Future<Video?> getVideoDetail(int id);

  /// Searches for videos based on a keyword.
  Future<List<Video>> searchVideos(String keyword);

  /// Resolves a potentially relative URL to a full URL.
  String resolveUrl(String url);

  /// Returns the download URL for a specific video or episode.
  Future<String?> getDownloadUrl(Video video, {VideoEpisode? episode});
}
