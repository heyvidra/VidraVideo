// v18 adds `videos.source_key`, which yfsp depends on outright: its shows are
// keyed by a base62 token that does not fit `api_id`, so a row without this
// column can be found locally but never refreshed. AppDatabase.forTesting runs
// onCreate, so a green round-trip says nothing about whether an install that
// already has a videos table full of rows can still open its database — that
// upgrade path is what this covers.

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vidra/src/data/database/app_database.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// A database standing where a v17 install stands: videos table, real rows,
  /// no source_key.
  Future<AppDatabase> priorInstall() async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    await db.customStatement('ALTER TABLE videos DROP COLUMN source_key');
    await db.customStatement(
      "INSERT INTO videos (source_id, api_id, title, cover_url, rating, type) "
      "VALUES ('olevod', 4242, '旧片', 'https://c/x.jpg', 7.5, '电影')",
    );
    return db;
  }

  test('the v17 -> v18 climb adds the column and keeps existing rows', () async {
    final db = await priorInstall();
    addTearDown(db.close);

    await db.migration.onUpgrade(db.createMigrator(), 17, db.schemaVersion);

    // The pre-existing row survives, and reads back with a null key — correct
    // for every source that shipped before this, all of which key on api_id.
    final old = await (db.select(
      db.videos,
    )..where((t) => t.apiId.equals(4242))).getSingle();
    expect(old.title, '旧片');
    expect(old.sourceKey, isNull);

    // And the column is WRITABLE, which is the part that matters: yfsp's whole
    // detail path is "read the key back off the row and ask again with it".
    await db
        .into(db.videos)
        .insert(
          VideosCompanion.insert(
            sourceId: const Value('yfsp'),
            apiId: 99,
            sourceKey: const Value('PwLAKyPFpPE'),
            title: '新片',
            coverUrl: 'https://c/y.jpg',
            rating: 8,
            type: '电视剧',
          ),
        );
    final fresh = await (db.select(
      db.videos,
    )..where((t) => t.apiId.equals(99))).getSingle();
    expect(fresh.sourceKey, 'PwLAKyPFpPE');
  });

  test('a half-migrated database recovers, and the step is idempotent', () async {
    // drift runs onUpgrade outside a transaction by default, so a crash
    // mid-climb leaves earlier steps applied with user_version still old — the
    // state that killed v1.6.0. A relaunch replays the same climb, which must
    // walk INTO the half-applied work and out the other side rather than
    // failing with "duplicate column name".
    final db = await priorInstall();
    addTearDown(db.close);

    final migrator = db.createMigrator();
    await db.migration.onUpgrade(migrator, 17, db.schemaVersion);
    await db.migration.onUpgrade(migrator, 17, db.schemaVersion);
    // And the climb an older install makes, passing through v18 on the way.
    await db.migration.onUpgrade(migrator, 4, db.schemaVersion);

    final old = await (db.select(
      db.videos,
    )..where((t) => t.apiId.equals(4242))).getSingle();
    expect(old.title, '旧片');
  });

  test('the v18 -> v19 climb adds the switched-off-sources column', () async {
    // v19 stores which data sources the user hid. Absent on every existing
    // row, which reads as "all on" — the behaviour they already had.
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    await db.customStatement(
      'ALTER TABLE app_settings DROP COLUMN disabled_data_source_ids',
    );

    final migrator = db.createMigrator();
    await db.migration.onUpgrade(migrator, 18, db.schemaVersion);
    // Replayed, the way a relaunch replays a climb that crashed halfway.
    await db.migration.onUpgrade(migrator, 18, db.schemaVersion);

    await db
        .into(db.appSettings)
        .insert(
          AppSettingsCompanion.insert(
            id: const Value(1),
            disabledDataSourceIds: const Value('dbku,yfsp'),
          ),
        );
    final row = await db.select(db.appSettings).getSingle();
    expect(row.disabledDataSourceIds, 'dbku,yfsp');
  });
}
