import 'dart:async';
import 'package:flutter/material.dart';

import 'package:bitsdojo_window/bitsdojo_window.dart';
import '../../features/settings/data/settings_repository.dart';
import 'log.dart';

class WindowHelper {
  static SettingsRepository? _repository;
  static bool isPip = false;
  static Timer? _saveDebounceTimer;

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

  static Size windowSize() {
    return appWindow.size;
  }

  static Rect windowRect() {
    return appWindow.rect;
  }

  static void saveWindowSize({bool? isPipOverride}) {
    if (_repository == null) return;

    final pip = isPipOverride ?? isPip;
    final size = appWindow.size;

    _saveDebounceTimer?.cancel();
    _saveDebounceTimer = Timer(const Duration(milliseconds: 500), () async {
      try {
        final settings = await _repository!.getSettings();
        if (pip) {
          settings.playerPipWidth = size.width;
          settings.playerPipHeight = size.height;
        } else {
          settings.playerNormalWidth = size.width;
          settings.playerNormalHeight = size.height;
        }
        await _repository!.updateSettings(settings);
      } catch (e) {
        logD('WindowHelper', '保存窗口尺寸失败: $e');
      }
    });
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
