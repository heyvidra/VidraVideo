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

final playHistoryProvider =
    AsyncNotifierProvider<PlayHistoryNotifier, List<VideoHistory>>(
      PlayHistoryNotifier.new,
    );

class PlayHistoryNotifier extends AsyncNotifier<List<VideoHistory>> {
  HistoryRepository get _repository => ref.watch(historyRepositoryProvider);

  @override
  Future<List<VideoHistory>> build() async {
    return await _repository.getAllVideoHistory();
  }

  Future<void> manualRefresh() async {
    state = const AsyncValue.loading();
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
