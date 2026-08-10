import '../../video/domain/episode_number.dart';
import '../../video/domain/video_collection.dart';

/// What a show looks like once it is on its way to a TV.
class CastPlaylist {
  const CastPlaylist({
    required this.title,
    required this.items,
    this.startIndex = 0,
    this.startPositionSeconds = 0,
  });

  final String title;
  final List<CastItem> items;
  final int startIndex;
  final int startPositionSeconds;

  /// The episode number behind playlist position [index], or null when the
  /// report names a position this playlist does not have.
  int? sourceIndexOf(int index) =>
      index >= 0 && index < items.length ? items[index].sourceIndex : null;
}

class CastItem {
  const CastItem({
    required this.title,
    required this.url,
    required this.sourceIndex,
  });

  final String title;
  final String url;

  /// Where this episode sits in `Video.urls`.
  ///
  /// Not the same as its position in [CastPlaylist.items]: episodes with no
  /// playable URL are dropped, so the two drift apart by however many were
  /// dropped before it. Every watch-history row in the app is keyed by the
  /// SOURCE index, so this is what has to come back — reporting the playlist
  /// position wrote 第8集's progress onto 第7集.
  final int sourceIndex;
}

/// Progress reported back by whatever is playing on the TV.
///
/// Carries the PLAYLIST position, because that is all either route knows —
/// the web page counts its own array, and DLNA reports the queue index.
/// [CastPlaylist.sourceIndexOf] turns it back into an episode number.
class CastProgress {
  const CastProgress({
    required this.playlistIndex,
    required this.position,
    required this.duration,
  });

  final int playlistIndex;
  final Duration position;
  final Duration duration;
}

/// How a given TV wants to be handed a show.
enum CastRoute {
  /// Push the stream URL and let the renderer play it. What every DLNA box
  /// does, and what gives us play/pause/seek and a position to read back.
  dlna,

  /// Serve a page and point the TV's browser at it. Samsung: its renderer
  /// refuses an HLS playlist, but its browser plays one in a `<video>` tag.
  browser,
}

/// Builds the playlist for casting [video] starting at [episodeIndex].
///
/// Episodes with no playable URL are dropped rather than sent — a renderer
/// handed an empty URI shows an error the viewer cannot act on — and
/// [CastPlaylist.startIndex] is corrected for anything dropped before it, so
/// "cast episode 7" opens episode 7 and not whatever slid into that slot.
CastPlaylist? buildCastPlaylist({
  required Video video,
  required int episodeIndex,
  int startPositionSeconds = 0,
}) {
  final episodes = video.urls ?? const <VideoEpisode>[];
  final items = <CastItem>[];
  var start = 0;
  var seenPlayable = 0;
  for (var i = 0; i < episodes.length; i++) {
    final url = episodes[i].url;
    if (url == null || url.trim().isEmpty) continue;
    if (i <= episodeIndex) start = seenPlayable;
    seenPlayable++;
    items.add(
      CastItem(
        title: episodeLabel(episodes[i].title, index: i),
        url: url.trim(),
        sourceIndex: i,
      ),
    );
  }
  if (items.isEmpty) return null;
  return CastPlaylist(
    title: video.title,
    items: items,
    startIndex: start.clamp(0, items.length - 1),
    startPositionSeconds: startPositionSeconds,
  );
}
