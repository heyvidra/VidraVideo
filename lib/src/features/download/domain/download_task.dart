/// Download task status
enum DownloadStatus {
  queued,
  downloading,
  paused,
  completed,
  failed,
  cancelled,
}

/// Individual episode download info
class EpisodeDownloadInfo {
  final int? index;
  final String? title;
  final String? url;
  final String? outputPath;

  /// vidraDlp format selector for this episode (e.g. an exact `format_id`, or
  /// `best` / `best[height<=720]`). Null keeps the legacy `direct` behavior
  /// used by catalog HLS downloads; the pasted-URL flow sets it explicitly.
  final String? formatId;
  final DownloadStatus status;
  final double progress; // 0.0 to 1.0
  final int bytesDownloaded;
  final int totalBytes;
  final DateTime? startTime;
  final DateTime? completedTime;
  final String? error;

  EpisodeDownloadInfo({
    this.index,
    this.title,
    this.url,
    this.outputPath,
    this.formatId,
    this.status = DownloadStatus.queued,
    this.progress = 0.0,
    this.bytesDownloaded = 0,
    this.totalBytes = 0,
    this.startTime,
    this.completedTime,
    this.error,
  });

  EpisodeDownloadInfo copyWith({
    int? index,
    String? title,
    String? url,
    String? outputPath,
    String? formatId,
    DownloadStatus? status,
    double? progress,
    int? bytesDownloaded,
    int? totalBytes,
    DateTime? startTime,
    DateTime? completedTime,
    String? error,
  }) {
    return EpisodeDownloadInfo(
      index: index ?? this.index,
      title: title ?? this.title,
      url: url ?? this.url,
      outputPath: outputPath ?? this.outputPath,
      formatId: formatId ?? this.formatId,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      bytesDownloaded: bytesDownloaded ?? this.bytesDownloaded,
      totalBytes: totalBytes ?? this.totalBytes,
      startTime: startTime ?? this.startTime,
      completedTime: completedTime ?? this.completedTime,
      error: error ?? this.error,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'index': index,
      'title': title,
      'url': url,
      'outputPath': outputPath,
      'formatId': formatId,
      'status': status.name,
      'progress': progress,
      'bytesDownloaded': bytesDownloaded,
      'totalBytes': totalBytes,
      'startTime': startTime?.toIso8601String(),
      'completedTime': completedTime?.toIso8601String(),
      'error': error,
    };
  }

  factory EpisodeDownloadInfo.fromJson(Map<String, dynamic> json) {
    return EpisodeDownloadInfo(
      index: json['index'] as int?,
      title: json['title'] as String?,
      url: json['url'] as String?,
      outputPath: json['outputPath'] as String?,
      formatId: json['formatId'] as String?,
      status: DownloadStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => DownloadStatus.queued,
      ),
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      bytesDownloaded: json['bytesDownloaded'] as int? ?? 0,
      totalBytes: json['totalBytes'] as int? ?? 0,
      startTime: json['startTime'] != null
          ? DateTime.parse(json['startTime'] as String)
          : null,
      completedTime: json['completedTime'] != null
          ? DateTime.parse(json['completedTime'] as String)
          : null,
      error: json['error'] as String?,
    );
  }
}

/// Download task for a video (can contain multiple episodes)
class DownloadTask {
  int id = 0;

  late String taskId;

  late int videoId;

  late String videoTitle;
  String? coverUrl;
  late List<EpisodeDownloadInfo> episodes;
  late DateTime createdAt;
  DateTime? completedAt;

  DownloadTask({
    this.taskId = '',
    required this.videoId,
    required this.videoTitle,
    this.coverUrl,
    required this.episodes,
    required this.createdAt,
    this.completedAt,
  });

  /// Overall task status
  DownloadStatus get status {
    if (episodes.isEmpty) return DownloadStatus.queued;

    if (episodes.every((e) => e.status == DownloadStatus.completed)) {
      return DownloadStatus.completed;
    }

    if (episodes.any((e) => e.status == DownloadStatus.downloading)) {
      return DownloadStatus.downloading;
    }

    // User-initiated pause outranks an incidental episode failure: a paused
    // task must still read as "paused" and offer Resume (which retries the
    // failed episodes too). Otherwise one failed episode flips the whole task
    // to "failed" and hides the resume action.
    if (episodes.any((e) => e.status == DownloadStatus.paused)) {
      return DownloadStatus.paused;
    }

    // Still has queued work waiting for a slot → in-progress, not failed.
    if (episodes.any((e) => e.status == DownloadStatus.queued)) {
      return DownloadStatus.queued;
    }

    if (episodes.any((e) => e.status == DownloadStatus.failed)) {
      return DownloadStatus.failed;
    }

    // No pending work remains — every episode is completed or cancelled. If any
    // finished, treat the task as completed (its files are playable and it
    // belongs in the Completed tab); otherwise it's fully cancelled. This is
    // what stops a partly-cancelled task from being stranded as "queued".
    if (episodes.any((e) => e.status == DownloadStatus.completed)) {
      return DownloadStatus.completed;
    }

    return DownloadStatus.cancelled;
  }

  /// Overall progress (0.0 to 1.0)
  double get progress {
    if (episodes.isEmpty) return 0.0;
    final totalProgress = episodes.fold<double>(
      0,
      (sum, episode) => sum + episode.progress,
    );
    return totalProgress / episodes.length;
  }

  /// Total bytes downloaded across all episodes
  int get totalBytesDownloaded {
    return episodes.fold<int>(
      0,
      (sum, episode) => sum + episode.bytesDownloaded,
    );
  }

  /// Total bytes across all episodes
  int get totalBytes {
    return episodes.fold<int>(0, (sum, episode) => sum + episode.totalBytes);
  }

  /// Estimated time remaining in seconds, for the in-flight batch.
  /// Remaining bytes of all downloading episodes / aggregate speed. Queued
  /// episodes' sizes are unknown until they start, so they're excluded.
  int? get estimatedTimeRemaining {
    final speed = downloadSpeed;
    if (speed == null || speed <= 0) return null;

    final remainingBytes = episodes
        .where((e) => e.status == DownloadStatus.downloading)
        .fold<int>(0, (sum, e) => sum + (e.totalBytes - e.bytesDownloaded));

    if (remainingBytes <= 0) return null;
    return (remainingBytes / speed).round();
  }

  /// Aggregate download speed in bytes/second across ALL concurrently
  /// downloading episodes (not just the first — the pool runs many at once).
  double? get downloadSpeed {
    final downloading = episodes.where(
      (e) => e.status == DownloadStatus.downloading && e.startTime != null,
    );
    if (downloading.isEmpty) return null;

    double total = 0;
    for (final e in downloading) {
      if (e.bytesDownloaded <= 0) continue;
      final secs = DateTime.now().difference(e.startTime!).inSeconds;
      if (secs <= 0) continue;
      total += e.bytesDownloaded / secs;
    }
    return total;
  }

  DownloadTask copyWith({
    String? taskId,
    int? videoId,
    String? videoTitle,
    String? coverUrl,
    List<EpisodeDownloadInfo>? episodes,
    DateTime? createdAt,
    DateTime? completedAt,
  }) {
    return DownloadTask(
      taskId: taskId ?? this.taskId,
      videoId: videoId ?? this.videoId,
      videoTitle: videoTitle ?? this.videoTitle,
      coverUrl: coverUrl ?? this.coverUrl,
      episodes: episodes ?? this.episodes,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
    )..id = id; // preserve the DB row id (not a constructor arg)
  }
}
