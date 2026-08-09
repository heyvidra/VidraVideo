import 'play_history.dart';

/// Matches the SDK's own "can this still be resumed" cut-off
/// (vidra_player ResumeDelegate treats >95% as finished).
const double kEpisodeFinishedRatio = 0.95;

/// Where "keep watching" should actually drop the viewer.
class ResumeTarget {
  /// The episode to open.
  final int episodeIndex;

  /// How far into [episodeIndex] they got, 0..1.
  final double progress;

  /// No history at all — the call to action is "play", not "continue".
  final bool isFirstTime;

  /// The remembered episode was finished, so this points at the next one.
  final bool advanced;

  const ResumeTarget({
    required this.episodeIndex,
    this.progress = 0.0,
    this.isFirstTime = false,
    this.advanced = false,
  });
}

/// The single rule for "which episode does this show resume at".
///
/// Lives here rather than in each widget because the detail page's button, the
/// recent-list card and the home rail all have to answer it, and answering it
/// three times is how they end up disagreeing — the detail page's main button
/// used to ignore history entirely and always open episode 1.
///
/// [histories] is episodeIndex → history, i.e. episodeHistoriesProvider's
/// value. [episodeCount] gates the "finished, so move on" jump and clamps a
/// stale index; pass null when the episode list isn't loaded.
ResumeTarget resolveResumeTarget({
  required Map<int, EpisodeHistory> histories,
  int? lastEpisodeIndex,
  int? episodeCount,
}) {
  var base = lastEpisodeIndex;
  if (base == null && histories.isNotEmpty) {
    base = histories.values
        .reduce((a, b) => b.updatedAt.isAfter(a.updatedAt) ? b : a)
        .episodeIndex;
  }
  if (base == null) {
    return const ResumeTarget(episodeIndex: 0, isFirstTime: true);
  }

  // A source can drop or reorder episodes between visits, and an out-of-range
  // index opens a player with no episode to play.
  if (episodeCount != null && episodeCount > 0 && base >= episodeCount) {
    base = episodeCount - 1;
  }
  if (base < 0) base = 0;

  final history = histories[base];
  final progress = (history == null || history.durationMillis <= 0)
      ? 0.0
      : (history.positionMillis / history.durationMillis).clamp(0.0, 1.0);

  if (progress >= kEpisodeFinishedRatio &&
      episodeCount != null &&
      base + 1 < episodeCount) {
    return ResumeTarget(episodeIndex: base + 1, advanced: true);
  }
  return ResumeTarget(episodeIndex: base, progress: progress);
}

/// Newest-wins across catalogs — the same rule the episode grid merges by:
/// between two viewings of one show, the later `updatedAt` says where the
/// viewer is now.
///
/// Returns [match] when it is newer than every row this source holds, else
/// null — meaning the local resume stands. Exists because the 看到 chip and
/// the play button used to consult the other catalog only when this one had
/// NOTHING: a show continued elsewhere kept resuming from the stale local row
/// (watched 第21集 there, offered 第16集 here). [lastWriteAt] is the local
/// `VideoHistory.updatedAt`, folded in because it can outlive the episode rows.
CrossSourceWatch? crossSourceResumeOverride({
  required CrossSourceWatch? match,
  required Map<int, EpisodeHistory> histories,
  DateTime? lastWriteAt,
}) {
  if (match == null) return null;
  var latest = lastWriteAt;
  for (final row in histories.values) {
    if (latest == null || row.updatedAt.isAfter(latest)) latest = row.updatedAt;
  }
  if (latest != null && !match.updatedAt.isAfter(latest)) return null;
  return match;
}
