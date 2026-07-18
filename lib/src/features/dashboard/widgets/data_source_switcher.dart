import 'package:flutter/material.dart' hide DropdownMenu;
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../common/dropdown_menu.dart';
import '../../video/data/video_repository.dart';

class DataSourceSwitcher extends HookConsumerWidget {
  final VoidCallback? onDataSourceChanged;

  const DataSourceSwitcher({super.key, this.onDataSourceChanged});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final sources = ref.watch(availableDataSourcesProvider);
    final activeId = ref.watch(activeDataSourceIdProvider);
    final isDark = theme.brightness == Brightness.dark;
    final isHovered = useState(false);

    final activeSource = sources.firstWhere(
      (s) => s.id == activeId,
      orElse: () => sources.first,
    );
    // activeId is already the string id

    return DropdownMenu(
      menuWidth: 160,
      offset: const Offset(0, 8),
      menuBuilder: (context, close) {
        return sources.map((source) {
          final isSelected = source.id == activeId;
          return PlayerMenuItem(
            text: source.name,
            trailing: isSelected
                ? Icon(Icons.check, size: 16, color: theme.colorScheme.primary)
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
      child: MouseRegion(
        onEnter: (_) => isHovered.value = true,
        onExit: (_) => isHovered.value = false,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isHovered.value
                ? (isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.05))
                : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.source,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
              const SizedBox(width: 6),
              Text(
                activeSource.name,
                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                color: isDark ? Colors.white54 : Colors.black45,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
