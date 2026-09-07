import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:vidra/src/features/cast/data/cast_web_server.dart';
import 'package:vidra/src/features/cast/domain/cast_target.dart';
import 'package:vidra/src/features/cast/presentation/cast_button.dart';
import 'package:vidra/src/features/cast/presentation/cast_provider.dart';
import 'package:vidra/src/features/video/data/video_repository.dart';
import 'package:vidra/src/features/video/domain/video_collection.dart';
import 'package:vidra_cast/vidra_cast.dart';

/// Never reached on the AirPlay route; here so the provider has something
/// that is not a real SSDP engine.
class _NoManager implements CastManager {
  @override
  Future<void> stopDiscovery() async {}
  @override
  Future<void> disconnect() async {}
  @override
  Stream<CastSession?> get sessionStream => const Stream.empty();
  @override
  void dispose() {}
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _PlainRepository implements VideoRepository {
  @override
  Future<String?> resolveEpisodeUrl(String url, {String? sourceId}) async =>
      url;
  @override
  Map<String, String>? streamHeaders({String? sourceId}) => null;
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

/// The native sender, as far as the controller can tell: what it was asked
/// to play, and a status the test moves through the phases a viewer would.
class _FakeSender {
  final List<String> played = [];
  bool available = true;
  bool picked = false;
  bool ended = false;
  bool dropped = false;
  bool cancelled = false;
  bool stopped = false;

  void install() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('vidra/airplay'), (
          call,
        ) async {
          switch (call.method) {
            case 'receivers':
              return available ? ["Helen's TV"] : <String>[];
            case 'play':
              played.add((call.arguments as Map)['url'] as String);
              ended = false; // the native side resets it on every play
              return true;
            case 'status':
              if (stopped) return {'active': false};
              return {
                'active': true,
                'external': picked && !dropped,
                'rate': 1.0,
                'position': 12.0,
                'duration': 600.0,
                'ended': ended,
                'cancelled': cancelled,
                'failed': null,
              };
            case 'stop':
              stopped = true;
              return true;
          }
          return null;
        });
  }
}

Video _show() => Video(
  apiId: 1,
  title: 'T',
  coverUrl: '',
  sourceId: 'demo',
  urls: const [
    VideoEpisode(
      title: '第01集',
      qualities: [VideoQuality(url: 'http://cdn.example/ep1.m3u8')],
    ),
    VideoEpisode(
      title: '第02集',
      qualities: [VideoQuality(url: 'http://cdn.example/ep2.m3u8')],
    ),
  ],
);

Future<CastController> _controller() async {
  final container = ProviderContainer(
    overrides: [
      castManagerProvider.overrideWithValue(_NoManager()),
      videoRepositoryProvider.overrideWithValue(_PlainRepository()),
    ],
  );
  addTearDown(container.dispose);
  return container.read(castStateProvider.notifier);
}

Future<void> _until(bool Function() done, {int seconds = 8}) async {
  final deadline = DateTime.now().add(Duration(seconds: seconds));
  while (!done()) {
    if (DateTime.now().isAfter(deadline)) fail('timed out waiting');
    await Future<void>.delayed(const Duration(milliseconds: 200));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = null;

  test(
    'the viewer picks a television, the show plays there, and moves on',
    () async {
      final sender = _FakeSender()..install();
      final c = await _controller();
      final casting = c.cast(
        device: CastButton.airPlayDevice("Helen's TV"),
        video: _show(),
        episodeIndex: 0,
        startPositionSeconds: 90,
      );
      // Nothing is decided until the viewer chooses in the system panel.
      await Future<void>.delayed(const Duration(milliseconds: 1200));
      expect(c.state.connecting, isTrue);
      sender.picked = true;
      try {
        await casting;
      } on CastServerException {
        return; // no LAN address on this machine
      }
      expect(c.state.route, CastRoute.airplay);
      expect(c.state.isCasting, isTrue);
      // The stream went through the proxy, not straight to the CDN.
      expect(sender.played.single, contains('/proxy?url='));
      expect(sender.played.single, contains('ep1'));

      // The episode ends: the next one is handed to the same player.
      sender.ended = true;
      await _until(() => sender.played.length == 2);
      expect(sender.played[1], contains('ep2'));

      // The viewer brings playback back to the Mac: the cast is over.
      sender.dropped = true;
      await _until(() => !c.state.isCasting);
      expect(sender.stopped, isTrue);
    },
    timeout: const Timeout(Duration(seconds: 60)),
  );

  test(
    'closing the panel without choosing is a cancelled cast, not a hang',
    () async {
      final sender = _FakeSender()..install();
      final c = await _controller();
      final casting = c.cast(
        device: CastButton.airPlayDevice("Helen's TV"),
        video: _show(),
        episodeIndex: 0,
      );
      await Future<void>.delayed(const Duration(milliseconds: 800));
      sender.cancelled = true;
      try {
        await expectLater(
          casting,
          throwsA(
            isA<CastException>().having(
              (e) => e.toString(),
              'message',
              contains('airplay cancelled'),
            ),
          ),
        );
      } on CastServerException {
        return;
      }
      expect(c.state.isCasting, isFalse);
      expect(sender.stopped, isTrue, reason: 'the panel must be taken down');
    },
    timeout: const Timeout(Duration(seconds: 60)),
  );
}
