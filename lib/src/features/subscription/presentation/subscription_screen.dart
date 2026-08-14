import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../common/bar_controls.dart';
import '../../../common/poster_card_action.dart';
import '../../../common/screen_chrome.dart';
import '../../../common/skeleton/skeleton_box.dart';
import '../../../common/skeleton/video_card_skeleton.dart';
import '../../../config/design_tokens.dart';
import '../../video/domain/video_collection.dart';
import '../../video/presentation/widgets/cards/popular_video_card.dart';
import '../../video/presentation/widgets/cross_source_watch_badge.dart';
import '../domain/subscription.dart';
import '../domain/update_calendar.dart';
import 'subscription_provider.dart';

/// Followed shows, updated ones first — as the catalog's poster grid, or as
/// the 追剧日历: the same list folded by WHEN each show is expected next.
class SubscriptionScreen extends ConsumerStatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  ConsumerState<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends ConsumerState<SubscriptionScreen> {
  bool calendar = false;

  @override
  Widget build(BuildContext context) {
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
              if (unread > 0) ...[
                ScreenAction(
                  label: tr('subscription.mark_all_read'),
                  onTap: () {
                    final notifier = ref.read(subscriptionsProvider.notifier);
                    for (final s in async.value!.where((s) => s.unread)) {
                      notifier.markRead(s);
                    }
                  },
                ),
                const SizedBox(width: 6),
              ],
              BarIcon(
                icon: calendar
                    ? Icons.grid_view_rounded
                    : Icons.calendar_month_rounded,
                tooltip: calendar
                    ? tr('subscription.view_grid')
                    : tr('subscription.view_calendar'),
                onTap: () => setState(() => calendar = !calendar),
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
      loading: () => SkeletonShimmer(
        child: GridView.builder(
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
      ),
      error: (e, _) => Center(child: Text('$e')),
      data: (subs) {
        if (subs.isEmpty) return const _Empty();
        if (calendar) return _CalendarView(subs: subs);
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

/// The followed list folded by expected day: 今天 / 明天 / 周X / 下周及以后 /
/// 待定 / 已完结. The estimates are [nextUpdateEstimate]'s — honest to a
/// fault, so a show the cadence cannot place says 待定 rather than guessing.
class _CalendarView extends ConsumerWidget {
  const _CalendarView({required this.subs});

  final List<Subscription> subs;

  String _dayLabel(BuildContext context, int? daysAway, DateTime now) {
    switch (daysAway) {
      case null:
        return tr('subscription.calendar_undated');
      case 0:
        return tr('subscription.calendar_today');
      case 1:
        return tr('subscription.calendar_tomorrow');
      case 7:
        return tr('subscription.calendar_later');
      default:
        // 周X, in the app's language — intl ships the names.
        final day = now.add(Duration(days: daysAway));
        return DateFormat.E(context.locale.toString()).format(day);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final cal = buildUpdateCalendar(subs, now);

    return ListView(
      padding: const EdgeInsets.fromLTRB(kContentGutter, 0, kContentGutter, 24),
      children: [
        for (final day in cal.days) ...[
          ScreenSection(
            title: _dayLabel(context, day.daysAway, now),
            children: [
              for (final s in day.shows) _CalendarRow(sub: s),
            ],
          ),
          const SizedBox(height: 18),
        ],
        if (cal.finished.isNotEmpty)
          ScreenSection(
            title: tr('subscription.calendar_finished'),
            children: [
              for (final s in cal.finished) _CalendarRow(sub: s),
            ],
          ),
      ],
    );
  }
}

/// One show in the calendar: cover, title, the progress line the checker
/// last saw. The amber dot is the same fact it is everywhere — this gained
/// an episode you have not looked at.
class _CalendarRow extends ConsumerWidget {
  const _CalendarRow({required this.sub});

  final Subscription sub;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = VidraTokens.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        ref.read(subscriptionsProvider.notifier).markRead(sub);
        context.push('/detail/${sub.videoId}?sourceId=${sub.sourceId}');
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            if ((sub.coverUrl ?? '').isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: CachedNetworkImage(
                  imageUrl: sub.coverUrl!,
                  width: 30,
                  height: 41,
                  fit: BoxFit.cover,
                  memCacheWidth:
                      (30 * MediaQuery.devicePixelRatioOf(context)).round(),
                  errorWidget: (_, _, _) =>
                      SizedBox(width: 30, height: 41),
                ),
              )
            else
              const SizedBox(width: 30, height: 41),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sub.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.5,
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                      color: t.fg,
                    ),
                  ),
                  if ((sub.lastSeenRemarks ?? '').trim().isNotEmpty)
                    Text(
                      sub.lastSeenRemarks!.trim(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.4,
                        color: t.fg3,
                      ),
                    ),
                ],
              ),
            ),
            if (sub.unread) ...[
              const SizedBox(width: 8),
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: t.amber,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
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
      // this source's own progress line. The learned schedule's estimate
      // rides along when it has one: "更新至第20集 · 预计明天更新" answers
      // the question a 追更 page exists for without opening anything.
      subtitle: [
        sub.crossSeenRemarks != null
            ? '${sourceDisplayName(ref, sub.crossSeenSourceId!)}: '
                  '${sub.crossSeenRemarks}'
            : (sub.lastSeenRemarks ?? _schedule(context, sub)),
        ?_expectedLabel(sub),
      ].join(' · '),
      trailing: PosterCardAction(
        icon: Icons.notifications_off_outlined,
        tooltip: tr('subscription.unfollow'),
        onTap: () => ref.read(subscriptionsProvider.notifier).remove(sub),
      ),
      onTap: () {
        // Opening the show is what "I have seen this" means; making the user
        // dismiss it separately would be a second chore for the same fact.
        ref.read(subscriptionsProvider.notifier).markRead(sub);
        context.push('/detail/${sub.videoId}?sourceId=${sub.sourceId}');
      },
    );
  }

  /// The learned schedule's next-episode estimate, worded by distance:
  /// 今天 / 明天 / a date. Null when the cadence has nothing to say.
  String? _expectedLabel(Subscription s) {
    final now = DateTime.now();
    final next = nextUpdateEstimate(s, now);
    if (next == null) return null;
    final days = DateTime(next.year, next.month, next.day)
        .difference(DateTime(now.year, now.month, now.day))
        .inDays;
    if (days <= 0) return tr('subscription.expected_today');
    if (days == 1) return tr('subscription.expected_tomorrow');
    return tr(
      'subscription.expected_on',
      args: [
        '${next.month.toString().padLeft(2, '0')}-'
            '${next.day.toString().padLeft(2, '0')}',
      ],
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

