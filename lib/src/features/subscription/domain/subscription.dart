/// Following a show: what was last seen, when it tends to update, and whether
/// it is worth spending a request on right now.
///
/// The whole design turns on that last question. Checking every followed show
/// on a timer is the obvious implementation and the wrong one — it scales with
/// the number of subscriptions, hits the source hardest for shows that have
/// finished airing, and buys nothing for a show that updates weekly. So the
/// cheap signals come first (see `SubscriptionRepository`) and a request is a
/// last resort, spent only when the show is actually due.
class Subscription {
  const Subscription({
    required this.sourceId,
    required this.videoId,
    required this.title,
    this.id,
    this.year,
    this.coverUrl,
    this.lastSeenRemarks,
    this.lastUpdateAt,
    this.updateHistory = const [],
    this.nextCheckAt,
    this.unread = false,
    this.finished = false,
    this.crossSeenSourceId,
    this.crossSeenRemarks,
  });

  final int? id;
  final String sourceId;
  final int videoId;
  final String title;
  final String? year;
  final String? coverUrl;

  /// The catalog's own progress line — "更新至第 05 集".
  ///
  /// This is the update signal, and it is free: every catalog listing carries
  /// it, so a show the user happens to scroll past reports its own progress
  /// with no request of ours. Comparing strings rather than parsing an episode
  /// number is deliberate — the wording varies by source and by show type, and
  /// any change at all is worth looking at.
  final String? lastSeenRemarks;

  final DateTime? lastUpdateAt;

  /// When updates were observed, oldest first. Capped — see [maxHistory].
  final List<DateTime> updateHistory;

  final DateTime? nextCheckAt;
  final bool unread;

  /// Finished airing: stop checking, forever. The cheapest request is the one
  /// never made, and a completed show cannot produce another episode.
  final bool finished;

  /// The same show's progress as last seen on ANOTHER source. Sources word
  /// their progress differently, so this never enters the same-source
  /// comparison — it has its own baseline and its own change test.
  final String? crossSeenSourceId;
  final String? crossSeenRemarks;

  /// Enough to estimate a cadence without hoarding. Five observations span a
  /// month of a weekly show; older ones describe a release schedule that no
  /// longer applies.
  static const maxHistory = 5;

  Subscription copyWith({
    int? id,
    String? lastSeenRemarks,
    DateTime? lastUpdateAt,
    List<DateTime>? updateHistory,
    DateTime? nextCheckAt,
    bool? unread,
    bool? finished,
    String? crossSeenSourceId,
    String? crossSeenRemarks,
  }) => Subscription(
    id: id ?? this.id,
    sourceId: sourceId,
    videoId: videoId,
    title: title,
    year: year,
    coverUrl: coverUrl,
    lastSeenRemarks: lastSeenRemarks ?? this.lastSeenRemarks,
    lastUpdateAt: lastUpdateAt ?? this.lastUpdateAt,
    updateHistory: updateHistory ?? this.updateHistory,
    nextCheckAt: nextCheckAt ?? this.nextCheckAt,
    unread: unread ?? this.unread,
    finished: finished ?? this.finished,
    crossSeenSourceId: crossSeenSourceId ?? this.crossSeenSourceId,
    crossSeenRemarks: crossSeenRemarks ?? this.crossSeenRemarks,
  );

  /// Record an observed update and re-plan the next check around it.
  Subscription withUpdate(String? remarks, DateTime at) {
    final history = [...updateHistory, at];
    final trimmed = history.length > maxHistory
        ? history.sublist(history.length - maxHistory)
        : history;
    return copyWith(
      lastSeenRemarks: remarks,
      lastUpdateAt: at,
      updateHistory: trimmed,
      nextCheckAt: UpdateCadence.nextExpected(trimmed),
      unread: true,
      finished: looksFinished(remarks),
    );
  }

  /// Worth spending a request on at [now].
  ///
  /// False for a finished show at any time, and false before the cadence says
  /// the next episode is plausible. A show with no history yet has no cadence,
  /// so it falls back to [UpdateCadence.unknownInterval] rather than being
  /// polled continuously.
  bool dueForCheck(DateTime now) {
    if (finished) return false;
    final next = nextCheckAt;
    if (next == null) return true;
    return !now.isBefore(next);
  }
}

/// Whether a catalog progress line says the show has stopped airing.
///
/// "全24集" and "完结" mean no more episodes; "更新至第 24 集" does not, even
/// though both mention 24. The distinction is the whole point — treating the
/// second as finished would silently stop following a show mid-run, and the
/// user would never learn why.
bool looksFinished(String? remarks) {
  if (remarks == null) return false;
  final text = remarks.trim();
  if (text.isEmpty) return false;
  if (text.contains('更新')) return false; // still airing, whatever follows
  return text.contains('完结') ||
      text.contains('完結') ||
      RegExp(r'^全\s*\d+\s*集').hasMatch(text) ||
      text.contains('已完成');
}

/// When the next episode is expected, or null when the cadence cannot say:
/// a finished show, fewer than two observed updates, or an estimate already
/// more than a day stale — a show on hiatus must not promise "today" every
/// day until it resumes.
///
/// This is the learned schedule surfaced to the USER; [Subscription.nextCheckAt]
/// is the same estimate biased early for the checker's own polling.
DateTime? nextUpdateEstimate(Subscription s, DateTime now) {
  if (s.finished) return null;
  final last = s.lastUpdateAt;
  final interval = UpdateCadence.estimateInterval(s.updateHistory);
  if (last == null || interval == null) return null;
  final next = last.add(interval);
  if (now.difference(next) > const Duration(days: 1)) return null;
  return next;
}

/// Infers when a show updates from when it has updated.
abstract final class UpdateCadence {
  /// Used before anything has been observed. Long enough not to hammer a
  /// source over a show we know nothing about, short enough that a daily
  /// drama is noticed the same day.
  static const unknownInterval = Duration(hours: 12);

  /// Checks are scheduled slightly BEFORE the estimate. A show that lands ten
  /// minutes early would otherwise wait a whole cycle, and the cost of being
  /// early is one request.
  static const slack = Duration(hours: 1);

  /// The show's typical gap between updates, or null with fewer than two
  /// observations (one observation is a point, not an interval).
  ///
  /// Median, not mean: a hiatus — a holiday, a broadcast pause — is a single
  /// enormous gap, and an average would let it drag every future estimate
  /// with it. The median ignores it, which is exactly right, because the
  /// schedule either resumes as it was or produces new observations that move
  /// the median honestly.
  static Duration? estimateInterval(List<DateTime> updates) {
    if (updates.length < 2) return null;
    final sorted = [...updates]..sort();
    final gaps = <int>[];
    for (var i = 1; i < sorted.length; i++) {
      final ms = sorted[i].difference(sorted[i - 1]).inMilliseconds;
      // Two sightings of one release — a list refresh minutes apart — are not
      // an interval. Counting them would collapse the estimate toward zero and
      // turn the schedule into a poll.
      if (ms > 0) gaps.add(ms);
    }
    if (gaps.isEmpty) return null;
    gaps.sort();
    final mid = gaps.length ~/ 2;
    final median = gaps.length.isOdd
        ? gaps[mid]
        : (gaps[mid - 1] + gaps[mid]) ~/ 2;
    return Duration(milliseconds: median);
  }

  /// How long to wait after a check that found nothing.
  ///
  /// Deliberately NOT the full interval. A show that missed its slot is
  /// usually late rather than gone, and waiting a whole cycle would skip the
  /// release it was late for. Deliberately not small either — a show that has
  /// genuinely stopped must not be re-asked every few minutes forever.
  ///
  /// Note what this does NOT do: a check that found nothing is not an update,
  /// so it never enters the history. Recording "we looked" alongside "it
  /// updated" would teach the estimator a schedule made of our own polling.
  static Duration retryAfterMiss(List<DateTime> updates) {
    final interval = estimateInterval(updates) ?? unknownInterval;
    final half = Duration(milliseconds: interval.inMilliseconds ~/ 2);
    return half < missRetryFloor ? missRetryFloor : half;
  }

  static const missRetryFloor = Duration(hours: 2);

  /// When to look again, given what has been seen.
  static DateTime nextExpected(List<DateTime> updates) {
    final last = updates.isEmpty ? DateTime.now() : ([...updates]..sort()).last;
    final interval = estimateInterval(updates) ?? unknownInterval;
    final next = last.add(interval).subtract(slack);
    // A cadence learned from bursts could put the next check in the past,
    // which would make the show due on every tick — the polling this design
    // exists to avoid. Never schedule closer than the unknown-case floor.
    final floor = last.add(unknownInterval).subtract(slack);
    return next.isBefore(floor) ? floor : next;
  }
}
