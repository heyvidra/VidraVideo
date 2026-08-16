// The point of this layer is that the identity it presents holds together.
// Headers that contradict each other are a stronger signal than sending none —
// a Chrome User-Agent whose `sec-ch-ua` names a different major is a
// combination no browser produces — so the tests here are mostly about
// combinations that must never occur, not about individual values.

import 'package:flutter_test/flutter_test.dart';
import 'package:vidra/src/core/network/browser_headers.dart';
import 'package:vidra/src/core/network/browser_identity.dart';

void main() {
  tearDown(BrowserIdentity.reset);

  Map<String, dynamic> headersFor(String url, {Map<String, dynamic>? seed}) {
    final headers = <String, dynamic>{...?seed};
    BrowserHeaders.apply(headers, Uri.parse(url));
    return headers;
  }

  group('identity', () {
    test('every profile in the pool is internally consistent', () {
      // Sample enough times to see the whole pool whatever this platform is.
      for (var i = 0; i < 60; i++) {
        BrowserIdentity.reset();
        final p = BrowserIdentity.current;
        final ua = p.userAgent;

        if (p.isChromium) {
          // The hint must name the same major the User-Agent does.
          final major = RegExp(r'Chrome/(\d+)').firstMatch(ua)?.group(1);
          expect(major, isNotNull, reason: 'chromium profile without Chrome/');
          expect(
            p.secChUa,
            contains('v="$major"'),
            reason: 'sec-ch-ua disagrees with the User-Agent: $ua',
          );
        } else {
          // Firefox and Safari send no client hints at all.
          expect(p.secChUa, isNull);
        }

        // Real Chrome sends four version components; two is a copy-paste tell.
        final chrome = RegExp(r'Chrome/([\d.]+)').firstMatch(ua)?.group(1);
        if (chrome != null) {
          expect(
            chrome.split('.').length,
            4,
            reason: 'implausible Chrome version "$chrome"',
          );
        }
      }
    });

    test('holds still for the whole run', () {
      final first = BrowserIdentity.userAgent;
      for (var i = 0; i < 20; i++) {
        expect(BrowserIdentity.userAgent, first);
      }
    });
  });

  group('a caller that brings its own User-Agent', () {
    // The regression this exists to prevent: a caller keeping its own UA while
    // inheriting our client hints, which names two different browsers at once.
    test('gets no client hints attached to it', () {
      final headers = headersFor(
        'https://www.dbku.tv/index.html',
        seed: {'User-Agent': 'Some/1.0 Other Browser'},
      );

      expect(headers['User-Agent'], 'Some/1.0 Other Browser');
      expect(headers.containsKey('sec-ch-ua'), isFalse);
      expect(headers.containsKey('sec-ch-ua-platform'), isFalse);
      expect(headers.containsKey('sec-ch-ua-mobile'), isFalse);
    });

    test('is matched case-insensitively', () {
      final headers = headersFor(
        'https://www.dbku.tv/',
        seed: {'user-agent': 'lowercase/1.0'},
      );

      expect(headers['user-agent'], 'lowercase/1.0');
      expect(headers.containsKey('User-Agent'), isFalse);
      expect(headers.containsKey('sec-ch-ua'), isFalse);
    });

    test('but still gets the headers that stand alone', () {
      final headers = headersFor(
        'https://www.dbku.tv/',
        seed: {'User-Agent': 'Some/1.0'},
      );

      expect(headers['Referer'], isNotNull);
      expect(headers['Accept-Language'], isNotNull);
    });
  });

  group('when we supply the User-Agent', () {
    test('chromium profiles carry all three hints, together', () {
      for (var i = 0; i < 40; i++) {
        BrowserIdentity.reset();
        final headers = headersFor('https://api.olelive.com/v1/pub/vod/list');
        final chromium = BrowserIdentity.current.isChromium;

        expect(headers.containsKey('sec-ch-ua'), chromium);
        expect(headers.containsKey('sec-ch-ua-mobile'), chromium);
        expect(headers.containsKey('sec-ch-ua-platform'), chromium);
      }
    });

    test('the User-Agent is the profile it came from', () {
      final headers = headersFor('https://api.olelive.com/x');
      expect(headers['User-Agent'], BrowserIdentity.current.userAgent);
    });
  });

  group('referer', () {
    // An XHR to the API host comes from a page on the SITE, which is a
    // different registrable domain. Sending the API host as its own referer is
    // a value no browser would produce for this request.
    test('a known API host refers to the site that fronts it', () {
      final headers = headersFor('https://api.olelive.com/v1/pub/vod/list');
      expect(headers['Referer'], 'https://www.olevod.com/');
      expect(headers['Sec-Fetch-Site'], 'cross-site');
      expect(headers['Origin'], 'https://www.olevod.com/');
    });

    test('a host that serves its own pages refers to itself', () {
      final headers = headersFor('https://www.dbku.tv/voddetail/1.html');
      expect(headers['Referer'], 'https://www.dbku.tv/');
      expect(headers['Sec-Fetch-Site'], 'same-origin');
      // Browsers omit Origin on same-origin GETs; sending it would contradict
      // the Sec-Fetch-Site we just claimed.
      expect(headers.containsKey('Origin'), isFalse);
    });

    test('an unknown host falls back to its own origin', () {
      final headers = headersFor('https://cdn.example.net/a/b.ts');
      expect(headers['Referer'], 'https://cdn.example.net/');
      expect(headers['Sec-Fetch-Site'], 'same-origin');
    });
  });

  group('fetchSite', () {
    test('classifies the three cases', () {
      String site(String url, String referer) =>
          BrowserHeaders.fetchSite(Uri.parse(url), Uri.parse(referer));

      expect(site('https://a.com/x', 'https://a.com/'), 'same-origin');
      expect(site('https://img.a.com/x', 'https://www.a.com/'), 'same-site');
      expect(site('https://api.olelive.com/x', 'https://www.olevod.com/'),
          'cross-site');
      // Scheme is part of an origin.
      expect(site('http://a.com/x', 'https://a.com/'), 'same-site');
    });
  });

  test('accept-language names a real language tag', () {
    expect(BrowserHeaders.acceptLanguage, matches(RegExp(r'^[a-zA-Z-]+,')));
    expect(BrowserHeaders.acceptLanguage, contains('q=0.'));
  });
}
