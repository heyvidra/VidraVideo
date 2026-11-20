import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Every `tr('a.b')` in lib/ must resolve in both languages.
///
/// A missing key does not fail anything at runtime — easy_localization draws
/// the key itself — which is how 1.16.8 shipped an Undo button labelled
/// `common.undo`: the string had been added under the wrong parent.
void main() {
  Set<String> keys(String lang) {
    final out = <String>{};
    void walk(Map<String, dynamic> node, String prefix) {
      node.forEach((k, v) {
        if (v is Map<String, dynamic>) {
          walk(v, '$prefix$k.');
        } else {
          out.add('$prefix$k');
        }
      });
    }

    walk(
      jsonDecode(File('assets/translations/$lang.json').readAsStringSync())
          as Map<String, dynamic>,
      '',
    );
    return out;
  }

  test('every tr() key exists in zh and en', () {
    final zh = keys('zh'), en = keys('en');
    expect(zh.difference(en), isEmpty, reason: 'keys only in zh');
    expect(en.difference(zh), isEmpty, reason: 'keys only in en');

    // ponytail: literal keys only. A key built at runtime is not seen here.
    final call = RegExp(r'''tr\(\s*['"]([a-z0-9_.]+)['"]''');
    final missing = <String>{};
    for (final f in Directory('lib').listSync(recursive: true)) {
      if (f is! File || !f.path.endsWith('.dart')) continue;
      for (final m in call.allMatches(f.readAsStringSync())) {
        if (!zh.contains(m.group(1))) missing.add('${m.group(1)} (${f.path})');
      }
    }
    expect(missing, isEmpty);
  });
}
