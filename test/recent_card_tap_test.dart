// 最近播放 hands its cards a play callback, and for a while that callback owned
// the WHOLE poster: a tap anywhere resumed playback, and the episode list was
// reachable only through a small pill in the hover overlay. It is the other way
// round now — the poster opens the detail page like every other card in the
// app, and the play ring is the one thing that resumes.
//
// Neither direction fails to compile, and no other test notices the swap, so
// the routing is pinned here.

import 'package:drift/native.dart';
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:vidra/src/data/database/app_database.dart' hide Video;
import 'package:vidra/src/data/database/app_database_provider.dart';
import 'package:vidra/src/features/video/data/video_repository.dart';
import 'package:vidra/src/features/video/domain/video_collection.dart';
import 'package:vidra/src/features/video/presentation/widgets/cards/popular_video_card.dart';

final _video = Video(
  apiId: 83579,
  sourceId: kDefaultDataSourceId,
  title: '九门',
  coverUrl: '',
  type: '连续剧',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() async => db.close());

  /// Mounts one card. [onTap] present is a 最近播放 card with somewhere to
  /// resume to; absent is the catalog, favourites and subscriptions.
  Future<({List<String> opened, int Function() plays})> pump(
    WidgetTester tester, {
    bool resumable = true,
  }) async {
    var plays = 0;
    // Recorded where the detail page actually builds: `context.push` is an
    // imperative push, which the router's currentConfiguration does not
    // reflect, so asking the destination itself is the unambiguous answer.
    final opened = <String>[];
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => Scaffold(
            body: Center(
              child: SizedBox(
                width: 220,
                height: 320,
                child: PopularVideoCard(
                  video: _video,
                  onTap: resumable ? () => plays++ : null,
                ),
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/detail/:id',
          builder: (_, state) {
            opened.add(state.uri.toString());
            return const Scaffold(body: Text('detail'));
          },
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          initialDataSourceIdProvider.overrideWithValue(kDefaultDataSourceId),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    return (opened: opened, plays: () => plays);
  }

  /// The overlay — play ring included — only exists while the pointer is over
  /// the card, so every tap on it has to arrive behind a real hover.
  Future<void> hover(WidgetTester tester) async {
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    addTearDown(mouse.removePointer);
    await mouse.moveTo(tester.getCenter(find.byType(PopularVideoCard)));
    await tester.pumpAndSettle();
  }

  testWidgets('tapping the poster opens the detail page, it does not play', (
    tester,
  ) async {
    final probe = await pump(tester);

    // Low on the card, clear of the play ring at Alignment(0, -0.35).
    final card = tester.getRect(find.byType(PopularVideoCard));
    await tester.tapAt(Offset(card.center.dx, card.bottom - 20));
    await tester.pumpAndSettle();

    expect(probe.plays(), 0, reason: 'the poster must not start playback');
    expect(probe.opened, ['/detail/83579?sourceId=olevod']);
  });

  testWidgets('tapping the play ring plays, it does not open the detail page', (
    tester,
  ) async {
    final probe = await pump(tester);
    await hover(tester);

    await tester.tap(find.byIcon(Icons.play_arrow_rounded));
    await tester.pumpAndSettle();

    expect(probe.plays(), 1);
    expect(
      probe.opened,
      isEmpty,
      reason: 'the ring resumes in the player window, it does not navigate',
    );
  });

  testWidgets('a card with nothing to resume follows the poster', (
    tester,
  ) async {
    final probe = await pump(tester, resumable: false);
    await hover(tester);

    await tester.tap(find.byIcon(Icons.play_arrow_rounded));
    await tester.pumpAndSettle();

    expect(probe.opened, ['/detail/83579?sourceId=olevod']);
  });
}
