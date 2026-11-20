import 'package:flutter_test/flutter_test.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:vidra/src/core/telemetry/scrub.dart';

/// The scrubber is the only thing standing between a diagnostic report and a
/// person's viewing history, so it is tested against the shapes that actually
/// leak: an exception that formatted a stream URL into its message, an HTTP
/// breadcrumb the SDK recorded on its own, a home directory in a file path.
void main() {
  group('text', () {
    test(
      'a URL keeps its host and loses everything that identifies content',
      () {
        const raw =
            'failed on https://cdn.olelive.com/vod/83579/ep12.m3u8?_vv=abc123';
        final out = Scrub.text(raw);

        expect(out, contains('https://cdn.olelive.com/'));
        // The video id, the episode and the signed token are the whole point.
        expect(out, isNot(contains('83579')));
        expect(out, isNot(contains('ep12')));
        expect(out, isNot(contains('_vv')));
        expect(out, isNot(contains('abc123')));
      },
    );

    test('a home directory never survives — it is named after its owner', () {
      final out = Scrub.text('wrote /Users/zhangwei/Movies/九门 第3集.mp4 ok');
      expect(out, isNot(contains('zhangwei')));
      expect(out, isNot(contains('九门')));
      expect(out, contains('<path>'));
    });

    test('windows paths too', () {
      final out = Scrub.text(r'opening C:\Users\wei\Videos\show.mp4');
      expect(out, isNot(contains('wei')));
      expect(out, contains('<path>'));
    });

    test('a path with a space in it is gone whole, not up to the space', () {
      // The download folder is the user's choice and files are named after
      // the show. The old pattern stopped at the first space.
      final out = Scrub.text(
        "open failed, path = '/Users/wei/Movies/Vidra/Breaking Bad/第1集.mp4'",
      );
      expect(out, isNot(contains('Bad')));
      expect(out, isNot(contains('第1集')));
      expect(out, startsWith('open failed, path = '));

      final win = Scrub.text(
        r'cannot open C:\Users\Zhang Wei\Videos\九门\第3集.mp4',
      );
      expect(win, isNot(contains('Wei')));
      expect(win, isNot(contains('九门')));
    });

    test('a path on any root, and a scheme-less stream path', () {
      for (final raw in [
        'wrote /Volumes/Media/Vidra/九门/第3集.mp4',
        'stat /private/var/folders/ab/九门.tmp failed',
        'GET /vod/play/83579/ep12.m3u8 -> 404',
      ]) {
        final out = Scrub.text(raw);
        expect(out, contains('<path>'), reason: raw);
        expect(out, isNot(contains('九门')), reason: raw);
        expect(out, isNot(contains('83579')), reason: raw);
      }
    });

    test('a failed statement keeps its SQL and loses its values', () {
      // What sqlite3 formats when the settings row is locked mid-write.
      const raw =
          'SqliteException(5): while executing statement, database is locked\n'
          '  Causing statement: UPDATE "app_settings" SET "search_history" = ?;'
          ', parameters: ["九门","breaking bad"]';
      final out = Scrub.text(raw);
      expect(out, contains('database is locked'));
      expect(out, contains('UPDATE "app_settings"'));
      expect(out, isNot(contains('九门')));
      expect(out, isNot(contains('breaking bad')));
    });

    test('ordinary slashes are not paths', () {
      const raw = 'retry 2/3 after 403, and/or a redirect; ratio 16/9';
      expect(Scrub.text(raw), raw);
    });

    test('text with nothing sensitive is left alone', () {
      const raw = 'upstream stalled after 20s, status 403, 2 redirects';
      expect(Scrub.text(raw), raw);
    });
  });

  group('data', () {
    test('banned keys lose their value whatever it holds', () {
      final out = Scrub.data({
        'title': '九门',
        'url': 'https://cdn.example.com/x.m3u8',
        'cookie_file': '/Users/a/cookies.txt',
        'status': 403,
      });

      expect(out['title'], '<redacted>');
      expect(out['url'], '<redacted>');
      expect(out['cookie_file'], '<redacted>');
      // The diagnosis itself must survive, or the whole exercise is pointless.
      expect(out['status'], 403);
    });

    test('nested maps and lists are scrubbed too', () {
      final out = Scrub.data({
        'hops': [
          'https://a.example.com/seg/1.ts?token=x',
          'https://b.example.com/seg/1.ts',
        ],
        'inner': {'title': 'x', 'code': 302},
      });

      final hops = out['hops'] as List<Object?>;
      expect(hops[0], 'https://a.example.com/…');
      expect(hops[1], 'https://b.example.com/…');
      // Different hosts is exactly the fact a cast diagnosis needs.
      expect(hops[0], isNot(hops[1]));

      final inner = out['inner'] as Map<String, Object?>;
      expect(inner['title'], '<redacted>');
      expect(inner['code'], 302);
    });
  });

  group('event', () {
    test('an exception message carrying a URL is redacted on the way out', () {
      final scrubbed = Scrub.event(
        SentryEvent(
          exceptions: [
            SentryException(
              type: 'HttpException',
              value: 'GET https://cdn.example.com/vod/83579.m3u8 failed (403)',
            ),
          ],
        ),
      );

      final value = scrubbed.exceptions!.single.value!;
      expect(value, contains('403'));
      expect(value, isNot(contains('83579')));
    });

    test('the request context is dropped entirely', () {
      final scrubbed = Scrub.event(
        SentryEvent(
          request: SentryRequest(url: 'https://cdn.example.com/vod/83579.m3u8'),
        ),
      );
      expect(scrubbed.request, isNull);
    });

    test('a breadcrumb the SDK recorded is scrubbed with the event', () {
      final scrubbed = Scrub.event(
        SentryEvent(
          breadcrumbs: [
            Breadcrumb(
              category: 'http',
              message: 'GET https://cdn.example.com/vod/83579.m3u8',
              data: {'url': 'https://cdn.example.com/vod/83579.m3u8'},
            ),
          ],
        ),
      );

      final crumb = scrubbed.breadcrumbs!.single;
      expect(crumb.message, isNot(contains('83579')));
      expect(crumb.data!['url'], '<redacted>');
    });
  });
}
