import 'package:flutter/services.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/utils/log.dart';
import 'yfsp_signer.dart';

/// The bridge to the native WebView that carries yfsp's requests.
///
/// yfsp is behind Cloudflare's interactive challenge, and the clearance a
/// human earns is bound to the *browser's* TLS fingerprint — a cookie lifted
/// out and replayed from Dart's HTTP client is refused all the same
/// (measured). So the requests are made from inside a real browser engine
/// instead: [fetch] hands a signed URL to the native side, which runs it from
/// the WebView that passed the challenge and returns the raw response text.
///
/// [solve] opens that WebView in a window for the human to pass the check.
/// Only macOS implements the channel; elsewhere both calls report "no window"
/// and the plain error stays on screen.
class YfspBrowser {
  YfspBrowser._();

  static const _channel = MethodChannel('vidra/yfsp_browser');

  /// One request through the browser. Returns the response body text.
  ///
  /// Throws [ChallengeRequiredException] when the browser has not (yet) passed
  /// the challenge — the caller surfaces the "verify" button — and a plain
  /// [ApiException] when the native transport is missing or errored.
  static Future<String> fetch(String url) async {
    final Map<dynamic, dynamic>? env;
    try {
      env = await _channel.invokeMethod<Map<dynamic, dynamic>>('fetch', {
        'url': url,
        'userAgent': YfspSigner.userAgent,
      });
    } on MissingPluginException {
      // No browser on this platform; nothing can pass the wall here.
      throw ChallengeRequiredException();
    } on PlatformException catch (e) {
      logD('Yfsp', 'browser fetch failed: $e');
      throw ApiException(message: '爱壹帆连接失败');
    }

    final status = (env?['status'] as num?)?.toInt() ?? -1;
    final body = env?['body'] as String? ?? '';

    if (status == -1) throw ApiException(message: '爱壹帆连接失败');
    // The wall is told apart from the API's own answer by the BODY, not a code:
    // Cloudflare's interactive page carries a marker, while whatever the API
    // itself returns is JSON we still want to parse for its code/msg.
    if (_looksLikeChallenge(body)) throw ChallengeRequiredException();
    return body;
  }

  /// The signing key pair, read from the key page's inline `pConfig` via a
  /// NAVIGATION load in the browser (an XHR of that page comes back without the
  /// keys). Null when the page has no pConfig — which, in practice, means the
  /// Cloudflare wall is up and a human still has to pass it.
  static Future<({String pub, String priv})?> readKeys() async {
    try {
      final env = await _channel.invokeMethod<Map<dynamic, dynamic>>('keys', {
        'userAgent': YfspSigner.userAgent,
      });
      final pub = env?['pub'] as String?;
      final priv = env?['priv'] as String?;
      if (pub == null || priv == null || pub.isEmpty || priv.isEmpty) {
        return null;
      }
      return (pub: pub, priv: priv);
    } on PlatformException catch (e) {
      logD('Yfsp', 'readKeys failed: $e');
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  /// Opens the challenge window and resolves true once the human passes it,
  /// false if they close it (or the platform has no window).
  static Future<bool> solve() async {
    try {
      return await _channel.invokeMethod<bool>('solve', {
            'userAgent': YfspSigner.userAgent,
          }) ??
          false;
    } on PlatformException catch (e) {
      logD('Yfsp', 'challenge window failed: $e');
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  /// Cloudflare's wall markup, told apart from the API's JSON. Both the
  /// interactive page and its non-interactive variant carry one of these.
  static bool _looksLikeChallenge(String body) {
    if (body.isEmpty) return true;
    final head = body.length > 1500 ? body.substring(0, 1500) : body;
    return head.contains('cf-mitigated') ||
        head.contains('Just a moment') ||
        head.contains('challenge-platform') ||
        head.contains('Attention Required');
  }
}

/// What the yfsp source throws when the wall is up. Its own type, because the
/// error screen keys the "human check" button off it.
class ChallengeRequiredException extends ApiException {
  ChallengeRequiredException()
    : super(message: '爱壹帆开启了人机验证', statusCode: 403);
}
