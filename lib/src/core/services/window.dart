import 'dart:io' show Platform;

import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';
import 'package:vidra_player/core/interfaces/window_delegate.dart';

import '../../config/app_config.dart';
import '../utils/window.dart';

class BitsdojoWindowDelegate implements WindowDelegate {
  static const _pipTransitionDuration = Duration(milliseconds: 280);
  static const _windowsPipTransitionDuration = Duration(milliseconds: 140);

  Duration get _resolvedPipTransitionDuration =>
      Platform.isWindows ? Duration.zero : _pipTransitionDuration;

  @override
  Future<void> close() async {
    appWindow.close();
  }

  @override
  Future<void> enterFullscreen() async {
    appWindow.toggleFullScreen();
  }

  @override
  Future<void> exitFullscreen() async {
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
    appWindow.toggleFullScreen();
  }

  @override
  Future<void> enterPip() async {
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

      appWindow.minSize = AppConfig.playerMiniSize;
      appWindow.alwaysOnTop = true;
      WindowHelper.isPip = true;

      if (Platform.isWindows) {
        await _animateWindowsPipTransition(
          targetSize: targetSize,
          targetAlignment: savedPipPosition == null
              ? Alignment.bottomRight
              : null,
          targetPosition: savedPipPosition,
        );
        return;
      }

      await appWindow.animateTo(
        size: targetSize,
        alignment: savedPipPosition == null ? Alignment.bottomRight : null,
        position: savedPipPosition,
        duration: _resolvedPipTransitionDuration,
      );
    } finally {
      await _settleTransition();
    }
  }

  @override
  Future<void> exitPip() async {
    WindowHelper.transitionInProgress = true;
    try {
      await WindowHelper.saveNow(isPipOverride: true);

      final targetSize = await WindowHelper.playerSize();
      // Return to where the window was BEFORE pip (saved by enterPip's
      // snapshot); center only when nothing usable is stored.
      final savedPosition = await WindowHelper.savedPlayerPosition();

      appWindow.minSize = AppConfig.playerMiniSize;
      WindowHelper.isPip = false;

      if (Platform.isWindows) {
        await _animateWindowsPipTransition(
          targetSize: targetSize,
          targetAlignment: savedPosition == null ? Alignment.center : null,
          targetPosition: savedPosition,
        );
        appWindow.alwaysOnTop = false;
        return;
      }

      await appWindow.animateTo(
        size: targetSize,
        alignment: savedPosition == null ? Alignment.center : null,
        position: savedPosition,
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

  Future<void> _animateWindowsPipTransition({
    required Size targetSize,
    Alignment? targetAlignment,
    Offset? targetPosition,
  }) async {
    // On Windows, animating size and position together tends to flash a white
    // background during DWM/compositor repaints. Keep the resize immediate and
    // only ease the final repositioning.
    appWindow.size = targetSize;
    await appWindow.animateTo(
      alignment: targetAlignment,
      position: targetPosition,
      duration: _windowsPipTransitionDuration,
      curve: Curves.easeOutCubic,
    );
  }
}
