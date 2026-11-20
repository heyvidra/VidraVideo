import 'dart:io' show Platform;

import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:material_ui/material_ui.dart';
import 'package:vidra_player/core/interfaces/window_delegate.dart';

import '../../config/app_config.dart';
import '../utils/window.dart';

class BitsdojoWindowDelegate implements WindowDelegate {
  static const _pipTransitionDuration = Duration(milliseconds: 280);

  /// Windows keeps its shorter travel — it was tuned against the flash this
  /// used to work around, and the shorter the move the less there is to see.
  ///
  /// It used to resolve to ZERO here, because the whole transition was
  /// hand-rolled below for Windows and this value only fed the other
  /// platforms. `animateTo` splits resize from travel itself now, so a real
  /// duration reaches it — and zero would have quietly cost Windows the eased
  /// reposition it always had.
  static const _windowsPipTransitionDuration = Duration(milliseconds: 140);

  Duration get _resolvedPipTransitionDuration => Platform.isWindows
      ? _windowsPipTransitionDuration
      : _pipTransitionDuration;

  @override
  Future<void> close() async {
    appWindow.close();
  }

  @override
  Future<void> enterFullscreen() async {
    WindowHelper.isFullscreen = true;
    appWindow.toggleFullScreen();
  }

  @override
  Future<void> exitFullscreen() async {
    WindowHelper.isFullscreen = false;
    appWindow.toggleFullScreen();
  }

  @override
  Future<void> maximize() async {
    appWindow.maximize();
  }

  @override
  Future<void> minimize() async {
    appWindow.minimize();
  }

  @override
  Future<void> restore() async {
    appWindow.restore();
  }

  @override
  Future<void> setTitle(String title) async {
    appWindow.title = title;
  }

  @override
  Future<void> toggleFullscreen() async {
    WindowHelper.isFullscreen = !WindowHelper.isFullscreen;
    appWindow.toggleFullScreen();
  }

  /// PiP transitions, one at a time.
  ///
  /// The player calls these un-awaited, so a second toggle (or a close,
  /// which exits PiP) could start while the first was still animating. Its
  /// "exact snapshot" then captured a half-animated frame into a slot — every
  /// later PiP opened at that in-between size — and the first transition's
  /// settle lowered [WindowHelper.transitionInProgress] under the second.
  Future<void> _pipQueue = Future.value();

  Future<void> _inOrder(Future<void> Function() transition) {
    final run = _pipQueue.then((_) => transition());
    _pipQueue = run.catchError((Object _) {});
    return run;
  }

  @override
  Future<void> enterPip() => _inOrder(_enterPip);

  @override
  Future<void> exitPip() => _inOrder(_exitPip);

  Future<void> _enterPip() async {
    // Exact pre-transition snapshot, written immediately — a debounced save
    // here used to be cancelled by the transition's own metric events, so
    // the normal-mode frame was never persisted at all.
    WindowHelper.transitionInProgress = true;
    try {
      await WindowHelper.saveNow(isPipOverride: false);

      final targetSize =
          await WindowHelper.getSavedWindowSize(isPipOverride: true) ??
          AppConfig.playerMiniSize;
      // Straight to where the user parked the pip window last time — the
      // bottom-right default is only for the first entry (or a spot that
      // left the screen). A detour through bottom-right reads as the window
      // "flying around".
      final savedPipPosition = await WindowHelper.savedPipPosition();
      // Stored logical; animateTo/position speak physical pixels on Windows.
      final pipTarget = savedPipPosition == null
          ? null
          : WindowHelper.logicalToPhysical(savedPipPosition);

      appWindow.minSize = AppConfig.playerMiniSize;
      appWindow.alwaysOnTop = true;
      WindowHelper.isPip = true;

      await appWindow.animateTo(
        size: targetSize,
        alignment: pipTarget == null ? Alignment.bottomRight : null,
        position: pipTarget,
        duration: _resolvedPipTransitionDuration,
      );
    } finally {
      await _settleTransition();
    }
  }

  Future<void> _exitPip() async {
    WindowHelper.transitionInProgress = true;
    try {
      await WindowHelper.saveNow(isPipOverride: true);

      final targetSize = await WindowHelper.playerSize();
      // Return to where the window was BEFORE pip (saved by enterPip's
      // snapshot); center only when nothing usable is stored.
      final savedPosition = await WindowHelper.savedPlayerPosition();
      // Stored logical; animateTo/position speak physical pixels on Windows.
      final normalTarget = savedPosition == null
          ? null
          : WindowHelper.logicalToPhysical(savedPosition);

      appWindow.minSize = AppConfig.playerMiniSize;
      WindowHelper.isPip = false;

      await appWindow.animateTo(
        size: targetSize,
        alignment: normalTarget == null ? Alignment.center : null,
        position: normalTarget,
        duration: _resolvedPipTransitionDuration,
      );

      appWindow.alwaysOnTop = false;
    } finally {
      await _settleTransition();
    }
  }

  /// Metric events trail the native animation by a frame or two; keep the
  /// suppression up briefly past the end so the tail cannot be persisted.
  Future<void> _settleTransition() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    WindowHelper.transitionInProgress = false;
  }
}
