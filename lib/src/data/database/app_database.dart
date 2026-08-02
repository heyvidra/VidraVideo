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

  RealColumn get playerNormalWidth => real().nullable()();
  RealColumn get playerNormalHeight => real().nullable()();
  RealColumn get playerPipWidth => real().nullable()();
  RealColumn get playerPipHeight => real().nullable()();

  TextColumn get locale => text().nullable()();
}

@DriftDatabase(
  tables: [
    Videos,
    VideoSettings,
    VideoHistory,
    EpisodeHistory,
    EpisodeSkipData,
    DownloadTasks,
    AppSettings,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// Test seam: pass an in-memory executor (`NativeDatabase.memory()`).
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async {
      // v2: add AppSettings.segmentConcurrency (default 6).
      if (from < 2) {
        await m.addColumn(appSettings, appSettings.segmentConcurrency);
      }
      // v3: add AppSettings.cookieFile (nullable) for gated-site cookies.
      if (from < 3) {
        await m.addColumn(appSettings, appSettings.cookieFile);
      }
      // v4: add VideoSettings.autoSkip (default true, matching the old
      // hardcoded value, so existing rows keep behaving as they do today).
      if (from < 4) {
        await m.addColumn(videoSettings, videoSettings.autoSkip);
      }
      // v5: per-episode skip boundaries + the sweep hashes they came from.
      // A new table, so nothing existing is touched: an upgraded install
      // simply has no rows until the player sweeps something.
      // `to` as well as `from`: this step CREATES rather than alters, so
      // running it when the caller only asked to reach v4 fails outright on a
      // database that already has the table. Real upgrades always pass the
      // current version, but the migration tests exercise one step at a time.
      if (from < 5 && to >= 5) {
        await m.createTable(episodeSkipData);
        // createTable does NOT create the table's @TableIndex entries, and
        // this one is not an optimisation: the upsert that keeps markers and
        // hashes from blanking each other targets it via ON CONFLICT, which
        // SQLite rejects outright without a matching unique index. Caught on
        // device only — a test database built by onCreate gets its indexes for
        // free and never sees this.
        await m.create(episodeSkipDataIdx);
      }
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
