import 'package:flutter_test/flutter_test.dart';
import 'package:vidra/src/features/subscription/data/subscription_notifier_service.dart';
import 'package:vidra/src/features/subscription/domain/subscription.dart';

void main() {
  // The one line both the OS toast and the pet bubble speak. Only the
  // more-than-two case goes through tr(), so the named cases are testable
  // without localization plumbing.
  group('SubscriptionNotifierService.summarise', () {
    test('one show is named alone', () {
      expect(
        SubscriptionNotifierService.summarise(const [
          Subscription(sourceId: 's', videoId: 1, title: '甲'),
        ]),
        '甲',
      );
    });

    test('two shows are joined with 、', () {
      expect(
        SubscriptionNotifierService.summarise(const [
          Subscription(sourceId: 's', videoId: 1, title: '甲'),
          Subscription(sourceId: 's', videoId: 2, title: '乙'),
        ]),
        '甲、乙',
      );
    });
  });
}
