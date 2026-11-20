// A download used to know its show only by a number, and the catalogs share
// no id space: the same number is a different show on each. So a second show
// was appended into the first one's task under its title and cover, its tiles
// wore the other's download badges, and pressing play in Downloads resolved
// the number on whichever catalog was active — and streamed that show.
//
// v20 records the source. These pin the three things that must hold: an
// install with downloads from before the column still opens and keeps them,
// two shows with one number are two tasks, and an old task with no recorded
// source is still found by — and adopts the source of — whoever asks next.

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vidra/src/core/services/download_service.dart';
import 'package:vidra/src/core/services/segment_downloader.dart';
import 'package:vidra/src/data/database/app_database.dart' hide DownloadTask;
import 'package:vidra/src/features/download/data/download_manager.dart';
import 'package:vidra/src/features/download/domain/download_task.dart';
import 'package:vidra/src/features/settings/data/settings_repository.dart';

class _Instant extends DownloadService {
  _Instant() : super(null);

  @override
  Future<String?> downloadM3u8ToMp4({
    required String url,
    required String filename,
    String? formatId,
    DownloadProgressCallback? onProgress,
    bool Function()? shouldCancel,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 5));
    return '/tmp/$filename.mp4';
  }
}

List<Map<String, dynamic>> _ep(String url) => [
  {'index': 0, 'title': 'E0', 'url': url},
];

Future<void> _until(bool Function() cond) async {
  final deadline = DateTime.now().add(const Duration(seconds: 4));
  while (!cond()) {
    if (DateTime.now().isAfter(deadline)) fail('timed out');
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<DownloadManager> managerOn(AppDatabase db) async {
    final m = DownloadManager(
      db,
      SettingsRepository(db),
      downloadService: _Instant(),
      retryDelay: const Duration(milliseconds: 5),
    );
    await m.initialize(startProcessing: true);
    return m;
  }

  bool allDone(DownloadManager m) =>
      m.allTasks.every((t) => t.status == DownloadStatus.completed);

  test('the v19 -> v20 climb keeps existing downloads', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    // Standing where a v19 install stands: a download row, no source column.
    await db.customStatement(
      'ALTER TABLE download_tasks DROP COLUMN source_id',
    );
    await db.customStatement(
      "INSERT INTO download_tasks (task_id, video_id, video_title, episodes, "
      "created_at) VALUES ('old', 4242, '旧下载', '[]', 0)",
    );

    await db.migration.onUpgrade(db.createMigrator(), 19, db.schemaVersion);

    final row = await db.select(db.downloadTasks).getSingle();
    expect(row.videoTitle, '旧下载');
    expect(row.sourceId, isNull);
    // And the manager loads it.
    final m = await managerOn(db);
    expect(m.allTasks.single.taskId, 'old');
  });

  test('one number on two catalogs is two downloads', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final m = await managerOn(db);

    final a = await m.addTask(
      videoId: 5,
      sourceId: 'dbku',
      videoTitle: '甲',
      episodes: _ep('http://dbku/0.m3u8'),
    );
    final b = await m.addTask(
      videoId: 5,
      sourceId: 'olevod',
      videoTitle: '乙',
      episodes: _ep('http://olevod/0.m3u8'),
    );

    expect(a, isNot(b));
    expect(m.allTasks.map((t) => t.videoTitle).toSet(), {'甲', '乙'});
    await _until(() => allDone(m));

    // And they are still two after a restart: the load-time merge of
    // duplicate rows must not fold them together.
    final reloaded = await managerOn(db);
    expect(reloaded.allTasks, hasLength(2));
    expect(
      reloaded.allTasks.firstWhere((t) => t.sourceId == 'dbku').videoTitle,
      '甲',
    );
  });

  test(
    'a task from before sources were recorded is found, and adopts one',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final m = await managerOn(db);
      // What every existing download looks like after the upgrade.
      final old = await m.addTask(
        videoId: 9,
        videoTitle: '老任务',
        episodes: _ep('http://x/0.m3u8'),
      );
      await _until(() => allDone(m));

      final again = await m.addTask(
        videoId: 9,
        sourceId: 'dbku',
        videoTitle: '老任务',
        episodes: [
          {'index': 1, 'title': 'E1', 'url': 'http://x/1.m3u8'},
        ],
      );

      expect(again, old, reason: 'not a second, empty task for the same show');
      expect(m.allTasks.single.episodes, hasLength(2));
      expect(m.allTasks.single.sourceId, 'dbku');
      await _until(() => allDone(m));
      final row = await db.select(db.downloadTasks).getSingle();
      expect(row.sourceId, 'dbku', reason: 'and it is persisted');
    },
  );

  test('isFor: an unknown source matches, two known ones must agree', () {
    DownloadTask t(String? source) => DownloadTask(
      videoId: 5,
      sourceId: source,
      videoTitle: 't',
      episodes: const [],
      createdAt: DateTime(2026),
    );
    expect(t(null).isFor(5, 'dbku'), isTrue);
    expect(t('dbku').isFor(5, null), isTrue);
    expect(t('dbku').isFor(5, 'dbku'), isTrue);
    expect(t('dbku').isFor(5, 'olevod'), isFalse);
    expect(t('dbku').isFor(6, 'dbku'), isFalse);
  });
}
