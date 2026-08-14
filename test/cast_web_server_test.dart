import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:vidra/src/features/cast/data/cast_web_server.dart';
import 'package:vidra/src/features/cast/domain/cast_target.dart';

/// A CDN that answers whatever this test needs it to.
class _FakeCdn {
  late HttpServer _server;
  String body = '';
  String contentType = 'application/vnd.apple.mpegurl';

  Future<String> start() async {
    _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    _server.listen((req) async {
      req.response.headers.set(HttpHeaders.contentTypeHeader, contentType);
      req.response.add(utf8.encode(body));
      await req.response.close();
    });
    return 'http://127.0.0.1:${_server.port}';
  }

  Future<void> stop() => _server.close(force: true);
}

/// A CDN with more than one thing on it: a master, a media playlist, a
/// segment, and wherever a path is told to redirect to.
class _Cdn {
  late HttpServer _server;
  late String origin;

  /// Path to body. The content type follows the extension, as a real one's
  /// does.
  final Map<String, String> bodies = {};

  /// Path to an absolute Location, for the mid-playback hop to an edge host.
  final Map<String, String> redirects = {};

  final List<String> seen = [];
  final List<String?> ranges = [];

  Future<String> start() async {
    _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    origin = 'http://127.0.0.1:${_server.port}';
    _server.listen((req) async {
      seen.add(req.uri.path);
      ranges.add(req.headers.value(HttpHeaders.rangeHeader));
      final to = redirects[req.uri.path];
      if (to != null) {
        req.response.statusCode = HttpStatus.found;
        req.response.headers.set(HttpHeaders.locationHeader, to);
        await req.response.close();
        return;
      }
      final body = bodies[req.uri.path];
      if (body == null) {
        req.response.statusCode = HttpStatus.notFound;
        await req.response.close();
        return;
      }
      final bytes = utf8.encode(body);
      req.response.headers.set(
        HttpHeaders.contentTypeHeader,
        req.uri.path.endsWith('.m3u8')
            ? 'application/vnd.apple.mpegurl'
            : 'video/mp2t',
      );
      req.response.headers.set(HttpHeaders.acceptRangesHeader, 'bytes');
      final range = RegExp(
        r'bytes=(\d+)-(\d*)',
      ).firstMatch(req.headers.value(HttpHeaders.rangeHeader) ?? '');
      if (range != null) {
        final from = int.parse(range.group(1)!);
        final to = range.group(2)!.isEmpty
            ? bytes.length - 1
            : int.parse(range.group(2)!);
        req.response.statusCode = HttpStatus.partialContent;
        req.response.headers.set(
          HttpHeaders.contentRangeHeader,
          'bytes $from-$to/${bytes.length}',
        );
        req.response.add(bytes.sublist(from, to + 1));
      } else {
        req.response.add(bytes);
      }
      await req.response.close();
    });
    return origin;
  }

  Future<void> stop() => _server.close(force: true);
}

/// One request, carrying whatever DLNA headers the test is about.
Future<({int status, HttpHeaders headers, String body})> _ask(
  String url, {
  String method = 'GET',
  Map<String, String> headers = const {},
}) async {
  final client = HttpClient();
  try {
    final req = await client.openUrl(method, Uri.parse(url));
    headers.forEach(req.headers.set);
    final res = await req.close();
    final bytes = <int>[];
    await for (final chunk in res) {
      bytes.addAll(chunk);
    }
    return (
      status: res.statusCode,
      headers: res.headers,
      body: utf8.decode(bytes, allowMalformed: true),
    );
  } finally {
    client.close(force: true);
  }
}

void main() {
  group('jsonForScript', () {
    // The escape shipped once as a replaceAll from '<' to '<' — a correct
    // comment over a line that did nothing. So assert on the output, never
    // on the presence of the call.
    test('a title cannot close the script block it sits in', () {
      final out = CastWebServer.jsonForScript([
        {'title': 'EP1</script><img src=x onerror=alert(1)>'},
      ]);
      expect(out, isNot(contains('</script')));
      expect(out, isNot(contains('<img')));
      // Still JSON, and still the same string once the page parses it.
      final back = jsonDecode(out) as List;
      expect(
        (back.first as Map)['title'],
        'EP1</script><img src=x onerror=alert(1)>',
      );
    });

    test('ordinary titles survive intact', () {
      final out = CastWebServer.jsonForScript([
        {'title': '第 1 集'},
      ]);
      expect(jsonDecode(out), [
        {'title': '第 1 集'},
      ]);
    });
  });

  group('lanAddress', () {
    test('prefers the interface on the television\'s own subnet', () async {
      final mine = await CastWebServer.lanAddress();
      if (mine == null) return; // no network on this machine
      final sameSubnet = '${mine.split('.').take(3).join('.')}.222';
      expect(await CastWebServer.lanAddress(sameSubnet), mine);
      // Nothing matches 203.0.113.x, so it falls back rather than failing.
      expect(await CastWebServer.lanAddress('203.0.113.7'), isNotNull);
    });
  });

  group('proxy', () {
    late _FakeCdn cdn;
    late CastWebServer server;
    late String origin;

    setUp(() async {
      cdn = _FakeCdn();
      origin = await cdn.start();
      server = CastWebServer();
    });

    tearDown(() async {
      await server.stop();
      server.dispose();
      await cdn.stop();
    });

    /// The proxied playlist URL, or null when this machine has no LAN
    /// address to serve from.
    Future<Uri?> proxiedPlaylist() async {
      try {
        await server.start(peerHost: '127.0.0.1');
      } on CastServerException {
        return null;
      }
      server.serve(
        CastPlaylist(
          title: 'T',
          items: [
            CastItem(title: '第01集', url: '$origin/index.m3u8', sourceIndex: 0),
          ],
        ),
      );
      return Uri.parse(server.proxied('$origin/index.m3u8'));
    }

    // A Chinese episode name in an #EXTINF line used to reach
    // HttpResponse.write() under its latin1 default and throw mid-response:
    // the television got a 500 for a playlist that was perfectly valid.
    test('a playlist with non-ASCII names is served, not 500ed', () async {
      cdn.body = '#EXTM3U\n#EXTINF:10,第01集\nseg.ts\n';
      final url = await proxiedPlaylist();
      if (url == null) return;
      final client = HttpClient();
      final res = await (await client.getUrl(url)).close();
      final text = await utf8.decodeStream(res);
      client.close();

      expect(res.statusCode, 200);
      expect(text, contains('第01集'));
      expect(res.headers.contentType?.charset, 'utf-8');
    });

    test('an unlisted origin is refused', () async {
      final url = await proxiedPlaylist();
      if (url == null) return;
      final evil = url.replace(
        queryParameters: {
          ...url.queryParameters,
          'url': 'http://127.0.0.1:1/secret',
        },
      );
      final client = HttpClient();
      final res = await (await client.getUrl(evil)).close();
      await res.drain<void>();
      client.close();
      expect(res.statusCode, HttpStatus.forbidden);
    });
  });

  // What an LG renderer is told about a stream, and what it is given when it
  // asks to start part-way in. None of this was said at all: the renderer got
  // an HLS playlist announced as video/mp4 with no DLNA headers on it, and a
  // renderer that is told nothing concludes it can neither seek nor resume.
  group('DLNA', () {
    late _Cdn cdn;
    late CastWebServer server;

    /// Four ten-second segments, and a master above them.
    const media =
        '#EXTM3U\n'
        '#EXT-X-VERSION:3\n'
        '#EXT-X-TARGETDURATION:10\n'
        '#EXTINF:10,\n'
        's0.ts\n'
        '#EXTINF:10,\n'
        's1.ts\n'
        '#EXTINF:10,\n'
        's2.ts\n'
        '#EXTINF:10,\n'
        's3.ts\n'
        '#EXT-X-ENDLIST\n';
    const master =
        '#EXTM3U\n'
        '#EXT-X-STREAM-INF:BANDWIDTH=800000\n'
        'media.m3u8\n';

    setUp(() async {
      cdn = _Cdn();
      await cdn.start();
      cdn.bodies
        ..['/index.m3u8'] = master
        ..['/media.m3u8'] = media
        ..['/s2.ts'] = 'SEGMENT-TWO-BYTES';
      server = CastWebServer();
    });

    tearDown(() async {
      await server.stop();
      server.dispose();
      await cdn.stop();
    });

    /// The proxied URL of [path], or null when this machine has no LAN
    /// address to serve from.
    Future<String?> proxied(String path) async {
      try {
        await server.start(peerHost: '127.0.0.1');
      } on CastServerException {
        return null;
      }
      server.serve(
        CastPlaylist(
          title: 'T',
          items: [
            CastItem(
              title: '第01集',
              url: '${cdn.origin}/index.m3u8',
              sourceIndex: 0,
            ),
          ],
        ),
      );
      return server.proxied('${cdn.origin}$path');
    }

    test('every answer says it is a stream, in the case renderers match on',
        () async {
      final url = await proxied('/media.m3u8');
      if (url == null) return;
      // Read the raw response: dart:io lower-cases every header name it
      // writes unless told not to, and a renderer doing a case-sensitive
      // compare never sees `transfermode.dlna.org`.
      final at = Uri.parse(url);
      final socket = await Socket.connect(at.host, at.port);
      socket.write(
        'GET ${at.path}?${at.query} HTTP/1.1\r\n'
        'Host: ${at.host}:${at.port}\r\n'
        'getcontentFeatures.dlna.org: 1\r\n'
        'TimeSeekRange.dlna.org: npt=25-\r\n'
        'Connection: close\r\n\r\n',
      );
      final received = <int>[];
      await for (final chunk in socket) {
        received.addAll(chunk);
      }
      final raw = utf8.decode(received, allowMalformed: true);
      await socket.close();

      expect(raw, contains('transferMode.dlna.org: Streaming'));
      expect(raw, contains('contentFeatures.dlna.org: DLNA.ORG_OP=10'));
      expect(raw, contains('TimeSeekRange.dlna.org: npt='));
    });

    test('a playlist advertises time-seek, a segment byte-seek', () async {
      final playlist = await proxied('/media.m3u8');
      if (playlist == null) return;
      final ask = {'getcontentFeatures.dlna.org': '1'};

      final onPlaylist = await _ask(playlist, headers: ask);
      expect(
        onPlaylist.headers.value('contentFeatures.dlna.org'),
        // Time-seek is real now; a byte range into a document we rewrite
        // whole would describe bytes nobody has.
        startsWith('DLNA.ORG_OP=10;'),
      );
      expect(
        onPlaylist.headers.value('contentFeatures.dlna.org'),
        contains('DLNA.ORG_FLAGS=017000000'),
      );

      final onSegment = await _ask(
        server.proxied('${cdn.origin}/s2.ts'),
        headers: ask,
      );
      expect(
        onSegment.headers.value('contentFeatures.dlna.org'),
        startsWith('DLNA.ORG_OP=01;'),
      );
      expect(onSegment.headers.value('transferMode.dlna.org'), 'Streaming');
    });

    test('a renderer that never asks is told nothing about seeking', () async {
      final url = await proxied('/media.m3u8');
      if (url == null) return;
      final res = await _ask(url);
      expect(res.headers.value('contentFeatures.dlna.org'), isNull);
      expect(res.headers.value('TimeSeekRange.dlna.org'), isNull);
      expect(res.body, contains('s0.ts'), reason: 'no seek, no cut');
    });

    test('TimeSeekRange is served from there and echoed back', () async {
      final url = await proxied('/media.m3u8');
      if (url == null) return;
      final res = await _ask(
        url,
        headers: {'TimeSeekRange.dlna.org': 'npt=25.000-'},
      );

      expect(res.status, 200);
      expect(res.body, isNot(contains('s0.ts')));
      expect(res.body, isNot(contains('s1.ts')));
      expect(res.body, contains('s2.ts'));
      expect(res.body, contains('#EXT-X-MEDIA-SEQUENCE:2'));
      // The echo IS the contract: a renderer that asks and gets nothing back
      // concludes the stream cannot be seeked, and this one has to describe
      // what was actually served — the segment boundary, not the 25 asked for.
      expect(
        res.headers.value('TimeSeekRange.dlna.org'),
        'npt=20.000-40.000/40.000',
      );

      // And what the renderer plays first is a segment it can actually fetch:
      // still through us, still carrying the session token.
      final first = res.body.split('\n').firstWhere((l) => l.startsWith('http'));
      final segment = await _ask(first);
      expect(segment.status, 200);
      expect(segment.body, 'SEGMENT-TWO-BYTES');
    });

    test('the clock spelling of npt is understood too', () async {
      final url = await proxied('/media.m3u8');
      if (url == null) return;
      final res = await _ask(
        url,
        headers: {'TimeSeekRange.dlna.org': 'npt=00:00:25.500-00:00:40.000'},
      );
      expect(res.body, contains('s2.ts'));
      expect(res.body, isNot(contains('s1.ts')));
      expect(
        res.headers.value('TimeSeekRange.dlna.org'),
        'npt=20.000-40.000/40.000',
      );
    });

    test('an offset past the end replays instead of serving nothing', () async {
      final url = await proxied('/media.m3u8');
      if (url == null) return;
      final res = await _ask(
        url,
        headers: {'TimeSeekRange.dlna.org': 'npt=9999-'},
      );
      expect(res.status, 200);
      expect(res.body, contains('s0.ts'));
      expect(
        res.headers.value('TimeSeekRange.dlna.org'),
        'npt=0.000-40.000/40.000',
      );
    });

    test('a master has no timeline, so the offset rides down to the variant',
        () async {
      final url = await proxied('/index.m3u8');
      if (url == null) return;
      final onMaster = await _ask(
        url,
        headers: {'TimeSeekRange.dlna.org': 'npt=25-'},
      );
      // The master names no durations, so it can only say where it was told
      // to start; the variant answers with the real window a moment later.
      expect(onMaster.headers.value('TimeSeekRange.dlna.org'), 'npt=25.000-/*');
      expect(onMaster.body, contains('start=25.000'));

      final variant = onMaster.body
          .split('\n')
          .firstWhere((l) => l.startsWith('http'));
      final onVariant = await _ask(variant);
      expect(onVariant.body, contains('s2.ts'));
      expect(onVariant.body, isNot(contains('s1.ts')));
      expect(
        onVariant.headers.value('TimeSeekRange.dlna.org'),
        'npt=20.000-40.000/40.000',
      );
      // And the segments in it carry no offset of their own — a cut playlist
      // is already where it needs to be.
      expect(onVariant.body, isNot(contains('start=')));
    });

    test('HEAD on a playlist describes the body a GET would send', () async {
      final url = await proxied('/media.m3u8');
      if (url == null) return;
      final head = await _ask(url, method: 'HEAD');
      final get = await _ask(url);

      expect(head.status, 200);
      expect(head.body, isEmpty, reason: 'never a rewritten playlist body');
      expect(
        head.headers.contentType?.mimeType,
        'application/vnd.apple.mpegurl',
      );
      expect(head.headers.contentLength, utf8.encode(get.body).length);
      expect(head.headers.value('transferMode.dlna.org'), 'Streaming');
    });

    test('HEAD on a segment states its length without pulling it', () async {
      final url = await proxied('/media.m3u8');
      if (url == null) return;
      cdn.seen.clear();
      cdn.ranges.clear();
      final head = await _ask(
        server.proxied('${cdn.origin}/s2.ts'),
        method: 'HEAD',
      );

      expect(head.status, 200, reason: 'not the 206 our own probe got');
      expect(head.body, isEmpty);
      expect(head.headers.contentType?.mimeType, 'video/mp2t');
      expect(head.headers.contentLength, 'SEGMENT-TWO-BYTES'.length);
      // One byte off the CDN, not the whole segment.
      expect(cdn.ranges, ['bytes=0-0']);
    });
  });

  // The allowlist is what stops this being an open proxy, so every way it
  // grows has to be a way that cannot reach this machine.
  group('allowlist', () {
    test('a host under an allowed domain is the same CDN', () {
      // The mid-episode redirect that used to be a 502 and a dead television.
      const vod = 'vod.example.com';
      expect(CastWebServer.sameSite(vod, 'edge12.vod.example.com'), isTrue);
      expect(CastWebServer.sameSite(vod, 'edge12.example.com'), isTrue);
      expect(CastWebServer.sameSite(vod, 'example.com'), isTrue);
      // The same name on another port is the same CDN too, which only comes
      // up because an exact origin match has already failed.
      expect(CastWebServer.sameSite(vod, vod), isTrue);
    });

    test('and everything else is somewhere new', () {
      const vod = 'vod.example.com';
      expect(CastWebServer.sameSite(vod, 'example.net'), isFalse);
      expect(CastWebServer.sameSite(vod, 'notexample.com'), isFalse);
      // Never above the allowed host's own domain: a two-label host vouches
      // for nothing at all.
      expect(CastWebServer.sameSite('example.com', 'evil.com'), isFalse);
      // And never a whole public suffix, which is what dropping one label
      // from a country-code host would otherwise hand over.
      const uk = 'player.example.co.uk';
      expect(CastWebServer.sameSite(uk, 'evil.co.uk'), isFalse);
      expect(CastWebServer.sameSite(uk, 'edge.example.co.uk'), isTrue);
      // An address literal has no domain above it, and another port on a
      // machine we are talking to is another service, not another edge.
      expect(CastWebServer.sameSite('127.0.0.1', '1.0.0.1'), isFalse);
      expect(CastWebServer.sameSite('127.0.0.1', '127.0.0.1'), isFalse);
      expect(CastWebServer.sameSite('192.168.1.9', 'evil.168.1.9'), isFalse);
    });

    group('over real sockets', () {
      late _Cdn origin;
      late _Cdn edge;
      late _Cdn stranger;
      late CastWebServer server;

      setUp(() async {
        origin = _Cdn();
        edge = _Cdn();
        stranger = _Cdn();
        await origin.start();
        await edge.start();
        await stranger.start();
        // Loopback ports cannot tell a redirect to another host from one to
        // another service on this machine, and that difference is the whole
        // rule. So give the fixtures the names a real CDN uses and resolve
        // them here.
        server = CastWebServer(
          client: HttpClient()
            ..autoUncompress = false
            ..connectionFactory = (uri, _, _) {
              final port = {
                'vod.example.com': Uri.parse(origin.origin).port,
                'edge12.vod.example.com': Uri.parse(edge.origin).port,
                'alt.example.net': Uri.parse(stranger.origin).port,
                'evil.example.net': Uri.parse(stranger.origin).port,
              }[uri.host];
              if (port == null) {
                throw SocketException('no such host', address: null);
              }
              return Socket.startConnect(InternetAddress.loopbackIPv4, port);
            },
        );
      });

      tearDown(() async {
        await server.stop();
        server.dispose();
        await origin.stop();
        await edge.stop();
        await stranger.stop();
      });

      /// Starts the cast on the catalog's own host, or null with no LAN
      /// address to serve from.
      Future<String?> cast() async {
        try {
          await server.start(peerHost: '127.0.0.1');
        } on CastServerException {
          return null;
        }
        server.serve(
          CastPlaylist(
            title: 'T',
            items: [
              CastItem(
                title: 'e',
                url: 'http://vod.example.com/index.m3u8',
                sourceIndex: 0,
              ),
            ],
          ),
        );
        return server.proxied('http://vod.example.com/index.m3u8');
      }

      test('a second host the playlist names becomes fetchable', () async {
        // Every multi-CDN catalog is built this way, and the variant used to
        // come back 403 from our own proxy.
        origin.bodies['/index.m3u8'] =
            '#EXTM3U\n'
            '#EXT-X-STREAM-INF:BANDWIDTH=800000\n'
            'http://alt.example.net/media.m3u8\n';
        stranger.bodies['/media.m3u8'] =
            '#EXTM3U\n#EXTINF:10,\ns0.ts\n#EXT-X-ENDLIST\n';

        final url = await cast();
        if (url == null) return;
        final onMaster = await _ask(url);
        final variant = onMaster.body
            .split('\n')
            .firstWhere((l) => l.startsWith('http'));
        final onVariant = await _ask(variant);

        expect(onVariant.status, 200);
        expect(onVariant.body, contains('s0.ts'));
      });

      test('a redirect to an edge host is followed, not 502ed', () async {
        origin.bodies['/index.m3u8'] =
            '#EXTM3U\n#EXTINF:10,\ns0.ts\n#EXT-X-ENDLIST\n';
        origin.redirects['/s0.ts'] = 'http://edge12.vod.example.com/s0.ts';
        edge.bodies['/s0.ts'] = 'EDGE-BYTES';

        final url = await cast();
        if (url == null) return;
        final onPlaylist = await _ask(url);
        final segment = onPlaylist.body
            .split('\n')
            .firstWhere((l) => l.startsWith('http'));
        final res = await _ask(segment);

        expect(res.status, 200, reason: 'the picture stops dead on a 502');
        expect(res.body, 'EDGE-BYTES');
      });

      test('a redirect off the CDN entirely is still refused', () async {
        // The widening is one level, not a blank cheque: an edge host under
        // the domain the playlist came from, and nothing else.
        origin.bodies['/index.m3u8'] =
            '#EXTM3U\n#EXTINF:10,\ns0.ts\n#EXT-X-ENDLIST\n';
        origin.redirects['/s0.ts'] = 'http://evil.example.net/s0.ts';
        stranger.bodies['/s0.ts'] = 'SOMEWHERE-ELSE';

        final url = await cast();
        if (url == null) return;
        final onPlaylist = await _ask(url);
        final segment = onPlaylist.body
            .split('\n')
            .firstWhere((l) => l.startsWith('http'));
        final res = await _ask(segment);

        expect(res.status, HttpStatus.badGateway);
        expect(res.body, isNot(contains('SOMEWHERE-ELSE')));
      });

      test('a playlist cannot name its way onto the local network', () async {
        // The proxy takes the origins a playlist names, which is what makes
        // the two tests above work. A private address it was never talking
        // to is where that stops.
        origin.bodies['/index.m3u8'] =
            '#EXTM3U\n#EXTINF:10,\nhttp://10.1.2.3/secret.ts\n#EXT-X-ENDLIST\n';

        final url = await cast();
        if (url == null) return;
        final onPlaylist = await _ask(url);
        final segment = onPlaylist.body
            .split('\n')
            .firstWhere((l) => l.startsWith('http'));
        expect(segment, contains(Uri.encodeQueryComponent('http://10.1.2.3/')));

        final res = await _ask(segment);
        expect(res.status, HttpStatus.forbidden);
      });
    });
  });
}
