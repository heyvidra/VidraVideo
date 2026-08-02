import 'dart:async'; // Add async import
import 'dart:typed_data';
import 'package:drift/drift.dart' show Value;
import 'package:vidra_player/core/interfaces/media_repository.dart';
import 'package:vidra_player/core/model/model.dart' as vidra_model;
import '../../data/database/app_database.dart' as db;
import '../../features/video/data/history_repository.dart';
import '../../features/video/data/video_repository.dart';
import '../../features/video/domain/video_collection.dart' show Video;
import '../../features/video/domain/play_history.dart' as domain;
import '../../features/video/domain/video_settings.dart' as domain;

// Utility for throttling native database/channel calls
class _HistoryThrottler {
  final Duration _duration;
  Timer? _timer;
  void Function()? _pendingAction;

  _HistoryThrottler(this._duration);

  void run(void Function() action) {
    _pendingAction = action;
    if (_timer?.isActive ?? false) return;
    _timer = Timer(_duration, () {
      _pendingAction?.call();
      _pendingAction = null;
    });
  }

  void flush() {
    _timer?.cancel();
    _pendingAction?.call();
    _pendingAction = null;
  }

  void dispose() {
    flush();
  }
}

class VidraMediaRepository
    implements MediaRepository, EpisodeMarkerStore, EpisodeHashStore {
  final VideoRepository _videoRepository;
  final HistoryRepository _historyRepository;

  // Throttle saves to once every 5 seconds to reduce native pressure and leaks
  final _saveThrottler = _HistoryThrottler(const Duration(seconds: 5));

  final Map<String, int> _lastSavedPosition = {};

  // Cache the Video per session so the throttled (every ~5s) history save
  // doesn't re-read + re-map it from the DB on every tick.
  final Map<String, Video> _videoCache = {};

  VidraMediaRepository(this._videoRepository, this._historyRepository);

  void dispose() {
    _saveThrottler.dispose();
  }

  ({int apiId, String? sourceId}) _parseVideoId(String videoId) {
    final parts = videoId.split('_');
    if (parts.length >= 2) {
      final apiId = int.tryParse(parts[0]) ?? -1;
      final sourceStr = parts.sublist(1).join('_');
      // If the source string is literally "null", treat it as null
      final sourceId = (sourceStr == "null" || sourceStr.isEmpty)
          ? null
          : sourceStr;
      return (apiId: apiId, sourceId: sourceId);
    }
    return (apiId: int.tryParse(videoId) ?? -1, sourceId: null);
  }

  @override
  Future<List<vidra_model.EpisodeHistory>> getEpisodeHistories({
    required String videoId,
  }) async {
    final parsed = _parseVideoId(videoId);
    final histories = await _historyRepository.getEpisodeHistories(
      parsed.apiId,
      parsed.sourceId,
    );
    return histories
        .map(
          (h) => vidra_model.EpisodeHistory(
            index: h.episodeIndex,
            positionMillis: h.positionMillis,
            durationMillis: h.durationMillis,
          ),
        )
        .toList();
  }

  @override
  Future<void> saveEpisodeHistory(
    String videoId,
    vidra_model.EpisodeHistory history,
  ) async {
    // 1. Fast check: if position change is less than 1 second, skip (Fast check)
    final cacheKey = "${videoId}_${history.index}";
    final lastPos = _lastSavedPosition[cacheKey] ?? 0;
    if (history.positionMillis > 0 &&
        (history.positionMillis - lastPos).abs() < 1000) {
      return;
    }

    final parsed = _parseVideoId(videoId);

    // 2. Throttle the actual heavy save operation (DB + potential native calls)
    _saveThrottler.run(() async {
      // Save progress only (lightweight operation)
      final domainHistory = domain.EpisodeHistory(
        videoId: parsed.apiId,
        episodeIndex: history.index,
        positionMillis: history.positionMillis,
        durationMillis: history.durationMillis,
        sourceId: parsed.sourceId,
      );

      await _historyRepository.saveEpisodeHistory(domainHistory);
      _lastSavedPosition[cacheKey] = history.positionMillis;

      // 3. Update VideoHistory (affects recent play list)
      _maybeUpdateVideoHistory(parsed, history);
    });
  }

  /// Internal method: low frequency update of video metadata
  Future<void> _maybeUpdateVideoHistory(
    ({int apiId, String? sourceId}) parsed,
    vidra_model.EpisodeHistory history,
  ) async {
    // Logic: update every minute, or only on first play
    // Keep it simple: update if it's the first minute, or if it's been a long time since last update
    // This can effectively reduce the frequency of "olevod" string creation in memory
    final cacheKey = '${parsed.apiId}_${parsed.sourceId}';
    final video =
        _videoCache[cacheKey] ??
        await _videoRepository.getVideo(
          parsed.apiId,
          sourceId: parsed.sourceId,
        );
    if (video != null) {
      _videoCache[cacheKey] = video;
      final lastEpisode =
          (video.urls != null && video.urls!.length > history.index)
          ? video.urls![history.index]
          : null;

      final videoHistory = domain.VideoHistory(
        videoId: parsed.apiId,
        videoTitle: video.title,
        coverUrl: video.coverUrl,
        lastEpisodeIndex: history.index,
        lastEpisodeTitle: lastEpisode?.title,
        type: video.type,
        rating: video.rating.toString(),
        region: video.region,
        year: video.year,
        actor: video.actor,
        version: video.version,
        hits: video.hits,
        remarks: video.remarks,
        blurb: video.blurb,
        sourceId: parsed.sourceId,
      );
      await _historyRepository.saveVideoHistory(videoHistory);
    }
  }

  @override
  Future<vidra_model.PlayerSetting> getPlayerSettings({
    required String videoId,
  }) async {
    final parsed = _parseVideoId(videoId);
    final settings = await _videoRepository.getVideoSettings(
      parsed.apiId,
      parsed.sourceId,
    );
    return vidra_model.PlayerSetting(
      videoId: videoId,
      autoSkip: settings.autoSkip,
      skipIntro: settings.introDuration,
      skipOutro: settings.outroDuration,
    );
  }

  @override
  Future<void> savePlayerSettings(vidra_model.PlayerSetting setting) async {
    final parsed = _parseVideoId(setting.videoId);
    final domainSettings = domain.VideoSettings(
      videoId: parsed.apiId,
      sourceId: parsed.sourceId,
      introDuration: setting.skipIntro,
      outroDuration: setting.skipOutro,
      autoSkip: setting.autoSkip,
    );
    await _videoRepository.saveVideoSettings(domainSettings);
  }

  // --- Per-episode skip markers ---

  @override
  Future<List<vidra_model.EpisodeMarkers>> getEpisodeMarkers({
    required String videoId,
  }) async {
    final parsed = _parseVideoId(videoId);
    final rows = await _historyRepository.getEpisodeSkipData(
      parsed.apiId,
      parsed.sourceId,
    );
    return [
      for (final r in rows)
        if (r.introEndMillis != null || r.outroStartMillis != null)
          vidra_model.EpisodeMarkers(
            episodeIndex: r.episodeIndex,
            introEnd: _millis(r.introEndMillis),
            outroStart: _millis(r.outroStartMillis),
            // Precedence has to survive the round trip, or a detected intro
            // read back as `manual` would block the user from ever correcting
            // it. Out-of-range values fall back to the weakest source.
            source:
                vidra_model.MarkerSource.values.elementAtOrNull(
                  r.markerSource ?? -1,
                ) ??
                vidra_model.MarkerSource.chapter,
          ),
    ];
  }

  @override
  Future<void> saveEpisodeMarkers(
    String videoId,
    vidra_model.EpisodeMarkers markers,
  ) async {
    final parsed = _parseVideoId(videoId);
    await _historyRepository.saveEpisodeSkipData(
      parsed.apiId,
      markers.episodeIndex,
      parsed.sourceId,
      db.EpisodeSkipDataCompanion(
        // Written unconditionally, including as null: `clear` markers exist
        // precisely so a wrong boundary can be taken away, and an absent value
        // would leave the old one in the row.
        introEndMillis: Value(markers.introEnd?.inMilliseconds),
        outroStartMillis: Value(markers.outroStart?.inMilliseconds),
        markerSource: Value(markers.source.index),
      ),
    );
  }

  // --- Sweep hashes (what cross-episode detection compares) ---

  @override
  Future<Map<int, List<int>>> getEpisodeHashes({
    required String videoId,
  }) async {
    final parsed = _parseVideoId(videoId);
    final rows = await _historyRepository.getEpisodeSkipData(
      parsed.apiId,
      parsed.sourceId,
    );
    return {
      for (final r in rows)
        if (r.sweepHashes != null) r.episodeIndex: r.sweepHashes!,
    };
  }

  @override
  Future<void> saveEpisodeHashes(
    String videoId,
    int episodeIndex,
    List<int> hashes,
  ) async {
    final parsed = _parseVideoId(videoId);
    await _historyRepository.saveEpisodeSkipData(
      parsed.apiId,
      episodeIndex,
      parsed.sourceId,
      db.EpisodeSkipDataCompanion(
        sweepHashes: Value(Uint8List.fromList(hashes)),
      ),
    );
  }

  static Duration? _millis(int? value) =>
      value == null ? null : Duration(milliseconds: value);
}
