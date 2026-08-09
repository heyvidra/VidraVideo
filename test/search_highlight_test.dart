// The search tile colours keyword matches inside the title. The split has to
// keep every character of the original title, match case-insensitively, and
// hand back a single unstyled span when there is nothing to highlight.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vidra/src/features/video/presentation/widgets/list/search_video_list_tile.dart';

void main() {
  const color = Colors.cyan;

  String joined(List<TextSpan> spans) => spans.map((s) => s.text).join();

  test('no keyword returns the title as one unstyled span', () {
    final spans = highlightKeyword('大奉打更人', '', color);
    expect(spans, hasLength(1));
    expect(spans.single.text, '大奉打更人');
    expect(spans.single.style, isNull);
  });

  test('match in the middle keeps all characters and styles only the match', () {
    final spans = highlightKeyword('大奉打更人', '打更', color);
    expect(joined(spans), '大奉打更人');
    expect(spans.map((s) => s.text).toList(), ['大奉', '打更', '人']);
    expect(spans[1].style?.color, color);
    expect(spans[0].style, isNull);
    expect(spans[2].style, isNull);
  });

  test('match at start and end, repeated', () {
    final spans = highlightKeyword('abcab', 'ab', color);
    expect(joined(spans), 'abcab');
    expect(spans.map((s) => s.style?.color).toList(), [color, null, color]);
  });

  test('case-insensitive match preserves original casing', () {
    final spans = highlightKeyword('The Matrix', 'matrix', color);
    expect(joined(spans), 'The Matrix');
    expect(spans.last.text, 'Matrix');
    expect(spans.last.style?.color, color);
  });

  test('no match returns the whole title unstyled', () {
    final spans = highlightKeyword('大奉打更人', '狂飙', color);
    expect(joined(spans), '大奉打更人');
    expect(spans.single.style, isNull);
  });
}
