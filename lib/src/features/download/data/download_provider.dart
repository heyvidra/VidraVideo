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

/// The previous list again when [next] holds the very same task objects.
///
/// The manager re-emits every task four times a second while anything is
/// downloading, but it only replaces the task that moved. Handing back a
/// fresh list each time made every tab — including 已完成, where nothing
/// changes — rebuild on every tick.
List<DownloadTask> _sameAsBefore(
  List<DownloadTask>? before,
  List<DownloadTask> next,
) {
  if (before == null || before.length != next.length) return next;
  for (var i = 0; i < next.length; i++) {
    if (!identical(before[i], next[i])) return next;
  }
  return before;
}

List<DownloadTask>? _lastActive;
List<DownloadTask>? _lastCompleted;

/// Active downloads (downloading, queued, paused)
final activeDownloadsProvider = Provider<List<DownloadTask>>((ref) {
  final tasksAsync = ref.watch(downloadTasksProvider);
  return _lastActive = _sameAsBefore(
    _lastActive,
    tasksAsync.maybeWhen(
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
    ),
  );
});

/// Completed downloads
final completedDownloadsProvider = Provider<List<DownloadTask>>((ref) {
  final tasksAsync = ref.watch(downloadTasksProvider);
  return _lastCompleted = _sameAsBefore(
    _lastCompleted,
    tasksAsync.maybeWhen(
      data: (tasks) =>
          tasks.where((t) => t.status == DownloadStatus.completed).toList(),
      orElse: () => [],
    ),
  );
});

/// Active download count
final activeDownloadCountProvider = Provider<int>((ref) {
  final activeTasks = ref.watch(activeDownloadsProvider);
  return activeTasks.length;
});
