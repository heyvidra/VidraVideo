import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vidra/src/core/services/m3u8_downloader.dart';

void main() {
  test('media playlist: resolves relative + keeps absolute segment URLs',
      () async {
    const content = '''
#EXTM3U
#EXT-X-VERSION:3
#EXT-X-TARGETDURATION:10
#EXTINF:10.0,
seg0.ts
#EXTINF:10.0,
sub/seg1.ts
#EXTINF:10.0,
https://cdn.example.com/abs/seg2.ts
#EXT-X-ENDLIST
''';

    final segments = await M3U8Parser.parsePlaylist(
      content,
      'https://host.example.com/video/',
      Dio(),
      null,
      null,
    );

    expect(segments, [
      'https://host.example.com/video/seg0.ts',
      'https://host.example.com/video/sub/seg1.ts',
      'https://cdn.example.com/abs/seg2.ts',
    ]);
  });

  test('shouldCancel=true throws DownloadCancelledException', () async {
    expect(
      () => M3U8Parser.parsePlaylist(
        '#EXTINF:1,\nseg.ts\n',
        'https://x/',
        Dio(),
        null,
        () => true,
      ),
      throwsA(isA<DownloadCancelledException>()),
    );
  });
}
