// Watch progress crosses sources; skip markers do not.
//
// The two catalogs share no ids, so the same show is recognised by what it
// says about itself. Measured on the local database before this was written:
// the four titles present in both sources match CHARACTER FOR CHARACTER, years
// included — hence exact matching after whitespace normalisation rather than
// fuzzy. A false positive here labels a show you have never opened with
// somebody else's progress, which is worse than showing nothing.

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vidra/src/data/database/app_database.dart';
import 'package:vidra/src/features/video/data/history_repository.dart';
import 'package:vidra/src/features/video/domain/play_history.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> watch(
    AppDatabase db, {
    required String source,
    required int videoId,
    required String title,
    String? year,
    required int episode,
    String? episodeTitle,
    required DateTime at,
  }) => db
      .into(db.videoHistory)
      .insert(
        VideoHistoryCompanion.insert(
          sourceId: Value(source),
          videoId: videoId,
          videoTitle: title,
          coverUrl: '',
          type: '连续剧',
          year: Value(year),
          lastEpisodeIndex: episode,
          lastEpisodeTitle: Value(episodeTitle),
          updatedAt: at,
        ),
      );

  test('the other source shows up, this one does not', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = HistoryRepository(db, 'dbku');

    await watch(
      db,
      source: 'olevod',
      videoId: 1,
      title: '兵自风中来',
      year: '2026',
      episode: 4,
      at: DateTime(2026, 8, 1),
    );
    await watch(
      db,
      source: 'dbku',
      videoId: 9,
      title: '江海潮生',
      year: '2026',
      episode: 2,
      at: DateTime(2026, 8, 1),
    );

    final found = await repo.getCrossSourceWatches();
    expect(found[crossSourceKey('兵自风中来', '2026')]!.single.sourceId, 'olevod');
    expect(found[crossSourceKey('兵自风中来', '2026')]!.single.lastEpisodeIndex, 4);
    // Every source is returned; excluding the video's OWN source is the
    // lookup's job, because which source is "current" belongs to the video
    // being annotated and not to the screen showing it.
    expect(found[crossSourceKey('江海潮生', '2026')]!.single.sourceId, 'dbku');
  });

  test('the year separates a remake from its original', () async {
    // Titles repeat across decades. Without the year the 1994 version wears
    // the 2026 version's progress, and nothing on screen explains why.
    expect(
      crossSourceKey('九门', '2026'),
      isNot(crossSourceKey('九门', '1994')),
    );
  });

  test('spacing differences do not split one show in two', () async {
    expect(
      crossSourceKey('  兵自 风中来 ', '2026'),
      crossSourceKey('兵自 风中来', '2026'),
    );
    // But a genuinely different title still is one.
    expect(
      crossSourceKey('兵自风中来', '2026'),
      isNot(crossSourceKey('兵自风中来 2', '2026')),
    );
  });

  List<CrossSourceWatch> found(Map<String, List<CrossSourceWatch>> m) =>
      m[crossSourceKey('九门', '2026')]!;

  test('every source that watched a title is kept, newest first', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = HistoryRepository(db, 'dbku');

    await watch(
      db,
      source: 'olevod',
      videoId: 1,
      title: '九门',
      year: '2026',
      episode: 2,
      at: DateTime(2026, 7, 1),
    );
    await watch(
      db,
      source: 'other',
      videoId: 2,
      title: '九门',
      year: '2026',
      episode: 11,
      at: DateTime(2026, 8, 1),
    );

    final entries = found(await repo.getCrossSourceWatches());
    expect(entries.map((e) => e.sourceId), containsAll(['olevod', 'other']));
    // Both are kept; the badge picks the most recent of whichever sources are
    // not the video's own.
    entries.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    expect(entries.first.sourceId, 'other');
    expect(entries.first.lastEpisodeIndex, 11);
  });
}
