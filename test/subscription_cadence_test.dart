// The cadence decides how often the app talks to a source. Getting it wrong in
// one direction misses episodes; in the other it turns a subscription list into
// a polling loop against someone else's server. These tests weight the second
// way — a late notification is a shrug, a request storm is abuse.

import 'package:flutter_test/flutter_test.dart';
import 'package:vidra/src/features/subscription/domain/subscription.dart';

DateTime day(int d, [int hour = 20]) => DateTime(2026, 8, d, hour);

void main() {
  group('estimateInterval', () {
    test('one sighting is a point, not an interval', () {
      expect(UpdateCadence.estimateInterval([day(1)]), isNull);
      expect(UpdateCadence.estimateInterval(const []), isNull);
    });

    test('a daily show reads as daily', () {
      final i = UpdateCadence.estimateInterval([day(1), day(2), day(3)]);
      expect(i, const Duration(days: 1));
    });

    test('a weekly show reads as weekly', () {
      final i = UpdateCadence.estimateInterval([day(1), day(8), day(15)]);
      expect(i, const Duration(days: 7));
    });

    test('a hiatus does not drag the estimate', () {
      // Daily, then a three-week break, then daily again. A mean would call
      // this show roughly six-daily and stop looking; the median keeps saying
      // daily, which is what the schedule actually is.
      final updates = [day(1), day(2), day(3), day(24), day(25)];
      expect(UpdateCadence.estimateInterval(updates), const Duration(days: 1));
    });

    test('input order does not matter', () {
      expect(
        UpdateCadence.estimateInterval([day(15), day(1), day(8)]),
        const Duration(days: 7),
      );
    });

    test('two sightings of one release are not an interval', () {
      // The same episode seen twice minutes apart — a list refresh — would
      // otherwise produce a near-zero gap and collapse the schedule into a
      // poll, which is the exact failure this design exists to avoid.
      final t = day(1);
      final i = UpdateCadence.estimateInterval([
        t,
        t,
        t.add(const Duration(days: 1)),
      ]);
      expect(i, const Duration(days: 1));
    });
  });

  group('nextExpected', () {
    test('a daily show is looked at again about a day later', () {
      final next = UpdateCadence.nextExpected([day(1), day(2), day(3)]);
      // One day on, minus the early-look slack.
      expect(
        next,
        day(3).add(const Duration(days: 1)).subtract(UpdateCadence.slack),
      );
    });

    test('never schedules sooner than the unknown-case floor', () {
      // A burst of sightings could estimate a tiny interval; honouring it
      // would make the show due on every tick.
      final t = day(1);
      final updates = [
        t,
        t.add(const Duration(minutes: 5)),
        t.add(const Duration(minutes: 10)),
      ];
      final next = UpdateCadence.nextExpected(updates);
      final earliest = updates.last
          .add(UpdateCadence.unknownInterval)
          .subtract(UpdateCadence.slack);
      expect(next.isBefore(earliest), isFalse);
    });
  });

  group('dueForCheck', () {
    final sub = Subscription(sourceId: 'olevod', videoId: 1, title: 'T');

    test('a show never seen updating is checked', () {
      expect(sub.dueForCheck(day(1)), isTrue);
    });

    test('a finished show is never checked again', () {
      final done = sub.copyWith(finished: true, nextCheckAt: day(1));
      expect(
        done.dueForCheck(day(30)),
        isFalse,
        reason: 'no request can produce an episode that will not exist',
      );
    });

    test('a scheduled show waits for its slot', () {
      final planned = sub.copyWith(nextCheckAt: day(5));
      expect(planned.dueForCheck(day(4)), isFalse);
      expect(planned.dueForCheck(day(5)), isTrue);
      expect(planned.dueForCheck(day(6)), isTrue);
    });
  });

  group('looksFinished', () {
    test('a completed run is recognised', () {
      expect(looksFinished('全24集'), isTrue);
      expect(looksFinished('全 24 集'), isTrue);
      expect(looksFinished('已完结'), isTrue);
      expect(looksFinished('完結'), isTrue);
    });

    test('a running show is never mistaken for a finished one', () {
      // Both mention 24. Reading the second as finished would stop following a
      // show mid-run, silently, and nothing on screen would explain it.
      expect(looksFinished('更新至第 24 集'), isFalse);
      expect(looksFinished('更新至24集'), isFalse);
      expect(looksFinished('第24集'), isFalse);
      expect(looksFinished(null), isFalse);
      expect(looksFinished(''), isFalse);
    });
  });

  group('withUpdate', () {
    test('records the sighting, re-plans, and flags it unread', () {
      var s = Subscription(sourceId: 's', videoId: 1, title: 'T');
      s = s.withUpdate('更新至第 01 集', day(1));
      s = s.withUpdate('更新至第 02 集', day(2));

      expect(s.lastSeenRemarks, '更新至第 02 集');
      expect(s.updateHistory, [day(1), day(2)]);
      expect(s.unread, isTrue);
      expect(s.finished, isFalse);
      expect(s.nextCheckAt, isNotNull);
    });

    test(
      'history is capped so an old schedule cannot outvote the current one',
      () {
        var s = Subscription(sourceId: 's', videoId: 1, title: 'T');
        for (var d = 1; d <= 10; d++) {
          s = s.withUpdate('更新至第 $d 集', day(d));
        }
        expect(s.updateHistory, hasLength(Subscription.maxHistory));
        expect(s.updateHistory.first, day(10 - Subscription.maxHistory + 1));
      },
    );

    test('a finishing remark ends the subscription cheaply', () {
      var s = Subscription(sourceId: 's', videoId: 1, title: 'T');
      s = s.withUpdate('全 30 集', day(1));
      expect(s.finished, isTrue);
      expect(s.dueForCheck(day(90)), isFalse);
    });
  });

  group('retryAfterMiss', () {
    test('a check that found nothing waits less than a full cycle', () {
      // A daily show due at 20:00 that has not updated is usually late, not
      // gone. Waiting the full day would skip the release it was late for.
      final daily = [day(1), day(2), day(3)];
      final retry = UpdateCadence.retryAfterMiss(daily);
      expect(retry, lessThan(const Duration(days: 1)));
      expect(retry, greaterThanOrEqualTo(UpdateCadence.missRetryFloor));
    });

    test('never retries faster than the floor', () {
      // Otherwise a show that has genuinely stopped gets asked forever at
      // whatever tiny interval its last burst implied.
      final burst = [day(1), day(1, 21), day(1, 22)];
      expect(
        UpdateCadence.retryAfterMiss(burst),
        greaterThanOrEqualTo(UpdateCadence.missRetryFloor),
      );
    });

    test('an unknown schedule falls back to half the default', () {
      expect(
        UpdateCadence.retryAfterMiss(const []),
        greaterThanOrEqualTo(UpdateCadence.missRetryFloor),
      );
    });
  });

  // The user-facing estimate on the 追更 card. Stricter than the checker's
  // own schedule: it would rather say nothing than promise an episode the
  // data cannot back.
  group('nextUpdateEstimate', () {
    Subscription sub({
      List<DateTime> history = const [],
      DateTime? last,
      bool finished = false,
    }) => Subscription(
      sourceId: 'olevod',
      videoId: 1,
      title: '追的剧',
      updateHistory: history,
      lastUpdateAt: last,
      finished: finished,
    );

    test('a daily show expects the next episode a day after the last', () {
      final s = sub(history: [day(1), day(2), day(3)], last: day(3));
      expect(nextUpdateEstimate(s, day(3, 22)), day(4));
    });

    test('a finished show expects nothing', () {
      final s = sub(
        history: [day(1), day(2), day(3)],
        last: day(3),
        finished: true,
      );
      expect(nextUpdateEstimate(s, day(3, 22)), isNull);
    });

    test('fewer than two observations is no cadence at all', () {
      expect(nextUpdateEstimate(sub(history: [day(1)], last: day(1)), day(2)),
          isNull);
    });

    test('an estimate gone stale by more than a day says nothing', () {
      // A hiatus: repeating "today" every day until the show resumes would
      // be a promise, not an estimate.
      final s = sub(history: [day(1), day(2), day(3)], last: day(3));
      expect(nextUpdateEstimate(s, day(6)), isNull);
    });
  });
}
