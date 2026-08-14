/// Rewrites an HLS playlist so every URI in it points back at our own proxy.
///
/// The TV fetches the playlist from us, then fetches what the playlist names —
/// and it fetches those directly from the CDN unless we intervene. Rewriting
/// is what keeps the whole chain on our side, which is what lets the proxy
/// attach the headers the source expects, downgrade https for renderers with
/// no TLS, and keep working when the CDN would have refused the TV.
///
/// [playlist] is the raw text, [playlistUrl] the absolute URL it came from
/// (relative entries resolve against it), and [proxyBase] our own endpoint,
/// e.g. `http://192.168.1.9:8899/proxy`. [onUri] is told every absolute URL
/// this rewrote, which is how the proxy learns the origins a playlist needs
/// before the renderer comes back asking for them.
///
/// Master playlists need no special case: a variant line is a URI line like
/// any other, so it comes back through the proxy and is rewritten in turn.
String rewriteHlsPlaylist({
  required String playlist,
  required Uri playlistUrl,
  required String proxyBase,
  String? extraQuery,
  void Function(Uri target)? onUri,
}) {
  final out = StringBuffer();
  // Split on \n and strip \r rather than splitting on line terminators: the
  // output has to stay line-for-line with the input so byte-range and
  // discontinuity tags keep the entry they describe.
  final lines = playlist.split('\n');
  for (var i = 0; i < lines.length; i++) {
    final raw = lines[i];
    final line = raw.trimRight();
    final isLast = i == lines.length - 1;

    if (line.isEmpty) {
      out.write(line);
    } else if (line.startsWith('#')) {
      // Four tags carry their URI in a quoted attribute instead of on a line
      // of their own, and the television fetches those URIs exactly as it
      // fetches a segment — so a raw CDN link in one is a request it cannot
      // make: no TLS, no User-Agent, and on #EXT-X-KEY that is an episode
      // that never decrypts. Only those four are touched. Everything else
      // passes through byte for byte, because rewriting the attributes of a
      // tag we do not understand would corrupt it.
      out.write(
        _rewriteTagUri(
          line,
          playlistUrl: playlistUrl,
          proxyBase: proxyBase,
          extraQuery: extraQuery,
          onUri: onUri,
        ),
      );
    } else {
      final target = playlistUrl.resolve(line.trim());
      onUri?.call(target);
      out.write(proxyUrlFor(target, proxyBase, extraQuery: extraQuery));
    }
    if (!isLast) out.write('\n');
  }
  return out.toString();
}

/// The tags whose URI is an attribute. Nothing else is rewritten in place.
final RegExp _uriAttributeTag = RegExp(
  r'^#EXT-X-(?:I-FRAME-STREAM-INF|KEY|SESSION-KEY|MAP):',
);

final RegExp _uriAttribute = RegExp(r'URI="([^"]*)"');

/// [line] with its `URI="…"` pointed at the proxy, or [line] itself when the
/// tag has no URI to point anywhere — `#EXT-X-KEY:METHOD=NONE` is a tag with
/// no attribute at all.
String _rewriteTagUri(
  String line, {
  required Uri playlistUrl,
  required String proxyBase,
  String? extraQuery,
  void Function(Uri target)? onUri,
}) {
  if (!_uriAttributeTag.hasMatch(line)) return line;
  return line.replaceAllMapped(_uriAttribute, (m) {
    final value = m.group(1)!.trim();
    // An empty URI resolves to the playlist itself, which would point the
    // renderer at a key that is a playlist. Leave nonsense as we found it.
    if (value.isEmpty) return m.group(0)!;
    final target = playlistUrl.resolve(value);
    onUri?.call(target);
    return 'URI="${proxyUrlFor(target, proxyBase, extraQuery: extraQuery)}"';
  });
}

/// The proxy URL that fetches [target] on the renderer's behalf.
///
/// [extraQuery] carries the session token, which every rewritten line needs:
/// the renderer fetches segments straight from what the playlist says, and
/// an untokened URL is one the server will answer with 404.
String proxyUrlFor(Uri target, String proxyBase, {String? extraQuery}) {
  final url = '$proxyBase?url=${Uri.encodeQueryComponent(target.toString())}';
  return extraQuery == null || extraQuery.isEmpty ? url : '$url&$extraQuery';
}

/// Whether [contentType] or [url] says this response is a playlist and so
/// needs rewriting before the renderer sees it.
///
/// Content type alone is not enough: one of our sources serves playlists as
/// `application/octet-stream`, so the extension has to vote too.
bool looksLikePlaylist(String? contentType, Uri url) {
  final ct = (contentType ?? '').toLowerCase();
  if (ct.contains('mpegurl')) return true;
  return url.path.toLowerCase().endsWith('.m3u8');
}

/// A media playlist cut down so that it begins part-way into the episode,
/// and what that cut landed on.
class HlsSlice {
  const HlsSlice({
    required this.playlist,
    required this.startSeconds,
    required this.totalSeconds,
    required this.isMedia,
  });

  /// The playlist to serve.
  final String playlist;

  /// Where [playlist] now starts in the original episode's timeline. Zero
  /// whenever nothing was cut, which is also what gets echoed back to the
  /// renderer, so it must describe what was actually served and not what was
  /// asked for.
  final double startSeconds;

  /// The whole episode as the source playlist described it — every #EXTINF
  /// added up, including the segments that were cut.
  final double totalSeconds;

  /// Whether this was a media playlist at all. A master carries no #EXTINF,
  /// so there is nothing in it to cut and no timeline to seek in; the offset
  /// has to travel down to the variant instead.
  final bool isMedia;
}

/// [playlist] beginning at [offsetSeconds] instead of at zero.
///
/// This is how a resume survives a renderer that will not seek. Handing it a
/// playlist whose first segment is the one twelve minutes in needs nothing
/// from the renderer but the ability to play what it was given, which is the
/// one thing every renderer can do. #EXT-X-MEDIA-SEQUENCE moves up by the
/// number of segments dropped, because a player counts segments from that
/// number and not from the top of the file.
///
/// The cut lands on the segment CONTAINING [offsetSeconds], never the one
/// after it: resuming a few seconds early costs a rewatch nobody notices,
/// resuming late drops content the viewer never saw. An offset at or past the
/// end returns the playlist untouched for the same kind of reason — replaying
/// an episode is a worse evening than the one an empty playlist gives, which
/// a renderer reports as a broken stream.
///
/// #EXT-X-KEY and #EXT-X-MAP are state rather than decoration: whichever were
/// in force at the cut are re-emitted above the first surviving segment even
/// when the segment that declared them is gone, or the renderer decrypts with
/// no key and demuxes with no initialisation segment.
HlsSlice sliceMediaPlaylist({
  required String playlist,
  required double offsetSeconds,
}) {
  final lines = playlist.split('\n');
  final header = <String>[];
  final segments = <_Segment>[];
  final pending = <String>[];
  // Whether the header is closed (the first #EXTINF has been seen) and
  // whether the lines waiting in [pending] describe a segment yet.
  var started = false;
  var open = false;

  for (final raw in lines) {
    final line = raw.trimRight();
    if (line.startsWith('#EXTINF')) {
      started = true;
      open = true;
      pending.add(raw);
    } else if (line.isEmpty || line.startsWith('#')) {
      if (!started && !_isSegmentTag(line)) {
        header.add(raw);
      } else {
        pending.add(raw);
      }
    } else if (!open) {
      // A URI line with no #EXTINF above it is a master's variant, not a
      // segment. Nothing here can cut a master, so it just rides along.
      pending.add(raw);
    } else {
      segments.add(_Segment([...pending, raw]));
      pending.clear();
      open = false;
    }
  }
  final trailer = List<String>.from(pending);

  if (segments.isEmpty) {
    return HlsSlice(
      playlist: playlist,
      startSeconds: 0,
      totalSeconds: 0,
      isMedia: false,
    );
  }
  var total = 0.0;
  for (final s in segments) {
    total += s.duration;
  }
  // Not `offsetSeconds <= 0`: a NaN offset has to land here too.
  if (!(offsetSeconds > 0) || offsetSeconds >= total) {
    return HlsSlice(
      playlist: playlist,
      startSeconds: 0,
      totalSeconds: total,
      isMedia: true,
    );
  }

  var start = 0.0;
  var cut = 0;
  while (cut < segments.length - 1 &&
      start + segments[cut].duration <= offsetSeconds) {
    start += segments[cut].duration;
    cut++;
  }
  if (cut == 0) {
    return HlsSlice(
      playlist: playlist,
      startSeconds: 0,
      totalSeconds: total,
      isMedia: true,
    );
  }

  // Generated lines match the terminator the source used: a lone \n dropped
  // into a CRLF playlist is legal but reads as damage to anyone debugging one.
  final eol = header.isNotEmpty && header.first.endsWith('\r') ? '\r' : '';
  final sequence = (_headerNumber(header, '#EXT-X-MEDIA-SEQUENCE') ?? 0) + cut;
  final discontinuities = _headerNumber(
    header,
    '#EXT-X-DISCONTINUITY-SEQUENCE',
  );
  var dropped = 0;
  for (var i = 0; i < cut; i++) {
    if (segments[i].hasDiscontinuity) dropped++;
  }

  final out = <String>[];
  var wroteSequence = false;
  for (final line in header) {
    final tag = line.trimRight();
    if (tag.startsWith('#EXT-X-MEDIA-SEQUENCE:')) {
      out.add('#EXT-X-MEDIA-SEQUENCE:$sequence$eol');
      wroteSequence = true;
    } else if (discontinuities != null &&
        tag.startsWith('#EXT-X-DISCONTINUITY-SEQUENCE:')) {
      out.add('#EXT-X-DISCONTINUITY-SEQUENCE:${discontinuities + dropped}$eol');
    } else {
      out.add(line);
    }
  }
  if (!wroteSequence) {
    // A playlist that never declared one was counting from zero, and now is
    // not. Straight under #EXTM3U, where every player looks for it.
    final at = out.indexWhere((l) => l.trimRight() == '#EXTM3U');
    out.insert(at + 1, '#EXT-X-MEDIA-SEQUENCE:$sequence$eol');
  }

  String? key;
  String? map;
  for (var i = 0; i < cut; i++) {
    key = segments[i].keyLine ?? key;
    map = segments[i].mapLine ?? map;
  }
  // Unless the surviving segment declares its own, in which case ours would
  // be an override that is about to be overridden.
  if (key != null && segments[cut].keyLine == null) out.add(key);
  if (map != null && segments[cut].mapLine == null) out.add(map);

  for (var i = cut; i < segments.length; i++) {
    out.addAll(segments[i].lines);
  }
  out.addAll(trailer);
  return HlsSlice(
    playlist: out.join('\n'),
    startSeconds: start,
    totalSeconds: total,
    isMedia: true,
  );
}

/// One segment: its own tags, in the order they were written, and the URI
/// line that closes it.
class _Segment {
  _Segment(this.lines);

  final List<String> lines;

  double get duration {
    for (final line in lines) {
      if (!line.startsWith('#EXTINF:')) continue;
      final value = line.substring('#EXTINF:'.length).split(',').first;
      return double.tryParse(value.trim()) ?? 0;
    }
    return 0;
  }

  bool get hasDiscontinuity =>
      lines.any((l) => l.trimRight() == '#EXT-X-DISCONTINUITY');

  String? get keyLine => _lineStartingWith('#EXT-X-KEY:');

  String? get mapLine => _lineStartingWith('#EXT-X-MAP:');

  String? _lineStartingWith(String tag) {
    String? found;
    // The last one wins: two keys in one segment's tags means a rotation, and
    // it is the second that decrypts what follows.
    for (final line in lines) {
      if (line.startsWith(tag)) found = line;
    }
    return found;
  }
}

/// Whether [line] describes the segment below it rather than the playlist as
/// a whole — the difference between a tag that survives a cut and one that
/// leaves with the segments it belonged to.
bool _isSegmentTag(String line) {
  // Sequence numbers are playlist-level and the prefix collides.
  if (line.startsWith('#EXT-X-DISCONTINUITY-SEQUENCE')) return false;
  return const [
    '#EXT-X-KEY:',
    '#EXT-X-MAP:',
    '#EXT-X-BYTERANGE:',
    '#EXT-X-DISCONTINUITY',
    '#EXT-X-PROGRAM-DATE-TIME:',
    '#EXT-X-DATERANGE:',
    '#EXT-X-BITRATE:',
    '#EXT-X-GAP',
  ].any(line.startsWith);
}

int? _headerNumber(List<String> header, String tag) {
  for (final line in header) {
    final t = line.trimRight();
    if (t.startsWith('$tag:')) {
      return int.tryParse(t.substring(tag.length + 1).trim());
    }
  }
  return null;
}
