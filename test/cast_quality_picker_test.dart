// The cast picker offers the show's lines only when there is a choice, and
// tapping one changes what the cast will be sent on.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:vidra/src/config/app_theme.dart';
import 'package:vidra/src/features/cast/presentation/cast_button.dart';
import 'package:vidra/src/features/cast/presentation/cast_provider.dart';
import 'package:vidra_cast/vidra_cast.dart';

Future<void> _pump(
  WidgetTester tester,
  List<String> qualities,
  ValueNotifier<String?> quality,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        castDevicesProvider.overrideWith(
          (ref) => Stream.value(const <CastDevice>[]),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(
          body: CastButton.pickerForTest(
            qualities: qualities,
            quality: quality,
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('two lines are offered, and a tap selects one', (tester) async {
    final quality = ValueNotifier<String?>('标清');
    await _pump(tester, const ['标清', '高清'], quality);

    expect(find.text('标清'), findsOneWidget);
    expect(find.text('高清'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('高清'));
    await tester.pump();
    expect(quality.value, '高清');

    // Timers: the picker polls while it is open.
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a show with one line gets no quality row', (tester) async {
    final quality = ValueNotifier<String?>(null);
    await _pump(tester, const [], quality);
    expect(find.text('cast.quality'), findsNothing);
    expect(find.text('标清'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });
}
