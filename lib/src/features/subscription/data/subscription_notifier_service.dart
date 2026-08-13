import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_notifier/local_notifier.dart';

import '../../../core/utils/log.dart';
import '../domain/subscription.dart';

final subscriptionNotifierServiceProvider =
    Provider<SubscriptionNotifierService>(
      (ref) => SubscriptionNotifierService(),
    );

/// Posts an OS notification when followed shows gain episodes.
///
/// One notification per batch, never one per show. A viewer following ten
/// dramas that all update at 20:00 would otherwise get ten toasts in a row —
/// which is not ten times the information, it is ten times the interruption
/// for the same fact ("there is new stuff").
class SubscriptionNotifierService {
  /// Titles named individually before the message switches to a count. Two
  /// names still read as news; a list of nine reads as a wall.
  static const maxNamed = 2;

  /// The one line that says what changed. Shared, because the desktop pet
  /// says the same news in its speech bubble and the two must not drift into
  /// describing the same batch differently.
  static String summarise(List<Subscription> updated) {
    final names = updated.take(maxNamed).map((s) => s.title).join('、');
    return updated.length <= maxNamed
        ? names
        : tr(
            'subscription.notify_body_more',
            args: [names, '${updated.length - maxNamed}'],
          );
  }

  Future<void> announce(List<Subscription> updated) async {
    if (updated.isEmpty) return;
    try {
      final body = summarise(updated);

      final notification = LocalNotification(
        title: tr('subscription.notify_title'),
        body: body,
      );
      await notification.show();
    } catch (e) {
      // A notification that cannot be posted — permission refused, platform
      // without a notification centre — must not break update detection. The
      // badge and the subscription page carry the same news regardless.
      logR('Subscription', 'notification failed: $e');
    }
  }
}
