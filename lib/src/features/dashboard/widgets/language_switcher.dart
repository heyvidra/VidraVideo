import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart' hide DropdownMenu;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../settings/presentation/settings_provider.dart';
import '../../../common/dropdown_menu.dart';

class LanguageSwitcher extends ConsumerStatefulWidget {
  const LanguageSwitcher({super.key});

  @override
  ConsumerState<LanguageSwitcher> createState() => _LanguageSwitcherState();
}

class _LanguageSwitcherState extends ConsumerState<LanguageSwitcher> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentLocale = context.locale.toString();

    return DropdownMenu(
      menuWidth: 120,
      offset: const Offset(0, 8),
      menuBuilder: (context, close) {
        return [
          PlayerMenuItem(
            text: 'English',
            trailing: currentLocale == 'en'
                ? Icon(Icons.check, size: 16, color: theme.colorScheme.primary)
                : null,
            textColor: currentLocale == 'en' ? theme.colorScheme.primary : null,
            onTap: () async {
              if (currentLocale != 'en') {
                await context.setLocale(const Locale('en'));
                await ref.read(settingsRepositoryProvider).updateLocale('en');
              }
              close();
            },
          ),
          PlayerMenuItem(
            text: '中文',
            trailing: currentLocale == 'zh'
                ? Icon(Icons.check, size: 16, color: theme.colorScheme.primary)
                : null,
            textColor: currentLocale == 'zh' ? theme.colorScheme.primary : null,
            onTap: () async {
              if (currentLocale != 'zh') {
                await context.setLocale(const Locale('zh'));
                await ref.read(settingsRepositoryProvider).updateLocale('zh');
              }
              close();
            },
          ),
        ];
      },
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: _isHovered
                ? theme.colorScheme.onSurface.withValues(alpha: 0.1)
                : Colors.transparent,
            shape: BoxShape.circle,
          ),
          padding: const EdgeInsets.all(8),
          child: Icon(
            Icons.translate,
            color: theme.colorScheme.onSurface,
            size: 20,
          ),
        ),
      ),
    );
  }
}
