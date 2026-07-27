import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;

import '../utils/log.dart';

/// Windows only installs a root certificate the first time *Schannel* meets it
/// (Automatic Root Update). Dart's TLS stack is BoringSSL, never triggers that
/// update, and so fails with `CERTIFICATE_VERIFY_FAILED: unable to get local
/// issuer certificate` on any host whose chain ends at a root the machine has
/// not browsed to yet — olevod's images chain to Certum Trusted Root CA and hit
/// exactly this. Seeding Mozilla's bundle covers every such host at once.
///
/// Installed as an [HttpOverrides] rather than on the Dio adapter because image
/// loading (`NetworkImage`, `CachedNetworkImage`) makes its own `HttpClient`.
/// Must run before the first request.
///
/// ponytail: refresh `assets/certs/cacert.pem` from https://curl.se/ca/cacert.pem
/// when a site starts failing on Windows only.
Future<void> installBundledRoots() async {
  if (!Platform.isWindows) return;
  try {
    final pem = await rootBundle.load('assets/certs/cacert.pem');
    final context = SecurityContext(withTrustedRoots: true)
      ..setTrustedCertificatesBytes(pem.buffer.asUint8List());
    HttpOverrides.global = _BundledRootsOverrides(context);
  } catch (e) {
    // A broken bundle must not take the app down; the OS roots still apply.
    logR('BundledRoots', 'Failed to install bundled roots: $e');
  }
}

class _BundledRootsOverrides extends HttpOverrides {
  _BundledRootsOverrides(this._context);

  final SecurityContext _context;

  @override
  HttpClient createHttpClient(SecurityContext? context) =>
      super.createHttpClient(context ?? _context);
}
