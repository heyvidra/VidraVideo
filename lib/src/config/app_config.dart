import 'dart:ui';

/// Application configuration constants
class AppConfig {
  // App Information
  static const String appName = 'Vidra';
  static const String appVersion = '1.0.0';

  // Download Configuration
  static const int maxConcurrentDownloads = 3;
  static const int downloadChunkSize = 5; // for M3U8 downloader

  static const Size playerMiniSize = Size(540, 305);
}
