// The one rule of the search-history list: newest first, no duplicates,
// bounded. Re-searching an old keyword must promote it, not double it.

import 'package:flutter_test/flutter_test.dart';
import 'package:vidra/src/features/video/presentation/search_history_provider.dart';

void main() {
  test('a new keyword lands at the front', () {
    expect(pushKeyword(['乙', '丙'], '甲'), ['甲', '乙', '丙']);
  });

  test('re-searching promotes rather than duplicates', () {
    expect(pushKeyword(['甲', '乙', '丙'], '丙'), ['丙', '甲', '乙']);
  });

  test('the list is capped, dropping the oldest', () {
    final ten = List.generate(10, (i) => 'k$i');
    final next = pushKeyword(ten, '新');
    expect(next, hasLength(10));
    expect(next.first, '新');
    expect(next.contains('k9'), isFalse);
  });

  test('whitespace-only input changes nothing', () {
    expect(pushKeyword(['甲'], '   '), ['甲']);
  });

  test('input is trimmed before it is remembered', () {
    expect(pushKeyword(const [], ' 九门 '), ['九门']);
  });
}
