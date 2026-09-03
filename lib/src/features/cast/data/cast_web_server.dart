import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import '../../../core/network/browser_identity.dart';
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
///   internet at large — see [_mayFetch] and [_adoptOrigin] for the two ways
///   that set grows and what each of them refuses to grow into;
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

  /// How long a renderer may take nothing at all before the transfer is
  /// dropped. Deliberately far longer than [_upstreamTimeout]: a paused
  /// television reads nothing for as long as someone is away from the sofa,
  /// and killing that is the freeze this file exists to stop. It is here only
  /// so a renderer that walked off without closing — a graceful half-close is
  /// invisible from this side — cannot pin an upstream socket forever.
  static const _writeDeadline = Duration(minutes: 5);

  /// Resume attempts per proxied body. A CDN that drops us twice in a row is
  /// not going to serve this segment, and an unbounded retry would hold the
  /// renderer on a connection that is never going to complete.
  static const _maxResumes = 3;

  /// A playlist has to be read whole to be rewritten. Anything bigger than
  /// this is not a playlist, and buffering it would cost the whole heap.
  static const _maxPlaylistBytes = 4 * 1024 * 1024;

  /// The headers the app's own player sends. Measured against both catalogs:
  /// Referer is never checked and one source only requires a non-empty
  /// User-Agent — but the renderer sends neither, so the proxy restores what
  /// the CDN saw when the app was the one asking.
  ///
  /// Comes from [BrowserIdentity] now rather than a constant of its own, so
  /// the proxy and the player present the SAME browser for the same run. They
  /// were two hardcoded Chrome versions before, sixteen majors apart, which
  /// meant a stream fetched directly and the same stream fetched through here
  /// looked like two different clients to one CDN.
  ///
  /// The Referer is deliberately NOT taken from here — [_fetch] sets it per
  /// redirect hop to the host being asked, which is the behaviour that was
  /// measured against real CDNs.
  static String get _upstreamUa => BrowserIdentity.userAgent;

  /// How a DLNA renderer asks to start part-way in, and how it is answered.
  static const _timeSeekHeader = 'TimeSeekRange.dlna.org';
  static const _transferModeHeader = 'transferMode.dlna.org';
  static const _featuresRequestHeader = 'getcontentFeatures.dlna.org';
  static const _featuresHeader = 'contentFeatures.dlna.org';

  /// What the renderer is told it may do with a URL.
  ///
  /// DLNA.ORG_OP is two flags in one number: the first says time-seek, the
  /// second byte-seek. A playlist gets 10 — [_timeSeekHeader] is answered for
  /// real below, and a byte range into a document we rewrite whole would
  /// describe bytes nobody has. A segment gets 01: it is a file, ranges are
  /// exactly what it supports, and it has no timeline of its own to seek in.
  /// The flags say DLNA 1.5, streaming rather than download, not transcoded.
  ///
  /// A renderer told none of this guesses, and what an LG guesses about an
  /// HLS URL declared `video/mp4` is that it can neither seek nor resume.
  static const _playlistFeatures =
      'DLNA.ORG_OP=10;DLNA.ORG_CI=0;'
      'DLNA.ORG_FLAGS=01700000000000000000000000000000';
  static const _segmentFeatures =
      'DLNA.ORG_OP=01;DLNA.ORG_CI=0;'
      'DLNA.ORG_FLAGS=01700000000000000000000000000000';

  final HttpClient _client;
  HttpServer? _server;

  CastPlaylist? _playlist;

  /// Origins the proxy may fetch: the ones the cast named, plus the ones the
  /// playlists it served named in turn.
  final Set<String> _allowedOrigins = <String>{};

  /// Unguessable per-session path parameter. Not much of a secret — it goes
  /// to a television in cleartext — but it is what makes these endpoints
  /// unreachable by anything that was not handed the page URL.
  String _token = '';

  void Function(CastProgress progress)? onProgress;

  /// Turns a non-http playlist entry into something fetchable, at the moment
  /// the renderer asks for it. yfsp stores a `yfsp://<key>` placeholder and
  /// mints the real URL one episode at a time behind a rate limiter, so the
  /// exchange happens here — when the TV fetches — and never for the whole
  /// show up front. May answer with an http(s) URL or a LOCAL playlist path
  /// (yfsp signs every segment and hands back the rewritten file).
  Future<String?> Function(String url)? resolve;

  /// Headers the current source's CDN must be asked with, replacing the
  /// browser identity and per-hop Referer [_fetch] sends by default. yfsp's
  /// CDN answers 520 to a Referer naming itself, which is exactly the default.
  Map<String, String>? upstreamHeaders;

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
    _allowedOrigins.clear();
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
    // Only http(s) entries name an origin; a placeholder (`yfsp://…`) has none
    // yet, and `.origin` throws on it — which was the whole cast failing.
    // Its origin is adopted when [resolve] answers.
    _allowedOrigins
      ..clear()
      ..addAll({
        for (final item in playlist.items)
          if (_isHttp(Uri.tryParse(item.url))) Uri.parse(item.url).origin,
      });
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
  ///
  /// [startSeconds] makes the proxy serve an episode that BEGINS there.
  ///
  /// This is the only resume that works on the televisions this app has met.
  /// An LG's remote has no seek at all — its fast-forward is 2x/4x playback —
  /// so it never sends `TimeSeekRange.dlna.org`, and waiting to be asked
  /// meant every cast restarted the episode. Cutting the playlist asks the
  /// renderer for nothing.
  ///
  /// The cost is that the renderer then counts from the cut, so its reported
  /// position is short by exactly this many seconds. Whoever passes a
  /// [startSeconds] owns adding it back before that position becomes watch
  /// history — see [CastPlaylist.startPositionSeconds]'s use in the cast
  /// controller. Without that correction a resume at 12:00 writes the
  /// viewer's progress twelve minutes backwards on every cast, which is a
  /// worse bug than the episode restarting.
  String proxied(String url, {int startSeconds = 0}) {
    final base = _baseUrl;
    if (base == null) throw const CastServerException('server not started');
    return proxyUrlFor(
      Uri.parse(url),
      '$base/proxy',
      extraQuery: startSeconds > 0
          ? 't=$_token&start=$startSeconds'
          : 't=$_token',
    );
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
    final head = req.method == 'HEAD';
    // On every answer, refusals included. A renderer reads this before it
    // reads a body, and one that is told nothing treats the URL as a file to
    // download rather than as a stream to play.
    _dlnaHeader(req.response, _transferModeHeader, 'Streaming');

    final raw = req.uri.queryParameters['url'];
    if (raw == null || raw.isEmpty) {
      req.response.statusCode = HttpStatus.badRequest;
      await req.response.close();
      return;
    }
    final parsed = Uri.tryParse(raw);
    if (parsed == null) {
      req.response.statusCode = HttpStatus.badRequest;
      await req.response.close();
      return;
    }
    var target = parsed;
    // A playlist path on this machine rather than a URL: what [resolve]
    // answers when the source had to rewrite the playlist before anything
    // could play it.
    String? localPlaylist;
    if (!_isHttp(target) && resolve != null) {
      final resolved = await resolve!(raw);
      final fetchable = resolved == null ? null : Uri.tryParse(resolved);
      if (resolved == null || fetchable == null) {
        req.response.statusCode = HttpStatus.badGateway;
        await req.response.close();
        return;
      }
      if (_isHttp(fetchable)) {
        _adoptOrigin(fetchable);
        target = fetchable;
      } else {
        localPlaylist = resolved;
      }
    }
    if (localPlaylist == null && !_mayFetch(target)) {
      // The playlist said which origins this cast needs. Anything else is
      // someone using us to reach something we were never asked to reach.
      // Scheme and host only: a signed CDN URL's query is a credential, and
      // .origin throws on the schemes worth refusing loudest.
      logD('cast', 'proxy refused ${target.scheme}://${target.host}');
      req.response.statusCode = HttpStatus.forbidden;
      await req.response.close();
      return;
    }

    // A playlist is rewritten whole, so a Range on it can only produce a
    // fragment presented as a complete document: the branch below forces 200,
    // and a renderer that probes with `Range: bytes=0-20` — which one
    // expecting MP4 does, looking for a moov atom — got `#EXTM3U\n#EXT-X-TARG`
    // under a 200 OK. With no #EXT-X-ENDLIST in what survived the cut, the
    // player treats it as a live playlist, reaches the last surviving segment
    // and waits for a continuation that never comes. Decide by extension
    // BEFORE fetching, because the content type only arrives with the body.
    final wantsPlaylist =
        localPlaylist != null || looksLikePlaylist(null, target);
    if (req.headers.value(_featuresRequestHeader)?.trim() == '1') {
      _dlnaHeader(
        req.response,
        _featuresHeader,
        wantsPlaylist ? _playlistFeatures : _segmentFeatures,
      );
    }

    // Where the episode should start. The renderer asks with a header; a URL
    // that was built with `start=` asks on its behalf, which is how a master
    // playlist passes an offset down to the variant that can actually honour
    // it. Both are absolute positions in the episode, never relative to what
    // is being served, so asking twice cannot land twice as far in.
    final asked =
        _nptSeconds(req.headers.value(_timeSeekHeader)) ??
        _positiveSeconds(req.uri.queryParameters['start']);

    if (localPlaylist != null) {
      await _servePlaylist(
        req,
        await File(localPlaylist).readAsBytes(),
        Uri.file(localPlaylist),
        asked: asked,
        head: head,
      );
      return;
    }

    if (head && !wantsPlaylist) {
      await _headSegment(req, target);
      return;
    }

    final res = await _fetch(
      target,
      wantsPlaylist ? null : req.headers.value(HttpHeaders.rangeHeader),
    );
    if (res == null) {
      req.response.statusCode = HttpStatus.badGateway;
      await req.response.close();
      return;
    }
    final upstreamType = res.headers.contentType?.mimeType;

    // 200 only: a 206 here would mean the CDN ranged us anyway, and half a
    // playlist must never be dressed up as a whole one.
    if (res.statusCode == HttpStatus.ok &&
        looksLikePlaylist(upstreamType, target)) {
      final bytes = await _readCapped(res);
      if (bytes == null) {
        req.response.statusCode = HttpStatus.badGateway;
        await req.response.close();
        return;
      }
      await _servePlaylist(req, bytes, target, asked: asked, head: head);
      return;
    }
    if (head) {
      // Not a playlist after all, whatever the extension promised — so
      // describe what did arrive, and drop the body on the floor.
      await _answerHead(req, target, res);
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
    await _streamBody(req, target, res);
  }

  /// Rewrites playlist [bytes] so every URI in it comes back through this
  /// proxy, cut to start at [asked] seconds, and sends it.
  Future<void> _servePlaylist(
    HttpRequest req,
    List<int> bytes,
    Uri playlistUrl, {
    double? asked,
    required bool head,
  }) async {
    // allowMalformed: one stray byte in a comment must not end the cast,
    // and every line that matters here is ASCII.
    final slice = sliceMediaPlaylist(
      playlist: utf8.decode(bytes, allowMalformed: true),
      offsetSeconds: asked ?? 0,
    );
    final rewritten = rewriteHlsPlaylist(
      playlist: slice.playlist,
      playlistUrl: playlistUrl,
      proxyBase: '$_baseUrl/proxy',
      // A master has no segments to cut, so the offset rides down to the
      // variant on the URL. A media playlist has already been cut, and
      // handing the same offset to its segments would mean nothing.
      extraQuery: !slice.isMedia && asked != null
          ? 't=$_token&start=${_npt(asked)}'
          : 't=$_token',
      onUri: _adoptOrigin,
    );
    if (asked != null) {
      // The echo IS the seek contract: a renderer that asked and got no
      // TimeSeekRange back concludes the stream cannot be seeked at all,
      // and one that got a window it did not ask for still learns where in
      // the episode the body it is about to play begins. A master knows no
      // durations, so it can only name the point; the variant answers with
      // the real window a moment later.
      _dlnaHeader(
        req.response,
        _timeSeekHeader,
        slice.isMedia
            ? 'npt=${_npt(slice.startSeconds)}-${_npt(slice.totalSeconds)}'
                  '/${_npt(slice.totalSeconds)}'
            : 'npt=${_npt(asked)}-/*',
      );
    }
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
    final body = utf8.encode(rewritten);
    // A HEAD gets the length of the body a GET would produce — the
    // rewritten one, counted, never guessed from the upstream's own length,
    // which describes a document with different URLs in it.
    req.response.headers.set(HttpHeaders.contentLengthHeader, '${body.length}');
    if (!head) req.response.add(body);
    await req.response.close();
  }

  static bool _isHttp(Uri? url) =>
      url != null && (url.isScheme('http') || url.isScheme('https'));

  /// Answers a HEAD for a media segment: what it is, how long it is, and what
  /// may be done with it — no body at all.
  ///
  /// A renderer HEADs a URL to learn what it is before committing to play it,
  /// and an answer invented from the file extension would be a confident lie
  /// about a resource that may not even be there. So ask the CDN, for one
  /// byte: the Content-Range on the 206 that comes back states the full
  /// length, and downloading a segment in order to describe it would be
  /// absurd on a connection the television is about to need.
  Future<void> _headSegment(HttpRequest req, Uri target) async {
    final res = await _fetch(target, 'bytes=0-0');
    if (res == null) {
      req.response.statusCode = HttpStatus.badGateway;
      await req.response.close();
      return;
    }
    await _answerHead(req, target, res);
  }

  /// Describes [res] to the renderer without forwarding a byte of it.
  Future<void> _answerHead(
    HttpRequest req,
    Uri target,
    HttpClientResponse res,
  ) async {
    final total =
        _rangeTotal(res.headers.value(HttpHeaders.contentRangeHeader)) ??
        (res.statusCode == HttpStatus.ok && res.contentLength >= 0
            ? res.contentLength
            : null);
    final type = _safeContentType(res.headers.contentType?.mimeType, target);
    // Nothing here will read this body, and a body nobody reads holds an
    // upstream socket until the CDN gives up on it.
    await res.detachSocket().then((s) => s.destroy()).catchError((_) {});

    // 200: the 206 answers a range we invented, not one the renderer asked
    // for, and a renderer told 206 for a HEAD it sent bare has to guess what
    // the partial was of.
    req.response.statusCode = res.statusCode == HttpStatus.partialContent
        ? HttpStatus.ok
        : res.statusCode;
    req.response.headers.set(HttpHeaders.contentTypeHeader, type);
    req.response.headers.set(HttpHeaders.acceptRangesHeader, 'bytes');
    if (total != null) {
      req.response.headers.set(HttpHeaders.contentLengthHeader, '$total');
    }
    await req.response.close();
  }

  /// The full resource length out of `Content-Range: bytes 0-0/12345`.
  static int? _rangeTotal(String? contentRange) {
    final m = RegExp(r'/\s*(\d+)\s*$').firstMatch(contentRange ?? '');
    return m == null ? null : int.tryParse(m.group(1)!);
  }

  /// DLNA header names are compared by renderers with a case-sensitive string
  /// match more often than they should be, and dart:io lower-cases every name
  /// it writes unless told not to. `transfermode.dlna.org` is a header those
  /// renderers do not see.
  static void _dlnaHeader(HttpResponse res, String name, String value) =>
      res.headers.set(name, value, preserveHeaderCase: true);

  /// The second [header] asks playback to start at, or null when it asks for
  /// nothing we can read.
  ///
  /// Both spellings are in the wild — `npt=12.5-` and `npt=00:00:12.500-` —
  /// and a renderer sends whichever it feels like. The end of the range is
  /// ignored: we serve to the end of the episode regardless, because a
  /// renderer that wanted less than that simply stops reading.
  static double? _nptSeconds(String? header) {
    final m = RegExp(
      r'npt\s*=\s*([\d:.]+)',
      caseSensitive: false,
    ).firstMatch(header ?? '');
    if (m == null) return null;
    var seconds = 0.0;
    for (final part in m.group(1)!.split(':')) {
      final value = double.tryParse(part);
      if (value == null || value < 0) return null;
      seconds = seconds * 60 + value;
    }
    return seconds;
  }

  /// Seconds from a `start=` query parameter, ignoring the zero and the
  /// nonsense — a resume at position zero is just playback.
  static double? _positiveSeconds(String? value) {
    final seconds = double.tryParse(value ?? '');
    return seconds != null && seconds > 0 ? seconds : null;
  }

  static String _npt(double seconds) => seconds.toStringAsFixed(3);

  /// Whether the proxy may fetch [url].
  ///
  /// Exact origin first: what the cast named, plus what the playlists it has
  /// served named in turn. Then one deliberate widening — a host under the
  /// same domain as an origin already on the list. CDNs hand out
  /// `edge12.<domain>` in a redirect mid-episode, and refusing that is a
  /// television that stops dead halfway through.
  ///
  /// Without a public-suffix list — a dependency this app is not taking for
  /// one redirect — the domain is read as an allowed host minus its first
  /// label, so `vod.example.com` vouches for `example.com` and everything
  /// under it, and never for anything above. Two rules keep that from
  /// swallowing a whole suffix: the domain needs at least two labels, and
  /// under a two-letter country code at least three, or `player.example.co.uk`
  /// would vouch for every `co.uk` there is. An address literal widens
  /// nothing at all — `127.0.0.1` has no domain above it, and another port on
  /// a machine we are talking to is another service, not another edge — so
  /// the guarantee this file opens with survives: this proxy still cannot be
  /// pointed at localhost or at the router.
  bool _mayFetch(Uri url) {
    if (!(url.isScheme('http') || url.isScheme('https'))) return false;
    if (_allowedOrigins.contains(url.origin)) return true;
    return _allowedOrigins.any((o) => sameSite(Uri.parse(o).host, url.host));
  }

  /// Whether [host] is close enough to [allowed] to be the same CDN. Public
  /// because the rule is the security boundary, and a boundary is worth
  /// asserting on directly rather than through a socket.
  static bool sameSite(String allowed, String host) {
    if (InternetAddress.tryParse(allowed) != null ||
        InternetAddress.tryParse(host) != null) {
      return false;
    }
    final labels = allowed.split('.');
    if (labels.length < 3) return false;
    final domain = labels.skip(1).join('.');
    final parts = domain.split('.');
    if (parts.length < 2) return false;
    if (parts.last.length <= 2 && parts.length < 3) return false;
    return host == domain || host.endsWith('.$domain');
  }

  /// Takes an origin a playlist we just served named, so the variants and
  /// segments in it can be fetched when the renderer comes back for them.
  ///
  /// The list has to grow here: a master playlist whose variants live on a
  /// second host — which is how every multi-CDN catalog is built — otherwise
  /// hands the television URLs this proxy then refuses with a 403. What it
  /// must not grow into is a way to reach this machine. A playlist naming a
  /// loopback, link-local or private address is refused unless the cast was
  /// already talking to that address, which on a real network never happens
  /// and in the tests is the entire fixture.
  void _adoptOrigin(Uri target) {
    if (!(target.isScheme('http') || target.isScheme('https'))) return;
    final origin = target.origin;
    if (_allowedOrigins.contains(origin)) return;
    if (_isLocalHost(target.host) &&
        !_allowedOrigins.any((o) => Uri.parse(o).host == target.host)) {
      logD('cast', 'playlist named a local origin, refused: $origin');
      return;
    }
    _allowedOrigins.add(origin);
  }

  /// Addresses that are this machine or this network rather than a CDN.
  static bool _isLocalHost(String host) {
    if (host == 'localhost' || host.endsWith('.local')) return true;
    final ip = InternetAddress.tryParse(host);
    if (ip == null) return false;
    if (ip.isLoopback || ip.isLinkLocal) return true;
    final b = ip.rawAddress;
    if (ip.type == InternetAddressType.IPv4) {
      return b[0] == 10 ||
          (b[0] == 172 && b[1] >= 16 && b[1] < 32) ||
          (b[0] == 192 && b[1] == 168);
    }
    return (b[0] & 0xfe) == 0xfc;
  }

  /// Copies the upstream body to the renderer, re-fetching where it left off
  /// if the CDN lets go early.
  ///
  /// Not `pipe`. A television fills its decode buffer and STOPS READING for a
  /// while — routine, several times a minute — and that back-pressure travels
  /// all the way through to the upstream socket, where we then advertise a
  /// zero window for as long as the TV stays quiet. Two things follow, both
  /// measured against a real socket rather than reasoned about:
  ///
  /// * `Stream.timeout` cancels its timer while its subscription is paused, so
  ///   the old idle timeout was disarmed at precisely the moment a transfer
  ///   was stuck — it could never fire on a wedge, only on a CDN that went
  ///   quiet while we were still reading;
  /// * the CDN's own write timeout (nginx `send_timeout`, 60s by default) is
  ///   measured between successive writes, so a blocked write is exactly what
  ///   trips it. It closes, we forward the truncated body under the
  ///   Content-Length we already promised, and the renderer treats the close
  ///   as end-of-stream: picture frozen on the last frame, transport still
  ///   reporting PLAYING, no error anywhere.
  ///
  /// So: count what has actually been written, await each flush — which is
  /// also how we learn the TV started reading again — and when the upstream
  /// dies owing us bytes, ask for the rest with a Range and keep writing into
  /// the same response. The renderer never learns any of it happened.
  Future<void> _streamBody(
    HttpRequest req,
    Uri target,
    HttpClientResponse first,
  ) async {
    // Every byte the renderer has actually taken. The resume offset is
    // relative to the body we are serving, so a ranged request that started
    // at 500 resumes at 500 + written — see [_resumeRange].
    var written = 0;
    final total = first.contentLength;
    final startedAt = _rangeStart(req.headers.value(HttpHeaders.rangeHeader));

    var res = first;
    for (var attempt = 0; ; attempt++) {
      final ended = await _pumpBody(req, res, (n) => written += n);
      if (ended == _BodyEnd.complete) break;
      // Nothing promised, nothing owed: without a Content-Length we cannot
      // tell a short close from a legitimate end of stream, so a close is
      // taken at its word rather than resumed into a duplicate tail.
      if (total < 0 || written >= total) break;
      if (attempt >= _maxResumes) {
        logD('cast', 'gave up resuming ${target.host} at $written/$total');
        break;
      }
      logD('cast', 'resuming ${target.host} at $written/$total');
      final next = await _fetch(target, _resumeRange(startedAt, written));
      // A CDN that will not range us cannot be resumed; leaving the response
      // short is no worse than the truncation we were already sending.
      if (next == null || next.statusCode != HttpStatus.partialContent) {
        await next?.detachSocket().then((s) => s.destroy()).catchError((_) {});
        break;
      }
      res = next;
    }
    await req.response.close().catchError((_) {});
  }

  /// Writes one upstream body out, reporting how it ended.
  ///
  /// The flush after each chunk is load-bearing twice over: it is the
  /// back-pressure (without it the whole segment buffers in this process), and
  /// awaiting it is the only signal that the renderer has resumed reading.
  /// [_writeDeadline] is generous on purpose — a paused television is not a
  /// dead one — and exists only so a renderer that walked away without closing
  /// cannot hold an upstream socket open forever.
  Future<_BodyEnd> _pumpBody(
    HttpRequest req,
    HttpClientResponse res,
    void Function(int) count,
  ) async {
    final chunks = StreamIterator<List<int>>(res);
    try {
      while (true) {
        final bool has;
        try {
          has = await chunks.moveNext().timeout(_upstreamTimeout);
        } on TimeoutException {
          logD('cast', 'upstream went quiet');
          return _BodyEnd.broken;
        } on Object {
          // A reset mid-body: the resume path decides whether anything is owed.
          return _BodyEnd.broken;
        }
        if (!has) return _BodyEnd.complete;

        final chunk = chunks.current;
        req.response.add(chunk);
        count(chunk.length);
        try {
          await req.response.flush().timeout(_writeDeadline);
        } on TimeoutException {
          logD('cast', 'renderer stopped reading, dropping the transfer');
          return _BodyEnd.rendererGone;
        } on Object {
          // The renderer hung up. Nothing to resume into.
          return _BodyEnd.rendererGone;
        }
      }
    } finally {
      await chunks.cancel().catchError((_) {});
    }
  }

  /// The byte offset a client Range asked us to start at, or 0.
  static int _rangeStart(String? range) {
    final m = RegExp(r'bytes=(\d+)-').firstMatch(range ?? '');
    return m == null ? 0 : int.parse(m.group(1)!);
  }

  /// Where to resume in the ORIGINAL resource: what the renderer asked us to
  /// start at, plus what it has already been given.
  static String _resumeRange(int start, int written) =>
      'bytes=${start + written}-';

  /// Fetches [target], following redirects by hand.
  ///
  /// By hand because the client's own redirect following would defeat both
  /// guards on this proxy: it re-sends the Referer to whatever host it lands
  /// on, and — the one that matters — it would fetch a Location outside the
  /// allowlist, so a redirect is all it would take to point this at
  /// 127.0.0.1. Every hop is checked like the first, by [_mayFetch], which is
  /// also what decides that an edge host under the CDN's own domain is the
  /// same CDN and not somewhere new.
  Future<HttpClientResponse?> _fetch(Uri target, String? range) async {
    var url = target;
    for (var hop = 0; hop < 5; hop++) {
      if (!_mayFetch(url)) {
        logD('cast', 'proxy refused redirect to $url');
        return null;
      }
      final req = await _client.getUrl(url).timeout(_upstreamTimeout);
      req.followRedirects = false;
      // dart:io asks for gzip whether or not we decompress it, and we do not
      // (autoUncompress is off). A compressed playlist would then reach the
      // rewriter as raw deflate bytes and go to the television as one long
      // line of U+FFFD. Ask for it uncompressed instead.
      req.headers.set(HttpHeaders.acceptEncodingHeader, 'identity');
      final custom = upstreamHeaders;
      if (custom != null) {
        // The source said exactly what its CDN wants — and, by omission,
        // what it must not get.
        custom.forEach(req.headers.set);
      } else {
        req.headers.set(HttpHeaders.userAgentHeader, _upstreamUa);
        // Per hop, so the Referer always names the host being asked rather
        // than trailing the origin we started from.
        req.headers.set(HttpHeaders.refererHeader, '${url.origin}/');
      }
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

/// How one upstream body ended, which decides whether to resume.
enum _BodyEnd {
  /// The upstream said it was done.
  complete,

  /// The upstream stopped early — the case worth resuming.
  broken,

  /// The renderer stopped taking bytes; there is nothing to resume into.
  rendererGone,
}

class CastServerException implements Exception {
  const CastServerException(this.message);
  final String message;
  @override
  String toString() => 'CastServerException: $message';
}
