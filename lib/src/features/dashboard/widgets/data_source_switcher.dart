import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart' hide DropdownMenu;
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../common/bar_controls.dart';
import '../../../common/dropdown_menu.dart';
import '../../video/data/video_repository.dart';

/// Which catalog the app is browsing.
///
/// A [BarChip] rather than a shape of its own: it is the same kind of control
/// as the catalog's type / area / year chips — a named value you can change —
/// and it was the one thing on the toolbar carrying a filled glyph and
/// hardcoded `white70` text. The name is capped and elided here; it used to be
/// free to push the window's controls off the right edge of the bar.
class DataSourceSwitcher extends ConsumerWidget {
  final VoidCallback? onDataSourceChanged;

  const DataSourceSwitcher({super.key, this.onDataSourceChanged});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final sources = ref.watch(availableDataSourcesProvider);
    final activeId = ref.watch(activeDataSourceIdProvider);

    final activeSource = sources.firstWhere(
      (s) => s.id == activeId,
      orElse: () => sources.first,
    );

    return DropdownMenu(
      menuWidth: 180,
      followTheme: true,
      offset: const Offset(0, 8),
      menuBuilder: (context, close) {
        return sources.map((source) {
          final isSelected = source.id == activeId;
          return PlayerMenuItem(
            text: source.name,
            trailing: isSelected
                ? Icon(
                    Icons.check_rounded,
                    size: 16,
                    color: theme.colorScheme.primary,
                  )
                : null,
            textColor: isSelected ? theme.colorScheme.primary : null,
            onTap: () {
              if (!isSelected) {
                ref
                    .read(activeDataSourceIdProvider.notifier)
                    .setSource(source.id);
                onDataSourceChanged?.call();
              }
              close();
            },
          );
        }).toList();
      },
      child: BarChip(
        label: tr('video.detail.source'),
        value: activeSource.name,
        maxValueWidth: 160,
      ),
    );
  }
}
