import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'dart:io';

import '../../features/video/domain/video_collection.dart';
import '../../features/download/domain/download_task.dart';

part 'app_database.g.dart';

// Type Converters

class StringListConverter extends TypeConverter<List<String>, String> {
  const StringListConverter();
  @override
  List<String> fromSql(String fromDb) => List<String>.from(json.decode(fromDb));
  @override
  String toSql(List<String> value) => json.encode(value);
}

class VideoEpisodeListConverter
    extends TypeConverter<List<VideoEpisode>, String> {
  const VideoEpisodeListConverter();
  @override
  List<VideoEpisode> fromSql(String fromDb) {
    final list = json.decode(fromDb) as List;
    return list.map((e) {
      final map = e as Map<String, dynamic>;
      return VideoEpisode(
        index: map['index'],
        title: map['title'],
        vip: map['vip'],
        isNew: map['isNew'],
        qualities: (map['qualities'] as List?)
            ?.map(
              (q) => VideoQuality(
                name: (q as Map<String, dynamic>)['name'],
                url: q['url'],
              ),
            )
            .toList(),
      );
    }).toList();
  }

  @override
  String toSql(List<VideoEpisode> value) {
    return json.encode(
      value
          .map(
            (e) => {
              'index': e.index,
              'title': e.title,
              'vip': e.vip,
              'isNew': e.isNew,
              'qualities': e.qualities
                  ?.map((q) => {'name': q.name, 'url': q.url})
                  .toList(),
            },
          )
          .toList(),
    );
  }
}

class EpisodeDownloadListConverter
    extends TypeConverter<List<EpisodeDownloadInfo>, String> {
  const EpisodeDownloadListConverter();
  @override
  List<EpisodeDownloadInfo> fromSql(String fromDb) {
    if (fromDb.isEmpty) return [];
    final list = json.decode(fromDb) as List;
    return list.map((e) => EpisodeDownloadInfo.fromJson(e)).toList();
  }

  @override
  String toSql(List<EpisodeDownloadInfo> value) =>
      json.encode(value.map((e) => e.toJson()).toList());
}

// Tables

@TableIndex(name: 'videos_idx', columns: {#sourceId, #apiId}, unique: true)
class Videos extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get sourceId => text().nullable()(); // Removed unique()
  IntColumn get apiId => integer()();

  TextColumn get title => text()();
  TextColumn get coverUrl => text()();
  TextColumn get thumbUrl => text().nullable()();
  TextColumn get backdropUrl => text().nullable()();
  RealColumn get rating => real()();
  TextColumn get year => text().nullable()();
  TextColumn get region => text().nullable()();
  TextColumn get type => text()();

  IntColumn get typeId => integer().nullable()();
  IntColumn get typeId1 => integer().nullable()();
  TextColumn get actor => text().nullable()();
  TextColumn get blurb => text().nullable()();
  TextColumn get remarks => text().nullable()();
  TextColumn get version => text().nullable()();
  BoolColumn get vip => boolean().nullable()();
  IntColumn get vodTime => integer().nullable()();
  IntColumn get hits => integer().nullable()();

  TextColumn get genres => text().map(const StringListConverter()).nullable()();

  TextColumn get description => text().nullable()();
  TextColumn get content => text().nullable()();
  TextColumn get director => text().nullable()();
  TextColumn get writer => text().nullable()();
  TextColumn get lang => text().nullable()();

  TextColumn get urls =>
      text().map(const VideoEpisodeListConverter()).nullable()();
}

@TableIndex(
  name: 'video_settings_idx',
  columns: {#sourceId, #videoId},
  unique: true,
)
class VideoSettings extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get sourceId => text().nullable()(); // Removed unique()
  IntColumn get videoId => integer()();
  IntColumn get introDuration => integer().withDefault(const Constant(0))();
  IntColumn get outroDuration => integer().withDefault(const Constant(0))();

  /// Master switch for intro/outro skipping. Lives here, per show, because
  /// "this one has a post-credits scene" is a property of the show. It was
  /// hardcoded true on read and dropped on write, so turning it off survived
  /// exactly until the next launch.
  BoolColumn get autoSkip => boolean().withDefault(const Constant(true))();
}

@TableIndex(
  name: 'video_history_idx',
  columns: {#sourceId, #videoId},
  unique: true,
)
class VideoHistory extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get sourceId => text().nullable()(); // Removed unique()
  IntColumn get videoId => integer()();

  TextColumn get videoTitle => text()();
  TextColumn get coverUrl => text()();

  TextColumn get rating => text().nullable()();
  TextColumn get type => text()();
  TextColumn get region => text().nullable()();
  TextColumn get year => text().nullable()();
  TextColumn get actor => text().nullable()();
  TextColumn get version => text().nullable()();
  IntColumn get hits => integer().nullable()();
  TextColumn get remarks => text().nullable()();
  TextColumn get blurb => text().nullable()();

  IntColumn get lastEpisodeIndex => integer()();
  TextColumn get lastEpisodeTitle => text().nullable()();

  DateTimeColumn get updatedAt => dateTime()();
}

// Uniqueness includes sourceId: the same videoId can exist across data sources.
@TableIndex(
  name: 'episode_history_idx',
  columns: {#videoId, #episodeIndex, #sourceId},
  unique: true,
)
class EpisodeHistory extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get sourceId => text().nullable()();

  IntColumn get videoId => integer()();
  IntColumn get episodeIndex => integer()();

  IntColumn get positionMillis => integer()();
  IntColumn get durationMillis => integer()();

  DateTimeColumn get updatedAt => dateTime()();
}

/// Per-episode skip boundaries and the sweep hashes they were derived from.
///
/// One table for both because they share a key and a lifetime: the hashes are
/// what the player's cross-episode detector compares to PRODUCE the markers.
/// Keyed with sourceId for the same reason as [EpisodeHistory] — videoId
/// collides across data sources.
@TableIndex(
  name: 'episode_skip_data_idx',
  columns: {#videoId, #episodeIndex, #sourceId},
  unique: true,
)
class EpisodeSkipData extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get sourceId => text().nullable()();

  IntColumn get videoId => integer()();
  IntColumn get episodeIndex => integer()();

  /// Absolute boundaries into the media. Null means "not set for this episode",
  /// which is not the same as zero.
  IntColumn get introEndMillis => integer().nullable()();
  IntColumn get outroStartMillis => integer().nullable()();

  /// `MarkerSource.index` from the player SDK. Stored so precedence survives a
  /// restart: without it a re-detected intro would overwrite one the user
  /// placed by hand.
  IntColumn get markerSource => integer().nullable()();

  /// Perceptual hashes from one sweep, in the SDK's own versioned format.
  /// Opaque here on purpose — this app stores and returns the bytes unchanged,
  /// and the SDK discards a blob it does not recognise.
  BlobColumn get sweepHashes => blob().nullable()();
}

/// Shows the user is following, and what it takes to notice a new episode
/// without asking the source over and over.
///
/// Keyed with sourceId like everything else here: videoId collides across data
/// sources, and the same show followed on both is two subscriptions with two
/// release schedules.
@TableIndex(
  name: 'subscriptions_idx',
  columns: {#videoId, #sourceId},
  unique: true,
)
class Subscriptions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get sourceId => text()();
  IntColumn get videoId => integer()();

  TextColumn get title => text()();
  TextColumn get year => text().nullable()();
  TextColumn get coverUrl => text().nullable()();

  /// The catalog's own progress line, as last seen. Any change to it is the
  /// update signal — and it arrives free with every listing the user scrolls
  /// past, which is why this feature costs no requests most of the time.
  TextColumn get lastSeenRemarks => text().nullable()();

  DateTimeColumn get lastUpdateAt => dateTime().nullable()();

  /// Observed update times, JSON, oldest first and capped. The release
  /// schedule is inferred from these — see `UpdateCadence`.
  TextColumn get updateHistory => text().nullable()();

  /// Earliest moment a request for this show is worth making. Before it, the
  /// show is skipped entirely.
  DateTimeColumn get nextCheckAt => dateTime().nullable()();

  BoolColumn get unread => boolean().withDefault(const Constant(false))();

  /// Finished airing. Never checked again — the cheapest request is the one
  /// never made.
  BoolColumn get finished => boolean().withDefault(const Constant(false))();

  /// The same show's progress as last seen on ANOTHER source (matched by
  /// title + year, like the cross-source watch badge). A drama often lands on
  /// one catalog hours before the other, and a viewer following the slow one
  /// still wants the news when the fast one has it first.
  ///
  /// Kept apart from [lastSeenRemarks] on purpose: sources word their progress
  /// differently ("更新至第 05 集" vs "更新至5集"), so cross-source text must
  /// never enter the same-source comparison — every sweep would read the
  /// wording difference as an update.
  TextColumn get crossSeenSourceId => text().nullable()();
  TextColumn get crossSeenRemarks => text().nullable()();

  DateTimeColumn get createdAt => dateTime()();
}

/// Shows saved to watch later — found now, not started yet.
///
/// A row is a bookmark plus the snapshot a poster card needs to render
/// without a network trip. Playback state stays in the history tables; the
/// list lives as the 想看 tab beside 继续观看 rather than its own rail entry.
@TableIndex(name: 'favorites_idx', columns: {#videoId, #sourceId}, unique: true)
class Favorites extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get sourceId => text()();
  IntColumn get videoId => integer()();

  TextColumn get title => text()();
  TextColumn get year => text().nullable()();
  TextColumn get coverUrl => text().nullable()();
  TextColumn get rating => text().nullable()();
  TextColumn get type => text().withDefault(const Constant(''))();
  TextColumn get region => text().nullable()();
  TextColumn get remarks => text().nullable()();

  DateTimeColumn get createdAt => dateTime()();
}

class DownloadTasks extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get taskId => text().unique()();
  IntColumn get videoId => integer()();

  TextColumn get videoTitle => text()();
  TextColumn get coverUrl => text().nullable()();

  TextColumn get episodes => text().map(const EpisodeDownloadListConverter())();

  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get completedAt => dateTime().nullable()();
}

class AppSettings extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get downloadPath => text().nullable()();
  // ponytail: retired feature (thumbnail preview removed). Column kept as a
  // dead default-false stub to avoid a drop-column migration; nothing maps it.
  BoolColumn get enableThumbnailPreview =>
      boolean().withDefault(const Constant(false))();
  IntColumn get maxConcurrentDownloads =>
      integer().withDefault(const Constant(3))();
  // Parallel HLS segment fetches within a single download (vidraDlp).
  IntColumn get segmentConcurrency =>
      integer().withDefault(const Constant(6))();
  TextColumn get lastDataSourceId => text().nullable()();

  // Path to a Netscape-format cookies.txt, forwarded to vidraDlp as the client
  // config `cookie_file` so gated sites (e.g. YouTube login-required videos)
  // can be extracted + downloaded. null = no cookies.
  TextColumn get cookieFile => text().nullable()();

  IntColumn get themeMode => integer().withDefault(const Constant(0))();

  /// When the subscription checker last ran. Persisted because the 20-minute
  /// floor lived only in memory, so the one habit desktop users actually have
  /// — closing and reopening the app — reset it and swept every launch.
  DateTimeColumn get subscriptionCheckedAt => dateTime().nullable()();

  RealColumn get playerNormalWidth => real().nullable()();
  RealColumn get playerNormalHeight => real().nullable()();
  RealColumn get playerPipWidth => real().nullable()();
  RealColumn get playerPipHeight => real().nullable()();

  /// Last top-left of the player window in NORMAL mode. Size alone cannot
  /// restore "where I left it" — and window MOVES emit no metric events,
  /// so these are captured at close/pip-enter snapshots, not on resize.
  RealColumn get playerWindowX => real().nullable()();
  RealColumn get playerWindowY => real().nullable()();

  /// Same for PIP mode: where the user parked the mini window. Without it
  /// every pip entry flies to the bottom-right default, discarding the
  /// user's chosen corner.
  RealColumn get playerPipX => real().nullable()();
  RealColumn get playerPipY => real().nullable()();

  TextColumn get locale => text().nullable()();

  /// Recent search keywords, JSON array, newest first and capped — see
  /// SearchHistoryNotifier. A column rather than a table: it is one small
  /// ordered list with no queries against it.
  TextColumn get searchHistory => text().nullable()();

  /// Whether the desktop pet window comes up with the app. Off by default:
  /// an always-on-top window that appears uninvited on first launch is a
  /// thing to close, not a thing to like.
  BoolColumn get showPet => boolean().withDefault(const Constant(false))();

  /// Where the user parked the pet: its window's BOTTOM-RIGHT corner. The
  /// anchor rather than the top-left because the window changes size while
  /// the pet speaks, and only the bottom-right corner survives that.
  RealColumn get petWindowX => real().nullable()();
  RealColumn get petWindowY => real().nullable()();
}

@DriftDatabase(
  tables: [
    Videos,
    VideoSettings,
    VideoHistory,
    EpisodeHistory,
    EpisodeSkipData,
    Subscriptions,
    Favorites,
    DownloadTasks,
    AppSettings,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// Test seam: pass an in-memory executor (`NativeDatabase.memory()`).
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 14;

  /// True when [table] already has a column named [name].
  ///
  /// Every ALTER here goes through this because upgrades are NOT atomic in
  /// the field: drift runs onUpgrade outside a transaction by default, so a
  /// failed step leaves every earlier step applied with user_version still at
  /// the old value. That exact state shipped — v1.6.0 crashed mid-climb, and
  /// the retry then collided with its own half-applied work ("duplicate
  /// column name"). An idempotent step is the only kind that can walk INTO a
  /// half-migrated database and out the other side.
  Future<bool> _hasColumn(TableInfo table, String name) async {
    final rows = await customSelect(
      'PRAGMA table_info(${table.actualTableName})',
    ).get();
    return rows.any((r) => r.data['name'] == name);
  }

  Future<void> _addColumnIfAbsent(
    Migrator m,
    TableInfo table,
    GeneratedColumn column,
  ) async {
    if (await _hasColumn(table, column.name)) return;
    await m.addColumn(table, column);
  }

  Future<bool> _hasTable(String name) async {
    final rows = await customSelect(
      "SELECT 1 FROM sqlite_master WHERE type = 'table' AND name = ?",
      variables: [Variable.withString(name)],
    ).get();
    return rows.isNotEmpty;
  }

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async {
      // One transaction for the whole climb. Without it a mid-climb failure
      // strands the database half-migrated with the old version number —
      // which is not hypothetical; it is how v1.6.0 died on launch.
      await transaction(() async {
        // v2: AppSettings.segmentConcurrency (default 6).
        if (from < 2) {
          await _addColumnIfAbsent(
            m,
            appSettings,
            appSettings.segmentConcurrency,
          );
        }
        // v3: AppSettings.cookieFile (nullable) for gated-site cookies.
        if (from < 3) {
          await _addColumnIfAbsent(m, appSettings, appSettings.cookieFile);
        }
        // v4: VideoSettings.autoSkip (default true, matching the old
        // hardcoded value, so existing rows keep behaving as they do today).
        if (from < 4) {
          await _addColumnIfAbsent(m, videoSettings, videoSettings.autoSkip);
        }
        // v5: per-episode skip boundaries + the sweep hashes they came from.
        // The index is created explicitly: createTable does not carry
        // @TableIndex across, and the marker/hash upsert targets it via
        // ON CONFLICT, which SQLite rejects without a matching unique index.
        if (from < 5 && to >= 5 && !await _hasTable('episode_skip_data')) {
          await m.createTable(episodeSkipData);
          await m.create(episodeSkipDataIdx);
        }
        // v6: shows the user follows. createTable builds the table from the
        // CURRENT schema — later columns included — which is why the v7/v8
        // steps below must be conditional on the column actually missing
        // rather than on version arithmetic. Version arithmetic already got
        // this wrong once.
        if (from < 6 && to >= 6 && !await _hasTable('subscriptions')) {
          await m.createTable(subscriptions);
          await m.create(subscriptionsIdx);
        }
        // v7: when the subscription sweep last ran, across restarts.
        if (from < 7 && to >= 7) {
          await _addColumnIfAbsent(
            m,
            appSettings,
            appSettings.subscriptionCheckedAt,
          );
        }
        // v8: a followed show's progress as seen on the OTHER source.
        if (from < 8 && to >= 8) {
          await _addColumnIfAbsent(
            m,
            subscriptions,
            subscriptions.crossSeenSourceId,
          );
          await _addColumnIfAbsent(
            m,
            subscriptions,
            subscriptions.crossSeenRemarks,
          );
        }
        // v9: player window position (normal mode), for restore-on-reopen.
        if (from < 9 && to >= 9) {
          await _addColumnIfAbsent(m, appSettings, appSettings.playerWindowX);
          await _addColumnIfAbsent(m, appSettings, appSettings.playerWindowY);
        }
        // v10: pip window position, so pip entry returns to the user's spot.
        if (from < 10 && to >= 10) {
          await _addColumnIfAbsent(m, appSettings, appSettings.playerPipX);
          await _addColumnIfAbsent(m, appSettings, appSettings.playerPipY);
        }
        // v11: shows saved to watch later (想看).
        if (from < 11 && to >= 11 && !await _hasTable('favorites')) {
          await m.createTable(favorites);
          await m.create(favoritesIdx);
        }
        // v12: recent search keywords on the settings row.
        if (from < 12 && to >= 12) {
          await _addColumnIfAbsent(m, appSettings, appSettings.searchHistory);
        }
        // v13: whether the desktop pet comes up with the app.
        if (from < 13 && to >= 13) {
          await _addColumnIfAbsent(m, appSettings, appSettings.showPet);
        }
        // v14: where the user parked the pet (bottom-right anchor).
        if (from < 14 && to >= 14) {
          await _addColumnIfAbsent(m, appSettings, appSettings.petWindowX);
          await _addColumnIfAbsent(m, appSettings, appSettings.petWindowY);
        }
      });
    },
  );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationSupportDirectory();
    if (!dbFolder.existsSync()) {
      await dbFolder.create(recursive: true);
    }
    final file = File(p.join(dbFolder.path, 'vidradb.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
