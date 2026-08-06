// The card's right-click menu could only be dismissed by clicking inside the
// grid: tapping the sidebar, the toolbar, or anything else outside the shell's
// content area left it hanging. It opened offset for the same reason.
//
// Both come from which overlay the entry lands in. Inside a ShellRoute the
// NEAREST overlay belongs to the shell's own Navigator and covers only the
// content area, so `Positioned.fill` — the dismiss barrier — stopped at the
// sidebar, and the anchor was measured against the wrong origin.
//
// This test rebuilds that shape: an app whose content area is a nested
// Navigator inset by a 200px sidebar.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vidra/src/common/dropdown_menu.dart';

const _sidebar = 200.0;

/// A sidebar beside a nested Navigator — the shell layout, minus go_router.
Widget _shell({required ValueChanged<BuildContext> onContent}) {
  return MaterialApp(
    home: Row(
      children: [
        const SizedBox(width: _sidebar, child: ColoredBox(color: Colors.grey)),
        Expanded(
          child: Navigator(
            onGenerateRoute: (settings) => MaterialPageRoute<void>(
              builder: (context) {
                onContent(context);
                return const SizedBox.expand();
              },
            ),
          ),
        ),
      ],
    ),
  );
}

void main() {
  testWidgets('a tap on the sidebar closes the menu', (tester) async {
    late BuildContext content;
    await tester.pumpWidget(_shell(onContent: (c) => content = c));

    // Never awaited: against the old nested overlay the tap below does not
    // dismiss, so this future would never complete and the test would hang
    // instead of failing. The panel leaving the tree is the real assertion.
    var dismissed = false;
    unawaited(
      showVidraMenu<String>(
        context: content,
        globalPosition: const Offset(400, 300),
        builder: (context, select) => [
          PlayerMenuItem(text: '播放', onTap: () => select('play')),
        ],
      ).then((v) => dismissed = v == null),
    );
    await tester.pumpAndSettle();

    expect(find.text('播放'), findsOneWidget);

    // Well inside the sidebar — the region the old barrier never covered.
    await tester.tapAt(const Offset(80, 300));
    await tester.pumpAndSettle();

    expect(find.text('播放'), findsNothing);
    expect(dismissed, isTrue);
  });

  // ponytail: no position test here. Inserting into the shell's overlay
  // subtracts the sidebar from the anchor AND adds it back when the entry
  // renders, so a synthetic shell cannot tell the two overlays apart by
  // position — only by how far the barrier reaches.

  testWidgets('picking an item still returns its value', (tester) async {
    late BuildContext content;
    await tester.pumpWidget(_shell(onContent: (c) => content = c));

    String? got;
    unawaited(
      showVidraMenu<String>(
        context: content,
        globalPosition: const Offset(400, 300),
        builder: (context, select) => [
          PlayerMenuItem(text: '播放', onTap: () => select('play')),
        ],
      ).then((v) => got = v),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('播放'));
    await tester.pumpAndSettle();

    expect(got, 'play');
    expect(find.text('播放'), findsNothing);
  });
}

void unawaited(Future<void> _) {}
