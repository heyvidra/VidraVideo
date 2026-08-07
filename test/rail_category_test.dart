// The rail's highlight is stored as a bare category id, and ids are only
// meaningful inside the catalog that issued them. Switching source used to
// keep the old id: the new catalog either had no row with it (nothing lit, and
// 首页 stayed dark too) or had a different row with it (the wrong one lit),
// while the grid had already reset to the new catalog's first category. This
// pins the reset.

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vidra/src/data/database/app_database.dart';
import 'package:vidra/src/data/database/app_database_provider.dart';
import 'package:vidra/src/features/dashboard/widgets/sidebar.dart';
import 'package:vidra/src/features/video/data/video_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late ProviderContainer container;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        initialDataSourceIdProvider.overrideWithValue(kDefaultDataSourceId),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  test('switching source drops a pick made in the old catalog', () async {
    final sources = container.read(availableDataSourcesProvider);
    final other = sources.firstWhere((s) => s.id != kDefaultDataSourceId);

    container.read(railCategoryProvider.notifier).state = 42;
    expect(container.read(railCategoryProvider), 42);

    await container.read(activeDataSourceIdProvider.notifier).setSource(
      other.id,
    );

    expect(container.read(railCategoryProvider), isNull);
  });

  test('a pick survives everything else', () async {
    container.read(railCategoryProvider.notifier).state = 42;
    // Reading unrelated state must not reset the rail — only the source does.
    container.read(activeDataSourceProvider);
    expect(container.read(railCategoryProvider), 42);
  });
}
