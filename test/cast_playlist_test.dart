// Casting hands the TV a whole show, not one file, so the queue has to line
// up with what the viewer picked. The trap is a catalog row with an episode
// that has no URL: drop it silently and every later index shifts, so "cast
// 第7集" opens 第8集 on the television.

import 'package:flutter_test/flutter_test.dart';
import 'package:vidra/src/features/cast/domain/cast_target.dart';
import 'package:vidra/src/features/video/domain/video_collection.dart';

VideoEpisode ep(String title, String? url) => VideoEpisode(
  title: title,
  qualities: url == null ? null : [VideoQuality(name: 'HD', url: url)],
);

Video show(List<VideoEpisode> episodes) => Video(
  apiId: 1,
  sourceId: 'olevod',
  title: '九门',
  coverUrl: '',
  type: '陆剧',
  urls: episodes,
);

void main() {
  test('every playable episode travels, in order', () {
    final p = buildCastPlaylist(
      video: show([ep('第1集', 'http://a/1.m3u8'), ep('第2集', 'http://a/2.m3u8')]),
      episodeIndex: 0,
    )!;
    expect(p.title, '九门');
    expect(p.items.map((e) => e.url).toList(), [
      'http://a/1.m3u8',
      'http://a/2.m3u8',
    ]);
    expect(p.items.first.title, '第1集');
  });

  test('the chosen episode is where playback starts', () {
    final p = buildCastPlaylist(
      video: show([
        ep('第1集', 'http://a/1.m3u8'),
        ep('第2集', 'http://a/2.m3u8'),
        ep('第3集', 'http://a/3.m3u8'),
      ]),
      episodeIndex: 2,
    )!;
    expect(p.startIndex, 2);
    expect(p.items[p.startIndex].url, 'http://a/3.m3u8');
  });

  test('a dropped episode shifts startIndex so the right one still opens', () {
    // 第2集 has no URL. Casting 第3集 (source index 2) must land on 第3集,
    // which is index 1 once the unplayable one is gone.
    final p = buildCastPlaylist(
      video: show([
        ep('第1集', 'http://a/1.m3u8'),
        ep('第2集', null),
        ep('第3集', 'http://a/3.m3u8'),
      ]),
      episodeIndex: 2,
    )!;
    expect(p.items, hasLength(2));
    expect(p.items[p.startIndex].url, 'http://a/3.m3u8');
  });

  test('picking an episode that has no URL falls back to the one before it', () {
    final p = buildCastPlaylist(
      video: show([ep('第1集', 'http://a/1.m3u8'), ep('第2集', null)]),
      episodeIndex: 1,
    )!;
    expect(p.items, hasLength(1));
    expect(p.startIndex, 0);
  });

  test('a show with nothing playable is not castable at all', () {
    expect(buildCastPlaylist(video: show([ep('第1集', null)]), episodeIndex: 0),
        isNull);
    expect(buildCastPlaylist(video: show(const []), episodeIndex: 0), isNull);
  });

  test('blank URLs count as missing, not as an address', () {
    expect(
      buildCastPlaylist(video: show([ep('第1集', '   ')]), episodeIndex: 0),
      isNull,
    );
  });

  test('an untitled episode is still named by its number', () {
    final p = buildCastPlaylist(
      video: show([ep('', 'http://a/1.m3u8')]),
      episodeIndex: 0,
    )!;
    expect(p.items.single.title, '第1集');
  });

  // Progress comes back as a PLAYLIST position from both routes, and every
  // history row in the app is keyed by the EPISODE number. Reporting one as
  // the other wrote 第8集's progress onto 第7集.
  group('sourceIndexOf', () {
    test('with nothing dropped the two agree', () {
      final p = buildCastPlaylist(
        video: show([ep('第1集', 'http://a/1.m3u8'), ep('第2集', 'http://a/2.m3u8')]),
        episodeIndex: 0,
      )!;
      expect(p.sourceIndexOf(0), 0);
      expect(p.sourceIndexOf(1), 1);
    });

    test('a dropped episode shifts every later mapping', () {
      final p = buildCastPlaylist(
        video: show([
          ep('第1集', 'http://a/1.m3u8'),
          ep('第2集', null),
          ep('第3集', 'http://a/3.m3u8'),
        ]),
        episodeIndex: 0,
      )!;
      expect(p.sourceIndexOf(1), 2, reason: 'playlist slot 1 is 第3集');
      expect(p.items[1].title, '第3集', reason: 'and the TV agrees');
    });

    test('a position the playlist does not have maps to nothing', () {
      final p = buildCastPlaylist(
        video: show([ep('第1集', 'http://a/1.m3u8')]),
        episodeIndex: 0,
      )!;
      expect(p.sourceIndexOf(5), isNull);
      expect(p.sourceIndexOf(-1), isNull);
    });
  });

  test('the resume position rides along', () {
    final p = buildCastPlaylist(
      video: show([ep('第1集', 'http://a/1.m3u8')]),
      episodeIndex: 0,
      startPositionSeconds: 754,
    )!;
    expect(p.startPositionSeconds, 754);
  });
}
