// Everything the TV fetches has to come back through our proxy, or the parts
// we cannot reach — headers, TLS downgrade, a CDN that would refuse the TV —
// stop being ours to fix. A missed URI line is a segment fetched straight
// from the CDN, which is exactly the request that fails.

import 'package:flutter_test/flutter_test.dart';
import 'package:vidra/src/features/cast/domain/hls_rewrite.dart';

const _base = 'http://192.168.1.9:8899/proxy';
final _at = Uri.parse('https://cdn.example.com/vod/2026/list.m3u8');

String rewrite(String playlist, {Uri? url}) => rewriteHlsPlaylist(
  playlist: playlist,
  playlistUrl: url ?? _at,
  proxyBase: _base,
);

void main() {
  test('a relative segment resolves against the playlist and is proxied', () {
    final out = rewrite('#EXTINF:9.0,\nseg1.ts');
    expect(out, contains('#EXTINF:9.0,'));
    expect(
      out,
      contains(
        '$_base?url=${Uri.encodeQueryComponent('https://cdn.example.com/vod/2026/seg1.ts')}',
      ),
    );
  });

  test('a root-relative segment resolves to the host, not the folder', () {
    // String concatenation would have produced /vod/2026//seg.ts here.
    final out = rewrite('/other/seg.ts');
    expect(
      out,
      contains(Uri.encodeQueryComponent('https://cdn.example.com/other/seg.ts')),
    );
  });

  test('an absolute segment keeps its own host', () {
    final out = rewrite('https://edge2.example.net/a/seg.ts');
    expect(
      out,
      contains(
        Uri.encodeQueryComponent('https://edge2.example.net/a/seg.ts'),
      ),
    );
  });

  // Byte for byte, but only for the tags that carry no URI. This test used to
  // assert that EVERY tag passed through, which is how #EXT-X-KEY went to the
  // television as an https CDN link it cannot fetch.
  test('tags with nothing to fetch, and blank lines, pass through', () {
    const src =
        '#EXTM3U\n#EXT-X-VERSION:3\n#EXT-X-TARGETDURATION:10\n\n#EXTINF:9.0,\na.ts\n#EXT-X-ENDLIST';
    final out = rewrite(src);
    final lines = out.split('\n');
    expect(lines[0], '#EXTM3U');
    expect(lines[1], '#EXT-X-VERSION:3');
    expect(lines[3], '');
    expect(lines[6], '#EXT-X-ENDLIST');
    expect(lines.length, src.split('\n').length, reason: 'line count is kept');
  });

  group('URIs that live in an attribute', () {
    // The renderer fetches these exactly as it fetches a segment, so a raw
    // CDN URL in one is a request it cannot make: no TLS, no User-Agent. An
    // #EXT-X-KEY it cannot fetch is an episode that never decrypts.
    test('#EXT-X-KEY is fetched through the proxy', () {
      final out = rewrite('#EXT-X-KEY:METHOD=AES-128,URI="k.key",IV=0x1\na.ts');
      expect(out, startsWith('#EXT-X-KEY:METHOD=AES-128,URI="$_base?url='));
      expect(
        out,
        contains(
          Uri.encodeQueryComponent('https://cdn.example.com/vod/2026/k.key'),
        ),
      );
      // Everything around the URI is left exactly as it was.
      expect(out, contains('METHOD=AES-128'));
      expect(out, contains(',IV=0x1'));
    });

    test('#EXT-X-MAP, #EXT-X-SESSION-KEY and I-frame variants too', () {
      for (final tag in const [
        '#EXT-X-MAP:URI="init.mp4"',
        '#EXT-X-SESSION-KEY:METHOD=AES-128,URI="s.key"',
        '#EXT-X-I-FRAME-STREAM-INF:BANDWIDTH=90000,URI="iframe.m3u8"',
      ]) {
        final out = rewrite(tag);
        expect(out, contains('URI="$_base?url='), reason: tag);
        expect(out, isNot(contains('URI="https://')), reason: tag);
      }
    });

    test('the token rides in the attribute as it does on a URI line', () {
      final out = rewriteHlsPlaylist(
        playlist: '#EXT-X-KEY:METHOD=AES-128,URI="k.key"',
        playlistUrl: _at,
        proxyBase: _base,
        extraQuery: 't=abc123',
      );
      expect(out, endsWith('&t=abc123"'));
    });

    test('a tag we do not understand keeps its attributes', () {
      // The safety property: only the four tags that name something fetchable
      // are touched, because rewriting an attribute of a tag we cannot read
      // would corrupt it.
      const src = '#EXT-X-SOMETHING:URI="https://cdn.example.com/x",A=1';
      expect(rewrite(src), src);
    });

    test('a key with no URI at all is left alone', () {
      expect(rewrite('#EXT-X-KEY:METHOD=NONE'), '#EXT-X-KEY:METHOD=NONE');
      expect(rewrite('#EXT-X-MAP:URI=""'), '#EXT-X-MAP:URI=""');
    });

    test('every rewritten URI is reported, attributes included', () {
      final seen = <String>[];
      rewriteHlsPlaylist(
        playlist: '#EXT-X-KEY:METHOD=AES-128,URI="k.key"\n#EXTINF:9,\na.ts',
        playlistUrl: _at,
        proxyBase: _base,
        onUri: (u) => seen.add(u.toString()),
      );
      // This is what the proxy's allowlist grows from, so a URI it never
      // hears about is a 403 for a segment the playlist itself named.
      expect(seen, [
        'https://cdn.example.com/vod/2026/k.key',
        'https://cdn.example.com/vod/2026/a.ts',
      ]);
    });
  });

  test('a master playlist variant is rewritten like any other URI', () {
    // Which is what makes the nesting work: the variant comes back through
    // the proxy and gets rewritten in turn.
    final out = rewrite('#EXT-X-STREAM-INF:BANDWIDTH=800000\n720/index.m3u8');
    expect(out, contains('#EXT-X-STREAM-INF:BANDWIDTH=800000'));
    expect(
      out,
      contains(
        Uri.encodeQueryComponent('https://cdn.example.com/vod/2026/720/index.m3u8'),
      ),
    );
  });

  test('CRLF input does not leave a stray carriage return in the URL', () {
    final out = rewrite('#EXTINF:9.0,\r\nseg1.ts\r\n');
    expect(out, isNot(contains('%0D')), reason: 'the \\r would 404 the segment');
    expect(
      out,
      contains(Uri.encodeQueryComponent('https://cdn.example.com/vod/2026/seg1.ts')),
    );
  });

  test('a query string on the segment survives encoding', () {
    final out = rewrite('seg.ts?token=a&expires=1');
    expect(
      out,
      contains(
        Uri.encodeQueryComponent(
          'https://cdn.example.com/vod/2026/seg.ts?token=a&expires=1',
        ),
      ),
    );
  });

  // The renderer fetches segments straight from what the playlist says, so
  // every rewritten line has to carry the session token or the proxy — which
  // 404s anything untokened — refuses its own segments.
  test('the session token rides on every rewritten line', () {
    final out = rewriteHlsPlaylist(
      playlist: '#EXTINF:9.0,\nseg1.ts\nseg2.ts',
      playlistUrl: _at,
      proxyBase: _base,
      extraQuery: 't=abc123',
    );
    final uris = out.split('\n').where((l) => l.startsWith(_base)).toList();
    expect(uris, hasLength(2));
    expect(uris.every((u) => u.endsWith('&t=abc123')), isTrue);
  });

  test('no token asked for, none added', () {
    expect(rewrite('seg1.ts'), isNot(contains('&t=')));
  });

  // A renderer that refuses Seek still plays what it is handed, so a resume
  // twelve minutes in is a playlist that BEGINS twelve minutes in. Everything
  // this cuts, it cuts once and never asks the television for anything.
  group('sliceMediaPlaylist', () {
    const key1 = '#EXT-X-KEY:METHOD=AES-128,URI="k1.key"';
    const key2 = '#EXT-X-KEY:METHOD=AES-128,URI="k2.key"';

    /// Four ten-second segments behind a key and an initialisation segment.
    const encrypted =
        '#EXTM3U\n'
        '#EXT-X-VERSION:3\n'
        '#EXT-X-TARGETDURATION:10\n'
        '#EXT-X-MEDIA-SEQUENCE:0\n'
        '$key1\n'
        '#EXT-X-MAP:URI="init.mp4"\n'
        '#EXTINF:10,\n'
        's0.ts\n'
        '#EXTINF:10,\n'
        's1.ts\n'
        '#EXTINF:10,\n'
        's2.ts\n'
        '#EXTINF:10,\n'
        's3.ts\n'
        '#EXT-X-ENDLIST\n';

    HlsSlice slice(String playlist, double at) =>
        sliceMediaPlaylist(playlist: playlist, offsetSeconds: at);

    test('drops what plays before the offset and keeps the rest', () {
      final out = slice(encrypted, 25);
      expect(out.playlist, isNot(contains('s0.ts')));
      expect(out.playlist, isNot(contains('s1.ts')));
      expect(out.playlist, contains('s2.ts'));
      expect(out.playlist, contains('s3.ts'));
      expect(out.startSeconds, 20);
      expect(out.totalSeconds, 40);
      expect(out.isMedia, isTrue);
    });

    test('the cut lands on the segment containing the offset, never after', () {
      // 19.999 is still inside s1, and a resume that skips the last second of
      // it has skipped content the viewer never saw.
      expect(slice(encrypted, 19.999).startSeconds, 10);
      // Exactly on a boundary belongs to the segment that starts there.
      expect(slice(encrypted, 20).startSeconds, 20);
      expect(slice(encrypted, 20.001).startSeconds, 20);
    });

    test('#EXT-X-MEDIA-SEQUENCE counts the segments that went', () {
      expect(slice(encrypted, 25).playlist, contains('#EXT-X-MEDIA-SEQUENCE:2'));
      expect(slice(encrypted, 35).playlist, contains('#EXT-X-MEDIA-SEQUENCE:3'));
    });

    test('a sequence the source had is added to, not replaced', () {
      final out = slice(
        encrypted.replaceFirst(
          '#EXT-X-MEDIA-SEQUENCE:0',
          '#EXT-X-MEDIA-SEQUENCE:100',
        ),
        25,
      );
      expect(out.playlist, contains('#EXT-X-MEDIA-SEQUENCE:102'));
      expect(out.playlist, isNot(contains('#EXT-X-MEDIA-SEQUENCE:2\n')));
    });

    test('a playlist that declared no sequence gets one', () {
      final out = slice(
        encrypted.replaceFirst('#EXT-X-MEDIA-SEQUENCE:0\n', ''),
        25,
      );
      final lines = out.playlist.split('\n');
      expect(lines.first, '#EXTM3U');
      expect(lines[1], '#EXT-X-MEDIA-SEQUENCE:2', reason: 'where players look');
    });

    test('the header survives the cut', () {
      final out = slice(encrypted, 25).playlist;
      expect(out, startsWith('#EXTM3U\n'));
      expect(out, contains('#EXT-X-VERSION:3'));
      expect(out, contains('#EXT-X-TARGETDURATION:10'));
      // Without the end marker a player treats what is left as live and
      // waits at the last segment for a continuation that never comes.
      expect(out, contains('#EXT-X-ENDLIST'));
    });

    test('the key and the map still stand above the first segment kept', () {
      final out = slice(encrypted, 25).playlist;
      // They were declared by a segment that is gone; without them the
      // renderer decrypts with no key and demuxes with no init segment.
      expect(out, contains(key1));
      expect(out, contains('#EXT-X-MAP:URI="init.mp4"'));
      expect(out.indexOf(key1), lessThan(out.indexOf('s2.ts')));
    });

    test('a key rotated mid-playlist carries the one in force at the cut', () {
      const rotated =
          '#EXTM3U\n'
          '#EXT-X-TARGETDURATION:10\n'
          '$key1\n'
          '#EXTINF:10,\n'
          's0.ts\n'
          '$key2\n'
          '#EXTINF:10,\n'
          's1.ts\n'
          '#EXTINF:10,\n'
          's2.ts\n'
          '#EXT-X-ENDLIST\n';
      final out = slice(rotated, 25).playlist;
      expect(out, contains(key2));
      expect(out, isNot(contains(key1)), reason: 'k1 decrypts nothing left');

      // And when the surviving segment declares its own, ours would only be
      // an override about to be overridden.
      final atRotation = slice(rotated, 15).playlist;
      expect(key2.allMatches(atRotation).length, 1);
      expect(atRotation, isNot(contains(key1)));
    });

    test('a tag belonging to a dropped segment leaves with it', () {
      const dated =
          '#EXTM3U\n'
          '#EXT-X-TARGETDURATION:10\n'
          '#EXT-X-PROGRAM-DATE-TIME:2026-01-01T00:00:00Z\n'
          '#EXTINF:10,\n'
          's0.ts\n'
          '#EXT-X-PROGRAM-DATE-TIME:2026-01-01T00:00:10Z\n'
          '#EXTINF:10,\n'
          's1.ts\n'
          '#EXT-X-ENDLIST\n';
      final out = slice(dated, 15).playlist;
      expect(out, isNot(contains('T00:00:00Z')), reason: 's0 is gone');
      expect(out, contains('T00:00:10Z'));
    });

    test('a dropped discontinuity is counted into the sequence', () {
      const broken =
          '#EXTM3U\n'
          '#EXT-X-TARGETDURATION:10\n'
          '#EXT-X-MEDIA-SEQUENCE:100\n'
          '#EXT-X-DISCONTINUITY-SEQUENCE:5\n'
          '#EXTINF:10,\n'
          's0.ts\n'
          '#EXT-X-DISCONTINUITY\n'
          '#EXTINF:10,\n'
          's1.ts\n'
          '#EXTINF:10,\n'
          's2.ts\n';
      final out = slice(broken, 25).playlist;
      expect(out, contains('#EXT-X-MEDIA-SEQUENCE:102'));
      expect(out, contains('#EXT-X-DISCONTINUITY-SEQUENCE:6'));
    });

    test('an offset past the end replays rather than serving nothing', () {
      // An empty playlist is an error on screen; a replay is an annoyance.
      expect(slice(encrypted, 40).playlist, encrypted);
      expect(slice(encrypted, 4000).playlist, encrypted);
      expect(slice(encrypted, 4000).startSeconds, 0);
      expect(slice(encrypted, 4000).totalSeconds, 40);
    });

    test('an offset inside the first segment changes nothing at all', () {
      expect(slice(encrypted, 0).playlist, encrypted);
      expect(slice(encrypted, -5).playlist, encrypted);
      expect(slice(encrypted, double.nan).playlist, encrypted);
      expect(slice(encrypted, 9.5).playlist, encrypted);
      expect(slice(encrypted, 9.5).startSeconds, 0);
    });

    test('a master playlist has no timeline to cut', () {
      const master =
          '#EXTM3U\n'
          '#EXT-X-STREAM-INF:BANDWIDTH=800000\n'
          '720/index.m3u8\n';
      final out = slice(master, 25);
      expect(out.playlist, master, reason: 'the variant carries the offset');
      expect(out.isMedia, isFalse);
      expect(out.totalSeconds, 0);
    });

    test('uneven segment durations still add up', () {
      const uneven =
          '#EXTM3U\n'
          '#EXTINF:9.009,\n'
          'a.ts\n'
          '#EXTINF:9.009,\n'
          'b.ts\n'
          '#EXTINF:2.502,\n'
          'c.ts\n'
          '#EXT-X-ENDLIST\n';
      final out = slice(uneven, 18.02);
      expect(out.playlist, contains('c.ts'));
      expect(out.playlist, isNot(contains('b.ts')));
      expect(out.startSeconds, closeTo(18.018, 0.0001));
      expect(out.totalSeconds, closeTo(20.52, 0.0001));
    });

    test('a CRLF playlist keeps its carriage returns', () {
      final out = slice(encrypted.replaceAll('\n', '\r\n'), 25).playlist;
      expect(out, contains('#EXT-X-MEDIA-SEQUENCE:2\r\n'));
      expect(out, contains('s2.ts\r\n'));
      final terminated = out
          .split('\n')
          .where((l) => l.isNotEmpty)
          .every((l) => l.endsWith('\r'));
      expect(terminated, isTrue);
    });

    test('what comes out is a playlist this can cut again', () {
      // The proxy serves what it cuts, and a renderer may seek twice.
      final once = slice(encrypted, 15);
      final twice = sliceMediaPlaylist(
        playlist: once.playlist,
        offsetSeconds: 10,
      );
      expect(twice.playlist, contains('s2.ts'));
      expect(twice.playlist, isNot(contains('s1.ts')));
      expect(twice.playlist, contains('#EXT-X-MEDIA-SEQUENCE:2'));
      expect(twice.totalSeconds, 30, reason: 'what is left after the first cut');
    });

    test('the cut playlist still rewrites into proxy URLs', () {
      final out = rewrite(slice(encrypted, 25).playlist);
      expect(
        out,
        contains(Uri.encodeQueryComponent('https://cdn.example.com/vod/2026/s2.ts')),
      );
      expect(
        out,
        contains(Uri.encodeQueryComponent('https://cdn.example.com/vod/2026/k1.key')),
      );
    });
  });

  group('looksLikePlaylist', () {
    test('trusts the content type', () {
      expect(
        looksLikePlaylist('application/vnd.apple.mpegurl', Uri.parse('http://x/a')),
        isTrue,
      );
    });

    test('falls back to the extension when the type is wrong', () {
      // One source serves playlists as application/octet-stream.
      expect(
        looksLikePlaylist('application/octet-stream', Uri.parse('http://x/a.m3u8')),
        isTrue,
      );
    });

    test('a segment is not a playlist', () {
      expect(
        looksLikePlaylist('video/mp2t', Uri.parse('http://x/a.ts')),
        isFalse,
      );
    });
  });
}
