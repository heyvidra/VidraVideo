// The 追剧日历 folds followed shows by expected day. Its one hard rule:
// never promise a day the cadence cannot back — a show it cannot place goes
// to 待定, and a show that already dropped today is 今天 regardless of what
// the estimate says about the NEXT episode.

import 'package:flutter_test/flutter_test.dart';
import 'package:vidra/src/features/subscription/domain/subscription.dart';
import 'package:vidra/src/features/subscription/domain/update_calendar.dart';

DateTime day(int d, [int hour = 20]) => DateTime(2026, 8, d, hour);

Subscription sub(
  String title, {
  List<DateTime> history = const [],
  DateTime? last,
  bool finished = false,
  bool unread = false,
}) => Subscription(
  sourceId: 'olevod',
  videoId: title.hashCode,
  title: title,
  updateHistory: history,
  lastUpdateAt: last,
  finished: finished,
  unread: unread,
);

void main() {
  final now = day(9, 12); // 2026-08-09 noon

  test('updated today is 今天, even though the estimate points at tomorrow',
      () {
    final s = sub('日更剧', history: [day(7), day(8), day(9, 10)], last: day(9, 10));
    expect(calendarDaysAway(s, now), 0);
  });

  test('a daily show last seen yesterday is expected today', () {
    final s = sub('日更剧', history: [day(6), day(7), day(8)], last: day(8));
    expect(calendarDaysAway(s, now), 0);
  });

  test('a weekly show maps to its weekday slot', () {
    final s = sub('周更剧', history: [day(1, 20), day(8, 20)], last: day(8, 20));
    // Interval 7 days from 08-08 → expected 08-15, six days out.
    expect(calendarDaysAway(s, now), 6);
  });

  test('no cadence is 待定, not a guess', () {
    expect(calendarDaysAway(sub('新追的', last: day(8)), now), isNull);
  });

  test('the calendar folds days in order and splits finished off', () {
    final cal = buildUpdateCalendar([
      sub('完结剧', finished: true),
      sub('周更剧', history: [day(1, 20), day(8, 20)], last: day(8, 20)),
      sub('日更剧', history: [day(7), day(8)], last: day(8)),
      sub('新追的', last: day(8)),
    ], now);

    expect(cal.days.map((d) => d.daysAway).toList(), [0, 6, null]);
    expect(cal.days.first.shows.single.title, '日更剧');
    expect(cal.days.last.shows.single.title, '新追的');
    expect(cal.finished.single.title, '完结剧');
  });

  test('within a day the unread show leads', () {
    final cal = buildUpdateCalendar([
      sub('乙', history: [day(7), day(8)], last: day(8)),
      sub('甲', history: [day(7), day(8)], last: day(8), unread: true),
    ], now);
    expect(cal.days.single.shows.first.title, '甲');
  });

  test('an estimate past this week is 下周及以后, not a fake weekday', () {
    // Updates 10 days apart: expected 08-18, nine days out → bucket 7.
    final slow = sub(
      '慢更剧',
      history: [DateTime(2026, 7, 29, 20), day(8, 20)],
      last: day(8, 20),
    );
    expect(calendarDaysAway(slow, now), 7);
  });
}
