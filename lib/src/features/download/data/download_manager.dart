import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart' show DioException;
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../../../core/services/m3u8_downloader.dart'
    show DownloadCancelledException;
import '../../../core/telemetry/telemetry.dart';
import '../../../core/utils/log.dart';
import '../../../data/database/app_database.dart' as db;
import '../../../data/database/mappers.dart';
import '../domain/download_task.dart';
import '../../../core/services/download_service.dart';
import '../../settings/data/settings_repository.dart';

/// Download manager - handles task queue and execution.
/// Created via [downloadManagerProvider]; no longer a global singleton.
class DownloadManager {
  DownloadManager(
    this._db,
    this._settingsRepo, {
    DownloadService? downloadService,
    Duration retryDelay = const Duration(seconds: 2),
  }) : _downloadService = downloadService ?? DownloadService(_settingsRepo),
       _retryDelay = retryDelay;

  /// Auto-retry a failing episode this many times (with linear backoff) before
  /// giving up and marking it failed. Transient CDN throttling under high
  /// concurrency is common, so a couple of quiet retries avoid needless failures.
  static const _maxAttempts = 3;
  final Duration _retryDelay;
  StreamSubscription? _settingsSub;
  StreamSubscription? _dbSub;

  final DownloadService _downloadService;
  final db.AppDatabase _db;
  final SettingsRepository _settingsRepo;
  final _tasks = <String, DownloadTask>{};
  final _taskController = StreamController<List<DownloadTask>>.broadcast();
  final _uuid = const Uuid();

  // Max concurrent EPISODE downloads, global across all tasks. Was task-level,
  // but a single multi-episode task then downloaded its episodes serially and
  // ignored the setting — so "download 10 at once" only ever ran one. Now it's
  // a global slot pool: any queued episode from any task fills a free slot.
  int _maxConcurrent = 3;
  final Set<String> _activeEpisodes = {}; // keys: "taskId#index"
  bool _isProcessing = false;

  /// Emits the current tasks immediately, then follows every update.
  /// No per-access StreamController — the old getter leaked one controller +
  /// subscription on every read (e.g. once per widget rebuild).
  Stream<List<DownloadTask>> get tasksStream async* {
    yield allTasks;
    yield* _taskController.stream;
  }

  List<DownloadTask> get allTasks => _tasks.values.toList();

  bool _isInitialized = false;

  /// Initialize manager and load persisted tasks.
  ///
  /// [watchDb] controls the standing drift watch that mirrors row changes
  /// into [_tasks]. Drift's stream invalidation is per database connection,
  /// and every engine opens its own background isolate — so in a secondary
  /// engine that watch could never see the main engine's writes and only ever
  /// delivered its initial snapshot, which [_loadTasks] already provides.
  /// Secondary engines pass false and live off the one-shot snapshot; the
  /// default keeps the watch for single-engine callers and tests.
  Future<void> initialize({
    bool startProcessing = false,
    bool watchDb = true,
  }) async {
    if (_isInitialized) {
      if (startProcessing && !_isProcessing) {
        _startProcessing();
      }
      return;
    }
    _isInitialized = true;

    await _refreshConcurrency();
    await _loadTasks();

    if (startProcessing) {
      // Before anything starts downloading, and ONLY in the engine that owns
      // downloading. Three engines run at once — dashboard, player, pet — and
      // each calls initialize(); a sweep in the other two would be scanning a
      // folder they have no idea about the state of. `startProcessing` is
      // already the flag main.dart uses to mean "this is the main window".
      //
      // Not awaited: it is a disk scan, and nothing about starting the queue
      // depends on its result. A failure inside is swallowed and logged.
      unawaited(_downloadService.sweepOrphanedResumeFiles());
      _startProcessing();
    } else if (watchDb) {
      _listenToDbChanges();
    }
  }

  void _listenToDbChanges() {
    logD('DownloadManager', 'Starting to listen for DB changes');
    _dbSub = _db.select(_db.downloadTasks).watch().listen((rows) {
      if (!_isProcessing) {
        logD(
          'DownloadManager',
          'DB update received, sync ${rows.length} tasks',
        );
        _tasks.clear();
        for (final r in rows) {
          final domainTask = r.toDomain();
          _tasks[domainTask.taskId] = domainTask;
        }
        _notifyUpdate();
      }
    });
  }

  /// Add a new download task
  Future<String> addTask({
    required int videoId,
    required String videoTitle,
    String? coverUrl,
    required List<Map<String, dynamic>> episodes,
  }) async {
    await _refreshConcurrency();

    // Check if a task for this video already exists
    String? existingTaskId;
    for (final entry in _tasks.entries) {
      if (entry.value.videoId == videoId) {
        existingTaskId = entry.key;
        break;
      }
    }

    if (existingTaskId != null) {
      final existingTask = _tasks[existingTaskId]!;
      final existingUrls = existingTask.episodes.map((e) => e.url).toSet();

      final newEpisodeInfos = episodes
          .where((ep) => !existingUrls.contains(ep['url']))
          .map(
            (ep) => EpisodeDownloadInfo(
              index: ep['index'] as int,
              title: ep['title'] as String,
              url: ep['url'] as String,
              formatId: ep['formatId'] as String?,
            ),
          )
          .toList();

      if (newEpisodeInfos.isNotEmpty) {
        final updatedEpisodes = [...existingTask.episodes, ...newEpisodeInfos];
        _tasks[existingTaskId] = existingTask.copyWith(
          episodes: updatedEpisodes,
          completedAt:
              null, // Reset completed date since new episodes are added
        );
        _notifyUpdate();
        await _saveTask(_tasks[existingTaskId]!);
        _pumpQueue();
      }
      return existingTaskId;
    }

    // Create new task if none exists
    final taskId = _uuid.v4();
    final episodeInfos = episodes.map((ep) {
      return EpisodeDownloadInfo(
        index: ep['index'] as int,
        title: ep['title'] as String,
        url: ep['url'] as String,
        formatId: ep['formatId'] as String?,
      );
    }).toList();

    final task = DownloadTask(
      taskId: taskId,
      videoId: videoId,
      videoTitle: videoTitle,
      coverUrl: coverUrl,
      episodes: episodeInfos,
      createdAt: DateTime.now(),
    );

    _tasks[taskId] = task;
    _notifyUpdate();
    await _saveTask(task);
    _pumpQueue();

    return taskId;
  }

  /// Pause a task
  Future<void> pauseTask(String taskId) async {
    final task = _tasks[taskId];
    if (task == null) return;

    // Pause BOTH downloading and queued episodes. Under the global pool a
    // still-queued episode would be picked up again the instant we pump, so a
    // pause that left them queued wouldn't actually pause the task.
    final updatedEpisodes = task.episodes.map((ep) {
      if (ep.status == DownloadStatus.downloading ||
          ep.status == DownloadStatus.queued) {
        return ep.copyWith(status: DownloadStatus.paused);
      }
      return ep;
    }).toList();

    _tasks[taskId] = task.copyWith(episodes: updatedEpisodes);
    _notifyUpdate();
    await _saveTask(_tasks[taskId]!);
    _pumpQueue(); // A freed slot can now go to another task.
  }

  /// Resume a task
  Future<void> resumeTask(String taskId) async {
    final task = _tasks[taskId];
    if (task == null) return;

    await _refreshConcurrency();

    // Resume re-queues paused, failed AND cancelled episodes — "resume" doubles
    // as "retry" and gives a cancelled task a forward path. Failed/cancelled
    // restart from scratch (downloads aren't resumable), so clear stale progress.
    final updatedEpisodes = task.episodes.map((ep) {
      if (ep.status == DownloadStatus.paused) {
        return ep.copyWith(status: DownloadStatus.queued);
      }
      if (ep.status == DownloadStatus.failed ||
          ep.status == DownloadStatus.cancelled) {
        return ep.copyWith(
          status: DownloadStatus.queued,
          progress: 0.0,
          bytesDownloaded: 0,
        );
      }
      return ep;
    }).toList();

    _tasks[taskId] = task.copyWith(episodes: updatedEpisodes);
    _notifyUpdate();
    await _saveTask(_tasks[taskId]!);
    _pumpQueue();
  }

  /// Cancel a task
  Future<void> cancelTask(String taskId) async {
    final task = _tasks[taskId];
    if (task == null) return;

    // Keep already-completed episodes completed — their files are on disk and
    // still playable; cancelling them would strip the play/reveal actions.
    final updatedEpisodes = task.episodes.map((ep) {
      return ep.status == DownloadStatus.completed
          ? ep
          : ep.copyWith(status: DownloadStatus.cancelled);
    }).toList();

    _tasks[taskId] = task.copyWith(episodes: updatedEpisodes);
    _notifyUpdate();
    await _saveTask(_tasks[taskId]!);
    _pumpQueue(); // Try to start other tasks
  }

  /// Cancel specific episode
  Future<void> cancelEpisode(String taskId, int episodeIndex) async {
    final task = _tasks[taskId];
    if (task == null || episodeIndex >= task.episodes.length) return;

    final updatedEpisodes = List<EpisodeDownloadInfo>.from(task.episodes);
    final episode = updatedEpisodes[episodeIndex];

    if (episode.status == DownloadStatus.downloading ||
        episode.status == DownloadStatus.queued) {
      updatedEpisodes[episodeIndex] = episode.copyWith(
        status: DownloadStatus.cancelled,
        bytesDownloaded: 0,
        progress: 0.0,
      );
      _tasks[taskId] = task.copyWith(episodes: updatedEpisodes);
      _notifyUpdate();
      await _saveTask(_tasks[taskId]!);
      _pumpQueue(); // Try to start key queued tasks
    }
  }

  /// Retry a single failed/cancelled episode (per-episode retry button).
  Future<void> retryEpisode(String taskId, int episodeIndex) async {
    final task = _tasks[taskId];
    if (task == null || episodeIndex >= task.episodes.length) return;
    final episode = task.episodes[episodeIndex];
    if (episode.status != DownloadStatus.failed &&
        episode.status != DownloadStatus.cancelled) {
      return;
    }
    final updatedEpisodes = List<EpisodeDownloadInfo>.from(task.episodes);
    updatedEpisodes[episodeIndex] = episode.copyWith(
      status: DownloadStatus.queued,
      progress: 0.0,
      bytesDownloaded: 0,
    );
    _tasks[taskId] = task.copyWith(episodes: updatedEpisodes);
    _notifyUpdate();
    await _saveTask(_tasks[taskId]!);
    await _refreshConcurrency();
    _pumpQueue();
  }

  /// Delete specific episode
  Future<void> deleteEpisode(
    String taskId,
    int episodeIndex, {
    bool deleteFile = false,
  }) async {
    final task = _tasks[taskId];
    if (task == null || episodeIndex >= task.episodes.length) return;

    final updatedEpisodes = List<EpisodeDownloadInfo>.from(task.episodes);
    final episode = updatedEpisodes[episodeIndex];

    // Delete file if requested and it exists
    if (deleteFile && episode.outputPath != null) {
      try {
        final f = File(episode.outputPath!);
        if (f.existsSync()) {
          f.deleteSync();
        }
      } catch (e) {
        logD('DownloadManager', 'Error deleting episode file: $e');
      }
    }

    // Remove episode from list
    updatedEpisodes.removeAt(episodeIndex);

    // If no episodes left, delete task entirely
    if (updatedEpisodes.isEmpty) {
      await deleteTask(taskId, deleteFile: deleteFile);
      return;
    }

    _tasks[taskId] = task.copyWith(episodes: updatedEpisodes);
    _notifyUpdate();
    await _saveTask(_tasks[taskId]!);
  }

  /// Delete task (optionally with file)
  Future<void> deleteTask(String taskId, {bool deleteFile = false}) async {
    final task = _tasks[taskId];
    if (task == null) return;

    // Drop from memory + cancel any pending save FIRST, so a throttled or
    // in-flight _saveTask (guarded by _tasks.containsKey) can't re-insert the
    // row right after we delete it.
    _tasks.remove(taskId);
    _saveThrottler.remove(taskId)?.cancel();

    if (deleteFile) {
      for (final episode in task.episodes) {
        try {
          if (episode.outputPath != null) {
            final f = File(episode.outputPath!);
            if (f.existsSync()) {
              f.deleteSync();
            }
          }
        } catch (e) {
          logD('DownloadManager', 'Error deleting task file: $e');
        }
      }
    }

    // Delete by the stable, unique taskId — NOT the autoincrement id, which
    // churns across insertOrReplace saves and can leave the row undeleted
    // (making a "deleted" task reappear after the next app load).
    await (_db.delete(
      _db.downloadTasks,
    )..where((t) => t.taskId.equals(taskId))).go();

    _notifyUpdate();
    _pumpQueue(); // Start next if slot freed
  }

  /// Start processing tasks
  void _startProcessing() {
    if (_isProcessing) return;
    _isProcessing = true;

    // Live-apply concurrency changes: raising the slider mid-batch should open
    // more slots immediately, not wait for the next add/resume. Only the
    // processing (main) window subscribes — secondary windows don't download.
    _settingsSub ??= _settingsRepo.watchSettings().listen((s) {
      if (s.maxConcurrentDownloads != _maxConcurrent) {
        _maxConcurrent = s.maxConcurrentDownloads;
        _pumpQueue();
      }
    });

    _pumpQueue();
  }

  /// Reload max concurrency from settings. Called on user-initiated actions
  /// (add/resume), NOT on every queue tick — the queue pump runs hot.
  Future<void> _refreshConcurrency() async {
    try {
      final settings = await _settingsRepo.getSettings();
      _maxConcurrent = settings.maxConcurrentDownloads;
    } catch (e) {
      // Keep current value if settings unavailable
    }
  }

  // In-flight episodes are keyed by (taskId, episode URL), NOT list index.
  // addTask dedups episodes by URL within a task, so URL is a stable identity
  // that survives deleteEpisode's removeAt() — a running download re-resolves
  // its current index by URL every time, so deleting an earlier episode can no
  // longer strand or cross-wire a sibling that's mid-download.
  String _epKey(String taskId, String url) => '$taskId$url';

  int _indexOfUrl(String taskId, String url) {
    final t = _tasks[taskId];
    if (t == null) return -1;
    return t.episodes.indexWhere((e) => e.url == url);
  }

  /// Global scheduler: fill idle slots with queued episodes drawn from any
  /// task (task insertion order, then episode order) up to [_maxConcurrent].
  /// Each episode downloads independently; freeing a slot re-pumps. This is the
  /// fix for "set 10 concurrent, only 1 downloads": the old model ran one task
  /// at a time and serialized that task's episodes, so a single 20-episode task
  /// never used more than one slot.
  void _pumpQueue() {
    while (_activeEpisodes.length < _maxConcurrent) {
      final next = _nextQueuedEpisode();
      if (next == null) return; // Nothing left to start right now.

      final (taskId, url) = next;
      _activeEpisodes.add(_epKey(taskId, url));

      // Mark downloading synchronously so the next loop iteration (and any
      // re-entrant pump) won't pick this episode again.
      final index = _indexOfUrl(taskId, url);
      final ep = _episodeAt(taskId, index);
      if (ep != null) {
        _updateEpisode(
          taskId,
          index,
          ep.copyWith(
            status: DownloadStatus.downloading,
            startTime: DateTime.now(),
          ),
        );
      }

      _downloadEpisode(taskId, url).whenComplete(() {
        _activeEpisodes.remove(_epKey(taskId, url));
        _maybeCompleteTask(taskId);
        _pumpQueue(); // A slot freed — start the next queued episode.
      });
    }
  }

  /// Next queued episode across all tasks (task order, then episode order),
  /// skipping any already in flight. Paused/cancelled tasks have no queued
  /// episodes (pause/cancel transition them), so they're skipped naturally.
  (String, String)? _nextQueuedEpisode() {
    for (final task in _tasks.values) {
      for (final ep in task.episodes) {
        final url = ep.url;
        // ponytail: a null-URL episode can't be downloaded or keyed; it's
        // unreachable via addTask (URL is required) so we just skip it.
        if (url != null &&
            ep.status == DownloadStatus.queued &&
            !_activeEpisodes.contains(_epKey(task.taskId, url))) {
          return (task.taskId, url);
        }
      }
    }
    return null;
  }

  /// Download a single episode (identified by URL). The scheduler already set
  /// it to downloading; this owns progress, auto-retry, and the terminal
  /// outcome (completed / cancelled / paused / failed). The current list index
  /// is re-resolved from the URL on every write so a concurrent deleteEpisode
  /// can't misdirect it.
  Future<void> _downloadEpisode(String taskId, String url) async {
    final startIndex = _indexOfUrl(taskId, url);
    if (startIndex == -1) return;
    final task = _tasks[taskId]!;

    final filename = '${task.videoTitle}_${task.episodes[startIndex].title}'
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
    // Format selector is fixed at add time (null → legacy 'direct' for HLS).
    final formatId = task.episodes[startIndex].formatId;

    for (int attempt = 1; attempt <= _maxAttempts; attempt++) {
      try {
        final outputPath = await _downloadService.downloadM3u8ToMp4(
          url: url,
          filename: filename,
          formatId: formatId,
          shouldCancel: () => _isEpisodeAborted(taskId, url),
          onProgress: (progress, bytesDownloaded, totalBytes, status) {
            final i = _indexOfUrl(taskId, url);
            final ep = _episodeAt(taskId, i);
            // Drop progress ticks that race a status change.
            if (ep == null || ep.status != DownloadStatus.downloading) return;
            _updateEpisode(
              taskId,
              i,
              ep.copyWith(
                progress: progress,
                bytesDownloaded: bytesDownloaded,
                totalBytes: totalBytes ?? ep.totalBytes,
              ),
            );
          },
        );

        final i = _indexOfUrl(taskId, url);
        final ep = _episodeAt(taskId, i);
        if (ep != null &&
            ep.status == DownloadStatus.downloading &&
            outputPath != null) {
          _updateEpisode(
            taskId,
            i,
            ep.copyWith(
              status: DownloadStatus.completed,
              progress: 1.0,
              outputPath: outputPath,
              completedTime: DateTime.now(),
            ),
          );
        }
        return; // Success (or already transitioned) — done.
      } on DownloadCancelledException {
        // pause/cancel/delete already set the episode's status before the abort
        // propagated. Never retry a user-initiated stop.
        final i = _indexOfUrl(taskId, url);
        final t = _tasks[taskId];
        final ep = _episodeAt(taskId, i);
        if (t != null &&
            ep != null &&
            ep.status == DownloadStatus.downloading &&
            t.status == DownloadStatus.paused) {
          _updateEpisode(taskId, i, ep.copyWith(status: DownloadStatus.paused));
        }
        return;
      } catch (e) {
        // User paused/cancelled/deleted mid-attempt? Respect it — don't retry.
        if (_isEpisodeAborted(taskId, url)) return;

        // A retry RESUMES from the on-disk checkpoint (vidraDlp HLS resume), so
        // it's cheap regardless of how far the download got — always retry up to
        // the cap. (No more "don't restart a near-complete download" gate: there
        // is no restart, the SDK continues from where it stopped.)
        if (attempt < _maxAttempts) {
          logD(
            'DownloadManager',
            'episode failed (attempt $attempt/$_maxAttempts), '
                'retrying (resumes from checkpoint): $e',
          );
          await Future.delayed(_retryDelay * attempt); // linear backoff
          if (_isEpisodeAborted(taskId, url)) return; // aborted during backoff
          continue;
        }

        logD(
          'DownloadManager',
          'episode failed after $_maxAttempts attempts: $e',
        );
        // Terminal only: an attempt that retried and then succeeded is not
        // news, and an abort is the user's own doing and returned above. The
        // error's TYPE, never the error — its message carries the stream URL
        // it died on.
        Telemetry.report(
          'download.failed',
          data: {
            'error': e.runtimeType.toString(),
            'attempts': attempt,
            // Which downloader gave up: the vidraDlp extractor path (a format
            // was selected at add time) or the plain HLS path.
            'extractor': formatId != null,
            if (e is DioException) 'type': e.type.name,
            if (e is DioException) 'status': e.response?.statusCode,
          },
        );
        final i = _indexOfUrl(taskId, url);
        final ep = _episodeAt(taskId, i);
        if (ep != null && ep.status == DownloadStatus.downloading) {
          _updateEpisode(
            taskId,
            i,
            ep.copyWith(status: DownloadStatus.failed, error: e.toString()),
          );
        }
        return;
      }
    }
  }

  /// Stamp completedAt once the task reaches a completed status (all episodes
  /// completed, or a completed/cancelled mix). Guarded so it fires once.
  void _maybeCompleteTask(String taskId) {
    final task = _tasks[taskId];
    if (task == null || task.completedAt != null) return;
    if (task.status == DownloadStatus.completed) {
      _tasks[taskId] = task.copyWith(completedAt: DateTime.now());
      _notifyUpdate();
      _saveTask(_tasks[taskId]!);
    }
  }

  EpisodeDownloadInfo? _episodeAt(String taskId, int i) {
    final t = _tasks[taskId];
    if (t == null || i < 0 || i >= t.episodes.length) return null;
    return t.episodes[i];
  }

  /// True when the downloader should abort the episode with [url] in [taskId]:
  /// the task was deleted/cancelled/paused, or the episode itself was (or was
  /// deleted from the list entirely).
  bool _isEpisodeAborted(String taskId, String url) {
    final t = _tasks[taskId];
    if (t == null) return true;
    if (t.status == DownloadStatus.cancelled ||
        t.status == DownloadStatus.paused) {
      return true;
    }
    final i = t.episodes.indexWhere((e) => e.url == url);
    if (i == -1) return true; // episode was deleted mid-download
    final s = t.episodes[i].status;
    return s == DownloadStatus.cancelled || s == DownloadStatus.paused;
  }

  // Throttling map for save operations
  final _saveThrottler = <String, Timer>{};

  // Pending trailing-edge notification for progress-only updates. One global
  // timer, not per-task: a notification carries allTasks, so one fire serves
  // every task's accumulated progress at once.
  Timer? _notifyThrottle;

  /// Update a specific episode in a task
  void _updateEpisode(
    String taskId,
    int episodeIndex,
    EpisodeDownloadInfo newEpisode,
  ) {
    final task = _tasks[taskId];
    if (task == null) return;

    final updatedEpisodes = List<EpisodeDownloadInfo>.from(task.episodes);
    final oldStatus = updatedEpisodes[episodeIndex].status;
    updatedEpisodes[episodeIndex] = newEpisode;

    _tasks[taskId] = task.copyWith(episodes: updatedEpisodes);

    // A status transition is news the UI must not sit on — an episode
    // finishing, pausing, or failing changes what actions the screen offers —
    // so it notifies and saves immediately. Pure progress ticks arrive many
    // times per second per episode, multiplied by the slot-pool concurrency,
    // and every notification rebuilds every downloads listener; those are
    // throttled the same way their save already is.
    if (oldStatus != newEpisode.status ||
        newEpisode.status == DownloadStatus.completed ||
        newEpisode.status == DownloadStatus.failed) {
      _notifyUpdate();
      _saveTask(_tasks[taskId]!);
    } else {
      _notifyProgressThrottled();
      _throttledSave(taskId);
    }
  }

  /// Notify listeners of task updates
  void _notifyUpdate() {
    // An immediate notification already carries the full current state, so a
    // pending throttled one would only repeat it.
    _notifyThrottle?.cancel();
    _notifyThrottle = null;
    _taskController.add(allTasks);
  }

  /// Trailing-edge throttle for progress-only notifications, capping listeners
  /// at ~4 updates/sec. The timer reads live state when it fires, so the final
  /// progress value of a burst always reaches listeners; status transitions
  /// bypass this entirely via [_notifyUpdate].
  void _notifyProgressThrottled() {
    if (_notifyThrottle != null) return;
    _notifyThrottle = Timer(const Duration(milliseconds: 250), () {
      _notifyThrottle = null;
      _taskController.add(allTasks);
    });
  }

  /// Throttled save for progress updates
  void _throttledSave(String taskId) {
    if (_saveThrottler.containsKey(taskId)) return;

    _saveThrottler[taskId] = Timer(const Duration(seconds: 2), () {
      _saveThrottler.remove(taskId);
      final task = _tasks[taskId];
      if (task != null) {
        _saveTask(task);
      }
    });
  }

  /// Save task to DB
  Future<void> _saveTask(DownloadTask task) async {
    // Check if task is still in memory (not deleted)
    if (!_tasks.containsKey(task.taskId)) return;

    try {
      final id = await _db
          .into(_db.downloadTasks)
          .insert(task.toCompanion(), mode: InsertMode.insertOrReplace);
      task.id = id;
    } catch (e) {
      logD('DownloadManager', 'Error saving task to DB: $e');
    }
  }

  /// Load tasks from DB, consolidating one task per video (same show).
  Future<void> _loadTasks() async {
    try {
      final rows = await _db.select(_db.downloadTasks).get();
      _tasks.clear();

      // One task per videoId. Old data / a past delete bug can leave several
      // rows for the same show (e.g. re-downloading an episode after the task
      // was "deleted" from memory but not the DB). Merge their episodes (dedup
      // by url) into a single task and drop the redundant rows.
      final byVideo = <int, DownloadTask>{};
      final duplicateTaskIds = <String>[];
      for (final row in rows) {
        final loaded = row.toDomain();
        // An episode persisted as `downloading` was in flight when the app last
        // exited — nothing is downloading it now. Re-queue so the pump resumes.
        final revived = loaded.episodes
            .map(
              (e) => e.status == DownloadStatus.downloading
                  ? e.copyWith(status: DownloadStatus.queued)
                  : e,
            )
            .toList();
        final task = loaded.copyWith(episodes: revived);

        final existing = byVideo[task.videoId];
        if (existing == null) {
          byVideo[task.videoId] = task;
        } else {
          final seenUrls = existing.episodes.map((e) => e.url).toSet();
          final mergedEpisodes = [
            ...existing.episodes,
            ...task.episodes.where((e) => !seenUrls.contains(e.url)),
          ];
          byVideo[task.videoId] = existing.copyWith(
            episodes: mergedEpisodes,
            completedAt: existing.completedAt ?? task.completedAt,
          );
          duplicateTaskIds.add(task.taskId); // redundant row, remove it
        }
      }

      _tasks.addEntries(byVideo.values.map((t) => MapEntry(t.taskId, t)));
      _notifyUpdate();

      // Persist the consolidation: delete the duplicate rows, save the merges.
      if (duplicateTaskIds.isNotEmpty) {
        for (final tid in duplicateTaskIds) {
          await (_db.delete(
            _db.downloadTasks,
          )..where((t) => t.taskId.equals(tid))).go();
        }
        for (final t in byVideo.values) {
          await _saveTask(t);
        }
      }
    } catch (e) {
      logD('DownloadManager', 'Error loading tasks from DB: $e');
    }
  }

  void dispose() {
    _settingsSub?.cancel();
    _dbSub?.cancel();
    // Cancelled before the controller closes, or a trailing notify could fire
    // into a closed StreamController.
    _notifyThrottle?.cancel();
    for (final t in _saveThrottler.values) {
      t.cancel();
    }
    _taskController.close();
  }
}
