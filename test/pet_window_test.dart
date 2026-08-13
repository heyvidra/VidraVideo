import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vidra/src/data/database/app_database.dart';
import 'package:vidra/src/features/settings/data/settings_repository.dart';
import 'package:vidra/src/window/pet_window.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // The setting is the only record of whether the pet should be on screen —
  // the pet window has no way to report back — so a field dropped from either
  // mapper would silently forget the user's choice on every restart.
  test('showPet survives a write and read back', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = SettingsRepository(db);

    expect((await repo.getSettings()).showPet, isFalse);

    final settings = await repo.getSettings();
    settings.showPet = true;
    await repo.updateSettings(settings);

    expect((await repo.getSettings()).showPet, isTrue);
  });

  // The mood is the whole cross-window contract: the main window pokes the
  // pet by re-opening it with new arguments, and this is what the pet reads.
  group('PetMood.fromArguments', () {
    test('reads a known mood', () {
      expect(PetMood.fromArguments({'mood': 'happy'}), PetMood.happy);
    });

    test('falls back to idle for null, junk and a missing key', () {
      expect(PetMood.fromArguments(null), PetMood.idle);
      expect(PetMood.fromArguments({}), PetMood.idle);
      expect(PetMood.fromArguments({'mood': 'elated'}), PetMood.idle);
      expect(PetMood.fromArguments({'mood': 42}), PetMood.idle);
    });
  });
}
