import 'package:easy_localization/easy_localization.dart';
import 'dart:convert';
import 'dart:isolate';

import 'package:crypto/crypto.dart';

import '../../features/download/domain/media_info.dart';
import 'vidradlp/vidradlp_flutter.dart';

/// Resolves video metadata for a pasted URL via vidraDlp's `extract()`.
///
/// `extract` is a synchronous, blocking FFI call that does network I/O inside
/// Rust (seconds for some sites), so it runs in a background isolate to keep the
/// window responsive.
class MediaInfoService {
  const MediaInfoService();

  /// What was pasted, as a web address the extractor may be given — or null.
  ///
  /// The old check asked only for an absolute path, so `/Users/me/file` and
  /// `file:///etc/hosts` went to the native extractor while
  /// `www.youtube.com/watch?v=1`, as copied from an address bar, was refused.
  static String? normalizeUrl(String pasted) {
    final first = pasted.trim().split(RegExp(r'\s+')).first;
    if (first.isEmpty || first.length > 4096) return null;
    final candidate = first.contains('://') ? first : 'https://$first';
    final uri = Uri.tryParse(candidate);
    if (uri == null || !uri.host.contains('.')) return null;
    return uri.scheme == 'http' || uri.scheme == 'https' ? candidate : null;
  }

  /// [configJson] is the vidraDlp client config (e.g. cookie_file); pass it so
  /// gated sites can be parsed with the user's cookies.
  Future<MediaInfo> extract(String url, {String? configJson}) async {
    final trimmed = normalizeUrl(url);
    if (trimmed == null) {
      throw MediaInfoException(tr('download.url.invalid'));
    }
    if (!vidradlpLibraryAvailable()) {
      throw MediaInfoException(tr('download.url.engine_missing'));
    }

    final Map<String, dynamic> raw;
    try {
      raw = await Isolate.run(() => _extractInIsolate(trimmed, configJson));
    } catch (e) {
      throw MediaInfoException(_friendly(e));
    }
    return MediaInfo.fromJson(raw, trimmed);
  }

  /// Runs in a fresh isolate: a throwaway client extracts then frees. Returns
  /// the raw MediaEntry JSON (sendable across the isolate boundary).
  static Map<String, dynamic> _extractInIsolate(
    String url,
    String? configJson,
  ) {
    final client = VidraDlpClient(configJson: configJson);
    try {
      return client.extract(url);
    } finally {
      client.free();
    }
  }

  static String _friendly(Object e) {
    // The FFI layer throws the native error JSON Map; surface its message.
    if (e is Map && e['message'] is String) return e['message'] as String;
    final s = e.toString();
    return s.length > 200 ? '${s.substring(0, 200)}…' : s;
  }
}

/// Thrown when parsing a URL fails; carries a user-facing [message].
class MediaInfoException implements Exception {
  const MediaInfoException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Stable, deterministic pseudo-videoId for a pasted URL. Negative to namespace
/// away from the catalog's positive ids; same URL → same id (re-paste dedups),
/// distinct URLs → distinct ids. Uses the first 6 md5 bytes (fits a Dart int).
int videoIdFromUrl(String url) {
  final digest = md5.convert(utf8.encode(url)).bytes;
  int v = 0;
  for (var i = 0; i < 6; i++) {
    v = (v << 8) | digest[i];
  }
  return -v - 1;
}
