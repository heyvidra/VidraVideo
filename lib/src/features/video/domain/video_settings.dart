class VideoSettings {
  final int id;
  final String? sourceId;
  final int videoId;

  // Intro/outro skip durations in seconds
  final int introDuration;
  final int outroDuration;

  /// Whether the two durations above are acted on at all.
  final bool autoSkip;

  const VideoSettings({
    this.id = 0,
    this.sourceId,
    required this.videoId,
    this.introDuration = 0,
    this.outroDuration = 0,
    this.autoSkip = true,
  });

  VideoSettings copyWith({int? id, String? sourceId}) {
    return VideoSettings(
      id: id ?? this.id,
      sourceId: sourceId ?? this.sourceId,
      videoId: videoId,
      introDuration: introDuration,
      outroDuration: outroDuration,
      autoSkip: autoSkip,
    );
  }
}
