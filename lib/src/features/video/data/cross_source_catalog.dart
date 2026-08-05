import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/database/app_database.dart' as db;
import '../../../data/database/app_database_provider.dart';
import '../domain/play_history.dart' show crossSourceKey;

final crossSourceCatalogProvider = Provider<CrossSourceCatalog>((ref) {
  return CrossSourceCatalog(ref.watch(appDatabaseProvider));
});

/// One show as it exists on another catalog.
class CrossSourceEntry {
  const CrossSourceEntry({
    required this.sourceId,
    required this.videoId,
    required this.title,
    this.year,
  });

  final String sourceId;

  /// The show's id ON THAT source. The catalogs share no id space, so this —
  /// not the id of the page the user is currently looking at — is the only
  /// thing "open this show on the other source" can navigate with.
  final int videoId;

  /// The title and year as THAT catalog spells them. They collapse to the same
  /// [crossSourceKey] as the show we searched for, but the raw strings can
  /// still differ in case and spacing, and the switcher shows what the source
  /// itself says rather than re-labelling it with our copy.
  final String title;
  final String? year;
}

/// Finds the same show on the catalogs the user is not currently looking at,
/// using only what browsing has already cached locally.
///
/// The pre-existing answer to "does this show exist elsewhere?" came from the
/// watch history ([HistoryRepository.getCrossSourceWatches]), which means a
/// counterpart was only discoverable after it had been PLAYED there. The
/// switcher therefore appeared on every detail page except the one the user
/// actually watched on — exactly backwards from what it is for. Reading the
/// `videos` table instead makes the counterpart visible from the first visit,
/// because every detail page the user opens leaves its row behind.
///
/// Deliberately local-only, and it must stay that way: the sources ban IPs
/// under request storms, so a lookup that fires on every detail page open can
/// never be allowed to become a network request. A show the user has never
/// browsed to on the other catalog simply does not appear, which is the
/// correct failure — silence, not a guess.
///
/// Matching is exact on [crossSourceKey], the same identity the watch-history
/// path uses: measured on this database, the titles present in both sources
/// agree character for character, years included. Fuzzy matching would buy
/// nothing and would let a switcher offer a show that is not the same show.
///
/// One coupling to watch history survives, and it is not this module's to fix:
/// `HistoryRepository.deleteVideoHistory` drops the `videos` row along with
/// the history row, and `clearAllHistory` empties the table outright. So
/// swiping a show out of "Recent" on olevod also removes the counterpart
/// button from the dbku page — the show is still on both catalogs, but the
/// only local evidence of it was thrown away. Reopening either detail page
/// restores it. Do not paper over that here by falling back to the history
/// table: that is the backwards behaviour this replaced.
class CrossSourceCatalog {
  CrossSourceCatalog(this._db);

  final db.AppDatabase _db;

  /// Counterparts of [title]+[year] on catalogs other than [excludeSourceId],
  /// newest-cached first, at most one per source.
  ///
  /// The key comparison happens in Dart rather than in SQL because
  /// [crossSourceKey] folds whitespace runs and case, which SQLite's `=` does
  /// not — pre-filtering on the raw title would drop the very rows (`第01集`
  /// spacing, differing capitalisation) this exists to catch. Only the four
  /// identity columns are read: a `videos` row carries the whole serialised
  /// episode list, and dragging that through a scan on every detail page open
  /// costs far more than the scan itself.
  ///
  /// Ordered by row id descending. The table has no cached-at timestamp, but
  /// the id is an insert counter that [VideoRepository.getVideo] deliberately
  /// preserves across refreshes, so descending id is "the source discovered
  /// most recently" and not "the source refreshed most recently".
  Future<List<CrossSourceEntry>> counterpartsOf({
    required String title,
    String? year,
    String? excludeSourceId,
  }) async {
    final wanted = crossSourceKey(title, year);
    final t = _db.videos;
    final rows =
        await (_db.selectOnly(t)
              ..addColumns([t.id, t.sourceId, t.apiId, t.title, t.year])
              ..orderBy([OrderingTerm.desc(t.id)]))
            .get();

    // Keyed by source. `videos_idx` makes (sourceId, apiId) unique, so the
    // duplicate this collapses is not a repeated cache write but one catalog
    // carrying the same show under two ids — a re-listing, which both sources
    // do. Two identical buttons for one catalog is a bug the user can see, and
    // the first one wins because the ordering below already put the most
    // recently cached id in front. Insertion order carries that through.
    final bySource = <String, CrossSourceEntry>{};
    for (final row in rows) {
      final sourceId = row.read(t.sourceId);
      // A null sourceId predates per-source rows and cannot be opened at all:
      // navigation needs a source to resolve the id against.
      if (sourceId == null || sourceId == excludeSourceId) continue;

      final rowTitle = row.read(t.title);
      if (rowTitle == null) continue;
      final rowYear = row.read(t.year);
      if (crossSourceKey(rowTitle, rowYear) != wanted) continue;

      final apiId = row.read(t.apiId);
      if (apiId == null) continue;

      bySource.putIfAbsent(
        sourceId,
        () => CrossSourceEntry(
          sourceId: sourceId,
          videoId: apiId,
          title: rowTitle,
          year: rowYear,
        ),
      );
    }
    return bySource.values.toList();
  }
}

/// Counterparts for one show, for the detail page's source switcher.
///
/// `sourceId` is the source of the show being displayed and is what gets
/// excluded — a page must never offer to switch to itself. It is nullable
/// because a video reached from search or from a link without `?sourceId=`
/// has none, and in that case every cached catalog is a legitimate offer.
///
/// autoDispose because the answer is only interesting while the detail page is
/// open, and it goes stale the moment the user browses the same show on the
/// other catalog. The record argument gives the family structural equality, so
/// re-entering the same show reuses the cached scan instead of repeating it.
final crossSourceCounterpartsProvider = FutureProvider.autoDispose
    .family<
      List<CrossSourceEntry>,
      ({String title, String? year, String? sourceId})
    >((ref, arg) async {
      return ref
          .watch(crossSourceCatalogProvider)
          .counterpartsOf(
            title: arg.title,
            year: arg.year,
            excludeSourceId: arg.sourceId,
          );
    });
