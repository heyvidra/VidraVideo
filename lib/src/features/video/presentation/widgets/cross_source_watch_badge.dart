import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vidra/src/features/video/data/video_repository.dart';
import 'package:vidra/src/features/video/domain/play_history.dart';
import 'package:vidra/src/features/video/domain/video_collection.dart';
import 'package:vidra/src/features/video/presentation/play_history_provider.dart';

/// Progress on the same title from another source, or null when there is none.
///
/// The two catalogs share no ids, so a show is matched on title + year — see
/// [crossSourceKey] for why that is exact rather than fuzzy.
CrossSourceWatch? crossSourceWatchFor(WidgetRef ref, Video video) {
  final watches = ref.watch(crossSourceWatchesProvider).value;
  final entries = watches?[crossSourceKey(video.title, video.year?.toString())];
  if (entries == null) return null;

  // The video's OWN source is not news. Filtered against `video.sourceId`, not
  // the screen's active source: arriving from search or a ?sourceId= link makes
  // those differ, and the wrong one told you where you already are.
  CrossSourceWatch? best;
  for (final w in entries) {
    if (w.sourceId == video.sourceId) continue;
    if (best == null || w.updatedAt.isAfter(best.updatedAt)) best = w;
  }
  return best;
}

/// The source's own display name, falling back to the raw id.
///
/// Users pick sources by the names shown in the switcher, never by the internal
/// slug — labelling a card "olevod" names something they have no other reason
/// to have seen.
String sourceDisplayName(WidgetRef ref, String sourceId) {
  for (final source in ref.watch(availableDataSourcesProvider)) {
    if (source.id == sourceId) return source.name;
  }
  return sourceId;
}

/// One line for a card: "欧乐影院 看到 第 5 集", or null to leave the card's own
/// remarks alone.
String? crossSourceWatchLabel(WidgetRef ref, Video video) {
  final match = crossSourceWatchFor(ref, video);
  if (match == null) return null;
  final where = sourceDisplayName(ref, match.sourceId);
  // A film's "episodes" are the source's audio tracks and mirrors, not
  // instalments — see [isEpisodicType].
  if (!isEpisodicType(video.type)) return '$where 看过';
  return '$where 看到 第 ${match.lastEpisodeIndex + 1} 集';
}

/// "已在 欧乐影院 看到 第 5 集", shown beside the episode-list heading.
///
/// Renders nothing when there is no match, which is the common case — an
/// absent badge must not leave a hole in the row.
class CrossSourceWatchBadge extends ConsumerWidget {
  const CrossSourceWatchBadge({super.key, required this.video});

  final Video video;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final match = crossSourceWatchFor(ref, video);
    if (match == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final where = sourceDisplayName(ref, match.sourceId);
    final text = isEpisodicType(video.type)
        ? '已在 $where 看到 第 ${match.lastEpisodeIndex + 1} 集'
        : '已在 $where 看过';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.history_rounded,
            size: 14,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
