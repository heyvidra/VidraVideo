import 'dart:io' show HttpDate;

import 'package:dio/dio.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/telemetry/telemetry.dart';
import '../../../../core/utils/log.dart';
import 'package:vidra/src/features/video/domain/category.dart';
import 'package:vidra/src/features/video/domain/video_collection.dart';
import 'package:vidra/src/features/video/data/video_data_source.dart';
import 'olevod_categories.dart';
import 'video_signature_helper.dart';
import 'olevod_dto.dart';

class OlevodDataSource implements VideoDataSource {
  static const String _apiBaseUrl = 'https://api.olelive.com';
  static const String _cdnBaseUrl = 'https://www.olevod.com';

  final Dio _dio;

  /// How far this machine's clock is from the API server's. Stays zero on a
  /// correctly-set machine; [_signedGet] fills it in on the first rejection.
  Duration _skew = Duration.zero;

  /// Response shapes already reported this run, keyed by endpoint and field.
  /// An API that answers the wrong shape answers it for every page and every
  /// retry, so the second event would only repeat the first.
  static final _reportedShapes = <String>{};

  /// The skew is learned once and reused for the rest of the run, so it is
  /// reported once too.
  static bool _reportedSkew = false;

  OlevodDataSource(this._dio);

  /// GET with a `_vv` signature, retried once against the server's own clock.
  ///
  /// The signature is a function of the current Unix second and the API only
  /// accepts about an hour of drift, so a device whose clock (or time zone) is
  /// wrong gets 401 on every call. Every response carries a `Date` header, so
  /// the rejection itself says what time the server thinks it is: learn the
  /// offset from it and sign again. One bad request per app run, then correct
  /// for good — no user action, and it works in any time zone.
  Future<Response<dynamic>> _signedGet(String path) async {
    try {
      return await _dio.get(
        path,
        queryParameters: {'_vv': VideoSignatureHelper.generate(_now())},
      );
    } on DioException catch (e) {
      final response = e.response;
      if (response == null || !_learnSkew(response)) rethrow;
      logR('Olevod', 'Clock is off by $_skew, re-signing against server time');
      // A machine whose clock is wrong is a field condition nothing else
      // reveals, and the offset is the whole of it — whole minutes, signed.
      if (!_reportedSkew) {
        _reportedSkew = true;
        Telemetry.report(
          'olevod.clock_skew',
          data: {'skew_minutes': _skew.inMinutes},
        );
      }
      return _dio.get(
        path,
        queryParameters: {'_vv': VideoSignatureHelper.generate(_now())},
      );
    }
  }

  DateTime _now() => DateTime.now().add(_skew);

  /// Returns true when [response] moved [_skew] enough to be worth a retry.
  bool _learnSkew(Response<dynamic> response) {
    final date = response.headers.value('date');
    if (date == null) return false;
    final DateTime serverTime;
    try {
      serverTime = HttpDate.parse(date);
    } on Exception {
      return false;
    }
    final skew = serverTime.difference(DateTime.now());
    // A minute of drift is well inside what the API tolerates; anything less
    // is not what a 401 was about, and retrying would just fail again.
    if ((skew - _skew).abs() < const Duration(minutes: 1)) return false;
    _skew = skew;
    return true;
  }

  /// Reports a response that arrived but did not carry what the parser needs.
  ///
  /// Shapes only: the fixed endpoint label, the API's own `code`, the HTTP
  /// status, and WHICH field was missing or the wrong type. Never the request
  /// path — it spells out the category, area and year being browsed — and
  /// never any part of the payload.
  void _reportShape(
    String endpoint, {
    required String field,
    String? errorType,
    Object? code,
    int? status,
    bool? hadFilters,
  }) {
    if (!_reportedShapes.add('$endpoint/$field/$errorType')) return;
    Telemetry.report(
      'catalog.shape',
      data: {
        'endpoint': endpoint,
        'field': field,
        'error': ?errorType,
        // `code` has been an int in every response seen. If it ever is not,
        // its type is the diagnostic part and its value may be an echo of the
        // request, so only the type goes out.
        if (code != null)
          'code': code is int ? code : code.runtimeType.toString(),
        'status': ?status,
        'had_filters': ?hadFilters,
      },
    );
  }

  @override
  String get id => 'olevod';

  @override
  String get name => '测试欧乐影院';

  @override
  Future<List<Category>> getCategories() async {
    return kVideoCategories;
  }

  @override
  Future<VideoResponse> fetchVideos({
    required int categoryId,
    int? subTypeId,
    String? area,
    String? year,
    int page = 1,
  }) async {
    final catIdStr = categoryId.toString();
    final subIdStr = (subTypeId ?? 0).toString();
    final areaStr = area == null ? '0' : Uri.encodeComponent(area);
    final yearStr = year ?? '0';

    final path =
        '$_apiBaseUrl/v1/pub/vod/list/true/3/0/$areaStr/$catIdStr/$subIdStr/$yearStr/update/$page/48';

    // A boolean, never the filters themselves: their values are the category,
    // area and year this person was browsing.
    final hadFilters = subTypeId != null || area != null || year != null;

    // Network errors propagate as ApiException so the UI can distinguish
    // "no results" from "request failed".
    try {
      final response = await _signedGet(path);
      if (response.statusCode == 200) {
        final data = response.data;
        if (data['code'] == 0) {
          // A filter combination with no matches comes back as "list": null
          // (seen with 综艺+英国), not an empty list — every field here is
          // optional-by-observation.
          final payload = data['data'] as Map<String, dynamic>?;
          final listData = payload?['list'] as List?;
          if (listData == null) {
            _reportShape(
              'olevod.fetchVideos',
              field: payload == null ? 'data' : 'data.list',
              code: data['code'],
              status: response.statusCode,
              hadFilters: hadFilters,
            );
          }
          final videos = (listData ?? const [])
              .map((e) => OlevodVideoDto.fromJson(e).toDomain(resolveUrl))
              .where((v) => v.vip != true)
              .toList();
          return VideoResponse(
            list: videos,
            total: payload?['total'] ?? videos.length,
            page: payload?['page'] ?? page,
          );
        }
        // The request arrived, the catalog still renders empty: the refusal
        // code is the only thing that says why.
        _reportShape(
          'olevod.fetchVideos',
          field: 'code',
          code: data['code'],
          status: response.statusCode,
          hadFilters: hadFilters,
        );
      }
      return VideoResponse(list: [], total: 0, page: 1);
    } on DioException catch (e) {
      logR(
        'Olevod',
        'fetchVideos failed: ${e.response?.statusCode} ${e.response?.data} '
            '(path=$path skew=$_skew)',
      );
      throw ApiException.fromDioException(e);
    } catch (e) {
      // Not a transport failure, so it is the payload this code could not
      // read — the class of bug where a cast meets a field the API changed and
      // takes the whole catalog page down with it. Rethrown untouched;
      // reporting only makes it visible.
      _reportShape(
        'olevod.fetchVideos',
        field: 'body',
        errorType: e.runtimeType.toString(),
        hadFilters: hadFilters,
      );
      rethrow;
    }
  }

  @override
  Future<Video?> getVideoDetail(int id, {String? sourceKey}) async {
    final path = '$_apiBaseUrl/v1/pub/vod/detail/$id/true';

    try {
      final response = await _signedGet(path);
      if (response.statusCode == 200) {
        final data = response.data;
        if (data['code'] == 0) {
          dynamic videoData = data['data'];
          if (videoData is List && videoData.isNotEmpty) {
            videoData = videoData.first;
          }
          if (videoData is! Map<String, dynamic>) {
            _reportShape(
              'olevod.getVideoDetail',
              field: 'data',
              errorType: videoData.runtimeType.toString(),
              code: data['code'],
              status: response.statusCode,
            );
            return null;
          }
          return OlevodVideoDto.fromJson(videoData).toDomain(resolveUrl);
        }
        _reportShape(
          'olevod.getVideoDetail',
          field: 'code',
          code: data['code'],
          status: response.statusCode,
        );
      }
      return null;
    } on DioException catch (e) {
      logD('Olevod', 'Error fetching video detail: $e');
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<List<Video>> searchVideos(String keyword) async {
    final encodedKeyword = Uri.encodeComponent(keyword);
    final path = '$_apiBaseUrl/v1/pub/index/search/$encodedKeyword/vod/0/1/4';

    try {
      final response = await _signedGet(path);
      if (response.statusCode == 200) {
        final data = response.data;
        if (data['code'] == 0) {
          final outerData = data['data'];
          if (outerData != null && outerData['data'] is List) {
            final dataList = outerData['data'] as List;
            for (final item in dataList) {
              if (item['type'] == 'vod' && item['list'] is List) {
                final videoList = item['list'] as List;
                return videoList
                    .map((e) => OlevodVideoDto.fromJson(e).toDomain(resolveUrl))
                    .where((v) => v.vip != true)
                    .toList();
              }
            }
          } else {
            // The buckets this walks are gone or are no longer a list; search
            // then answers "nothing found" for every keyword.
            _reportShape(
              'olevod.searchVideos',
              field: outerData == null ? 'data' : 'data.data',
              code: data['code'],
              status: response.statusCode,
            );
          }
        }
      }
      return [];
    } on DioException catch (e) {
      logD('Olevod', 'Error searching videos: $e');
      throw ApiException.fromDioException(e);
    }
  }

  @override
  String resolveUrl(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }
    return '$_cdnBaseUrl/$url';
  }

  // Olevod's detail payload already carries stream URLs, so nothing to resolve.
  @override
  Future<String?> resolveEpisodeUrl(String url) async => url;

  // The API host, not the CDN one: it is what every catalog call waits on.
  @override
  String? get pingHost => 'api.olelive.com';

  // Happy with the player's default headers.
  @override
  Map<String, String>? get streamHeaders => null;

  @override
  Future<String?> getDownloadUrl(Video video, {VideoEpisode? episode}) async {
    final targetEpisode = episode ?? video.urls?.firstOrNull;
    if (targetEpisode == null || targetEpisode.url == null) return null;
    return resolveUrl(targetEpisode.url!);
  }
}
