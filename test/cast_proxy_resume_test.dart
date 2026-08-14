import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:vidra/src/features/cast/data/cast_web_server.dart';
import 'package:vidra/src/features/cast/domain/cast_target.dart';

/// A CDN that behaves like the ones that broke casting: it honours Range, and
/// it can be told to hang up partway through a body it promised in full —
/// which is what nginx's `send_timeout` does to a connection the proxy has
/// stopped draining while a television empties its buffer.
class _RangingCdn {
  late HttpServer _server;

  /// The whole resource. Served in slices according to Range.
  Uint8List body = Uint8List(0);
  String contentType = 'video/mp2t';

  /// Bytes to write before hanging up, per request index. A null entry serves
  /// the request in full. Consumed in order, so a test can say "drop the
  /// first, then behave".
  final List<int?> cutAfter = [];

  /// Every Range header received, in order — the proof that a resume asked
  /// for the right offset, and that a playlist was never ranged at all.
  final List<String?> ranges = [];

  int _requests = 0;

  Future<String> start() async {
    _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    _server.listen((req) async {
      final n = _requests++;
      final range = req.headers.value(HttpHeaders.rangeHeader);
      ranges.add(range);

      var start = 0;
      if (range != null) {
        final m = RegExp(r'bytes=(\d+)-').firstMatch(range);
        if (m != null) start = int.parse(m.group(1)!);
      }
      final slice = body.sublist(start);

      req.response.headers.set(HttpHeaders.contentTypeHeader, contentType);
      req.response.headers.set(HttpHeaders.acceptRangesHeader, 'bytes');
      if (range != null) {
        req.response.statusCode = HttpStatus.partialContent;
        req.response.headers.set(
          'content-range',
          'bytes $start-${body.length - 1}/${body.length}',
        );
      }
      req.response.headers.set('content-length', '${slice.length}');

      final cut = n < cutAfter.length ? cutAfter[n] : null;
      if (cut == null) {
        req.response.add(slice);
        await req.response.close();
        return;
      }
      // Promise the whole slice, deliver `cut` bytes, then destroy the socket
      // — no clean close, exactly what a CDN write timeout looks like. The
      // socket has to be detached BEFORE the body goes out: once dart:io has
      // written a response it will not hand the socket over.
      final socket = await req.response.detachSocket();
      socket.add(slice.sublist(0, cut));
      await socket.flush();
      // Let the bytes leave before the RST, or the proxy sees only the reset
      // and there is nothing partial to resume from.
      await Future<void>.delayed(const Duration(milliseconds: 50));
      socket.destroy();
    });
    return 'http://127.0.0.1:${_server.port}';
  }

  Future<void> stop() => _server.close(force: true);
}

Future<(int status, List<int> body)> _get(String url, {String? range}) async {
  final client = HttpClient();
  try {
    final req = await client.getUrl(Uri.parse(url));
    if (range != null) req.headers.set(HttpHeaders.rangeHeader, range);
    final res = await req.close();
    final bytes = <int>[];
    await for (final c in res) {
      bytes.addAll(c);
    }
    return (res.statusCode, bytes);
  } finally {
    client.close(force: true);
  }
}

void main() {
  late _RangingCdn cdn;
  late CastWebServer server;
  late String cdnBase;

  setUp(() async {
    cdn = _RangingCdn();
    cdnBase = await cdn.start();
    server = CastWebServer();
    await server.start(peerHost: '127.0.0.1');
  });

  tearDown(() async {
    await server.stop();
    await cdn.stop();
  });

  test('a CDN that hangs up mid-segment is resumed, not passed on short',
      () async {
    // 400 KB of recognisable bytes, cut off a quarter of the way in.
    cdn.body = Uint8List.fromList(
      List.generate(400 * 1024, (i) => i % 251),
    );
    cdn.cutAfter.add(100 * 1024);

    final url = '$cdnBase/seg.ts';
    server.serve(
      CastPlaylist(title: 't', items: [CastItem(title: 'e', url: url, sourceIndex: 0)]),
    );
    final (status, bytes) = await _get(server.proxied(url));

    expect(status, 200);
    // The whole segment reached the renderer, which is the difference between
    // a picture that keeps moving and one frozen on its last frame.
    expect(bytes.length, cdn.body.length);
    expect(bytes, cdn.body);
    // And the resume asked for exactly what was still owed.
    expect(cdn.ranges.length, 2);
    expect(cdn.ranges.first, isNull);
    expect(cdn.ranges[1], 'bytes=${100 * 1024}-');
  });

  test('a resume inside a ranged request offsets from what the client asked',
      () async {
    cdn.body = Uint8List.fromList(List.generate(200 * 1024, (i) => i % 251));
    cdn.cutAfter.add(50 * 1024);

    final url = '$cdnBase/seg.ts';
    server.serve(
      CastPlaylist(title: 't', items: [CastItem(title: 'e', url: url, sourceIndex: 0)]),
    );
    final (_, bytes) = await _get(
      server.proxied(url),
      range: 'bytes=${20 * 1024}-',
    );

    expect(bytes.length, cdn.body.length - 20 * 1024);
    expect(bytes, cdn.body.sublist(20 * 1024));
    // 20K asked for by the renderer + 50K already delivered.
    expect(cdn.ranges[1], 'bytes=${70 * 1024}-');
  });

  test('a bounded Range on a playlist is never forwarded, and the whole '
      'playlist comes back', () async {
    const playlist = '#EXTM3U\n'
        '#EXT-X-TARGETDURATION:6\n'
        '#EXTINF:6,\n'
        'a.ts\n'
        '#EXTINF:6,\n'
        'b.ts\n'
        '#EXT-X-ENDLIST\n';
    cdn.body = Uint8List.fromList(utf8.encode(playlist));
    cdn.contentType = 'application/vnd.apple.mpegurl';

    final url = '$cdnBase/index.m3u8';
    server.serve(
      CastPlaylist(title: 't', items: [CastItem(title: 'e', url: url, sourceIndex: 0)]),
    );
    // What a renderer expecting MP4 does when it goes looking for a moov atom.
    final (status, bytes) = await _get(
      server.proxied(url),
      range: 'bytes=0-20',
    );

    expect(status, 200);
    final text = utf8.decode(bytes);
    // The end marker is the whole point: without it a player treats the
    // playlist as live and waits forever at the last segment it can see.
    expect(text, contains('#EXT-X-ENDLIST'));
    expect(text, contains('a.ts'));
    expect(text, contains('b.ts'));
    // The CDN must never have seen a Range for a document we rewrite whole.
    expect(cdn.ranges.single, isNull);
  });
}
