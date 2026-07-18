import 'dart:io';
import 'package:drift/drift.dart';
import 'package:path_provider/path_provider.dart';
import '../../../data/database/app_database.dart' hide AppSettings;
import '../../../data/database/mappers.dart';
import '../domain/app_settings.dart';

class SettingsRepository {
  final AppDatabase _db;

  SettingsRepository(this._db);

  Future<void> _cleanupDuplicateSettings() async {
    await _db.customStatement('DELETE FROM app_settings WHERE id != ?', [
      AppSettings.singletonId,
    ]);
  }

  /// Get current settings (creates default if not exists)
  Future<AppSettings> getSettings() async {
    final singleton = await (_db.select(
      _db.appSettings,
    )..where((t) => t.id.equals(AppSettings.singletonId))).getSingleOrNull();
    if (singleton != null) {
      await _cleanupDuplicateSettings();
      return singleton.toDomain();
    }

    final existing =
        await (_db.select(_db.appSettings)
              ..orderBy([
                (t) => OrderingTerm(expression: t.id, mode: OrderingMode.asc),
              ])
              ..limit(1))
            .getSingleOrNull();

    final settings = existing?.toDomain() ?? AppSettings();
    settings.id = AppSettings.singletonId;
    await updateSettings(settings);

    if (existing != null && existing.id != AppSettings.singletonId) {
      await (_db.delete(
        _db.appSettings,
      )..where((t) => t.id.equals(existing.id))).go();
    }

    return settings;
  }

  Stream<AppSettings> watchSettings() {
    return (_db.select(_db.appSettings)
          ..where((t) => t.id.equals(AppSettings.singletonId)))
        .watchSingleOrNull()
        .asyncMap((row) async {
          if (row != null) {
            await _cleanupDuplicateSettings();
            return row.toDomain();
          }

          return getSettings();
        });
  }

  /// Update settings
  Future<void> updateSettings(AppSettings settings) async {
    settings.id = AppSettings.singletonId;
    final id = await _db
        .into(_db.appSettings)
        .insert(settings.toCompanion(), mode: InsertMode.insertOrReplace);
    settings.id = id;
    await _cleanupDuplicateSettings();
  }

  /// Update locale
  Future<void> updateLocale(String locale) async {
    final settings = await getSettings();
    settings.locale = locale;
    await updateSettings(settings);
  }

  /// Get default download path
  Future<String> getDefaultDownloadPath() async {
    final downloadsDir = await getDownloadsDirectory();
    return downloadsDir?.path ??
        (await getApplicationDocumentsDirectory()).path;
  }

  /// Get effective download path (custom or default)
  Future<String> getEffectiveDownloadPath() async {
    final settings = await getSettings();
    if (settings.downloadPath != null && settings.downloadPath!.isNotEmpty) {
      return settings.downloadPath!;
    }
    return getDefaultDownloadPath();
  }

  /// Calculate cache size in bytes
  Future<int> calculateCacheSize() async {
    try {
      final tempDir = await getApplicationCacheDirectory();
      return await _calculateDirectorySize(tempDir);
    } catch (e) {
      return 0;
    }
  }

  Future<int> _calculateDirectorySize(Directory dir) async {
    int totalSize = 0;
    try {
      if (await dir.exists()) {
        await for (var entity in dir.list(
          recursive: true,
          followLinks: false,
        )) {
          if (entity is File) {
            totalSize += await entity.length();
          }
        }
      }
    } catch (e) {
      // Ignore errors
    }
    return totalSize;
  }

  /// Clear cache directory
  Future<void> clearCache() async {
    try {
      final tempDir = await getApplicationCacheDirectory();
      if (await tempDir.exists()) {
        await for (var entity in tempDir.list()) {
          await entity.delete(recursive: true);
        }
      }
    } catch (e) {
      // Ignore errors
    }
  }

  /// Recommended concurrent EPISODE downloads. Deliberately low and NOT
  /// CPU-based: downloading is network/CDN-bound, and each episode already
  /// fans out to ~6 parallel segment fetches. So N episodes = N×6 connections
  /// to one host; past a handful the CDN throttles per-IP and aggregate
  /// throughput DROPS (10 episodes measured slower than 3). CPU only matters
  /// for the brief remux at each episode's end.
  int getRecommendedMaxDownloads() => 3;
}
