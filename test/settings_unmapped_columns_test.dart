// The settings row holds more than the settings model does. Search history
// and the followed-shows "last checked" time live in the same row, written by
// their own targeted updates, and are not part of AppSettings at all.
//
// updateSettings used to replace the whole row, so every settings write —
// a theme toggle, a source switch, or just closing the player, which saves
// its window size — reset both to NULL. The search dropdown came back empty
// after a restart, and the 20-minute floor on update checks did not survive
// one either.

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vidra/src/data/database/app_database.dart';
import 'package:vidra/src/features/settings/data/settings_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a settings write leaves the columns it does not own alone', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = SettingsRepository(db);
    final checkedAt = DateTime(2026, 11, 20, 12);

    await repo.getSettings(); // creates the row
    await db
        .update(db.appSettings)
        .write(
          AppSettingsCompanion(
            searchHistory: const Value('["九门"]'),
            subscriptionCheckedAt: Value(checkedAt),
          ),
        );

    // What closing the player does: read, change something unrelated, write.
    final settings = await repo.getSettings();
    settings.playerNormalWidth = 1234;
    await repo.updateSettings(settings);

    final row = await db.select(db.appSettings).getSingle();
    expect(row.playerNormalWidth, 1234, reason: 'the write itself landed');
    expect(row.searchHistory, '["九门"]');
    expect(row.subscriptionCheckedAt, checkedAt);
  });

  test('the first write on a fresh install still creates the row', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = SettingsRepository(db);
    final settings = await repo.getSettings();
    await db.delete(db.appSettings).go();

    settings.playerNormalWidth = 800;
    await repo.updateSettings(settings);

    expect(
      (await db.select(db.appSettings).get()).single.playerNormalWidth,
      800,
    );
  });

  test('change() edits the stored row, not a stale copy of it', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = SettingsRepository(db);

    // The settings screen's snapshot, taken before…
    final snapshot = await repo.getSettings();
    // …the player window saved its size from another engine.
    final players = await repo.getSettings();
    players.playerNormalWidth = 1234;
    await repo.updateSettings(players);

    snapshot.telemetryEnabled = !snapshot.telemetryEnabled;
    await repo.change((s) => s.telemetryEnabled = snapshot.telemetryEnabled);

    final now = await repo.getSettings();
    expect(now.telemetryEnabled, snapshot.telemetryEnabled);
    expect(now.playerNormalWidth, 1234, reason: 'not the snapshot’s old size');
  });
}
