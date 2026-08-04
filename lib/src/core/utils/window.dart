import 'dart:async';
import 'package:flutter/material.dart';

import 'package:bitsdojo_window/bitsdojo_window.dart';
import '../../features/settings/data/settings_repository.dart';
import 'log.dart';

class WindowHelper {
  static SettingsRepository? _repository;
  static bool isPip = false;

  /// True while enterPip/exitPip animates the window. Metric events during
  /// that window carry mid-animation frames — persisting one of those is how
  /// the pip slot ended up holding a full normal-window size (found in the
  /// field: pip slot = 1136x658, normal slot = 881.898x578.933, both
  /// fractional animation frames). The transition edges save exact snapshots
  /// via [saveNow]; everything in between must be dropped.
  static bool transitionInProgress = false;

  // One debounce PER SLOT. A single shared timer let the pip transition's
  // metric churn cancel the pending pre-transition normal-slot snapshot —
  // the normal size was simply never written.
  static Timer? _normalDebounce;
  static Timer? _pipDebounce;

  static void init(SettingsRepository repository) {
    _repository = repository;
  }

  static Future<Size> playerSize() async {
    final screenSize = appWindow.workingScreenSize;
    final playerWidth = screenSize.width * 0.75;
    final playerHeight = playerWidth / (16 / 9);

    final savedSize = await getSavedWindowSize(isPipOverride: false);
    return savedSize ?? Size(playerWidth, playerHeight);
  }

  /// Saved top-left for the normal-mode player window (GLOBAL desktop
  /// coordinates — negative values are legal on multi-display rigs, e.g. a
  /// monitor above the primary). No geometry check here: only the native
  /// side can enumerate screens, and openNewWindow centers instead when the
  /// restored frame intersects no attached screen.
  static Future<Offset?> savedPlayerPosition() async {
    if (_repository == null) return null;
    final settings = await _repository!.getSettings();
    final x = settings.playerWindowX;
    final y = settings.playerWindowY;
    if (x == null || y == null) return null;
    return Offset(x, y);
  }

  /// Where the user last parked the pip window (global coordinates), or
  /// null on first pip — callers fall back to bottom-right. Same reasoning
  /// as [savedPlayerPosition] for the absence of a geometry check; the pip
  /// snapshot is at most one session old and animateTo to a detached
  /// monitor's coordinates is the accepted residual risk.
  static Future<Offset?> savedPipPosition() async {
    if (_repository == null) return null;
    final settings = await _repository!.getSettings();
    final x = settings.playerPipX;
    final y = settings.playerPipY;
    if (x == null || y == null) return null;
    return Offset(x, y);
  }

  static Size windowSize() {
    return appWindow.size;
  }

  static Rect windowRect() {
    return appWindow.rect;
  }

  /// Debounced save for metric churn (user drag-resizes). Dropped entirely
  /// during programmatic transitions — see [transitionInProgress].
  static void saveWindowSize({bool? isPipOverride}) {
    if (_repository == null || transitionInProgress) return;

    final pip = isPipOverride ?? isPip;
    final rect = appWindow.rect;

    final timer = Timer(const Duration(milliseconds: 500), () {
      _write(pip: pip, rect: rect);
    });
    if (pip) {
      _pipDebounce?.cancel();
      _pipDebounce = timer;
    } else {
      _normalDebounce?.cancel();
      _normalDebounce = timer;
    }
  }

  /// Exact snapshot, written immediately. For the two moments the debounce
  /// cannot serve: transition edges (the very next metric event would carry
  /// an animation frame) and close (this engine's timers die with it — a
  /// resize finished <500ms before closing was previously lost, and close is
  /// also the ONLY point that captures pure window MOVES, which emit no
  /// metric events at all).
  static Future<void> saveNow({bool? isPipOverride}) async {
    if (_repository == null) return;
    final pip = isPipOverride ?? isPip;
    // The pending debounce for this slot is staler than what we hold now.
    if (pip) {
      _pipDebounce?.cancel();
    } else {
      _normalDebounce?.cancel();
    }
    await _write(pip: pip, rect: appWindow.rect);
  }

  static Future<void> _write({required bool pip, required Rect rect}) async {
    try {
      final settings = await _repository!.getSettings();
      if (pip) {
        settings.playerPipWidth = rect.width;
        settings.playerPipHeight = rect.height;
        settings.playerPipX = rect.left;
        settings.playerPipY = rect.top;
      } else {
        settings.playerNormalWidth = rect.width;
        settings.playerNormalHeight = rect.height;
        settings.playerWindowX = rect.left;
        settings.playerWindowY = rect.top;
      }
      await _repository!.updateSettings(settings);
    } catch (e) {
      logD('WindowHelper', '保存窗口尺寸失败: $e');
    }
  }

  static Future<Size?> getSavedWindowSize({bool? isPipOverride}) async {
    if (_repository == null) return null;
    final settings = await _repository!.getSettings();
    final pip = isPipOverride ?? isPip;
    if (pip) {
      if (settings.playerPipWidth != null && settings.playerPipHeight != null) {
        return Size(settings.playerPipWidth!, settings.playerPipHeight!);
      }
    } else {
      if (settings.playerNormalWidth != null &&
          settings.playerNormalHeight != null) {
        return Size(settings.playerNormalWidth!, settings.playerNormalHeight!);
      }
    }
    return null;
  }
}
