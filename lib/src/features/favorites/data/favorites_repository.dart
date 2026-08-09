import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/database/app_database.dart' as db;
import '../../../data/database/app_database_provider.dart';
import '../../video/domain/video_collection.dart';

final favoritesRepositoryProvider = Provider<FavoritesRepository>((ref) {
  return FavoritesRepository(ref.watch(appDatabaseProvider));
});

/// Storage for 想看 — shows saved to watch later.
///
/// Rows are (sourceId, videoId) bookmarks carrying the snapshot a poster card
/// needs, and they come back as [Video]s because that is all the grid and the
/// detail route want. Playback state stays in the history tables.
class FavoritesRepository {
  FavoritesRepository(this._db);

  final db.AppDatabase _db;

  Future<List<Video>> all() async {
    // id breaks createdAt ties: the column stores whole seconds, so two saves
    // in one second would otherwise come back in insertion order, oldest first.
    final rows =
        await (_db.select(_db.favorites)..orderBy([
              (t) => OrderingTerm.desc(t.createdAt),
              (t) => OrderingTerm.desc(t.id),
            ]))
            .get();
    return rows.map(_toVideo).toList();
  }

  Future<void> add(Video video) async {
    final sourceId = video.sourceId;
    if (sourceId == null) return;
    await _db
        .into(_db.favorites)
        .insert(
          db.FavoritesCompanion.insert(
            sourceId: sourceId,
            videoId: video.apiId,
            title: video.title,
            year: Value(video.year),
            coverUrl: Value(video.coverUrl),
            rating: Value(video.rating > 0 ? video.rating.toString() : null),
            type: Value(video.type),
            region: Value(video.region),
            remarks: Value(video.remarks),
            createdAt: DateTime.now(),
          ),
          mode: InsertMode.insertOrIgnore,
        );
  }

  Future<void> remove(String sourceId, int videoId) async {
    await (_db.delete(_db.favorites)..where(
          (t) => t.sourceId.equals(sourceId) & t.videoId.equals(videoId),
        ))
        .go();
  }

  Video _toVideo(db.Favorite r) => Video(
    sourceId: r.sourceId,
    apiId: r.videoId,
    title: r.title,
    coverUrl: r.coverUrl ?? '',
    rating: double.tryParse(r.rating ?? '') ?? 0.0,
    year: r.year,
    region: r.region,
    type: r.type,
    remarks: r.remarks,
  );
}
