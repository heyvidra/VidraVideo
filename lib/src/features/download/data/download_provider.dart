import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../data/database/app_database_provider.dart';
import '../../settings/presentation/settings_provider.dart';
import '../domain/download_task.dart';
import 'download_manager.dart';

/// Download manager provider — single source of truth, DI via Riverpod.
final downloadManagerProvider = Provider<DownloadManager>((ref) {
  final manager = DownloadManager(
    ref.watch(appDatabaseProvider),
    ref.watch(settingsRepositoryProvider),
  );
  ref.onDispose(manager.dispose);
  return manager;
});

/// All download tasks stream
final downloadTasksProvider = StreamProvider<List<DownloadTask>>((ref) {
  final manager = ref.watch(downloadManagerProvider);
  return manager.tasksStream;
});

/// Active downloads (downloading, queued, paused)
final activeDownloadsProvider = Provider<List<DownloadTask>>((ref) {
  final tasksAsync = ref.watch(downloadTasksProvider);
  return tasksAsync.maybeWhen(
    data: (tasks) => tasks
        .where(
          (t) =>
              t.status == DownloadStatus.downloading ||
              t.status == DownloadStatus.queued ||
              t.status == DownloadStatus.paused ||
              t.status == DownloadStatus.cancelled ||
              t.status == DownloadStatus.failed,
        )
        .toList(),
    orElse: () => [],
  );
});

/// Completed downloads
final completedDownloadsProvider = Provider<List<DownloadTask>>((ref) {
  final tasksAsync = ref.watch(downloadTasksProvider);
  return tasksAsync.maybeWhen(
    data: (tasks) =>
        tasks.where((t) => t.status == DownloadStatus.completed).toList(),
    orElse: () => [],
  );
});

/// Active download count
final activeDownloadCountProvider = Provider<int>((ref) {
  final activeTasks = ref.watch(activeDownloadsProvider);
  return activeTasks.length;
});
