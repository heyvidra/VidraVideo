import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

import '../../../../core/utils/log.dart';
import 'yfsp_challenge.dart';

/// Signs yfsp API calls.
///
/// Every endpoint rejects an unsigned request with `{"code":1,"msg":"用户签名
/// 错误"}`. The site's own bundle (`main.*.js`, `uriSignature`) computes:
///
/// ```
/// vv  = md5("<publicKey>&<query>&<privateKey>")
/// pub = <publicKey>
/// ```
///
/// where `<query>` is the request's query string with its values URL-DECODED
/// and the whole string lowercased — keys included, which is why the signed
/// copy is built separately from the one that goes on the wire (`isIndex`
/// travels cased and hashes lowercase).
///
/// The key pair is not a constant. It is embedded in every HTML page as
/// `pConfig` and rotates, which is why a captured URL replays for a while and
/// then starts answering 用户签名错误 forever. So the pair is scraped from a
/// page, cached, and re-scraped when the API says the signature is stale —
/// there is no expiry to schedule against, only the server's verdict.
class YfspSigner {
  YfspSigner();

  /// Any page carries `pConfig`; the drama list is the smallest reliable one.
  static const String _keyPageUrl = 'https://www.yfsp.tv/list/drama';

  static const String userAgent =
      'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36';

  /// The API 403s a request with no `Referer` from the site.
  static const String referer = 'https://www.yfsp.tv/';

  /// STATIC, so the pair outlives the source instance holding it.
  ///
  /// `allDataSourcesProvider` builds a fresh [YfspDataSource] — and with it a
  /// fresh signer — on every rebuild, so an instance field meant re-scraping
  /// a 26 KB page each time. That page sits in front of the FIRST signed call
  /// of a session, so it was pre-roll the viewer waited through, and it was
  /// spent on the one host here that rate-limits into a bot challenge.
  static ({String pub, String priv})? _keys;

  /// De-duplicates concurrent scrapes. A cold start fires the category list
  /// and the first catalog page at once; without this they would each fetch
  /// and parse the same 26 KB page.
  static Future<({String pub, String priv})>? _pending;

  /// Where the pair survives a process boundary.
  ///
  /// Static is not enough on its own: the player runs in its OWN engine, hence
  /// its own isolate and its own statics, so opening a video scraped the page
  /// a second time — and that one lands squarely on the play path. A file is
  /// the cheapest thing both engines can read. Nothing secret is in it: this
  /// is public page markup, and a stale pair costs one retry, which
  /// [invalidate] already handles.
  static File get _cacheFile =>
      File('${Directory.systemTemp.path}/vidra_yfsp/keys.json');

  /// Throws away the cached pair, memory and disk, so the next [sign] scrapes
  /// a fresh one. Called when the API says a signature is stale — which is the
  /// only expiry signal there is, since the pair carries no lifetime.
  void invalidate() {
    _keys = null;
    try {
      if (_cacheFile.existsSync()) _cacheFile.deleteSync();
    } on FileSystemException {
      // A cache that will not delete is one the next write replaces anyway.
    }
  }

  /// The pair, from memory, then disk, then the site.
  ///
  /// The disk read is what keeps the scrape off the play path: the player's
  /// engine starts cold every time a video opens, and a pair another engine
  /// already fetched is as good as one of its own.
  Future<({String pub, String priv})> _resolveKeys() async {
    final cached = _keys ??= _readCache();
    if (cached != null) return cached;
    // `_pending` MUST be cleared even when the scrape throws — otherwise a
    // first attempt that hit the Cloudflare wall leaves this static pointing
    // at a permanently-failed future, and every later attempt (including the
    // one right after the human passes the challenge) re-awaits that same
    // failure instead of scraping again. The `finally` is the whole fix.
    try {
      final keys = await (_pending ??= _fetchKeys());
      _keys = keys;
      _writeCache(keys);
      return keys;
    } finally {
      _pending = null;
    }
  }

  ({String pub, String priv})? _readCache() {
    try {
      final file = _cacheFile;
      if (!file.existsSync()) return null;
      final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      final pub = json['pub'] as String?;
      final priv = json['priv'] as String?;
      if (pub == null || priv == null || pub.isEmpty || priv.isEmpty) {
        return null;
      }
      return (pub: pub, priv: priv);
    } on Object {
      // Unreadable, truncated, or written by an older shape: scraping again is
      // always correct, so a bad cache must never be an error.
      return null;
    }
  }

  void _writeCache(({String pub, String priv}) keys) {
    try {
      final file = _cacheFile;
      file.parent.createSync(recursive: true);
      file.writeAsStringSync(jsonEncode({'pub': keys.pub, 'priv': keys.priv}));
    } on Object {
      // A cache that will not write costs a scrape, not a failure.
    }
  }

  /// `base` plus [params], signed. Values are passed RAW — this encodes them.
  Future<String> sign(String base, Map<String, String> params) async {
    final keys = await _resolveKeys();
    return signWith(base, params, pub: keys.pub, priv: keys.priv);
  }

  /// Signs an ALREADY-BUILT url, query and all.
  ///
  /// [sign] is for calls this code composes; this is for urls the API handed
  /// back — every segment in a playlist, above all. A url that already carries
  /// a signature is returned untouched, matching the site's own guard.
  Future<String> signExisting(String url) async {
    if (_alreadySigned(url)) return url;
    final keys = await _resolveKeys();
    return _signExisting(url, keys);
  }

  /// [signExisting] without the await, for a caller holding hundreds of urls.
  ///
  /// Rewriting a playlist means signing every segment in it, and awaiting per
  /// line would serialise a few hundred futures for no gain — the key pair is
  /// already in hand by then, because the playlist itself was fetched signed.
  /// Returns the url untouched if it somehow is not, which fails loudly at the
  /// CDN rather than quietly producing a playlist of half-signed segments.
  String signExistingSync(String url) {
    final keys = _keys;
    if (keys == null || _alreadySigned(url)) return url;
    return _signExisting(url, keys);
  }

  /// The site's own guard: a url that carries a signature is left alone.
  bool _alreadySigned(String url) =>
      url.contains('vv=') && url.contains('pub=');

  String _signExisting(String url, ({String pub, String priv}) keys) {
    final uri = Uri.parse(url);
    final base = uri.replace(query: '').toString().replaceAll(RegExp(r'\?$'), '');
    // Decoded pairs in the order they appear: [signWith] re-encodes them for
    // the wire and hashes the decoded form, which is what the site does.
    final params = <String, String>{};
    for (final pair in uri.query.split('&')) {
      if (pair.isEmpty) continue;
      final i = pair.indexOf('=');
      final k = i < 0 ? pair : pair.substring(0, i);
      final v = i < 0 ? '' : pair.substring(i + 1);
      params[Uri.decodeComponent(k)] = Uri.decodeComponent(v);
    }
    return signWith(base, params, pub: keys.pub, priv: keys.priv);
  }

  /// The signature itself, with the key pair supplied rather than scraped.
  ///
  /// Split out from [sign] so the algorithm can be checked against a captured
  /// key pair without a network round trip — see `test/yfsp_signer_test.dart`.
  static String signWith(
    String base,
    Map<String, String> params, {
    required String pub,
    required String priv,
  }) {
    // Two renderings of the same map, in the same order: one decoded and
    // lowercased for the hash, one encoded for the wire. Dart preserves map
    // insertion order, which is what keeps the two in step. Lowercasing is
    // NOT applied to what goes out — `isIndex` travels cased and hashes
    // lowercase, and sending it folded gets the request refused.
    final signed = params.entries
        .map((e) => '${e.key}=${e.value}')
        .join('&')
        .toLowerCase();
    final wire = params.entries
        .map((e) => '${e.key}=${Uri.encodeQueryComponent(e.value)}')
        .join('&');

    final vv = md5.convert(utf8.encode('$pub&$signed&$priv')).toString();
    return '$base?$wire&vv=$vv&pub=$pub';
  }

  /// Reads the key pair from the browser's NAVIGATION-loaded key page (see
  /// [YfspBrowser.readKeys]). Null keys mean the page carried no pConfig, which
  /// in practice is the Cloudflare wall — surfaced as [ChallengeRequiredException]
  /// so the caller shows the "human check" button instead of a dead end.
  Future<({String pub, String priv})> _fetchKeys() async {
    final keys = await YfspBrowser.readKeys();
    if (keys == null) throw ChallengeRequiredException();
    logD('Yfsp', 'Signing keys refreshed');
    return keys;
  }

  /// Pulls the key pair out of a page's inline `pConfig`.
  ///
  /// Separate from the fetch so the decoy below can be regression-tested
  /// without a network round trip.
  static ({String pub, String priv}) parseKeys(String html) {
    // Anchored on the pConfig object, and it has to be: the page carries a
    // SECOND "publicKey" — Cloudflare Turnstile's site key ("0x4AAAA…"), part
    // of the bot challenge the API's own rate limiter escalates to. Matching
    // the field names loose pairs that key with pConfig's privateKey, and a
    // mismatched pair signs perfectly well and is refused by every endpoint.
    final config = RegExp(
      r'"pConfig"\s*:\s*\{([^{}]*)\}',
    ).firstMatch(html)?[1];
    final pub = config == null
        ? null
        : RegExp(r'"publicKey"\s*:\s*"([^"]+)"').firstMatch(config)?[1];
    final priv = config == null
        ? null
        : RegExp(r'"privateKey"\s*:\s*\[\s*"([^"]+)"').firstMatch(config)?[1];

    if (pub == null || priv == null) {
      throw StateError(
        'yfsp: no signing keys in $_keyPageUrl '
        '(pConfig=${config != null}, publicKey=${pub != null}, '
        'privateKey=${priv != null})',
      );
    }
    return (pub: pub, priv: priv);
  }
}
