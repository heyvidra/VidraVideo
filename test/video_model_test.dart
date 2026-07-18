import 'package:flutter_test/flutter_test.dart';
import 'package:vidra/src/features/video/domain/video_collection.dart';

void main() {
  Video make() => const Video(
    apiId: 1,
    sourceId: 'olevod',
    title: 't',
    coverUrl: 'c',
    urls: [
      VideoEpisode(
        index: 0,
        title: 'ep1',
        qualities: [VideoQuality(name: 'HD', url: 'http://x/1.m3u8')],
      ),
    ],
  );

  test('value equality: separately built identical Videos are ==', () {
    expect(make(), equals(make()));
    expect(make().hashCode, make().hashCode);
  });

  test('copyWith changes one field, keeps the rest, never mutates', () {
    final a = make();
    final b = a.copyWith(id: 42);
    expect(b.id, 42);
    expect(b.title, a.title);
    expect(a.id, 0); // original untouched
    expect(a == b, isFalse);
  });

  test('episode url compat getter returns first quality url', () {
    expect(make().urls!.first.url, 'http://x/1.m3u8');
  });
}
