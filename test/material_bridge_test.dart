// The app is on package:material_ui; a few third-party packages still build
// with package:flutter/material.dart. The two are separate class hierarchies,
// so each side has to find its own Theme and its own MaterialLocalizations —
// and nothing but running a widget tree shows whether it does. The analyzer
// and every other test in this suite were green with the built-in labels
// falling back to English.

// The old library is the thing under test here.
// ignore: deprecated_member_use
import 'package:flutter/material.dart' as legacy;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:vidra/src/common/material_bridge.dart';

void main() {
  testWidgets('both Material libraries get the theme and Chinese labels', (
    tester,
  ) async {
    const seed = Color(0xFF12B5CB);
    late String modernCancel;
    late String legacyCancel;
    late Color modernPrimary;
    late Color legacyPrimary;
    late Brightness legacyBrightness;

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('zh'),
        supportedLocales: const [Locale('zh'), Locale('en')],
        // What appLocalizationsDelegates adds to easy_localization's own.
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: seed,
            brightness: Brightness.dark,
          ),
        ),
        builder: (context, child) => legacyMaterialBridge(child!),
        home: Builder(
          builder: (context) {
            modernCancel = MaterialLocalizations.of(context).cancelButtonLabel;
            modernPrimary = Theme.of(context).colorScheme.primary;
            legacyCancel = legacy.MaterialLocalizations.of(
              context,
            ).cancelButtonLabel;
            final old = legacy.Theme.of(context);
            legacyPrimary = old.colorScheme.primary;
            legacyBrightness = old.brightness;
            // A legacy widget that needs a legacy Material ancestor's theme.
            return const legacy.Card(child: legacy.Text('x'));
          },
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(modernCancel, '取消');
    expect(legacyCancel, '取消');
    expect(legacyPrimary, modernPrimary);
    expect(legacyBrightness, Brightness.dark);
  });
}
