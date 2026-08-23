import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../utils/log.dart';
import 'm3u8_downloader.dart' show DownloadCancelledException;
import 'segment_downloader.dart';
import 'vidradlp/vidradlp_flutter.dart';

/// Downloads HLS via the native vidraDlp SDK and lets it remux TS→MP4 in-Rust,
/// so the produced file is an iPhone-playable `.mp4` (no ffmpeg needed).
///
/// Bridges vidraDlp's event-callback API to the [SegmentDownloader] Future
/// contract, and bridges the app's polled [shouldCancel] to vidraDlp's explicit
/// `downloadCancel(jobId)`.
class VidraDlpDownloader implements SegmentDownloader {
  VidraDlpDownloader({this.concurrency = 6, this.configJson});

  /// Parallel HLS segment fetches, passed to the SDK as `options.concurrency`
  /// (the SDK clamps to 1..=16).
  final int concurrency;

  /// vidraDlp client config JSON (e.g. cookie_file for gated sites). Null =
  /// SDK defaults. Applies to the shared client, so it also covers cookies.
  final String? configJson;

  // One long-lived engine session for the whole app (holds the job table).
  static VidraDlpClient? _client;
  static String? _clientConfig;
  static int _activeJobs = 0;

  /// Returns the process-wide client, rebuilding it when [configJson] changes
  /// (e.g. the user set/cleared the cookie file). Never frees a client with
  /// jobs in flight — that would crash active downloads; the new config takes
  /// effect once the current batch drains.
  static VidraDlpClient _sharedClient(String? configJson) {
    if (_client != null && _clientConfig != configJson && _activeJobs == 0) {
      _client!.free();
      _client = null;
    }
    if (_client == null) {
      _client = VidraDlpClient(configJson: configJson);
      _clientConfig = configJson;
    }
    return _client!;
  }

  @override
  Future<String> downloadM3U8({
    required String m3u8Url,
    required String outputPath,
    String? formatId,
    DownloadProgressCallback? onProgress,
    bool Function()? shouldCancel,
  }) {
    final client = _sharedClient(configJson);
    final completer = Completer<String>();

    // The SDK downloads to `outputPath` (.ts) and, with remux_to=mp4, produces
    // the sibling `.mp4`. That is the file we return.
    final mp4Path = p.setExtension(outputPath, '.mp4');

    int? jobId;
    Timer? cancelPoll;
    var cancelRequested = false;

    void cleanup() {
      cancelPoll?.cancel();
      cancelPoll = null;
    }

    void finish(FutureOr<String> Function() produce) {
      if (completer.isCompleted) return;
      cleanup();
      try {
        Future.value(
          produce(),
        ).then((v) => completer.complete(v), onError: completer.completeError);
      } catch (e, st) {
        completer.completeError(e, st);
      }
    }

    void onEvent(Map<String, dynamic> event) {
      switch (event['event'] as String?) {
        case 'progress':
          if (onProgress != null) {
            final diag = event['diagnostics'];
            final stage =
                (diag is Map ? diag['stage'] : event['stage']) as String?;
            if (stage == 'remuxing' || stage == 'merging') {
              // All bytes are down; the in-SDK remux/merge is running. The
              // event carries no byte counts — the consumer keeps its own.
              onProgress(1.0, 0, null, 'Remuxing');
              break;
            }
            final downloaded =
                (event['downloaded_bytes'] as num?)?.toInt() ?? 0;
            final total = (event['total_bytes'] as num?)?.toInt();
            final prog = (total != null && total > 0)
                ? downloaded / total
                : 0.0;
            onProgress(prog, downloaded, total, 'Downloading');
          }
          break;
        case 'finished':
          finish(() {
            // Prefer the remuxed .mp4; fall back to the raw output if remux
            // didn't apply (e.g. non-TS source).
            if (File(mp4Path).existsSync()) return mp4Path;
            if (File(outputPath).existsSync()) return outputPath;
            throw Exception('vidraDlp finished but no output file found');
          });
          break;
        case 'error':
          final msg = event['message'] as String? ?? 'vidraDlp download error';
          finish(() => throw Exception(msg));
          break;
        case 'cancelled':
          finish(() => throw const DownloadCancelledException());
          break;
      }
    }

    try {
      jobId = client.download(
        url: m3u8Url,
        output: outputPath,
        // Direct .m3u8 links resolve to the manifest extractor's single
        // "direct" format; "best" does not match it. The pasted-URL flow
        // supplies a real selector (exact format_id / best[...]).
        formatId: formatId ?? 'direct',
        options: {'remux_to': 'mp4', 'concurrency': concurrency},
        callback: onEvent,
      );
    } catch (e, st) {
      // download() throws the native error Map on a bad request/extract.
      completer.completeError(
        Exception('vidraDlp download start failed: $e'),
        st,
      );
      return completer.future;
    }

    // Track in-flight jobs so a config change (cookie file) never frees the
    // shared client mid-download. Balanced: one inc on start, one dec on any
    // completion.
    _activeJobs++;
    completer.future.whenComplete(() => _activeJobs--);

    // Bridge polled cancellation → explicit downloadCancel(jobId).
    if (shouldCancel != null) {
      cancelPoll = Timer.periodic(const Duration(milliseconds: 200), (_) {
        if (completer.isCompleted) {
          cleanup();
          return;
        }
        if (!cancelRequested && shouldCancel()) {
          cancelRequested = true;
          try {
            client.downloadCancel(jobId!);
          } catch (e) {
            logD('VidraDlpDownloader', 'downloadCancel failed: $e');
          }
        }
      });
    }

    return completer.future;
  }
}
