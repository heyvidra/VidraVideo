import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'video_data_source.dart';
import 'video_repository.dart';

/// One source's round trip, or the fact that it did not answer.
class SourceLatency {
  const SourceLatency({
    required this.sourceId,
    required this.name,
    this.millis,
  });

  final String sourceId;
  final String name;

  /// Null when the host refused, timed out, or has no network behind it.
  final int? millis;

  bool get reachable => millis != null;
}

/// How long a probe waits before calling a host unreachable.
///
/// Long enough that a slow mobile link still reports a number, short enough
/// that a dead source does not hold the status bar in "measuring" for the
/// whole of it.
const _kTimeout = Duration(seconds: 5);

/// Latency to every enabled source, newest measurement wins.
///
/// Measured with a TCP connect, NOT an API call. yfsp answers a burst of API
/// requests with `code:5` and escalates to a bot challenge, so a number that
/// refreshes on a timer must not be bought with API calls — see
/// [VideoDataSource.pingHost]. A connect is also the honest measurement here:
/// what the user picks between is the round trip to the host, not how quickly
/// one endpoint happens to render.
///
/// Probes run in PARALLEL: a dead source that eats the whole timeout must not
/// delay the numbers for the live ones.
class SourceLatencyNotifier extends AsyncNotifier<List<SourceLatency>> {
  @override
  Future<List<SourceLatency>> build() async {
    // Re-measures when the enabled set changes, which is exactly when the row
    // the user is looking at gains or loses an entry.
    final sources = ref.watch(availableDataSourcesProvider);
    return _probeAll(sources);
  }

  /// The shortest gap between two measurements.
  ///
  /// The button this throttles is one click away from opening a connection to
  /// every source at once. Held here rather than in the button so a second
  /// caller — another widget, a later feature — cannot get a faster probe by
  /// not knowing about the rule.
  static const cooldown = Duration(minutes: 1);

  DateTime? _lastProbeAt;

  /// When the next measurement is allowed, or null when one is allowed now.
  DateTime? get nextRefreshAt {
    final last = _lastProbeAt;
    if (last == null) return null;
    final at = last.add(cooldown);
    return at.isAfter(DateTime.now()) ? at : null;
  }

  bool get canRefresh => nextRefreshAt == null;

  /// Measure again, keeping the previous numbers on screen meanwhile.
  ///
  /// Deliberately manual: nothing here polls. A status bar that re-probed on a
  /// timer would open connections to every source forever, including while the
  /// app sits untouched in the background.
  ///
  /// A call inside the cooldown is a no-op rather than an error — the caller
  /// asked for fresh numbers and the numbers on screen are as fresh as this
  /// is willing to make them.
  Future<void> refresh() async {
    if (!canRefresh) return;
    final sources = ref.read(availableDataSourcesProvider);
    state = AsyncData(await _probeAll(sources));
  }

  Future<List<SourceLatency>> _probeAll(List<VideoDataSource> sources) async {
    // Stamped here rather than in [refresh], so the cooldown counts from ANY
    // measurement. The first build probes too, and a toggle in settings
    // rebuilds and probes again — without this, a source switched on would
    // hand out a free extra probe a moment later.
    _lastProbeAt = DateTime.now();
    return Future.wait(sources.map(_probe));
  }

  Future<SourceLatency> _probe(VideoDataSource source) async {
    final host = source.pingHost;
    if (host == null) {
      return SourceLatency(sourceId: source.id, name: source.name);
    }
    final watch = Stopwatch()..start();
    Socket? socket;
    try {
      socket = await Socket.connect(host, 443, timeout: _kTimeout);
      return SourceLatency(
        sourceId: source.id,
        name: source.name,
        millis: watch.elapsedMilliseconds,
      );
    } on Object {
      // Any failure is the same answer to the only question being asked: this
      // source is not reachable right now.
      return SourceLatency(sourceId: source.id, name: source.name);
    } finally {
      // destroy, not close: close waits for the peer, and nothing was sent.
      socket?.destroy();
    }
  }
}

final sourceLatencyProvider =
    AsyncNotifierProvider<SourceLatencyNotifier, List<SourceLatency>>(
      SourceLatencyNotifier.new,
    );

/// How many bars of five to fill for [millis].
///
/// Thresholds are for a signal glyph, not a benchmark: what the user needs off
/// this is "which of these is the quick one", and four buckets say that
/// without inviting anyone to read meaning into a 12ms difference.
int latencyBars(int? millis) {
  if (millis == null) return 0;
  if (millis < 120) return 4;
  if (millis < 300) return 3;
  if (millis < 800) return 2;
  return 1;
}
