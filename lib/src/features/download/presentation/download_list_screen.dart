import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../common/screen_chrome.dart';
import '../data/download_provider.dart';
import 'widgets/download_task_card.dart';
import 'widgets/download_ui.dart';

class DownloadListScreen extends ConsumerWidget {
  const DownloadListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    // Only the COUNT here. The lists are watched by the tab that shows them,
    // so a progress tick rebuilds the 下载中 list and nothing else.
    final activeCount = ref.watch(activeDownloadCountProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(
          children: [
            ScreenHeader(
              title: tr('download.title'),
              count: activeCount == 0 ? null : '$activeCount',
            ),
            // The tabs sit in the SAME left-aligned content column as the
            // cards, so everything shares one left edge next to the rail.
            constrainedContent(
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  kContentGutter,
                  0,
                  kContentGutter,
                  8,
                ),
                child: TabBar(
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  dividerColor: Colors.transparent,
                  indicatorSize: TabBarIndicatorSize.label,
                  indicatorColor: theme.colorScheme.primary,
                  labelColor: theme.colorScheme.onSurface,
                  unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13.5,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.w400,
                    fontSize: 13.5,
                  ),
                  padding: EdgeInsets.zero,
                  labelPadding: const EdgeInsets.only(right: 24),
                  tabs: [
                    Tab(text: tr('download.tab.downloading')),
                    Tab(text: tr('download.tab.completed')),
                  ],
                ),
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  const _TaskList(isActive: true),
                  const _TaskList(isActive: false),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskList extends ConsumerWidget {
  const _TaskList({required this.isActive});

  final bool isActive;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(
      isActive ? activeDownloadsProvider : completedDownloadsProvider,
    );
    if (tasks.isEmpty) {
      return ScreenEmpty(
        icon: isActive
            ? Icons.download_outlined
            : Icons.check_circle_outline_rounded,
        title: isActive
            ? tr('download.empty.active')
            : tr('download.empty.completed'),
      );
    }

    return constrainedContent(
      ListView.builder(
        padding: const EdgeInsets.fromLTRB(
          kContentGutter,
          4,
          kContentGutter,
          24,
        ),
        itemCount: tasks.length,
        itemBuilder: (context, index) {
          return DownloadTaskCard(task: tasks[index], isActive: isActive);
        },
      ),
    );
  }
}
