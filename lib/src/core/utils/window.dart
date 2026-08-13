import 'dart:async';
import 'package:flutter/material.dart';

import 'package:bitsdojo_window/bitsdojo_window.dart';
import '../../config/app_config.dart';
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

  /// Coordinates at or beyond this band are the CreateWindow int16 clamp
  /// (±32767), not anything a user parked a window at — see
  /// [savedPlayerPosition].
  static const double _insaneCoordinate = 30000;

  static void init(SettingsRepository repository) {
    _repository = repository;
  }

  /// Physical-to-logical ratio of the current window, recovered from the two
  /// getters the platform interface already exposes: on Windows
  /// `appWindow.rect` is physical pixels while `appWindow.size` is logical,
  /// so their width ratio is the DPI scale. On macOS/Linux both are points
  /// and the ratio is 1. Falls back to 1 when the window cannot be measured.
  static double currentScale() {
    final logical = appWindow.size;
    final physical = appWindow.rect;
    if (logical.width <= 0 || physical.width <= 0) return 1.0;
    final scale = physical.width / logical.width;
    if (!scale.isFinite || scale <= 0) return 1.0;
    return scale;
  }

  /// Convert a stored LOGICAL point to the physical pixels the in-engine
  /// window APIs (`position`, `animateTo`) speak on Windows. Identity on
  /// macOS/Linux.
  static Offset logicalToPhysical(Offset logical) => logical * currentScale();

  static Future<Size> playerSize() async {
    final screenSize = appWindow.workingScreenSize;
    final playerWidth = screenSize.width * 0.75;
    final playerHeight = playerWidth / (16 / 9);

    final savedSize = await getSavedWindowSize(isPipOverride: false);
    if (savedSize == null) return Size(playerWidth, playerHeight);

    // Rows written before the units fix stored PHYSICAL pixels here; on a
    // scaled display those read as up-to-NxN logical. Clamping into the
    // working screen keeps a legacy row from producing a window larger than
    // the display; one resize later the row is logical and exact.
    if (screenSize.width >= AppConfig.playerMiniSize.width &&
        screenSize.height >= AppConfig.playerMiniSize.height) {
      return Size(
        savedSize.width.clamp(AppConfig.playerMiniSize.width, screenSize.width),
        savedSize.height.clamp(
          AppConfig.playerMiniSize.height,
          screenSize.height,
        ),
      );
    }
    return savedSize;
  }

  /// Saved top-left for the normal-mode player window, in LOGICAL pixels
  /// (GLOBAL desktop coordinates — negative values are legal on multi-display
  /// rigs, e.g. a monitor above the primary).
  ///
  /// Null — which every caller turns into "center on ready" — when nothing
  /// usable is stored. "Usable" excludes the CreateWindow clamp band:
  /// Windows truncates creation coordinates to int16, so a window created
  /// from an oversized restore parks invisibly at (32767, 32767), and
  /// closing it there wrote the parking spot back to this slot. Rejecting
  /// the band both breaks that loop and heals rows already poisoned by the
  /// 1.7.2-dev builds — the next open centers, the next close saves a real
  /// position again.
  static Future<Offset?> savedPlayerPosition() async {
    if (_repository == null) return null;
    final settings = await _repository!.getSettings();
    return _sanePosition(settings.playerWindowX, settings.playerWindowY);
  }

  /// Where the user last parked the pip window (LOGICAL, global
  /// coordinates), or null on first pip — callers fall back to bottom-right.
  /// Same clamp-band rejection as [savedPlayerPosition]; animateTo to a
  /// detached monitor's coordinates remains the accepted residual risk.
  static Future<Offset?> savedPipPosition() async {
    if (_repository == null) return null;
    final settings = await _repository!.getSettings();
    return _sanePosition(settings.playerPipX, settings.playerPipY);
  }

  /// Where the user last parked the pet: its window's BOTTOM-RIGHT corner
  /// (LOGICAL, global). The anchor rather than the top-left because the pet
  /// window changes size while speaking, and only that corner survives it.
  static Future<Offset?> savedPetAnchor() async {
    if (_repository == null) return null;
    final settings = await _repository!.getSettings();
    return _sanePosition(settings.petWindowX, settings.petWindowY);
  }

  /// Persists the pet window's bottom-right corner. Best-effort, like every
  /// other geometry write here.
  static Future<void> savePetAnchor(Offset anchor) async {
    if (_repository == null) return;
    try {
      final settings = await _repository!.getSettings();
      settings.petWindowX = anchor.dx;
      settings.petWindowY = anchor.dy;
      await _repository!.updateSettings(settings);
    } catch (e) {
      logD('WindowHelper', '保存宠物位置失败: $e');
    }
  }

  static Offset? _sanePosition(double? x, double? y) {
    if (x == null || y == null) return null;
    if (x.abs() >= _insaneCoordinate || y.abs() >= _insaneCoordinate) {
      return null;
    }
    return Offset(x, y);
  }

  static Size windowSize() {
    return appWindow.size;
  }

  static Rect windowRect() {
    return appWindow.rect;
  }

  /// The window frame in LOGICAL pixels, captured now.
  ///
  /// This is the unit every consumer of the stored slots speaks:
  /// `openNewWindow` hands size/position to the native window factory, which
  /// multiplies by the monitor DPI scale at CreateWindow, and the Dart size
  /// setter scales by the window DPI itself. Storing `appWindow.rect` raw —
  /// physical on Windows — fed each restore through one extra multiply, and
  /// every save/restore cycle DOUBLED the stored position on a 200% display
  /// until it hit the int16 clamp and the window vanished off-screen.
  static Rect _logicalRectNow() {
    final rect = appWindow.rect;
    final scale = currentScale();
    if (scale == 1.0) return rect;
    return Rect.fromLTWH(
      rect.left / scale,
      rect.top / scale,
      rect.width / scale,
      rect.height / scale,
    );
  }

  /// Debounced save for metric churn (user drag-resizes). Dropped entirely
  /// during programmatic transitions — see [transitionInProgress].
  static void saveWindowSize({bool? isPipOverride}) {
    if (_repository == null || transitionInProgress) return;

    final pip = isPipOverride ?? isPip;
    // Snapshot rect AND scale now — by the time the debounce fires the
    // window may sit on another monitor or be mid-close.
    final rect = _logicalRectNow();

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
    await _write(pip: pip, rect: _logicalRectNow());
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
