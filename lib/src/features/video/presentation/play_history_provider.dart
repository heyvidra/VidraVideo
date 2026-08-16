import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/log.dart';
import '../data/history_repository.dart';
import '../data/video_repository.dart' show disabledDataSourceIdsProvider;
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
      final disabled = ref.watch(disabledDataSourceIdsProvider);
      final index = await repository.getCrossSourceWatches();
      if (disabled.isEmpty) return index;
      // These annotate a card with "you watched this on the OTHER catalog".
      // A switched-off catalog must not be that other one, and an entry whose
      // every watch came from one leaves no badge rather than an empty one.
      final visible = <String, List<CrossSourceWatch>>{};
      for (final entry in index.entries) {
        final kept = entry.value
            .where((w) => !disabled.contains(w.sourceId))
            .toList();
        if (kept.isNotEmpty) visible[entry.key] = kept;
      }
      return visible;
    });

final playHistoryProvider =
    AsyncNotifierProvider<PlayHistoryNotifier, List<RecentPlayback>>(
      PlayHistoryNotifier.new,
    );

/// What 最近观看 lists: history minus the sources the user switched off.
///
/// Derived, not filtered in the notifier, for the same reason favourites are:
/// clearing and deleting history walk the full list. Nothing is removed from
/// the database — switching the source back on restores the entries.
final visiblePlayHistoryProvider = Provider<AsyncValue<List<RecentPlayback>>>((
  ref,
) {
  final disabled = ref.watch(disabledDataSourceIdsProvider);
  return ref
      .watch(playHistoryProvider)
      .whenData(
        (all) =>
            all.where((r) => !disabled.contains(r.video.sourceId)).toList(),
      );
});

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
    final next = await AsyncValue.guard(() => build());
    // A fresh AsyncData is a new state even when its contents are identical,
    // and crossSourceWatchesProvider re-queries on top of it — so assigning an
    // unchanged reload rebuilds every visible card twice per cmd-tab back.
    // Content is compared by value (identity never matches: the repository
    // builds new objects per load); errors and first data always land.
    final current = state.asData?.value;
    final fresh = next.asData?.value;
    if (current != null && fresh != null && _samePlaybacks(current, fresh)) {
      return;
    }
    state = next;
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

/// Deep equality for [PlayHistoryNotifier.manualRefresh]'s no-op check. The
/// domain classes carry no operator== and that refresh is the only caller that
/// needs one, so the comparison lives here, field by field, instead of on the
/// models.
bool _samePlaybacks(List<RecentPlayback> a, List<RecentPlayback> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (!_sameVideoHistory(a[i].video, b[i].video)) return false;
    if (!_sameEpisodeHistory(a[i].lastEpisode, b[i].lastEpisode)) return false;
  }
  return true;
}

bool _sameVideoHistory(VideoHistory a, VideoHistory b) =>
    a.id == b.id &&
    a.sourceId == b.sourceId &&
    a.videoId == b.videoId &&
    a.videoTitle == b.videoTitle &&
    a.coverUrl == b.coverUrl &&
    a.rating == b.rating &&
    a.type == b.type &&
    a.region == b.region &&
    a.year == b.year &&
    a.actor == b.actor &&
    a.version == b.version &&
    a.hits == b.hits &&
    a.remarks == b.remarks &&
    a.blurb == b.blurb &&
    a.lastEpisodeIndex == b.lastEpisodeIndex &&
    a.lastEpisodeTitle == b.lastEpisodeTitle &&
    a.updatedAt == b.updatedAt;

bool _sameEpisodeHistory(EpisodeHistory? a, EpisodeHistory? b) {
  if (a == null || b == null) return identical(a, b);
  return a.id == b.id &&
      a.sourceId == b.sourceId &&
      a.videoId == b.videoId &&
      a.episodeIndex == b.episodeIndex &&
      a.positionMillis == b.positionMillis &&
      a.durationMillis == b.durationMillis &&
      a.updatedAt == b.updatedAt;
}
