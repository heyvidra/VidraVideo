import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vidra/src/features/video/data/demo_dbku/dbku_data_source.dart';
import 'package:vidra/src/features/video/data/demo_olevod/olevod_data_source.dart';
import 'package:vidra/src/features/video/data/yfsp/yfsp_data_source.dart';
import 'package:vidra/src/features/video/data/yfsp/yfsp_dto.dart';
import 'package:vidra/src/features/video/data/yfsp/yfsp_signer.dart';

/// A key pair captured from a `pConfig` blob on www.yfsp.tv. The pair itself
/// has since rotated and no longer authenticates anything — it is kept only so
/// the hash below is a fixed vector.
const _pub =
    'CJSuDZWuCpOrC2usE3TVIKrVEIuoD3OkE3SkDZTVC3PZC3SvOJ4nE3PcD69XPc8v'
    'OJXYC6DcE3arPJ0sOpDVPJSuCJ4sOsKsC3OpE6CoCZSqCcOpCcCsOJ9bCJ4tCJ0';
const _priv = 'SuDZJSuDZWuCpOrC2usE';

void main() {
  group('YfspSigner.signWith', () {
    test('reproduces a signature the live API accepted', () {
      // Captured end to end: this exact vv/pub pair on list/AllVideoType came
      // back {"code":0}. If this expectation ever fails, the port drifted —
      // the vector did not.
      final url = YfspSigner.signWith('https://m10.yfsp.tv/api/list/AllVideoType', {
        'cinema': '1',
        'cid': '0,1',
      }, pub: _pub, priv: _priv);

      expect(
        url,
        'https://m10.yfsp.tv/api/list/AllVideoType'
        '?cinema=1&cid=0%2C1'
        '&vv=135c0aa8610c6bb501c89cb6f0729433&pub=$_pub',
      );
    });

    test('hashes decoded values and lowercased keys, sends neither', () {
      // The two ways the port can silently diverge: hashing the ENCODED value
      // (Chinese filters would sign as %E5%A4%A7...) and sending a lowercased
      // key (`isindex` is refused). One vector pins both.
      final url = YfspSigner.signWith('https://m10.yfsp.tv/api/list/Search', {
        'cinema': '1',
        'tags': '',
        'cid': '0,1,4',
        'region': '大陆',
        'isIndex': '-1',
      }, pub: _pub, priv: _priv);

      expect(
        url,
        'https://m10.yfsp.tv/api/list/Search'
        '?cinema=1&tags=&cid=0%2C1%2C4&region=%E5%A4%A7%E9%99%86&isIndex=-1'
        '&vv=77a6ec405bb6f60e60ae9d70fc8e5b18&pub=$_pub',
      );
    });
  });

  group('YfspSigner.parseKeys', () {
    // The page's real shape: Cloudflare Turnstile's site key is ALSO called
    // "publicKey" and comes first, and there is only one "privateKey". Reading
    // the two field names independently pairs Turnstile's key with pConfig's
    // private one — a pair that signs cleanly and that every endpoint refuses
    // with 用户签名错误. That shipped once; this is the guard.
    const page =
        '<script>window.__d={"turnstile":{"publicKey":"0x4AAAAAACCL7s2rRZySToUJ"},'
        '"pConfig":{"publicKey":"CJSuDZWuE38oD2umCpTV","privateKey":["SuDZJSuDZWuE38oD2umC"]},'
        '"googleMapkey":"AIzaSyDjj"};</script>';

    test('takes the pair from pConfig, not the Turnstile decoy', () {
      final keys = YfspSigner.parseKeys(page);
      expect(keys.pub, 'CJSuDZWuE38oD2umCpTV');
      expect(keys.priv, 'SuDZJSuDZWuE38oD2umC');
    });

    test('throws rather than signing with a half-found pair', () {
      expect(
        () => YfspSigner.parseKeys(
          '<script>window.__d={"turnstile":{"publicKey":"0x4AAAAAACCL"}};</script>',
        ),
        throwsStateError,
      );
    });
  });

  group('yfspPickStream', () {
    test('skips the pre-roll ad and takes the HLS feature', () {
      // Shape of a real `video/play` response: ad first, show second.
      final stream = yfspPickStream([
        {
          'isHls': false,
          'result': 'https://cdn.example/vod/AD-0001.mp4',
          'link': 'https://ppt.yfsp.tv/c/c?position=PI',
        },
        {
          'isHls': true,
          'result': 'https://cdn.example/s111/abc/chunklist.m3u8',
          'link': null,
        },
      ]);
      expect(stream, 'https://cdn.example/s111/abc/chunklist.m3u8');
    });

    test('falls back to an entry with no advertiser link', () {
      final stream = yfspPickStream([
        {
          'isHls': false,
          'result': 'https://cdn.example/vod/AD-0001.mp4',
          'link': 'https://ppt.yfsp.tv/c/c?position=PI',
        },
        {'isHls': false, 'result': 'https://cdn.example/vod/FEATURE.mp4'},
      ]);
      expect(stream, 'https://cdn.example/vod/FEATURE.mp4');
    });

    test('answers null rather than an advert when only ads are present', () {
      final stream = yfspPickStream([
        {
          'isHls': false,
          'result': 'https://cdn.example/vod/AD-0001.mp4',
          'link': 'https://ppt.yfsp.tv/c/c?position=PI',
        },
      ]);
      expect(stream, isNull);
    });
  });

  group('剧情简介', () {
    // The detail screen prints `content ?? blurb`. `content` briefly carried
    // the class path — a spare-looking field used as a courier — and the page
    // duly showed "0,1,4,131" where the story goes.
    test('a list row puts the story in content, never the class path', () {
      final v = YfspListItemDto(const {
        'key': 'PwLAKyPFpPE',
        'title': '我们的少年时代2',
        'contxt': '开学季，宜北篮球社濒临解散。',
        'videoClassID': '0,1,4,131',
      }).toDomain();
      expect(v.content, '开学季，宜北篮球社濒临解散。');
      expect(v.content, isNot(contains('0,1,4')));
    });

    test('a detail row does the same', () {
      final v = YfspDetailDto(const {
        'key': 'PwLAKyPFpPE',
        'title': '我们的少年时代2',
        'contxt': '开学季，宜北篮球社濒临解散。',
        'cid': '0,1,4,131',
      }).toDomain(const []);
      expect(v.content, '开学季，宜北篮球社濒临解散。');
      expect(v.content, isNot(contains('0,1,4')));
    });
  });

  group('评分与更新状态', () {
    test('a derived rating carries no binary-float tail', () {
      // 0.47 * 10 is 4.699999999999999, and "★ 4.6999999999999999" reached
      // the detail page. Rounded at the source so it never enters the row.
      final v = YfspDetailDto(const {
        'key': 'k',
        'title': 't',
        'score': '暂无评分',
        'pinfenRate': 0.47,
      }).toDomain(const []);
      expect(v.rating, 4.7);
    });

    test('a bare episode number becomes an airing label', () {
      // "05" alone said nothing on the page, and missed the regex that paints
      // a still-airing show amber.
      expect(yfspAiringLabel('05'), '第5集');
      expect(yfspAiringLabel('5'), '第5集');
    });

    test("the catalog's own phrasing is left alone", () {
      expect(yfspAiringLabel('60集全'), '60集全');
      expect(yfspAiringLabel(''), isNull);
      expect(yfspAiringLabel(null), isNull);
    });
  });

  group('signHlsPlaylist', () {
    // The CDN answers an UNSIGNED request by resetting the connection — not
    // 403, not 404 — and it does that for segments too. The playlist the API
    // returns names its segments unsigned and the player fetches them itself,
    // so a playlist that reaches the player unrewritten stalls on every
    // segment and surfaces as "failed to open media" with nothing in the log.
    // Measured: unsigned segment RST, same segment signed 206.
    String signer(Uri u) => '$u${u.query.isEmpty ? '?' : '&'}vv=V&pub=P';

    test('signs every segment and leaves the tags alone', () {
      final out = signHlsPlaylist(
        playlist:
            '#EXTM3U\n'
            '#EXT-X-TARGETDURATION:14\n'
            '#EXTINF:10.0,\n'
            'https://cdn.example/media_0.ts?vhash=a\n'
            '#EXTINF:10.0,\n'
            'https://cdn.example/media_1.ts?vhash=b\n'
            '#EXT-X-ENDLIST',
        playlistUrl: Uri.parse('https://cdn.example/chunklist.m3u8'),
        signUri: signer,
      );
      expect(out, contains('media_0.ts?vhash=a&vv=V&pub=P'));
      expect(out, contains('media_1.ts?vhash=b&vv=V&pub=P'));
      // Line-for-line, or the tags stop describing the segment below them.
      expect(out.split('\n').length, 7);
      expect(out.split('\n').first, '#EXTM3U');
      expect(out, contains('#EXT-X-TARGETDURATION:14'));
      expect(out.trimRight(), endsWith('#EXT-X-ENDLIST'));
    });

    test('resolves a relative segment against the playlist', () {
      final out = signHlsPlaylist(
        playlist: '#EXTINF:9.0,\nseg1.ts',
        playlistUrl: Uri.parse('https://cdn.example/vod/list.m3u8'),
        signUri: signer,
      );
      expect(out, contains('https://cdn.example/vod/seg1.ts?vv=V&pub=P'));
    });

    test('signs a URI hiding in a tag attribute', () {
      // None of the playlists seen so far carry one, but an unsigned
      // #EXT-X-KEY is an episode that never decrypts — a silent failure worse
      // than the one this whole path exists to fix.
      final out = signHlsPlaylist(
        playlist: '#EXT-X-KEY:METHOD=AES-128,URI="key.bin"\n#EXTINF:9.0,\ns.ts',
        playlistUrl: Uri.parse('https://cdn.example/vod/list.m3u8'),
        signUri: signer,
      );
      expect(out, contains('URI="https://cdn.example/vod/key.bin?vv=V&pub=P"'));
    });

    test('leaves a tag with no URI untouched', () {
      const line = '#EXT-X-KEY:METHOD=NONE';
      final out = signHlsPlaylist(
        playlist: line,
        playlistUrl: Uri.parse('https://cdn.example/list.m3u8'),
        signUri: signer,
      );
      expect(out, line);
    });
  });

  group('streamHeaders', () {
    // The player's default guess is a browser UA plus `Referer: <stream's own
    // origin>`. Measured against the yfsp CDN: bare request 520, UA alone 200,
    // UA + that self-referer 520. So the referer is not merely unnecessary
    // here, it is what breaks playback — the source has to replace the guess,
    // not extend it, and it must not quietly regrow a Referer.
    test('yfsp sends a user agent and NO referer', () {
      final headers = YfspDataSource(Dio()).streamHeaders;
      expect(headers, isNotNull);
      expect(headers!['User-Agent'], isNotEmpty);
      expect(headers.keys.map((k) => k.toLowerCase()), isNot(contains('referer')));
    });

    test('the sources that are happy with the guess keep it', () {
      // Null means "let the player guess" — anything else here would silently
      // change how olevod and dbku streams open.
      expect(OlevodDataSource(Dio()).streamHeaders, isNull);
      expect(DbkuDataSource(Dio()).streamHeaders, isNull);
    });
  });

  group('yfspHandle', () {
    test('is stable, positive, and distinguishes the real keys', () {
      // Keys from one show and its episodes — consecutive database rows on the
      // host, deliberately unrelated as tokens.
      const keys = [
        'PwLAKyPFpPE',
        '8HZBdNQzaC9',
        'tS5TptCed4C',
        '4uffU88NQV7',
        '4aCzigFsFmI',
        'Z613NkuHqYB',
        '6h1p4eyaUWH',
      ];
      final handles = keys.map(yfspHandle).toList();

      expect(handles.toSet().length, keys.length, reason: 'collision');
      expect(handles.every((h) => h > 0), isTrue);
      // Same key, same handle — the cached `videos` row is found by it.
      expect(yfspHandle(keys.first), handles.first);
    });
  });
}
