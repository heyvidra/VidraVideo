import 'dart:io';

import 'package:dio/dio.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/telemetry/telemetry.dart';
import '../../../../core/utils/log.dart';
import 'package:vidra/src/features/video/domain/category.dart';
import 'package:vidra/src/features/video/domain/video_collection.dart';
import 'package:vidra/src/features/video/data/video_data_source.dart';
import 'yfsp_categories.dart';
import 'yfsp_dto.dart';
import 'yfsp_signer.dart';

/// yfsp.tv (爱壹帆) — a signed JSON API. See [YfspSigner] for the signature.
///
/// Two things shape everything here:
///
/// * **Shows are keyed by a string.** `PwLAKyPFpPE`, 11 base62 characters, and
///   no endpoint trades a number for one. So [Video.apiId] is only a local
///   handle ([yfspHandle]) and the real key travels in [Video.sourceKey],
///   which the repository replays into [getVideoDetail]. Given neither, this
///   source can answer nothing — that is the correct failure, not a guess.
/// * **The API rate-limits, and it bites.** A burst of a dozen `video/play`
///   calls answers `code:5 访问过量` and pushes the browser session into a bot
///   challenge; keep it up and the host drops connections at the TLS
///   handshake. That is why episode stream URLs are NOT resolved up front the
///   way dbku resolves its play pages: a 60-episode short drama would be 60
///   requests on every detail open. Episodes carry a `yfsp://` placeholder and
///   are exchanged one at a time by [resolveEpisodeUrl], at the moment
///   playback starts.
class YfspDataSource implements VideoDataSource {
  YfspDataSource(this._dio) : _signer = YfspSigner(_dio);

  final Dio _dio;
  final YfspSigner _signer;

  static const String _apiM10 = 'https://m10.yfsp.tv/api';
  static const String _apiV3 = 'https://m10.yfsp.tv/v3';

  /// What the site's own list page asks for.
  static const int _pageSize = 35;

  /// `list/Search` answers `maxpage:30` no matter how large `recordcount` is,
  /// and page 31 comes back empty. Reporting the raw count would leave the
  /// grid asking for pages the API will never serve.
  static const int _maxPage = 30;

  /// Show key -> class path ("0,1,4,131"), learned from whatever listed the
  /// show. The episode playlist call needs it and the detail response carries
  /// it, so this is only a shortcut, never the sole copy.
  final _classPathByKey = <String, String>{};

  /// Placeholder -> minted stream URL, for this run only. Re-opening the
  /// episode you just watched must not spend another mint against the rate
  /// limit; a restart is the right expiry boundary, since the URLs the mint
  /// returns carry roughly two days of `vendtime` and nothing persists them.
  final _resolvedThisSession = <String, String>{};

  /// Report signatures already sent this run.
  static final _reported = <String>{};

  @override
  String get id => 'yfsp';

  @override
  String get name => '测试爱壹帆';

  @override
  Future<List<Category>> getCategories() async => kYfspCategories;

  @override
  Future<VideoResponse> fetchVideos({
    required int categoryId,
    int? subTypeId,
    String? area,
    String? year,
    int page = 1,
  }) async {
    // The catalog filters on the class PATH, not on the leaf id: `cid=4`
    // matches nothing, `cid=0,1,4` is 电视剧 and `cid=0,1,4,131` is its 青春
    // sub-genre. (`label`, which reads like the sub-genre filter, is accepted
    // and ignored by the server — do not reach for it.)
    final cid = subTypeId == null
        ? '0,1,$categoryId'
        : '0,1,$categoryId,$subTypeId';

    final info = await _get('$_apiM10/list/Search', {
      'cinema': '1',
      'tags': '',
      'orderby': '0',
      'page': '$page',
      'size': '$_pageSize',
      'desc': '1',
      'cid': cid,
      'label': '',
      'year': year ?? '',
      'language': '',
      'region': area ?? '',
      'isserial': '-1',
      'isIndex': '-1',
      'isfree': '-1',
    }, endpoint: 'yfsp.fetchVideos', hadFilters: area != null || year != null);

    final bucket = info.isEmpty ? null : info.first as Map<String, dynamic>?;
    final rows = bucket?['result'] as List?;
    if (rows == null && page == 1) {
      _report(
        'yfsp.fetchVideos',
        field: bucket == null ? 'info' : 'info.result',
        extra: {'had_filters': area != null || year != null},
      );
    }

    final list = (rows ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(YfspListItemDto.new)
        .where((d) => d.key.isNotEmpty)
        .map((d) {
          final path = d.videoClassID;
          if (path != null) _classPathByKey[d.key] = path;
          return d.toDomain();
        })
        .toList();

    final count = (bucket?['recordcount'] as num?)?.toInt() ?? list.length;
    return VideoResponse(
      list: list,
      total: count.clamp(0, _maxPage * _pageSize),
      page: page,
    );
  }

  @override
  Future<List<Video>> searchVideos(String keyword) async {
    final info = await _get('$_apiM10/list/Search', {
      'cinema': '1',
      'tags': keyword,
      'orderby': '0',
      'page': '1',
      'size': '$_pageSize',
      'desc': '1',
      'cid': '',
      'label': '',
      'year': '',
      'language': '',
      'region': '',
      'isserial': '-1',
      'isIndex': '-1',
      'isfree': '-1',
    }, endpoint: 'yfsp.searchVideos');

    final bucket = info.isEmpty ? null : info.first as Map<String, dynamic>?;
    final rows = bucket?['result'] as List?;
    return (rows ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(YfspListItemDto.new)
        .where((d) => d.key.isNotEmpty)
        .map((d) {
          final path = d.videoClassID;
          if (path != null) _classPathByKey[d.key] = path;
          return d.toDomain();
        })
        .toList();
  }

  @override
  Future<Video?> getVideoDetail(int id, {String? sourceKey}) async {
    final key = sourceKey ?? _keyFromSession(id);
    if (key == null) {
      // Nothing to ask about. Happens when a row cached before this source
      // stored keys is reopened; browsing to the show again repairs it.
      _report('yfsp.getVideoDetail', field: 'sourceKey');
      return null;
    }

    final info = await _get('$_apiV3/video/detail', {
      'cinema': '1',
      'device': '1',
      'id': key,
      'region': 'GL.',
    }, endpoint: 'yfsp.getVideoDetail');

    final row = info.isEmpty ? null : info.first;
    if (row is! Map<String, dynamic>) {
      _report(
        'yfsp.getVideoDetail',
        field: 'info',
        extra: {'type': row.runtimeType.toString()},
      );
      return null;
    }

    final dto = YfspDetailDto(row);
    final classPath = dto.cid ?? _classPathByKey[key];
    if (classPath != null) _classPathByKey[key] = classPath;

    return dto.toDomain(await _episodes(key, classPath));
  }

  /// The episode list. One request, no matter how long the show — the stream
  /// URLs behind it stay unresolved until playback.
  Future<List<VideoEpisode>> _episodes(String key, String? classPath) async {
    final info = await _get('$_apiV3/video/languagesplaylist', {
      'cinema': '1',
      'vid': key, // NOT `id` — that spelling answers an empty list.
      'lsk': '1',
      'taxis': '0',
      'cid': classPath ?? '',
    }, endpoint: 'yfsp.episodes');

    final bucket = info.isEmpty ? null : info.first as Map<String, dynamic>?;
    final rows = bucket?['playList'] as List?;
    if (rows == null || rows.isEmpty) {
      _report('yfsp.episodes', field: 'playList');
      return const [];
    }
    return rows
        .whereType<Map<String, dynamic>>()
        .toList()
        .asMap()
        .entries
        .map((e) => yfspEpisode(e.value, e.key))
        .toList();
  }

  /// Exchanges a `yfsp://<episodeKey>` placeholder for a playable URL.
  ///
  /// Idempotent: an http(s) URL — an already-resolved episode, or a source
  /// that never had a placeholder — is handed straight back.
  @override
  Future<String?> resolveEpisodeUrl(String url) async {
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    if (!url.startsWith(kYfspEpisodeScheme)) return null;

    final known = _resolvedThisSession[url];
    if (known != null) return known;

    final key = url.substring(kYfspEpisodeScheme.length);
    final info = await _get('$_apiV3/video/play', {
      'cinema': '1',
      'id': key,
      // a=0 says "id is an EPISODE key". a=1 says "id is a SHOW key" and
      // returns its first episode; passing the wrong one answers 视频不存在.
      'a': '0',
      'usersign': '1',
      'region': 'GL.',
      'device': '1',
      'isMasterSupport': '1',
    }, endpoint: 'yfsp.resolveEpisodeUrl');

    final row = info.isEmpty ? null : info.first;
    if (row is! Map<String, dynamic>) return null;

    final stream = yfspPickStream(row['flvPathList']);
    if (stream == null) {
      _report('yfsp.resolveEpisodeUrl', field: 'flvPathList');
      return null;
    }

    final playable = await _playable(stream);
    if (playable != null) _resolvedThisSession[url] = playable;
    return playable;
  }

  /// Turns the CDN url into something the player can actually open.
  ///
  /// Every request to this CDN has to be signed — segments included — and an
  /// unsigned one is answered by RESETTING the connection, so a player handed
  /// the raw playlist stalls on segment after segment and eventually reports
  /// "failed to open media" with nothing in the log to say why. The player
  /// fetches segments itself and cannot be taught to sign them, so the
  /// playlist is fetched here, every URI in it signed, and the result handed
  /// over as a local file. Signatures carry no expiry of their own — the
  /// `vendtime` already in each url is the clock, roughly two days — so one
  /// pass holds for the whole session.
  ///
  /// A non-playlist url (the mp4 fallback) just gets signed and returned.
  Future<String?> _playable(String stream) async {
    final signed = await _signer.signExisting(stream);
    if (!Uri.parse(stream).path.toLowerCase().endsWith('.m3u8')) return signed;

    final String body;
    try {
      final response = await _dio.get<String>(
        signed,
        options: Options(
          responseType: ResponseType.plain,
          headers: const {
            'User-Agent': YfspSigner.userAgent,
            'Referer': YfspSigner.referer,
          },
        ),
      );
      body = response.data ?? '';
    } on DioException catch (e) {
      logD('Yfsp', 'playlist fetch failed: $e');
      _report('yfsp.playlist', field: 'request', extra: {'type': e.type.name});
      return null;
    }
    if (!body.contains('#EXTM3U')) {
      _report('yfsp.playlist', field: 'body');
      return null;
    }

    // Signing is async (it may have to re-scrape the key pair) while the
    // rewrite is not, so the keys are warmed by the fetch above and every URI
    // below signs from the cached pair without another await.
    final playlistUrl = Uri.parse(signed);
    final rewritten = signHlsPlaylist(
      playlist: body,
      playlistUrl: playlistUrl,
      signUri: (target) => _signer.signExistingSync(target.toString()),
    );

    // Directory.systemTemp, not path_provider: this needs no platform channel,
    // so the whole resolve path stays runnable under `flutter test` — which is
    // where this feature's only end-to-end check lives.
    final dir = Directory('${Directory.systemTemp.path}/vidra_yfsp')
      ..createSync(recursive: true);
    final file = File('${dir.path}/${yfspHandle(playlistUrl.path)}.m3u8');
    await file.writeAsString(rewritten);
    return file.path;
  }

  @override
  Future<String?> getDownloadUrl(Video video, {VideoEpisode? episode}) async {
    final url = (episode ?? video.urls?.firstOrNull)?.url;
    if (url == null) return null;
    return resolveEpisodeUrl(url);
  }

  /// The API host. Measured by connect, never by a request — see
  /// [VideoDataSource.pingHost]. This is the source whose rate limiter made
  /// that rule necessary.
  @override
  String? get pingHost => 'm10.yfsp.tv';

  /// A user agent and nothing else.
  ///
  /// The stream CDN (global.dudupro.com) answers 520 to a request with no
  /// user agent AND to one whose `Referer` names the CDN itself — which is
  /// exactly the pair the player guesses by default, so the guess had to be
  /// replaced rather than extended. Measured: bare 520, `UA` 200,
  /// `UA + Referer: https://global.dudupro.com/` 520.
  @override
  Map<String, String>? get streamHeaders => const {
    'User-Agent': YfspSigner.userAgent,
  };

  @override
  String resolveUrl(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    return 'https://www.yfsp.tv${url.startsWith('/') ? '' : '/'}$url';
  }

  // --- internals -----------------------------------------------------------

  /// Recovers a key for a handle from what this run has already listed. Only a
  /// fallback for a caller with no cached row to replay; [Video.sourceKey] is
  /// the durable copy.
  String? _keyFromSession(int handle) {
    for (final key in _classPathByKey.keys) {
      if (yfspHandle(key) == handle) return key;
    }
    return null;
  }

  /// Signed GET returning the payload's `info` list.
  ///
  /// Retries once on a signature refusal: the key pair is scraped from a page
  /// and rotates, so the FIRST call after a rotation is expected to fail and
  /// re-scraping is the fix. Nothing else is retried — a rate-limit refusal in
  /// particular must not be, since retrying is what deepens it.
  Future<List<dynamic>> _get(
    String base,
    Map<String, String> params, {
    required String endpoint,
    bool? hadFilters,
    bool retried = false,
  }) async {
    final Response<dynamic> response;
    try {
      response = await _dio.getUri(
        Uri.parse(await _signer.sign(base, params)),
        options: Options(
          headers: const {
            'User-Agent': YfspSigner.userAgent,
            'Referer': YfspSigner.referer,
          },
        ),
      );
    } on DioException catch (e) {
      logD('Yfsp', '$endpoint failed: $e');
      throw ApiException.fromDioException(e);
    }

    final body = response.data;
    final data = body is Map<String, dynamic>
        ? body['data'] as Map<String, dynamic>?
        : null;
    if (data == null) {
      _report(endpoint, field: 'data', extra: {'status': response.statusCode});
      return const [];
    }

    final code = data['code'];
    if (code == 0) return (data['info'] as List?) ?? const [];

    final msg = data['msg']?.toString() ?? '';

    // code 1 covers every refusal the API bothers to phrase; only the
    // signature one is worth another request.
    if (code == 1 && msg.contains('签名') && !retried) {
      logD('Yfsp', 'Signature rejected, re-scraping keys');
      _signer.invalidate();
      return _get(
        base,
        params,
        endpoint: endpoint,
        hadFilters: hadFilters,
        retried: true,
      );
    }

    // code 5 is the rate limiter, and in the browser it redirects to a bot
    // challenge. Surfaced as an error rather than as an empty catalog: the
    // user needs to know to stop, and a silent empty screen invites exactly
    // the retrying that makes it worse.
    if (code == 5) {
      _report(endpoint, field: 'rate_limited');
      throw ApiException(message: '爱壹帆访问过于频繁，请稍后再试');
    }

    _report(
      endpoint,
      field: 'code',
      extra: {
        'code': code is int ? code : code.runtimeType.toString(),
        'status': response.statusCode,
        'had_filters': ?hadFilters,
      },
    );
    return const [];
  }

  /// Reports a response that arrived but did not carry what the parser needs.
  ///
  /// Fixed labels and shapes only, once per signature per run. Never a path or
  /// a title: those name the show somebody opened.
  void _report(
    String endpoint, {
    required String field,
    Map<String, Object?> extra = const {},
  }) {
    if (!_reported.add('$endpoint/$field')) return;
    Telemetry.report(
      'catalog.shape',
      data: {'endpoint': endpoint, 'field': field, ...extra},
    );
  }
}
