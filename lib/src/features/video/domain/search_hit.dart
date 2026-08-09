import 'play_history.dart' show crossSourceKey;
import 'video_collection.dart';

/// One show in the search results, across every catalog that returned it.
///
/// [primary] is the current source's row when it has one — opening the tile
/// keeps the viewer on the source they are browsing — otherwise the first
/// source that answered. [others] are the same show on the remaining
/// catalogs, in source-priority order, so the tile can say "the other
/// catalog has it too, at 21 episodes".
typedef SearchHit = ({Video primary, List<Video> others});

/// Folds per-source result lists into one list of shows.
///
/// [perSource] is ordered by source priority with the CURRENT source first.
/// The first occurrence of a show (by [crossSourceKey] — title + year, exact,
/// same identity the watch badge uses) pins both its position and its
/// [SearchHit.primary]: the current source's own relevance order survives,
/// and shows only the other catalogs carry append after it rather than
/// interleaving. Later occurrences of the same key become [SearchHit.others].
List<SearchHit> groupSearchResults(List<List<Video>> perSource) {
  final order = <String>[];
  final primaries = <String, Video>{};
  final others = <String, List<Video>>{};

  for (final results in perSource) {
    for (final video in results) {
      final key = crossSourceKey(video.title, video.year);
      if (!primaries.containsKey(key)) {
        order.add(key);
        primaries[key] = video;
        others[key] = [];
      } else {
        others[key]!.add(video);
      }
    }
  }

  return [
    for (final key in order) (primary: primaries[key]!, others: others[key]!),
  ];
}
