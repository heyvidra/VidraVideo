import 'package:dio/dio.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/utils/log.dart';
import 'package:vidra/src/features/video/domain/category.dart';
import 'package:vidra/src/features/video/domain/video_collection.dart';
import 'package:vidra/src/features/video/data/video_data_source.dart';
import 'dbku_categories.dart';
import 'dbku_parser.dart';

/// dbku.tv (独播库) — a MacCMS10 site with its JSON collection API disabled,
/// so every call here fetches HTML and hands it to [DbkuParser].
class DbkuDataSource implements VideoDataSource {
  static const String _baseUrl = 'https://www.dbku.tv';

  /// The site is behind Cloudflare and serves the plain HTML to a browser UA.
  /// If it ever turns on a JS challenge, this is the first thing to revisit.
  static const String _userAgent =
      'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/131.0 Safari/537.36';

  /// Grid pages render a fixed 48 items.
  static const int _pageSize = 48;

  /// Play pages fetched at a time by [_resolveEpisodes].
  static const int _resolveBatch = 8;

  final Dio _dio;

  DbkuDataSource(this._dio);

  @override
  String get id => 'dbku';

  @override
  String get name => '测试独播库';

  @override
  Future<List<Category>> getCategories() async {
    return kDbkuCategories;
  }

  @override
  Future<VideoResponse> fetchVideos({
    required int categoryId,
    int? subTypeId,
    String? area,
    String? year,
    int page = 1,
  }) async {
    // subTypeId is ignored: dbku's sub-genre filter keys on a name, not an id
    // (see the note in dbku_categories.dart).
    try {
      final html = await _getHtml(
        _showPath(typeId: categoryId, area: area, year: year, page: page),
      );
      final list = DbkuParser.parseVideoList(html);
      return VideoResponse(
        list: list,
        // ponytail: dbku prints no result count anywhere, so "there is more"
        // is inferred from the page being full. Read a real total off the
        // pagination block if the theme ever grows one.
        total: list.length < _pageSize
            ? (page - 1) * _pageSize + list.length
            : page * _pageSize + 1,
        page: page,
      );
    } on DioException catch (e) {
      logD('Dbku', 'Error fetching videos: $e');
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<Video?> getVideoDetail(int id) async {
    try {
      final html = await _getHtml('/voddetail/$id.html');
      final video = DbkuParser.parseVideoDetail(html, id);
      if (video == null) return null;
      return video.copyWith(urls: await _resolveEpisodes(video.urls ?? const []));
    } on DioException catch (e) {
      logD('Dbku', 'Error fetching video detail: $e');
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<List<Video>> searchVideos(String keyword) async {
    // Only the query-string form works; the path form (/vodsearch/{wd}---...)
    // answers 404 on this template.
    try {
      final html = await _getHtml(
        '/vodsearch/-------------.html',
        query: {'wd': keyword},
      );
      // Search items are a media list with director/cast/region/year/blurb
      // per row — the grid parser would drop all of that.
      return DbkuParser.parseSearchList(html);
    } on DioException catch (e) {
      logD('Dbku', 'Error searching videos: $e');
      throw ApiException.fromDioException(e);
    }
  }

  @override
  String resolveUrl(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }
    return '$_baseUrl${url.startsWith('/') ? '' : '/'}$url';
  }

  /// dbku stores a `/vodplay/` page path per episode and hides the stream URL
  /// in that page's `player_aaaa` blob. Absolute URLs pass straight through,
  /// so this stays safe to call on an episode [getVideoDetail] already
  /// resolved.
  @override
  Future<String?> resolveEpisodeUrl(String url) async {
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    try {
      return DbkuParser.parsePlayUrl(await _getHtml(url));
    } on DioException catch (e) {
      logD('Dbku', 'Error resolving $url: $e');
      return null;
    }
  }

  @override
  Future<String?> getDownloadUrl(Video video, {VideoEpisode? episode}) async {
    final url = (episode ?? video.urls?.firstOrNull)?.url;
    if (url == null) return null;
    final resolved = await resolveEpisodeUrl(url);
    return resolved == null ? null : resolveUrl(resolved);
  }

  // --- internals -----------------------------------------------------------

  Future<String> _getHtml(String path, {Map<String, dynamic>? query}) async {
    final response = await _dio.get<String>(
      '$_baseUrl$path',
      queryParameters: query,
      options: Options(
        responseType: ResponseType.plain,
        headers: const {'User-Agent': _userAgent},
      ),
    );
    return response.data ?? '';
  }

  /// MacCMS filter path: the type id, then 11 dash-joined fields. Only three
  /// of them are wired up here — index 0 area, index 7 page, index 10 year —
  /// which is what the site's own filter bar emits.
  String _showPath({
    required int typeId,
    String? area,
    String? year,
    int page = 1,
  }) {
    final fields = List.filled(11, '');
    if (area != null && area.isNotEmpty) fields[0] = Uri.encodeComponent(area);
    if (page > 1) fields[7] = '$page';
    if (year != null && year.isNotEmpty) fields[10] = year;
    return '/vodshow/$typeId-${fields.join('-')}.html';
  }

  /// Swaps each episode's play-page path for its real stream URL.
  ///
  /// The player feeds [VideoQuality.url] straight into the media stack
  /// (video_player_screen.dart:112), so every episode has to carry a playable
  /// URL by the time this call returns — and dbku hides each one behind its
  /// own `/vodplay/` page. Episodes whose page yields nothing are dropped
  /// rather than shown as broken entries.
  ///
  /// ponytail: [_resolveBatch] requests in flight, so a 32-episode show costs
  /// 4 round trips — paid once, because VideoRepository.getVideo caches the
  /// resolved episodes to drift and both consumers of [VideoEpisode.url] (the
  /// player and the download task builders) read that cache. Deferring to
  /// [resolveEpisodeUrl] per episode would cut the detail fetch to one request
  /// but would cache `/vodplay/` paths instead, moving the cost onto every
  /// play and every "download all".
  Future<List<VideoEpisode>> _resolveEpisodes(List<VideoEpisode> episodes) async {
    final resolved = <VideoEpisode>[];
    for (var i = 0; i < episodes.length; i += _resolveBatch) {
      final batch = episodes.skip(i).take(_resolveBatch).map(_resolveEpisode);
      resolved.addAll(await Future.wait(batch));
    }
    return resolved.where((e) => e.url != null).toList();
  }

  /// Play-page path -> stream URL, remembered for this session. A repeat
  /// detail fetch (the repository's freshness window expired, or another
  /// screen asked) re-parses the episode LIST but only pays a network
  /// request for episodes it has never resolved — for an ongoing show
  /// that's the one new episode instead of the whole run. Session-scoped
  /// on purpose: stream URLs rot on the CDN's schedule, and a restart is
  /// the rot boundary we can afford without persisting timestamps.
  final _resolvedThisSession = <String, String>{};

  Future<VideoEpisode> _resolveEpisode(VideoEpisode episode) async {
    final playPath = episode.url;
    if (playPath == null) return episode;
    final known = _resolvedThisSession[playPath];
    if (known != null) {
      return episode.copyWith(qualities: [VideoQuality(name: '标清', url: known)]);
    }
    final url = await resolveEpisodeUrl(playPath);
    if (url == null) return episode.copyWith(qualities: const []);
    _resolvedThisSession[playPath] = url;
    return episode.copyWith(qualities: [VideoQuality(name: '标清', url: url)]);
  }
}
