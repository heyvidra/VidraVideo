// autoSkip persistence, including the v3 -> v4 upgrade.
//
// The switch was hardcoded true on read and dropped on write, so a viewer who
// turned it off (this show has a post-credits scene) got it back on at the
// next launch, silently. The migration matters as much as the column:
// AppDatabase.forTesting runs onCreate, so a green unit test says nothing
// about whether an existing install can open its database at all.

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vidra/src/data/database/app_database.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('autoSkip round-trips instead of resetting to true', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    await db
        .into(db.videoSettings)
        .insert(
          VideoSettingsCompanion.insert(
            videoId: 42,
            sourceId: const Value('olevod'),
            introDuration: const Value(90),
            autoSkip: const Value(false),
          ),
        );

    final row = await (db.select(
      db.videoSettings,
    )..where((t) => t.videoId.equals(42))).getSingle();

    expect(row.autoSkip, isFalse, reason: 'the user turned it off');
    expect(row.introDuration, 90);
  });

  test('a fresh row still defaults to on', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    await db
        .into(db.videoSettings)
        .insert(VideoSettingsCompanion.insert(videoId: 7));
    final row = await db.select(db.videoSettings).getSingle();

    expect(row.autoSkip, isTrue);
  });

  test('a v3 database upgrades and keeps its existing rows', () async {
    // Hand-built v3 schema: what an installed copy actually looks like.
    final raw = NativeDatabase.memory();
    final probe = AppDatabase.forTesting(raw);
    addTearDown(probe.close);

    await probe.customStatement('DROP TABLE IF EXISTS video_settings');
    await probe.customStatement('''
      CREATE TABLE video_settings (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        source_id TEXT NULL,
        video_id INTEGER NOT NULL,
        intro_duration INTEGER NOT NULL DEFAULT 0,
        outro_duration INTEGER NOT NULL DEFAULT 0
      )''');
    await probe.customStatement(
      "INSERT INTO video_settings (source_id, video_id, intro_duration, "
      "outro_duration) VALUES ('olevod', 99, 85, 40)",
    );

    // Run the real v3 -> v4 step against it.
    final migrator = probe.createMigrator();
    await probe.migration.onUpgrade(migrator, 3, 4);

    final row = await (probe.select(
      probe.videoSettings,
    )..where((t) => t.videoId.equals(99))).getSingle();

    expect(row.introDuration, 85, reason: 'existing settings must survive');
    expect(row.outroDuration, 40);
    expect(
      row.autoSkip,
      isTrue,
      reason: 'upgraded rows keep the behaviour they had before the column',
    );
  });
}
