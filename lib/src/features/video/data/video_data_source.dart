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
  ///
  /// [sourceKey] is the source's own identifier, replayed from the cached row
  /// for sources whose ids are not numbers (yfsp). Sources that key on [id]
  /// ignore it. It is null on a show this device has never cached, which is
  /// why a source that needs it must answer null rather than guess.
  Future<Video?> getVideoDetail(int id, {String? sourceKey});

  /// Searches for videos based on a keyword.
  Future<List<Video>> searchVideos(String keyword);

  /// Resolves a potentially relative URL to a full URL.
  String resolveUrl(String url);

  /// Turns a stored episode URL into a playable stream URL.
  ///
  /// Sources whose detail payload already carries stream URLs just hand the
  /// URL back. Sources that store a placeholder (dbku keeps a `/vodplay/` page
  /// path, since the stream sits behind one more request) resolve it here.
  /// Implementations must be idempotent: passing an already-resolved URL
  /// returns it untouched.
  Future<String?> resolveEpisodeUrl(String url);

  /// Returns the download URL for a specific video or episode.
  Future<String?> getDownloadUrl(Video video, {VideoEpisode? episode});

  /// The host to measure this source's latency against, or null for a source
  /// with no network behind it.
  ///
  /// A HOST rather than an endpoint, and measured with a TCP connect rather
  /// than a request, deliberately: yfsp rate-limits its API hard enough to
  /// answer `code:5` and escalate to a bot challenge, so anything that pings
  /// on a timer must not spend API calls to do it. A connect handshake is the
  /// round trip the user is actually choosing between, costs the host nothing
  /// it polices, and stays honest if the API is having a bad day.
  String? get pingHost;

  /// HTTP headers this source's streams have to be opened with, or null to let
  /// the player guess.
  ///
  /// The player's guess is a browser user agent plus a referer pointing at the
  /// stream's own host, which is what most anti-hotlinking CDNs want. yfsp's
  /// answers 520 to exactly that referer, so it says otherwise here. Null for
  /// every source that is happy with the guess, which is the default.
  Map<String, String>? get streamHeaders => null;
}
