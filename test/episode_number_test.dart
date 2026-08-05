// One show, two catalogs, two ways of writing the same episode.
//
// olevod ships 第1集 … 第14集; dbku ships 第01集 … 第15集 for the same title.
// Joining those lists by array position moves progress a whole instalment once
// the counts differ, so the join has to run on the number in the title — and
// where no number is stated (a film's 立即播放 / 粤语播放 lines) the join has to
// be refused, not guessed.

import 'package:flutter_test/flutter_test.dart';
import 'package:vidra/src/features/video/domain/episode_number.dart';

int? num_(String? title, {int index = 0, bool episodic = true}) =>
    episodeNumberOf(title, index: index, episodic: episodic);

void main() {
  test('padding is not a difference between two sources', () {
    expect(num_('第01集'), 1);
    expect(num_('第1集'), 1);
    expect(episodeLabel('第01集', index: 0), '第1集');
    expect(episodeLabel('第1集', index: 0), '第1集');
    expect(episodeLabel('第007集', index: 0), '第7集');
  });

  test('the lists join on the number even when the rows do not line up', () {
    // The two catalogs are deliberately OFFSET here, because index-aligned
    // fixtures cannot fail: a stub that ignored the title and answered
    // `index + 1` satisfies every assertion when row i is episode i+1 on both
    // sides, which is exactly the broken mapping this module exists to replace.
    // dbku files a trailer ahead of episode 1 and carries one instalment more,
    // so its array positions run a step behind olevod's the whole way down.
    final olevod = [for (var i = 1; i <= 14; i++) '第$i集'];
    final dbku = [
      '预告',
      for (var i = 1; i <= 15; i++) '第${i.toString().padLeft(2, '0')}集',
    ];

    for (var i = 0; i < olevod.length; i++) {
      expect(num_(olevod[i], index: i), i + 1, reason: 'olevod row $i');
      // Same episode, one row further down, and written with padding.
      expect(
        num_(dbku[i + 1], index: i + 1),
        num_(olevod[i], index: i),
        reason: 'olevod row $i is dbku row ${i + 1}',
      );
      // Which is also what the viewer reads on the tile, on both pages.
      expect(
        episodeLabel(dbku[i + 1], index: i + 1),
        episodeLabel(olevod[i], index: i),
        reason: 'both pages must print the same thing for row $i',
      );
    }

    // Joining these two by array position instead would hand the viewer the
    // previous instalment on every single row.
    for (var i = 0; i < olevod.length; i++) {
      expect(num_(dbku[i], index: i), isNot(num_(olevod[i], index: i)));
    }
    // The trailer at the head of dbku is not episode 1 just because it sits
    // where episode 1 sits, and dbku's extra instalment has no counterpart.
    expect(num_(dbku.first, index: 0), isNull);
    expect(num_(dbku.last, index: 15), 15);
  });

  test('the unit is written four ways', () {
    expect(num_('第3話'), 3);
    expect(num_('第3话'), 3);
    expect(num_('第3期'), 3);
    expect(num_('第3集'), 3);
    // …and the parts are not always tight against each other.
    expect(num_('第 12 集'), 12);
    // The unit is normalised away too, not just the padding: a catalog that
    // counts in 話 and one that counts in 集 have to print one word, or the
    // two detail pages go on looking like two different shows.
    expect(episodeLabel('第3話', index: 0), '第3集');
    expect(episodeLabel('第3话', index: 0), '第3集');
    expect(episodeLabel('第3期', index: 0), '第3集');
    expect(episodeLabel('第 12 集', index: 0), '第12集');
  });

  test('EP form, either case, with or without a gap', () {
    expect(num_('EP12'), 12);
    expect(num_('ep 12'), 12);
    expect(num_('Ep.7'), 7);
    expect(episodeLabel('EP12', index: 3), '第12集');
  });

  test('a bare number counts only as the whole title', () {
    expect(num_('12'), 12);
    expect(num_('01'), 1);
    // A source that files nothing but digits still gets the same tile wording
    // as the source that spells it out.
    expect(episodeLabel('12', index: 0), '第12集');
    expect(episodeLabel('01', index: 0), '第1集');
    // Otherwise a resolution or a year becomes an episode number.
    expect(num_('1080P'), isNull);
    expect(num_('2026 抢先版'), isNull);
    expect(episodeLabel('1080P', index: 0), '1080P');
  });

  test('full-width digits are the same digits', () {
    expect(num_('第１２集'), 12);
    expect(num_('１２'), 12);
    expect(episodeLabel('第０１集', index: 0), '第1集');
  });

  test('a film\'s playback lines are not episodes', () {
    // These sit in the same episode list as real instalments. Numbering them by
    // position would join 粤语播放 on one source to 第2集 on the other.
    for (final name in ['立即播放', '粤语播放', '英语播放', 'HD', '抢先版', '预告']) {
      expect(num_(name, index: 1), isNull, reason: name);
      // And the tile keeps saying what the source said.
      expect(episodeLabel(name, index: 1), name, reason: name);
    }
  });

  test('第0集 is refused rather than handed back as a 1-based number', () {
    expect(num_('第0集'), isNull);
    expect(num_('0'), isNull);
  });

  test('a blank title falls back to its position, but only for a series', () {
    expect(num_(null, index: 0), 1);
    expect(num_('', index: 3), 4);
    expect(num_('   ', index: 3), 4);
    expect(num_(null, index: 3, episodic: false), isNull);
    expect(episodeLabel(null, index: 3), '第4集');
    expect(episodeLabel('  ', index: 0), '第1集');
  });

  test('a film never yields a number, however its lines are named', () {
    // No sequence to align: its list entries are audio tracks and mirrors, so
    // even one that parses must not become a join key.
    expect(num_('第1集', episodic: false), isNull);
    expect(num_('EP2', index: 1, episodic: false), isNull);
    expect(num_('立即播放', episodic: false), isNull);
    // The label is a separate question — it still renders whatever is there.
    expect(episodeLabel('立即播放', index: 0), '立即播放');
  });

  test('trailing decoration does not hide the episode', () {
    expect(num_('第12集(粤语)'), 12);
    expect(episodeLabel('第12集 抢先版', index: 0), '第12集');
  });
}
