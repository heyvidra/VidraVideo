import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import '../../../core/utils/log.dart';
import '../domain/cast_target.dart';
import '../domain/hls_rewrite.dart';

/// The LAN-facing half of casting: a player page for televisions that will
/// not take a stream, and a proxy that stands between the renderer and the
/// CDN.
///
/// Samsung is the reason this exists. Its DLNA renderer refuses an HLS
/// playlist outright, but the Tizen browser plays `.m3u8` in a plain
/// `<video>` tag — so for those TVs we serve a page instead of pushing a
/// stream, and point the TV's browser at it.
///
/// ## What keeps this from being an open proxy
///
/// It listens on every interface, because the television has to reach it and
/// we cannot know in advance which interface that is. Everything else here
/// exists to make that safe:
///
/// * every request carries a per-session token, regenerated on each [start],
///   so someone who finds the port still gets 404;
/// * the proxy fetches only origins the current playlist actually names, so
///   it cannot be aimed at 127.0.0.1, at the router's admin page, or at the
///   internet at large;
/// * responses carry a content type we chose, never the upstream's, so
///   nothing can serve HTML through us and have it run on this origin;
/// * no `Access-Control-Allow-Origin`, so even a page holding the token
///   could not read what came back.
///
/// The first two are load-bearing. Without them this is a machine on the
/// network that will fetch anything for anybody.
class CastWebServer {
  CastWebServer({HttpClient? client})
    : _client =
          client ??
          (HttpClient()
            ..connectionTimeout = _connectTimeout
            // Pass compressed bodies through untouched. Decompressing while
            // copying the upstream's content-length made the two disagree,
            // and the renderer's connection died mid-episode.
            ..autoUncompress = false);

  static const _connectTimeout = Duration(seconds: 10);
  static const _upstreamTimeout = Duration(seconds: 20);

  /// A playlist has to be read whole to be rewritten. Anything bigger than
  /// this is not a playlist, and buffering it would cost the whole heap.
  static const _maxPlaylistBytes = 4 * 1024 * 1024;

  /// The headers the app's own player sends. Measured against both catalogs:
  /// Referer is never checked and one source only requires a non-empty
  /// User-Agent — but the renderer sends neither, so the proxy restores what
  /// the CDN saw when the app was the one asking.
  static const _upstreamUa =
      'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36';

  final HttpClient _client;
  HttpServer? _server;

  CastPlaylist? _playlist;

  /// Origins the proxy may fetch, taken from the playlist being served.
  Set<String> _allowedOrigins = const {};

  /// Unguessable per-session path parameter. Not much of a secret — it goes
  /// to a television in cleartext — but it is what makes these endpoints
  /// unreachable by anything that was not handed the page URL.
  String _token = '';

  void Function(CastProgress progress)? onProgress;

  /// Completes the first time a television asks for the player page.
  Completer<void>? _fetched;

  /// Resolves once a television has actually loaded the page.
  ///
  /// Handing a URL to a TV is not the same as the TV opening it. A blocked
  /// inbound port, a firewall prompt nobody answered, an address on the wrong
  /// interface — all three look like a successful cast from this side, and
  /// the viewer gets "casting to Samsung" over a television doing nothing.
  /// This is the only thing that distinguishes them.
  Future<void> get pageFetched => (_fetched ??= Completer<void>()).future;

  String? _baseUrl;

  String? get baseUrl => _baseUrl;

  bool get isRunning => _server != null;

  /// Binds and returns the base URL. [peerHost] is the television this is
  /// being served to, which picks the interface — see [lanAddress].
  Future<String> start({String? peerHost}) async {
    if (_baseUrl != null) return _baseUrl!;
    final ip = await lanAddress(peerHost);
    if (ip == null) {
      throw const CastServerException('no LAN address to serve from');
    }
    _token = _newToken();
    final server = await HttpServer.bind(InternetAddress.anyIPv4, 0);
    _server = server;
    _baseUrl = 'http://$ip:${server.port}';
    server.listen(_handle, onError: (Object e) => logD('cast', 'server: $e'));
    logD('cast', 'serving at $_baseUrl');
    return _baseUrl!;
  }

  Future<void> stop() async {
    await _server?.close(force: true);
    _server = null;
    _baseUrl = null;
    _playlist = null;
    _allowedOrigins = const {};
    _token = '';
    _fetched = null;
  }

  void dispose() {
    unawaited(stop());
    _client.close(force: true);
  }

  /// The page URL for [playlist] — hand this to the TV's browser.
  String serve(CastPlaylist playlist) {
    final base = _baseUrl;
    if (base == null) throw const CastServerException('server not started');
    _playlist = playlist;
    _allowedOrigins = {
      for (final item in playlist.items) Uri.parse(item.url).origin,
    };
    _fetched = Completer<void>();
    return '$base/player?t=$_token';
  }

  /// [url] as the renderer should ask for it: through us.
  ///
  /// The DLNA path needs this as much as the browser one. A television's
  /// renderer fetches the URI itself, with no TLS on many models and no
  /// User-Agent on most — an https CDN link that one catalog only serves to
  /// a non-empty UA comes back to the viewer as UPnP error 716, "Resource
  /// not found", with nothing to say which of the two it was.
  String proxied(String url) {
    final base = _baseUrl;
    if (base == null) throw const CastServerException('server not started');
    return proxyUrlFor(Uri.parse(url), '$base/proxy', extraQuery: 't=$_token');
  }

  static String _newToken() {
    final rand = Random.secure();
    const alphabet = 'abcdefghijklmnopqrstuvwxyz0123456789';
    return List.generate(24, (_) => alphabet[rand.nextInt(36)]).join();
  }

  /// This machine's address on the network the television is on.
  ///
  /// [peerHost] is the television's own address, and it decides this outright
  /// when it can: an address on its subnet is one it can route to, which no
  /// amount of guessing from interface names can establish. A laptop on
  /// wired and wireless at once has two perfectly good addresses and only one
  /// of them reaches the TV.
  ///
  /// Without it — or when nothing matches — fall back to skipping the
  /// interfaces a television is never behind. Handing the TV a VPN or
  /// virtual-machine address shows up as a page that never loads, with
  /// nothing on screen to say why.
  static Future<String?> lanAddress([String? peerHost]) async {
    final interfaces = await NetworkInterface.list(
      type: InternetAddressType.IPv4,
      includeLoopback: false,
      includeLinkLocal: false,
    );
    final peer = _subnet(peerHost);
    String? physical;
    String? any;
    for (final i in interfaces) {
      for (final a in i.addresses) {
        if (a.address.startsWith('169.254')) continue;
        if (peer != null && _subnet(a.address) == peer) return a.address;
        any ??= a.address;
        if (!_isVirtual(i.name)) physical ??= a.address;
      }
    }
    return physical ?? any;
  }

  /// The /24 an address sits in. Crude — the real prefix length is not
  /// something dart:io exposes — but home networks are /24 and this only ever
  /// has to break a tie between interfaces.
  static String? _subnet(String? host) {
    final parts = host?.split('.') ?? const [];
    return parts.length == 4 ? parts.take(3).join('.') : null;
  }

  /// Interfaces with no television on the other end. Substrings rather than
  /// prefixes, and named for Linux and Windows too, because Windows reports
  /// friendly names like "vEthernet (Default Switch)".
  static bool _isVirtual(String name) {
    final n = name.toLowerCase();
    return const [
      'utun',
      'tun',
      'tap',
      'bridge',
      'vmnet',
      'vboxnet',
      'vmware',
      'vethernet',
      'veth',
      'docker',
      'virbr',
      'hyper-v',
      'llw',
      'awdl',
    ].any(n.contains);
  }

  bool _authorised(HttpRequest req) =>
      _token.isNotEmpty && req.uri.queryParameters['t'] == _token;

  Future<void> _handle(HttpRequest req) async {
    try {
      if (!_authorised(req)) {
        // 404 rather than 401: an unauthorised caller learns nothing about
        // what is running here.
        req.response.statusCode = HttpStatus.notFound;
        await req.response.close();
        return;
      }
      switch (req.uri.path) {
        case '/player':
          await _servePlayer(req);
        case '/proxy':
          await _serveProxy(req);
        case '/progress':
          await _serveProgress(req);
        default:
          req.response.statusCode = HttpStatus.notFound;
          await req.response.close();
      }
    } catch (e) {
      logD('cast', 'request ${req.uri.path} failed: $e');
      try {
        req.response.statusCode = HttpStatus.internalServerError;
        await req.response.close();
      } catch (_) {
        // The renderer hung up mid-response; nothing left to say.
      }
    }
  }

  Future<void> _servePlayer(HttpRequest req) async {
    final playlist = _playlist;
    if (playlist == null) {
      req.response.statusCode = HttpStatus.notFound;
      await req.response.close();
      return;
    }
    req.response.headers.contentType = ContentType.html;
    req.response.headers.set('Cache-Control', 'no-store');
    req.response.add(utf8.encode(_playerPage(playlist)));
    await req.response.close();
    if (_fetched?.isCompleted == false) _fetched!.complete();
  }

  /// Fetches [url] for the renderer, wearing the headers the CDN expects.
  Future<void> _serveProxy(HttpRequest req) async {
    final raw = req.uri.queryParameters['url'];
    if (raw == null || raw.isEmpty) {
      req.response.statusCode = HttpStatus.badRequest;
      await req.response.close();
      return;
    }
    final target = Uri.tryParse(raw);
    if (target == null ||
        !(target.isScheme('http') || target.isScheme('https')) ||
        !_allowedOrigins.contains(target.origin)) {
      // The playlist said which origins this cast needs. Anything else is
      // someone using us to reach something we were never asked to reach.
      logD('cast', 'proxy refused ${target?.origin}');
      req.response.statusCode = HttpStatus.forbidden;
      await req.response.close();
      return;
    }

    final res = await _fetch(
      target,
      req.headers.value(HttpHeaders.rangeHeader),
    );
    if (res == null) {
      req.response.statusCode = HttpStatus.badGateway;
      await req.response.close();
      return;
    }
    final upstreamType = res.headers.contentType?.mimeType;

    if (res.statusCode < 400 && looksLikePlaylist(upstreamType, target)) {
      final bytes = await _readCapped(res);
      if (bytes == null) {
        req.response.statusCode = HttpStatus.badGateway;
        await req.response.close();
        return;
      }
      // allowMalformed: one stray byte in a comment must not end the cast,
      // and every line that matters here is ASCII.
      final rewritten = rewriteHlsPlaylist(
        playlist: utf8.decode(bytes, allowMalformed: true),
        playlistUrl: target,
        proxyBase: '$_baseUrl/proxy',
        extraQuery: 't=$_token',
      );
      // 200, not the upstream's status: a rewritten playlist is a different
      // body of a different length, so a passed-through 206 and its
      // Content-Range would describe bytes we are not sending.
      req.response.statusCode = HttpStatus.ok;
      req.response.headers.set(
        HttpHeaders.contentTypeHeader,
        // charset or dart:io encodes the body as latin1, and a Chinese
        // episode name in an #EXTINF line then throws mid-response — the
        // television got a 500 for a playlist that was perfectly valid.
        'application/vnd.apple.mpegurl; charset=utf-8',
      );
      req.response.add(utf8.encode(rewritten));
      await req.response.close();
      return;
    }

    req.response.statusCode = res.statusCode;
    // Never the upstream's own type: a source answering with text/html would
    // otherwise get to run it on this origin.
    req.response.headers.set(
      HttpHeaders.contentTypeHeader,
      _safeContentType(upstreamType, target),
    );
    for (final h in const [
      'content-range',
      'accept-ranges',
      'content-length',
      'content-encoding',
    ]) {
      final v = res.headers.value(h);
      if (v != null) req.response.headers.set(h, v);
    }
    // Idle timeout, not a deadline: an episode legitimately takes minutes to
    // stream, but a CDN that sends headers and then stops sending anything
    // would otherwise leave the renderer waiting on a socket forever.
    try {
      await res.timeout(_upstreamTimeout).pipe(req.response);
    } on TimeoutException {
      logD('cast', 'upstream stalled, hanging up on ${target.host}');
      await req.response.close().catchError((_) {});
    }
  }

  /// Fetches [target], following redirects by hand.
  ///
  /// By hand because the client's own redirect following would defeat both
  /// guards on this proxy: it re-sends the Referer to whatever host it lands
  /// on, and — the one that matters — it would fetch a Location outside the
  /// allowlist, so a redirect is all it would take to point this at
  /// 127.0.0.1. Every hop is checked like the first.
  Future<HttpClientResponse?> _fetch(Uri target, String? range) async {
    var url = target;
    for (var hop = 0; hop < 5; hop++) {
      if (!_allowedOrigins.contains(url.origin)) {
        logD('cast', 'proxy refused redirect to ${url.origin}');
        return null;
      }
      final req = await _client.getUrl(url).timeout(_upstreamTimeout);
      req.followRedirects = false;
      req.headers.set(HttpHeaders.userAgentHeader, _upstreamUa);
      // dart:io asks for gzip whether or not we decompress it, and we do not
      // (autoUncompress is off). A compressed playlist would then reach the
      // rewriter as raw deflate bytes and go to the television as one long
      // line of U+FFFD. Ask for it uncompressed instead.
      req.headers.set(HttpHeaders.acceptEncodingHeader, 'identity');
      // Per hop, so the Referer always names the host being asked rather
      // than trailing the origin we started from.
      req.headers.set(HttpHeaders.refererHeader, '${url.origin}/');
      if (range != null) req.headers.set(HttpHeaders.rangeHeader, range);

      final HttpClientResponse res;
      try {
        res = await req.close().timeout(_upstreamTimeout);
      } on TimeoutException {
        // abort() and not just the timeout: a Future's timeout abandons the
        // wait but cancels nothing, so a server that accepted the socket and
        // went silent kept it — one leaked connection per stalled request.
        req.abort();
        return null;
      }
      final location = res.headers.value(HttpHeaders.locationHeader);
      if (!res.isRedirect || location == null) return res;

      // Stream.timeout, not Future.timeout on drain(): the stream form tears
      // the subscription down when it fires, where the future form walked
      // away and left the proxy swallowing an endless redirect body forever.
      try {
        await res.timeout(_upstreamTimeout).drain<void>();
      } on TimeoutException {
        return null;
      }
      url = url.resolve(location);
    }
    logD('cast', 'proxy gave up after 5 redirects from $target');
    return null;
  }

  /// Reads at most [_maxPlaylistBytes], or null if the body runs past it or
  /// stalls partway through.
  Future<List<int>?> _readCapped(HttpClientResponse res) async {
    final out = <int>[];
    try {
      await for (final chunk in res.timeout(_upstreamTimeout)) {
        out.addAll(chunk);
        if (out.length > _maxPlaylistBytes) return null;
      }
    } on TimeoutException {
      return null;
    }
    return out;
  }

  /// A media type we are willing to put our name to.
  static String _safeContentType(String? upstream, Uri url) {
    const allowed = {
      'video/mp2t',
      'video/mp4',
      'video/x-matroska',
      'audio/mpeg',
      'audio/aac',
      'application/octet-stream',
    };
    if (upstream != null && allowed.contains(upstream)) return upstream;
    final path = url.path.toLowerCase();
    if (path.endsWith('.ts')) return 'video/mp2t';
    if (path.endsWith('.mp4') || path.endsWith('.m4s')) return 'video/mp4';
    if (path.endsWith('.aac')) return 'audio/aac';
    return 'application/octet-stream';
  }

  Future<void> _serveProgress(HttpRequest req) async {
    // Bounded in bytes, and bounded by breaking out rather than by take():
    // take(4096) counts socket reads, not bytes, so it let ~256MB through,
    // and a timeout on the joined future leaves the subscription eating the
    // rest of the body in the background. This endpoint takes three numbers.
    final buf = <int>[];
    try {
      await for (final chunk in req.timeout(const Duration(seconds: 5))) {
        buf.addAll(chunk);
        if (buf.length > 4096) break;
      }
    } catch (_) {
      // A half-sent report is not worth a log line.
    }
    final body = buf.length > 4096
        ? ''
        : utf8.decode(buf, allowMalformed: true);
    req.response.statusCode = HttpStatus.noContent;
    await req.response.close();
    try {
      final json = jsonDecode(body) as Map<String, dynamic>;
      final index = (json['index'] as num).toInt();
      final position = (json['position'] as num).toInt();
      final duration = (json['duration'] as num).toInt();
      final items = _playlist?.items.length ?? 0;
      if (index < 0 || index >= items || position < 0 || duration <= 0) return;
      onProgress?.call(
        CastProgress(
          playlistIndex: index,
          position: Duration(milliseconds: position),
          duration: Duration(milliseconds: duration),
        ),
      );
    } catch (e) {
      logD('cast', 'bad progress report: $e');
    }
  }

  /// The page the TV browser runs.
  ///
  /// Deliberately plain: a `<video>` tag pointed at the proxied playlist,
  /// because the Tizen browser plays HLS natively and shipping a JS player
  /// would mean shipping a JS player to a device we cannot debug.
  ///
  /// Titles come from the catalogs, so as far as this page is concerned they
  /// are attacker-controlled: they go in through `textContent`, never
  /// `innerHTML`, and the JSON carrying them has its `<` escaped so a title
  /// containing `</script>` cannot close the block it sits in.
  String _playerPage(CastPlaylist playlist) {
    final items = jsonForScript([
      for (final e in playlist.items)
        {
          'title': e.title,
          'url': proxyUrlFor(
            Uri.parse(e.url),
            '/proxy',
            extraQuery: 't=$_token',
          ),
        },
    ]);
    return '''
<!DOCTYPE html>
<html><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Vidra</title>
<style>
*{margin:0;padding:0;box-sizing:border-box}
body{background:#000;color:#eee;font-family:system-ui,sans-serif}
video{width:100vw;height:100vh;background:#000;display:block}
#bar{position:fixed;left:0;right:0;bottom:0;padding:14px 20px;
  background:linear-gradient(transparent,rgba(0,0,0,.85));font-size:20px;
  transition:opacity .4s}
#bar.hidden{opacity:0;pointer-events:none}
#eps{display:flex;gap:8px;overflow-x:auto;margin-top:10px}
.ep{padding:6px 14px;border:1px solid #555;border-radius:999px;
  white-space:nowrap;font-size:16px;cursor:pointer}
.ep.on{background:#7BE7F0;color:#05323A;border-color:#7BE7F0}
</style></head><body>
<video id="v" autoplay controls></video>
<div id="bar"><div id="t"></div><div id="eps"></div></div>
<script>
var items = $items;
var i = ${playlist.startIndex};
var v = document.getElementById('v');
var eps = document.getElementById('eps');
function render() {
  document.getElementById('t').textContent = items[i].title;
  eps.textContent = '';
  items.forEach(function (e, n) {
    var el = document.createElement('span');
    el.className = 'ep' + (n === i ? ' on' : '');
    el.textContent = e.title;
    el.onclick = function () { report(); load(n); };
    eps.appendChild(el);
  });
}
// Fullscreen, in three tries because no single one is reliable on a TV.
//
// A browser only grants fullscreen from a user gesture, and there is no
// gesture here — the app launched this page remotely. So: ask outright
// (some TV browsers allow it), ask again on the first button press from the
// remote (which IS a gesture), and either way fade the info bar out so the
// picture is unobstructed even when the request is refused.
function isFull() {
  return !!(document.fullscreenElement || document.webkitFullscreenElement ||
            document.webkitIsFullScreen);
}
function goFullscreen() {
  if (isFull()) return;
  // The video element first: a media element is the one thing some browsers
  // will take fullscreen without a gesture. Then the document. Then the
  // vendor-prefixed video call that older WebKit TVs still use.
  var targets = [v, document.documentElement];
  for (var t = 0; t < targets.length; t++) {
    var el = targets[t];
    var req = el.requestFullscreen || el.webkitRequestFullscreen ||
              el.webkitRequestFullScreen || el.mozRequestFullScreen ||
              el.msRequestFullscreen;
    if (!req) continue;
    try {
      var r = req.call(el);
      if (r && r.catch) r.catch(function () {});
      return;
    } catch (e) {}
  }
  try {
    if (v.webkitEnterFullscreen) v.webkitEnterFullscreen();
  } catch (e) {}
}
['click', 'keydown', 'touchstart'].forEach(function (ev) {
  document.addEventListener(ev, function () { goFullscreen(); showBar(); });
});

var barTimer = null;
function showBar() {
  var bar = document.getElementById('bar');
  bar.classList.remove('hidden');
  clearTimeout(barTimer);
  barTimer = setTimeout(function () { bar.classList.add('hidden'); }, 4000);
}

function load(n, seekTo) {
  i = n; render();
  v.src = items[i].url;
  v.load();
  if (seekTo) {
    v.addEventListener('loadedmetadata', function once() {
      v.removeEventListener('loadedmetadata', once);
      try { v.currentTime = seekTo; } catch (e) {}
    });
  }
  v.play();
}
// The app is what remembers where you were, so report rather than store: a
// TV browser's localStorage is not somewhere watch progress should live.
function report() {
  if (!v.duration) return;
  try {
    fetch('/progress?t=$_token', {method: 'POST', body: JSON.stringify({
      index: i,
      position: Math.floor(v.currentTime * 1000),
      duration: Math.floor(v.duration * 1000)
    })});
  } catch (e) {}
}
// Only while something is actually playing: an idle page left on the TV
// used to write to the database every five seconds all night.
setInterval(function () { if (!v.paused) report(); }, 5000);
v.addEventListener('pause', report);
v.addEventListener('ended', function () {
  if (i < items.length - 1) load(i + 1);
});
// Once pictures are actually moving: try for fullscreen, and get the
// caption out of the way.
v.addEventListener('playing', function () {
  goFullscreen();
  showBar();
  // The app sends a remote key a moment after launching this page; that is
  // a genuine input event, so the keydown handler above can ask for
  // fullscreen where this unprompted attempt was refused. Retry a few times
  // in case the key lands before playback starts.
  var tries = 0;
  var retry = setInterval(function () {
    if (isFull() || ++tries > 6) { clearInterval(retry); return; }
    goFullscreen();
  }, 1000);
});
load(i, ${playlist.startPositionSeconds});
showBar();
</script></body></html>
''';
  }

  /// JSON safe to embed in a `<script>` block.
  ///
  /// `jsonEncode` leaves `<` alone, so a title containing `</script>` would
  /// end the block and turn everything after it into markup.
  ///
  /// The replacement must be a raw string. Written as an ordinary literal,
  /// Dart resolves the escape at compile time and this becomes a no-op that
  /// replaces `<` with itself — which is exactly how it shipped the first
  /// time, comment and all.
  static String jsonForScript(Object value) =>
      jsonEncode(value).replaceAll('<', r'\u003c');
}

class CastServerException implements Exception {
  const CastServerException(this.message);
  final String message;
  @override
  String toString() => 'CastServerException: $message';
}
