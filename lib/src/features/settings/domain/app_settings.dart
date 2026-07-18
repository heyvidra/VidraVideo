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

  String? locale;

  AppSettings({
    this.downloadPath,
    this.maxConcurrentDownloads = 3,
    this.segmentConcurrency = 6,
    this.themeMode = ThemeMode.dark,
    this.playerNormalWidth,
    this.playerNormalHeight,
    this.playerPipWidth,
    this.playerPipHeight,
    this.locale,
  });
}
