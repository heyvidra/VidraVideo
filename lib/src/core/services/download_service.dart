import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../utils/log.dart';
import 'segment_downloader.dart';
import 'vidradlp/vidra_config.dart';
import 'vidradlp/vidradlp_ffi.dart' show vidradlpLibraryAvailable;
import 'vidradlp/vidradlp_flutter.dart' show VidraDlpClient;
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
      int segmentConcurrency = 8;
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

      // Target extension. Extractor downloads (formatId set — YouTube etc.)
      // are http/DASH mp4, so write `.mp4` directly. Catalog downloads
      // (formatId null) pass the SDK's `%(ext)s` template so the file is
      // named by the ACTUAL container: m3u8 resolves to `.ts` (and the
      // in-SDK TS→MP4 remux fires as before), a direct-mp4 source resolves
      // to `.mp4` with no remux — the old hardcoded `.ts` sent MP4 bytes
      // into a doomed TS parse. The SDK reports the resolved path in the
      // finished event.
      final ext = formatId != null ? 'mp4' : '%(ext)s';
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

  /// Deletes the resume state vidraDlp leaves behind when a download stops
  /// short. Returns how many jobs were swept.
  ///
  /// vidraDlp keeps `<output>.vidradlp.tmp` plus a small `.tmp.hls` manifest on
  /// purpose, so an interrupted job can carry on where it stopped. This app
  /// never carries one on — [DownloadManager.resumeTask] re-queues a failed or
  /// cancelled episode and starts it from scratch — and nothing here deleted
  /// them either: `deleteEpisode`/`deleteTask` only remove the finished output
  /// file. So every interrupted download left a pair behind permanently, and a
  /// partial of a 800MB episode is not a rounding error.
  ///
  /// Everything the scan finds is therefore garbage BY THIS APP'S RULES. The
  /// day resume is actually wired up (the FFI already exposes it) this has to
  /// learn to spare the jobs it would resume — deleting them would be the
  /// whole feature's state.
  ///
  /// [minimumAge] is what keeps this safe to run: a download in flight rewrites
  /// its temp continuously, so anything touched recently belongs to somebody.
  /// That somebody can be ANOTHER COPY OF THIS APP — an installed build and a
  /// debug build do run side by side, pointed at the same downloads folder, and
  /// a sweep with no age gate would delete the other one's partial mid-write.
  /// Whether a leftover is old enough that nobody can still be writing it.
  ///
  /// The one guard that protects a download IN FLIGHT — including one owned by
  /// a different copy of this app sharing the folder. Pure so the boundary is
  /// checkable without a filesystem or a native library.
  static bool sweepable({
    required DateTime lastModified,
    required DateTime now,
    required Duration minimumAge,
  }) => now.difference(lastModified) >= minimumAge;

  Future<int> sweepOrphanedResumeFiles({
    Duration minimumAge = const Duration(minutes: 10),
  }) async {
    if (!vidradlpLibraryAvailable()) return 0;
    final dir = await _resolveDownloadsDir();
    if (dir == null || !await dir.exists()) return 0;

    final List<Map<String, dynamic>> jobs;
    final client = VidraDlpClient();
    try {
      jobs = client.scanResumableJobs(dir.path);
    } catch (e) {
      logD('DownloadService', '扫描残留失败: $e');
      return 0;
    } finally {
      client.free();
    }

    final now = DateTime.now();
    var swept = 0;
    for (final job in jobs) {
      final temp = job['temp_path'] as String?;
      final manifest = job['manifest_path'] as String?;
      if (temp == null) continue;
      try {
        final tempFile = File(temp);
        if (tempFile.existsSync() &&
            !sweepable(
              lastModified: tempFile.lastModifiedSync(),
              now: now,
              minimumAge: minimumAge,
            )) {
          continue;
        }
        if (tempFile.existsSync()) tempFile.deleteSync();
        if (manifest != null) {
          final m = File(manifest);
          if (m.existsSync()) m.deleteSync();
        }
        swept++;
      } catch (e) {
        // One unreadable leftover must not stop the rest being cleared.
        logD('DownloadService', '清理残留失败 $temp: $e');
      }
    }
    if (swept > 0) {
      logR('DownloadService', 'swept $swept orphaned resume file(s)');
    }
    return swept;
  }

  /// Where downloads land: the user's chosen folder, else the default.
  /// Same resolution [downloadM3u8ToMp4] performs per download.
  Future<Directory?> _resolveDownloadsDir() async {
    final repo = _settingsRepo;
    if (repo == null) return getDownloadsDirectory();
    final settings = await repo.getSettings();
    final path = (settings.downloadPath != null &&
            settings.downloadPath!.isNotEmpty)
        ? settings.downloadPath!
        : await repo.getDefaultDownloadPath();
    return Directory(path);
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
