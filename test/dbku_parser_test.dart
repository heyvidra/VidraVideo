import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vidra/src/features/video/data/demo_dbku/dbku_data_source.dart';
import 'package:vidra/src/features/video/data/demo_dbku/dbku_parser.dart';
import 'package:vidra/src/features/video/data/mock/mock_data_source.dart';
import 'package:vidra/src/features/video/domain/video_collection.dart';

/// Markup below mirrors dbku.tv's MacCMS "mytheme" template structurally;
/// the titles and text are placeholders. If the site's theme changes, these
/// are the assertions that should start failing.
void main() {
  group('parseVideoList', () {
    test('reads a grid item', () {
      const html =
          '<li class="col-lg-8"><div class="myui-vodlist__box">'
          '<a class="myui-vodlist__thumb lazyload" href="/voddetail/147218.html" '
          'title="Placeholder A" data-original="https://img.example.com/a.jpg">'
          '<span class="play hidden-xs"></span>'
          '<span class="pic-tag pic-tag-top"><span class="tag" style="background-color: #858484;">6分</span></span>'
          '<span class="pic-text text-right">更新至3集</span></a></div></li>';

      final list = DbkuParser.parseVideoList(html);

      expect(list, hasLength(1));
      expect(list.single.apiId, 147218);
      expect(list.single.sourceId, 'dbku');
      expect(list.single.title, 'Placeholder A');
      expect(list.single.coverUrl, 'https://img.example.com/a.jpg');
      expect(list.single.rating, 6.0);
      expect(list.single.remarks, '更新至3集');
    });

    test('picks up the cast line beside a grid thumb', () {
      // Real structure: the thumb anchor's SIBLING detail div carries the
      // comma-separated cast. The old parser stopped at </a> and lost it —
      // dbku cards rendered with an empty subtitle while the data sat in
      // the very HTML being parsed.
      const html =
          '<li class="col-lg-8 col-md-6"><div class="myui-vodlist__box">'
          '<a class="myui-vodlist__thumb lazyload" href="/voddetail/148144.html" '
          'title="凤池生春" data-original="https://img.example.com/f.jpg">'
          '<span class="play hidden-xs"></span>'
          '<span class="pic-tag pic-tag-top"><span class="tag" style="background-color: #858484;">9.1分</span></span>'
          '<span class="pic-text text-right">更新至19集</span></a>'
          '<div class="myui-vodlist__detail">'
          '<h4 class="title text-overflow"><a href="/voddetail/148144.html" title="凤池生春">凤池生春</a></h4>'
          '<p class="text text-overflow text-muted hidden-xs">朱丽岚,邓凯,薛八一</p>'
          '</div></div></li>';

      final list = DbkuParser.parseVideoList(html);
      expect(list, hasLength(1));
      expect(list.single.actor, '朱丽岚,邓凯,薛八一');
      expect(list.single.rating, 9.1);
      expect(list.single.remarks, '更新至19集');
    });

    test('a grid item without a cast line still parses, actor null', () {
      const html =
          '<li class="col-lg-8"><div class="myui-vodlist__box">'
          '<a class="myui-vodlist__thumb lazyload" href="/voddetail/1.html" '
          'title="X" data-original="https://img.example.com/x.jpg"></a>'
          '</div></li>';
      final list = DbkuParser.parseVideoList(html);
      expect(list, hasLength(1));
      expect(list.single.actor, isNull);
    });

    test('reads a search item, and counts each show once', () {
      // The search template repeats /voddetail/ links (thumb, heading, buttons);
      // only the thumb anchor should be picked up.
      const html =
          '<li class="clearfix"><div class="thumb">'
          '<a class="myui-vodlist__thumb img-lg-150 lazyload" href="/voddetail/4570.html" '
          'title="Placeholder B" data-original="https://img.example.com/b.jpg">'
          '<span class="pic-tag pic-tag-top"><span class="tag" style="background-color: #858484;">8.5分</span></span>'
          '<span class="pic-text text-right">全36集</span> </a></div>'
          '<div class="detail"><h4 class="title">'
          '<a class="searchkey" href="/voddetail/4570.html">Placeholder B</a></h4>'
          '<p class="margin-0"><a class="btn btn-sm btn-warm" href="/vodplay/4570-1-1.html">立即播放</a>'
          '<a class="btn btn-sm btn-default" href="/voddetail/4570.html">查看详情</a></p></div></li>';

      final list = DbkuParser.parseVideoList(html);

      expect(list, hasLength(1));
      expect(list.single.apiId, 4570);
      expect(list.single.rating, 8.5);
      expect(list.single.remarks, '全36集');
    });
  });

  group('parseSearchList', () {
    test('extracts the full media-row fields; 未知 becomes null', () {
      // Real structure of a /vodsearch result row: labelled spans with the
      // values as bare text. 导演 is the site's own 未知 placeholder and must
      // come through as null so the UI's fallback stays the single source
      // of "missing".
      const html =
          '<li class="clearfix"><div class="thumb">'
          '<a class="myui-vodlist__thumb img-lg-150 lazyload" href="/voddetail/148144.html" '
          'title="凤池生春" data-original="https://img.example.com/f.jpg">'
          '<span class="play hidden-xs"></span>'
          '<span class="pic-tag pic-tag-top"><span class="tag" style="background-color: #858484;">9.1分</span></span>'
          '<span class="pic-text text-right">更新至19集</span> </a></div>'
          '<div class="detail"><h4 class="title"><a class="searchkey" href="/voddetail/148144.html">凤池生春</a></h4>'
          '<p><span class="text-muted">导演：</span>未知</p>'
          '<p><span class="text-muted">主演：</span>朱丽岚,邓凯,薛八一</p>'
          '<p><span class="text-muted">分类：</span>短剧<span class="split-line"></span>'
          '<span class="text-muted hidden-xs">地区：</span>大陆<span class="split-line"></span>'
          '<span class="text-muted hidden-xs">年份：</span>2026</p>'
          '<p class="hidden-xs"><span class="text-muted">简介：</span>《凤池生春》线上看，共21集…'
          '<a href="/voddetail/148144.html">详情 &gt;</a></p>'
          '<p class="margin-0"><a class="btn btn-sm btn-warm" href="/vodplay/148144-1-1.html">立即播放</a>'
          '<a class="btn btn-sm btn-default hidden-xs" href="/voddetail/148144.html">查看详情</a></p>'
          '</div></li>';

      final list = DbkuParser.parseSearchList(html);
      expect(list, hasLength(1), reason: 'one row, however many voddetail links');
      final v = list.single;
      expect(v.apiId, 148144);
      expect(v.director, isNull, reason: '未知 is a placeholder, not a name');
      expect(v.actor, '朱丽岚,邓凯,薛八一');
      expect(v.type, '短剧');
      expect(v.region, '大陆');
      expect(v.year, '2026');
      expect(v.blurb, startsWith('《凤池生春》线上看'));
      expect(v.rating, 9.1);
      expect(v.remarks, '更新至19集');
    });
  });

  group('parseVideoDetail', () {
    const html =
        '<div class="myui-content__thumb">'
        '<a class="myui-vodlist__thumb picture" href="/vodplay/147143-1-1.html" title="Placeholder C">'
        '<img class="lazyload" src="/static/img/loading.png" data-original="https://img.example.com/c.jpg" /></a></div>'
        '<div class="myui-content__detail"><h1 class="title">Placeholder C</h1>'
        '<div id="rating" class="score" data-mid="1" data-id="147143" data-score="5">'
        '<span class="branch">8.3</span></div>'
        '<p class="data"><span class="text-muted">分类：</span>'
        '<a href="/vodshow/13-----------.html">陆剧</a><span class="split-line"></span>'
        '<span class="text-muted hidden-xs">地区：</span>'
        '<a href="/vodshow/13-大陆----------.html">大陆</a><span class="split-line"></span>'
        '<span class="text-muted hidden-xs">年份：</span>'
        '<a href="/vodshow/13-----------2026.html">2026</a></p>'
        '<p class="data hidden-sm"><span class="text-muted">更新：</span>'
        '<span class="text-red">2026-07-20 12:30:00</span></p>'
        '<p class="data"><span class="text-muted">主演：</span>'
        '<a href="/vodsearch/-X------------.html" target="_blank">Actor X</a>&nbsp;'
        '<a href="/vodsearch/-Y------------.html" target="_blank">Actor Y</a>&nbsp;</p>'
        '<p class="data"><span class="text-muted">导演：</span>'
        '<a href="/vodsearch/-----Z--------.html" target="_blank">Director Z</a>&nbsp;</p></div>'
        '<div class="col-pd text-collapse content">'
        '<span class="sketch content">Short summary.</span>'
        '<span class="data" style="display: none;"><p>Long summary.</p></span></div>'
        '<div id="playlist1" class="tab-pane fade in clearfix"><ul class="myui-content__list">'
        '<li><a class="btn btn-default" href="/vodplay/147143-1-1.html">第1集</a></li>'
        '<li><a class="btn btn-default" href="/vodplay/147143-1-2.html">第2集</a></li></ul></div>';

    test('reads the header fields', () {
      final video = DbkuParser.parseVideoDetail(html, 147143)!;

      expect(video.apiId, 147143);
      expect(video.title, 'Placeholder C');
      expect(video.coverUrl, 'https://img.example.com/c.jpg');
      expect(video.rating, 8.3);
      expect(video.type, '陆剧');
      expect(video.typeId, 13);
      expect(video.region, '大陆');
      expect(video.year, '2026');
      expect(video.actor, 'Actor X,Actor Y');
      expect(video.director, 'Director Z');
      expect(video.blurb, 'Short summary.');
      expect(video.content, 'Long summary.');
      expect(
        video.vodTime,
        DateTime.utc(2026, 7, 20, 12, 30).millisecondsSinceEpoch ~/ 1000,
      );
    });

    test('episodes carry the play-page path, not a stream URL', () {
      final episodes = DbkuParser.parseVideoDetail(html, 147143)!.urls!;

      expect(episodes, hasLength(2));
      expect(episodes.first.index, 0);
      expect(episodes.first.title, '第1集');
      expect(episodes.first.url, '/vodplay/147143-1-1.html');
      expect(episodes.last.url, '/vodplay/147143-1-2.html');
    });

    test('keeps only the first play source', () {
      final withSecondSource =
          '$html<div id="playlist2" class="tab-pane fade clearfix"><ul>'
          '<li><a class="btn btn-default" href="/vodplay/147143-2-1.html">第1集</a></li></ul></div>';

      final episodes = DbkuParser.parseVideoDetail(withSecondSource, 147143)!.urls!;

      expect(episodes, hasLength(2));
      expect(episodes.every((e) => e.url!.contains('-1-')), isTrue);
    });

    test('returns null when the page has no title', () {
      expect(DbkuParser.parseVideoDetail('<html></html>', 1), isNull);
    });
  });

  group('parsePlayUrl', () {
    test('decodes encrypt=2 (base64 of a urlencoded URL)', () {
      const html =
          '<script>var player_aaaa={"flag":"play","encrypt":2,"trysee":5,'
          '"url":"aHR0cHMlM0EvL3ZpZC5leGFtcGxlLmNvbS8yMDI2MDcwNS9hYmMubXA0L2NodW5rbGlzdC5tM3U4",'
          '"from":"vidjs25","id":"147143","sid":"1","nid":"1"}</script>';

      expect(
        DbkuParser.parsePlayUrl(html),
        'https://vid.example.com/20260705/abc.mp4/chunklist.m3u8',
      );
    });

    test('decodes encrypt=1 (urlencoded only)', () {
      const html =
          '<script>var player_aaaa={"encrypt":1,"url":"https%3A//vid.example.com/x.m3u8"}</script>';

      expect(DbkuParser.parsePlayUrl(html), 'https://vid.example.com/x.m3u8');
    });

    test('passes encrypt=0 through', () {
      const html =
          '<script>var player_aaaa={"encrypt":0,"url":"https://vid.example.com/x.m3u8"}</script>';

      expect(DbkuParser.parsePlayUrl(html), 'https://vid.example.com/x.m3u8');
    });

    test('returns null on a missing or unreadable config', () {
      expect(DbkuParser.parsePlayUrl('<html></html>'), isNull);
      expect(
        DbkuParser.parsePlayUrl('<script>var player_aaaa={"encrypt":2}</script>'),
        isNull,
      );
    });
  });

  group('resolveEpisodeUrl', () {
    // The Dio here has no adapter on purpose: every case below must answer
    // without a request, so any network attempt fails the test loudly.
    final dbku = DbkuDataSource(Dio());

    test('passes an already-resolved stream URL through', () async {
      // getVideoDetail resolves episodes eagerly, so the hook is routinely
      // handed a real URL. Re-fetching one as if it were a play page would
      // turn a cache hit into a broken request.
      const url = 'https://vid.example.com/x/chunklist.m3u8';

      expect(await dbku.resolveEpisodeUrl(url), url);
      expect(await dbku.getDownloadUrl(
        const Video(apiId: 1, title: 't', coverUrl: ''),
        episode: const VideoEpisode(
          qualities: [VideoQuality(name: '标清', url: url)],
        ),
      ), url);
    });

    test('defaults to a passthrough for sources that need no resolving', () async {
      expect(
        await MockDataSource().resolveEpisodeUrl('https://example.com/a.m3u8'),
        'https://example.com/a.m3u8',
      );
    });
  });
}
