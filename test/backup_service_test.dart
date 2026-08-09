// The property a panicking user needs from import: it cannot lose anything.
// Rows merge by business key, an existing row always wins, and running the
// same import twice adds nothing the second time.

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vidra/src/data/database/app_database.dart';
import 'package:vidra/src/features/settings/data/backup_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase source;
  late AppDatabase target;

  setUp(() {
    source = AppDatabase.forTesting(NativeDatabase.memory());
    target = AppDatabase.forTesting(NativeDatabase.memory());
  });
  tearDown(() async {
    await source.close();
    await target.close();
  });

  Future<void> seed(AppDatabase db) async {
    await db
        .into(db.videoHistory)
        .insert(
          VideoHistoryCompanion.insert(
            sourceId: const Value('olevod'),
            videoId: 83164,
            videoTitle: '九门',
            coverUrl: 'https://x/cover.jpg',
            type: '陆剧',
            lastEpisodeIndex: 20,
            updatedAt: DateTime(2026, 8, 9),
          ),
        );
    await db
        .into(db.episodeHistory)
        .insert(
          EpisodeHistoryCompanion.insert(
            sourceId: const Value('olevod'),
            videoId: 83164,
            episodeIndex: 20,
            positionMillis: 3000853,
            durationMillis: 3164019,
            updatedAt: DateTime(2026, 8, 9),
          ),
        );
    await db
        .into(db.subscriptions)
        .insert(
          SubscriptionsCompanion.insert(
            sourceId: 'olevod',
            videoId: 83164,
            title: '九门',
            createdAt: DateTime(2026, 8, 1),
          ),
        );
    await db
        .into(db.favorites)
        .insert(
          FavoritesCompanion.insert(
            sourceId: 'dbku',
            videoId: 7,
            title: '想看的剧',
            createdAt: DateTime(2026, 8, 5),
          ),
        );
  }

  test('a backup round-trips into an empty database', () async {
    await seed(source);
    final json = await BackupService(source).exportJson();

    final summary = await BackupService(target).importJson(json);
    expect(summary.added, 4);
    expect(summary.total, 4);

    final history = await target.select(target.videoHistory).get();
    expect(history.single.videoTitle, '九门');
    expect(history.single.lastEpisodeIndex, 20);
    final ep = await target.select(target.episodeHistory).get();
    expect(ep.single.positionMillis, 3000853);
    expect((await target.select(target.favorites).get()).single.title, '想看的剧');
  });

  test('importing the same backup twice adds nothing', () async {
    await seed(source);
    final json = await BackupService(source).exportJson();

    await BackupService(target).importJson(json);
    final again = await BackupService(target).importJson(json);
    expect(again.added, 0);
    expect(again.total, 4);
    expect(await target.select(target.videoHistory).get(), hasLength(1));
  });

  test('an existing row wins over the backup', () async {
    await seed(source);
    final json = await BackupService(source).exportJson();

    // The target already knows this show, further along than the backup.
    await target
        .into(target.videoHistory)
        .insert(
          VideoHistoryCompanion.insert(
            sourceId: const Value('olevod'),
            videoId: 83164,
            videoTitle: '九门',
            coverUrl: 'https://x/cover.jpg',
            type: '陆剧',
            lastEpisodeIndex: 25,
            updatedAt: DateTime(2026, 9, 1),
          ),
        );

    await BackupService(target).importJson(json);
    final row = (await target.select(target.videoHistory).get()).single;
    expect(row.lastEpisodeIndex, 25, reason: 'local progress must survive');
  });

  test('a file that is not a vidra backup is refused', () async {
    expect(
      () => BackupService(target).importJson('{"app":"other"}'),
      throwsFormatException,
    );
    expect(
      () => BackupService(target).importJson('not json at all'),
      throwsFormatException,
    );
  });
}
