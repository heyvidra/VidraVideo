import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vidra/src/core/services/download_service.dart';
import 'package:vidra/src/core/services/m3u8_downloader.dart';
import 'package:vidra/src/features/download/data/download_manager.dart';
import 'package:vidra/src/features/download/domain/download_task.dart';

void main() {
  test('a resumed episode reports the speed of this run, not of all time', () {
    DownloadTask task(int atStart) => DownloadTask(
      taskId: 't',
      videoId: 1,
      videoTitle: 'T',
      createdAt: DateTime.now(),
      episodes: [
        EpisodeDownloadInfo(
          url: 'u',
          status: DownloadStatus.downloading,
          bytesDownloaded: 600 << 20,
          bytesAtStart: atStart,
          startTime: DateTime.now().subtract(const Duration(seconds: 10)),
        ),
      ],
    );
    // 10 MB moved in 10s since the resume → about 1 MB/s, not 60.
    expect(task(590 << 20).downloadSpeed, closeTo(1 << 20, 1 << 18));
    // Checkpoint gone, download began again from zero and passed nothing yet.
    expect(task(700 << 20).downloadSpeed, closeTo(60 << 20, 8 << 20));
  });

  test('file names are capped in bytes, on a character boundary', () {
    final long = '字' * 120; // 360 bytes
    final capped = DownloadManager.capFileName(long);
    expect(utf8.encode(capped).length, 198);
    expect(capped, '字' * 66);
    expect(DownloadManager.capFileName('short_第1集'), 'short_第1集');
  });

  test('only partials nobody can resume are swept', () {
    const keep = {'西游记_第1集'};
    bool orphan(String n) => DownloadService.orphanedPartial(n, keep);
    expect(orphan('西游记_第1集.ts.vidradlp.tmp'), isFalse);
    expect(orphan('西游记_第1集.ts.vidradlp.tmp.hls'), isFalse);
    expect(orphan('西游记_第2集.ts.vidradlp.tmp'), isTrue);
    expect(orphan('西游记_第2集.ts.vidradlp.tmp.hls'), isTrue);
    // A different download whose name merely starts the same way.
    expect(orphan('西游记_第1集_abc.ts.vidradlp.tmp'), isTrue);
    // Finished files and anything else in the folder are never candidates.
    expect(orphan('西游记_第2集.mp4'), isFalse);
    expect(orphan('notes.tmp'), isFalse);
  });

  group('the fallback HLS parser refuses what it cannot download honestly', () {
    Future<List<String>> parse(String c) =>
        M3U8Parser.parsePlaylist(c, 'https://x/', Dio(), null, null);

    test('an error page', () {
      expect(parse('<html>403</html>'), throwsException);
    });
    test('an encrypted stream', () {
      expect(
        parse('#EXTM3U\n#EXT-X-KEY:METHOD=AES-128,URI="k"\n#EXTINF:1,\na.ts\n'),
        throwsException,
      );
    });
    test('but METHOD=NONE is plain TS', () async {
      expect(
        await parse('#EXTM3U\n#EXT-X-KEY:METHOD=NONE\n#EXTINF:1,\na.ts\n'),
        ['https://x/a.ts'],
      );
    });
  });
}
