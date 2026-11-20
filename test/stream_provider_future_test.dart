// Since Riverpod 3.5 a provider nobody listens to stays paused, so
// `ref.read(streamProvider.future)` on one never completes — no error, no
// timeout. 1.16.20 shipped with exactly that in the pet's launch restore:
// the pet silently never came back. Read the repository instead, or listen.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('no stream provider is awaited through .future', () {
    final providers = <String>{};
    final sources = <File, String>{};
    for (final f in Directory(
      'lib',
    ).listSync(recursive: true).whereType<File>()) {
      if (!f.path.endsWith('.dart') || f.path.endsWith('.g.dart')) continue;
      // Code only: a comment is allowed to name the mistake.
      final text = f
          .readAsLinesSync()
          .where((l) => !l.trimLeft().startsWith('//'))
          .join('\n');
      sources[f] = text;
      for (final m in RegExp(
        r'final (\w+) =\s*StreamProvider',
      ).allMatches(text)) {
        providers.add(m.group(1)!);
      }
    }
    expect(providers, isNotEmpty, reason: 'the scan itself must still work');
    final offenders = [
      for (final e in sources.entries)
        for (final p in providers)
          if (RegExp('$p(\\([^)]*\\))?\\s*\\.future').hasMatch(e.value))
            '${e.key.path}: $p.future',
    ];
    expect(offenders, isEmpty);
  });
}
