// Scheduler + state-machine tests for DownloadManager's global episode pool.
//
// Guards the fixes for: "set concurrency N, only 1 downloads", pause not
// stopping queued episodes, auto-retry of transient failures, per-task retry,
// and deleteEpisode corrupting a concurrently-downloading sibling (URL-keyed
// in-flight tracking). Pure DownloadTask.status ladder cases live at the bottom.
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vidra/src/core/services/download_service.dart';
import 'package:vidra/src/core/services/segment_downloader.dart';
import 'package:vidra/src/data/database/app_database.dart' hide DownloadTask;
import 'package:vidra/src/features/download/data/download_manager.dart';
import 'package:vidra/src/features/download/domain/download_task.dart';
import 'package:vidra/src/features/settings/data/settings_repository.dart';

/// Fake downloader: records concurrency, consumes a per-URL failure budget
/// (for retry tests), never touches the network. Holds each call for
/// [downloadDelay] so the pool visibly fills / a delete can race it.
class _FakeDownloadService extends DownloadService {
  _FakeDownloadService({this.downloadDelay = const Duration(milliseconds: 20)})
    : super(null);

  final Duration downloadDelay;
  int inFlight = 0;
  int maxInFlight = 0;
  int completed = 0;
  final Map<String, int> attempts = {};

  /// url -> number of remaining attempts that should throw before succeeding.
  final Map<String, int> failTimes = {};

  @override
  Future<String?> downloadM3u8ToMp4({
    required String url,
    required String filename,
    String? formatId,
    DownloadProgressCallback? onProgress,
    bool Function()? shouldCancel,
  }) async {
    inFlight++;
    if (inFlight > maxInFlight) maxInFlight = inFlight;
    attempts.update(url, (v) => v + 1, ifAbsent: () => 1);
    await Future<void>.delayed(downloadDelay);
    inFlight--;
    final remaining = failTimes[url] ?? 0;
    if (remaining > 0) {
      failTimes[url] = remaining - 1;
      throw Exception('simulated failure ($remaining left)');
    }
    completed++;
    return '/tmp/$filename.mp4';
  }
}

List<Map<String, dynamic>> _episodes(int n) => List.generate(
  n,
  (i) => {'index': i, 'title': 'E$i', 'url': 'http://x/$i.m3u8'},
);

Future<void> _waitUntil(bool Function() cond, {int timeoutMs = 4000}) async {
  final deadline = DateTime.now().add(Duration(milliseconds: timeoutMs));
  while (!cond()) {
    if (DateTime.now().isAfter(deadline)) fail('timed out waiting for condition');
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
}

void main() {
  group('scheduler', () {
    late AppDatabase db;
    late SettingsRepository settings;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      settings = SettingsRepository(db);
    });
    tearDown(() async => db.close());

    Future<DownloadManager> makeManager(
      _FakeDownloadService fake, {
      required int concurrency,
    }) async {
      final s = await settings.getSettings();
      s.maxConcurrentDownloads = concurrency;
      await settings.updateSettings(s);
      final m = DownloadManager(
        db,
        settings,
        downloadService: fake,
        retryDelay: const Duration(milliseconds: 5),
      );
      await m.initialize(startProcessing: true);
      return m;
    }

    test('one task runs up to N episodes concurrently and all finish', () async {
      final fake = _FakeDownloadService();
      final m = await makeManager(fake, concurrency: 3);

      await m.addTask(videoId: 1, videoTitle: 'V', episodes: _episodes(6));
      expect(fake.inFlight, 3, reason: 'exactly the cap should be in flight');

      await _waitUntil(() => fake.completed == 6);
      expect(fake.maxInFlight, 3, reason: 'never exceeds the concurrency cap');
      expect(m.allTasks.single.status, DownloadStatus.completed);
    });

    test('pause stops still-queued episodes, not just the downloading one',
        () async {
      final fake = _FakeDownloadService();
      final m = await makeManager(fake, concurrency: 2);

      final id =
          await m.addTask(videoId: 1, videoTitle: 'V', episodes: _episodes(6));
      expect(fake.inFlight, 2);

      await m.pauseTask(id);
      final task = m.allTasks.single;
      expect(
        task.episodes.any((e) => e.status == DownloadStatus.queued),
        isFalse,
        reason: 'queued episodes must be paused too',
      );
      expect(task.status, DownloadStatus.paused);
    });

    test('a transient failure auto-retries and completes without user action',
        () async {
      final fake = _FakeDownloadService();
      fake.failTimes['http://x/0.m3u8'] = 1; // fail once, then succeed
      final m = await makeManager(fake, concurrency: 3);

      await m.addTask(videoId: 1, videoTitle: 'V', episodes: _episodes(6));

      await _waitUntil(() => fake.completed == 6);
      expect(fake.attempts['http://x/0.m3u8'], 2, reason: 'one retry happened');
      expect(m.allTasks.single.status, DownloadStatus.completed);
    });

    test('a persistent failure ends as failed, then per-task retry recovers it',
        () async {
      final fake = _FakeDownloadService();
      fake.failTimes['http://x/0.m3u8'] = 3; // exhaust all auto-retry attempts
      final m = await makeManager(fake, concurrency: 3);

      final id =
          await m.addTask(videoId: 1, videoTitle: 'V', episodes: _episodes(6));

      await _waitUntil(() => m.allTasks.single.status == DownloadStatus.failed);
      expect(fake.attempts['http://x/0.m3u8'], 3, reason: 'tried 3 times');

      await m.resumeTask(id); // failTimes now 0 → this attempt succeeds
      await _waitUntil(() => m.allTasks.single.status == DownloadStatus.completed);
      expect(fake.completed, 6);
    });

    test('failures retry up to the cap (retries resume from checkpoint)',
        () async {
      // With SDK-level HLS resume a retry continues from the on-disk checkpoint
      // instead of restarting, so there's no "don't retry a near-complete
      // download" gate — failures retry up to _maxAttempts (3), then fail.
      final fake = _FakeDownloadService();
      fake.failTimes['http://x/0.m3u8'] = 99; // fail every attempt
      final m = await makeManager(fake, concurrency: 3);

      await m.addTask(videoId: 1, videoTitle: 'V', episodes: _episodes(6));
      await _waitUntil(
        () => m.allTasks.single.episodes[0].status == DownloadStatus.failed,
      );
      expect(fake.attempts['http://x/0.m3u8'], 3, reason: 'retried up to the cap');
    });

    test('deleting an earlier episode mid-download does not strand its siblings',
        () async {
      // URL-keyed tracking: after removeAt(0) shifts indices, in-flight
      // downloads must still resolve to the right episode by URL.
      final fake =
          _FakeDownloadService(downloadDelay: const Duration(milliseconds: 150));
      final m = await makeManager(fake, concurrency: 2);

      final id =
          await m.addTask(videoId: 1, videoTitle: 'V', episodes: _episodes(3));
      expect(fake.inFlight, 2); // ep0, ep1 downloading; ep2 queued

      await m.deleteEpisode(id, 0); // delete ep0 while ep1 is mid-download

      // ep1 (now index 0) and ep2 must both finish; task completes with 2 eps.
      await _waitUntil(() => m.allTasks.single.status == DownloadStatus.completed);
      final task = m.allTasks.single;
      expect(task.episodes.length, 2);
      expect(
        task.episodes.every((e) => e.status == DownloadStatus.completed),
        isTrue,
        reason: 'no surviving episode may be stranded in downloading',
      );
    });

    test('a deleted task does not resurrect after reload (DB row removed)',
        () async {
      final fake = _FakeDownloadService();
      final m1 = await makeManager(fake, concurrency: 3);
      final id =
          await m1.addTask(videoId: 1, videoTitle: 'V', episodes: _episodes(2));
      await _waitUntil(
        () => m1.allTasks.single.status == DownloadStatus.completed,
      );

      await m1.deleteTask(id);
      expect(m1.allTasks, isEmpty);

      // A fresh manager loading from the SAME DB must not resurrect it —
      // proves the row was actually deleted (not just dropped from memory).
      final m2 = DownloadManager(
        db,
        settings,
        downloadService: fake,
        retryDelay: const Duration(milliseconds: 5),
      );
      await m2.initialize(startProcessing: false);
      expect(
        m2.allTasks,
        isEmpty,
        reason: 'deleted task must stay deleted in the DB',
      );
      m2.dispose();
    });

    test('load consolidates duplicate rows for the same video into one task',
        () async {
      // Simulate the old-bug aftermath: two DB rows for the same videoId.
      EpisodeDownloadInfo ep(int i, String t) => EpisodeDownloadInfo(
        index: i,
        title: t,
        url: 'http://x/$i.m3u8',
        status: DownloadStatus.completed,
        outputPath: '/tmp/$i.mp4',
      );
      await db.into(db.downloadTasks).insert(
        DownloadTasksCompanion.insert(
          taskId: 'A',
          videoId: 99,
          videoTitle: '问心2',
          episodes: [ep(32, '第33集'), ep(33, '第34集')],
          createdAt: DateTime(2026, 1, 1),
        ),
      );
      await db.into(db.downloadTasks).insert(
        DownloadTasksCompanion.insert(
          taskId: 'B',
          videoId: 99, // same show
          videoTitle: '问心2',
          episodes: [ep(32, '第33集')], // duplicate episode
          createdAt: DateTime(2026, 1, 2),
        ),
      );

      final m = DownloadManager(
        db,
        settings,
        downloadService: _FakeDownloadService(),
      );
      await m.initialize(startProcessing: false);

      expect(m.allTasks.length, 1, reason: 'same show → one task');
      expect(
        m.allTasks.single.episodes.length,
        2,
        reason: 'episodes merged + deduped by url',
      );
      final rowCount = (await db.select(db.downloadTasks).get()).length;
      expect(rowCount, 1, reason: 'duplicate DB row must be removed');
      m.dispose();
    });
  });

  group('DownloadTask.status ladder', () {
    DownloadTask task(List<DownloadStatus> statuses) => DownloadTask(
      videoId: 1,
      videoTitle: 'V',
      createdAt: DateTime(2026),
      episodes: [
        for (final s in statuses) EpisodeDownloadInfo(url: 'u', status: s),
      ],
    );

    test('paused outranks a failed episode', () {
      expect(
        task([
          DownloadStatus.paused,
          DownloadStatus.failed,
          DownloadStatus.completed,
        ]).status,
        DownloadStatus.paused,
      );
    });

    test('queued (work pending) outranks failed', () {
      expect(
        task([DownloadStatus.queued, DownloadStatus.failed]).status,
        DownloadStatus.queued,
      );
    });

    test('completed + cancelled mix reads as completed (not stuck queued)', () {
      expect(
        task([DownloadStatus.completed, DownloadStatus.cancelled]).status,
        DownloadStatus.completed,
      );
    });

    test('all cancelled reads as cancelled', () {
      expect(
        task([DownloadStatus.cancelled, DownloadStatus.cancelled]).status,
        DownloadStatus.cancelled,
      );
    });

    test('failed with nothing pending reads as failed', () {
      expect(
        task([DownloadStatus.failed, DownloadStatus.completed]).status,
        DownloadStatus.failed,
      );
    });
  });
}
