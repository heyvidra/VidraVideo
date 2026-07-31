class VideoHistory {
  final int id;
  final String? sourceId;
  final int videoId;

  final String videoTitle;
  final String coverUrl;

  // Extra fields for PopularVideoCard
  final String? rating;
  final String type;
  final String? region;
  final String? year;
  final String? actor;
  final String? version;
  final int? hits;
  final String? remarks;
  final String? blurb;

  final int lastEpisodeIndex;
  final String? lastEpisodeTitle;

  final DateTime updatedAt;

  VideoHistory({
    this.id = 0,
    this.sourceId,
    required this.videoId,
    required this.videoTitle,
    required this.coverUrl,
    required this.lastEpisodeIndex,
    this.lastEpisodeTitle,
    this.rating,
    required this.type,
    this.region,
    this.year,
    this.actor,
    this.version,
    this.hits,
    this.remarks,
    this.blurb,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  /// Only the fields the repository normalizes; extend if needed.
  VideoHistory copyWith({int? id, String? sourceId}) {
    return VideoHistory(
      id: id ?? this.id,
      sourceId: sourceId ?? this.sourceId,
      videoId: videoId,
      videoTitle: videoTitle,
      coverUrl: coverUrl,
      lastEpisodeIndex: lastEpisodeIndex,
      lastEpisodeTitle: lastEpisodeTitle,
      rating: rating,
      type: type,
      region: region,
      year: year,
      actor: actor,
      version: version,
      hits: hits,
      remarks: remarks,
      blurb: blurb,
      updatedAt: updatedAt,
    );
  }
}

class EpisodeHistory {
  final int id;
  final String? sourceId;
  final int videoId;
  final int episodeIndex;
  final int positionMillis;
  final int durationMillis;
  final DateTime updatedAt;

  EpisodeHistory({
    this.id = 0,
    this.sourceId,
    required this.videoId,
    required this.episodeIndex,
    required this.positionMillis,
    required this.durationMillis,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  EpisodeHistory copyWith({int? id, String? sourceId}) {
    return EpisodeHistory(
      id: id ?? this.id,
      sourceId: sourceId ?? this.sourceId,
      videoId: videoId,
      episodeIndex: episodeIndex,
      positionMillis: positionMillis,
      durationMillis: durationMillis,
      updatedAt: updatedAt,
    );
  }
}

/// A recent-play row together with how far into it the viewer got.
class RecentPlayback {
  final VideoHistory video;
  final EpisodeHistory? lastEpisode;

  const RecentPlayback({required this.video, this.lastEpisode});

  double get progress =>
      (lastEpisode == null || lastEpisode!.durationMillis <= 0)
      ? 0.0
      : (lastEpisode!.positionMillis / lastEpisode!.durationMillis).clamp(
          0.0,
          1.0,
        );

  Duration get position =>
      Duration(milliseconds: lastEpisode?.positionMillis ?? 0);
}

/// Whether this kind of content is measured in episodes.
///
/// Sources file a film's playback lines under the episode list and name them
/// things like 立即播放 / 粤语播放 / 英语播放 — audio tracks and mirrors, not
/// instalments. Echoing one back reads as nonsense ("看到 立即播放"), so a film
/// is located by its timestamp instead.
bool isEpisodicType(String? type) => !(type ?? '').contains('电影');
