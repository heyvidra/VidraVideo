// The checker is the only layer of the subscription feature that spends
// requests, and every rule here fails SILENTLY when broken: delete the
// per-run cap and the app still works — it just fires a request per followed
// show at every launch, and the first symptom is the source rate-limiting us.
// So the request budget is asserted directly, by counting.

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vidra/src/data/database/app_database.dart' show AppDatabase;
import 'package:vidra/src/features/subscription/data/subscription_checker.dart';
import 'package:vidra/src/features/subscription/data/subscription_repository.dart';
import 'package:vidra/src/features/subscription/domain/subscription.dart';
import 'package:vidra/src/features/video/domain/video_collection.dart';

Video show({
  required int id,
  String source = 'olevod',
  String title = '剧',
  String? remarks,
}) => Video(
  apiId: id,
  sourceId: source,
  title: title,
  coverUrl: '',
  rating: 0,
  type: '陆剧',
  year: '2026',
  remarks: remarks,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late SubscriptionRepository repo;
  late DateTime now;
  late int recentCalls;
  late int detailCalls;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = SubscriptionRepository(db);
    now = DateTime(2026, 8, 3, 20);
    recentCalls = 0;
    detailCalls = 0;
  });
  tearDown(() => db.close());

  SubscriptionChecker checker({
    List<Video> Function()? recent,
    Video? Function(Subscription)? detail,
  }) => SubscriptionChecker(
    subscriptions: repo,
    clock: () => now,
    fetchRecent: () async {
      recentCalls++;
      return recent?.call() ?? const [];
    },
    fetchDetail: (sub) async {
      detailCalls++;
      return detail?.call(sub);
    },
  );

  test('a run costs one listing plus at most the per-run cap', () async {
    // Thirty shows, all overdue — the worst case the cap exists for.
    for (var i = 1; i <= 30; i++) {
      await repo.subscribe(show(id: i, remarks: '更新至第 01 集'));
    }

    final c = checker(
      detail: (s) => show(id: s.videoId, remarks: '更新至第 01 集'),
    );
    await c.run();

    expect(recentCalls, 1, reason: 'one listing answers for everyone');
    expect(
      detailCalls,
      SubscriptionChecker.maxDetailChecksPerRun,
      reason: 'thirty followed shows must not mean thirty requests',
    );
  });

  test('the min-run interval holds, and force bypasses it', () async {
    await repo.subscribe(show(id: 1, remarks: 'x'));
    final c = checker();

    await c.run();
    expect(recentCalls, 1);

    // Alt-tab storms: five triggers inside the window cost nothing.
    for (var i = 0; i < 5; i++) {
      now = now.add(const Duration(minutes: 2));
      await c.run();
    }
    expect(recentCalls, 1, reason: 'refocusing the window is not a sweep');

    now = now.add(SubscriptionChecker.minRunInterval);
    await c.run();
    expect(recentCalls, 2, reason: 'the window has passed');

    await c.run(force: true);
    expect(recentCalls, 3, reason: 'an explicit refresh is the user asking');
  });

  test('a fresh checker honours a persisted last-run time', () async {
    // The floor used to live only in memory, so every relaunch reset it and
    // the one habit desktop users actually have — closing and reopening the
    // app — triggered a sweep each time.
    await repo.subscribe(show(id: 1, remarks: 'x'));
    await checker().run();
    expect(recentCalls, 1);

    // Same clock, new instance — an app restart.
    final again = checker();
    await again.run();
    expect(recentCalls, 1, reason: 'restarting the app is not a sweep');

    now = now.add(SubscriptionChecker.minRunInterval);
    await again.run();
    expect(recentCalls, 2);
  });

  test('a finished show costs nothing, forever', () async {
    await repo.subscribe(show(id: 1, remarks: '全24集'));
    final c = checker();

    for (var day = 0; day < 30; day++) {
      now = now.add(const Duration(days: 1));
      await c.run(force: true);
    }
    expect(detailCalls, 0, reason: 'it cannot gain an episode');
  });

  test('an update found in the sweep spares the detail request', () async {
    await repo.subscribe(show(id: 1, remarks: '更新至第 01 集'));

    final c = checker(recent: () => [show(id: 1, remarks: '更新至第 02 集')]);
    final updated = await c.run();

    expect(updated.map((s) => s.videoId), [1]);
    expect(detailCalls, 0, reason: 'the listing already answered');
  });

  test('a miss reschedules without polluting the cadence history', () async {
    await repo.subscribe(show(id: 1, remarks: '更新至第 01 集'));

    final c = checker(
      detail: (s) => show(id: s.videoId, remarks: '更新至第 01 集'),
    );
    await c.run();
    expect(detailCalls, 1);

    final sub = (await repo.find('olevod', 1))!;
    expect(
      sub.updateHistory,
      isEmpty,
      reason: 'we looked; the show did not update — those are different facts',
    );
    expect(
      sub.nextCheckAt!.isAfter(now),
      isTrue,
      reason: 'and the next look is pushed out, not immediate',
    );

    // The very next run must not ask again.
    await c.run(force: true);
    expect(detailCalls, 1);
  });

  test('a failed detail fetch does not sink the whole run', () async {
    await repo.subscribe(show(id: 1, remarks: 'a'));
    await repo.subscribe(show(id: 2, remarks: 'b'));

    var thrown = false;
    final c = SubscriptionChecker(
      subscriptions: repo,
      clock: () => now,
      fetchRecent: () async => const [],
      fetchDetail: (sub) async {
        if (sub.videoId == 1 && !thrown) {
          thrown = true;
          throw Exception('CDN hiccup');
        }
        return show(id: sub.videoId, remarks: '更新至第 09 集');
      },
    );

    final updated = await c.run();
    expect(thrown, isTrue);
    expect(
      updated.map((s) => s.videoId),
      contains(2),
      reason: 'one bad show must not silence the others',
    );
  });
}
