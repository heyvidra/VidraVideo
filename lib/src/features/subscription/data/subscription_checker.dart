import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/log.dart';
import '../../video/data/video_repository.dart';
import '../../video/domain/video_collection.dart';
import '../domain/subscription.dart';
import 'subscription_repository.dart';

/// Which listing carries "recently updated" on each source. Probed live
/// (2026-08-03), not assumed:
///
/// - olevod: categoryId 0 — a hidden "all" listing, 47/47 items carrying
///   vodTime in strictly descending order. Its DECLARED first category is 短剧,
///   whose listing only shows 短剧 — a followed drama would never appear there,
///   which is why "just use the first category" is wrong for the sweep.
/// - dbku: has no category 0 (404). Its 连续剧 listing (id 2) carries full
///   progress remarks ("更新至26集") for every row.
///
/// A source missing here falls back to its first declared category — possibly
/// blind to some subscriptions, but never an error.
const _recentCategoryBySource = {'olevod': 0, 'dbku': 2};

final subscriptionCheckerProvider = Provider<SubscriptionChecker>((ref) {
  final videos = ref.watch(videoRepositoryProvider);
  final sources = ref.watch(availableDataSourcesProvider);
  final subscriptionRepo = ref.watch(subscriptionRepositoryProvider);
  return SubscriptionChecker(
    subscriptions: subscriptionRepo,
    // Function seams rather than the repository itself: the checker needs two
    // calls out of a class that owns the network, and a test needs to script
    // exactly those two without standing up a data source.
    //
    // One page per source THAT HAS subscriptions — not per subscription, and
    // not only the active source, which would leave the other catalog's
    // followed shows invisible to the sweep.
    fetchRecent: () async {
      final subs = await subscriptionRepo.all();
      final wanted = subs
          .where((s) => !s.finished)
          .map((s) => s.sourceId)
          .toSet();
      final out = <Video>[];
      for (final ds in sources.where((d) => wanted.contains(d.id))) {
        try {
          final categoryId =
              _recentCategoryBySource[ds.id] ??
              (await ds.getCategories()).first.id;
          final page = await ds.fetchVideos(categoryId: categoryId);
          out.addAll(page.list);
        } catch (e) {
          logR('Subscription', 'recent sweep on ${ds.id} failed: $e');
        }
      }
      return out;
    },
    fetchDetail: (sub) => videos.getVideo(sub.videoId, sourceId: sub.sourceId),
  );
});

/// Tiers 2 and 3 of update detection: the part that actually spends requests.
///
/// Tier 1 (browsing) catches most updates for free, but only for shows the
/// user happens to scroll past. This covers the rest — and it is deliberately
/// stingy, because it is the only part whose cost grows with the number of
/// subscriptions.
class SubscriptionChecker {
  SubscriptionChecker({
    required this.subscriptions,
    required this.fetchRecent,
    required this.fetchDetail,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final SubscriptionRepository subscriptions;

  /// One page of the catalog, newest-updated first — the tier-2 sweep.
  final Future<List<Video>> Function() fetchRecent;

  /// One show's current detail — the tier-3 backstop.
  final Future<Video?> Function(Subscription sub) fetchDetail;

  /// Injectable so tests can move time instead of sleeping through it.
  final DateTime Function() _clock;

  /// Detail requests per run.
  ///
  /// A viewer following thirty shows must not produce thirty simultaneous
  /// requests the moment the app opens. Whatever is left over is still due on
  /// the next run minutes later, so the only cost of the cap is latency on a
  /// show nobody is watching for right now.
  static const maxDetailChecksPerRun = 5;

  /// Nothing runs more often than this, however often it is asked to.
  ///
  /// The app calls [run] on launch and on a foreground timer, and window
  /// activation can fire several of those in a row. Without a floor, a user
  /// alt-tabbing would each time trigger a sweep.
  static const minRunInterval = Duration(minutes: 20);

  /// Loaded from storage on first use, then kept in step with it. In-memory
  /// only, this floor reset on every relaunch — and relaunching is the one
  /// thing desktop users do constantly.
  DateTime? _lastRun;
  bool _lastRunLoaded = false;
  bool _running = false;

  /// One pass: a single listing for everyone, then detail checks for the few
  /// shows that are actually due.
  ///
  /// Returns the subscriptions found to have updated, so the caller can
  /// announce them by name in a single notification.
  Future<List<Subscription>> run({bool force = false}) async {
    if (_running) return const [];
    if (!_lastRunLoaded) {
      _lastRun = await subscriptions.loadLastCheckAt();
      _lastRunLoaded = true;
    }
    final last = _lastRun;
    if (!force && last != null && _clock().difference(last) < minRunInterval) {
      return const [];
    }
    _running = true;
    _lastRun = _clock();
    await subscriptions.saveLastCheckAt(_lastRun!);
    try {
      return [...await _sweepRecent(), ...await _checkDue()];
    } finally {
      _running = false;
    }
  }

  /// Tier 2 — one request covering every subscription at once.
  ///
  /// The catalog's first page is ordered newest-updated-first by every source
  /// here, so a show that gained an episode today is almost certainly on it.
  /// One request answers for the whole followed set, which is why this runs
  /// before the per-show checks and usually makes them unnecessary.
  Future<List<Subscription>> _sweepRecent() async {
    try {
      final list = await fetchRecent();
      if (list.isEmpty) return const [];
      final changed = await subscriptions.noticeFromListing(list);
      if (changed.isNotEmpty) {
        logR('Subscription', 'recent sweep: ${changed.length} updated');
      }
      return changed;
    } catch (e) {
      // A failed sweep is not an error the user needs: tier 1 and tier 3 both
      // still apply, and the next run is minutes away.
      logR('Subscription', 'recent sweep failed: $e');
      return const [];
    }
  }

  /// Tier 3 — one request per show, for shows the cadence says are due.
  Future<List<Subscription>> _checkDue() async {
    final due = await subscriptions.dueForDetailCheck(_clock());
    if (due.isEmpty) return const [];

    final found = <Subscription>[];
    // Sequential on purpose. These are background requests competing with
    // whatever the user is doing, and a burst is exactly what a source
    // notices.
    for (final sub in due.take(maxDetailChecksPerRun)) {
      try {
        final video = await fetchDetail(sub);
        final remarks = video?.remarks;
        if (remarks != null && remarks != sub.lastSeenRemarks) {
          final updated = sub.withUpdate(remarks, _clock());
          await subscriptions.save(updated);
          found.add(updated);
        } else {
          // Nothing new, but the question WAS asked — so push the next check
          // out. Leaving it due would ask again on the very next run, which is
          // the polling this design exists to avoid.
          //
          // The history is NOT touched: a check that found nothing is not an
          // update, and feeding it in would teach the estimator a rhythm made
          // of our own polling rather than the show's releases.
          await subscriptions.save(
            sub.copyWith(
              nextCheckAt: _clock().add(
                UpdateCadence.retryAfterMiss(sub.updateHistory),
              ),
            ),
          );
        }
      } catch (e) {
        logR('Subscription', 'check failed for ${sub.title}: $e');
      }
    }
    if (found.isNotEmpty) {
      logR('Subscription', 'due checks: ${found.length} updated');
    }
    return found;
  }
}
