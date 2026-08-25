import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vidra/src/core/network/api_exception.dart';
import 'package:vidra/src/features/video/data/yfsp/yfsp_challenge.dart';

// The transport's classifier: a browser response is either the API's payload
// (hand the body back) or Cloudflare's wall (throw so the UI shows the
// human-check button). Everything downstream hangs off this split.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('vidra/yfsp_browser');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  void stub(Map<String, Object?> Function() reply) {
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'fetch') return reply();
      return null;
    });
  }

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test('200 + JSON body is handed back', () async {
    stub(() => {'status': 200, 'body': '{"data":{"code":0}}'});
    expect(await YfspBrowser.fetch('https://x'), '{"data":{"code":0}}');
  });

  test('403 is the wall', () async {
    stub(() => {'status': 403, 'body': ''});
    expect(
      () => YfspBrowser.fetch('https://x'),
      throwsA(isA<ChallengeRequiredException>()),
    );
  });

  test('a navigation fallback (status 0) carrying challenge HTML is the wall',
      () async {
    stub(() => {'status': 0, 'body': '<html><title>Just a moment...</title>'});
    expect(
      () => YfspBrowser.fetch('https://x'),
      throwsA(isA<ChallengeRequiredException>()),
    );
  });

  test('a navigation fallback (status 0) carrying JSON is payload', () async {
    stub(() => {'status': 0, 'body': '{"data":{"code":0}}'});
    expect(await YfspBrowser.fetch('https://x'), '{"data":{"code":0}}');
  });

  test('a transport error (status -1) is a plain failure, not the wall',
      () async {
    stub(() => {'status': -1, 'error': 'boom'});
    await expectLater(
      () => YfspBrowser.fetch('https://x'),
      throwsA(
        isA<ApiException>().having(
          (e) => e is ChallengeRequiredException,
          'not a challenge',
          isFalse,
        ),
      ),
    );
  });

  test('a missing native side surfaces as the wall (no browser here)',
      () async {
    messenger.setMockMethodCallHandler(channel, null); // MissingPluginException
    expect(
      () => YfspBrowser.fetch('https://x'),
      throwsA(isA<ChallengeRequiredException>()),
    );
  });
}
