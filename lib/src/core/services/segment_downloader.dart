import '../utils/log.dart';
import 'vidradlp/vidradlp_ffi.dart' show vidradlpLibraryAvailable;
import 'vidradlp_downloader.dart';
import 'm3u8_downloader.dart';

/// Progress callback shared by all segment downloaders.
typedef DownloadProgressCallback =
    void Function(
      double progress,
      int bytesDownloaded,
      int? totalBytes,
      String status,
    );

/// A downloader that turns an HLS/m3u8 URL into a single local file.
///
/// Two implementations: [VidraDlpDownloader] (native Rust vidraDlp — downloads
/// + remuxes to a playable `.mp4`) and [M3U8Downloader] (pure Dart — concatenates
/// TS segments into a `.ts`, used as a fallback where the native lib isn't
/// available, e.g. Windows without a prebuilt dylib).
abstract class SegmentDownloader {
  /// Downloads [m3u8Url]. [outputPath] is the requested target (`*.ts`); the
  /// returned string is the ACTUAL file produced, which may differ (vidraDlp
  /// produces `*.mp4`). Throws [DownloadCancelledException] on cancel.
  ///
  /// [formatId] is the vidraDlp format selector (exact `format_id`, or `best`
  /// / `best[height<=720]`, etc.). Null means the legacy `direct` selector used
  /// for direct HLS manifests; the pure-Dart fallback ignores it.
  Future<String> downloadM3U8({
    required String m3u8Url,
    required String outputPath,
    String? formatId,
    DownloadProgressCallback? onProgress,
    bool Function()? shouldCancel,
  });
}

/// Picks vidraDlp when its native library loads, else the pure-Dart fallback.
/// [segmentConcurrency] is the parallel HLS-segment fetch count, honoured by
/// both paths (vidraDlp reads it as its download `concurrency` option; the
/// pure-Dart fallback as its sliding-window size). [configJson] is the vidraDlp
/// client config (e.g. cookie_file); the pure-Dart fallback ignores it.
SegmentDownloader createSegmentDownloader({
  int segmentConcurrency = 8,
  String? configJson,
}) {
  if (vidradlpLibraryAvailable()) {
    logR(
      'SegmentDownloader',
      'using vidraDlp (native, TS→MP4 remux, concurrency=$segmentConcurrency)',
    );
    return VidraDlpDownloader(
      concurrency: segmentConcurrency,
      configJson: configJson,
    );
  }
  logR(
    'SegmentDownloader',
    'vidraDlp lib unavailable → pure-Dart .ts fallback',
  );
  return M3U8Downloader(maxConcurrentDownloads: segmentConcurrency);
}
