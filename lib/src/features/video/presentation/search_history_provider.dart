import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/database/app_database.dart' as db;
import '../../../data/database/app_database_provider.dart';

/// [history] with [keyword] moved (or added) to the front, capped at [cap].
///
/// Pure so the one rule — newest first, no duplicates, bounded — is testable
/// without a database.
List<String> pushKeyword(List<String> history, String keyword, {int cap = 10}) {
  final kw = keyword.trim();
  if (kw.isEmpty) return history;
  return [kw, ...history.where((e) => e != kw)].take(cap).toList();
}

final searchHistoryProvider =
    AsyncNotifierProvider<SearchHistoryNotifier, List<String>>(
      SearchHistoryNotifier.new,
    );

/// The last few searches, newest first, surviving restarts on the settings
/// row. Desktop users search the same handful of followed shows every day;
/// this is the difference between one click and retyping the title.
class SearchHistoryNotifier extends AsyncNotifier<List<String>> {
  db.AppDatabase get _db => ref.read(appDatabaseProvider);

  @override
  Future<List<String>> build() async {
    final row = await _db.select(_db.appSettings).getSingleOrNull();
    final raw = row?.searchHistory;
    if (raw == null || raw.isEmpty) return const [];
    // Tolerant: an unreadable history costs the dropdown, not the search.
    try {
      return [for (final e in jsonDecode(raw) as List) '$e'];
    } catch (_) {
      return const [];
    }
  }

  Future<void> push(String keyword) async {
    final next = pushKeyword(state.value ?? const [], keyword);
    state = AsyncData(next);
    await _write(next);
  }

  Future<void> clear() async {
    state = const AsyncData([]);
    await _write(const []);
  }

  Future<void> _write(List<String> history) async {
    final encoded = jsonEncode(history);
    final updated = await _db
        .update(_db.appSettings)
        .write(db.AppSettingsCompanion(searchHistory: Value(encoded)));
    if (updated == 0) {
      // A fresh install where nothing has written settings yet.
      await _db
          .into(_db.appSettings)
          .insert(db.AppSettingsCompanion(searchHistory: Value(encoded)));
    }
  }
}
