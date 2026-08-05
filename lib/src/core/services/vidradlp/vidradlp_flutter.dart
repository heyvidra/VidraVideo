// vidraDlp Flutter plugin wrapper.
//
// Wraps the vidraDlp C ABI library for Flutter mobile apps with
// isolate-safe progress callbacks and convenient metadata query methods.

import 'dart:convert';
import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'vidradlp_ffi.dart';

export 'vidradlp_ffi.dart';

/// Callback type for media download progress events.
typedef MediaDownloadCallback = void Function(Map<String, dynamic> event);

/// Structured request for starting a download through the high-level client.
///
/// This mirrors the stable C ABI JSON request schema while keeping Flutter
/// callers from hand-authoring raw JSON for common download starts.
class VidraDlpDownloadRequest {
  /// Create a v1 download request.
  const VidraDlpDownloadRequest({
    required this.url,
    required this.output,
    this.formatId = 'best',
    this.options = const <String, dynamic>{},
  });

  /// Source URL to extract and download.
  final String url;

  /// Destination path requested by the host app.
  final String output;

  /// Format selector accepted by the native engine.
  final String formatId;

  /// Optional engine-specific request options.
  final Map<String, dynamic> options;

  /// Convert to the stable FFI JSON request shape.
  Map<String, dynamic> toJson() => <String, dynamic>{
    'schema_version': 1,
    'url': url,
    'format_id': formatId,
    'output': output,
    'options': options,
  };

  /// Encode this request for [VidraDlpClient.downloadStart].
  String toJsonString() => jsonEncode(toJson());
}

/// High-level client wrapping the native vidraDlp library.
///
/// Handles initialization, synchronous media metadata extraction,
/// isolate-safe asynchronous downloads with callback cleanup, and runtime
/// feature split capability checks.
class VidraDlpClient {
  final Pointer<Void> _client;
  bool _isFreed = false;
  final List<NativeCallable> _callables = [];

  /// Creates a new native vidraDlp client with an optional config JSON string.
  VidraDlpClient({String? configJson}) : _client = _createNewClient(configJson);

  static Pointer<Void> _createNewClient(String? configJson) {
    if (configJson == null) {
      return mediaClientNew(nullptr);
    }
    final configPtr = configJson.toNativeUtf8();
    try {
      return mediaClientNew(configPtr);
    } finally {
      calloc.free(configPtr);
    }
  }

  /// Get the full runtime capability manifest from the native SDK.
  Map<String, dynamic> getCapabilities() {
    _checkFreed();
    final manifestPtr = mediaCapabilityManifestJson(_client);
    if (manifestPtr == nullptr) {
      return {};
    }
    try {
      final jsonStr = manifestPtr.toDartString();
      return jsonDecode(jsonStr) as Map<String, dynamic>;
    } finally {
      mediaStringFree(manifestPtr);
    }
  }

  /// Check if a specific feature (e.g., `"youtube"`, `"bilibili"`, `"reddit"`) is enabled.
  bool isFeatureEnabled(String name) {
    final capabilities = getCapabilities();
    final sites = capabilities['sites'] as List<dynamic>?;
    if (sites == null) return false;
    for (final site in sites) {
      if (site is Map && site['name'] == name) {
        return site['enabled'] == true;
      }
    }
    return false;
  }

  /// Returns the list of enabled site extractors under the current build configuration.
  ///
  /// Can be used to dynamically check which site extractors are compiled into the binary
  /// (e.g. `['bilibili', 'generic']` in Lite vs `['bilibili', 'youtube', ...]` in Full).
  List<String> getSupportedSites() {
    final capabilities = getCapabilities();
    final sites = capabilities['sites'] as List<dynamic>?;
    if (sites == null) return const [];
    return sites
        .whereType<Map>()
        .where((site) => site['enabled'] == true)
        .map((site) => site['name'] as String)
        .toList();
  }

  /// Returns the list of enabled download protocols (e.g., `['https', 'm3u8', 'mpd']`).
  List<String> getSupportedProtocols() {
    final capabilities = getCapabilities();
    final protocols = capabilities['protocols'] as List<dynamic>?;
    if (protocols == null) return const [];
    return protocols.map((p) => p.toString()).toList();
  }

  /// Extract media metadata from a webpage URL.
  ///
  /// Returns a structured Map representing the `MediaEntry` schema.
  /// Throws the native error JSON Map on failure.
  Map<String, dynamic> extract(String url, {String? optsJson}) {
    _checkFreed();
    final urlPtr = url.toNativeUtf8();
    final optsPtr = optsJson != null ? optsJson.toNativeUtf8() : nullptr;
    try {
      final resultPtr = mediaExtract(_client, urlPtr, optsPtr);
      if (resultPtr == nullptr) {
        throw _getLastError();
      }
      try {
        final jsonStr = resultPtr.toDartString();
        return jsonDecode(jsonStr) as Map<String, dynamic>;
      } finally {
        mediaStringFree(resultPtr);
      }
    } finally {
      calloc.free(urlPtr);
      if (optsPtr != nullptr) {
        calloc.free(optsPtr);
      }
    }
  }

  /// Start an asynchronous media download.
  /// Returns a unique job ID.
  ///
  /// Uses [NativeCallable.listener] to dispatch progress callbacks safely across native FFI
  /// threads and Dart isolates, avoiding typical multi-threading crashes in Flutter.
  ///
  /// Resource management: automatically closes and releases the native callback resources
  /// once a terminal event (`finished`, `error`, `cancelled`) is encountered.
  int downloadStart(String requestJson, MediaDownloadCallback callback) {
    _checkFreed();
    final requestPtr = requestJson.toNativeUtf8();

    late final NativeCallable<MediaProgressFnC> nativeCallable;

    void onEvent(Pointer<Utf8> jsonEvent, Pointer<Void> userData) {
      if (jsonEvent == nullptr) return;
      // Buffer ownership: as of the new FFI contract the native side
      // `CString::into_raw()`s this buffer and hands it to us. We MUST
      // call `mediaStringFree` exactly once — even on early returns and
      // on exceptions — or we leak. The `try / finally` below guarantees
      // that, regardless of what `callback(event)` throws.
      try {
        final jsonStr = jsonEvent.toDartString();
        if (jsonStr.isEmpty) {
          // Should be impossible under the new contract; keep a diagnostic
          // for if it ever happens.
          return;
        }
        final event = jsonDecode(jsonStr) as Map<String, dynamic>;

        callback(event);

        // Auto-close and release native callable when the job completes
        final eventType = event['event'] as String?;
        if (eventType == 'finished' ||
            eventType == 'error' ||
            eventType == 'cancelled') {
          nativeCallable.close();
          _callables.remove(nativeCallable);
        }
      } catch (_) {
        // Safe fallback for parsing or callback errors
      } finally {
        // Always release the heap buffer the SDK handed us.
        mediaStringFree(jsonEvent);
      }
    }

    nativeCallable = NativeCallable<MediaProgressFnC>.listener(onEvent);
    _callables.add(nativeCallable);

    final outJobIdPtr = calloc<Uint64>();

    try {
      final rc = mediaDownloadStart(
        _client,
        requestPtr,
        nativeCallable.nativeFunction,
        nullptr,
        outJobIdPtr,
      );
      if (rc != 0) {
        nativeCallable.close();
        _callables.remove(nativeCallable);
        throw _getLastError();
      }
      return outJobIdPtr.value;
    } finally {
      calloc.free(requestPtr);
      calloc.free(outJobIdPtr);
    }
  }

  /// Start an asynchronous media download from structured Dart fields.
  ///
  /// This is the recommended Flutter entry point for new integrations. Use
  /// [downloadStart] only when you already have a raw FFI request JSON string.
  int download({
    required String url,
    required String output,
    String formatId = 'best',
    Map<String, dynamic> options = const <String, dynamic>{},
    required MediaDownloadCallback callback,
  }) {
    final request = VidraDlpDownloadRequest(
      url: url,
      output: output,
      formatId: formatId,
      options: options,
    );
    return downloadStart(request.toJsonString(), callback);
  }

  /// Cancel an active download job.
  /// Throws the native error JSON Map on failure.
  void downloadCancel(int jobId) {
    _checkFreed();
    final rc = mediaDownloadCancel(_client, jobId);
    if (rc != 0) {
      throw _getLastError();
    }
  }

  // ---- Resumable downloads (W3 / W4) --------------------------------------

  /// Scan [directory] for downloads that were interrupted (worker crashed,
  /// app killed mid-download, etc.) and can be resumed.
  ///
  /// Returns the `jobs` array from the FFI's JSON report, with each entry as
  /// a `Map<String, dynamic>` carrying the fields documented in
  /// `docs/RESUME.md` — most usefully:
  ///   * `manifest_path`  — pass verbatim to [downloadResume]
  ///   * `output_path`    — where the file WILL land on resume success
  ///   * `temp_path`      — the partial file on disk
  ///   * `url`, `format_id`
  ///   * `bytes_on_disk`  — authoritative resume offset
  ///   * `bytes_downloaded` — manifest's last checkpoint hint (UI only)
  ///   * `total_bytes`    — if discovered by the prior run
  ///
  /// On native I/O error returns an empty list (the FFI returns NULL; we
  /// translate that to "no resumable jobs" since the host can't act on it
  /// any differently anyway). If you need to distinguish "scan failed" from
  /// "no jobs", check [directory] yourself first.
  List<Map<String, dynamic>> scanResumableJobs(String directory) {
    _checkFreed();
    final dirPtr = directory.toNativeUtf8();
    try {
      final raw = mediaScanResumableJobs(dirPtr);
      if (raw == nullptr) {
        // NULL = scan failed (likely permission / nonexistent dir). Treat
        // as "no resumable jobs" — the host has nothing actionable here.
        return const <Map<String, dynamic>>[];
      }
      final jsonStr = raw.toDartString();
      mediaStringFree(raw);
      final parsed = jsonDecode(jsonStr) as Map<String, dynamic>;
      final jobs = (parsed['jobs'] as List<dynamic>?) ?? const [];
      return jobs
          .whereType<Map>()
          .map((m) => m.map((k, v) => MapEntry(k.toString(), v)))
          .toList(growable: false);
    } finally {
      calloc.free(dirPtr);
    }
  }

  /// Resume a previously-interrupted download from its manifest on disk.
  ///
  /// [manifestPath] should come from a [scanResumableJobs] result. A fresh
  /// `MediaJobId` is assigned — the trace_id from the original run is
  /// preserved in every event's `diagnostics.trace_id` for log correlation,
  /// but the new job_id is distinct.
  ///
  /// Mirrors [downloadStart]'s contract for [callback]:
  /// `NativeCallable.listener` is wired up to receive native events; the
  /// callable is auto-closed on the first terminal event
  /// (`finished` / `error` / `cancelled`).
  ///
  /// Throws the native error JSON Map on failure (corrupt manifest, etc.).
  int downloadResume(String manifestPath, MediaDownloadCallback callback) {
    _checkFreed();
    final manifestPtr = manifestPath.toNativeUtf8();

    late final NativeCallable<MediaProgressFnC> nativeCallable;

    void onEvent(Pointer<Utf8> jsonEvent, Pointer<Void> userData) {
      if (jsonEvent == nullptr) return;
      try {
        final jsonStr = jsonEvent.toDartString();
        if (jsonStr.isEmpty) return;
        final event = jsonDecode(jsonStr) as Map<String, dynamic>;
        callback(event);
        final eventType = event['event'] as String?;
        if (eventType == 'finished' ||
            eventType == 'error' ||
            eventType == 'cancelled') {
          nativeCallable.close();
          _callables.remove(nativeCallable);
        }
      } catch (_) {
        // Same defensive swallow as downloadStart — never propagate host
        // callback exceptions into the worker.
      } finally {
        mediaStringFree(jsonEvent);
      }
    }

    nativeCallable = NativeCallable<MediaProgressFnC>.listener(onEvent);
    _callables.add(nativeCallable);

    final outJobIdPtr = calloc<Uint64>();
    try {
      final rc = mediaDownloadResume(
        _client,
        manifestPtr,
        nativeCallable.nativeFunction,
        nullptr,
        outJobIdPtr,
      );
      if (rc != 0) {
        nativeCallable.close();
        _callables.remove(nativeCallable);
        throw _getLastError();
      }
      return outJobIdPtr.value;
    } finally {
      calloc.free(manifestPtr);
      calloc.free(outJobIdPtr);
    }
  }

  // Holds the NativeCallable for the global log sink as long as it's
  // registered, so the GC doesn't free it from underneath the native side.
  static NativeCallable<MediaLogFnC>? _logCallable;

  /// Install a process-wide debug-log sink. Every `debug_log!` line emitted
  /// from the native SDK (any thread, any download) is delivered to
  /// [handler] on the calling Dart isolate.
  ///
  /// Pass `null` to clear the previously installed sink.
  ///
  /// Notes:
  ///  - Native side also needs `debug: true` in `ClientConfig` (or env
  ///    `VIDRADLP_DEBUG=1`), otherwise nothing is emitted.
  ///  - Only one sink can be active at a time process-wide. Calling this
  ///    again replaces the previous handler and closes its NativeCallable.
  static void setLogCallback(void Function(String message)? handler) {
    // Tear down any previously installed sink first.
    if (_logCallable != null) {
      mediaSetLogCallback(nullptr, nullptr);
      _logCallable!.close();
      _logCallable = null;
    }
    if (handler == null) return;

    void onLog(Pointer<Utf8> msgPtr, Pointer<Void> _) {
      if (msgPtr == nullptr) return;
      // Buffer ownership: SDK transferred via `CString::into_raw`. Must be
      // released exactly once via `mediaStringFree`. See the matching
      // OWNERSHIP CONTRACT comment in `crates/media-ffi/src/api.rs`.
      try {
        handler(msgPtr.toDartString());
      } catch (_) {
        // Swallow — never let host-side log handling crash a worker.
      } finally {
        mediaStringFree(msgPtr);
      }
    }

    _logCallable = NativeCallable<MediaLogFnC>.listener(onLog);
    mediaSetLogCallback(_logCallable!.nativeFunction, nullptr);
  }

  /// Get the last error from the native client.
  Map<String, dynamic> _getLastError() {
    final errPtr = mediaLastError(_client);
    if (errPtr == nullptr) {
      return {
        'schema_version': 1,
        'error': {'code': 'unknown', 'message': 'Unknown native error'},
      };
    }
    try {
      final jsonStr = errPtr.toDartString();
      return jsonDecode(jsonStr) as Map<String, dynamic>;
    } finally {
      mediaStringFree(errPtr);
    }
  }

  void _checkFreed() {
    if (_isFreed) {
      throw StateError('VidraDlpClient has already been freed.');
    }
  }

  /// Free the native client resources.
  ///
  /// After calling [free], any further calls to client methods will throw a [StateError].
  void free() {
    if (!_isFreed) {
      for (final callable in _callables) {
        callable.close();
      }
      _callables.clear();
      mediaClientFree(_client);
      _isFreed = true;
    }
  }
}
