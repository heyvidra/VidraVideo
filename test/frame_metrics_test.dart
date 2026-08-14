import 'package:flutter_test/flutter_test.dart';
import 'package:vidra/src/core/telemetry/frame_metrics.dart';

/// The aggregator is what a frame report actually says, so it is tested on the
/// two things someone reads off one: where the percentiles land, and how many
/// frames missed the budget.
void main() {
  FrameAggregator withMillis(Iterable<num> millis, {int capacity = 4096}) {
    final agg = FrameAggregator(capacity: capacity);
    for (final ms in millis) {
      agg.addSample(Duration(microseconds: (ms * 1000).round()));
    }
    return agg;
  }

  group('percentiles', () {
    test('nearest rank over 1..100ms', () {
      final s = withMillis([for (var i = 1; i <= 100; i++) i]).summary();

      expect(s['frames'], 100);
      expect(s['sampled'], 100);
      expect(s['p50_ms'], 50.0);
      expect(s['p95_ms'], 95.0);
      expect(s['p99_ms'], 99.0);
      expect(s['worst_ms'], 100.0);
    });

    test('order of arrival does not matter', () {
      final up = withMillis([for (var i = 1; i <= 100; i++) i]).summary();
      final down = withMillis([for (var i = 100; i >= 1; i--) i]).summary();
      expect(down['p95_ms'], up['p95_ms']);
    });

    test('a single frame is its own p50 and p99', () {
      final s = withMillis([12.5]).summary();
      expect(s['p50_ms'], 12.5);
      expect(s['p99_ms'], 12.5);
    });

    test('an empty window reports nothing at all', () {
      expect(FrameAggregator().summary(), isEmpty);
    });
  });

  group('jank', () {
    test('counted against the 60Hz budget, badly dropped counted twice', () {
      final agg = withMillis([
        ...List.filled(90, 8.0), // comfortable
        ...List.filled(7, 20.0), // over 16.7ms
        ...List.filled(3, 50.0), // over 33ms as well
      ]);
      final s = agg.summary();

      // A badly dropped frame is still a dropped frame: the counts nest, so
      // nobody has to add them together to get the total.
      expect(s['jank_16ms'], 10);
      expect(s['jank_33ms'], 3);
      expect(agg.severeJank, lessThanOrEqualTo(agg.jank));
    });

    test('a frame exactly on the budget is not jank', () {
      final agg = withMillis([16.7, 16.8]);
      expect(agg.jank, 1);
    });
  });

  test('build and raster averages come back in milliseconds', () {
    final agg = FrameAggregator();
    for (var i = 0; i < 4; i++) {
      agg.addSample(
        const Duration(milliseconds: 10),
        build: const Duration(milliseconds: 2),
        raster: const Duration(milliseconds: 6),
      );
    }
    final s = agg.summary();
    expect(s['build_avg_ms'], 2.0);
    expect(s['raster_avg_ms'], 6.0);
  });

  test('the reservoir is bounded: counts exact, percentiles recent', () {
    final agg = withMillis([
      ...List.filled(8, 100.0),
      ...List.filled(8, 10.0),
    ], capacity: 8);
    final s = agg.summary();

    // Memory is constant, so the oldest half of the window is gone…
    expect(s['sampled'], 8);
    expect(s['p50_ms'], 10.0);
    // …but every frame that ever arrived is still counted.
    expect(s['frames'], 16);
    expect(s['jank_16ms'], 8);
    expect(s['worst_ms'], 100.0);
  });

  test('reset empties the window without reallocating it', () {
    final agg = withMillis([50.0, 60.0])..reset();
    expect(agg.frames, 0);
    expect(agg.jank, 0);
    expect(agg.summary(), isEmpty);

    agg.addSample(const Duration(milliseconds: 8));
    expect(agg.summary()['worst_ms'], 8.0);
  });

  test('a summary is numbers only — nothing here can carry content', () {
    final s = withMillis([10.0, 20.0]).summary();
    expect(s, isNotEmpty);
    expect(s.values.every((v) => v is num), isTrue);
  });
}
