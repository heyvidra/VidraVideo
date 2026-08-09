// 想看 is a bookmark, not playback state: rows are (sourceId, videoId) with a
// card snapshot, and the same show saved twice must stay one row — the detail
// button toggles, so a double-tap that inserted two rows would need two more
// taps to undo.

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vidra/src/data/database/app_database.dart' show AppDatabase;
import 'package:vidra/src/features/favorites/data/favorites_repository.dart';
import 'package:vidra/src/features/video/domain/video_collection.dart';

Video show({
  required int id,
  String source = 'olevod',
  String title = '想看的剧',
}) => Video(
  apiId: id,
  sourceId: source,
  title: title,
  coverUrl: 'https://x/cover.jpg',
  rating: 8.4,
  type: '陆剧',
  region: '大陆',
  year: '2026',
  remarks: '更新至第 05 集',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late FavoritesRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = FavoritesRepository(db);
  });
  tearDown(() => db.close());

  test('a saved show comes back with the snapshot a card needs', () async {
    await repo.add(show(id: 1));
    final all = await repo.all();
    expect(all, hasLength(1));
    final v = all.single;
    expect(v.apiId, 1);
    expect(v.sourceId, 'olevod');
    expect(v.title, '想看的剧');
    expect(v.coverUrl, 'https://x/cover.jpg');
    expect(v.rating, 8.4);
    expect(v.type, '陆剧');
    expect(v.year, '2026');
    expect(v.remarks, '更新至第 05 集');
  });

  test('saving the same row twice stays one row', () async {
    await repo.add(show(id: 1));
    await repo.add(show(id: 1));
    expect(await repo.all(), hasLength(1));
  });

  test('the same show on another source is its own row', () async {
    await repo.add(show(id: 1, source: 'olevod'));
    await repo.add(show(id: 77, source: 'dbku'));
    expect(await repo.all(), hasLength(2));
  });

  test('remove deletes only the named row', () async {
    await repo.add(show(id: 1, source: 'olevod'));
    await repo.add(show(id: 77, source: 'dbku'));
    await repo.remove('olevod', 1);
    final left = await repo.all();
    expect(left, hasLength(1));
    expect(left.single.sourceId, 'dbku');
  });

  test('a show without a source is refused rather than half-saved', () async {
    await repo.add(
      const Video(apiId: 5, title: 'x', coverUrl: '', type: '陆剧'),
    );
    expect(await repo.all(), isEmpty);
  });

  test('newest saved first', () async {
    await repo.add(show(id: 1, title: '先存的'));
    await Future<void>.delayed(const Duration(milliseconds: 5));
    await repo.add(show(id: 2, title: '后存的'));
    final all = await repo.all();
    expect(all.first.title, '后存的');
  });
}
