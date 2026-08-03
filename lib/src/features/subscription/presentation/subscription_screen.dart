import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../video/data/video_repository.dart';
import '../../video/presentation/widgets/cross_source_watch_badge.dart';
import '../domain/subscription.dart';
import 'subscription_provider.dart';

/// Followed shows, updated ones first.
class SubscriptionScreen extends ConsumerWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(subscriptionsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(tr('subscription.title'))),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (subs) {
          if (subs.isEmpty) return const _Empty();
          // Unread first, then most recently updated. What is new is the
          // reason the page was opened.
          final sorted = [...subs]
            ..sort((a, b) {
              if (a.unread != b.unread) return a.unread ? -1 : 1;
              final at = a.lastUpdateAt, bt = b.lastUpdateAt;
              if (at == null && bt == null) return 0;
              if (at == null) return 1;
              if (bt == null) return -1;
              return bt.compareTo(at);
            });

          // A grid, like the catalog: these are the same posters the user
          // recognises from browsing, and a subscription list is scanned for
          // "what's new" rather than read top to bottom.
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 200,
              childAspectRatio: 0.62,
              mainAxisSpacing: 18,
              crossAxisSpacing: 18,
            ),
            itemCount: sorted.length,
            itemBuilder: (context, i) => _Card(sub: sorted[i]),
          );
        },
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.notifications_none,
            size: 56,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 12),
          Text(
            tr('subscription.empty'),
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 4),
          Text(
            tr('subscription.empty_hint'),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

class _Card extends ConsumerWidget {
  const _Card({required this.sub});

  final Subscription sub;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final repo = ref.read(videoRepositoryProvider);

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () {
        // Opening the show is what "I have seen this" means; making the user
        // dismiss it separately would be a second chore for the same fact.
        ref.read(subscriptionsProvider.notifier).markRead(sub);
        context.push('/detail/${sub.videoId}?sourceId=${sub.sourceId}');
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: repo.resolveUrl(
                      sub.coverUrl ?? '',
                      sourceId: sub.sourceId,
                    ),
                    fit: BoxFit.cover,
                    errorWidget: (_, _, _) => Container(
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.08,
                      ),
                    ),
                  ),
                  // Progress line over a scrim rather than beneath the poster:
                  // it is the thing being checked for, so it belongs on the
                  // artwork the eye lands on first.
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(8, 14, 8, 6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.75),
                          ],
                        ),
                      ),
                      child: Text(
                        sub.lastSeenRemarks ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                  if (sub.unread)
                    Positioned(
                      top: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          tr('subscription.new'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    top: 2,
                    right: 2,
                    child: _UnfollowButton(sub: sub),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            sub.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          if (sub.crossSeenRemarks != null) ...[
            const SizedBox(height: 2),
            // The other catalog's progress, named. Often ahead of the
            // followed one — which is exactly the news worth showing.
            Text(
              '${sourceDisplayName(ref, sub.crossSeenSourceId!)}: '
              '${sub.crossSeenRemarks}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                color: theme.colorScheme.primary.withValues(alpha: 0.85),
              ),
            ),
          ],
          const SizedBox(height: 2),
          Text(
            _schedule(context, sub),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.75),
            ),
          ),
        ],
      ),
    );
  }

  /// What the app has worked out about this show's release rhythm.
  ///
  /// Shown because the schedule is the reason a followed show can sit
  /// untouched for days — without it, "nothing happening" is indistinguishable
  /// from "not working".
  String _schedule(BuildContext context, Subscription s) {
    if (s.finished) return tr('subscription.finished');
    final interval = UpdateCadence.estimateInterval(s.updateHistory);
    if (interval == null) return tr('subscription.learning');
    final days = interval.inHours / 24;
    if (days >= 6 && days <= 8) return tr('subscription.weekly');
    if (days >= 0.8 && days <= 1.3) return tr('subscription.daily');
    if (days < 0.8) {
      return tr('subscription.every_hours', args: ['${interval.inHours}']);
    }
    return tr('subscription.every_days', args: ['${days.round()}']);
  }
}

class _UnfollowButton extends ConsumerWidget {
  const _UnfollowButton({required this.sub});

  final Subscription sub;

  @override
  Widget build(BuildContext context, WidgetRef ref) => IconButton(
    tooltip: tr('subscription.unfollow'),
    iconSize: 16,
    visualDensity: VisualDensity.compact,
    style: IconButton.styleFrom(
      backgroundColor: Colors.black.withValues(alpha: 0.45),
      foregroundColor: Colors.white,
    ),
    icon: const Icon(Icons.notifications_off_outlined),
    onPressed: () => ref.read(subscriptionsProvider.notifier).remove(sub),
  );
}
