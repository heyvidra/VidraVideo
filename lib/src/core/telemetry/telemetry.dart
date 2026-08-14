import 'dart:async';
import 'dart:io' show Platform;

import 'package:sentry_flutter/sentry_flutter.dart';

import '../utils/log.dart';
import 'scrub.dart';

/// Diagnostics: what the app tells us about how it ran on a machine we do
/// not have.
///
/// Every customer problem this exists for — a 2016 Intel MacBook that stutters,
/// a television that freezes mid-cast — is one nobody here can reproduce. What
/// gets reported is therefore only ever the SHAPE of a failure: frame times,
/// hardware class, protocol stage, status codes, error types.
///
/// ## What must never leave the machine
///
/// This is a video app, so the interesting-looking data is exactly the data
/// that must not be collected. No titles, no search terms, no stream or cover
/// URLs, no episode names, no local file paths (they carry the user's account
/// name), no cookie-file contents or paths, no catalog account state. None of
/// it is needed to diagnose a dropped frame or a 403 from a CDN.
///
/// Two layers enforce that, deliberately redundant because one of them will
/// eventually be forgotten at a call site:
///
/// 1. callers pass shapes, not content — see [castBreadcrumb], which takes a
///    stage and a status rather than a URL;
/// 2. [Scrub.event] runs over every event on its way out and redacts anything
///    that looks like a URL, a path or a query string regardless.
///
/// ## Off unless someone asked for it
///
/// The DSN arrives as a `--dart-define`, never from this repo. Without one —
/// every dev build, every fork, every CI run — [isEnabled] is false and each
/// method here returns immediately, so there is no accidental reporting and no
/// secret to leak. The user's own switch is checked on top of that.
class Telemetry {
  const Telemetry._();

  /// Set by the release build: `--dart-define=SENTRY_DSN=https://…`.
  static const _dsn = String.fromEnvironment('SENTRY_DSN');

  static bool _enabled = false;

  /// Whether anything is actually being reported. False whenever the build
  /// carries no DSN or the user turned diagnostics off.
  static bool get isEnabled => _enabled;

  /// Starts diagnostics for THIS engine, then runs [appRunner].
  ///
  /// [windowKind] tags every event, because "the player window froze" and
  /// "the catalog window froze" are different bugs and the stack traces alone
  /// do not distinguish them. Secondary engines must not initialize the native
  /// crash handler: it is process-global, and a second engine claiming it
  /// fights the first for the same signal handlers.
  static Future<void> run({
    required String windowKind,
    required bool userOptedIn,
    required bool isMainEngine,
    required String release,
    required Map<String, String> deviceTags,
    required FutureOr<void> Function() appRunner,
  }) async {
    if (_dsn.isEmpty || !userOptedIn) {
      _enabled = false;
      await appRunner();
      return;
    }

    _enabled = true;
    await SentryFlutter.init((options) {
      options.dsn = _dsn;
      options.release = release;
      options.environment = _environment;

      // The whole privacy posture, in one place.
      options.sendDefaultPii = false;
      options.attachScreenshot = false;
      options.beforeSend = (event, hint) => Scrub.event(event);
      options.beforeSendTransaction = (tx, hint) => Scrub.transaction(tx);
      // Breadcrumbs are the biggest leak surface: the HTTP and navigation
      // integrations record full URLs and route names on their own. Scrub
      // every one, whoever recorded it.
      options.beforeBreadcrumb = (crumb, hint) =>
          crumb == null ? null : Scrub.breadcrumb(crumb);

      // Errors always; traces are sampled because a cast session or a frame
      // report is worth keeping while routine navigation is not.
      options.tracesSampleRate = 1.0;
      options.enableAutoPerformanceTracing = false;

      options.autoInitializeNativeSdk = isMainEngine;
      options.debug = false;
    }, appRunner: () async {
      Sentry.configureScope((scope) {
        scope.setTag('window', windowKind);
        for (final tag in deviceTags.entries) {
          scope.setTag(tag.key, tag.value);
        }
      });
      // A heartbeat, once per launch, from the main engine only.
      //
      // Everything else here reports an exception or a filled measurement
      // window, so a healthy machine that renders little sends nothing at all
      // — and "nothing arrived" then means either "all is well" or "this has
      // been broken since the release" with no way to tell which. 1.12.0
      // shipped in exactly that state and cost an afternoon of proving the
      // pipe was alive by hand. One event per launch is nothing against a
      // 5k/month tier and it makes the absence of data readable.
      if (isMainEngine) {
        report('app.start', data: {'engine': windowKind});
      }
      await appRunner();
    });
  }

  static String get _environment {
    var release = true;
    assert(() {
      release = false;
      return true;
    }());
    return release ? 'release' : 'debug';
  }

  /// Stops reporting for the rest of this run.
  ///
  /// Someone who turns diagnostics off means now, not next launch, so this
  /// closes the client rather than only writing the setting. Turning it back
  /// on does need a restart — the SDK is initialized once, around the app —
  /// and the settings screen says so.
  static Future<void> disable() async {
    if (!_enabled) return;
    _enabled = false;
    await Sentry.close();
  }

  /// Reports an error the app handled but should not have had to.
  ///
  /// [where] is a fixed label ('olevod.fetchVideos', 'cast.setUri'), never a
  /// formatted message: labels group, sentences do not.
  static void error(String where, Object error, [StackTrace? stack]) {
    if (!_enabled) return;
    unawaited(
      Sentry.captureException(
        error,
        stackTrace: stack,
        withScope: (scope) => scope.setTag('where', where),
      ).catchError((Object e) {
        // Diagnostics must never be able to break the thing they watch.
        logD('telemetry', 'capture failed: $e');
        return SentryId.empty();
      }),
    );
  }

  /// One step of a cast attempt: the stage reached and how it went.
  ///
  /// Shapes only. [detail] is for status codes, durations and enum names —
  /// a URL or a title here would defeat the point of the whole file, and
  /// [Scrub] will redact it anyway.
  static void castBreadcrumb(
    String stage, {
    String? outcome,
    Map<String, Object?> detail = const {},
  }) {
    if (!_enabled) return;
    unawaited(
      Sentry.addBreadcrumb(
        Breadcrumb(
          category: 'cast',
          message: stage,
          level: outcome == 'error' ? SentryLevel.error : SentryLevel.info,
          data: {'outcome': ?outcome, ...detail},
        ),
      ),
    );
  }

  /// Sends one aggregate report — a frame-timing window, a cast session
  /// summary — as a message event carrying [measurements] as tags.
  ///
  /// A message rather than a transaction because these are already summarised:
  /// a transaction per frame would be absurd, and per-window aggregates are
  /// what answers "did the Intel optimisations land".
  static void report(
    String name, {
    Map<String, Object?> data = const {},
    SentryLevel level = SentryLevel.info,
  }) {
    if (!_enabled) return;
    unawaited(
      Sentry.captureEvent(
        SentryEvent(
          message: SentryMessage(name),
          level: level,
          contexts: Contexts()..['report'] = data,
        ),
      ).catchError((Object e) {
        logD('telemetry', 'report failed: $e');
        return SentryId.empty();
      }),
    );
  }

  /// The machine, as far as diagnostics are concerned: enough to tell a 2016
  /// Intel laptop from an M4, and nothing that identifies a person.
  static Map<String, String> deviceTags({required bool reduceEffects}) {
    return {
      'cpu': Platform.version.contains('x64') ? 'intel' : 'apple_silicon',
      'cores': '${Platform.numberOfProcessors}',
      'os': Platform.operatingSystemVersion.split(' ').take(3).join(' '),
      'reduce_effects': '$reduceEffects',
    };
  }
}
