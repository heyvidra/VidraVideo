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
    WindowHelper.saveWindowSize(isPipOverride: false);

    final targetSize =
        await WindowHelper.getSavedWindowSize(isPipOverride: true) ??
        AppConfig.playerMiniSize;

    appWindow.minSize = AppConfig.playerMiniSize;
    appWindow.alwaysOnTop = true;
    WindowHelper.isPip = true;

    if (Platform.isWindows) {
      await _animateWindowsPipTransition(
        targetSize: targetSize,
        targetAlignment: Alignment.bottomRight,
      );
      return;
    }

    await appWindow.animateTo(
      size: targetSize,
      alignment: Alignment.bottomRight,
      duration: _resolvedPipTransitionDuration,
    );
  }

  @override
  Future<void> exitPip() async {
    WindowHelper.saveWindowSize(isPipOverride: true);

    final targetSize = await WindowHelper.playerSize();

    appWindow.minSize = AppConfig.playerMiniSize;
    WindowHelper.isPip = false;

    if (Platform.isWindows) {
      await _animateWindowsPipTransition(
        targetSize: targetSize,
        targetAlignment: Alignment.center,
      );
      appWindow.alwaysOnTop = false;
      return;
    }

    await appWindow.animateTo(
      size: targetSize,
      alignment: Alignment.center,
      duration: _resolvedPipTransitionDuration,
    );

    appWindow.alwaysOnTop = false;
  }

  Future<void> _animateWindowsPipTransition({
    required Size targetSize,
    required Alignment targetAlignment,
  }) async {
    // On Windows, animating size and position together tends to flash a white
    // background during DWM/compositor repaints. Keep the resize immediate and
    // only ease the final repositioning.
    appWindow.size = targetSize;
    await appWindow.animateTo(
      alignment: targetAlignment,
      duration: _windowsPipTransitionDuration,
      curve: Curves.easeOutCubic,
    );
  }
}
