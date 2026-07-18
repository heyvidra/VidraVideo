import '../../../core/utils/format.dart';

/// Parsed result of a vidraDlp `extract()` call — the subset of the native
/// `MediaEntry` schema the download-by-URL UI needs. All parsing is tolerant of
/// missing/renamed fields so a schema bump can't crash the screen.
class MediaInfo {
  final String title;

  /// Canonical page URL to hand back to `download()` (it re-extracts by URL, so
  /// this survives direct-media-URL expiry).
  final String webpageUrl;
  final double? durationSecs;
  final String? thumbnailUrl;
  final String? uploader;
  final List<MediaFormat> formats;
  final List<PlaylistItem> playlistEntries;

  const MediaInfo({
    required this.title,
    required this.webpageUrl,
    this.durationSecs,
    this.thumbnailUrl,
    this.uploader,
    this.formats = const [],
    this.playlistEntries = const [],
  });

  bool get isPlaylist => playlistEntries.isNotEmpty;

  /// Progressive (muxed) formats first — a single downloaded file with both
  /// video and audio. These are the only ones safe to select as one artifact.
  List<MediaFormat> get muxedFormats =>
      formats.where((f) => f.isMuxed).toList();

  factory MediaInfo.fromJson(Map<String, dynamic> json, String requestedUrl) {
    final formats = (json['formats'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(MediaFormat.fromJson)
        .toList();

    final playlist = json['playlist'] as Map<String, dynamic>?;
    final entries = (playlist?['entries'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(PlaylistItem.fromJson)
        .where((e) => e.url != null && e.url!.isNotEmpty)
        .toList();

    return MediaInfo(
      title: (json['title'] as String?)?.trim().isNotEmpty == true
          ? json['title'] as String
          : (playlist?['playlist_title'] as String? ?? requestedUrl),
      webpageUrl: (json['webpage_url'] as String?)?.isNotEmpty == true
          ? json['webpage_url'] as String
          : requestedUrl,
      durationSecs: (json['duration'] as num?)?.toDouble(),
      thumbnailUrl: _bestThumbnail(json['thumbnails']),
      uploader: json['uploader'] as String?,
      formats: formats,
      playlistEntries: entries,
    );
  }

  /// Largest thumbnail by pixel area (falls back to the first with a URL).
  static String? _bestThumbnail(dynamic thumbnails) {
    if (thumbnails is! List) return null;
    Map<String, dynamic>? best;
    int bestArea = -1;
    for (final t in thumbnails) {
      if (t is! Map<String, dynamic>) continue;
      final url = t['url'] as String?;
      if (url == null || url.isEmpty) continue;
      final area =
          ((t['width'] as num?)?.toInt() ?? 0) *
          ((t['height'] as num?)?.toInt() ?? 0);
      if (best == null || area > bestArea) {
        best = t;
        bestArea = area;
      }
    }
    return best?['url'] as String?;
  }
}

class MediaFormat {
  final String formatId;
  final String ext;
  final int? width;
  final int? height;
  final String? vcodec;
  final String? acodec;
  final int? filesizeBytes;

  const MediaFormat({
    required this.formatId,
    required this.ext,
    this.width,
    this.height,
    this.vcodec,
    this.acodec,
    this.filesizeBytes,
  });

  /// Has both a video and an audio stream → downloads as one playable file.
  bool get isMuxed => _present(vcodec) && _present(acodec);
  bool get isAudioOnly => _present(acodec) && !_present(vcodec);
  bool get isVideoOnly => _present(vcodec) && !_present(acodec);

  /// H.264-in-MP4 video-only stream — muxable with AAC into a single mp4 by the
  /// SDK's in-Rust muxer (used for HD, where YouTube has no muxed format).
  bool get isAvcMp4VideoOnly =>
      isVideoOnly && ext == 'mp4' && (vcodec?.startsWith('avc') ?? false);

  static bool _present(String? codec) =>
      codec != null && codec.isNotEmpty && codec != 'none';

  /// e.g. "1080p · mp4 · 45.2 MB" or "audio · m4a · 3.1 MB".
  String get label {
    final quality = height != null
        ? '${height}p'
        : (isAudioOnly ? 'audio' : formatId);
    final size = filesizeBytes != null ? ' · ${formatBytes(filesizeBytes!)}' : '';
    return '$quality · $ext$size';
  }

  factory MediaFormat.fromJson(Map<String, dynamic> json) {
    return MediaFormat(
      formatId: json['format_id'] as String? ?? '',
      ext: json['ext'] as String? ?? '',
      width: (json['width'] as num?)?.toInt(),
      height: (json['height'] as num?)?.toInt(),
      vcodec: json['vcodec'] as String?,
      acodec: json['acodec'] as String?,
      filesizeBytes: (json['filesize'] as num?)?.toInt(),
    );
  }
}

class PlaylistItem {
  final String? title;
  final String? url;
  final int? index;
  final double? duration;
  final String? thumbnail;

  const PlaylistItem({
    this.title,
    this.url,
    this.index,
    this.duration,
    this.thumbnail,
  });

  factory PlaylistItem.fromJson(Map<String, dynamic> json) {
    return PlaylistItem(
      title: json['title'] as String?,
      url: json['url'] as String?,
      index: (json['index'] as num?)?.toInt(),
      duration: (json['duration'] as num?)?.toDouble(),
      thumbnail: json['thumbnail'] as String?,
    );
  }
}

