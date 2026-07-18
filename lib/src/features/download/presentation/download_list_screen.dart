import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../data/download_provider.dart';
import '../domain/download_task.dart';
import 'widgets/download_task_card.dart';
import 'widgets/download_ui.dart';

class DownloadListScreen extends ConsumerWidget {
  const DownloadListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final activeTasks = ref.watch(activeDownloadsProvider);
    final completedTasks = ref.watch(completedDownloadsProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        body: Column(
          children: [
            // Title + tabs live in the SAME left-aligned content column as the
            // cards, so everything shares one left edge next to the sidebar.
            constrainedContent(
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tr('download.title'),
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TabBar(
                      isScrollable: true,
                      tabAlignment: TabAlignment.start,
                      dividerColor: Colors.transparent,
                      indicatorSize: TabBarIndicatorSize.label,
                      indicatorColor: theme.colorScheme.primary,
                      labelColor: theme.colorScheme.onSurface,
                      unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                      unselectedLabelStyle: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                      ),
                      padding: EdgeInsets.zero,
                      labelPadding: const EdgeInsets.only(right: 28),
                      tabs: [
                        Tab(text: tr('download.tab.downloading')),
                        Tab(text: tr('download.tab.completed')),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildTaskList(context, ref, activeTasks, isActive: true),
                  _buildTaskList(context, ref, completedTasks, isActive: false),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskList(
    BuildContext context,
    WidgetRef ref,
    List<DownloadTask> tasks, {
    required bool isActive,
  }) {
    if (tasks.isEmpty) {
      final theme = Theme.of(context);
      final muted = theme.colorScheme.onSurfaceVariant;
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isActive ? Icons.download_outlined : Icons.check_circle_outline,
              size: 64,
              color: muted.withAlpha(120),
            ),
            const SizedBox(height: 16),
            Text(
              isActive
                  ? tr('download.empty.active')
                  : tr('download.empty.completed'),
              style: TextStyle(fontSize: 16, color: muted),
            ),
          ],
        ),
      );
    }

    return constrainedContent(
      ListView.builder(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
        itemCount: tasks.length,
        itemBuilder: (context, index) {
          return DownloadTaskCard(task: tasks[index], isActive: isActive);
        },
      ),
    );
  }
}
