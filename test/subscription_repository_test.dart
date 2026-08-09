// Tier 1 of update detection: reconciling followed shows against a listing the
// app already had. It runs on every catalog page the user scrolls, so its
// no-op case has to be genuinely no-op — a false positive here would mark a
// show updated, re-plan its schedule, and light up the badge every time the
// user browsed past it.

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vidra/src/data/database/app_database.dart' show AppDatabase;
import 'package:vidra/src/features/subscription/data/subscription_repository.dart';
import 'package:vidra/src/features/video/domain/video_collection.dart';

Video show({
  required int id,
  String source = 'olevod',
  String title = '追的剧',
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

  // The badge derives unread from the list; the tests do the same.
  Future<int> unreadCount() async =>
      (await repo.all()).where((s) => s.unread).length;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = SubscriptionRepository(db);
  });
  tearDown(() => db.close());

  test(
    'subscribing seeds the baseline so it is not read as an update',
    () async {
      await repo.subscribe(show(id: 1, remarks: '更新至第 05 集'));

      final changed = await repo.noticeFromListing([
        show(id: 1, remarks: '更新至第 05 集'),
      ]);
      expect(changed, isEmpty, reason: 'the same line is not news');
      expect(await unreadCount(), 0);
    },
  );

  test('a changed progress line is an update, and costs no request', () async {
    await repo.subscribe(show(id: 1, remarks: '更新至第 05 集'));

    final changed = await repo.noticeFromListing([
      show(id: 1, remarks: '更新至第 06 集'),
      show(id: 99, remarks: '更新至第 02 集'), // not followed
    ]);

    expect(changed, hasLength(1));
    expect(changed.single.videoId, 1);
    expect(changed.single.unread, isTrue);
    expect(await unreadCount(), 1);
    // And the schedule has been planned from the sighting.
    expect((await repo.find('olevod', 1))!.nextCheckAt, isNotNull);
  });

  test('re-seeing the same listing repeatedly stays a no-op', () async {
    await repo.subscribe(show(id: 1, remarks: '更新至第 05 集'));
    await repo.noticeFromListing([show(id: 1, remarks: '更新至第 06 集')]);
    await repo.markRead('olevod', 1);

    for (var i = 0; i < 5; i++) {
      final again = await repo.noticeFromListing([
        show(id: 1, remarks: '更新至第 06 集'),
      ]);
      expect(again, isEmpty);
    }
    expect(await unreadCount(), 0, reason: 'browsing is not an update');
  });

  test('the same show on two sources is two subscriptions', () async {
    // videoId collides across catalogs, and the two carry different release
    // schedules — merging them would attribute one source's update to the
    // other.
    await repo.subscribe(show(id: 1, source: 'olevod', remarks: 'A'));
    await repo.subscribe(show(id: 1, source: 'dbku', remarks: 'B'));
    expect(await repo.all(), hasLength(2));

    final changed = await repo.noticeFromListing([
      show(id: 1, source: 'dbku', remarks: 'B2'),
    ]);
    expect(changed.single.sourceId, 'dbku');
    expect((await repo.find('olevod', 1))!.lastSeenRemarks, 'A');
  });

  test('subscribing twice does not duplicate', () async {
    await repo.subscribe(show(id: 1, remarks: 'x'));
    await repo.subscribe(show(id: 1, remarks: 'y'));
    expect(await repo.all(), hasLength(1));
  });

  test('a show that was already finished is never due', () async {
    await repo.subscribe(show(id: 1, remarks: '全 30 集'));
    final due = await repo.dueForDetailCheck(DateTime(2030));
    expect(due, isEmpty, reason: 'it cannot gain an episode');
  });

  test('only shows past their scheduled slot are worth a request', () async {
    await repo.subscribe(show(id: 1, remarks: '更新至第 01 集'));
    await repo.subscribe(show(id: 2, remarks: '更新至第 01 集'));

    // Show 1 has just been seen updating, so it is scheduled forward.
    await repo.noticeFromListing([show(id: 1, remarks: '更新至第 02 集')]);

    final due = await repo.dueForDetailCheck(DateTime.now());
    expect(
      due.map((s) => s.videoId),
      [2],
      reason: 'a show seen minutes ago is not worth asking about',
    );
  });

  group('cross-source updates', () {
    test(
      'the other catalog updating first still reaches the subscriber',
      () async {
        // Followed on olevod; dbku lists the same title (title+year identity)
        // and moves first. The subscriber hears about it without following the
        // dbku copy at all.
        await repo.subscribe(show(id: 1, remarks: '更新至第 08 集'));
        // Seed pass: dbku's current state becomes the baseline, silently.
        await repo.noticeFromListing([
          show(id: 77, source: 'dbku', remarks: '更新至8集'),
        ]);
        expect(
          await unreadCount(),
          0,
          reason: 'first sighting is a baseline, not news',
        );

        final changed = await repo.noticeFromListing([
          show(id: 77, source: 'dbku', remarks: '更新至9集'),
        ]);
        expect(changed, hasLength(1));
        expect(
          changed.single.sourceId,
          'olevod',
          reason: 'the notification belongs to the followed subscription',
        );
        expect(changed.single.crossSeenRemarks, '更新至9集');
        expect(await unreadCount(), 1);
      },
    );

    test('cross-source sightings never touch the same-source state', () async {
      // Sources word progress differently; letting dbku text into olevod's
      // comparison would read the wording gap as an update on every sweep.
      await repo.subscribe(show(id: 1, remarks: '更新至第 08 集'));
      await repo.noticeFromListing([
        show(id: 77, source: 'dbku', remarks: '更新至8集'),
      ]);
      await repo.noticeFromListing([
        show(id: 77, source: 'dbku', remarks: '更新至9集'),
      ]);

      final sub = (await repo.find('olevod', 1))!;
      expect(sub.lastSeenRemarks, '更新至第 08 集');
      expect(
        sub.updateHistory,
        isEmpty,
        reason: "dbku's schedule must not teach olevod's cadence",
      );
    });

    test('re-seeing the other catalog unchanged is a no-op', () async {
      await repo.subscribe(show(id: 1, remarks: 'x'));
      await repo.noticeFromListing([
        show(id: 77, source: 'dbku', remarks: '更新至9集'),
      ]);
      for (var i = 0; i < 3; i++) {
        final again = await repo.noticeFromListing([
          show(id: 77, source: 'dbku', remarks: '更新至9集'),
        ]);
        expect(again, isEmpty);
      }
    });
  });
}
