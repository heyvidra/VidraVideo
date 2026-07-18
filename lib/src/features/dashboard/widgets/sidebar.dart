import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../core/services/vidradlp/vidradlp_ffi.dart';
import '../domain/app_navigation_item.dart';

const _sidebarTopDragAreaHeight = 65.0;

// ponytail: memoized — vidradlpLibraryAvailable() attempts a dylib open;
// resolve it once for the app's lifetime instead of per sidebar rebuild.
final bool _mediaFfiAvailable = vidradlpLibraryAvailable();

class Sidebar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onDestinationSelected;

  const Sidebar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: _sidebarTopDragAreaHeight,
            child: WindowTitleBarBox(child: MoveWindow()),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 50),
            child: Image.asset(
              'assets/images/logo.png',
              height: 45,
              fit: BoxFit.contain,
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...['Menu', 'Library', 'General'].map((sectionKey) {
                    final items = AppNavigationItem.values
                        .where(
                          (item) =>
                              (!item.requiresMediaFfi || _mediaFfiAvailable) &&
                              item.localizedSection ==
                              tr(
                                'navigation.section_${sectionKey.toLowerCase()}',
                              ),
                        )
                        .toList();
                    if (items.isEmpty) return const SizedBox.shrink();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SidebarSection(
                          title: tr(
                            'navigation.section_${sectionKey.toLowerCase()}',
                          ),
                          children: items.map((item) {
                            return _SidebarItem(
                              icon: item.icon,
                              label: item.localizedLabel,
                              isSelected: selectedIndex == item.branchIndex,
                              onTap: () =>
                                  onDestinationSelected(item.branchIndex),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 32),
                      ],
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SidebarSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 16),
          child: Text(
            title,
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        ...children,
      ],
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isSelected
        ? theme
              .colorScheme
              .primary // Red for selected
        : theme.colorScheme.onSurface;

    return InkWell(
      onTap: onTap,
      hoverColor: isSelected
          ? theme.colorScheme.primary.withAlpha(20)
          : Colors.white.withAlpha(20),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        margin: const EdgeInsets.only(bottom: 4),
        child: Row(
          children: [
            TweenAnimationBuilder<Color?>(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              tween: ColorTween(begin: Colors.white70, end: color),
              builder: (context, c, child) {
                return Icon(icon, color: c, size: 22);
              },
            ),
            const SizedBox(width: 16),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              style: TextStyle(
                color: color,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 15,
              ),
              child: Text(label),
            ),
            const Spacer(),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              width: isSelected ? 3 : 0,
              height: 16,
              margin: EdgeInsets.only(left: isSelected ? 0 : 3),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(1.5),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: theme.colorScheme.primary.withAlpha(128),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ]
                    : [],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
