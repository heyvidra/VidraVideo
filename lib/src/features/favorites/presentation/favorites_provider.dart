import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../video/domain/play_history.dart' show crossSourceKey;
import '../../video/domain/video_collection.dart';
import '../data/favorites_repository.dart';

final favoritesProvider = AsyncNotifierProvider<FavoritesNotifier, List<Video>>(
  FavoritesNotifier.new,
);

/// Whether one show is saved, for the detail page's button.
///
/// By SHOW, not by catalog row — the same identity rule as the subscribe
/// button. Asking the row for whichever source is on screen would answer
/// "not saved" on a show saved yesterday from the other catalog.
final isFavoritedProvider = Provider.family<bool, ({String title, String? year})>(
  (ref, arg) {
    final favs = ref.watch(favoritesProvider).value ?? const [];
    final key = crossSourceKey(arg.title, arg.year);
    return favs.any((v) => crossSourceKey(v.title, v.year) == key);
  },
);

class FavoritesNotifier extends AsyncNotifier<List<Video>> {
  FavoritesRepository get _repo => ref.read(favoritesRepositoryProvider);

  @override
  Future<List<Video>> build() => _repo.all();

  Future<void> _refresh() async {
    state = AsyncData(await _repo.all());
  }

  /// Save or unsave the SHOW. Unsaving spans sources for the same reason
  /// unsubscribing does: rows are per (sourceId, videoId), and deleting only
  /// the visible one leaves the show still listed under the other catalog.
  Future<void> toggle(Video video) async {
    if (video.sourceId == null) return;
    final key = crossSourceKey(video.title, video.year);
    final owned = (state.value ?? const [])
        .where((v) => crossSourceKey(v.title, v.year) == key)
        .toList();
    if (owned.isEmpty) {
      await _repo.add(video);
    } else {
      for (final v in owned) {
        final s = v.sourceId;
        if (s != null) await _repo.remove(s, v.apiId);
      }
    }
    await _refresh();
  }

  Future<void> remove(Video video) async {
    final s = video.sourceId;
    if (s == null) return;
    await _repo.remove(s, video.apiId);
    await _refresh();
  }

  /// Reconcile saved shows against a listing the app already fetched.
  /// Only refreshes state on an actual change, or every scroll would
  /// rebuild the 想看 grid.
  Future<void> noticeFromListing(List<Video> videos) async {
    if (await _repo.noticeFromListing(videos)) await _refresh();
  }
}
