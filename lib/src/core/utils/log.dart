import 'dart:io';

import 'package:flutter/foundation.dart' show kDebugMode;

/// Single logging entrypoint. Use [logD] for debug-only noise and [logR]
/// for messages that should also appear in release builds.
void logR(String tag, String message) {
  final time = DateTime.now().toIso8601String();
  final pid = pidSafe;
  stdout.writeln('[$time][$pid][$tag] $message');
}

/// Debug-only log; silent in release builds.
void logD(String tag, String message) {
  if (kDebugMode) logR(tag, message);
}

String get pidSafe {
  try {
    return pid.toString();
  } catch (_) {
    return 'no-pid';
  }
}
