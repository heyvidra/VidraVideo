import 'episode_number.dart';
import 'play_history.dart';
import 'video_collection.dart';

/// Which history drives each local tile's checkmark and progress bar, once the
/// other catalog's progress on the same show is folded in.
///
/// Both maps are ARRAY INDEX → history, because that is what the episode list
/// and `episodeHistoriesProvider` agree on WITHIN one source — and precisely
/// what means nothing BETWEEN two. olevod files 第1集 where dbku files 第01集,
/// and on the titles compared locally the two lists ran 14 entries against 15,
/// so index 13 is the finale on one side and the second-to-last episode on the
/// other. Every join here therefore goes through [episodeNumberOf], and
/// anything it declines to number is dropped rather than guessed at: a local
/// episode with no readable number, or with a number the other catalog does not
/// carry, gets NOTHING. An unwatched episode drawn as unwatched is the right
/// answer; a positional fallback ticks off an instalment the viewer never
/// opened, with nothing on screen to explain where the checkmark came from.
///
/// The local row wins wherever there is one. The other catalog holds a
/// different encode of the same episode — the same reason `EpisodeSkipData`
/// stays per-source — so its position in milliseconds points at a different
/// moment of the episode, and it is worth having only when this source has no
/// answer at all.
///
/// Borrowed rows come through untouched, sourceId/videoId/episodeIndex
/// included. Those fields say where the progress actually lives, which is what
/// distinguishes "the other source got this far" from a row this source could
/// write back to; rewriting them here would quietly turn one into the other.
///
/// Which leaves the result keyed for the episode GRID and nothing else. It is
/// the same type `episodeHistoriesProvider` hands back, on the same page, to
/// the widget sitting beside the grid — and it is not interchangeable with it:
/// only the KEY locates a borrowed row's tile, while its `episodeIndex` still
/// points into the other catalog's list. `resolveResumeTarget` reads
/// `episodeIndex` off the newest row rather than the key it was filed under, so
/// handed this map it resumes at the other catalog's position — a different
/// episode wherever the two lists disagree, which is the only case this join
/// exists for — and its own `histories[base]` lookup then misses, so the button
/// reports no progress on top of opening the wrong episode. Resume keeps taking
/// this source's own histories.
///
/// Returns [localHistories] itself when nothing is borrowed, so the ordinary
/// case — a show only one catalog has ever played — hands listeners back the
/// identical map they already hold instead of an equal copy that repaints every
/// tile.
/// One catalog's list numbered for joining, with the positional fallback
/// allowed only when the WHOLE list is unnamed.
///
/// [episodeNumberOf] answers a blank title with its position, which is right for
/// a source that ships an unnamed list — it really is counting in order, and
/// position is the only numbering there is. It stops being right the moment a
/// list is only PARTLY unnamed: a blank row among numbered ones takes its own
/// position as its number, and in a list that opens with a 预告 the two are off
/// by one. Caught on review — local `['第2集', '', '第4集']` numbered 2, 2, 4, so
/// two tiles borrowed the same episode's progress and the middle one showed a
/// checkmark for an instalment the viewer had never opened, which is the single
/// failure this whole join exists to prevent. A numbered neighbour is proof that
/// position is not the numbering, so blanks are refused whenever any title in
/// the list states a number of its own.
List<int?> _joinNumbers(List<VideoEpisode> episodes) {
  bool blank(VideoEpisode e) => (e.title ?? '').trim().isEmpty;
  final anyNamed = !episodes.every(blank);
  return [
    for (var i = 0; i < episodes.length; i++)
      if (anyNamed && blank(episodes[i]))
        null
      else
        episodeNumberOf(episodes[i].title, index: i, episodic: true),
  ];
}

Map<int, EpisodeHistory> mergeHistoriesByEpisodeNumber({
  required List<VideoEpisode> localEpisodes,
  required Map<int, EpisodeHistory> localHistories,
  required List<VideoEpisode> otherEpisodes,
  required Map<int, EpisodeHistory> otherHistories,
  required bool episodic,
}) {
  // A film's "episodes" are its audio tracks and mirrors — 立即播放 / 粤语播放 /
  // HD — so there is no sequence to align and index 1 on one catalog is not the
  // same playback line as index 1 on the other. [episodeNumberOf] already
  // refuses every one of them, but returning early says why.
  if (!episodic) return localHistories;

  final otherNumbers = _joinNumbers(otherEpisodes);
  final byNumber = <int, EpisodeHistory>{};
  for (var i = 0; i < otherEpisodes.length; i++) {
    final row = otherHistories[i];
    if (row == null) continue;
    final number = otherNumbers[i];
    if (number == null) continue;
    // Catalogs list the same episode twice — a re-upload beside the original,
    // or a mirror of it. Both are the same instalment, so the question is only
    // which viewing describes where the viewer is now, and that is the later
    // one.
    final held = byNumber[number];
    if (held == null || row.updatedAt.isAfter(held.updatedAt)) {
      byNumber[number] = row;
    }
  }
  if (byNumber.isEmpty) return localHistories;

  final localNumbers = _joinNumbers(localEpisodes);
  final borrowed = <int, EpisodeHistory>{};
  for (var i = 0; i < localEpisodes.length; i++) {
    if (localHistories.containsKey(i)) continue;
    final number = localNumbers[i];
    if (number == null) continue;
    final row = byNumber[number];
    if (row != null) borrowed[i] = row;
  }
  if (borrowed.isEmpty) return localHistories;

  return {...localHistories, ...borrowed};
}
