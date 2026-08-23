// Integration test for the vendored vidraDlp FFI path.
//
// Serves a local HLS fixture, drives the app's exact VidraDlpClient
// (NativeCallable-based) download + in-Rust remux, and asserts a playable MP4.
//
// Requires the native lib; run with:
//   VIDRADLP_FFI_LIB=$(pwd)/macos/libmedia_ffi.dylib \
//     flutter test test/vidradlp_download_test.dart
// Skipped automatically if the lib can't load (e.g. plain CI without the dylib).
import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
// vidradlp_flutter re-exports vidradlp_ffi (incl. vidradlpLibraryAvailable).
import 'package:vidra/src/core/services/vidradlp/vidradlp_flutter.dart';

const _fixtureDir = '/private/tmp/claude-501/-Users-sidym-Workspace-video/'
    '3675a53b-33b9-4b6a-822a-3fb9161b2c2d/scratchpad/hls_fixture';

void main() {
  test('vidraDlp downloads local HLS and remuxes to a playable mp4', () async {
    final libExpected = Platform.environment['VIDRADLP_FFI_LIB'] != null;
    if (!vidradlpLibraryAvailable()) {
      if (libExpected) {
        fail('VIDRADLP_FFI_LIB is set but the native lib failed to load');
      }
      return; // genuinely unavailable on this runner — skip
    }
    if (!Directory(_fixtureDir).existsSync()) {
      return; // local HLS fixture not present on this machine — skip
    }

    final server = await HttpServer.bind('127.0.0.1', 0);
    server.listen((req) async {
      final f = File('$_fixtureDir${req.uri.path}');
      if (await f.exists()) {
        req.response.add(await f.readAsBytes());
      } else {
        req.response.statusCode = HttpStatus.notFound;
      }
      await req.response.close();
    });
    final url = 'http://127.0.0.1:${server.port}/playlist.m3u8';

    final outDir = Directory.systemTemp.createTempSync('vidradlp_dl');
    final outTs = '${outDir.path}/out.ts';

    final client = VidraDlpClient();
    final done = Completer<Map<String, dynamic>>();
    client.download(
      url: url,
      output: outTs,
      formatId: 'direct',
      options: const {'remux_to': 'mp4'},
      callback: (event) {
        final t = event['event'] as String?;
        if (t == 'finished' || t == 'error' || t == 'cancelled') {
          if (!done.isCompleted) done.complete(event);
        }
      },
    );

    final result = await done.future.timeout(const Duration(seconds: 30));
    expect(result['event'], 'finished', reason: 'download should succeed: $result');

    final mp4 = File('${outDir.path}/out.mp4');
    expect(mp4.existsSync(), isTrue, reason: 'remuxed .mp4 must exist');
    final bytes = mp4.readAsBytesSync();
    expect(bytes.length, greaterThan(1000));
    expect(String.fromCharCodes(bytes.sublist(4, 8)), 'ftyp',
        reason: 'must be a valid ISO-BMFF/MP4');
    // intermediate .ts cleaned up by the SDK
    expect(File(outTs).existsSync(), isFalse);

    client.free();
    await server.close(force: true);
    outDir.deleteSync(recursive: true);
  });

  test('ext template resolves by container and reports the final path',
      () async {
    final libExpected = Platform.environment['VIDRADLP_FFI_LIB'] != null;
    if (!vidradlpLibraryAvailable()) {
      if (libExpected) {
        fail('VIDRADLP_FFI_LIB is set but the native lib failed to load');
      }
      return;
    }
    if (!Directory(_fixtureDir).existsSync()) {
      return;
    }

    final server = await HttpServer.bind('127.0.0.1', 0);
    server.listen((req) async {
      final f = File('$_fixtureDir${req.uri.path}');
      if (await f.exists()) {
        req.response.add(await f.readAsBytes());
      } else {
        req.response.statusCode = HttpStatus.notFound;
      }
      await req.response.close();
    });
    final url = 'http://127.0.0.1:${server.port}/playlist.m3u8';

    final outDir = Directory.systemTemp.createTempSync('vidradlp_tpl');
    // The catalog flow's request shape: name by the ACTUAL container.
    final template = '${outDir.path}/show.%(ext)s';

    final client = VidraDlpClient();
    final done = Completer<Map<String, dynamic>>();
    client.download(
      url: url,
      output: template,
      formatId: 'direct',
      options: const {'remux_to': 'mp4', 'concurrency': 4},
      callback: (event) {
        final t = event['event'] as String?;
        if (t == 'finished' || t == 'error' || t == 'cancelled') {
          if (!done.isCompleted) done.complete(event);
        }
      },
    );

    final result = await done.future.timeout(const Duration(seconds: 30));
    expect(result['event'], 'finished',
        reason: 'template download should succeed: $result');
    // m3u8 resolves to .ts, the in-SDK remux produces .mp4, and the engine
    // reports that final path authoritatively.
    expect(result['output_path'], '${outDir.path}/show.mp4');
    final mp4 = File('${outDir.path}/show.mp4');
    expect(mp4.existsSync(), isTrue);
    expect(String.fromCharCodes(mp4.readAsBytesSync().sublist(4, 8)), 'ftyp');
    expect(File('${outDir.path}/show.ts').existsSync(), isFalse,
        reason: 'intermediate .ts cleaned up by the SDK');

    client.free();
    await server.close(force: true);
    outDir.deleteSync(recursive: true);
  });
}
