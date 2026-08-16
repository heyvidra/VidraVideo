import 'package:vidra_player/vidra_player.dart';
import 'package:vidra_player_kit/vidra_player_kit.dart';

import 'browser_headers.dart';
import 'browser_identity.dart';

/// Makes the playback engine present the same browser as everything else.
///
/// This is the request that matters most and the one nothing in this repo
/// could reach: the video itself is fetched by libmdk, several layers down
/// through fvp and `video_player`, from a URL the app hands over as a bare
/// string. The player package was already sending a User-Agent and a Referer
/// on it — but a Chrome version of its own, sixteen majors from the one the
/// cast proxy used, so the same stream looked like a different client
/// depending on which path fetched it.
///
/// Overriding the adapter's header hook is the whole mechanism. It is
/// `@protected`, which restricts calling rather than overriding, and fvp
/// converts whatever comes back into libmdk's `avio.headers` — so these land
/// on the real playlist and segment requests, not on a probe.
class BrowserHeaderPlayerAdapter extends VideoPlayerAdapter {
  @override
  Map<String, String>? getHttpProxyHeaders(VideoSource source) {
    if (source.type != VideoSourceType.network) return null;
    final uri = Uri.tryParse(source.path);
    if (uri == null) return null;
    // No client hints and no Sec-Fetch-*: this is a media element fetching a
    // stream, not a page's XHR, and the two send different sets. What has to
    // match across the app is the browser being claimed — the User-Agent.
    return {
      'User-Agent': BrowserIdentity.userAgent,
      'Referer': BrowserHeaders.refererFor(uri),
      'Accept-Language': BrowserHeaders.acceptLanguage,
    };
  }
}
