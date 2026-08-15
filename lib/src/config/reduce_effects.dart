import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vidra_player/vidra_player.dart' show PlayerEffects;

import '../features/settings/domain/app_settings.dart';
import '../features/settings/presentation/settings_provider.dart';

/// 减少特效 — the switch's three states as stored in [AppSettings.reduceEffects].
///
/// [auto] resolves by GPU class, and it is the default precisely because the
/// hardware answer is the one thing the user cannot reasonably judge: the
/// glassmorphism this app ships is fine on Apple Silicon and buries a 2016
/// Intel machine. An explicit choice always wins over the hardware default,
/// in both directions — the degradations behind this switch are real, visible
/// look changes, never a silent flattening.
enum ReduceEffectsMode {
  auto(null),
  on('on'),
  off('off');

  const ReduceEffectsMode(this.stored);

  /// The value persisted in settings; null is auto so a database predating
  /// the column needs no backfill.
  final String? stored;

  static ReduceEffectsMode fromStored(String? raw) => switch (raw) {
    'on' => on,
    'off' => off,
    _ => auto,
  };
}

class ReduceEffects {
  const ReduceEffects._();

  static bool? _lowPowerGpu;

  /// Intel Macs (and anything else that is a Mac but not Apple Silicon).
  ///
  /// Every Intel Mac pays full-window alpha compositing and behind-window
  /// blur out of a GPU class that thermal-throttles under it; Apple Silicon
  /// does not care. Non-mac platforms answer false — their window effects
  /// are already disabled wholesale in the window configuration.
  static bool get lowPowerGpu => _lowPowerGpu ??= _detectLowPowerGpu();

  static bool _detectLowPowerGpu() {
    if (!Platform.isMacOS) return false;
    // The VM embeds the host arch in Platform.version ('… on "macos_x64"').
    // Read that rather than exec'ing sysctl: this runs during the first
    // build, where spawning a process is a synchronous stall — and in
    // sandboxed test environments, a hang.
    return Platform.version.contains('x64');
  }

  static bool resolve(ReduceEffectsMode mode) => switch (mode) {
    ReduceEffectsMode.on => true,
    ReduceEffectsMode.off => false,
    ReduceEffectsMode.auto => lowPowerGpu,
  };

  /// The resolved value, readable synchronously.
  ///
  /// The window-effect builders run during window setup, before any provider
  /// scope exists, so main() seeds this from the settings row it has already
  /// loaded; the settings screen re-seeds it when the user flips the switch.
  static bool current = false;

  static void seed(AppSettings settings) {
    current = resolve(ReduceEffectsMode.fromStored(settings.reduceEffects));
    // The player package carries its own copy of this switch, because it is a
    // package and cannot read this one. Set it HERE rather than at the call
    // sites: _runApp() seeds every engine — player and pet included, each its
    // own isolate with its own statics — and the settings screen re-seeds on
    // every toggle, so this one line is the whole wiring for both.
    //
    // It gates the player's BackdropFilter panels, which read back the live
    // video texture every frame. That readback is the single most expensive
    // thing the player does on an Intel Mac.
    PlayerEffects.reduced = current;
  }
}

/// Whether the running UI should degrade its effects, live.
///
/// Reads the value main() already seeded rather than watching the settings
/// stream, and the settings screen pushes changes through [set]. That
/// direction matters: this is watched by glass panels, skeletons and every
/// card in a grid, and hanging all of them off a drift query stream would
/// subscribe the whole UI to the database to learn one boolean that changes
/// only when a person opens Settings and taps.
class ReduceEffectsNotifier extends Notifier<bool> {
  @override
  bool build() => ReduceEffects.current;

  /// Persists [mode] and republishes the resolved value.
  Future<void> set(ReduceEffectsMode mode) async {
    final repo = ref.read(settingsRepositoryProvider);
    final settings = await repo.getSettings();
    settings.reduceEffects = mode.stored;
    await repo.updateSettings(settings);
    ReduceEffects.seed(settings);
    state = ReduceEffects.current;
  }
}

final reduceEffectsProvider = NotifierProvider<ReduceEffectsNotifier, bool>(
  ReduceEffectsNotifier.new,
);
