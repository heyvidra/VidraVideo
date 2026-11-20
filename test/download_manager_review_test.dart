// Four ways the download manager contradicted itself, found by review:
// one download deleting another's finished file because they shared a name,
// a re-queued episode being downloaded twice, a tap on a cancelled episode
// that said "added" and did nothing, and a retried episode that went on
// claiming to be remuxing.

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vidra/src/core/services/download_service.dart';
import 'package:vidra/src/core/services/segment_downloader.dart';
import 'package:vidra/src/data/database/app_database.dart' hide DownloadTask;
import 'package:vidra/src/features/download/data/download_manager.dart';
import 'package:vidra/src/features/download/domain/download_task.dart';
import 'package:vidra/src/features/settings/data/settings_repository.dart';

class _Fake extends DownloadService {
  _Fake({this.delay = const Duration(milliseconds: 20)}) : super(null);

  final Duration delay;
  int inFlight = 0;
  final attempts = <String, int>{};
  final names = <String, String>{};
  final failTimes = <String, int>{};

  /// When set, the next attempt reports the remux phase and then fails.
  bool remuxThenFail = false;

  @override
  Future<String?> downloadM3u8ToMp4({
    required String url,
    required String filename,
    String? formatId,
    DownloadProgressCallback? onProgress,
    bool Function()? shouldCancel,
  }) async {
    inFlight++;
    attempts.update(url, (v) => v + 1, ifAbsent: () => 1);
    names[url] = filename;
    try {
      if (remuxThenFail) {
        remuxThenFail = false;
        onProgress?.call(1, 100, 100, 'Remuxing');
        await Future<void>.delayed(delay);
        throw Exception('remux failed');
      }
      onProgress?.call(0.5, 50, 100, 'Downloading');
      await Future<void>.delayed(delay);
      final remaining = failTimes[url] ?? 0;
      if (remaining > 0) {
        failTimes[url] = remaining - 1;
        throw Exception('simulated failure');
      }
      return '/tmp/$filename.mp4';
    } finally {
      inFlight--;
    }
  }
}

Future<void> _until(bool Function() cond, {int timeoutMs = 4000}) async {
  final deadline = DateTime.now().add(Duration(milliseconds: timeoutMs));
  while (!cond()) {
    if (DateTime.now().isAfter(deadline)) fail('timed out');
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
}

void main() {
  late AppDatabase db;
  late SettingsRepository settings;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    settings = SettingsRepository(db);
  });
  tearDown(() => db.close());

  Future<DownloadManager> manager(
    _Fake fake, {
    int concurrency = 2,
    Duration retryDelay = const Duration(milliseconds: 5),
  }) async {
    final s = await settings.getSettings();
    s.maxConcurrentDownloads = concurrency;
    await settings.updateSettings(s);
    final m = DownloadManager(
      db,
      settings,
      downloadService: fake,
      retryDelay: retryDelay,
    );
    await m.initialize(startProcessing: true);
    return m;
  }

  bool allDone(DownloadManager m) =>
      m.allTasks.every((t) => t.status == DownloadStatus.completed);

  test('two shows with one title do not share a file', () async {
    final fake = _Fake();
    final m = await manager(fake);
    await m.addTask(
      videoId: 1,
      videoTitle: '西游记',
      episodes: [
        {'index': 0, 'title': '第1集', 'url': 'http://a/1.m3u8'},
      ],
    );
    await _until(() => allDone(m));
    // The remake, or the same show from the other catalog.
    await m.addTask(
      videoId: 2,
      videoTitle: '西游记',
      episodes: [
        {'index': 0, 'title': '第1集', 'url': 'http://b/1.m3u8'},
      ],
    );
    await _until(() => allDone(m));

    expect(fake.names['http://a/1.m3u8'], '西游记_第1集');
    expect(fake.names['http://b/1.m3u8'], isNot('西游记_第1集'));
    expect(
      m.allTasks.map((t) => t.episodes.single.outputPath).toSet(),
      hasLength(2),
    );
  });

  test('two lines of one episode do not share a file', () async {
    // 第12集 and 第12集(粤语) are given the same label by the detail page.
    final fake = _Fake();
    final m = await manager(fake);
    await m.addTask(
      videoId: 1,
      videoTitle: 'V',
      episodes: [
        {'index': 0, 'title': '第12集', 'url': 'http://x/12.m3u8'},
        {'index': 1, 'title': '第12集', 'url': 'http://x/12-yue.m3u8'},
      ],
    );
    await _until(() => allDone(m));
    expect(fake.names.values.toSet(), hasLength(2));
  });

  test('a name is the same on every attempt', () async {
    // A retry resumes from a checkpoint kept beside the output file.
    final fake = _Fake()..failTimes['http://b/1.m3u8'] = 1;
    final m = await manager(fake);
    await m.addTask(
      videoId: 1,
      videoTitle: 'T',
      episodes: [
        {'index': 0, 'title': 'E', 'url': 'http://a/1.m3u8'},
      ],
    );
    await _until(() => allDone(m));
    await m.addTask(
      videoId: 2,
      videoTitle: 'T',
      episodes: [
        {'index': 0, 'title': 'E', 'url': 'http://b/1.m3u8'},
      ],
    );
    await _until(() => fake.attempts['http://b/1.m3u8'] == 1);
    final first = fake.names['http://b/1.m3u8'];
    await _until(() => allDone(m));
    expect(fake.attempts['http://b/1.m3u8'], 2);
    expect(fake.names['http://b/1.m3u8'], first);
  });

  test('pause then resume during a retry backoff downloads once', () async {
    const url = 'http://x/0.m3u8';
    final fake = _Fake()..failTimes[url] = 1;
    final m = await manager(
      fake,
      retryDelay: const Duration(milliseconds: 150),
    );
    final id = await m.addTask(
      videoId: 1,
      videoTitle: 'V',
      episodes: [
        {'index': 0, 'title': 'E0', 'url': url},
      ],
    );
    // The first attempt has failed and the loop is sleeping before its retry.
    await _until(() => fake.attempts[url] == 1 && fake.inFlight == 0);
    await m.pauseTask(id);
    await m.resumeTask(id);

    await _until(() => allDone(m));
    await Future<void>.delayed(const Duration(milliseconds: 250));
    expect(
      fake.attempts[url],
      2,
      reason: 'the failed attempt and ONE successful one',
    );
  });

  test('asking again for a cancelled episode queues it again', () async {
    final fake = _Fake(delay: const Duration(milliseconds: 60));
    final m = await manager(fake, concurrency: 1);
    final episodes = [
      {'index': 0, 'title': 'E0', 'url': 'http://x/0.m3u8'},
      {'index': 1, 'title': 'E1', 'url': 'http://x/1.m3u8'},
    ];
    final id = await m.addTask(videoId: 1, videoTitle: 'V', episodes: episodes);
    await m.cancelTask(id);
    await _until(() => fake.inFlight == 0);
    expect(m.allTasks.single.status, DownloadStatus.cancelled);

    // The detail page's tile shows no badge now; the user taps it again.
    await m.addTask(videoId: 1, videoTitle: 'V', episodes: episodes);

    await _until(() => allDone(m));
    expect(m.allTasks, hasLength(1), reason: 'the same task, revived');
  });

  test('a retry after a failed remux is not still "remuxing"', () async {
    const url = 'http://x/0.m3u8';
    final fake = _Fake(delay: const Duration(milliseconds: 60))
      ..remuxThenFail = true;
    final m = await manager(fake);
    await m.addTask(
      videoId: 1,
      videoTitle: 'V',
      episodes: [
        {'index': 0, 'title': 'E0', 'url': url},
      ],
    );
    // Second attempt is under way and has reported bytes.
    await _until(() => fake.attempts[url] == 2 && fake.inFlight == 1);
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(m.allTasks.single.episodes.single.phase, isNull);
    await _until(() => allDone(m));
  });
}
