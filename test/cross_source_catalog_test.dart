// The source switcher used to be driven by the watch history, so a
// counterpart only existed once it had been played there — the offer appeared
// everywhere except the page you actually watched on. These tests pin the
// catalog-driven replacement: the same identity rule ([crossSourceKey]), but
// answered from rows that browsing alone leaves behind, and answered without
// touching the network (the sources ban IPs under request storms, and this
// runs on every detail page open).

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vidra/src/data/database/app_database.dart';
import 'package:vidra/src/data/database/app_database_provider.dart';
import 'package:vidra/src/features/video/data/cross_source_catalog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late CrossSourceCatalog catalog;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    catalog = CrossSourceCatalog(db);
  });

  tearDown(() => db.close());

  Future<void> cache({
    String? source,
    required int apiId,
    required String title,
    String? year,
  }) => db
      .into(db.videos)
      .insert(
        VideosCompanion.insert(
          sourceId: Value(source),
          apiId: apiId,
          title: title,
          coverUrl: '',
          rating: 0,
          year: Value(year),
          type: '连续剧',
        ),
      );

  test(
    'a show browsed on the other catalog is offered, before any playback',
    () async {
      await cache(source: 'olevod', apiId: 1, title: '兵自风中来', year: '2026');
      await cache(source: 'dbku', apiId: 88, title: '兵自风中来', year: '2026');

      final found = await catalog.counterpartsOf(
        title: '兵自风中来',
        year: '2026',
        excludeSourceId: 'olevod',
      );
      expect(found.single.sourceId, 'dbku');
      // The id ON THAT source. Ids are per-catalog, so opening the counterpart
      // with the page's own id would land on an unrelated show.
      expect(found.single.videoId, 88);
      expect(found.single.title, '兵自风中来');
      expect(found.single.year, '2026');
    },
  );

  test('the page never offers to switch to itself', () async {
    await cache(source: 'olevod', apiId: 1, title: '九门', year: '2026');

    expect(
      await catalog.counterpartsOf(
        title: '九门',
        year: '2026',
        excludeSourceId: 'olevod',
      ),
      isEmpty,
    );
    // Arriving without a source — from search, or a link with no ?sourceId= —
    // has nothing to exclude, so every cached catalog is a valid offer.
    expect(
      (await catalog.counterpartsOf(title: '九门', year: '2026')).single.sourceId,
      'olevod',
    );
  });

  test('a remake is not the show you are looking at', () async {
    // Titles repeat across decades. Matching on title alone would offer the
    // 1994 version as "the same show on dbku", and one tap later the user is
    // watching a different programme with no explanation on screen.
    await cache(source: 'dbku', apiId: 5, title: '九门', year: '1994');

    expect(
      await catalog.counterpartsOf(
        title: '九门',
        year: '2026',
        excludeSourceId: 'olevod',
      ),
      isEmpty,
    );
    // A year the caller does not know is its own identity, not a wildcard:
    // it must not silently absorb every dated edition of the title.
    expect(
      await catalog.counterpartsOf(title: '九门', excludeSourceId: 'olevod'),
      isEmpty,
    );
  });

  test('spacing and case differences do not hide the counterpart', () async {
    // The two catalogs are scraped from different HTML and disagree about
    // padding and capitalisation far more often than about the title itself.
    await cache(
      source: 'dbku',
      apiId: 7,
      title: '  The  Long   River ',
      year: '2026',
    );

    final found = await catalog.counterpartsOf(
      title: 'the long river',
      year: '2026',
      excludeSourceId: 'olevod',
    );
    expect(found.single.videoId, 7);
    // What the switcher renders is what THAT catalog calls the show, not the
    // normalised form the match was made on.
    expect(found.single.title, '  The  Long   River ');
  });

  test('one entry per source, newest cached first', () async {
    // `videos_idx` makes (sourceId, apiId) unique, so a source duplicates
    // itself only by re-listing the show under a second id — which both
    // catalogs do. Two buttons for one catalog is a bug the user can see.
    await cache(source: 'dbku', apiId: 5, title: '江海潮生', year: '2026');
    await cache(source: 'other', apiId: 6, title: '江海潮生', year: '2026');
    await cache(source: 'dbku', apiId: 55, title: '江海潮生', year: '2026');

    final found = await catalog.counterpartsOf(
      title: '江海潮生',
      year: '2026',
      excludeSourceId: 'olevod',
    );
    expect(found.map((e) => e.sourceId), ['dbku', 'other']);
    // Of the two dbku rows, the one cached most recently is the one the
    // switcher opens — the stale id is the more likely to 404.
    expect(found.first.videoId, 55);
  });

  test('the most recently discovered catalog is offered first', () async {
    // Deliberately arranged so the expected order is neither insertion order
    // nor alphabetical: the assertion in the dedup test above holds under both
    // of those, so on its own it would not notice the ordering being dropped.
    // Which button sits first is what the user's thumb lands on, and the
    // catalog they last browsed the show on is the one still in front of them.
    await cache(source: 'zzz', apiId: 1, title: '风起洛阳', year: '2026');
    await cache(source: 'aaa', apiId: 2, title: '风起洛阳', year: '2026');

    final found = await catalog.counterpartsOf(
      title: '风起洛阳',
      year: '2026',
      excludeSourceId: 'olevod',
    );
    expect(found.map((e) => e.sourceId), ['aaa', 'zzz']);
  });

  test('rows with no source are skipped', () async {
    // Opening one needs a source to resolve the id against, so an entry that
    // cannot be navigated to is worse than no entry at all.
    await cache(apiId: 3, title: '孤舟', year: '2026');

    expect(await catalog.counterpartsOf(title: '孤舟', year: '2026'), isEmpty);
  });

  test('an evicted catalog row takes the offer with it', () async {
    // `HistoryRepository.deleteVideoHistory` deletes the `videos` row next to
    // the history row, and `clearAllHistory` empties the table, so removing a
    // show from "Recent" on one catalog silently retracts the switcher button
    // on the other. This module has exactly one source of truth and must not
    // grow a history-table fallback to hide that — the fallback is the
    // backwards behaviour it exists to replace. Pinned so the widget layer
    // treats an empty list as "nothing cached", not as "no counterpart exists".
    await cache(source: 'dbku', apiId: 88, title: '长风渡', year: '2026');
    await db.delete(db.videos).go();

    expect(
      await catalog.counterpartsOf(
        title: '长风渡',
        year: '2026',
        excludeSourceId: 'olevod',
      ),
      isEmpty,
    );
  });

  // The detail page reaches this through the provider, never through the class
  // directly, and the family argument is three same-shaped fields — two
  // nullable strings either side of a title. A swapped `year`/`sourceId` still
  // type-checks and still returns a plausible-looking list, so the wiring is
  // pinned here rather than left to the widget layer to discover.
  test('the provider excludes the page it was asked from', () async {
    await cache(source: 'olevod', apiId: 1, title: '雪中悍刀行', year: '2026');
    await cache(source: 'dbku', apiId: 88, title: '雪中悍刀行', year: '2026');
    await cache(source: 'dbku', apiId: 99, title: '雪中悍刀行', year: '1994');

    final container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );
    addTearDown(container.dispose);

    final found = await container.read(
      crossSourceCounterpartsProvider((
        title: '雪中悍刀行',
        year: '2026',
        sourceId: 'olevod',
      )).future,
    );
    expect(found.single.sourceId, 'dbku');
    // 99 is the newer row and would win on ordering alone; it loses on year,
    // which is what proves the year actually reached [counterpartsOf].
    expect(found.single.videoId, 88);
  });
}
