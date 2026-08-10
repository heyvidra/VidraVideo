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
}
