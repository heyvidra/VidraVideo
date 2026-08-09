import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/database/app_database.dart' as db;
import '../../../data/database/app_database_provider.dart';

final backupServiceProvider = Provider<BackupService>(
  (ref) => BackupService(ref.watch(appDatabaseProvider)),
);

/// What an import did: how many rows the file held, how many were new.
typedef BackupSummary = ({int total, int added});

/// Everything irreplaceable, as one JSON document: watch progress, skip
/// markers, per-show settings, 追更 and 想看. Nothing machine-local —
/// downloads, window geometry, catalog caches all rebuild themselves.
///
/// Import MERGES. Every table here carries a unique business key, so rows go
/// in with insertOrIgnore and an existing row always wins: importing a backup
/// twice, or an old backup over newer data, adds nothing and destroys
/// nothing. The trade — an existing stale row is not refreshed by a newer
/// backup — is deliberate; "import cannot lose anything" is the property a
/// panicking user needs, and re-watching one episode re-writes the row anyway.
class BackupService {
  BackupService(this._db);

  final db.AppDatabase _db;

  static const version = 1;

  Future<String> exportJson() async {
    final payload = {
      'app': 'vidra',
      'version': version,
      'videoHistory': await _dump(_db.videoHistory),
      'episodeHistory': await _dump(_db.episodeHistory),
      'episodeSkipData': await _dump(_db.episodeSkipData),
      'videoSettings': await _dump(_db.videoSettings),
      'subscriptions': await _dump(_db.subscriptions),
      'favorites': await _dump(_db.favorites),
    };
    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  Future<BackupSummary> importJson(String raw) async {
    final data = jsonDecode(raw);
    if (data is! Map || data['app'] != 'vidra') {
      throw const FormatException('not a vidra backup');
    }

    var total = 0;
    var added = 0;
    await _db.transaction(() async {
      Future<void> restore(
        TableInfo table,
        String key,
        Insertable Function(Map<String, dynamic>) fromJson,
      ) async {
        final list = data[key];
        if (list is! List) return;
        // insertOrIgnore reports nothing, so new-vs-known is a row count.
        final before = await _count(table);
        for (final e in list) {
          total++;
          await _db
              .into(table)
              .insert(
                fromJson(Map<String, dynamic>.from(e as Map)),
                mode: InsertMode.insertOrIgnore,
              );
        }
        added += await _count(table) - before;
      }

      // Each row re-enters through its data class (same serializer that wrote
      // it) and sheds its id — ids are this database's business, and imported
      // rows collide with local ones on autoincrement, not identity.
      await restore(
        _db.videoHistory,
        'videoHistory',
        (e) => db.VideoHistoryData.fromJson(
          e,
        ).toCompanion(true).copyWith(id: const Value.absent()),
      );
      await restore(
        _db.episodeHistory,
        'episodeHistory',
        (e) => db.EpisodeHistoryData.fromJson(
          e,
        ).toCompanion(true).copyWith(id: const Value.absent()),
      );
      await restore(
        _db.episodeSkipData,
        'episodeSkipData',
        (e) => db.EpisodeSkipDataData.fromJson(
          e,
        ).toCompanion(true).copyWith(id: const Value.absent()),
      );
      await restore(
        _db.videoSettings,
        'videoSettings',
        (e) => db.VideoSetting.fromJson(
          e,
        ).toCompanion(true).copyWith(id: const Value.absent()),
      );
      await restore(
        _db.subscriptions,
        'subscriptions',
        (e) => db.Subscription.fromJson(
          e,
        ).toCompanion(true).copyWith(id: const Value.absent()),
      );
      await restore(
        _db.favorites,
        'favorites',
        (e) => db.Favorite.fromJson(
          e,
        ).toCompanion(true).copyWith(id: const Value.absent()),
      );
    });

    return (total: total, added: added);
  }

  Future<List<Map<String, dynamic>>> _dump(TableInfo table) async {
    final rows = await _db.select(table).get();
    return [for (final r in rows) (r as DataClass).toJson()];
  }

  Future<int> _count(TableInfo table) async {
    final c = countAll();
    final row = await (_db.selectOnly(table)..addColumns([c])).getSingle();
    return row.read(c) ?? 0;
  }
}
