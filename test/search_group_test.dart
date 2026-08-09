// Cross-source search folds per-catalog result lists into one list of shows.
// The current source's relevance order must survive the fold, the same show
// on two catalogs must become ONE tile, and a remake reusing a title must
// not — the identity is title + year, the watch badge's rule.

import 'package:flutter_test/flutter_test.dart';
import 'package:vidra/src/features/video/domain/search_hit.dart';
import 'package:vidra/src/features/video/domain/video_collection.dart';

Video v(
  String title, {
  String source = 'olevod',
  String? year = '2026',
  int id = 1,
}) => Video(
  apiId: id,
  sourceId: source,
  title: title,
  coverUrl: '',
  type: '陆剧',
  year: year,
);

void main() {
  test('the same show on two catalogs becomes one hit', () {
    final hits = groupSearchResults([
      [v('九门', source: 'dbku', id: 148599)],
      [v('九门', source: 'olevod', id: 83164)],
    ]);
    expect(hits, hasLength(1));
    expect(hits.single.primary.sourceId, 'dbku');
    expect(hits.single.others.single.sourceId, 'olevod');
  });

  test('current-source order survives; other-source-only shows append', () {
    final hits = groupSearchResults([
      [v('甲', id: 1), v('乙', id: 2)],
      [v('乙', source: 'dbku', id: 20), v('丙', source: 'dbku', id: 30)],
    ]);
    expect(hits.map((h) => h.primary.title).toList(), ['甲', '乙', '丙']);
    expect(hits[1].others, hasLength(1));
    expect(hits[2].primary.sourceId, 'dbku');
  });

  test('a remake reusing the title is a separate show', () {
    final hits = groupSearchResults([
      [v('神雕侠侣', year: '2006')],
      [v('神雕侠侣', source: 'dbku', year: '2014')],
    ]);
    expect(hits, hasLength(2));
  });

  test('no source answering means no hits', () {
    expect(groupSearchResults([[], []]), isEmpty);
  });
}
