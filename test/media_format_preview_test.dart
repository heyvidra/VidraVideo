// The preview button picks a format that plays without muxing. This checks the
// path it depends on against REAL extractor output — the button vanished on a
// link that had just played, and the JSON turned out to carry everything it
// needed, which put the fault in the mapping rather than the library.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:vidra/src/features/download/domain/media_info.dart';

void main() {
  test('a real muxed format survives parsing with its url', () {
    final raw =
        jsonDecode(
              File('test/fixtures_youtube_formats.json').readAsStringSync(),
            )
            as Map<String, dynamic>;
    final media = MediaInfo.fromJson(raw, 'https://example.test/watch');

    expect(media.formats, hasLength(3));

    final muxed = media.muxedFormats;
    expect(muxed, hasLength(1), reason: 'itag 18 carries both codecs');
    expect(muxed.single.formatId, '18');
    expect(muxed.single.height, 640);
    // The whole point: without the address there is nothing to hand the player.
    expect(muxed.single.url, isNotNull);
    expect(muxed.single.url, isNotEmpty);
  });

  test('video-only formats are not offered as playable', () {
    final raw =
        jsonDecode(
              File('test/fixtures_youtube_formats.json').readAsStringSync(),
            )
            as Map<String, dynamic>;
    final media = MediaInfo.fromJson(raw, 'https://example.test/watch');

    for (final f in media.formats.where((f) => f.formatId != '18')) {
      expect(f.isMuxed, isFalse, reason: '${f.formatId} has no audio stream');
    }
  });

  test('a progressive file with no codec info is still playable alone', () {
    // Bilibili's `durl` fallback: one file carrying both streams, described
    // with no codecs at all. Requiring both to be STATED read that silence as
    // "not muxed" and disabled the preview on every Bilibili link.
    final media = MediaInfo.fromJson({
      'formats': [
        {
          'format_id': 'flv-0',
          'ext': 'flv',
          'url': 'https://example.test/whole.flv',
          'height': 480,
        },
      ],
    }, 'https://example.test/video');

    final f = media.formats.single;
    expect(
      f.isMuxed,
      isFalse,
      reason: 'nothing is stated, so nothing is known',
    );
    expect(f.isPlayableAlone, isTrue, reason: 'but it is still one file');
  });

  test('an adaptive stream is never offered, stated codecs or not', () {
    // The half-a-file case is the one an extractor is certain about, which is
    // why the negative test is the reliable one.
    final media = MediaInfo.fromJson({
      'formats': [
        {'format_id': 'v', 'ext': 'm4s', 'url': 'u', 'vcodec': 'avc1'},
        {'format_id': 'a', 'ext': 'm4s', 'url': 'u', 'acodec': 'mp4a'},
      ],
    }, 'https://example.test/video');

    for (final f in media.formats) {
      expect(f.isPlayableAlone, isFalse, reason: f.formatId);
    }
  });
}
