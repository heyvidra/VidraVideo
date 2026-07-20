import 'package:drift/drift.dart'; // For Value, OrderingTerm, etc.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/log.dart';
import '../../../data/database/app_database.dart' as db;
import '../../../data/database/app_database_provider.dart';
import '../../../data/database/mappers.dart';
import '../../../core/network/dio_provider.dart';
import '../domain/video_collection.dart';
import '../domain/video_settings.dart';
import '../domain/category.dart'; // Relative to this file
import '../../settings/presentation/settings_provider.dart';
import 'video_data_source.dart';
import 'demo_dbku/dbku_data_source.dart';
import 'demo_olevod/olevod_data_source.dart';
import 'mock/mock_data_source.dart';

// Providers
final initialDataSourceIdProvider = Provider<String>((ref) {
  throw UnimplementedError('initialDataSourceIdProvider must be overridden');
});

final availableDataSourcesProvider = Provider<List<VideoDataSource>>((ref) {
  final dio = ref.watch(dioProvider);
  return [OlevodDataSource(dio), DbkuDataSource(dio), MockDataSource()];
});

class DataSourceIdNotifier extends Notifier<String> {
  @override
  String build() {
    return ref.watch(initialDataSourceIdProvider);
  }

  Future<void> setSource(String id) async {
    state = id;
    final settingsRepo = ref.read(settingsRepositoryProvider);
    final settings = await settingsRepo.getSettings();
    settings.lastDataSourceId = id;
    await settingsRepo.updateSettings(settings);
  }
}

final activeDataSourceIdProvider =
    NotifierProvider<DataSourceIdNotifier, String>(DataSourceIdNotifier.new);

final activeDataSourceProvider = Provider<VideoDataSource>((ref) {
  final sources = ref.watch(availableDataSourcesProvider);
  final activeId = ref.watch(activeDataSourceIdProvider);
  return sources.firstWhere(
    (s) => s.id == activeId,
    orElse: () => sources.first,
  );
});

final videoRepositoryProvider = Provider<VideoRepository>((ref) {
  final dataSource = ref.watch(activeDataSourceProvider);
  final allSources = ref.watch(availableDataSourcesProvider);
  final database = ref.watch(appDatabaseProvider);
  return VideoRepository(dataSource, allSources, database);
});

class VideoRepository {
  final VideoDataSource _defaultDataSource;
  final List<VideoDataSource> _allDataSources;
  final db.AppDatabase _db;

  db.AppDatabase get database => _db;

  VideoRepository(this._defaultDataSource, this._allDataSources, this._db);

  VideoDataSource _getDataSource(String? sourceId) {
    if (sourceId == null) return _defaultDataSource;
    return _allDataSources.firstWhere(
      (s) => s.id == sourceId,
      orElse: () => _defaultDataSource,
    );
  }

  Future<List<Category>> getCategories() => _defaultDataSource.getCategories();

  Future<Map<String, dynamic>> fetchVideos({
    required int categoryId,
    int? subTypeId,
    String? area,
    String? year,
    int page = 1,
  }) async {
    final response = await _defaultDataSource.fetchVideos(
      categoryId: categoryId,
      subTypeId: subTypeId,
      area: area,
      year: year,
      page: page,
    );
    return {
      'list': response.list,
      'total': response.total,
      'page': response.page,
    };
  }

  Future<Video?> getVideo(
    int apiId, {
    bool forceRefresh = false,
    String? sourceId,
  }) async {
    final sid = sourceId ?? _defaultDataSource.id;
    // 1. Check local cache if not forcing refresh
    if (!forceRefresh) {
      try {
        final cached =
            await (_db.select(
                  _db.videos,
                )..where((t) => t.sourceId.equals(sid) & t.apiId.equals(apiId)))
                .getSingleOrNull();

        // Check if urls exist efficiently?
        // cached.urls is loaded.
        if (cached != null) {
          final domainVideo = cached.toDomain();
          if (domainVideo.urls?.isNotEmpty ?? false) {
            return domainVideo;
          }
        }
      } catch (e) {
        // Log error?
      }
    }

    final ds = _getDataSource(sid);
    var video = await ds.getVideoDetail(apiId);
    if (video != null) {
      // Ensure sourceId is set for the local DB
      video = video.copyWith(sourceId: sid);
      // 2. Save to DB
      try {
        video = await _db.transaction(() async {
          final existing =
              await (_db.select(_db.videos)..where(
                    (t) => t.sourceId.equals(sid) & t.apiId.equals(apiId),
                  ))
                  .getSingleOrNull();

          // Preserve local ID if the row already exists
          var v = video!.copyWith(id: existing?.id);
          final newId = await _db
              .into(_db.videos)
              .insert(v.toCompanion(), mode: InsertMode.insertOrReplace);
          return v.copyWith(id: newId);
        });
      } catch (e) {
        logR("getVideo", e.toString());
      }
    }
    return video;
  }

  // Video Settings methods
  Future<VideoSettings> getVideoSettings(int videoId, String? sourceId) async {
    final sid = sourceId ?? _defaultDataSource.id;
    final settings =
        await (_db.select(
              _db.videoSettings,
            )..where((t) => t.sourceId.equals(sid) & t.videoId.equals(videoId)))
            .getSingleOrNull();

    return settings?.toDomain() ??
        VideoSettings(videoId: videoId, sourceId: sid);
  }

  Future<void> saveVideoSettings(VideoSettings settings) async {
    await _db
        .into(_db.videoSettings)
        .insert(settings.toCompanion(), mode: InsertMode.insertOrReplace);
  }

  // Play history lives in HistoryRepository (history_repository.dart).

  Future<List<Video>> searchVideos(String keyword) =>
      _defaultDataSource.searchVideos(keyword);

  String resolveUrl(String url, {String? sourceId}) {
    final ds = _getDataSource(sourceId);
    return ds.resolveUrl(url);
  }

  Future<String?> getDownloadUrl(Video video, {VideoEpisode? episode}) =>
      _getDataSource(video.sourceId).getDownloadUrl(video, episode: episode);
}

final searchVideosProvider = FutureProvider.autoDispose
    .family<List<Video>, String>((ref, keyword) async {
      final repo = ref.watch(videoRepositoryProvider);
      return await repo.searchVideos(keyword);
    });

final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  final repo = ref.watch(videoRepositoryProvider);
  return await repo.getCategories();
});

final videoByIdProvider = FutureProvider.autoDispose
    .family<Video?, ({int id, String? sourceId})>((ref, arg) async {
      final repo = ref.watch(videoRepositoryProvider);
      return await repo.getVideo(
        arg.id,
        forceRefresh: true,
        sourceId: arg.sourceId,
      );
    });

final cachedVideoByIdProvider = FutureProvider.autoDispose
    .family<Video?, ({int id, String? sourceId})>((ref, arg) async {
      final repo = ref.watch(videoRepositoryProvider);
      return await repo.getVideo(arg.id, sourceId: arg.sourceId);
    });
