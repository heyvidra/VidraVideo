import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:vidra/src/core/network/browser_headers.dart';
import 'package:vidra/src/core/utils/log.dart';
import 'segment_downloader.dart';

class DownloadCancelledException implements Exception {
  const DownloadCancelledException([this.message = 'Download cancelled']);

  final String message;

  @override
  String toString() => message;
}

/// M3U8 playlist parser
class M3U8Parser {
  /// Parse m3u8 content and extract TS segment URLs or sub-playlist URLs
  static Future<List<String>> parsePlaylist(
    String content,
    String baseUrl,
    Dio dio,
    CancelToken? cancelToken,
    bool Function()? shouldCancel,
  ) async {
    if (shouldCancel?.call() ?? false) {
      cancelToken?.cancel('Download cancelled');
      throw const DownloadCancelledException();
    }

    final lines = content.split('\n');
    final segments = <String>[];
    bool isMediaPlaylist = false;

    // Check if this is a media playlist (contains #EXTINF) or master playlist (contains #EXT-X-STREAM-INF)
    for (final line in lines) {
      if (line.trim().startsWith('#EXTINF')) {
        isMediaPlaylist = true;
        break;
      }
    }

    // If it's a master playlist, we need to fetch the first sub-playlist
    if (!isMediaPlaylist && content.contains('#EXT-X-STREAM-INF')) {
      logD('M3U8', 'Detected master playlist, fetching sub-playlist...');

      // Find the first sub-playlist URL (usually the best quality)
      for (final line in lines) {
        if (shouldCancel?.call() ?? false) {
          cancelToken?.cancel('Download cancelled');
          throw const DownloadCancelledException();
        }

        final trimmed = line.trim();
        if (trimmed.isEmpty || trimmed.startsWith('#')) {
          continue;
        }

        // This is a sub-playlist URL
        final subPlaylistUrl = _resolveUrl(trimmed, baseUrl);
        logD('M3U8', 'Fetching sub-playlist: $subPlaylistUrl');

        // Fetch and parse the sub-playlist
        final response = await dio.get(
          subPlaylistUrl,
          cancelToken: cancelToken,
        );
        final subBaseUrl = subPlaylistUrl.substring(
          0,
          subPlaylistUrl.lastIndexOf('/') + 1,
        );
        return await parsePlaylist(
          response.data.toString(),
          subBaseUrl,
          dio,
          cancelToken,
          shouldCancel,
        );
      }
    }

    // Parse media playlist to extract TS segments
    for (final line in lines) {
      if (shouldCancel?.call() ?? false) {
        cancelToken?.cancel('Download cancelled');
        throw const DownloadCancelledException();
      }

      final trimmed = line.trim();
      if (trimmed.isEmpty || trimmed.startsWith('#')) {
        continue;
      }

      // This should be a TS segment URL
      final segmentUrl = _resolveUrl(trimmed, baseUrl);
      segments.add(segmentUrl);
    }

    return segments;
  }

  /// Resolve relative URL to absolute URL
  static String _resolveUrl(String url, String baseUrl) {
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    } else {
      final uri = Uri.parse(baseUrl);
      final segmentUri = uri.resolve(url);
      return segmentUri.toString();
    }
  }
}

/// M3U8 Downloader with concurrent TS segment downloads (pure-Dart fallback
/// used where the native vidraDlp library isn't available).
class M3U8Downloader implements SegmentDownloader {
  final int maxConcurrentDownloads;

  M3U8Downloader({this.maxConcurrentDownloads = 5});

  void _throwIfCancelled(bool Function()? shouldCancel, {CancelToken? token}) {
    if (shouldCancel?.call() ?? false) {
      token?.cancel('Download cancelled');
      throw const DownloadCancelledException();
    }
  }

  /// Runs [body] with a CancelToken that a periodic watcher cancels as soon
  /// as [shouldCancel] flips. Replaces the old 150ms `future.timeout` polling
  /// loops — dio aborts the in-flight request itself on token cancel.
  Future<T> _withCancelWatcher<T>(
    Future<T> Function(CancelToken token) body,
    bool Function()? shouldCancel,
  ) async {
    final token = CancelToken();
    Timer? watcher;
    if (shouldCancel != null) {
      watcher = Timer.periodic(const Duration(milliseconds: 200), (_) {
        if (shouldCancel() && !token.isCancelled) {
          token.cancel('Download cancelled');
        }
      });
    }
    try {
      return await body(token);
    } on DioException catch (e) {
      if (CancelToken.isCancel(e) || token.isCancelled) {
        throw const DownloadCancelledException();
      }
      rethrow;
    } finally {
      watcher?.cancel();
    }
  }

  /// Download m3u8 video into a concatenated `.ts` file (no remux).
  @override
  Future<String> downloadM3U8({
    required String m3u8Url,
    required String outputPath,
    String? formatId, // ponytail: pure-Dart HLS fallback ignores the selector
    DownloadProgressCallback? onProgress,
    bool Function()? shouldCancel,
  }) async {
    try {
      onProgress?.call(0.0, 0, null, 'Fetching playlist...');
      _throwIfCancelled(shouldCancel);

      // 1. Download m3u8 playlist (one Dio shared by playlist + all segments)
      //
      // Its own client, not the app's shared one, so it carries the identity
      // explicitly. This is the highest-volume request site in the app on the
      // fallback path — one playlist plus every TS segment — and a CDN that
      // starts refusing non-browsers would break it before anything else.
      final dio = Dio()..interceptors.add(const BrowserHeaders());
      final response = await _withCancelWatcher(
        (token) => dio.get(m3u8Url, cancelToken: token),
        shouldCancel,
      );
      final playlistContent = response.data.toString();

      // 2. Parse playlist to get TS segments (handles master and media playlists)
      final baseUrl = m3u8Url.substring(0, m3u8Url.lastIndexOf('/') + 1);
      final segments = await _withCancelWatcher(
        (token) => M3U8Parser.parsePlaylist(
          playlistContent,
          baseUrl,
          dio,
          token,
          shouldCancel,
        ),
        shouldCancel,
      );

      if (segments.isEmpty) {
        throw Exception('No segments found in playlist');
      }

      logD('M3U8', 'Found ${segments.length} segments');

      onProgress?.call(0.05, 0, null, 'Found ${segments.length} segments');

      // 3. Create temp directory for TS files
      final outputFile = File(outputPath);
      final tempDir = Directory(
        '${outputFile.parent.path}/.temp_${DateTime.now().millisecondsSinceEpoch}',
      );
      await tempDir.create(recursive: true);

      try {
        // 4. Download all TS segments with concurrency control
        final segmentFiles = await _downloadSegmentsConcurrently(
          segments: segments,
          tempDir: tempDir,
          dio: dio,
          shouldCancel: shouldCancel,
          onProgress: (downloaded, total, bytesDownloaded) {
            final progress = 0.05 + (downloaded / total) * 0.90;

            // Estimate total bytes based on average segment size
            int? estimatedTotalBytes;
            if (downloaded > 0) {
              final avgSegmentSize = bytesDownloaded / downloaded;
              estimatedTotalBytes = (avgSegmentSize * total).round();
            }

            onProgress?.call(
              progress,
              bytesDownloaded,
              estimatedTotalBytes,
              'Downloading: $downloaded/$total',
            );
          },
        );

        onProgress?.call(0.95, 0, null, 'Merging segments...');
        _throwIfCancelled(shouldCancel);

        // 5. Concatenate TS files into single file
        await _concatenateSegments(
          segmentFiles,
          outputPath,
          shouldCancel: shouldCancel,
        );

        final fileSize = await File(outputPath).length();
        logD(
          'M3U8',
          'Final file size: ${(fileSize / 1024 / 1024).toStringAsFixed(2)} MB',
        );

        onProgress?.call(1.0, fileSize, null, 'Complete!');

        return outputPath;
      } finally {
        // 6. Cleanup temp directory
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      }
    } catch (e, stackTrace) {
      logD('M3U8', 'Error downloading m3u8: $e\n$stackTrace');
      rethrow;
    }
  }

  /// Download segments with a sliding-window worker pool: N workers pull the
  /// next segment index as soon as they finish, so one slow segment no longer
  /// stalls a whole batch. All workers share one CancelToken; a periodic
  /// watcher cancels it when [shouldCancel] flips, and any worker error
  /// cancels it so the others stop instead of downloading doomed segments.
  Future<List<File>> _downloadSegmentsConcurrently({
    required List<String> segments,
    required Directory tempDir,
    required Dio dio,
    required Function(int downloaded, int total, int bytesDownloaded)
    onProgress,
    bool Function()? shouldCancel,
  }) {
    return _withCancelWatcher((cancelToken) async {
      final files = List<File?>.filled(segments.length, null);
      int nextIndex = 0;
      int downloadedCount = 0;
      int totalBytesDownloaded = 0;

      Future<void> worker() async {
        while (true) {
          if (cancelToken.isCancelled) {
            throw const DownloadCancelledException();
          }
          final i = nextIndex++;
          if (i >= segments.length) return;

          final segmentPath =
              '${tempDir.path}/segment_${i.toString().padLeft(6, '0')}.ts';
          final file = await _downloadSegment(
            segments[i],
            segmentPath,
            i,
            dio: dio,
            cancelToken: cancelToken,
          );
          totalBytesDownloaded += await file.length();
          files[i] = file;
          downloadedCount++;
          onProgress(downloadedCount, segments.length, totalBytesDownloaded);
        }
      }

      final workerCount = maxConcurrentDownloads.clamp(1, segments.length);
      try {
        await Future.wait(
          List.generate(workerCount, (_) => worker()),
          eagerError: true,
        );
      } catch (e) {
        // Stop the remaining workers; Future.wait already swallows their
        // subsequent errors when eagerError is true.
        if (!cancelToken.isCancelled) {
          cancelToken.cancel('Sibling segment failed');
          // Distinguish a real failure from a user cancel: only map to
          // DownloadCancelledException when the user actually cancelled.
          rethrow;
        }
        if (e is DioException && CancelToken.isCancel(e)) {
          throw const DownloadCancelledException();
        }
        rethrow;
      }

      return files.cast<File>();
    }, shouldCancel);
  }

  /// Download a single TS segment
  Future<File> _downloadSegment(
    String url,
    String outputPath,
    int index, {
    required Dio dio,
    CancelToken? cancelToken,
  }) async {
    try {
      await dio.download(
        url,
        outputPath,
        cancelToken: cancelToken,
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: true,
          validateStatus: (status) => status! < 500,
        ),
      );

      final file = File(outputPath);
      final size = await file.length();

      if (index % 10 == 0) {
        logD(
          'M3U8',
          'Downloaded segment $index: ${(size / 1024).toStringAsFixed(2)} KB',
        );
      }

      return file;
    } catch (e) {
      if (e is DioException &&
          (CancelToken.isCancel(e) || cancelToken?.isCancelled == true)) {
        throw const DownloadCancelledException();
      }
      logD('M3U8', 'Error downloading segment $index from $url: $e');
      rethrow;
    }
  }

  /// Concatenate TS segments into a single file
  Future<void> _concatenateSegments(
    List<File> segmentFiles,
    String outputPath, {
    bool Function()? shouldCancel,
  }) async {
    final outputFile = File(outputPath);
    final sink = outputFile.openWrite();

    try {
      int totalBytes = 0;
      for (int i = 0; i < segmentFiles.length; i++) {
        _throwIfCancelled(shouldCancel);
        final segmentFile = segmentFiles[i];
        final bytes = await segmentFile.readAsBytes();
        sink.add(bytes);
        totalBytes += bytes.length;

        if (i % 50 == 0) {
          logD(
            'M3U8',
            'Merged ${i + 1}/${segmentFiles.length} segments, total: ${(totalBytes / 1024 / 1024).toStringAsFixed(2)} MB',
          );
        }
      }

      logD(
        'M3U8',
        'Total merged: ${(totalBytes / 1024 / 1024).toStringAsFixed(2)} MB',
      );
    } finally {
      await sink.close();
    }
  }
}
