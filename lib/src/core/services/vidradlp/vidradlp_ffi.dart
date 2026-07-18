// vidraDlp Dart FFI bindings — VENDORED into the Vidra app.
//
// Source of truth: `vidraDlp/packages/vidradlp_flutter/lib/vidradlp_ffi.dart`.
// Vendored (not a path/pub dep) so the app fully controls the native library
// load path: the desktop app bundles `libmedia_ffi.dylib` inside the `.app`,
// which the upstream package's dev-only candidate paths don't resolve. The
// ONLY change from upstream is [_loadLib]'s macOS/Linux branch (bundle-first).

import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'package:path/path.dart' as p;

// ---- C type aliases -------------------------------------------------------

typedef MediaClient = Pointer<Void>;
typedef MediaJobId = Uint64;

typedef MediaClientNewC = Pointer<Void> Function(Pointer<Utf8> config);
typedef MediaClientNewDart = Pointer<Void> Function(Pointer<Utf8> config);

typedef MediaClientFreeC = Void Function(Pointer<Void> client);
typedef MediaClientFreeDart = void Function(Pointer<Void> client);

typedef MediaExtractC = Pointer<Utf8> Function(
    Pointer<Void> client, Pointer<Utf8> url, Pointer<Utf8> opts);
typedef MediaExtractDart = Pointer<Utf8> Function(
    Pointer<Void> client, Pointer<Utf8> url, Pointer<Utf8> opts);

typedef MediaCapabilityManifestJsonC = Pointer<Utf8> Function(
    Pointer<Void> client);
typedef MediaCapabilityManifestJsonDart = Pointer<Utf8> Function(
    Pointer<Void> client);

typedef MediaDownloadStartC = Int32 Function(
    Pointer<Void> client,
    Pointer<Utf8> requestJson,
    Pointer<NativeFunction<MediaProgressFnC>> callback,
    Pointer<Void> userData,
    Pointer<Uint64> outJobId);
typedef MediaDownloadStartDart = int Function(
    Pointer<Void> client,
    Pointer<Utf8> requestJson,
    Pointer<NativeFunction<MediaProgressFnC>> callback,
    Pointer<Void> userData,
    Pointer<Uint64> outJobId);

typedef MediaDownloadCancelC = Int32 Function(
    Pointer<Void> client, Uint64 jobId);
typedef MediaDownloadCancelDart = int Function(Pointer<Void> client, int jobId);

// ---- resumable downloads (W3 / W4) ----------------------------------------

typedef MediaScanResumableJobsC = Pointer<Utf8> Function(Pointer<Utf8> dirPath);
typedef MediaScanResumableJobsDart = Pointer<Utf8> Function(
    Pointer<Utf8> dirPath);

typedef MediaDownloadResumeC = Int32 Function(
    Pointer<Void> client,
    Pointer<Utf8> manifestPath,
    Pointer<NativeFunction<MediaProgressFnC>> callback,
    Pointer<Void> userData,
    Pointer<Uint64> outJobId);
typedef MediaDownloadResumeDart = int Function(
    Pointer<Void> client,
    Pointer<Utf8> manifestPath,
    Pointer<NativeFunction<MediaProgressFnC>> callback,
    Pointer<Void> userData,
    Pointer<Uint64> outJobId);

typedef MediaProgressFnC = Void Function(
    Pointer<Utf8> jsonEvent, Pointer<Void> userData);

typedef MediaLogFnC = Void Function(
    Pointer<Utf8> message, Pointer<Void> userData);

typedef MediaSetLogCallbackC = Int32 Function(
    Pointer<NativeFunction<MediaLogFnC>> callback, Pointer<Void> userData);
typedef MediaSetLogCallbackDart = int Function(
    Pointer<NativeFunction<MediaLogFnC>> callback, Pointer<Void> userData);

typedef MediaStringFreeC = Void Function(Pointer<Utf8> s);
typedef MediaStringFreeDart = void Function(Pointer<Utf8> s);

typedef MediaLastErrorC = Pointer<Utf8> Function(Pointer<Void> client);
typedef MediaLastErrorDart = Pointer<Utf8> Function(Pointer<Void> client);

// ---- Library loading ------------------------------------------------------

/// Whether the native vidraDlp library can be loaded on this platform/build.
/// The downloader factory uses this to decide vidraDlp-primary vs Dart-fallback.
bool vidradlpLibraryAvailable() {
  try {
    _lib;
    return true;
  } catch (e) {
    // ignore: avoid_print
    print('[vidradlp] native library load failed: $e');
    return false;
  }
}

// Desktop/Android shared-library file name for the current platform.
// Windows Rust cdylib -> `media_ffi.dll`; Apple -> `libmedia_ffi.dylib`;
// Linux/Android -> `libmedia_ffi.so`.
String _libFileName() {
  if (Platform.isMacOS) return 'libmedia_ffi.dylib';
  if (Platform.isWindows) return 'media_ffi.dll';
  return 'libmedia_ffi.so';
}

String? _bundledLibPath() {
  try {
    final exe = Platform.resolvedExecutable;
    final name = _libFileName();
    // macOS: <App>.app/Contents/MacOS/<exe> -> Contents/Frameworks/<name>
    // (copied there by the Runner build phase).
    if (Platform.isMacOS) {
      final contents = p.dirname(p.dirname(exe)); // .../Contents
      final f = p.join(contents, 'Frameworks', name);
      if (File(f).existsSync()) return f;
    }
    // Windows/Linux (and a macOS loose fallback): right next to the exe.
    // On Windows CMake installs media_ffi.dll into the bundle root.
    final beside = p.join(p.dirname(exe), name);
    if (File(beside).existsSync()) return beside;
  } catch (_) {}
  return null;
}

DynamicLibrary _loadLib() {
  final envPath = Platform.environment['VIDRADLP_FFI_LIB'];
  if (envPath != null && envPath.isNotEmpty) {
    return DynamicLibrary.open(envPath);
  }
  if (Platform.isIOS) {
    return DynamicLibrary.open('MediaFFI.framework/MediaFFI');
  }

  // Prefer the copy bundled beside the app; fall back to the bare name
  // (system/loader search path — Android's libmedia_ffi.so, dev checkouts).
  final bundled = _bundledLibPath();
  if (bundled != null) return DynamicLibrary.open(bundled);
  return DynamicLibrary.open(_libFileName());
}

final _lib = _loadLib();

// ---- Public API -----------------------------------------------------------

final mediaClientNew =
    _lib.lookupFunction<MediaClientNewC, MediaClientNewDart>('media_client_new');
final mediaClientFree = _lib
    .lookupFunction<MediaClientFreeC, MediaClientFreeDart>('media_client_free');
final mediaExtract =
    _lib.lookupFunction<MediaExtractC, MediaExtractDart>('media_extract');
final mediaCapabilityManifestJson = _lib.lookupFunction<
    MediaCapabilityManifestJsonC,
    MediaCapabilityManifestJsonDart>('media_capability_manifest_json');
final mediaDownloadStart =
    _lib.lookupFunction<MediaDownloadStartC, MediaDownloadStartDart>(
        'media_download_start');
final mediaDownloadCancel =
    _lib.lookupFunction<MediaDownloadCancelC, MediaDownloadCancelDart>(
        'media_download_cancel');
final mediaStringFree = _lib
    .lookupFunction<MediaStringFreeC, MediaStringFreeDart>('media_string_free');
final mediaLastError = _lib
    .lookupFunction<MediaLastErrorC, MediaLastErrorDart>('media_last_error_json');
final mediaSetLogCallback =
    _lib.lookupFunction<MediaSetLogCallbackC, MediaSetLogCallbackDart>(
        'media_set_log_callback');
final mediaScanResumableJobs =
    _lib.lookupFunction<MediaScanResumableJobsC, MediaScanResumableJobsDart>(
        'media_scan_resumable_jobs');
final mediaDownloadResume =
    _lib.lookupFunction<MediaDownloadResumeC, MediaDownloadResumeDart>(
        'media_download_resume');
