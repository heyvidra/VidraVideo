import 'dart:io' show Platform;

import 'package:dio/dio.dart';

import 'browser_identity.dart';

/// Where each API host's requests appear to come from.
///
/// A browser calling `api.olelive.com` is doing it from a page on
/// `www.olevod.com`, so that is the Referer it sends — not the API host, which
/// is a value no browser would ever produce for this request. Hosts absent
/// here fall back to their own origin, which is the honest answer when we do
/// not know of a site that fronts them.
const Map<String, String> _siteOrigins = {
  'api.olelive.com': 'https://www.olevod.com',
  'www.olevod.com': 'https://www.olevod.com',
  'www.dbku.tv': 'https://www.dbku.tv',
};

/// Presents one coherent browser to every host this app talks to.
///
/// Catalogs increasingly refuse anything that does not look like a browser.
/// Rather than add a User-Agent at each of a dozen call sites and drift apart,
/// the whole identity is assembled in one place from [BrowserIdentity] — which
/// is what keeps `Sec-CH-UA` agreeing with the User-Agent it belongs to.
///
/// Every header is set with `putIfAbsent`: a caller that has a reason to send
/// something specific keeps it. That is not a nicety — the HTML catalog wants a
/// document `Accept`, not the XHR one this would otherwise supply.
class BrowserHeaders extends Interceptor {
  const BrowserHeaders();

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    apply(options.headers, options.uri);
    handler.next(options);
  }

  /// Fills [headers] for a request to [url]. Exposed because two callers reach
  /// the network without Dio — the cast proxy speaks raw `HttpClient`, and the
  /// HLS downloader builds its own client — and an identity that only covers
  /// some of a process's traffic is not an identity.
  static void apply(Map<String, dynamic> headers, Uri url) {
    final profile = BrowserIdentity.current;
    final referer = refererFor(url);

    // Client hints have to describe the SAME browser the User-Agent names.
    // Filling each header independently is what makes that impossible: a
    // caller keeping its own User-Agent would inherit hints belonging to a
    // different Chrome, and a major-version disagreement between the two is a
    // stronger bot signal than either header is a mitigation — precisely on
    // the host strict enough to be reading them. So the identity is attached
    // whole or not at all.
    final ours = !_hasUserAgent(headers);

    if (ours) {
      headers['User-Agent'] = profile.userAgent;
      if (profile.isChromium) {
        headers.putIfAbsent('sec-ch-ua', () => profile.secChUa!);
        headers.putIfAbsent('sec-ch-ua-mobile', () => '?0');
        headers.putIfAbsent('sec-ch-ua-platform', () => profile.platform);
      }
    }

    headers.putIfAbsent('Referer', () => referer);
    headers.putIfAbsent('Accept', () => _xhrAccept);
    headers.putIfAbsent('Accept-Language', () => acceptLanguage);

    final site = fetchSite(url, Uri.parse(referer));
    headers.putIfAbsent('Sec-Fetch-Dest', () => 'empty');
    headers.putIfAbsent('Sec-Fetch-Mode', () => 'cors');
    headers.putIfAbsent('Sec-Fetch-Site', () => site);
    // Browsers attach Origin to cross-origin fetches and omit it on same-origin
    // GETs. Sending it always would contradict Sec-Fetch-Site; sending it never
    // would contradict Sec-Fetch-Mode: cors.
    if (site != 'same-origin') {
      headers.putIfAbsent('Origin', () => referer);
    }
  }

  /// Dio's own header map is case-insensitive, but this is also called with a
  /// plain map for the two clients that do not use Dio.
  static bool _hasUserAgent(Map<String, dynamic> headers) =>
      headers.keys.any((k) => k.toLowerCase() == 'user-agent');

  /// What a browser would call this request's referring page.
  static String refererFor(Uri url) {
    final known = _siteOrigins[url.host];
    if (known != null) return '$known/';
    return '${url.scheme}://${url.host}/';
  }

  /// `same-origin` / `same-site` / `cross-site`, as the fetch metadata spec
  /// defines them.
  ///
  /// ponytail: registrable domain is approximated by the last two labels rather
  /// than consulting the public suffix list. It is wrong for hosts under
  /// multi-label suffixes (`example.co.uk` reads as `co.uk`), which would
  /// downgrade a same-site request to cross-site — a difference no origin here
  /// acts on. Pull in a PSL only if one ever does.
  static String fetchSite(Uri url, Uri referer) {
    if (url.host == referer.host && url.scheme == referer.scheme) {
      return 'same-origin';
    }
    return _registrable(url.host) == _registrable(referer.host)
        ? 'same-site'
        : 'cross-site';
  }

  static String _registrable(String host) {
    final labels = host.split('.');
    if (labels.length < 2) return host;
    return labels.sublist(labels.length - 2).join('.');
  }

  /// What a browser on THIS machine would ask for, so the language the app
  /// reports agrees with the one the OS is set to.
  static String get acceptLanguage {
    // Platform.localeName is like `zh_Hans_CN.UTF-8` or `en_GB`.
    final raw = Platform.localeName.split('.').first.replaceAll('_', '-');
    final primary = raw.isEmpty ? 'en-US' : raw;
    final base = primary.split('-').first;
    if (base == 'en') return '$primary,en;q=0.9';
    return '$primary,$base;q=0.9,en-US;q=0.8,en;q=0.7';
  }

  /// What `fetch`/XHR asks for. Callers scraping HTML override this.
  static const _xhrAccept = 'application/json, text/plain, */*';

  /// What a browser asks for when it is loading a page — for the catalog this
  /// app scrapes rather than calls.
  static const documentAccept =
      'text/html,application/xhtml+xml,application/xml;q=0.9,'
      'image/avif,image/webp,image/apng,*/*;q=0.8';
}
