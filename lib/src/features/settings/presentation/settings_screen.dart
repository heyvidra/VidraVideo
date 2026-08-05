import 'package:file_picker/file_picker.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
import '../data/settings_repository.dart';
import 'settings_provider.dart';
import '../../../common/screen_chrome.dart';
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
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) =>
            Center(child: Text('${tr("common.error")}: $error')),
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
