// Per-episode skip markers and sweep hashes share one table because they share
// a key — but they are written by DIFFERENT callers at different times: the
// player writes hashes when a background sweep completes, and markers when
// detection or the user produces a boundary. A whole-row upsert would therefore
// blank whichever half the current write isn't carrying, and the visible
// symptom is the skip button disappearing moments after it appeared.
//
// The v4 -> v5 step matters as much as the columns: AppDatabase.forTesting runs
// onCreate, so a green round-trip test says nothing about whether an existing
// install can still open its database.

// `isNull` collides with drift's SQL expression of the same name.
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vidra/src/data/database/app_database.dart';
import 'package:vidra/src/features/video/data/history_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<EpisodeSkipDataData> row(AppDatabase db) => (db.select(
    db.episodeSkipData,
  )..where((t) => t.episodeIndex.equals(3))).getSingle();

  test('writing hashes leaves an existing marker intact', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    // The real repository method, not a hand-rolled upsert — this is the code
    // that would regress.
    final repo = HistoryRepository(db, 'dbku');
    Future<void> save(EpisodeSkipDataCompanion values) =>
        repo.saveEpisodeSkipData(42, 3, 'dbku', values);

    await save(
      const EpisodeSkipDataCompanion(
        introEndMillis: Value(19000),
        markerSource: Value(1), // MarkerSource.detected
      ),
    );
    await save(
      EpisodeSkipDataCompanion(
        sweepHashes: Value(Uint8List.fromList([1, 2, 3, 4])),
      ),
    );

    final r = await row(db);
    expect(r.introEndMillis, 19000, reason: 'the marker must survive');
    expect(r.markerSource, 1);
    expect(r.sweepHashes, [1, 2, 3, 4]);

    // And the reverse order, which is the one that actually happens: a sweep
    // stores hashes, then detection writes the marker it derived from them.
    await save(const EpisodeSkipDataCompanion(outroStartMillis: Value(2600000)));
    final r2 = await row(db);
    expect(r2.sweepHashes, [1, 2, 3, 4], reason: 'hashes must survive too');
    expect(r2.outroStartMillis, 2600000);
    expect(r2.introEndMillis, 19000);
  });

  test('a null marker is stored as an erasure, not skipped', () async {
    // EpisodeMarkers.clear exists so a wrong boundary can be taken away. If a
    // null wrote Value.absent() instead, the old value would stay and the
    // marker would be unremovable.
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    await db
        .into(db.episodeSkipData)
        .insert(
          const EpisodeSkipDataCompanion(
            videoId: Value(42),
            episodeIndex: Value(3),
            sourceId: Value('dbku'),
            introEndMillis: Value(19000),
          ),
        );
    await (db.update(db.episodeSkipData)
          ..where((t) => t.episodeIndex.equals(3)))
        .write(const EpisodeSkipDataCompanion(introEndMillis: Value(null)));

    expect((await row(db)).introEndMillis, isNull);
  });

  test('a v4 database upgrades and keeps its existing rows', () async {
    final probe = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(probe.close);

    // v4 had no such table at all.
    await probe.customStatement('DROP TABLE IF EXISTS episode_skip_data');
    await probe
        .into(probe.videoSettings)
        .insert(
          VideoSettingsCompanion.insert(
            videoId: 99,
            sourceId: const Value('olevod'),
            introDuration: const Value(85),
          ),
        );

    final migrator = probe.createMigrator();
    await probe.migration.onUpgrade(migrator, 4, 5);

    // The new table exists and is empty; nothing else was disturbed.
    expect(await probe.select(probe.episodeSkipData).get(), isEmpty);
    final settings = await (probe.select(
      probe.videoSettings,
    )..where((t) => t.videoId.equals(99))).getSingle();
    expect(settings.introDuration, 85);

    // And it is actually WRITABLE. Migrating is not enough: createTable does
    // not carry the table's @TableIndex across, and the upsert targets that
    // unique index via ON CONFLICT — which SQLite rejects when it is missing.
    // A database built by onCreate gets its indexes for free, so this failed
    // only on real upgraded installs until the migration created the index
    // too.
    final repo = HistoryRepository(probe, 'olevod');
    await repo.saveEpisodeSkipData(
      99,
      0,
      'olevod',
      const EpisodeSkipDataCompanion(introEndMillis: Value(19000)),
    );
    await repo.saveEpisodeSkipData(
      99,
      0,
      'olevod',
      EpisodeSkipDataCompanion(sweepHashes: Value(Uint8List.fromList([7]))),
    );

    final saved = await repo.getEpisodeSkipData(99, 'olevod');
    expect(saved.single.introEndMillis, 19000);
    expect(saved.single.sweepHashes, [7]);
  });
}
