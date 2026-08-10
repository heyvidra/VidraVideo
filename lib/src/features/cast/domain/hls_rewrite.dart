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
/// e.g. `http://192.168.1.9:8899/proxy`.
///
/// Master playlists need no special case: a variant line is a URI line like
/// any other, so it comes back through the proxy and is rewritten in turn.
String rewriteHlsPlaylist({
  required String playlist,
  required Uri playlistUrl,
  required String proxyBase,
  String? extraQuery,
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

    if (line.isEmpty || line.startsWith('#')) {
      // Tags pass through untouched. Nothing our sources emit carries a URI
      // in an attribute — neither catalog encrypts, so there is no
      // #EXT-X-KEY:URI= to follow — and rewriting attributes blindly would
      // corrupt tags we do not understand.
      out.write(line);
    } else {
      out.write(
        proxyUrlFor(
          playlistUrl.resolve(line.trim()),
          proxyBase,
          extraQuery: extraQuery,
        ),
      );
    }
    if (!isLast) out.write('\n');
  }
  return out.toString();
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
