import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

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
    final theme = Theme.of(context);
    final unread = ref.watch(unreadSubscriptionCountProvider);

    // Swing when there is MORE news than before — not continuously while
    // unread sits nonzero. A bell that never stops ringing is an alarm the
    // user learns to ignore; one swing per arrival stays information.
    ref.listen(unreadSubscriptionCountProvider, (prev, next) {
      if (next > (prev ?? 0) && next > 0) _swing.forward(from: 0);
    });

    return IconButton(
      tooltip: unread > 0
          ? tr('subscription.updates_waiting', args: ['$unread'])
          : tr('subscription.title'),
      onPressed: () => context.push('/subscriptions'),
      icon: AnimatedBuilder(
        animation: _swing,
        builder: (context, child) => Transform.rotate(
          // Pivot at the top of the icon, where a real bell hangs.
          angle: _angle(_swing.value),
          alignment: Alignment.topCenter,
          child: child,
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(
              unread > 0
                  ? Icons.notifications_active
                  : Icons.notifications_none,
              color: unread > 0
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface,
            ),
            if (unread > 0)
              Positioned(
                right: -4,
                top: -4,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(999),
                    // A ring in the surface colour so the badge stays legible
                    // against the icon it overlaps.
                    border: Border.all(
                      color: theme.colorScheme.surface,
                      width: 2,
                    ),
                  ),
                  constraints: const BoxConstraints(minWidth: 18),
                  child: Text(
                    // Past nine the exact number stops being actionable and
                    // starts being a wide badge.
                    unread > 9 ? '9+' : '$unread',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
