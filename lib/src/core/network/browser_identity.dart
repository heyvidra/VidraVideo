import 'dart:io' show Platform;
import 'dart:math';

/// One browser, whole.
///
/// The User-Agent and the headers that accompany it are ONE choice, not
/// several: `Sec-CH-UA` carries the same major version the User-Agent does, and
/// a mismatch between them is a combination no real browser produces. Firefox
/// and Safari send no `Sec-CH-UA` at all, so those profiles carry none — an
/// empty field would be as wrong as a wrong one.
class BrowserProfile {
  const BrowserProfile({
    required this.userAgent,
    required this.platform,
    this.secChUa,
  });

  final String userAgent;

  /// The value for `Sec-CH-UA-Platform`. Quoted, as the header wants it.
  final String platform;

  /// Chromium only. Null on Firefox and Safari, which do not send it.
  final String? secChUa;

  bool get isChromium => secChUa != null;
}

/// The browser this process claims to be, for as long as it runs.
///
/// Catalogs increasingly refuse anything that does not look like a browser —
/// one of the two this app already talks to serves plain HTML only to a browser
/// User-Agent, and a renderer that sent none got a CDN refusal. Rather than
/// wait for the next one to start checking, every request now presents a
/// complete, self-consistent identity.
///
/// Picked ONCE per launch and held: within a session every request must agree,
/// because a client whose browser changes between two requests is stranger than
/// one that never claimed to be a browser. Across launches it is re-rolled
/// rather than persisted — a string frozen at install time only gets more
/// conspicuous as real browsers move on, and there is nothing here worth
/// keeping stable between runs.
///
/// Platform-matched on purpose. A Windows install claiming to be Chrome on a
/// Mac contradicts every other signal it sends, which is worse than sending
/// nothing at all.
class BrowserIdentity {
  const BrowserIdentity._();

  /// macOS Chrome reports `Intel Mac OS X 10_15_7` on Apple Silicon too —
  /// Chrome froze that string years ago, so the "Intel" here is correct even on
  /// an M-series machine, and "correcting" it would be the tell.
  static const _macos = [
    BrowserProfile(
      userAgent:
          'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) '
          'AppleWebKit/537.36 (KHTML, like Gecko) '
          'Chrome/138.0.0.0 Safari/537.36',
      platform: '"macOS"',
      secChUa:
          '"Not)A;Brand";v="8", "Chromium";v="138", "Google Chrome";v="138"',
    ),
    BrowserProfile(
      userAgent:
          'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) '
          'AppleWebKit/537.36 (KHTML, like Gecko) '
          'Chrome/137.0.0.0 Safari/537.36',
      platform: '"macOS"',
      secChUa:
          '"Google Chrome";v="137", "Chromium";v="137", "Not_A Brand";v="24"',
    ),
    BrowserProfile(
      userAgent:
          'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) '
          'AppleWebKit/605.1.15 (KHTML, like Gecko) '
          'Version/18.5 Safari/605.1.15',
      platform: '"macOS"',
    ),
    BrowserProfile(
      userAgent:
          'Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:141.0) '
          'Gecko/20100101 Firefox/141.0',
      platform: '"macOS"',
    ),
  ];

  static const _windows = [
    BrowserProfile(
      userAgent:
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) '
          'AppleWebKit/537.36 (KHTML, like Gecko) '
          'Chrome/138.0.0.0 Safari/537.36',
      platform: '"Windows"',
      secChUa:
          '"Not)A;Brand";v="8", "Chromium";v="138", "Google Chrome";v="138"',
    ),
    BrowserProfile(
      userAgent:
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) '
          'AppleWebKit/537.36 (KHTML, like Gecko) '
          'Chrome/138.0.0.0 Safari/537.36 Edg/138.0.0.0',
      platform: '"Windows"',
      secChUa:
          '"Not)A;Brand";v="8", "Chromium";v="138", "Microsoft Edge";v="138"',
    ),
    BrowserProfile(
      userAgent:
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:141.0) '
          'Gecko/20100101 Firefox/141.0',
      platform: '"Windows"',
    ),
  ];

  static const _linux = [
    BrowserProfile(
      userAgent:
          'Mozilla/5.0 (X11; Linux x86_64) '
          'AppleWebKit/537.36 (KHTML, like Gecko) '
          'Chrome/138.0.0.0 Safari/537.36',
      platform: '"Linux"',
      secChUa:
          '"Not)A;Brand";v="8", "Chromium";v="138", "Google Chrome";v="138"',
    ),
    BrowserProfile(
      userAgent:
          'Mozilla/5.0 (X11; Linux x86_64; rv:141.0) '
          'Gecko/20100101 Firefox/141.0',
      platform: '"Linux"',
    ),
  ];

  static List<BrowserProfile> get _pool {
    if (Platform.isMacOS) return _macos;
    if (Platform.isWindows) return _windows;
    return _linux;
  }

  static BrowserProfile? _current;

  /// The profile for this run. Rolls one on first use if [seed] never ran, so
  /// a request that beats main() to the punch still gets a complete identity
  /// rather than none.
  static BrowserProfile get current => _current ??= _pool[Random().nextInt(
    _pool.length,
  )];

  /// Chooses this run's browser. Called from main() so the choice is made
  /// before anything can send a request; [random] is for tests.
  static void seed([Random? random]) {
    final pool = _pool;
    _current = pool[(random ?? Random()).nextInt(pool.length)];
  }

  /// Test seam: forget the choice so the next read re-rolls.
  static void reset() => _current = null;

  static String get userAgent => current.userAgent;
}
