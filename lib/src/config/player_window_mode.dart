import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/settings/domain/app_settings.dart';
import '../features/settings/presentation/settings_provider.dart';
import 'reduce_effects.dart';

/// Where playback opens — as stored in [AppSettings.playerWindowMode].
///
/// [auto] resolves by GPU class, and it is the default for the same reason
/// [ReduceEffectsMode.auto] is: the hardware answer is the one the user cannot
/// judge. A second window is a second Flutter engine — its own isolate, its
/// own raster thread, its own copy of the framework — and on a machine that
/// already misses the frame budget drawing a catalog, paying for two of them
/// to show one video is the wrong trade. Machines that can afford it keep the
/// window, which is genuinely the better experience: playback survives
/// walking around the library, and it can sit on a second display.
enum PlayerWindowMode {
  auto(null),
  window('window'),
  inApp('in_app');

  const PlayerWindowMode(this.stored);

  /// The value persisted in settings; null is auto so a database predating
  /// the column needs no backfill.
  final String? stored;

  static PlayerWindowMode fromStored(String? raw) => switch (raw) {
    'window' => window,
    'in_app' => inApp,
    _ => auto,
  };
}

class PlayerWindow {
  const PlayerWindow._();

  /// Whether playback should stay in the window it was started from.
  ///
  /// [PlayerWindowMode.auto] follows [ReduceEffects.lowPowerGpu] — the same
  /// detector, deliberately: "can this machine afford the pretty version" and
  /// "can it afford a second engine" are the same question about the same
  /// hardware, and two probes that could ever disagree would be worse than
  /// one that cannot.
  static bool resolve(PlayerWindowMode mode) => switch (mode) {
    PlayerWindowMode.inApp => true,
    PlayerWindowMode.window => false,
    PlayerWindowMode.auto => ReduceEffects.lowPowerGpu,
  };

  /// The resolved value, readable synchronously.
  ///
  /// Every launch site is a tap handler with no time to await a database, so
  /// this follows [ReduceEffects.current]: seeded by main() from the settings
  /// row it has already loaded, re-seeded when the switch is flipped.
  static bool inApp = false;

  static void seed(AppSettings settings) {
    inApp = resolve(PlayerWindowMode.fromStored(settings.playerWindowMode));
  }
}

/// Whether playback opens in this window, live.
///
/// Same shape and the same reasoning as `reduceEffectsProvider`: read what
/// main() seeded, and let the settings screen push changes through [set].
class PlayerWindowNotifier extends Notifier<bool> {
  @override
  bool build() => PlayerWindow.inApp;

  /// Persists [mode] and republishes the resolved value.
  Future<void> set(PlayerWindowMode mode) async {
    final repo = ref.read(settingsRepositoryProvider);
    final settings = await repo.getSettings();
    settings.playerWindowMode = mode.stored;
    await repo.updateSettings(settings);
    PlayerWindow.seed(settings);
    state = PlayerWindow.inApp;
  }
}

final playerWindowProvider = NotifierProvider<PlayerWindowNotifier, bool>(
  PlayerWindowNotifier.new,
);
