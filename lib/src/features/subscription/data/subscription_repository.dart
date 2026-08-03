import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/database/app_database.dart' as db;
import '../../../data/database/app_database_provider.dart';
import '../../video/domain/play_history.dart' show crossSourceKey;
import '../../video/domain/video_collection.dart';
import '../domain/subscription.dart';

final subscriptionRepositoryProvider = Provider<SubscriptionRepository>((ref) {
  return SubscriptionRepository(ref.watch(appDatabaseProvider));
});

/// Storage for followed shows, and the three ways a new episode gets noticed.
///
/// Ordered by cost, cheapest first, because the expensive one scales with the
/// number of subscriptions and the cheap ones do not:
///
///   1. [noticeFromListing] — free. Every catalog page the user scrolls past
///      carries each show's own progress line, so a followed show announces
///      its update with no request of ours.
///   2. [noticeFromRecent] — one request for ALL subscriptions. A single page
///      of "recently updated" intersected against the followed set.
///   3. [dueForDetailCheck] — one request per show, and only for shows the
///      learned cadence says are actually due.
///
/// Most updates are caught by 1 and 2. Tier 3 is the backstop for a show the
/// user never browses past, not the main path.
class SubscriptionRepository {
  SubscriptionRepository(this._db);

  final db.AppDatabase _db;

  // --- Reads ---

  Future<List<Subscription>> all() async {
    final rows = await (_db.select(
      _db.subscriptions,
    )..orderBy([(t) => OrderingTerm.desc(t.lastUpdateAt)])).get();
    return rows.map(_toDomain).toList();
  }

  Future<Subscription?> find(String sourceId, int videoId) async {
    final row =
        await (_db.select(_db.subscriptions)..where(
              (t) => t.sourceId.equals(sourceId) & t.videoId.equals(videoId),
            ))
            .getSingleOrNull();
    return row == null ? null : _toDomain(row);
  }

  Future<int> unreadCount() async {
    final rows = await (_db.select(
      _db.subscriptions,
    )..where((t) => t.unread.equals(true))).get();
    return rows.length;
  }

  // --- Writes ---

  Future<void> subscribe(Video video) async {
    final sourceId = video.sourceId;
    if (sourceId == null) return;
    await _db
        .into(_db.subscriptions)
        .insert(
          db.SubscriptionsCompanion.insert(
            sourceId: sourceId,
            videoId: video.apiId,
            title: video.title,
            year: Value(video.year?.toString()),
            coverUrl: Value(video.coverUrl),
            // Seeded with what the catalog says RIGHT NOW, so the first change
            // is an update rather than the baseline being mistaken for one.
            lastSeenRemarks: Value(video.remarks),
            finished: Value(looksFinished(video.remarks)),
            createdAt: DateTime.now(),
          ),
          mode: InsertMode.insertOrIgnore,
        );
  }

  Future<void> unsubscribe(String sourceId, int videoId) async {
    await (_db.delete(_db.subscriptions)..where(
          (t) => t.sourceId.equals(sourceId) & t.videoId.equals(videoId),
        ))
        .go();
  }

  Future<void> markRead(String sourceId, int videoId) async {
    await (_db.update(_db.subscriptions)..where(
          (t) => t.sourceId.equals(sourceId) & t.videoId.equals(videoId),
        ))
        .write(const db.SubscriptionsCompanion(unread: Value(false)));
  }

  Future<void> save(Subscription s) async {
    await (_db.update(_db.subscriptions)..where(
          (t) => t.sourceId.equals(s.sourceId) & t.videoId.equals(s.videoId),
        ))
        .write(
          db.SubscriptionsCompanion(
            lastSeenRemarks: Value(s.lastSeenRemarks),
            lastUpdateAt: Value(s.lastUpdateAt),
            updateHistory: Value(_encodeHistory(s.updateHistory)),
            nextCheckAt: Value(s.nextCheckAt),
            unread: Value(s.unread),
            finished: Value(s.finished),
            crossSeenSourceId: Value(s.crossSeenSourceId),
            crossSeenRemarks: Value(s.crossSeenRemarks),
          ),
        );
  }

  /// When the checker last ran, surviving restarts. Nullable: never ran.
  Future<DateTime?> loadLastCheckAt() async {
    final row = await _db.select(_db.appSettings).getSingleOrNull();
    return row?.subscriptionCheckedAt;
  }

  Future<void> saveLastCheckAt(DateTime at) async {
    final updated = await _db
        .update(_db.appSettings)
        .write(db.AppSettingsCompanion(subscriptionCheckedAt: Value(at)));
    if (updated == 0) {
      // A fresh install where nothing has written settings yet.
      await _db
          .into(_db.appSettings)
          .insert(db.AppSettingsCompanion(subscriptionCheckedAt: Value(at)));
    }
  }

  // --- Tier 1: free ---

  /// Reconcile followed shows against a catalog listing the app already had.
  ///
  /// Costs nothing: the caller is handing over videos it fetched for its own
  /// reasons. Returns the subscriptions that changed, so the caller can say so.
  Future<List<Subscription>> noticeFromListing(List<Video> videos) async {
    if (videos.isEmpty) return const [];
    final subs = await all();
    if (subs.isEmpty) return const [];

    final byKey = {for (final s in subs) '${s.sourceId}|${s.videoId}': s};
    // The cross-source index reuses the watch badge's identity: title + year,
    // exact. A show followed on one catalog is recognised when the OTHER
    // catalog lists it — often hours earlier.
    final byTitle = <String, List<Subscription>>{};
    for (final s in subs) {
      byTitle.putIfAbsent(crossSourceKey(s.title, s.year), () => []).add(s);
    }
    final changed = <Subscription>[];
    final now = DateTime.now();

    for (final v in videos) {
      final sub = byKey['${v.sourceId}|${v.apiId}'];
      if (sub != null &&
          v.remarks != null &&
          v.remarks != sub.lastSeenRemarks) {
        // Only a CHANGE counts. Re-seeing the same progress line is the
        // common case — every scroll past the show — and must cost nothing
        // and mean nothing.
        final updated = sub.withUpdate(v.remarks, now);
        await save(updated);
        changed.add(updated);
        continue;
      }

      // Cross-source: the same title on a DIFFERENT catalog moved.
      final siblings = byTitle[crossSourceKey(v.title, v.year?.toString())];
      if (siblings == null || v.remarks == null) continue;
      for (final other in siblings) {
        if (other.sourceId == v.sourceId) continue;
        if (v.remarks == other.crossSeenRemarks) continue;
        // First sighting is a baseline, not news — same seeding rule as the
        // subscription itself, or following a show would immediately
        // "update" with whatever the other catalog already had.
        final isSeed = other.crossSeenRemarks == null;
        final updated = other.copyWith(
          crossSeenSourceId: v.sourceId,
          crossSeenRemarks: v.remarks,
          unread: isSeed ? null : true,
        );
        await save(updated);
        if (!isSeed) changed.add(updated);
      }
    }
    return changed;
  }

  // --- Tier 3 selection ---

  /// Followed shows worth spending a request on now.
  ///
  /// The filter is the point: finished shows never qualify, and a show whose
  /// cadence says the next episode is days away is skipped even if the user
  /// opens the app twenty times today.
  Future<List<Subscription>> dueForDetailCheck(DateTime now) async {
    final subs = await all();
    return subs.where((s) => s.dueForCheck(now)).toList();
  }

  Subscription _toDomain(db.Subscription r) => Subscription(
    id: r.id,
    sourceId: r.sourceId,
    videoId: r.videoId,
    title: r.title,
    year: r.year,
    coverUrl: r.coverUrl,
    lastSeenRemarks: r.lastSeenRemarks,
    lastUpdateAt: r.lastUpdateAt,
    updateHistory: _decodeHistory(r.updateHistory),
    nextCheckAt: r.nextCheckAt,
    unread: r.unread,
    finished: r.finished,
    crossSeenSourceId: r.crossSeenSourceId,
    crossSeenRemarks: r.crossSeenRemarks,
  );

  static String _encodeHistory(List<DateTime> history) =>
      jsonEncode(history.map((d) => d.toIso8601String()).toList());

  /// Tolerant on purpose: a history that cannot be read costs an over-eager
  /// schedule, while throwing would take down the subscription list.
  static List<DateTime> _decodeHistory(String? raw) {
    if (raw == null || raw.isEmpty) return const [];
    try {
      final list = jsonDecode(raw) as List;
      return [for (final e in list) ?DateTime.tryParse('$e')];
    } catch (_) {
      return const [];
    }
  }
}
