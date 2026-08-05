import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../common/screen_chrome.dart';
import '../../../common/skeleton/video_card_skeleton.dart';
import '../../video/domain/video_collection.dart';
import '../../video/presentation/widgets/cards/popular_video_card.dart';
import '../../video/presentation/widgets/cross_source_watch_badge.dart';
import '../domain/subscription.dart';
import 'subscription_provider.dart';

/// Followed shows, updated ones first.
class SubscriptionScreen extends ConsumerWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(subscriptionsProvider);

    final unread = async.value?.where((s) => s.unread).length ?? 0;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          ScreenHeader(
            title: tr('navigation.subscriptions'),
            count: (async.value?.isNotEmpty ?? false)
                ? '${async.value!.length}'
                : null,
            actions: [
              if (unread > 0)
                ScreenAction(
                  label: tr('subscription.mark_all_read'),
                  onTap: () {
                    final notifier = ref.read(subscriptionsProvider.notifier);
                    for (final s in async.value!.where((s) => s.unread)) {
                      notifier.markRead(s);
                    }
                  },
                ),
            ],
          ),
          Expanded(child: _body(context, ref, async)),
        ],
      ),
    );
  }

  Widget _body(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<Subscription>> async,
  ) {
    return async.when(
      // The catalog's skeleton, not a spinner: this screen shows the catalog's
      // cards, and a lone spinner in the middle of an empty page says nothing
      // about what is coming.
      loading: () => GridView.builder(
        padding: const EdgeInsets.fromLTRB(
          kContentGutter,
          0,
          kContentGutter,
          24,
        ),
        gridDelegate: kPosterGrid,
        itemCount: 8,
        itemBuilder: (context, i) => const VideoCardSkeleton(),
      ),
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

        // A grid, like the catalog — and the SAME grid: these are the posters
        // the user recognises from browsing, and three screens showing the
        // same cards at three different widths is the thing that made the app
        // look assembled rather than designed.
        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(
            kContentGutter,
            0,
            kContentGutter,
            24,
          ),
          gridDelegate: kPosterGrid,
          itemCount: sorted.length,
          itemBuilder: (context, i) => _Card(sub: sorted[i]),
        );
      },
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) => ScreenEmpty(
    icon: Icons.notifications_none_rounded,
    title: tr('subscription.empty'),
    hint: tr('subscription.empty_hint'),
  );
}

/// A followed show, drawn as the SAME card the catalog and 最近播放 draw.
///
/// It used to be a hand-built column: a bare poster with the title and two
/// lines floating on the page beneath it, no card surface at all. Side by side
/// with 最近播放 — the same posters, on a glass card with a captioned footer —
/// they did not look like the same application. Everything specific to a
/// subscription now arrives through the card's own slots.
class _Card extends ConsumerWidget {
  const _Card({required this.sub});

  final Subscription sub;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopularVideoCard(
      video: Video(
        apiId: sub.videoId,
        title: sub.title,
        coverUrl: sub.coverUrl ?? '',
        rating: 0,
        type: '',
        sourceId: sub.sourceId,
        remarks: sub.lastSeenRemarks,
      ),
      // The catalog infers "new" from a timestamp; a subscription KNOWS.
      isNew: sub.unread,
      // What the other catalog says, when it has something to add — otherwise
      // this source's own progress line.
      subtitle: sub.crossSeenRemarks != null
          ? '${sourceDisplayName(ref, sub.crossSeenSourceId!)}: '
                '${sub.crossSeenRemarks}'
          : (sub.lastSeenRemarks ?? _schedule(context, sub)),
      trailing: _UnfollowButton(sub: sub),
      onTap: () {
        // Opening the show is what "I have seen this" means; making the user
        // dismiss it separately would be a second chore for the same fact.
        ref.read(subscriptionsProvider.notifier).markRead(sub);
        context.push('/detail/${sub.videoId}?sourceId=${sub.sourceId}');
      },
    );
  }

  /// What the app has worked out about this show's release rhythm.
  ///
  /// The fallback when the catalog's own progress line is missing — without
  /// it, "nothing happening" is indistinguishable from "not working".
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
  Widget build(BuildContext context, WidgetRef ref) => Tooltip(
    message: tr('subscription.unfollow'),
    child: Material(
      color: Colors.black.withValues(alpha: 0.47),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => ref.read(subscriptionsProvider.notifier).remove(sub),
        child: const Padding(
          padding: EdgeInsets.all(4),
          child: Icon(
            Icons.notifications_off_outlined,
            size: 14,
            color: Colors.white,
          ),
        ),
      ),
    ),
  );
}
