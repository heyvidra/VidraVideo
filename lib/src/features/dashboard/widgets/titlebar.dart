import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/theme_provider.dart';

import 'package:bitsdojo_window/bitsdojo_window.dart';

import 'data_source_switcher.dart';
import 'language_switcher.dart';

class DashboardTitleBar extends ConsumerStatefulWidget {
  final void Function(String) onSearchSubmitted;
  final VoidCallback? onHomeRequested;

  const DashboardTitleBar({
    super.key,
    required this.onSearchSubmitted,
    this.onHomeRequested,
  });

  @override
  ConsumerState<DashboardTitleBar> createState() => _DashboardTitleBarState();
}

class _DashboardTitleBarState extends ConsumerState<DashboardTitleBar> {
  bool isAlwaysOnTop = false;

  @override
  void initState() {
    super.initState();
  }

  void _toggleAlwaysOnTop() {
    setState(() {
      isAlwaysOnTop = !isAlwaysOnTop;
      appWindow.alwaysOnTop = isAlwaysOnTop;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 450),
              height: 45,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withAlpha(100)
                    : Colors.black.withAlpha(80),
                borderRadius: BorderRadius.circular(25),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      style: TextStyle(color: theme.colorScheme.onSurface),
                      decoration: InputDecoration(
                        hintText: tr('dashboard.search_hint'),
                        hintStyle: TextStyle(
                          color: isDark ? Colors.black45 : Colors.white70,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onSubmitted: (value) {
                        if (value.isNotEmpty) {
                          widget.onSearchSubmitted(value);
                        }
                      },
                      textInputAction: TextInputAction.search,
                    ),
                  ),
                  Icon(
                    Icons.search,
                    color: isDark ? Colors.black45 : Colors.white70,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
        // Theme Toggle, Always on Top, and User Profile
        Row(
          children: [
            DataSourceSwitcher(onDataSourceChanged: widget.onHomeRequested),
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(
                isAlwaysOnTop ? Icons.push_pin : Icons.push_pin_outlined,
                color: isAlwaysOnTop
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface,
                // size: 20,
              ),
              onPressed: _toggleAlwaysOnTop,
              tooltip: isAlwaysOnTop
                  ? tr('dashboard.unpin_from_top')
                  : tr('dashboard.pin_to_top'),
            ),
            IconButton(
              icon: Icon(
                isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                color: theme.colorScheme.onSurface,
              ),
              onPressed: () {
                ref.read(themeModeProvider.notifier).toggleTheme();
              },
              tooltip: isDark
                  ? tr('dashboard.switch_to_light_mode')
                  : tr('dashboard.switch_to_dark_mode'),
            ),
            const SizedBox(width: 8),
            const LanguageSwitcher(),

            const SizedBox(width: 12),
            const CircleAvatar(
              radius: 18,
              backgroundImage: NetworkImage(
                'https://www.olevod.com/upload/vod/20250824-1/5ee9fd7793f13d492ec3c72abffbc888.jpg_384x560.jpg',
              ),
            ),
            // const SizedBox(width: 8),
            // Icon(Icons.keyboard_arrow_down, color: theme.colorScheme.onSurface),
          ],
        ),
      ],
    );
  }
}
