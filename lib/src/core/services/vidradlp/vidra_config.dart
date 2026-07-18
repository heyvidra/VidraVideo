import 'dart:convert';

/// Builds the vidraDlp client config JSON (`media_client_new` input) from app
/// settings. Currently only carries [cookieFile] (Netscape cookies.txt), which
/// vidraDlp applies to BOTH extract and download — required for gated sites
/// (e.g. YouTube "login required" videos that 403 without cookies).
///
/// Returns null when there's nothing to configure, so callers pass `null` and
/// the SDK uses all defaults.
String? vidraClientConfigJson({String? cookieFile}) {
  if (cookieFile == null || cookieFile.isEmpty) return null;
  return jsonEncode({'schema_version': 1, 'cookie_file': cookieFile});
}
