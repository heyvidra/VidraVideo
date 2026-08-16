import 'package:flutter/material.dart';

class AppSettings {
  static const int singletonId = 1;

  int id = singletonId; // Singleton, always use fixed id

  // Download settings
  String? downloadPath; // null = use default (Downloads folder)

  // Download manager settings
  int maxConcurrentDownloads;

  // Parallel HLS segment fetches within a single download (vidraDlp).
  int segmentConcurrency;

  String? lastDataSourceId;

  // Netscape cookies.txt path forwarded to vidraDlp for gated sites. null = none.
  String? cookieFile;

  ThemeMode themeMode;

  // Window sizes
  double? playerNormalWidth;
  double? playerNormalHeight;
  double? playerPipWidth;
  double? playerPipHeight;

  // Player window top-left in normal mode (restore-on-reopen)
  double? playerWindowX;
  double? playerWindowY;

  // Pip window top-left (where the user parked the mini window)
  double? playerPipX;
  double? playerPipY;

  String? locale;

  /// Whether the desktop pet window opens with the app.
  bool showPet;

  /// The pet window's bottom-right corner as last parked by the user.
  double? petWindowX;
  double? petWindowY;

  /// 减少特效: 'on' / 'off', null = auto (on for Intel-GPU Macs).
  /// See [ReduceEffects] for the resolution.
  String? reduceEffects;

  /// Whether this machine reports diagnostics. See [Telemetry].
  bool telemetryEnabled;

  /// Where the player opens: 'window' / 'in_app', null = auto.
  /// See [PlayerWindowMode] for the resolution.
  String? playerWindowMode;

  /// Data sources the user switched off, comma-joined ids. Null = all on.
  /// Read with [parseSourceIds], written with [formatSourceIds].
  String? disabledDataSourceIds;

  AppSettings({
    this.downloadPath,
    this.maxConcurrentDownloads = 3,
    this.segmentConcurrency = 6,
    this.themeMode = ThemeMode.dark,
    this.playerNormalWidth,
    this.playerNormalHeight,
    this.playerPipWidth,
    this.playerPipHeight,
    this.playerWindowX,
    this.playerWindowY,
    this.playerPipX,
    this.playerPipY,
    this.locale,
    this.showPet = false,
    this.telemetryEnabled = true,
  });
}

/// Splits the stored form of a source-id set. Tolerant of the shapes a hand
/// edit or an interrupted write can leave: blanks and stray spaces drop out.
Set<String> parseSourceIds(String? stored) {
  if (stored == null || stored.isEmpty) return const {};
  return stored
      .split(',')
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toSet();
}

/// The stored form of [ids]. Sorted, so the same set always produces the same
/// string and a settings row does not churn on rewrites. Empty is stored as
/// null, so "nothing disabled" has one representation rather than two.
String? formatSourceIds(Set<String> ids) {
  if (ids.isEmpty) return null;
  final sorted = ids.toList()..sort();
  return sorted.join(',');
}
