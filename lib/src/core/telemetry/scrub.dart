import 'package:sentry_flutter/sentry_flutter.dart';

/// The last thing every event passes through before it leaves the machine.
///
/// Call sites are supposed to send shapes rather than content, but this runs
/// regardless, because the leak that matters is the one nobody wrote on
/// purpose: an exception whose `toString()` embeds the stream URL it failed on,
/// an HTTP breadcrumb the SDK's own integration recorded, a file path in a
/// message that happens to contain the user's account name.
///
/// The rules are deliberately blunt. Redacting a harmless string costs a
/// diagnostic detail; missing a URL costs a person their viewing history.
class Scrub {
  const Scrub._();

  /// `https://cdn.example.com/a/b?t=1` → `https://cdn.example.com/…`
  ///
  /// The host survives on purpose: "the segment came from a different host
  /// than the playlist" is the whole diagnosis for a cast failure, and a
  /// hostname is not a person. Path and query never survive — that is where
  /// the video id, the episode number and the signed token live.
  static final _url = RegExp(r'(https?://[^\s/?#]+)[^\s]*');

  /// Any absolute POSIX or Windows path: `/Users/somebody/Movies/…`. macOS
  /// home directories are named after their owner, so a path is a name.
  static final _posixPath = RegExp(r'(?<![\w.])/(?:Users|home|var|tmp)/[^\s,;)"\]]*');
  static final _winPath = RegExp(r'[A-Za-z]:\\\\?[^\s,;)"\]]*');

  /// Keys whose VALUE is content no matter how it got here.
  static const _bannedKeys = {
    'url',
    'uri',
    'link',
    'href',
    'title',
    'name',
    'keyword',
    'query',
    'q',
    'search',
    'path',
    'file',
    'filename',
    'cover',
    'cover_url',
    'poster',
    'episode',
    'episode_title',
    'video_title',
    'cookie',
    'cookies',
    'cookie_file',
    'token',
    'authorization',
  };

  static String text(String value) => value
      .replaceAllMapped(_url, (m) => '${m[1]}/…')
      .replaceAll(_posixPath, '<path>')
      .replaceAll(_winPath, '<path>');

  /// Redacts a data map: banned keys lose their value entirely, everything
  /// else keeps its shape with any URL or path inside it rewritten.
  static Map<String, Object?> data(Map<String, Object?> input) {
    return {
      for (final e in input.entries)
        e.key: _bannedKeys.contains(e.key.toLowerCase())
            ? '<redacted>'
            : _value(e.value),
    };
  }

  static Object? _value(Object? v) => switch (v) {
    String s => text(s),
    Map<String, Object?> m => data(m),
    List<Object?> l => [for (final e in l) _value(e)],
    _ => v,
  };

  static SentryEvent event(SentryEvent event) {
    final message = event.message;
    return event
      ..message = message == null
          ? null
          : SentryMessage(
              text(message.formatted),
              template: message.template,
              params: const [],
            )
      ..breadcrumbs = [
        for (final c in event.breadcrumbs ?? const <Breadcrumb>[])
          breadcrumb(c) ?? c,
      ]
      // An exception's own message routinely carries the URL it failed on:
      // dio, HttpClient and drift all format one into theirs.
      ..exceptions = [
        for (final e in event.exceptions ?? const <SentryException>[])
          e..value = e.value == null ? null : text(e.value!),
      ]
      ..request = null;
  }

  static SentryTransaction transaction(SentryTransaction tx) {
    return tx
      ..breadcrumbs = [
        for (final c in tx.breadcrumbs ?? const <Breadcrumb>[])
          breadcrumb(c) ?? c,
      ]
      ..request = null;
  }

  static Breadcrumb? breadcrumb(Breadcrumb crumb) {
    // The SDK's own HTTP integration records the full request URL. Nothing
    // here needs per-request breadcrumbs the app did not write itself, and
    // keeping them scrubbed is cheaper to reason about than keeping them out.
    return crumb.copyWith(
      message: crumb.message == null ? null : text(crumb.message!),
      data: crumb.data == null ? null : data(crumb.data!),
    );
  }
}
