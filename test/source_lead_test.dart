// The source pill claimed dbku was "快 9 小时" while olevod was the catalog
// that had posted episode 16 nine hours EARLIER. The bug was reading a newer
// timestamp as "faster": at the same episode count, the newer row is the one
// that only just caught up.
//
// The field case is the first test, with the real shape of that afternoon:
// both catalogs at 16 episodes, olevod stamped nine hours before dbku.

import 'package:flutter_test/flutter_test.dart';
import 'package:vidra/src/features/video/domain/source_lead.dart';

const _hour = 3600;

void main() {
  test('same count: the OLDER row got there first', () {
    // olevod, measured against dbku as the reference.
    final lead = compareSourceRows(
      ourEpisodes: 16,
      theirEpisodes: 16,
      ourVodTime: 1000 * _hour,
      theirVodTime: 1009 * _hour,
    );

    expect(lead.episodeDelta, isNull, reason: 'counts agree, so no delta');
    expect(lead.arrivedEarlierBy, const Duration(hours: 9));
    expect(
      lead.arrivedEarlierBy!.isNegative,
      isFalse,
      reason: 'olevod was first; it must not read as the slow one',
    );
  });

  test('same count, the other way round', () {
    final lead = compareSourceRows(
      ourEpisodes: 16,
      theirEpisodes: 16,
      ourVodTime: 1009 * _hour,
      theirVodTime: 1000 * _hour,
    );
    expect(lead.arrivedEarlierBy, const Duration(hours: -9));
  });

  test('different counts: the delta is the whole answer', () {
    final lead = compareSourceRows(
      ourEpisodes: 16,
      theirEpisodes: 15,
      ourVodTime: 1009 * _hour,
      theirVodTime: 1000 * _hour,
    );

    expect(lead.episodeDelta, 1);
    // A timestamp claim on top of a count difference is the contradiction
    // this whole file exists to prevent: one episode ahead but "9 小时慢".
    expect(lead.arrivedEarlierBy, isNull);
  });

  test('a catalog that does not stamp its rows makes no claim', () {
    expect(
      compareSourceRows(
        ourEpisodes: 16,
        theirEpisodes: 16,
        ourVodTime: 0,
        theirVodTime: 1000 * _hour,
      ).isEmpty,
      isTrue,
    );
    expect(
      compareSourceRows(
        ourEpisodes: 16,
        theirEpisodes: 16,
        ourVodTime: null,
        theirVodTime: null,
      ).isEmpty,
      isTrue,
    );
  });

  test('identical rows say nothing at all', () {
    expect(
      compareSourceRows(
        ourEpisodes: 16,
        theirEpisodes: 16,
        ourVodTime: 1000 * _hour,
        theirVodTime: 1000 * _hour,
      ).isEmpty,
      isTrue,
    );
  });
}
