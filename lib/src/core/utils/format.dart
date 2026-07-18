/// seconds → clock "41:32" / "1:02:03" ([clock] true, for runtimes) or human
/// "45s" / "5m 3s" / "1h 2m" (default, for time-remaining).
String formatDuration(int seconds, {bool clock = false}) {
  final d = Duration(seconds: seconds);
  final h = d.inHours;
  final m = d.inMinutes % 60;
  final s = d.inSeconds % 60;
  if (clock) {
    final mm = m.toString().padLeft(2, '0');
    final ss = s.toString().padLeft(2, '0');
    return h > 0 ? '$h:$mm:$ss' : '$m:$ss';
  }
  if (seconds < 60) return '${seconds}s';
  if (seconds < 3600) return '${m}m ${s}s';
  return '${h}h ${m}m';
}

/// bytes → "1.2 MB" / "512 B" / "3.4 GB". Shared by download UI and models.
String formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  const units = ['KB', 'MB', 'GB', 'TB'];
  double v = bytes / 1024;
  int u = 0;
  while (v >= 1024 && u < units.length - 1) {
    v /= 1024;
    u++;
  }
  return '${v.toStringAsFixed(v >= 100 ? 0 : 1)} ${units[u]}';
}
