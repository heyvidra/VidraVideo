import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../utils/log.dart';
import 'segment_downloader.dart';
import 'vidradlp/vidra_config.dart';
import '../../features/settings/data/settings_repository.dart';

class DownloadService {
  DownloadService(this._settingsRepo, {SegmentDownloader? downloader})
    : _injected = downloader;

  // Test override; otherwise a downloader is created per-download using the
  // current segment-concurrency setting (so a settings change takes effect
  // without restarting the app).
  final SegmentDownloader? _injected;
  final SettingsRepository? _settingsRepo;

  /// Download and convert m3u8 to mp4 using pure Dart implementation
  /// Returns the path to the downloaded file
  Future<String?> downloadM3u8ToMp4({
    required String url,
    required String filename,
    String? formatId,
    DownloadProgressCallback? onProgress,
    bool Function()? shouldCancel,
  }) async {
    String? outputPath;
    try {
      // Resolve downloads directory + segment concurrency + cookie config from
      // settings (one read).
      Directory downloadsDir;
      int segmentConcurrency = 6;
      String? configJson;
      final settingsRepo = _settingsRepo;
      if (settingsRepo != null) {
        final settings = await settingsRepo.getSettings();
        segmentConcurrency = settings.segmentConcurrency;
        configJson = vidraClientConfigJson(cookieFile: settings.cookieFile);
        final path =
            (settings.downloadPath != null && settings.downloadPath!.isNotEmpty)
            ? settings.downloadPath!
            : await settingsRepo.getDefaultDownloadPath();
        downloadsDir = Directory(path);
      } else {
        final dir = await getDownloadsDirectory();
        if (dir == null) {
          throw Exception('Could not access downloads directory');
        }
        downloadsDir = dir;
      }
      final downloader =
          _injected ??
          createSegmentDownloader(
            segmentConcurrency: segmentConcurrency,
            configJson: configJson,
          );

      // Ensure directory exists
      if (!await downloadsDir.exists()) {
        await downloadsDir.create(recursive: true);
      }

      // Target extension. Extractor downloads (formatId set — YouTube etc.) are
      // http/DASH mp4, so write `.mp4` directly. Catalog HLS (formatId null)
      // writes `.ts` and lets vidraDlp remux TS→MP4 in-SDK — that in-SDK remux
      // only fires for a `.ts` target, so keep it for that path.
      final ext = formatId != null ? 'mp4' : 'ts';
      outputPath = '${downloadsDir.path}/$filename.$ext';

      // Delete any stale outputs (both possible extensions).
      for (final stale in [
        '${downloadsDir.path}/$filename.ts',
        '${downloadsDir.path}/$filename.mp4',
      ]) {
        final f = File(stale);
        if (await f.exists()) await f.delete();
      }

      logD('DownloadService', 'Starting download: $url -> $outputPath');

      final produced = await downloader.downloadM3U8(
        m3u8Url: url,
        outputPath: outputPath,
        formatId: formatId,
        onProgress: onProgress,
        shouldCancel: shouldCancel,
      );

      logD('DownloadService', 'Download completed successfully: $produced');

      return produced;
    } catch (e) {
      if (outputPath != null) {
        final outputFile = File(outputPath);
        if (await outputFile.exists()) {
          await outputFile.delete();
        }
      }
      logD('DownloadService', 'Error downloading video: $e');
      rethrow;
    }
  }

  /// Get the downloads directory
  /// Uses app's Documents/Downloads folder to avoid sandbox permission issues
  Future<Directory?> getDownloadsDirectory() async {
    // For sandboxed apps, use the app's Documents directory
    final appDocDir = await getApplicationDocumentsDirectory();

    // Create a Downloads subdirectory within Documents
    final downloadsDir = Directory('${appDocDir.path}/Downloads');
    if (!await downloadsDir.exists()) {
      await downloadsDir.create(recursive: true);
    }

    logD('DownloadService', 'Downloads will be saved to: ${downloadsDir.path}');

    return downloadsDir;
  }
}
