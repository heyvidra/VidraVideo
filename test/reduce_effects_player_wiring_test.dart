import 'package:flutter_test/flutter_test.dart';
import 'package:vidra/src/config/reduce_effects.dart';
import 'package:vidra/src/features/settings/domain/app_settings.dart';
import 'package:vidra_player/vidra_player.dart' show PlayerEffects;

/// The player package keeps its own copy of the 减少特效 switch, and nothing in
/// either package fails to compile when the two drift apart — the blur just
/// quietly comes back on the machines the switch exists for. So the seam is
/// pinned here: seeding the app's switch must carry the player's with it.
void main() {
  AppSettings settingsWith(String? reduceEffects) =>
      AppSettings()..reduceEffects = reduceEffects;

  tearDown(() {
    PlayerEffects.reduced = false;
    ReduceEffects.current = false;
  });

  test("'on' reaches the player", () {
    ReduceEffects.seed(settingsWith('on'));

    expect(ReduceEffects.current, isTrue);
    expect(PlayerEffects.reduced, isTrue);
  });

  test("'off' reaches the player", () {
    PlayerEffects.reduced = true;

    ReduceEffects.seed(settingsWith('off'));

    expect(ReduceEffects.current, isFalse);
    expect(PlayerEffects.reduced, isFalse);
  });

  // auto resolves by GPU class, which differs between this machine and CI, so
  // the assertion is that the two agree — not which way they landed.
  test('auto hands the player whatever it resolved to', () {
    ReduceEffects.seed(settingsWith(null));

    expect(PlayerEffects.reduced, ReduceEffects.current);
    expect(ReduceEffects.current, ReduceEffects.lowPowerGpu);
  });
}
