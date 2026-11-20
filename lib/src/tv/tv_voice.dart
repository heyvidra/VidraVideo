import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../config/app_theme.dart';
import '../core/utils/log.dart';

// Two ways to search without the on-screen keyboard.
//
// [TvVoice] is the device's own recognizer — one press, but it only exists
// where the box ships one (Google TV). [PhoneInput] works on every box that
// is on a LAN, which is what covers the domestic ones: the phone's keyboard
// already has a microphone, in the user's own dialect and accent, with no
// speech SDK, account or key in this app.
//
// ponytail: no bundled speech engine. Speaking into a domestic box's remote
// needs that vendor's SDK (iFlytek etc.) and its credentials; add it behind
// TvVoice when there is an account to put in.

class TvVoice {
  const TvVoice._();

  static const _channel = MethodChannel('vidra/voice');

  static Future<bool> available() async {
    try {
      return await _channel.invokeMethod<bool>('available') ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Shows the system's listening UI; null when cancelled or nothing heard.
  static Future<String?> listen(String languageTag) async {
    try {
      final text = await _channel.invokeMethod<String>('listen', {
        'language': languageTag,
      });
      return (text == null || text.trim().isEmpty) ? null : text.trim();
    } catch (_) {
      return null;
    }
  }
}

/// A one-field web page served to the LAN, for typing (or dictating) a search
/// on a phone.
///
/// The trust boundary of this app: anything on the network can reach the
/// port. So the path carries a random token only the QR code shows, the body
/// is capped, and the only thing a request can do is hand over a short string
/// that becomes a search keyword.
class PhoneInput {
  PhoneInput._(this._server, this.url);

  final HttpServer _server;
  final Uri url;

  static const _maxBody = 2048;
  static const _maxKeyword = 60;

  /// Null when the device has no LAN address to be reached at.
  static Future<PhoneInput?> start(
    void Function(String keyword) onKeyword,
  ) async {
    final address = await _lanAddress();
    if (address == null) return null;
    final server = await HttpServer.bind(InternetAddress.anyIPv4, 0);
    final random = Random.secure();
    final token = [
      for (var i = 0; i < 8; i++) random.nextInt(16).toRadixString(16),
    ].join();
    final url = Uri(
      scheme: 'http',
      host: address,
      port: server.port,
      path: '/$token',
    );
    logD('TV', 'phone input at port ${server.port}');
    server.listen((request) async {
      try {
        await _handle(request, token, onKeyword);
      } catch (_) {
        // A phone that hung up mid-request is not this app's problem.
      } finally {
        await request.response.close().catchError((_) {});
      }
    });
    return PhoneInput._(server, url);
  }

  Future<void> close() => _server.close(force: true);

  static Future<void> _handle(
    HttpRequest request,
    String token,
    void Function(String) onKeyword,
  ) async {
    final response = request.response;
    if (request.uri.path != '/$token') {
      response.statusCode = HttpStatus.notFound;
      return;
    }
    var sent = false;
    if (request.method == 'POST') {
      final bytes = <int>[];
      await for (final chunk in request) {
        bytes.addAll(chunk);
        if (bytes.length > _maxBody) {
          response.statusCode = HttpStatus.requestEntityTooLarge;
          return;
        }
      }
      final keyword =
          (Uri.splitQueryString(
                    utf8.decode(bytes, allowMalformed: true),
                  )['q'] ??
                  '')
              .replaceAll(RegExp(r'\s+'), ' ')
              .trim();
      if (keyword.isNotEmpty) {
        onKeyword(
          keyword.length > _maxKeyword
              ? keyword.substring(0, _maxKeyword)
              : keyword,
        );
        sent = true;
      }
    }
    response.headers.contentType = ContentType.html;
    response.write(_page(sent));
  }

  // No user text is ever echoed into this page, so there is nothing to escape.
  static String _page(bool sent) =>
      '''
<!doctype html><html><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Vidra</title><style>
body{margin:0;padding:28px 20px;background:#0A1220;color:#fff;font:17px -apple-system,sans-serif}
h1{font-size:22px;color:#7BE7F0;margin:0 0 20px}
input{width:100%;box-sizing:border-box;padding:14px;font-size:18px;border-radius:12px;border:0}
button{width:100%;margin-top:14px;padding:14px;font-size:18px;border:0;border-radius:12px;background:#7BE7F0;color:#000}
p{color:#ffffffa8;font-size:14px}</style></head><body>
<h1>Vidra</h1>
<form method="post"><input name="q" maxlength="$_maxKeyword" autofocus
 enterkeyhint="search" placeholder="片名 / Title">
<button>搜索 / Search</button></form>
<p>${sent ? '✓ 已发送到电视 / Sent to the TV' : '点键盘上的麦克风可以直接说 / Tap the keyboard microphone to speak'}</p>
</body></html>''';

  /// The address a phone on the same network would reach this device at.
  static Future<String?> _lanAddress() async {
    final interfaces = await NetworkInterface.list(
      type: InternetAddressType.IPv4,
    );
    final addresses = [
      for (final i in interfaces)
        for (final a in i.addresses)
          if (!a.isLoopback && !a.isLinkLocal) a.address,
    ];
    if (addresses.isEmpty) return null;
    // A box with both a LAN and something else up (VPN, tether): the LAN is
    // the one a phone in the room can see.
    return addresses.firstWhere(
      (a) => a.startsWith('192.168.') || a.startsWith('10.'),
      orElse: () => addresses.first,
    );
  }
}

/// The QR code and what to do with it. Nothing here is focusable: Back closes
/// it, and a keyword arriving closes it from the caller's side.
class PhoneInputDialog extends StatelessWidget {
  const PhoneInputDialog({super.key, required this.url});

  final Uri url;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF111C2E),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // White card: a QR code is read by contrast, not by theme.
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(10),
              child: QrImageView(data: '$url', size: 190),
            ),
            const SizedBox(width: 28),
            SizedBox(
              width: 300,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr('tv.phone_title'),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    tr('tv.phone_steps'),
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.7,
                      color: Color(0xA8FFFFFF),
                    ),
                  ),
                  const SizedBox(height: 14),
                  // For a phone whose camera will not scan: typeable.
                  Text(
                    '$url',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.accent,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
