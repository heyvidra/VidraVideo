import 'package:dio/dio.dart';
import '../../../../core/network/api_exception.dart';
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

  OlevodDataSource(this._dio);

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
    final sign = VideoSignatureHelper.generate();

    // Network errors propagate as ApiException so the UI can distinguish
    // "no results" from "request failed".
    try {
      final response = await _dio.get(path, queryParameters: {'_vv': sign});
      if (response.statusCode == 200) {
        final data = response.data;
        if (data['code'] == 0) {
          final listData = data['data']['list'] as List;
          final videos = listData
              .map((e) => OlevodVideoDto.fromJson(e).toDomain(resolveUrl))
              .where((v) => v.vip != true)
              .toList();
          return VideoResponse(
            list: videos,
            total: data['data']['total'],
            page: data['data']['page'],
          );
        }
      }
      return VideoResponse(list: [], total: 0, page: 1);
    } on DioException catch (e) {
      // The signature is a function of the clock, so the timestamp that fed it
      // is the first thing worth seeing when the server rejects a request.
      logR(
        'Olevod',
        'fetchVideos failed: ${e.response?.statusCode} ${e.response?.data} '
        '(path=$path sign=$sign now=${DateTime.now().toUtc().toIso8601String()})',
      );
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<Video?> getVideoDetail(int id) async {
    final path = '$_apiBaseUrl/v1/pub/vod/detail/$id/true';
    final sign = VideoSignatureHelper.generate();

    try {
      final response = await _dio.get(path, queryParameters: {'_vv': sign});
      if (response.statusCode == 200) {
        final data = response.data;
        if (data['code'] == 0) {
          dynamic videoData = data['data'];
          if (videoData is List && videoData.isNotEmpty) {
            videoData = videoData.first;
          }
          if (videoData is! Map<String, dynamic>) {
            return null;
          }
          return OlevodVideoDto.fromJson(videoData).toDomain(resolveUrl);
        }
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
    final sign = VideoSignatureHelper.generate();

    try {
      final response = await _dio.get(path, queryParameters: {'_vv': sign});
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

  @override
  Future<String?> getDownloadUrl(Video video, {VideoEpisode? episode}) async {
    final targetEpisode = episode ?? video.urls?.firstOrNull;
    if (targetEpisode == null || targetEpisode.url == null) return null;
    return resolveUrl(targetEpisode.url!);
  }
}
