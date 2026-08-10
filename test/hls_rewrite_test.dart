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

  test('tags and blank lines pass through byte for byte', () {
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
