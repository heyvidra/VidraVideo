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

/// Every watched title, keyed by [crossSourceKey], one entry per source.
///
/// One index for the whole screen rather than a query per card: a catalog page
/// renders dozens of cards against a table of dozens of rows. Not keyed by the
/// active source — which source is "current" belongs to the video being
/// annotated, not to the screen, and conflating the two showed a video its own
/// progress under another platform's name.
final crossSourceWatchesProvider =
    FutureProvider<Map<String, List<CrossSourceWatch>>>((ref) async {
      final repository = ref.watch(historyRepositoryProvider);
      // Rebuild when playback history changes, or a show watched in this
      // session would not be annotated until the app restarts.
      ref.watch(playHistoryProvider);
      return repository.getCrossSourceWatches();
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
