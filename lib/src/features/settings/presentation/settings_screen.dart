import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import '../data/backup_service.dart';
import '../data/settings_repository.dart';
import '../../../config/reduce_effects.dart';
import '../../favorites/presentation/favorites_provider.dart';
import '../../subscription/presentation/subscription_provider.dart';
import '../../video/presentation/play_history_provider.dart';
import 'settings_provider.dart';
import '../../../common/screen_chrome.dart';
import '../../../window/pet_window.dart';
import '../domain/app_settings.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(settingsProvider);
    final settingsRepo = ref.watch(settingsRepositoryProvider);
    final recommendedMax = ref.watch(recommendedMaxDownloadsProvider);
    final cacheSizeAsync = ref.watch(cacheSizeProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: settingsAsync.when(
        data: (settings) => SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(0, 0, 0, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ScreenHeader(title: tr('settings.title')),
              _section(
                context,
                title: tr('settings.download.title'),
                children: [
                  _buildDownloadPathSetting(context, settings, settingsRepo),
                  const SizedBox(height: 16),
                  _buildConcurrentDownloadsSetting(
                    context,
                    settings,
                    settingsRepo,
                    recommendedMax,
                  ),
                  _buildSegmentConcurrencySetting(
                    context,
                    settings,
                    settingsRepo,
                  ),
                  _buildCookieFileSetting(context, settings, settingsRepo),
                ],
              ),
              const SizedBox(height: 26),
              _section(
                context,
                title: tr('settings.storage.title'),
                children: [
                  _buildCacheSetting(context, cacheSizeAsync, settingsRepo),
                ],
              ),
              const SizedBox(height: 26),
              _section(
                context,
                title: tr('settings.performance.title'),
                children: [
                  _buildReduceEffectsSetting(context, settings, settingsRepo),
                ],
              ),
              // macOS only: elsewhere the pet renders opaque and Linux
              // cannot even close it by name — offer it where it works.
              if (Platform.isMacOS) ...[
                const SizedBox(height: 26),
                _section(
                  context,
                  title: tr('settings.pet.title'),
                  children: [_buildPetSetting(context, settings, settingsRepo)],
                ),
              ],
              const SizedBox(height: 26),
              _section(
                context,
                title: tr('settings.backup.title'),
                children: [
                  _buildExportSetting(context),
                  _buildImportSetting(context),
                ],
              ),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) =>
            Center(child: Text('${tr("common.error")}: $error')),
      ),
    );
  }

  void _snack(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..removeCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _buildExportSetting(BuildContext context) {
    return ListTile(
      title: Text(tr('settings.backup.export')),
      subtitle: Text(
        tr('settings.backup.export_desc'),
        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
      trailing: TextButton(
        onPressed: () async {
          try {
            final json = await ref.read(backupServiceProvider).exportJson();
            final now = DateTime.now();
            final stamp =
                '${now.year}-${now.month.toString().padLeft(2, '0')}-'
                '${now.day.toString().padLeft(2, '0')}';
            // v12 file_picker writes the bytes itself; null means cancelled.
            final path = await FilePicker.saveFile(
              fileName: 'vidra-backup-$stamp.json',
              bytes: utf8.encode(json),
            );
            if (path != null && context.mounted) {
              _snack(context, tr('settings.backup.export_done', args: [path]));
            }
          } catch (e) {
            if (context.mounted) {
              _snack(context, '${tr("common.error")}: $e');
            }
          }
        },
        child: Text(tr('settings.backup.export_action')),
      ),
    );
  }

  Widget _buildImportSetting(BuildContext context) {
    return ListTile(
      title: Text(tr('settings.backup.import')),
      subtitle: Text(
        // Merge semantics, stated up front: nothing existing is touched.
        tr('settings.backup.import_desc'),
        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
      trailing: TextButton(
        onPressed: () async {
          final result = await FilePicker.pickFiles(type: FileType.any);
          final picked = result?.files.single.path;
          if (picked == null) return;
          try {
            final raw = await File(picked).readAsString();
            final summary = await ref
                .read(backupServiceProvider)
                .importJson(raw);
            // Everything the backup feeds reloads from the database it
            // just grew.
            ref.invalidate(playHistoryProvider);
            ref.invalidate(subscriptionsProvider);
            ref.invalidate(favoritesProvider);
            if (context.mounted) {
              _snack(
                context,
                tr(
                  'settings.backup.import_done',
                  args: [
                    '${summary.added}',
                    '${summary.total - summary.added}',
                  ],
                ),
              );
            }
          } catch (e) {
            if (context.mounted) {
              _snack(context, '${tr("common.error")}: $e');
            }
          }
        },
        child: Text(tr('settings.backup.import_action')),
      ),
    );
  }

  /// A settings group. The card and its eyebrow come from [ScreenSection], so
  /// this shape matches every other grouped list in the app.
  Widget _section(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: kContentGutter),
      child: ScreenSection(title: title, children: children),
    );
  }

  /// 减少特效, three states: an explicit choice must be able to beat the
  /// hardware default in both directions, so this is not a boolean switch.
  Widget _buildReduceEffectsSetting(
    BuildContext context,
    AppSettings settings,
    settingsRepo,
  ) {
    final mode = ReduceEffectsMode.fromStored(settings.reduceEffects);
    return ListTile(
      title: Text(tr('settings.performance.reduce_effects')),
      subtitle: Text(
        // Name what auto resolves to on THIS machine, or the default state
        // reads as a mystery ("自动 — 然后呢?").
        tr(
          ReduceEffects.lowPowerGpu
              ? 'settings.performance.reduce_effects_desc_auto_on'
              : 'settings.performance.reduce_effects_desc_auto_off',
        ),
        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
      trailing: SegmentedButton<ReduceEffectsMode>(
        showSelectedIcon: false,
        segments: [
          ButtonSegment(
            value: ReduceEffectsMode.auto,
            label: Text(tr('settings.performance.mode_auto')),
          ),
          ButtonSegment(
            value: ReduceEffectsMode.on,
            label: Text(tr('settings.performance.mode_on')),
          ),
          ButtonSegment(
            value: ReduceEffectsMode.off,
            label: Text(tr('settings.performance.mode_off')),
          ),
        ],
        selected: {mode},
        onSelectionChanged: (selection) async {
          settings.reduceEffects = selection.first.stored;
          await settingsRepo.updateSettings(settings);
          // Widgets follow the settings stream on their own; the seeded
          // mirror and the native window effect need an explicit push.
          ReduceEffects.seed(settings);
          if (Platform.isMacOS) {
            appWindow.backgroundEffect = ReduceEffects.current
                ? WindowEffect.disabled
                : WindowEffect.acrylic;
          }
        },
      ),
    );
  }

  Widget _buildPetSetting(
    BuildContext context,
    AppSettings settings,
    settingsRepo,
  ) {
    return ListTile(
      title: Text(tr('settings.pet.show')),
      subtitle: Text(
        tr('settings.pet.show_desc'),
        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextButton(
            // push, not go: the demo needs a way back to settings, and the
            // titlebar's back affordance keys off the route stack.
            onPressed: () => context.push('/pet-demo'),
            child: Text(tr('settings.pet.preview')),
          ),
          Switch(
            value: settings.showPet,
            onChanged: (value) async {
              settings.showPet = value;
              await settingsRepo.updateSettings(settings);
              // The setting mirrors the screen: closing the pet any other
              // way (its right-click menu) flips this back off through the
              // windowClosed broadcast the dashboard listens for.
              if (value) {
                await PetWindowLauncher.show();
              } else {
                await PetWindowLauncher.dismiss();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadPathSetting(
    BuildContext context,
    AppSettings settings,
    settingsRepo,
  ) {
    final theme = Theme.of(context);
    return ListTile(
      title: Text(tr('settings.download.location')),
      subtitle: FutureBuilder<String>(
        future: settingsRepo.getEffectiveDownloadPath(),
        builder: (context, snapshot) {
          final path = snapshot.data ?? tr('common.loading');
          return Text(
            path,
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          );
        },
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.folder_open),
            tooltip: tr('settings.action.open_folder'),
            onPressed: () async {
              try {
                final path = await settingsRepo.getEffectiveDownloadPath();
                final uri = Uri.file(path);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri);
                } else {
                  throw Exception('Cannot open folder');
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${tr("video.detail.error")}: $e')),
                  );
                }
              }
            },
          ),
          TextButton(
            onPressed: () async {
              final result = await FilePicker.getDirectoryPath();
              if (result != null) {
                // Mutate + save the full object; rebuilding an AppSettings from
                // scratch here used to drop theme/locale/window-size fields.
                settings.downloadPath = result;
                await settingsRepo.updateSettings(settings);
              }
            },
            child: Text(tr('settings.action.change')),
          ),
        ],
      ),
    );
  }

  Widget _buildCookieFileSetting(
    BuildContext context,
    AppSettings settings,
    settingsRepo,
  ) {
    final theme = Theme.of(context);
    final path = settings.cookieFile;
    final has = path != null && path.isNotEmpty;
    return ListTile(
      isThreeLine: true,
      title: Text(tr('settings.download.cookie.title')),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            has ? path : tr('settings.download.cookie.none'),
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            tr('settings.download.cookie.desc'),
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onSurfaceVariant.withAlpha(160),
            ),
          ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (has)
            IconButton(
              icon: const Icon(Icons.clear),
              tooltip: tr('settings.download.cookie.clear'),
              onPressed: () async {
                settings.cookieFile = null;
                await settingsRepo.updateSettings(settings);
              },
            ),
          TextButton(
            onPressed: () async {
              final result = await FilePicker.pickFiles(type: FileType.any);
              final picked = result?.files.single.path;
              if (picked != null) {
                settings.cookieFile = picked;
                await settingsRepo.updateSettings(settings);
              }
            },
            child: Text(tr('settings.action.change')),
          ),
        ],
      ),
    );
  }

  Widget _buildConcurrentDownloadsSetting(
    BuildContext context,
    AppSettings settings,
    settingsRepo,
    int recommendedMax,
  ) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(tr('settings.download.concurrent')),
              Text(
                '${settings.maxConcurrentDownloads}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            tr(
              'settings.download.recommended',
              args: [recommendedMax.toString()],
            ),
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Slider(
            value: settings.maxConcurrentDownloads.toDouble(),
            min: 1,
            max: 10,
            divisions: 9,
            activeColor: theme.colorScheme.primary,
            onChanged: (value) async {
              settings.maxConcurrentDownloads = value.toInt();
              await settingsRepo.updateSettings(settings);
            },
          ),
        ],
      ),
    );
  }

  /// Parallel HLS segment fetches within ONE download (vidraDlp). Distinct from
  /// [_buildConcurrentDownloadsSetting], which is how many episodes download at
  /// once. Higher = faster on good networks; lower is gentler on the CDN.
  Widget _buildSegmentConcurrencySetting(
    BuildContext context,
    AppSettings settings,
    settingsRepo,
  ) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(tr('settings.download.segment_concurrent')),
              Text(
                '${settings.segmentConcurrency}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            tr('settings.download.segment_concurrent_desc'),
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Slider(
            value: settings.segmentConcurrency.toDouble(),
            min: 1,
            max: 16,
            divisions: 15,
            activeColor: theme.colorScheme.primary,
            onChanged: (value) async {
              settings.segmentConcurrency = value.toInt();
              await settingsRepo.updateSettings(settings);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCacheSetting(
    BuildContext context,
    AsyncValue<int> cacheSizeAsync,
    SettingsRepository settingsRepo,
  ) {
    final theme = Theme.of(context);
    return ListTile(
      title: Text(tr('settings.storage.cache')),
      subtitle: cacheSizeAsync.when(
        data: (size) {
          final sizeInMB = (size / (1024 * 1024)).toStringAsFixed(2);
          return Text(
            '$sizeInMB MB',
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
          );
        },
        loading: () => Text(tr('settings.status.calculating')),
        error: (error, stackTrace) =>
            Text('${tr("common.error")} calculating size'),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.folder_open),
            tooltip: tr('settings.action.open_folder'),
            onPressed: () async {
              try {
                final cacheDir = await getApplicationCacheDirectory();
                final uri = Uri.file(cacheDir.path);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri);
                } else {
                  throw Exception('Cannot open folder');
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to open folder: $e')),
                  );
                }
              }
            },
          ),
          TextButton(
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(tr('settings.storage.clear_cache')),
                  content: Text(tr('settings.storage.clear_confirm')),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(tr('common.cancel')),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: Text(tr('settings.action.clear')),
                    ),
                  ],
                ),
              );

              if (confirmed == true) {
                await settingsRepo.clearCache();
                ref.invalidate(cacheSizeProvider);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(tr('settings.status.cleared'))),
                  );
                }
              }
            },
            child: Text(tr('settings.action.clear')),
          ),
        ],
      ),
    );
  }
}
