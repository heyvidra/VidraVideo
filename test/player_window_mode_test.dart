// The switch decides whether playing a video spins up a second Flutter engine.
// Its whole point is that an explicit choice beats the hardware guess in BOTH
// directions — a fast machine whose owner wants one window, and a slow one
// whose owner wants playback on a second display — so both overrides are
// pinned here, along with the round trip through the settings column.

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vidra/src/config/player_window_mode.dart';
import 'package:vidra/src/config/reduce_effects.dart';
// The drift table generates a class of the same name; this test means the
// domain one.
import 'package:vidra/src/data/database/app_database.dart'
    show AppDatabase;
import 'package:vidra/src/features/settings/data/settings_repository.dart';
import 'package:vidra/src/features/settings/domain/app_settings.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  AppSettings settingsWith(String? mode) =>
      AppSettings()..playerWindowMode = mode;

  tearDown(() => PlayerWindow.inApp = false);

  test('an explicit choice outranks the hardware, both ways', () {
    expect(PlayerWindow.resolve(PlayerWindowMode.inApp), isTrue);
    expect(PlayerWindow.resolve(PlayerWindowMode.window), isFalse);
    // Whichever way this machine's auto lands, neither override follows it.
    expect(
      PlayerWindow.resolve(PlayerWindowMode.inApp),
      isNot(PlayerWindow.resolve(PlayerWindowMode.window)),
    );
  });

  // Asserted against the detector rather than a literal: auto is defined as
  // "whatever 减少特效 decided about this machine", and the two must not be
  // able to drift apart.
  test('auto follows the same GPU verdict as 减少特效', () {
    expect(
      PlayerWindow.resolve(PlayerWindowMode.auto),
      ReduceEffects.lowPowerGpu,
    );
  });

  test('a database predating the column reads as auto', () {
    expect(PlayerWindowMode.fromStored(null), PlayerWindowMode.auto);
    // Anything unrecognised too — a downgrade must not wedge the player.
    expect(PlayerWindowMode.fromStored('nonsense'), PlayerWindowMode.auto);
  });

  test('every mode survives the round trip through the column', () {
    for (final mode in PlayerWindowMode.values) {
      expect(PlayerWindowMode.fromStored(mode.stored), mode);
    }
  });

  test('seeding publishes the resolved value', () {
    PlayerWindow.seed(settingsWith('in_app'));
    expect(PlayerWindow.inApp, isTrue);

    PlayerWindow.seed(settingsWith('window'));
    expect(PlayerWindow.inApp, isFalse);

    PlayerWindow.seed(settingsWith(null));
    expect(PlayerWindow.inApp, ReduceEffects.lowPowerGpu);
  });

  // The schema v17 column, end to end. A setting that cannot be persisted is
  // a setting that resets on every launch, and the generated mapping is the
  // one part of this that no other test would touch.
  test('the choice survives a write and a reopen', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = SettingsRepository(db);

    final fresh = await repo.getSettings();
    expect(fresh.playerWindowMode, isNull, reason: 'a new install is auto');

    fresh.playerWindowMode = PlayerWindowMode.inApp.stored;
    await repo.updateSettings(fresh);

    final reread = await repo.getSettings();
    expect(reread.playerWindowMode, 'in_app');
    expect(
      PlayerWindowMode.fromStored(reread.playerWindowMode),
      PlayerWindowMode.inApp,
    );
  });

  // The way it actually gets lost. `updateSettings` is an insertOrReplace, so
  // it rewrites the WHOLE row — and every window-geometry save on the way out
  // of the app is a read-modify-write of some unrelated field through that
  // same call. A column missing from either half of the mapping does not fail
  // anything; it just quietly comes back null on the next launch.
  test('an unrelated save does not wipe the choice', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = SettingsRepository(db);

    final settings = await repo.getSettings();
    settings.playerWindowMode = PlayerWindowMode.inApp.stored;
    await repo.updateSettings(settings);

    // What WindowHelper does when the player window is resized or closed.
    final onQuit = await repo.getSettings();
    onQuit.playerNormalWidth = 1280;
    onQuit.playerNormalHeight = 720;
    await repo.updateSettings(onQuit);

    final next = await repo.getSettings();
    expect(next.playerNormalWidth, 1280);
    expect(
      next.playerWindowMode,
      'in_app',
      reason: 'a window resize must not reset where the player opens',
    );
  });
}
