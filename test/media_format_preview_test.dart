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
    final raw = jsonDecode(
      File('test/fixtures_youtube_formats.json').readAsStringSync(),
    ) as Map<String, dynamic>;
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
    final raw = jsonDecode(
      File('test/fixtures_youtube_formats.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final media = MediaInfo.fromJson(raw, 'https://example.test/watch');

    for (final f in media.formats.where((f) => f.formatId != '18')) {
      expect(f.isMuxed, isFalse, reason: '${f.formatId} has no audio stream');
    }
  });
}
