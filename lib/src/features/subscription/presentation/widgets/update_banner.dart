import 'package:vidra/src/common/cover_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/app_theme.dart';
import '../../domain/subscription.dart';
import '../subscription_provider.dart';

/// What landed while you were away, at the top of the catalog.
///
/// The app already knew this — the checker sets `unread` and the sidebar grew a
/// badge — but a number on a nav item is not an answer, and the one question
/// someone opens a catalog app to ask is whether the show they are following
/// has moved. It states which show, on which catalog, and offers the two
/// replies that exist: go there, or stop telling me.
///
/// Shows one at a time even when several are waiting. A stack of banners is a
/// second inbox to clear; the count says how many are behind this one, and
/// dismissing walks through them.
class UpdateBanner extends ConsumerWidget {
  const UpdateBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subs =
        ref.watch(subscriptionsProvider).value ?? const <Subscription>[];
    final unread = subs.where((s) => s.unread).toList()
      ..sort((a, b) {
        final at = a.lastUpdateAt, bt = b.lastUpdateAt;
        if (at == null || bt == null) return 0;
        return bt.compareTo(at);
      });
    if (unread.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final top = unread.first;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 12),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: AppTheme.onAir.withValues(alpha: 0.10),
          border: Border.all(color: AppTheme.onAir.withValues(alpha: 0.32)),
        ),
        child: Row(
          children: [
            // The show's face first — a cover is how a show is recognised
            // before its title is read. The amber dot stands in only when the
            // subscription carries no cover (or it fails to load).
            if ((top.coverUrl ?? '').isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: CoverImage(
                  imageUrl: top.coverUrl!,
                  width: 34,
                  height: 46,
                  memCacheWidth:
                      (34 * MediaQuery.devicePixelRatioOf(context)).round(),
                  errorWidget: const _OnAirDot(),
                ),
              )
            else
              const _OnAirDot(),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    top.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  // The catalog's own progress line, which is the update: the
                  // checker compares these strings rather than parsing an
                  // episode number out of them, so this is exactly what it saw
                  // change.
                  if ((top.lastSeenRemarks ?? '').trim().isNotEmpty)
                    Text(
                      top.lastSeenRemarks!.trim(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            if (unread.length > 1) ...[
              Text(
                tr('subscription.updates_waiting', args: ['${unread.length}']),
                style: const TextStyle(fontSize: 11.5, color: AppTheme.onAir),
              ),
              const SizedBox(width: 12),
            ],
            TextButton(
              onPressed: () {
                // Marked read on the way out, not on arrival: the banner is
                // gone either way, and leaving it unread would show it again on
                // the next catalog load.
                ref.read(subscriptionsProvider.notifier).markRead(top);
                context.push('/detail/${top.videoId}?sourceId=${top.sourceId}');
              },
              child: Text(tr('subscription.go_watch')),
            ),
            IconButton(
              tooltip: tr('subscription.dismiss'),
              icon: const Icon(Icons.close_rounded, size: 18),
              color: theme.colorScheme.onSurfaceVariant,
              onPressed: () =>
                  ref.read(subscriptionsProvider.notifier).markRead(top),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnAirDot extends StatelessWidget {
  const _OnAirDot();

  @override
  Widget build(BuildContext context) => Container(
    width: 7,
    height: 7,
    decoration: const BoxDecoration(
      color: AppTheme.onAir,
      shape: BoxShape.circle,
    ),
  );
}
