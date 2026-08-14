import 'dart:io' show Platform;

import 'package:flutter/services.dart';

import '../../../core/utils/log.dart';

/// Keeps the machine from idling to sleep while it is serving a cast.
///
/// Casting makes this machine the media server — the television pulls every
/// segment from a local HTTP server here — so a system sleep freezes the
/// process and the picture stops dead.
///
/// Deliberately NOT `wakelock_plus`, which asserts `NoDisplaySleep` and
/// leaves the screen lit all evening for a video playing on another device.
/// The native side asserts `NoIdleSleep` instead: the display sleeps on its
/// usual schedule, the system stays up. Closing the lid still sleeps the
/// machine and still drops the cast — no assertion overrides a sleep the
/// user asked for, and pretending otherwise would be a worse lie than the
/// current behaviour.
///
/// macOS only. Everything here is a no-op elsewhere rather than a failure:
/// Windows and Linux casting would need their own assertion and neither has
/// been tested against a television.
class SleepBlocker {
  const SleepBlocker._();

  static const _channel = MethodChannel('vidra/sleep_blocker');

  /// True while an assertion is believed to be held, so a failed release is
  /// not retried forever and a second cast does not stack assertions.
  static bool _held = false;

  static bool get isHeld => _held;

  static Future<void> hold() async {
    if (!Platform.isMacOS || _held) return;
    try {
      final ok = await _channel.invokeMethod<bool>('hold', {
        'reason': 'Vidra is casting to a television',
      });
      _held = ok ?? false;
    } on PlatformException catch (e) {
      // A cast that cannot hold the assertion is still a cast; it just stops
      // when the machine sleeps, which is what happens today.
      logD('cast', 'sleep assertion refused: ${e.code}');
    } on MissingPluginException {
      // An engine without the channel — a secondary window, or a build that
      // predates it.
    }
  }

  static Future<void> release() async {
    if (!Platform.isMacOS || !_held) return;
    _held = false;
    try {
      await _channel.invokeMethod<bool>('release');
    } on PlatformException catch (e) {
      logD('cast', 'sleep assertion release failed: ${e.code}');
    } on MissingPluginException {
      // Nothing to release.
    }
  }
}
