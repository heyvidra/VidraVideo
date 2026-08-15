// Every error this app shows a person arrives as a snack bar. Left to
// Material's defaults the dark theme rendered white text on a white surface —
// the bar appeared, correctly sized, holding an invisible sentence, so a cast
// failure with a perfectly good explanation read as a silent one.
//
// The two roles behind that (`inverseSurface`, `onInverseSurface`) are the only
// ones AppTheme's ColorScheme does not name, which is exactly why nobody
// noticed. Contrast is asserted here rather than colours, so restyling stays
// free and only illegibility fails.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vidra/src/config/app_theme.dart';

/// [top] composited onto [bottom], both possibly translucent.
Color _over(Color top, Color bottom) {
  final a = top.a;
  return Color.from(
    alpha: 1,
    red: top.r * a + bottom.r * (1 - a),
    green: top.g * a + bottom.g * (1 - a),
    blue: top.b * a + bottom.b * (1 - a),
  );
}

/// WCAG relative luminance.
double _luminance(Color c) {
  double channel(double v) =>
      v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * channel(c.r) +
      0.7152 * channel(c.g) +
      0.0722 * channel(c.b);
}

double _contrast(Color a, Color b) {
  final la = _luminance(a);
  final lb = _luminance(b);
  final (hi, lo) = la > lb ? (la, lb) : (lb, la);
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  for (final (name, theme) in [
    ('dark', AppTheme.darkTheme),
    ('light', AppTheme.lightTheme),
  ]) {
    testWidgets('$name: an error snack bar is legible', (tester) async {
      final key = GlobalKey<ScaffoldMessengerState>();
      await tester.pumpWidget(
        MaterialApp(
          scaffoldMessengerKey: key,
          theme: theme,
          home: const Scaffold(body: SizedBox.expand()),
        ),
      );
      key.currentState!.showSnackBar(
        const SnackBar(content: Text('投屏失败')),
      );
      await tester.pumpAndSettle();

      final bar = tester.widget<Material>(
        find
            .descendant(
              of: find.byType(SnackBar),
              matching: find.byType(Material),
            )
            .first,
      );
      final label = find.text('投屏失败');
      final style =
          tester.widget<Text>(label).style ??
          DefaultTextStyle.of(tester.element(label)).style;

      // The bar can be translucent over the page, and the text over the bar.
      final page = theme.scaffoldBackgroundColor;
      final surface = _over(bar.color ?? page, page);
      final ink = _over(style.color ?? surface, surface);

      final ratio = _contrast(ink, surface);
      expect(
        ratio,
        greaterThanOrEqualTo(4.5),
        reason:
            '$name snack bar text ${style.color} on ${bar.color} '
            'is ${ratio.toStringAsFixed(2)}:1, below WCAG AA for body text',
      );
    });
  }
}
