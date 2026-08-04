import 'package:drift/drift.dart'; // For Value, OrderingTerm, etc.
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/log.dart';
import '../../../core/utils/ttl_cache.dart';
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

/// The source a fresh install lands on. Must be a real one: the first screen a
/// new user sees is this source's catalog, and a mock catalog there reads as a
/// broken app, not as a demo.
const kDefaultDataSourceId = 'olevod';

final availableDataSourcesProvider = Provider<List<VideoDataSource>>((ref) {
  final dio = ref.watch(dioProvider);
  return [
    OlevodDataSource(dio),
    DbkuDataSource(dio),
    // Fixture data for development only — never offered in a release build.
    if (kDebugMode) MockDataSource(),
  ];
});

class DataSourceIdNotifier extends Notifier<String> {
  @override
  String build() {
    final saved = ref.watch(initialDataSourceIdProvider);
    final sources = ref.watch(availableDataSourcesProvider);
    // A persisted id can outlive its source — 'mock' is registered in debug
    // builds only, so anyone who picked it once would carry a dangling id into
    // release. activeDataSourceProvider falls back to sources.first either way,
    // but leaving the id dangling means the switcher shows a source with no
    // menu entry ticked, and it never heals.
    if (sources.any((s) => s.id == saved)) return saved;
    return sources.first.id;
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

  // --- request caches ------------------------------------------------------
  // Both demo sources ban IPs under request storms, and plain navigation
  // (tab flips, re-entering a detail, repeating a search) used to map
  // one-to-one onto network fetches. Session-scoped and source-keyed; the
  // repository itself is rebuilt on source switch, which resets them.

  /// Whole list responses, keyed by the full query tuple.
  final _listCache = TtlCache<String, Map<String, dynamic>>(
    ttl: const Duration(minutes: 10),
  );

  final _searchCache = TtlCache<String, List<Video>>(
    ttl: const Duration(minutes: 10),
    maxEntries: 32,
  );

  /// When a detail was last fetched from the NETWORK. Guards the
  /// forceRefresh path: the detail screen always asks for fresh data, but
  /// "fresh" within this window is served from the drift cache instead —
  /// on dbku one detail fetch fans out into a play-page request PER
  /// EPISODE, so an unguarded refresh on a 90-episode show was a
  /// 90-request burst every single visit.
  final _detailFreshAt = <String, DateTime>{};
  static const _detailTtl = Duration(minutes: 15);

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
    bool forceRefresh = false,
  }) async {
    final key =
        '${_defaultDataSource.id}|$categoryId|$subTypeId|$area|$year|$page';
    if (!forceRefresh) {
      final cached = _listCache.get(key);
      if (cached != null) return cached;
    }
    final response = await _defaultDataSource.fetchVideos(
      categoryId: categoryId,
      subTypeId: subTypeId,
      area: area,
      year: year,
      page: page,
    );
    final result = {
      'list': response.list,
      'total': response.total,
      'page': response.page,
    };
    _listCache.set(key, result);
    return result;
  }

  Future<Video?> getVideo(
    int apiId, {
    bool forceRefresh = false,
    String? sourceId,
  }) async {
    final sid = sourceId ?? _defaultDataSource.id;
    // A forced refresh inside the freshness window downgrades to a cache
    // read: the caller wants CURRENT data, and data fetched minutes ago is
    // current. See [_detailFreshAt] for why this matters so much on dbku.
    final freshAt = _detailFreshAt['$sid|$apiId'];
    if (forceRefresh &&
        freshAt != null &&
        DateTime.now().difference(freshAt) < _detailTtl) {
      forceRefresh = false;
    }
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
      _detailFreshAt['$sid|$apiId'] = DateTime.now();
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

  Future<List<Video>> searchVideos(String keyword) async {
    final key = '${_defaultDataSource.id}|$keyword';
    final cached = _searchCache.get(key);
    if (cached != null) return cached;
    final result = await _defaultDataSource.searchVideos(keyword);
    _searchCache.set(key, result);
    return result;
  }

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
