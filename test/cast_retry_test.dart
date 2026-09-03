import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:vidra/src/features/cast/data/cast_web_server.dart';
import 'package:vidra/src/features/cast/presentation/cast_provider.dart';
import 'package:vidra/src/features/video/data/video_repository.dart';
import 'package:vidra/src/features/video/domain/video_collection.dart';
import 'package:vidra_cast/vidra_cast.dart';

/// A renderer that wedges the way an LG does: [failures] refusals of the
/// queue, then it works.
///
/// Records the calls in order, because the ORDER is the fix — a wedged
/// renderer refuses the next SetAVTransportURI outright, so a bare replay
/// would never recover, and stop() drops the session playQueue needs.
class _FakeManager implements CastManager {
  _FakeManager({this.failures = 0});

  final int failures;
  final List<String> calls = [];
  int _plays = 0;

  @override
  Future<void> connect(CastDevice device) async => calls.add('connect');

  @override
  Future<void> playQueue(CastQueue queue) async {
    calls.add('playQueue');
    if (_plays++ < failures) {
      throw TimeoutException('Play was never answered');
    }
  }

  @override
  Future<void> stop() async => calls.add('stop');

  @override
  Future<void> disconnect() async => calls.add('disconnect');

  @override
  Stream<CastSession?> get sessionStream => const Stream.empty();

  @override
  Stream<List<CastDevice>> get devicesStream => const Stream.empty();

  @override
  List<CastDevice> get devices => const [];

  @override
  Future<void> stopDiscovery() async {}

  @override
  void dispose() {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Every source this test asks about hands its URLs straight back.
class _FakeRepository implements VideoRepository {
  @override
  Future<String?> resolveEpisodeUrl(String url, {String? sourceId}) async =>
      url;

  @override
  Map<String, String>? streamHeaders({String? sourceId}) => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Video _show(String url) => Video(
  apiId: 1,
  title: 'T',
  coverUrl: '',
  sourceId: 'demo',
  urls: [
    VideoEpisode(
      title: '第01集',
      qualities: [VideoQuality(name: 'HD', url: url)],
    ),
  ],
);

/// A device on a port nothing answers, so the Samsung probe fails fast and
/// the cast takes the DLNA route.
const _device = CastDevice(id: 'tv', name: 'TV', address: 'http://127.0.0.1:9');

Future<({CastController controller, _FakeManager manager})> _harness(
  int failures,
) async {
  final manager = _FakeManager(failures: failures);
  final container = ProviderContainer(
    overrides: [
      castManagerProvider.overrideWithValue(manager),
      videoRepositoryProvider.overrideWithValue(_FakeRepository()),
    ],
  );
  addTearDown(container.dispose);
  return (
    controller: container.read(castStateProvider.notifier),
    manager: manager,
  );
}

void main() {
  // A successful cast asks the platform to hold off idle sleep, and that is
  // a MethodChannel: without a binding it throws before the assertions below.
  // The binding then hands out a mock HttpClient, which the Samsung probe and
  // the proxy both need to be real sockets — hence putting that back.
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = null;

  // Roughly two casts in five to a webOS renderer never start: Play is
  // accepted and never answered. Asking again is the only thing that helps,
  // and it only helps in this order.
  test('a wedged renderer is stopped, reconnected and asked again', () async {
    final h = await _harness(1);
    try {
      await h.controller.cast(
        device: _device,
        video: _show('http://127.0.0.1:9/ep1.m3u8'),
        episodeIndex: 0,
      );
    } on CastServerException {
      return; // no LAN address on this machine
    }
    expect(h.manager.calls, [
      'connect',
      'playQueue',
      'stop',
      'connect',
      'playQueue',
    ]);
  }, timeout: const Timeout(Duration(seconds: 60)));

  test(
    'a renderer that keeps refusing gives up, and says what it said',
    () async {
      final h = await _harness(99);
      try {
        await expectLater(
          h.controller.cast(
            device: _device,
            video: _show('http://127.0.0.1:9/ep1.m3u8'),
            episodeIndex: 0,
          ),
          throwsA(isA<TimeoutException>()),
        );
      } on CastServerException {
        return;
      }
      // Three attempts, not four, and not one.
      expect(h.manager.calls.where((c) => c == 'playQueue').length, 3);
    },
    timeout: const Timeout(Duration(seconds: 60)),
  );
}
