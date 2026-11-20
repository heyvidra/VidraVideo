// What a fetch that went wrong may and may not do to what is already stored.

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vidra/src/data/database/app_database.dart' show AppDatabase;
import 'package:vidra/src/data/database/mappers.dart';
import 'package:vidra/src/features/favorites/data/favorites_repository.dart';
import 'package:vidra/src/features/video/data/history_repository.dart';
import 'package:vidra/src/features/video/domain/play_history.dart';
import 'package:vidra/src/features/video/domain/video_collection.dart';

Video _show(int id) => Video(
  apiId: id,
  sourceId: 'yfsp',
  sourceKey: 'key-$id',
  title: 'show $id',
  coverUrl: '',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppDatabase db;
  late HistoryRepository history;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    history = HistoryRepository(db, 'yfsp');
  });
  tearDown(() => db.close());

  Future<void> watch(int id) async {
    await db.into(db.videos).insert(_show(id).toCompanion());
    await history.saveVideoHistory(
      VideoHistory(
        id: 0,
        sourceId: 'yfsp',
        videoId: id,
        videoTitle: 'show $id',
        coverUrl: '',
        type: '剧集',
        lastEpisodeIndex: 0,
        updatedAt: DateTime.now(),
      ),
    );
  }

  Future<List<int>> cached() async =>
      (await db.select(db.videos).get()).map((v) => v.apiId).toList()..sort();

  test('removing a show from history keeps its cached row while it is '
      'still in 想看', () async {
    await watch(1);
    await watch(2);
    await FavoritesRepository(db).add(_show(1));

    for (final h in await history.getAllVideoHistory()) {
      await history.deleteVideoHistory(h.id);
    }
    // 1 is the only place its sourceKey lives; 2 nothing else needs.
    expect(await cached(), [1]);
  });

  test('clearing all history does the same', () async {
    await watch(1);
    await watch(2);
    await FavoritesRepository(db).add(_show(1));
    await history.clearAllHistory();
    expect(await cached(), [1]);
    expect(await history.getAllVideoHistory(), isEmpty);
  });
}
