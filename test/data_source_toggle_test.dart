// Switching a data source off has to hide it everywhere without deleting
// anything, and — the part that can take the whole app down — it must never
// leave the catalog with no source at all. Every screen reaches for
// `sources.first`.

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vidra/src/data/database/app_database.dart' hide Video;
import 'package:vidra/src/data/database/app_database_provider.dart';
import 'package:vidra/src/features/settings/domain/app_settings.dart';
import 'package:vidra/src/features/video/data/video_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// A container standing where the app stands at launch: bootstrap has read
  /// the settings row and seeded the switched-off set, and the settings stream
  /// has not emitted yet. That first frame is the one this feature has to get
  /// right, so it is the one under test.
  ProviderContainer launchedWith(
    Set<String> disabled, {
    String activeId = kDefaultDataSourceId,
  }) {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        initialDisabledDataSourceIdsProvider.overrideWithValue(disabled),
        initialDataSourceIdProvider.overrideWithValue(activeId),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('stored form', () {
    test('round-trips, and empty is stored as null rather than ""', () {
      expect(formatSourceIds({}), isNull);
      expect(parseSourceIds(null), isEmpty);
      expect(parseSourceIds(''), isEmpty);
      expect(parseSourceIds(formatSourceIds({'yfsp', 'dbku'})), {
        'dbku',
        'yfsp',
      });
    });

    test('is canonical, so an unrelated settings write is not a change', () {
      // disabledDataSourceIdsProvider reads this through a riverpod `select`
      // that compares by value. An unstable order would look like a change on
      // every settings write and rebuild every data source — throwing away the
      // repository's request caches, which exist because the hosts rate-limit.
      expect(
        formatSourceIds({'yfsp', 'dbku'}),
        formatSourceIds({'dbku', 'yfsp'}),
      );
    });

    test('survives a hand-edited row', () {
      expect(parseSourceIds(' dbku , ,yfsp '), {'dbku', 'yfsp'});
    });
  });

  group('availableDataSourcesProvider', () {
    test('drops the switched-off source and keeps the rest', () {
      final c = launchedWith({'dbku'});
      final ids = c.read(availableDataSourcesProvider).map((s) => s.id);
      expect(ids, isNot(contains('dbku')));
      expect(ids, containsAll(['olevod', 'yfsp']));
      // The switch has to be able to bring it back, so the full list keeps it.
      expect(c.read(allDataSourcesProvider).map((s) => s.id), contains('dbku'));
    });

    test('ignores a set that would switch off everything', () {
      // Not reachable through the settings screen, which refuses the last
      // switch — but a hand-edited row, or a source id retired in an update,
      // could produce it. An app with no catalog is worse than an ignored
      // setting.
      // Enumerated from a bare container: allDataSourcesProvider only needs
      // dio, and opening a second database here would race the first.
      final bare = ProviderContainer();
      final everything = bare
          .read(allDataSourcesProvider)
          .map((s) => s.id)
          .toSet();
      bare.dispose();

      final c = launchedWith(everything);
      expect(c.read(availableDataSourcesProvider), isNotEmpty);
    });

    test('the active source moves off one that was switched off', () {
      // olevod is kDefaultDataSourceId and what a fresh install lands on.
      // Leaving the active id pointing at a hidden source shows an empty
      // catalog with no obvious way back, so the id has to move by itself.
      final c = launchedWith({kDefaultDataSourceId}, activeId: kDefaultDataSourceId);
      expect(c.read(activeDataSourceIdProvider), isNot(kDefaultDataSourceId));
      expect(c.read(activeDataSourceProvider).id, isNot(kDefaultDataSourceId));
    });
  });
}
