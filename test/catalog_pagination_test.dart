// A page that fails must not end the catalog. Before 1.16.8 it did so
// silently; since then the footer says so and offers a retry, and that path
// had never been run by anything but reading the code. These pin what the
// footer and the scroll listener rely on: the rows already loaded survive a
// failed page, the error is visible while it stands, and one successful
// retry clears it and picks up at the page that failed.

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:vidra/src/data/database/app_database.dart' show AppDatabase;
import 'package:vidra/src/data/database/app_database_provider.dart';
import 'package:vidra/src/features/video/data/video_repository.dart';
import 'package:vidra/src/features/video/domain/category.dart';
import 'package:vidra/src/features/video/domain/video_collection.dart';
import 'package:vidra/src/features/video/presentation/video_list_provider.dart';

class _FlakyRepository implements VideoRepository {
  /// Pages asked for, in order.
  final asked = <int>[];
  bool failNext = false;

  @override
  Future<List<Category>> getCategories() async => const [
    Category(id: 1, name: '电影'),
  ];

  @override
  Future<Map<String, dynamic>> fetchVideos({
    required int categoryId,
    int? subTypeId,
    String? area,
    String? year,
    int page = 1,
    bool forceRefresh = false,
  }) async {
    asked.add(page);
    if (failNext) {
      failNext = false;
      throw Exception('page $page did not load');
    }
    return {
      'list': [
        for (var i = 0; i < 3; i++)
          Video(
            apiId: page * 10 + i,
            title: 'p$page-$i',
            coverUrl: '',
            sourceId: 'demo',
          ),
      ],
    };
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a failed page keeps the rows, shows the error, and retries', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = _FlakyRepository();
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        videoRepositoryProvider.overrideWithValue(repo),
      ],
    );
    addTearDown(container.dispose);

    // Categories first: the list rebuilds (and reloads) when the filter
    // settles on one, and the assertions below want that behind them.
    await container.read(categoriesProvider.future);
    final sub = container.listen(videoListProvider, (_, _) {});
    addTearDown(sub.close);
    Future<void> settle() => Future<void>.delayed(Duration.zero);
    await settle();
    await settle();

    final first = container.read(videoListProvider);
    expect(first.videos, hasLength(3));
    expect(first.error, isNull);
    final failingPage = first.page;

    repo.failNext = true;
    await container.read(videoListProvider.notifier).loadNextPage();
    final failed = container.read(videoListProvider);
    expect(failed.videos, hasLength(3), reason: 'loaded rows must survive');
    expect(failed.error, isNotNull);
    expect(failed.isLoading, isFalse);
    expect(failed.hasMore, isTrue, reason: 'a failure is not the end');

    await container.read(videoListProvider.notifier).loadNextPage();
    final retried = container.read(videoListProvider);
    expect(retried.error, isNull, reason: 'success clears the error');
    expect(retried.videos, hasLength(6));
    expect(
      repo.asked.where((p) => p == failingPage),
      hasLength(2),
      reason: 'the retry asks for the page that failed, not the one after',
    );
  });
}
