// The episode grid must be LAZY. It used to be a Wrap inside a
// SliverToBoxAdapter, which builds and lays out every episode at once — on a
// 150-episode variety show that alone was the detail page's scroll jank
// (compounded by a per-tile FutureBuilder re-querying the database on every
// rebuild). This pins both properties: the sliver protocol holds all the way
// down, and off-viewport tiles simply do not exist.

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vidra/src/data/database/app_database.dart' hide Video;
import 'package:vidra/src/data/database/app_database_provider.dart';
import 'package:vidra/src/features/video/data/video_repository.dart';
import 'package:vidra/src/features/video/domain/video_collection.dart';
import 'package:vidra/src/features/video/presentation/widgets/detail/episode_item.dart';
import 'package:vidra/src/features/video/presentation/widgets/detail/episode_section.dart';

Video _show(int episodes) => Video(
  apiId: 7,
  sourceId: kDefaultDataSourceId,
  title: '试播剧',
  coverUrl: '',
  type: '综艺',
  urls: [
    for (var i = 0; i < episodes; i++)
      VideoEpisode(index: i, title: '2026060${i % 10}(第$i期)'),
  ],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> pump(WidgetTester tester, Video video) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          initialDataSourceIdProvider.overrideWithValue(kDefaultDataSourceId),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: EpisodeSection(
              video: video,
              isAscending: ValueNotifier(true),
              isDownloadMode: ValueNotifier(false),
              selectedSource: ValueNotifier(null),
              lastRefresh: ValueNotifier(null),
              showComparison: ValueNotifier(false),
            ),
          ),
        ),
      ),
    );
    // First frame shows the skeleton while histories load; settle to the grid.
    await tester.pumpAndSettle();
  }

  testWidgets('off-viewport episodes are never built', (tester) async {
    await pump(tester, _show(150));

    final built = tester.widgetList(find.byType(EpisodeItem)).length;
    expect(built, greaterThan(0));
    // The 800px test viewport fits a handful of 88px rows plus the cache
    // extent — nowhere near 150. If this creeps toward the full count, the
    // grid has gone eager again.
    expect(built, lessThan(100));
  });

  testWidgets('scrolling to the end reaches the last episode', (tester) async {
    await pump(tester, _show(150));

    final scrollable = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(
      find.text('20260609(第149期)', findRichText: true),
      600,
      scrollable: scrollable,
    );
    expect(find.text('20260609(第149期)', findRichText: true), findsOneWidget);
  });
}
