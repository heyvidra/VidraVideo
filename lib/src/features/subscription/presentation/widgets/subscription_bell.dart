import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../common/bar_controls.dart';

import '../subscription_provider.dart';

/// Titlebar entry to followed shows, with a count of the ones that have updated.
///
/// In the titlebar rather than the sidebar because it answers a question the
/// user has on arrival — "is there anything new?" — and the answer has to be
/// visible from wherever they happen to be, not only from a nav item they
/// might not be looking at.
class SubscriptionBell extends ConsumerStatefulWidget {
  const SubscriptionBell({super.key});

  @override
  ConsumerState<SubscriptionBell> createState() => _SubscriptionBellState();
}

class _SubscriptionBellState extends ConsumerState<SubscriptionBell>
    with SingleTickerProviderStateMixin {
  late final AnimationController _swing = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void dispose() {
    _swing.dispose();
    super.dispose();
  }

  /// A decaying pendulum: four diminishing swings, then rest. sin gives the
  /// left-right, (1 - t) drains the energy — like a struck bell rather than a
  /// metronome.
  double _angle(double t) => math.sin(t * math.pi * 4) * (1 - t) * 0.3;

  @override
  Widget build(BuildContext context) {
    final unread = ref.watch(unreadSubscriptionCountProvider);

    // Swing when there is MORE news than before — not continuously while
    // unread sits nonzero. A bell that never stops ringing is an alarm the
    // user learns to ignore; one swing per arrival stays information.
    ref.listen(unreadSubscriptionCountProvider, (prev, next) {
      if (next > (prev ?? 0) && next > 0) _swing.forward(from: 0);
    });

    // The same shell as every other control on the bar — see [BarIcon], which
    // owns the size, the colour and the hit box. This one was a 24px filled
    // glyph in a 48px Material box beside 17px outlined ones.
    return BarIcon(
      icon: unread > 0
          ? Icons.notifications_active_outlined
          : Icons.notifications_none_rounded,
      active: unread > 0,
      // Past nine the exact number stops being actionable and starts being a
      // wide badge.
      badge: unread > 0 ? (unread > 9 ? '9+' : '$unread') : null,
      tooltip: unread > 0
          ? tr('subscription.updates_waiting', args: ['$unread'])
          : tr('subscription.title'),
      onTap: () => context.push('/subscriptions'),
      wrap: (context, icon) => AnimatedBuilder(
        animation: _swing,
        builder: (context, child) => Transform.rotate(
          // Pivot at the top of the icon, where a real bell hangs.
          angle: _angle(_swing.value),
          alignment: Alignment.topCenter,
          child: child,
        ),
        child: icon,
      ),
    );
  }
}
