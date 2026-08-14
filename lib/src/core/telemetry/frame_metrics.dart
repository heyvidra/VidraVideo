import 'dart:typed_data';
import 'dart:ui' show FramePhase;

import 'package:flutter/scheduler.dart';

import '../utils/log.dart';
import 'telemetry.dart';

/// How long a frame is allowed to take before it counts as jank.
///
/// Fixed at the 60Hz budget rather than the panel's actual refresh interval:
/// these reports are compared BETWEEN machines — a 2016 Intel laptop against
/// an M4 — and a threshold that moved with the display would make the two
/// numbers mean different things.
const int _jankMicros = 16700;

/// Badly dropped: two 60Hz budgets. Visible as a stutter rather than as a
/// number, which is what a person actually complains about.
const int _severeJankMicros = 33000;

/// A span longer than this is the engine having been suspended mid-frame —
/// a lid closed, a machine slept — not something anyone waited through.
/// Clamped rather than dropped: the freeze was real and belongs in the jank
/// count, but one artifact must not own p99, and the samples are stored as
/// 32-bit micros.
const int _maxFrameMicros = 10 * 1000000;

/// Frame timings, reduced to arithmetic.
///
/// The pure half of frame collection: durations in, counts and percentiles
/// out. It holds no clock and no binding, so the real collector and a test
/// drive it the same way.
///
/// Samples live in a fixed-size ring, oldest-dropped. A session that renders
/// for an hour must not cost an hour's worth of memory, and dropping the
/// oldest keeps the percentiles describing recent rendering — which is the
/// rendering someone is complaining about. The counts ([frames], [jank],
/// [severeJank]) are exact over the whole window regardless; only the
/// percentiles are limited to the last [capacity] frames.
class FrameAggregator {
  FrameAggregator({int capacity = 4096}) : _spans = Int32List(capacity);

  /// 4096 spans is 16KB, and covers a full 60Hz window without wrapping.
  int get capacity => _spans.length;

  final Int32List _spans;
  int _next = 0;
  bool _wrapped = false;

  int _frames = 0;
  int _jank = 0;
  int _severeJank = 0;
  int _worstMicros = 0;
  int _buildMicros = 0;
  int _rasterMicros = 0;

  /// Every frame seen since the last [reset], not just the sampled ones.
  int get frames => _frames;

  /// Frames over the 60Hz budget. Includes [severeJank] — a badly dropped
  /// frame is still a dropped frame, and a report where the two counts had to
  /// be added together to mean anything would get added up wrong.
  int get jank => _jank;
  int get severeJank => _severeJank;

  /// Adds one frame. Micros rather than [Duration] so the timings callback,
  /// which runs on every batch, allocates nothing per frame.
  void addMicros(int totalMicros, int buildMicros, int rasterMicros) {
    if (totalMicros < 0) return;
    if (totalMicros > _maxFrameMicros) totalMicros = _maxFrameMicros;
    _spans[_next] = totalMicros;
    _next++;
    if (_next == capacity) {
      _next = 0;
      _wrapped = true;
    }
    _frames++;
    if (totalMicros > _jankMicros) _jank++;
    if (totalMicros > _severeJankMicros) _severeJank++;
    if (totalMicros > _worstMicros) _worstMicros = totalMicros;
    _buildMicros += buildMicros;
    _rasterMicros += rasterMicros;
  }

  /// [addMicros] for callers that already hold [Duration]s.
  void addSample(Duration total, {Duration? build, Duration? raster}) {
    addMicros(
      total.inMicroseconds,
      build?.inMicroseconds ?? 0,
      raster?.inMicroseconds ?? 0,
    );
  }

  /// The window as numbers. Empty when nothing was collected, so a caller
  /// cannot report a window that never rendered.
  ///
  /// Sorts a copy of the ring, so it costs something — call it once per
  /// window, not per frame.
  Map<String, Object?> summary() {
    final sampled = _wrapped ? capacity : _next;
    if (sampled == 0) return const {};
    final sorted = _spans.sublist(0, sampled)..sort();
    return {
      'frames': _frames,
      'sampled': sampled,
      'p50_ms': _ms(_percentile(sorted, 50)),
      'p95_ms': _ms(_percentile(sorted, 95)),
      'p99_ms': _ms(_percentile(sorted, 99)),
      'worst_ms': _ms(_worstMicros),
      'jank_16ms': _jank,
      'jank_33ms': _severeJank,
      'build_avg_ms': _ms(_buildMicros ~/ _frames),
      'raster_avg_ms': _ms(_rasterMicros ~/ _frames),
    };
  }

  void reset() {
    _next = 0;
    _wrapped = false;
    _frames = 0;
    _jank = 0;
    _severeJank = 0;
    _worstMicros = 0;
    _buildMicros = 0;
    _rasterMicros = 0;
  }

  /// Nearest-rank percentile, in integers throughout: `n * percent / 100`
  /// rounded up is the 1-based rank. Doubles here would put p99 on either
  /// side of a sample boundary depending on the rounding of 0.99.
  static int _percentile(Int32List sorted, int percent) {
    final rank = (sorted.length * percent + 99) ~/ 100;
    return sorted[rank < 1 ? 0 : rank - 1];
  }

  /// Milliseconds to two decimals, without formatting a string: these are
  /// numbers to compare across builds, not text to read.
  static double _ms(int micros) => (micros / 10).round() / 100;
}

/// The app's frame collector: one report per window of active rendering.
///
/// Registered by the dashboard shell rather than by `main()`, so it measures
/// the main window. The player runs in its own engine with its own
/// [SchedulerBinding] and is tagged separately by [Telemetry.run].
///
/// Nothing here describes what was on screen. The only contextual field is a
/// coarse screen label the shell hands over — one of a fixed set of literals,
/// never a location, because '/detail/83579' and '/search/…' ARE the viewing
/// history this app must not collect. Machine class and the reduce-effects
/// setting are already global Sentry tags and are not repeated per report.
class FrameMetrics {
  FrameMetrics._();

  static final FrameMetrics instance = FrameMetrics._();

  /// One report per five minutes of rendering — measured in frames, not on a
  /// wall clock. A timer would keep firing while the app sits idle in the
  /// background at zero frames, and a stream of reports saying "no jank in a
  /// window where nothing was drawn" is worse than no reports at all.
  ///
  /// Five rather than one because the free Sentry tier is 5k events a month
  /// and a per-minute window spends it on a handful of machines. The counters
  /// are exact over whatever the window turns out to be and [summary] reports
  /// `window_s`, so a longer window costs resolution, not correctness.
  static const int _windowMicros = 5 * 60 * 1000000;

  /// A gap larger than this is not slow rendering, it is the app doing
  /// nothing — so it does not count towards the window.
  static const int _idleGapMicros = 1000000;

  /// Below this, a window says nothing about how the machine renders. Only
  /// reached by a lifecycle flush; a full window is thousands of frames.
  static const int _minFrames = 60;

  /// Null until [start], and again after teardown: a build with diagnostics
  /// off allocates no buffer and registers no callback.
  FrameAggregator? _aggregator;
  int _activeMicros = 0;
  int _lastVsyncMicros = 0;
  String? _screen;
  bool _screenStable = true;

  /// Begins collecting, unless diagnostics are off. Idempotent.
  void start() {
    if (_aggregator != null || !Telemetry.isEnabled) return;
    _aggregator = FrameAggregator();
    SchedulerBinding.instance.addTimingsCallback(_onTimings);
  }

  /// Reports what the current window holds, then stops collecting.
  void stop() {
    flush();
    _teardown();
  }

  /// The screen currently rendering, as a fixed label ('catalog', 'detail').
  /// Cheap enough to call from a build method: it assigns a field and
  /// notifies nothing.
  void setScreen(String label) {
    if (_screen == label) return;
    // A window that spanned two screens still reports, but says so: mixing a
    // scrolling catalog with an idle settings page would otherwise read as
    // one well-behaved screen.
    if (_screen != null) _screenStable = false;
    _screen = label;
  }

  /// Sends the current window if it holds enough frames to mean anything.
  ///
  /// Called when a window fills, and by the shell on lifecycle pause or
  /// detach — nothing renders once the app is put away, so no later batch
  /// would arrive to flush the window that just ended.
  void flush() {
    final aggregator = _aggregator;
    if (aggregator == null) return;
    // Diagnostics can be switched off mid-session from settings. The window
    // in hand goes with it rather than waiting for a later flush.
    if (!Telemetry.isEnabled) {
      _teardown();
      return;
    }
    if (aggregator.frames < _minFrames) return;
    try {
      Telemetry.report(
        'frames',
        data: {
          ...aggregator.summary(),
          'window_s': _activeMicros ~/ 1000000,
          if (_screen != null) 'screen': _screen,
          'screen_stable': _screenStable,
        },
      );
    } catch (e) {
      // Diagnostics must never be able to break the thing they watch.
      logD('frames', 'flush failed: $e');
    } finally {
      aggregator.reset();
      _activeMicros = 0;
      _screenStable = true;
    }
  }

  void _teardown() {
    if (_aggregator == null) return;
    SchedulerBinding.instance.removeTimingsCallback(_onTimings);
    _aggregator = null;
    _activeMicros = 0;
    _lastVsyncMicros = 0;
    _screenStable = true;
  }

  /// Runs on every frame batch, so it does integer arithmetic and nothing
  /// else: no allocation, no formatting, no percentiles.
  void _onTimings(List<FrameTiming> timings) {
    final aggregator = _aggregator;
    if (aggregator == null) return;
    try {
      for (var i = 0; i < timings.length; i++) {
        final timing = timings[i];
        final vsync = timing.timestampInMicroseconds(FramePhase.vsyncStart);
        final gap = vsync - _lastVsyncMicros;
        _lastVsyncMicros = vsync;
        if (gap > 0 && gap < _idleGapMicros) _activeMicros += gap;
        final buildStart = timing.timestampInMicroseconds(
          FramePhase.buildStart,
        );
        final buildFinish = timing.timestampInMicroseconds(
          FramePhase.buildFinish,
        );
        final rasterStart = timing.timestampInMicroseconds(
          FramePhase.rasterStart,
        );
        final rasterFinish = timing.timestampInMicroseconds(
          FramePhase.rasterFinish,
        );
        aggregator.addMicros(
          rasterFinish - vsync,
          buildFinish - buildStart,
          rasterFinish - rasterStart,
        );
      }
    } catch (e) {
      logD('frames', 'timings failed: $e');
      return;
    }
    if (_activeMicros >= _windowMicros) flush();
  }
}
