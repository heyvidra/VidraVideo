import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/log.dart';
import '../data/history_repository.dart';
import '../domain/play_history.dart';

final episodeHistoriesProvider = FutureProvider.autoDispose
    .family<Map<int, EpisodeHistory>, ({int videoId, String? sourceId})>((
      ref,
      arg,
    ) async {
      final repository = ref.watch(historyRepositoryProvider);
      final histories = await repository.getEpisodeHistories(
        arg.videoId,
        arg.sourceId,
      );
      return {for (var h in histories) h.episodeIndex: h};
    });

/// The video-level history row for one show, i.e. which episode it was left on.
/// Backs the detail page's "continue watching" button — [HistoryRepository
/// .getVideoHistory] was written but had no callers.
final videoHistoryProvider = FutureProvider.autoDispose
    .family<VideoHistory?, ({int videoId, String? sourceId})>((ref, arg) async {
      final repository = ref.watch(historyRepositoryProvider);
      return repository.getVideoHistory(arg.videoId, arg.sourceId);
    });

/// What has been watched on the OTHER sources, keyed by [crossSourceKey].
///
/// One index for the whole screen rather than a query per card: a catalog page
/// renders dozens of cards and the history table is dozens of rows, so a lookup
/// per card would be dozens of round trips to answer from a map that fits in a
/// breath. NOT autoDispose — it is read by every list and the detail page, and
/// rebuilding it on each navigation is the same work again.
final crossSourceWatchesProvider =
    FutureProvider.family<Map<String, CrossSourceWatch>, String>((
      ref,
      currentSourceId,
    ) async {
      final repository = ref.watch(historyRepositoryProvider);
      // Rebuild when playback history changes, or a show watched in this
      // session would not be annotated until the app restarts.
      ref.watch(playHistoryProvider);
      return repository.getCrossSourceWatches(currentSourceId);
    });

final playHistoryProvider =
    AsyncNotifierProvider<PlayHistoryNotifier, List<RecentPlayback>>(
      PlayHistoryNotifier.new,
    );

class PlayHistoryNotifier extends AsyncNotifier<List<RecentPlayback>> {
  HistoryRepository get _repository => ref.watch(historyRepositoryProvider);

  @override
  Future<List<RecentPlayback>> build() async {
    return await _repository.getRecentPlaybacks();
  }

  Future<void> manualRefresh() async {
    // No AsyncValue.loading() first: this runs on every window-resumed event,
    // and dropping to loading makes the whole list blink through its skeleton
    // each time the user comes back from the player.
    state = await AsyncValue.guard(() => build());
  }

  Future<void> saveVideoHistory(VideoHistory history) async {
    try {
      await _repository.saveVideoHistory(history);
    } catch (e) {
      logR('PlayHistory', 'Error saving video history: $e');
    }
  }

  Future<void> deleteVideoHistory(int id) async {
    try {
      await _repository.deleteVideoHistory(id);
      await manualRefresh();
    } catch (e) {
      logR('PlayHistory', 'Error deleting video history: $e');
    }
  }

  Future<void> clearHistory() async {
    try {
      await _repository.clearAllHistory();
      await manualRefresh();
    } catch (e) {
      logR('PlayHistory', 'Error clearing history: $e');
    }
  }
}
