// The downloads screen used to rebuild both tabs four times a second while
// anything was downloading. Since 1.16.8 a tab is handed the SAME list when
// none of its tasks changed, so it is skipped. The risk in that shortcut is
// the opposite failure — a tab that stops updating when it should — so both
// directions are pinned here: a progress tick must reach 下载中, must not
// disturb 已完成, and a task finishing must move between them.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:vidra/src/features/download/data/download_provider.dart';
import 'package:vidra/src/features/download/domain/download_task.dart';

DownloadTask task(String id, DownloadStatus status, double progress) =>
    DownloadTask(
      taskId: id,
      videoId: id.hashCode,
      videoTitle: id,
      episodes: [
        EpisodeDownloadInfo(index: 0, status: status, progress: progress),
      ],
      createdAt: DateTime(2026),
    );

void main() {
  test(
    'a progress tick reaches the active tab and skips the completed one',
    () async {
      final feed = StreamController<List<DownloadTask>>();
      addTearDown(feed.close);
      final container = ProviderContainer(
        overrides: [downloadTasksProvider.overrideWith((ref) => feed.stream)],
      );
      addTearDown(container.dispose);
      // Keep both alive, as the two mounted tabs do.
      final a = container.listen(activeDownloadsProvider, (_, _) {});
      final c = container.listen(completedDownloadsProvider, (_, _) {});
      addTearDown(a.close);
      addTearDown(c.close);
      Future<void> emit(List<DownloadTask> tasks) async {
        feed.add(tasks);
        await Future<void>.delayed(Duration.zero);
      }

      final done = task('done', DownloadStatus.completed, 1);
      final running = task('running', DownloadStatus.downloading, 0.2);
      await emit([done, running]);
      final completedBefore = container.read(completedDownloadsProvider);
      final activeBefore = container.read(activeDownloadsProvider);
      expect(completedBefore.single.taskId, 'done');
      expect(activeBefore.single.progress, 0.2);

      // The manager replaces the task that moved and re-emits the rest as-is.
      final ticked = task('running', DownloadStatus.downloading, 0.6);
      await emit([done, ticked]);
      expect(
        identical(container.read(completedDownloadsProvider), completedBefore),
        isTrue,
        reason: 'nothing completed changed, so the tab must not be rebuilt',
      );
      expect(
        container.read(activeDownloadsProvider).single.progress,
        0.6,
        reason: 'the progress tick must reach the active tab',
      );

      // Finishing moves the task across.
      await emit([done, task('running', DownloadStatus.completed, 1)]);
      expect(container.read(activeDownloadsProvider), isEmpty);
      expect(container.read(completedDownloadsProvider), hasLength(2));
    },
  );
}
