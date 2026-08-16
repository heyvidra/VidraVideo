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
import '../domain/episode_number.dart';
import '../domain/play_history.dart' show isEpisodicType, crossSourceKey;
import '../domain/search_hit.dart';
import '../domain/video_settings.dart';
import '../domain/category.dart'; // Relative to this file
import '../../settings/domain/app_settings.dart' show formatSourceIds;
import '../../settings/presentation/settings_provider.dart';
import 'video_data_source.dart';
import 'demo_dbku/dbku_data_source.dart';
import 'demo_olevod/olevod_data_source.dart';
import 'yfsp/yfsp_data_source.dart';
import 'mock/mock_data_source.dart';

// Providers
final initialDataSourceIdProvider = Provider<String>((ref) {
  throw UnimplementedError('initialDataSourceIdProvider must be overridden');
});

/// The source a fresh install lands on. Must be a real one: the first screen a
/// new user sees is this source's catalog, and a mock catalog there reads as a
/// broken app, not as a demo.
const kDefaultDataSourceId = 'olevod';

/// The switched-off set as of app start, so the first frame is already right.
///
/// Overridden in `main()` from the settings row that bootstrap already reads.
/// Without it the dashboard would paint every source for one frame and then
/// drop the disabled ones — the same flash [ReduceEffects.seed] exists to
/// avoid. Left empty in tests, which is the "nothing disabled" default.
final initialDisabledDataSourceIdsProvider = Provider<Set<String>>(
  (ref) => const {},
);

/// Which sources the user has switched off.
///
/// Seeded from bootstrap and updated imperatively on toggle — deliberately NOT
/// derived from the settings STREAM, even though that would be less code.
/// [availableDataSourcesProvider] is read all over the widget tree, and wiring
/// it to a drift stream drags a live database subscription into every screen
/// that renders a source; the widget tests caught it first, failing with "a
/// Timer is still pending after the widget tree was disposed". The active
/// source id next door has the same shape for the same reason — see
/// [DataSourceIdNotifier], whose `setSource` this mirrors.
class DisabledDataSourceIdsNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => ref.watch(initialDisabledDataSourceIdsProvider);

  /// Switches [id] on or off and persists it.
  ///
  /// State moves first so the switch and the screens behind it flip together;
  /// the write follows. A failed write costs the setting on the next launch,
  /// not the frame the user is looking at.
  Future<void> setEnabled(String id, bool enabled) async {
    final next = {...state};
    if (enabled) {
      next.remove(id);
    } else {
      next.add(id);
    }
    if (next.length == state.length) return;
    state = next;

    final repo = ref.read(settingsRepositoryProvider);
    final settings = await repo.getSettings();
    settings.disabledDataSourceIds = formatSourceIds(next);
    await repo.updateSettings(settings);
  }
}

final disabledDataSourceIdsProvider =
    NotifierProvider<DisabledDataSourceIdsNotifier, Set<String>>(
      DisabledDataSourceIdsNotifier.new,
    );

/// Every source the build ships, switched off ones included.
///
/// Only the settings screen wants this: it has to list a source in order to
/// offer the switch that turns it back on. Everything else wants
/// [availableDataSourcesProvider].
final allDataSourcesProvider = Provider<List<VideoDataSource>>((ref) {
  final dio = ref.watch(dioProvider);
  return [
    OlevodDataSource(dio),
    DbkuDataSource(dio),
    YfspDataSource(dio),
    // Fixture data for development only — never offered in a release build.
    if (kDebugMode) MockDataSource(),
  ];
});

final availableDataSourcesProvider = Provider<List<VideoDataSource>>((ref) {
  final all = ref.watch(allDataSourcesProvider);
  final disabled = ref.watch(disabledDataSourceIdsProvider);
  final enabled = all.where((s) => !disabled.contains(s.id)).toList();
  // Belt and braces: the settings screen refuses to switch off the last
  // source, but a hand-edited row or a source id retired in an update could
  // still empty this — and everything downstream reaches for `sources.first`.
  // An app with no catalog at all is a worse answer than an ignored setting.
  return enabled.isEmpty ? all : enabled;
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
    // 1. Read the cached row. Unconditionally, even on a forced refresh: it
    // is the only place [Video.sourceKey] survives a restart, and a source
    // that keys on it (yfsp) cannot fetch anything without it. Serving the
    // row back is still gated on !forceRefresh below.
    Video? cached;
    try {
      cached =
          (await (_db.select(
                _db.videos,
              )..where((t) => t.sourceId.equals(sid) & t.apiId.equals(apiId)))
              .getSingleOrNull())
              ?.toDomain();
    } catch (e) {
      // Log error?
    }
    if (!forceRefresh && (cached?.urls?.isNotEmpty ?? false)) {
      return cached;
    }

    final ds = _getDataSource(sid);
    var video = await ds.getVideoDetail(apiId, sourceKey: cached?.sourceKey);
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
          var v = _markNewEpisodes(
            video!.copyWith(id: existing?.id),
            previous: existing?.toDomain().urls,
          );
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

  /// The locally stored detail for one show, or null when there is none.
  ///
  /// Never falls through to the network, which is the whole difference from
  /// [getVideo] — and from `cachedVideoByIdProvider`, which prefers the cache
  /// but still fetches on a miss. This backs the cross-source episode merge,
  /// and that runs on EVERY detail page open: a miss has to cost nothing, or
  /// opening any show quietly bills a request to the OTHER catalog, which is
  /// precisely the traffic the caches on this class exist to remove.
  ///
  /// A row with no episode list counts as a miss. Catalog browsing stores rows
  /// with nothing but the poster fields, and there is no progress to align
  /// against a list that isn't there.
  Future<Video?> locallyCachedVideo(int apiId, {String? sourceId}) async {
    final sid = sourceId ?? _defaultDataSource.id;
    final row =
        await (_db.select(_db.videos)
              ..where((t) => t.sourceId.equals(sid) & t.apiId.equals(apiId)))
            .getSingleOrNull();
    final video = row?.toDomain();
    return (video?.urls?.isNotEmpty ?? false) ? video : null;
  }

  /// Flags the episodes that appeared since this show was last cached.
  ///
  /// The 新 badge used to be whatever the source said: olevod ships a `new`
  /// field and dbku ships none, so one catalog's page was dotted with orange
  /// and the other never was — for the same show, on the same day. Computing
  /// it from our own previous snapshot gives both catalogs the same rule.
  ///
  /// It also gives a better answer than the field did. olevod marked 第14集 new
  /// on a viewer who had already watched it on the other source; "new" is a
  /// property of the LIST changing, and the list is what we can see change.
  ///
  /// First sighting marks nothing. There is no previous snapshot to have
  /// appeared since, and flagging a whole catalogue-fresh show would make the
  /// badge mean "unseen by this app", which is every episode of everything.
  /// Episodes are matched by their own [episodeNumberOf], never by position —
  /// a source that inserts a 预告 at the top would otherwise renumber the
  /// entire list and light up every tile.
  Video _markNewEpisodes(Video video, {List<VideoEpisode>? previous}) {
    final current = video.urls;
    if (current == null || current.isEmpty) return video;
    if (previous == null || previous.isEmpty) return video;
    if (!isEpisodicType(video.type)) return video;

    final episodic = true;
    final seen = <int>{};
    for (var i = 0; i < previous.length; i++) {
      final n = episodeNumberOf(
        previous[i].title,
        index: i,
        episodic: episodic,
      );
      if (n != null) seen.add(n);
    }
    if (seen.isEmpty) return video;

    return video.copyWith(
      urls: [
        for (var i = 0; i < current.length; i++)
          () {
            final n = episodeNumberOf(
              current[i].title,
              index: i,
              episodic: episodic,
            );
            // An unnumbered row cannot be told apart from the unnumbered row
            // that was there last time, so it is left as the source filed it.
            if (n == null) return current[i];
            return current[i].copyWith(isNew: !seen.contains(n));
          }(),
      ],
    );
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

  /// Searches EVERY configured catalog and folds the answers into one list
  /// of shows — "which source has it, and how far along" is the question a
  /// multi-source app's search exists to answer, and the single-source
  /// version answered it with a manual source switch and a second search.
  ///
  /// Sources are queried in parallel; one catalog erroring (or being rate
  /// limited) costs its own results, never the search. Answers are cached
  /// per source, so switching the global source and searching again reuses
  /// what this already fetched.
  Future<List<SearchHit>> searchVideosAllSources(String keyword) async {
    final ordered = [
      _defaultDataSource,
      ..._allDataSources.where((s) => s.id != _defaultDataSource.id),
    ];
    final perSource = await Future.wait(
      ordered.map((ds) async {
        final key = '${ds.id}|$keyword';
        final cached = _searchCache.get(key);
        if (cached != null) return cached;
        try {
          final result = await ds.searchVideos(keyword);
          _searchCache.set(key, result);
          return result;
        } catch (e) {
          logD('search', 'search on ${ds.id} failed: $e');
          return const <Video>[];
        }
      }),
    );
    return groupSearchResults(perSource);
  }

  /// Looks for this show on ONE other catalog, and caches it if found.
  ///
  /// The only place the app goes looking across sources, and it is never
  /// automatic: [CrossSourceCatalog] answers from what browsing has already
  /// stored, which turns out to be a counterpart for about one show in
  /// fourteen — the whole cross-source feature was invisible on the rest.
  /// Offering the lookup as something the user asks for keeps the automatic
  /// path at zero requests while making the feature reachable everywhere.
  ///
  /// Costs a search plus one detail fetch, and only on an exact
  /// [crossSourceKey] match: a search for 九门 returns a page of things that
  /// merely mention it, and pairing the wrong show would hand it another
  /// show's watch progress.
  Future<Video?> findOnSource({
    required String sourceId,
    required String title,
    String? year,
  }) async {
    final key = '$sourceId|search|$title';
    final cached = _searchCache.get(key);
    final results = cached ?? await _getDataSource(sourceId).searchVideos(title);
    if (cached == null) _searchCache.set(key, results);

    final wanted = crossSourceKey(title, year);
    for (final candidate in results) {
      if (crossSourceKey(candidate.title, candidate.year) != wanted) continue;
      // Fetching the detail is what actually files the row, which is what
      // makes it a counterpart on every later visit.
      return getVideo(candidate.apiId, sourceId: sourceId);
    }
    return null;
  }

  String resolveUrl(String url, {String? sourceId}) {
    final ds = _getDataSource(sourceId);
    return ds.resolveUrl(url);
  }

  Future<String?> getDownloadUrl(Video video, {VideoEpisode? episode}) =>
      _getDataSource(video.sourceId).getDownloadUrl(video, episode: episode);

  /// Turns a stored episode URL into one the player can open.
  ///
  /// Idempotent for every source: an already-playable URL comes back
  /// untouched, so this is safe to run in front of ALL playback rather than
  /// only yfsp's. yfsp is the source that needs it — it stores a `yfsp://`
  /// placeholder and mints the real URL here, one request at play time,
  /// because minting a whole show up front trips its rate limiter.
  Future<String?> resolveEpisodeUrl(String url, {String? sourceId}) =>
      _getDataSource(sourceId).resolveEpisodeUrl(url);

  /// Headers this source's streams must be opened with, or null to let the
  /// player guess. See [VideoDataSource.streamHeaders].
  Map<String, String>? streamHeaders({String? sourceId}) =>
      _getDataSource(sourceId).streamHeaders;
}

final crossSearchProvider = FutureProvider.autoDispose
    .family<List<SearchHit>, String>((ref, keyword) async {
      final repo = ref.watch(videoRepositoryProvider);
      return await repo.searchVideosAllSources(keyword);
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

/// Strictly local, unlike [cachedVideoByIdProvider], which still fetches when
/// the cache misses. See [VideoRepository.locallyCachedVideo].
final locallyCachedVideoProvider = FutureProvider.autoDispose
    .family<Video?, ({int id, String? sourceId})>((ref, arg) async {
      final repo = ref.watch(videoRepositoryProvider);
      return await repo.locallyCachedVideo(arg.id, sourceId: arg.sourceId);
    });
