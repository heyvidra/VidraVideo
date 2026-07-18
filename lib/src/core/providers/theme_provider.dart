import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database/app_database_provider.dart';
import '../../features/settings/data/settings_repository.dart';

// Provider for initial value (overridden in main.dart)
final initialThemeModeProvider = Provider<ThemeMode>((ref) => ThemeMode.dark);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    final db = ref.watch(appDatabaseProvider);
    final initial = ref.watch(initialThemeModeProvider);
    final settingsRepo = SettingsRepository(db);

    final subscription = settingsRepo.watchSettings().listen((settings) {
      final newMode = settings.themeMode;
      if (state != newMode) {
        state = newMode;
      }
    });
    ref.onDispose(() => subscription.cancel());

    return initial;
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final db = ref.read(appDatabaseProvider);
    final settingsRepo = SettingsRepository(db);

    final settings = await settingsRepo.getSettings();
    settings.themeMode = mode;
    await settingsRepo.updateSettings(settings);
    state = mode;
  }

  Future<void> toggleTheme() async {
    final current = state;
    final next = current == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await setThemeMode(next);
  }
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);
