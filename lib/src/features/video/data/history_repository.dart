import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/database/app_database.dart' as db;
import '../../../data/database/app_database_provider.dart';
import '../../../data/database/mappers.dart';
import '../domain/play_history.dart';
import 'video_repository.dart';

final historyRepositoryProvider = Provider<HistoryRepository>((ref) {
  return HistoryRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(activeDataSourceProvider).id,
  );
});

/// Play-history persistence, split out of VideoRepository so catalog
/// fetching and user history don't share one god-object.
class HistoryRepository {
  HistoryRepository(this._db, this._defaultSourceId);

  final db.AppDatabase _db;
  final String _defaultSourceId;

  // --- Video history (the "Recent" list) ---

  Future<List<VideoHistory>> getAllVideoHistory() async {
    final history =
        await (_db.select(_db.videoHistory)..orderBy([
              (t) => OrderingTerm(
                expression: t.updatedAt,
                mode: OrderingMode.desc,
              ),
            ]))
            .get();
    return history.map((h) => h.toDomain()).toList();
  }

  /// The recent list plus each row's position in the episode it stopped on.
  ///
  /// Two queries, not one per card: the grid renders a dozen at a time and a
  /// per-card round trip would be a dozen DB hits per frame.
  Future<List<RecentPlayback>> getRecentPlaybacks() async {
    final videos = await getAllVideoHistory();
    if (videos.isEmpty) return const [];

    final rows =
        await (_db.select(_db.episodeHistory)..where(
              (t) => t.videoId.isIn(videos.map((v) => v.videoId).toList()),
            ))
            .get();

    // videoId collides across sources, so the key has to carry sourceId.
    final byKey = {
      for (final r in rows)
        '${r.sourceId}|${r.videoId}|${r.episodeIndex}': r.toDomain(),
    };

    return videos
        .map(
          (v) => RecentPlayback(
            video: v,
            lastEpisode:
                byKey['${v.sourceId}|${v.videoId}|${v.lastEpisodeIndex}'],
          ),
        )
        .toList();
  }

  Future<VideoHistory?> getVideoHistory(int videoId, String? sourceId) async {
    final sid = sourceId ?? _defaultSourceId;
    final h =
        await (_db.select(
              _db.videoHistory,
            )..where((t) => t.sourceId.equals(sid) & t.videoId.equals(videoId)))
            .getSingleOrNull();
    return h?.toDomain();
  }

  Future<void> saveVideoHistory(VideoHistory history) async {
    // Normalize sourceId and preserve existing row id before saving
    final sid = history.sourceId ?? _defaultSourceId;
    final existing = await getVideoHistory(history.videoId, sid);
    final normalized = history.copyWith(sourceId: sid, id: existing?.id);

    await _db
        .into(_db.videoHistory)
        .insert(normalized.toCompanion(), mode: InsertMode.insertOrReplace);
  }

  /// Deletes the history row and all cached data tied to that video.
  Future<void> deleteVideoHistory(int id) async {
    final history = await (_db.select(
      _db.videoHistory,
    )..where((t) => t.id.equals(id))).getSingleOrNull();

    if (history == null) return;

    final videoId = history.videoId;
    final sourceId = history.sourceId;

    await _db.transaction(() async {
      await (_db.delete(_db.videoHistory)..where((t) => t.id.equals(id))).go();

      // Related rows are keyed by (sourceId, videoId); with a null sourceId
      // we can't identify them safely, so only the history row is removed.
      if (sourceId != null) {
        await (_db.delete(_db.videos)..where(
              (t) => t.sourceId.equals(sourceId) & t.apiId.equals(videoId),
            ))
            .go();

        await (_db.delete(_db.videoSettings)..where(
              (t) => t.sourceId.equals(sourceId) & t.videoId.equals(videoId),
            ))
            .go();

        await (_db.delete(_db.episodeHistory)..where(
              (t) => t.sourceId.equals(sourceId) & t.videoId.equals(videoId),
            ))
            .go();
      }
    });
  }

  // --- Episode history (per-episode playback position) ---

  Future<EpisodeHistory?> getEpisodeHistory(
    int videoId,
    int episodeIndex,
    String? sourceId,
  ) async {
    final sid = sourceId ?? _defaultSourceId;
    final h =
        await (_db.select(_db.episodeHistory)..where(
              (t) =>
                  t.sourceId.equals(sid) &
                  t.videoId.equals(videoId) &
                  t.episodeIndex.equals(episodeIndex),
            ))
            .getSingleOrNull();
    return h?.toDomain();
  }

  Future<List<EpisodeHistory>> getEpisodeHistories(
    int videoId,
    String? sourceId,
  ) async {
    final sid = sourceId ?? _defaultSourceId;
    final list = await (_db.select(
      _db.episodeHistory,
    )..where((t) => t.sourceId.equals(sid) & t.videoId.equals(videoId))).get();
    return list.map((h) => h.toDomain()).toList();
  }

  Future<void> saveEpisodeHistory(EpisodeHistory history) async {
    // Normalize sourceId and preserve existing row id before saving
    final sid = history.sourceId ?? _defaultSourceId;
    final existing = await getEpisodeHistory(
      history.videoId,
      history.episodeIndex,
      sid,
    );
    final normalized = history.copyWith(sourceId: sid, id: existing?.id);

    await _db
        .into(_db.episodeHistory)
        .insert(normalized.toCompanion(), mode: InsertMode.insertOrReplace);
  }

  // --- Cross-source watch state ---

  /// Every watched title, keyed by [crossSourceKey], with one entry per source.
  ///
  /// Deliberately NOT filtered by "the current source" here: which source is
  /// current is a property of the SCREEN, while the thing being annotated is a
  /// video that may come from a different one — arriving from search, or a link
  /// carrying ?sourceId=. Filtering on the wrong one showed a video its OWN
  /// progress labelled as another platform's.
  ///
  /// A list, not a single entry, because a show watched on both sources still
  /// has something to say about the one you are not looking at.
  ///
  /// The two catalogs share no ids, so a show is recognised by what it says
  /// about itself. Measured on this database: the titles present in both
  /// sources match CHARACTER FOR CHARACTER, years included, so this matches
  /// exactly rather than fuzzily. A false positive here labels a show you have
  /// never opened with somebody else's progress.
  ///
  /// Skip markers are deliberately NOT shared: the two sources are different
  /// encodes with different intros, and `episode_skip_data` stays per-source.
  Future<Map<String, List<CrossSourceWatch>>> getCrossSourceWatches() async {
    final rows = await _db.select(_db.videoHistory).get();
    final out = <String, List<CrossSourceWatch>>{};
    for (final r in rows) {
      final sid = r.sourceId;
      if (sid == null) continue;
      out
          .putIfAbsent(crossSourceKey(r.videoTitle, r.year), () => [])
          .add(
            CrossSourceWatch(
              sourceId: sid,
              lastEpisodeIndex: r.lastEpisodeIndex,
              lastEpisodeTitle: r.lastEpisodeTitle,
              updatedAt: r.updatedAt,
            ),
          );
    }
    return out;
  }

  // --- Episode skip data (intro/outro markers + the sweep hashes behind them)

  Future<List<db.EpisodeSkipDataData>> getEpisodeSkipData(
    int videoId,
    String? sourceId,
  ) async {
    final sid = sourceId ?? _defaultSourceId;
    return (_db.select(
      _db.episodeSkipData,
    )..where((t) => t.sourceId.equals(sid) & t.videoId.equals(videoId))).get();
  }

  /// Upsert ONLY the columns present in [values].
  ///
  /// Markers and hashes are written by different callers at different times —
  /// a whole-row replace would blank whichever one this write isn't carrying,
  /// so a completed sweep would erase the marker it had just produced.
  Future<void> saveEpisodeSkipData(
    int videoId,
    int episodeIndex,
    String? sourceId,
    db.EpisodeSkipDataCompanion values,
  ) async {
    final sid = sourceId ?? _defaultSourceId;
    final row = values.copyWith(
      videoId: Value(videoId),
      episodeIndex: Value(episodeIndex),
      sourceId: Value(sid),
    );
    await _db
        .into(_db.episodeSkipData)
        .insert(
          row,
          onConflict: DoUpdate(
            (_) => values, // set fields only; the rest stay as they are
            target: [
              _db.episodeSkipData.videoId,
              _db.episodeSkipData.episodeIndex,
              _db.episodeSkipData.sourceId,
            ],
          ),
        );
  }

  /// Clears all history and cached video data.
  Future<void> clearAllHistory() async {
    await _db.transaction(() async {
      await _db.delete(_db.videoHistory).go();
      await _db.delete(_db.episodeHistory).go();
      await _db.delete(_db.videos).go();
      await _db.delete(_db.videoSettings).go();
      await _db.delete(_db.episodeSkipData).go();
    });
  }
}
