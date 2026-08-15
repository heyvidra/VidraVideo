import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../../core/utils/file_reveal.dart';
import '../../../../core/utils/format.dart';
import '../../../../window/player_window_launcher.dart';
import '../../domain/download_task.dart';
import '../../data/download_manager.dart';
import '../../data/download_provider.dart';
import '../../../video/data/video_repository.dart';
import 'download_ui.dart';

class DownloadTaskCard extends ConsumerStatefulWidget {
  final DownloadTask task;
  final bool isActive;

  const DownloadTaskCard({
    super.key,
    required this.task,
    required this.isActive,
  });

  @override
  ConsumerState<DownloadTaskCard> createState() => _DownloadTaskCardState();
}

class _DownloadTaskCardState extends ConsumerState<DownloadTaskCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final manager = ref.watch(downloadManagerProvider);
    final task = widget.task;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: downloadCardDecoration(theme),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Main task info
          InkWell(
            // Multi-episode: expand. Single completed episode: tap plays it.
            onTap: task.episodes.length > 1
                ? () => setState(() => _isExpanded = !_isExpanded)
                : (_completedFile(task) != null
                      ? () => _playInApp(task, task.episodes.first)
                      : null),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ThumbWithBadge(
                    imageUrl: _resolvedCover(task),
                    cornerBadge: _thumbBadge(task, theme),
                  ),
                  const SizedBox(width: 14),
                  Expanded(child: _middle(task, theme)),
                  const SizedBox(width: 8),
                  _actions(task, manager, theme),
                  if (task.episodes.length > 1)
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Icon(
                        _isExpanded ? Icons.expand_less : Icons.expand_more,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
          ),
          // Expanded episode list
          if (_isExpanded && task.episodes.length > 1)
            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLow,
                border: Border(
                  top: BorderSide(color: theme.dividerColor.withAlpha(50)),
                ),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: task.episodes.length,
                separatorBuilder: (context, index) =>
                    Divider(height: 1, color: theme.dividerColor.withAlpha(50)),
                itemBuilder: (context, index) {
                  final episode = task.episodes[index];
                  final epDone =
                      episode.status == DownloadStatus.completed &&
                      episode.outputPath != null;
                  return ListTile(
                    dense: true,
                    onTap: epDone ? () => _playInApp(task, episode) : null,
                    leading: _getEpisodeStatusIcon(episode.status, theme),
                    title: Text(
                      episode.title ?? tr('download.episode_fallback'),
                      style: TextStyle(
                        fontSize: 14,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    subtitle: episode.status == DownloadStatus.downloading
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              LinearProgressIndicator(
                                value: episode.progress,
                                backgroundColor:
                                    theme.colorScheme.surfaceContainerHighest,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${formatBytes(episode.bytesDownloaded)} / ${formatBytes(episode.totalBytes)}'
                                '${task.estimatedTimeRemaining != null ? " · ${tr('download.time_left', args: [formatDuration(task.estimatedTimeRemaining!)])}" : ""}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          )
                        : null,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (episode.status == DownloadStatus.downloading)
                          Text(
                            '${(episode.progress * 100).toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        if (episode.status == DownloadStatus.downloading ||
                            episode.status == DownloadStatus.queued)
                          IconButton(
                            icon: const Icon(Icons.close, size: 20),
                            onPressed: () =>
                                manager.cancelEpisode(task.taskId, index),
                            tooltip: tr('download.action.cancel'),
                          ),
                        // Failed/cancelled episode → retry just this one.
                        if (episode.status == DownloadStatus.failed ||
                            episode.status == DownloadStatus.cancelled)
                          IconButton(
                            icon: const Icon(Icons.refresh, size: 20),
                            onPressed: () =>
                                manager.retryEpisode(task.taskId, index),
                            tooltip: tr('download.action.retry'),
                          ),
                        if (epDone) ...[
                          IconButton(
                            icon: const Icon(
                              Icons.play_circle_outline,
                              size: 20,
                            ),
                            color: theme.colorScheme.primary,
                            onPressed: () => _playInApp(task, episode),
                            tooltip: tr('download.action.play'),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.folder_open_outlined,
                              size: 20,
                            ),
                            onPressed: () =>
                                revealInFileManager(episode.outputPath!),
                            tooltip: tr('download.action.reveal'),
                          ),
                        ],
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 20),
                          onPressed: () => _showDeleteDialog(
                            context,
                            (deleteFile) => manager.deleteEpisode(
                              task.taskId,
                              index,
                              deleteFile: deleteFile,
                            ),
                            title: tr('download.delete.episode_title'),
                            content: tr('download.delete.episode_content'),
                          ),
                          tooltip: tr('download.action.delete'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  /// Resolve the cover URL (http as-is, else through the catalog repo).
  String? _resolvedCover(DownloadTask task) {
    final url = task.coverUrl;
    if (url == null || url.isEmpty) return null;
    return url.startsWith('http')
        ? url
        : ref.read(videoRepositoryProvider).resolveUrl(url);
  }

  /// Corner badge on the thumbnail: green ✓ when completed, red "下载中" while
  /// downloading, none otherwise.
  Widget? _thumbBadge(DownloadTask task, ThemeData theme) {
    if (!widget.isActive) {
      return Container(
        width: 18,
        height: 18,
        decoration: const BoxDecoration(
          color: Colors.green,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.check, size: 12, color: Colors.white),
      );
    }
    if (task.status == DownloadStatus.downloading) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withAlpha(230),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          tr('download.tab.downloading'),
          style: const TextStyle(fontSize: 10, color: Colors.white),
        ),
      );
    }
    return null;
  }

  /// Middle column: title + progress/status (active) or chips + done (completed).
  Widget _middle(DownloadTask task, ThemeData theme) {
    final label = task.episodes.length == 1
        ? (task.episodes.first.title ?? '')
        : tr('download.episodes_count', args: ['${task.episodes.length}']);
    final title = Text(
      task.videoTitle,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600),
    );

    if (!widget.isActive) {
      // Completed: thumbnail already carries the green ✓ and the tab says
      // "已完成", so just show quality + size chips — no redundant status text.
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          title,
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (label.isNotEmpty) MetaChip(label),
              if (task.totalBytes > 0) MetaChip(formatBytes(task.totalBytes)),
            ],
          ),
        ],
      );
    }

    final isDownloading = task.status == DownloadStatus.downloading;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        title,
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: task.progress,
                  minHeight: 6,
                  backgroundColor: theme.colorScheme.onSurface.withAlpha(20),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _getStatusColor(task.status, theme),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              '${(task.progress * 100).toStringAsFixed(0)}%',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        _metaLine(task, theme, label, isDownloading),
      ],
    );
  }

  /// One-line meta under the progress bar: bytes · speed(red) · remaining while
  /// downloading; label · status otherwise.
  Widget _metaLine(
    DownloadTask task,
    ThemeData theme,
    String label,
    bool isDownloading,
  ) {
    final muted = theme.colorScheme.onSurfaceVariant;
    final spans = <InlineSpan>[];
    void add(String t, {Color? c}) => spans.add(
      TextSpan(
        text: t,
        style: TextStyle(color: c ?? muted),
      ),
    );
    const dot = '  ·  ';

    if (isDownloading) {
      add(
        '${formatBytes(task.totalBytesDownloaded)} / ${formatBytes(task.totalBytes)}',
      );
      if (task.downloadSpeed != null) {
        add(dot);
        add(_formatSpeed(task.downloadSpeed!), c: theme.colorScheme.primary);
      }
      if (task.estimatedTimeRemaining != null) {
        add(dot);
        add(
          tr(
            'download.time_left',
            args: [formatDuration(task.estimatedTimeRemaining!)],
          ),
        );
      }
    } else {
      if (label.isNotEmpty) {
        add(label);
        add(dot);
      }
      add(_getStatusText(task), c: _getStatusColor(task.status, theme));
    }

    return Text.rich(
      TextSpan(children: spans, style: const TextStyle(fontSize: 12)),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  /// Trailing action cluster (ghost icons; red play on completed).
  Widget _actions(DownloadTask task, DownloadManager manager, ThemeData theme) {
    final items = <Widget>[];
    if (widget.isActive) {
      if (task.status == DownloadStatus.downloading) {
        items.add(
          GhostIconButton(
            icon: Icons.pause,
            tooltip: tr('download.action.pause'),
            onPressed: () => manager.pauseTask(task.taskId),
          ),
        );
      } else if (task.status == DownloadStatus.paused ||
          task.status == DownloadStatus.failed ||
          task.status == DownloadStatus.cancelled) {
        // paused → resume; failed/cancelled → retry (resumeTask re-queues all).
        final paused = task.status == DownloadStatus.paused;
        items.add(
          GhostIconButton(
            icon: paused ? Icons.play_arrow : Icons.refresh,
            tooltip: paused
                ? tr('download.action.resume')
                : tr('download.action.retry'),
            onPressed: () => manager.resumeTask(task.taskId),
          ),
        );
      }
      items.add(
        GhostIconButton(
          icon: Icons.close,
          tooltip: tr('download.action.cancel_all'),
          onPressed: () => manager.cancelTask(task.taskId),
        ),
      );
      items.add(
        GhostIconButton(
          icon: Icons.delete_outline,
          tooltip: tr('download.action.delete_task'),
          onPressed: () => _showDeleteDialog(
            context,
            (deleteFile) =>
                manager.deleteTask(task.taskId, deleteFile: deleteFile),
          ),
        ),
      );
    } else {
      if (_completedFile(task) != null) {
        items.add(
          GhostIconButton(
            icon: Icons.play_arrow,
            tooltip: tr('download.action.play'),
            color: theme.colorScheme.primary,
            onPressed: () => _playInApp(task, task.episodes.first),
          ),
        );
        items.add(
          GhostIconButton(
            icon: Icons.folder_open_outlined,
            tooltip: tr('download.action.reveal'),
            onPressed: () => revealInFileManager(_completedFile(task)!),
          ),
        );
      }
      items.add(
        GhostIconButton(
          icon: Icons.delete_outline,
          tooltip: tr('download.action.delete'),
          onPressed: () => _showDeleteDialog(
            context,
            (deleteFile) =>
                manager.deleteTask(task.taskId, deleteFile: deleteFile),
          ),
        ),
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          items[i],
        ],
      ],
    );
  }

  Color _getStatusColor(DownloadStatus status, ThemeData theme) {
    switch (status) {
      case DownloadStatus.downloading:
        return theme.colorScheme.secondary;
      case DownloadStatus.completed:
        return Colors.green;
      case DownloadStatus.failed:
        return Colors.red;
      case DownloadStatus.paused:
        return Colors.orange;
      default:
        return theme.colorScheme.onSurfaceVariant;
    }
  }

  /// Path of the single downloaded file for a completed one-episode task, but
  /// only when the file still exists on disk — so a task whose file was deleted
  /// externally doesn't offer play/reveal (which would open a broken player).
  /// Multi-episode tasks expose per-episode actions in the expanded list, so
  /// this returns null for them.
  String? _completedFile(DownloadTask task) {
    if (task.episodes.length != 1) return null;
    final ep = task.episodes.first;
    if (ep.status != DownloadStatus.completed) return null;
    final path = ep.outputPath;
    if (path == null || !File(path).existsSync()) return null;
    return path;
  }

  /// Play a downloaded episode in the app's own player window (not the OS
  /// default app). The in-app player prefers the local downloaded file for a
  /// video/episode it already has on disk, so this plays offline from disk.
  void _playInApp(DownloadTask task, EpisodeDownloadInfo episode) {
    PlayerLauncher.open(
      context,
      videoId: task.videoId,
      episodeIndex: episode.index ?? 0,
    );
  }

  String _getStatusText(DownloadTask task) {
    final completed = task.episodes
        .where((e) => e.status == DownloadStatus.completed)
        .length;
    final total = '${task.episodes.length}';

    switch (task.status) {
      case DownloadStatus.completed:
        return tr('download.status.completed');
      case DownloadStatus.paused:
        return tr('download.status.paused', args: ['$completed', total]);
      case DownloadStatus.failed:
        return tr('download.status.failed');
      case DownloadStatus.cancelled:
        return tr('download.status.cancelled');
      case DownloadStatus.queued:
        return tr('download.status.queued');
      default:
        return tr('download.status.downloading', args: ['$completed', total]);
    }
  }

  Widget _getEpisodeStatusIcon(DownloadStatus status, ThemeData theme) {
    switch (status) {
      case DownloadStatus.completed:
        return const Icon(Icons.check_circle, color: Colors.green, size: 20);
      case DownloadStatus.downloading:
        return const Icon(Icons.download, color: Colors.red, size: 20);
      case DownloadStatus.failed:
        return const Icon(Icons.error, color: Colors.red, size: 20);
      case DownloadStatus.paused:
        return const Icon(Icons.pause_circle, color: Colors.orange, size: 20);
      case DownloadStatus.cancelled:
        return Icon(
          Icons.cancel_outlined,
          color: theme.colorScheme.onSurfaceVariant,
          size: 20,
        );
      default:
        return Icon(
          Icons.schedule,
          color: theme.colorScheme.onSurfaceVariant,
          size: 20,
        );
    }
  }

  String _formatSpeed(double bytesPerSecond) {
    if (bytesPerSecond < 1024) {
      return '${bytesPerSecond.toStringAsFixed(0)} B/s';
    } else if (bytesPerSecond < 1024 * 1024) {
      return '${(bytesPerSecond / 1024).toStringAsFixed(1)} KB/s';
    } else {
      return '${(bytesPerSecond / 1024 / 1024).toStringAsFixed(1)} MB/s';
    }
  }

  Future<void> _showDeleteDialog(
    BuildContext context,
    Function(bool deleteFile) onConfirm, {
    String? title,
    String? content,
  }) async {
    final dialogTitle = title ?? tr('download.delete.task_title');
    final dialogContent = content ?? tr('download.delete.task_content');
    bool deleteFile = false;
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(dialogTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(dialogContent),
              const SizedBox(height: 16),
              CheckboxListTile(
                title: Text(tr('download.delete.also_files')),
                value: deleteFile,
                onChanged: (value) =>
                    setState(() => deleteFile = value ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(tr('common.cancel')),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                onConfirm(deleteFile);
              },
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              child: Text(tr('download.action.delete')),
            ),
          ],
        ),
      ),
    );
  }
}
