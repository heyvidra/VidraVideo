import 'subscription.dart';

/// One row of the 追剧日历: shows expected on the same day.
///
/// [daysAway] counts calendar days from "today": 0 today, 1 tomorrow, 2-6 a
/// named weekday, 7 "next week or later" (a weekly show's estimate can land
/// past this week, and labelling next 周六 like this week's would be a lie).
/// Null is 待定 — the cadence has nothing defensible to say: still learning,
/// or the estimate went stale in a hiatus.
typedef CalendarDay = ({int? daysAway, List<Subscription> shows});

typedef UpdateCalendar = ({
  List<CalendarDay> days,
  List<Subscription> finished,
});

/// Which day a followed show belongs to, or null for 待定.
///
/// A show that ALREADY updated today outranks its own estimate: "今晚有的看"
/// is a fact, and the estimate now points at the NEXT episode. An estimate in
/// the past (late, within [nextUpdateEstimate]'s staleness window) also reads
/// as today — late means "any moment now", not "yesterday".
int? calendarDaysAway(Subscription s, DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  final last = s.lastUpdateAt;
  if (last != null &&
      !DateTime(last.year, last.month, last.day).isBefore(today)) {
    return 0;
  }
  final next = nextUpdateEstimate(s, now);
  if (next == null) return null;
  final days = DateTime(
    next.year,
    next.month,
    next.day,
  ).difference(today).inDays;
  if (days < 0) return 0;
  return days > 7 ? 7 : days;
}

/// Folds the followed list into the calendar: one entry per day that has
/// shows, soonest first, 待定 after the dated days. Finished shows are not
/// days at all and come back separately. Within a day, what is new leads —
/// the same rule the grid sorts by.
UpdateCalendar buildUpdateCalendar(List<Subscription> subs, DateTime now) {
  final byDay = <int, List<Subscription>>{};
  final undated = <Subscription>[];
  final finished = <Subscription>[];

  for (final s in subs) {
    if (s.finished) {
      finished.add(s);
    } else {
      final days = calendarDaysAway(s, now);
      (days == null ? undated : byDay.putIfAbsent(days, () => [])).add(s);
    }
  }

  int newFirst(Subscription a, Subscription b) {
    if (a.unread != b.unread) return a.unread ? -1 : 1;
    return a.title.compareTo(b.title);
  }

  undated.sort(newFirst);
  finished.sort(newFirst);
  for (final list in byDay.values) {
    list.sort(newFirst);
  }

  return (
    days: [
      for (final key in byDay.keys.toList()..sort())
        (daysAway: key, shows: byDay[key]!),
      if (undated.isNotEmpty) (daysAway: null, shows: undated),
    ],
    finished: finished,
  );
}
