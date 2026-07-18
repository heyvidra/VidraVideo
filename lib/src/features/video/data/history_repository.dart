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

  /// Clears all history and cached video data.
  Future<void> clearAllHistory() async {
    await _db.transaction(() async {
      await _db.delete(_db.videoHistory).go();
      await _db.delete(_db.episodeHistory).go();
      await _db.delete(_db.videos).go();
      await _db.delete(_db.videoSettings).go();
    });
  }
}
