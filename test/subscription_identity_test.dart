// Following belongs to the show, not to the catalog row it was created from.
//
// The two catalogs share no id space, so the same show followed from both
// detail pages is two rows joined only by title and year. Every test here is
// one of the ways the app contradicts itself when a question about "this show"
// is answered from a single row: the bell reading unfollowed on the other
// source, an unfollow that leaves half the show still checking, a badge that
// stays dark because the update landed on the catalog the user is not looking
// at. The year test is the counterweight — a join this loose must still refuse
// to merge a remake with its original.

import 'package:flutter_test/flutter_test.dart';
import 'package:vidra/src/features/subscription/domain/subscription.dart';
import 'package:vidra/src/features/subscription/domain/subscription_identity.dart';

Subscription sub({
  required String source,
  required int videoId,
  required String title,
  String? year,
  bool unread = false,
}) => Subscription(
  sourceId: source,
  videoId: videoId,
  title: title,
  year: year,
  unread: unread,
);

void main() {
  group('isShowSubscribed', () {
    test('followed on the other catalog reads as followed on this one', () {
      // The user subscribed from olevod and is now standing on the dbku page.
      // Answering from the dbku row — which does not exist — would offer to
      // follow a show that is already followed, and the tap would create the
      // second row rather than undo the first.
      final subs = [
        sub(source: 'olevod', videoId: 1, title: '兵自风中来', year: '2026'),
      ];
      expect(
        isShowSubscribed(subs, title: '兵自风中来', year: '2026'),
        isTrue,
      );
    });

    test('a remake is not its original', () {
      // Titles repeat across decades and the ids say nothing, so the year is
      // the only thing standing between two unrelated shows.
      final subs = [sub(source: 'olevod', videoId: 1, title: '九门', year: '2026')];
      expect(isShowSubscribed(subs, title: '九门', year: '1994'), isFalse);
      expect(isShowSubscribed(subs, title: '九门', year: '2026'), isTrue);
    });

    test('a row with no year is its own show, not a wildcard', () {
      // Treating a missing year as "matches anything" would be the false
      // positive the exact key exists to prevent.
      final subs = [sub(source: 'dbku', videoId: 7, title: '九门')];
      expect(isShowSubscribed(subs, title: '九门', year: '2026'), isFalse);
      expect(isShowSubscribed(subs, title: '九门'), isTrue);
    });

    test('spacing differences do not split one show in two', () {
      final subs = [
        sub(source: 'olevod', videoId: 1, title: ' 兵自 风中来 ', year: '2026'),
      ];
      expect(
        isShowSubscribed(subs, title: '兵自 风中来', year: '2026'),
        isTrue,
      );
    });

    test('nothing followed yet', () {
      expect(
        isShowSubscribed(const [], title: '兵自风中来', year: '2026'),
        isFalse,
      );
    });
  });

  group('subscriptionsForShow', () {
    test('every catalog holding the show comes back', () {
      // This is the list an unfollow deletes. Missing one leaves that source
      // checking and notifying for a show the user switched off, with no
      // subscription visible anywhere to explain the notification.
      final subs = [
        sub(source: 'olevod', videoId: 1, title: '兵自风中来', year: '2026'),
        sub(source: 'dbku', videoId: 42, title: '兵自风中来', year: '2026'),
        sub(source: 'olevod', videoId: 9, title: '江海潮生', year: '2026'),
      ];

      final rows = subscriptionsForShow(subs, title: '兵自风中来', year: '2026');
      expect(rows, hasLength(2));
      expect(rows.map((s) => s.sourceId), ['olevod', 'dbku']);
      // The id ON THAT source: unsubscribe takes (sourceId, videoId), and the
      // ids are per-catalog, so the pair has to travel together.
      expect(rows.map((s) => s.videoId), [1, 42]);
    });

    test('the other show is left alone', () {
      final subs = [
        sub(source: 'olevod', videoId: 1, title: '九门', year: '2026'),
        sub(source: 'dbku', videoId: 2, title: '九门', year: '1994'),
      ];
      final rows = subscriptionsForShow(subs, title: '九门', year: '2026');
      expect(rows.single.videoId, 1);
    });

    test('nothing followed yet', () {
      expect(
        subscriptionsForShow(const [], title: '兵自风中来', year: '2026'),
        isEmpty,
      );
    });
  });

  group('showHasUnread', () {
    test('an update on any catalog lights the badge', () {
      // The episode landed on dbku first while the user was on the olevod
      // page. Reading the olevod row alone would show no badge for the update
      // the badge exists to announce.
      final subs = [
        sub(source: 'olevod', videoId: 1, title: '兵自风中来', year: '2026'),
        sub(
          source: 'dbku',
          videoId: 42,
          title: '兵自风中来',
          year: '2026',
          unread: true,
        ),
      ];
      expect(showHasUnread(subs, title: '兵自风中来', year: '2026'), isTrue);
    });

    test('nothing unread stays dark', () {
      final subs = [
        sub(source: 'olevod', videoId: 1, title: '兵自风中来', year: '2026'),
        sub(source: 'dbku', videoId: 42, title: '兵自风中来', year: '2026'),
      ];
      expect(showHasUnread(subs, title: '兵自风中来', year: '2026'), isFalse);
    });

    test("a remake's update does not light the original's badge", () {
      // The badge computes its own key, so it can drift from the bell's. A
      // showHasUnread that compared bare titles passes every other test in
      // this group — checked by mutation — and ships a badge announcing an
      // episode of a show the user never followed, on a page whose follow
      // button correctly reads unfollowed.
      final subs = [
        sub(
          source: 'dbku',
          videoId: 2,
          title: '九门',
          year: '2026',
          unread: true,
        ),
      ];
      expect(showHasUnread(subs, title: '九门', year: '1994'), isFalse);
      expect(showHasUnread(subs, title: '九门', year: '2026'), isTrue);
    });

    test('another show being unread says nothing about this one', () {
      final subs = [
        sub(
          source: 'dbku',
          videoId: 9,
          title: '江海潮生',
          year: '2026',
          unread: true,
        ),
      ];
      expect(showHasUnread(subs, title: '兵自风中来', year: '2026'), isFalse);
      expect(showHasUnread(const [], title: '兵自风中来', year: '2026'), isFalse);
    });
  });
}
