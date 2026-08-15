import 'dart:async';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:vidra_cast/vidra_cast.dart';

import '../../../core/telemetry/telemetry.dart';
import '../../../core/utils/log.dart';
import '../../video/domain/play_history.dart';
import '../../video/data/history_repository.dart';
import '../../video/domain/video_collection.dart';
import '../../video/presentation/play_history_provider.dart';
import '../data/cast_web_server.dart';
import '../data/sleep_blocker.dart';
import '../domain/cast_target.dart';

/// The DLNA control point. One per window, disposed with it.
///
/// Constructed lazily — nothing here touches the network until something
/// watches this provider, so an app that never casts never opens a socket.
final castManagerProvider = Provider<CastManager>((ref) {
  final manager = CastManagerImpl();
  ref.onDispose(() {
    // dispose() alone leaves the TV playing and the renderer connected, so
    // hang up first. Neither call can be awaited here; both are fire-and-
    // forget by the time the provider is going away.
    unawaited(manager.disconnect());
    manager.dispose();
  });
  return manager;
});

/// Devices seen on the network so far.
///
/// Yields the manager's current list before following the stream, and that
/// seed is load-bearing rather than an optimisation: cached devices are
/// emitted within milliseconds of startDiscovery(), before the picker has
/// finished building, and `devicesStream` is a broadcast that replays
/// nothing. Without the seed the first open of the picker spun forever on a
/// network whose devices had already been found, and only a second open —
/// served by the provider's retained value — showed anything.
final castDevicesProvider = StreamProvider<List<CastDevice>>((ref) async* {
  final manager = ref.watch(castManagerProvider);
  yield manager.devices;
  yield* manager.devicesStream;
});

/// The current DLNA session, or null when nothing is being cast.
final castSessionProvider = StreamProvider<CastSession?>((ref) {
  final manager = ref.watch(castManagerProvider);
  return manager.sessionStream;
});

final castWebServerProvider = Provider<CastWebServer>((ref) {
  final server = CastWebServer();
  ref.onDispose(server.dispose);
  return server;
});

/// What is playing on a TV right now, as far as this app knows.
class CastState {
  const CastState({
    this.device,
    this.route,
    this.video,
    this.playlist,
    this.connecting = false,
    this.playlistIndex,
  });

  final CastDevice? device;
  final CastRoute? route;
  final Video? video;
  final CastPlaylist? playlist;

  /// Which entry of [playlist] the television is on, as last reported by it.
  ///
  /// Seeded from the playlist's start so a freshly-started cast can name its
  /// episode before the first report arrives; the TV's own reports then keep
  /// it honest across auto-advance, which is the only way this app learns
  /// the show moved on by itself.
  final int? playlistIndex;

  /// On its way: probing the device, pairing, connecting. Seconds, not
  /// milliseconds, so the page has to say so.
  final bool connecting;

  bool get isCasting => device != null && !connecting;

  /// The episode number on screen, in the show's own numbering.
  ///
  /// Not the playlist position: episodes with no playable URL never enter
  /// the playlist, so the two drift apart by however many were dropped
  /// before it — the same reason watch history is keyed by source index.
  int? get episodeIndex {
    final i = playlistIndex;
    final list = playlist;
    if (i == null || list == null) return null;
    return list.sourceIndexOf(i);
  }

  CastState withPlaylistIndex(int index) => CastState(
    device: device,
    route: route,
    video: video,
    playlist: playlist,
    connecting: connecting,
    playlistIndex: index,
  );
}

final castStateProvider = NotifierProvider<CastController, CastState>(
  CastController.new,
);

/// Drives a cast from start to finish and keeps watch history honest while
/// it runs.
///
/// The two routes differ in more than transport. DLNA hands the renderer a
/// stream and reads position back off it; the browser route hands the TV a
/// page, and the page reports its own position. Either way the app is what
/// remembers where the viewer got to, so both feed the same history rows the
/// in-app player writes.
class CastController extends Notifier<CastState> {
  ProviderSubscription<AsyncValue<CastSession?>>? _progressSub;
  DateTime? _lastWrite;

  @override
  CastState build() {
    ref.onDispose(() => _progressSub?.close());
    return const CastState();
  }

  CastManager get _manager => ref.read(castManagerProvider);
  CastWebServer get _server => ref.read(castWebServerProvider);

  /// How far the current attempt got.
  ///
  /// A cast crosses two networks and a television, and every interesting
  /// failure looks the same from the outside: a snack bar, and a TV that
  /// stayed dark. What separates them is WHERE it stopped — the Tizen probe,
  /// the TV fetching our page, the renderer accepting the queue — so the
  /// stage is carried on the breadcrumb trail and ends up as the tag on
  /// whatever gets thrown.
  String _stage = 'idle';
  final Stopwatch _elapsed = Stopwatch();

  /// Records one stage. Shapes only — enum names, counts, milliseconds. A
  /// title, a URL or a television's name here would defeat [Telemetry]'s
  /// whole premise, and none of them would say anything a count does not.
  void _mark(String stage, {Map<String, Object?> detail = const {}}) {
    _stage = stage;
    Telemetry.castBreadcrumb(
      stage,
      detail: {'at_ms': _elapsed.elapsedMilliseconds, ...detail},
    );
  }

  Future<void> startDiscovery() => _manager.startDiscovery();
  Future<void> stopDiscovery() => _manager.stopDiscovery();

  /// Whether [device] is a Samsung TV, which decides the route.
  ///
  /// Samsung answers on the Tizen API port; its DLNA renderer refuses an HLS
  /// playlist, so those get a page and a browser rather than a stream. The
  /// probe is cheap and its failure mode is the right one: unreachable reads
  /// as "not Samsung", and DLNA is the path that works for everything else.
  Future<CastRoute> routeFor(CastDevice device) async {
    final host = Uri.parse(device.address).host;
    final tizen = TizenRemoteController(host);
    final reachable = await tizen.connect().timeout(
      const Duration(seconds: 3),
      onTimeout: () => false,
    );
    tizen.disconnect();
    return reachable ? CastRoute.browser : CastRoute.dlna;
  }

  /// Casts [video] from [episodeIndex], resuming at [startPositionSeconds].
  ///
  /// Throws on the failures worth telling the viewer about: nothing playable,
  /// no LAN address, a renderer that will not connect. It deliberately does
  /// NOT throw when the renderer accepts the URI and then plays nothing —
  /// DLNA gives us no way to know, so the UI watches the session instead.
  Future<void> cast({
    required CastDevice device,
    required Video video,
    required int episodeIndex,
    int startPositionSeconds = 0,
  }) async {
    final playlist = buildCastPlaylist(
      video: video,
      episodeIndex: episodeIndex,
      startPositionSeconds: startPositionSeconds,
    );
    if (playlist == null) throw const CastException('no playable episode');
    // The button's own busy flag only guards the show it belongs to; walking
    // to another show's page and tapping there gets past it, and two casts
    // starting at once fight over one server and one manager.
    if (state.connecting) {
      throw const CastException('a cast is already starting');
    }

    // Say so before the slow part, not after: device probe, pairing and
    // connect together run to tens of seconds, and a page that looks
    // untouched invites a second tap and a second cast.
    state = CastState(device: device, video: video, connecting: true);
    _elapsed
      ..reset()
      ..start();
    _mark(
      'start',
      detail: {
        'protocol': device.protocol.name,
        'episodes': playlist.items.length,
        'resuming': playlist.startPositionSeconds > 0,
      },
    );
    try {
      // Whatever was running is over. Unsubscribing here rather than in the
      // DLNA path covers the case that used to leak: casting show A over
      // DLNA and then show B to a Samsung, where nothing stopped A's
      // listener and it went on writing A's progress every two seconds,
      // taking the throttle window B needed.
      _progressSub?.close();
      _progressSub = null;
      _lastWrite = null;
      // Bind fresh, too — the previous session's server holds the previous
      // TV's interface, and the address it chose may not reach this one.
      await _server.stop();
      await _manager.stopDiscovery();
      // The ceiling on the whole attempt. Every await under it should be
      // bounded on its own, but the guard above reads `connecting`, so one
      // unbounded call against a wedged TV — accepted the TCP connection,
      // answers nothing — would otherwise lock casting out until the app is
      // restarted. Sized for the slowest honest path: Samsung first-time
      // pairing (45s) plus the wait for the TV to fetch the page (25s).
      final route = await () async {
        _mark('probe');
        final route = await routeFor(device);
        _mark('route', detail: {'route': route.name});
        if (route == CastRoute.browser) {
          await _castViaBrowser(device, video, playlist);
        } else {
          await _castViaDlna(device, video, playlist);
        }
        return route;
      }().timeout(
        const Duration(seconds: 90),
        onTimeout: () => throw const CastException('the TV did not answer'),
      );
      _mark('ready');
      // Casting makes this machine the media server, so an idle sleep stops
      // the picture on the television. Held for the life of the session and
      // released on every exit below — including the failure path, which is
      // why this sits after the last throw.
      await SleepBlocker.hold();
      state = CastState(
        device: device,
        route: route,
        video: video,
        playlist: playlist,
        playlistIndex: playlist.startIndex,
      );
    } catch (e, stack) {
      // The one place every failure passes through. Without this, a cast the
      // renderer refused left the server listening on every interface with a
      // live token and a loaded playlist, while the UI showed "cast" again —
      // so there was no longer any way to switch it off.
      //
      // It is also the only place with both the stage and a real stack, so the
      // report goes out from here. The stage is in the tag, not the message:
      // `cast.browser.page_wait` and `cast.dlna.connect` are different bugs
      // that throw the same CastException, and a tag is what lets Sentry keep
      // them apart. The two guards above this try are deliberately not
      // reported — an empty show and a double tap are answers, not defects.
      Telemetry.castBreadcrumb(_stage, outcome: 'error');
      Telemetry.error('cast.$_stage', e, stack);
      //
      // Neither teardown may throw. Reaching the reset below matters more
      // than either of them succeeding: the guard at the top of this method
      // reads `connecting`, so an exception escaping here would lock casting
      // off for the rest of the session.
      try {
        await _server.stop();
      } catch (_) {}
      try {
        await _manager.disconnect();
      } catch (_) {}
      // A cast that never started must not leave the machine unable to
      // sleep. Harmless when the hold never happened.
      try {
        await SleepBlocker.release();
      } catch (_) {}
      state = const CastState();
      rethrow;
    }
  }

  Future<void> _castViaBrowser(
    CastDevice device,
    Video video,
    CastPlaylist playlist,
  ) async {
    final host = Uri.parse(device.address).host;
    _mark('browser.serve');
    await _server.start(peerHost: host);
    _server.onProgress = (p) => _recordProgress(video, playlist, p);
    final url = _server.serve(playlist);
    final tizen = TizenRemoteController(host);
    _mark('browser.launch');
    if (!await tizen.launchBrowser(url)) {
      // Take the server down again. It is serving this show to the LAN and
      // nothing on screen would say so, because the UI is about to be told
      // the cast failed.
      await _server.stop();
      throw const CastException('could not open the TV browser');
    }
    // launchBrowser only says the TV was told. Whether it listened is a
    // different question, and the answer is the TV asking us for the page:
    // an unanswered firewall prompt or an address on the wrong interface
    // both look identical from the sending side, and used to end in
    // "casting to Samsung" over a television showing nothing.
    _mark('browser.page_wait');
    try {
      await _server.pageFetched.timeout(const Duration(seconds: 25));
    } on TimeoutException {
      await _server.stop();
      throw const CastException('the TV never opened the page');
    }
    unawaited(_nudgeFullscreen(tizen));
  }

  /// Presses a key on the television so its browser can go fullscreen.
  ///
  /// A browser only grants fullscreen from a user gesture, and this page was
  /// opened remotely — there has never been one, so the page's own request
  /// is refused and the viewer gets a video framed by browser furniture.
  /// A key sent down the remote channel is a real input event, which gives
  /// the page's keydown handler the gesture it needs.
  ///
  /// KEY_UP rather than KEY_ENTER: nothing on the page is focusable, so it
  /// has no effect beyond existing, while Enter could activate whatever a TV
  /// browser decided to focus.
  Future<void> _nudgeFullscreen(TizenRemoteController tizen) async {
    for (final delay in const [
      Duration(seconds: 4),
      Duration(seconds: 4),
      Duration(seconds: 6),
    ]) {
      await Future<void>.delayed(delay);
      // Spread out because the page has to exist first, and how long the TV
      // takes to open its browser is not ours to know.
      await tizen.sendKeyEvent(CastKeyEvent.up);
    }
  }

  Future<void> _castViaDlna(
    CastDevice device,
    Video video,
    CastPlaylist playlist,
  ) async {
    _mark('dlna.connect');
    await _manager
        .connect(device)
        .timeout(
          const Duration(seconds: 20),
          onTimeout: () => throw const CastException('the TV did not answer'),
        );
    // Hand the renderer our own address, not the CDN's. Measured on an LG
    // webOS: given the catalog's https URL directly it answers UPnP 716,
    // "Resource not found" — it will not do TLS, and it sends no
    // User-Agent to a CDN that requires one. Through the proxy it is plain
    // http from a machine on its own network, with the headers restored.
    _mark('dlna.serve');
    await _server.start(peerHost: Uri.parse(device.address).host);
    _server.onProgress = (p) => _recordProgress(video, playlist, p);
    _server.serve(playlist);
    // Resume by cutting the playlist, not by asking the renderer to seek.
    // An LG's remote has no seek — its fast-forward is 2x/4x playback — so
    // Seek was refused every time and every cast restarted the episode. The
    // episode that STARTS where the viewer left off asks the renderer for
    // nothing, and only the item being resumed carries the offset: the ones
    // after it are watched from their beginning.
    final resumeAt = playlist.startPositionSeconds;
    _mark('dlna.play_queue');
    await _manager.playQueue(
      CastQueue(
        items: [
          for (final (i, item) in playlist.items.indexed)
            PlaylistItem(
              id: item.url,
              title: item.title,
              mediaUrl: _server.proxied(
                item.url,
                startSeconds: i == playlist.startIndex ? resumeAt : 0,
              ),
            ),
        ],
        currentIndex: playlist.startIndex,
      ),
    );
    _watchDlnaProgress(video, playlist);
  }

  /// Mirrors the renderer's position into watch history.
  ///
  /// The manager already polls the device every two seconds for its own
  /// bookkeeping; this reads the session it publishes rather than adding a
  /// second poll of the TV.
  void _watchDlnaProgress(Video video, CastPlaylist playlist) {
    // cast() has already closed whatever came before — including when the
    // previous cast went to a Samsung and never came through here at all.
    _progressSub = ref.listen(castSessionProvider, (_, next) {
      final session = next.value;
      if (session == null) return;
      _recordProgress(
        video,
        playlist,
        CastProgress(
          playlistIndex: session.queue.currentIndex,
          position: session.currentPosition,
          duration: session.duration,
        ),
      );
    });
  }

  /// Writes a position from the TV into the same rows the in-app player
  /// writes, throttled to once every five seconds — a report arrives every
  /// two, and watch history is not worth a database write that often.
  Future<void> _recordProgress(
    Video video,
    CastPlaylist playlist,
    CastProgress p,
  ) async {
    if (p.duration <= Duration.zero) return;
    // The TV moving to the next episode by itself is something only these
    // reports can tell us, and the detail page names the episode on screen
    // from it. Updated before the throttle below, which exists to spare the
    // database, not the UI.
    if (state.isCasting && state.playlistIndex != p.playlistIndex) {
      state = state.withPlaylistIndex(p.playlistIndex);
    }
    // Put back what the cut took out. A resumed episode is served starting at
    // startPositionSeconds, so the renderer counts from there and reports a
    // position — and a duration — short by exactly that much. Writing those
    // raw would walk the viewer's progress backwards by the resume offset on
    // every cast, which is the whole reason this correction exists. Only the
    // episode that was resumed is short; the TV moving on to the next one is
    // playing a whole file again.
    final offset = p.playlistIndex == playlist.startIndex
        ? Duration(seconds: playlist.startPositionSeconds)
        : Duration.zero;
    final position = p.position + offset;
    final duration = p.duration + offset;
    // Back from playlist position to episode number. They differ whenever an
    // episode had no URL and was left out, and history everywhere else in
    // the app is keyed by the episode number.
    final episodeIndex = playlist.sourceIndexOf(p.playlistIndex);
    if (episodeIndex == null) return;
    final now = DateTime.now();
    final last = _lastWrite;
    if (last != null && now.difference(last) < const Duration(seconds: 5)) {
      return;
    }
    _lastWrite = now;
    try {
      final repo = ref.read(historyRepositoryProvider);
      await repo.saveEpisodeHistory(
        EpisodeHistory(
          sourceId: video.sourceId,
          videoId: video.apiId,
          episodeIndex: episodeIndex,
          positionMillis: position.inMilliseconds,
          durationMillis: duration.inMilliseconds,
        ),
      );
      await repo.saveVideoHistory(
        VideoHistory(
          sourceId: video.sourceId,
          videoId: video.apiId,
          videoTitle: video.title,
          coverUrl: video.coverUrl,
          type: video.type,
          region: video.region,
          year: video.year,
          actor: video.actor,
          remarks: video.remarks,
          blurb: video.blurb,
          lastEpisodeIndex: episodeIndex,
        ),
      );
      ref.invalidate(playHistoryProvider);
    } catch (e) {
      // A history write is bookkeeping; losing one must not interrupt what
      // is playing on the television.
      logD('cast', 'progress write failed: $e');
    }
  }

  /// Stops playback on the TV and tears down whichever route was in use.
  Future<void> stop() async {
    _progressSub?.close();
    _progressSub = null;
    if (state.route == CastRoute.dlna) {
      try {
        await _manager.stop();
      } catch (_) {}
      await _manager.disconnect();
    }
    // Both routes now, not just the browser one: DLNA streams through the
    // proxy too, so leaving the server up would keep this show reachable on
    // the network after the viewer stopped casting it.
    await _server.stop();
    await SleepBlocker.release();
    state = const CastState();
  }
}

class CastException implements Exception {
  const CastException(this.message);
  final String message;
  @override
  String toString() => message;
}
