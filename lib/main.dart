import 'dart:async';
import 'dart:io' show Platform;

import 'package:easy_localization/easy_localization.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vidra_player_kit/vidra_player_kit.dart';

import 'src/config/app_config.dart';
import 'src/core/network/bundled_roots.dart';
import 'src/core/utils/log.dart';
import 'src/core/utils/window.dart';

import 'src/config/app_theme.dart';
import 'src/config/no_scrollbar_behavior.dart';
import 'src/core/providers/theme_provider.dart'; // Import theme_provider
import 'src/features/video/data/video_repository.dart';
import 'src/routing/app_router.dart';
import 'src/features/settings/data/settings_repository.dart';
import 'src/features/settings/presentation/settings_provider.dart';
import 'src/features/download/data/download_provider.dart';
import 'src/window/video_player_window.dart';
import 'src/window/window_title_bar_buttons.dart';

import 'src/data/database/app_database.dart';
import 'src/data/database/app_database_provider.dart';

Future<void> main() async {
  await _runApp();
}

Future<void> _runApp() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  await installBundledRoots();

  try {
    VidraPlayerKit.ensureInitialized();
  } catch (e) {
    logR('Main', 'Error initializing VidraPlayerKit: $e');
  }

  // 2. Data layers
  final database = AppDatabase();
  final settingsRepository = SettingsRepository(database);
  final appSettings = await settingsRepository.getSettings();

  final initialDataSourceId = appSettings.lastDataSourceId ?? 'mock';
  final savedLocale = appSettings.locale;
  final initialThemeMode = appSettings.themeMode;

  final container = ProviderContainer(
    overrides: [
      appDatabaseProvider.overrideWithValue(database),
      initialDataSourceIdProvider.overrideWithValue(initialDataSourceId),
      initialThemeModeProvider.overrideWithValue(
        initialThemeMode,
      ), // Override theme
    ],
  );

  // 3. Services initialization
  await container
      .read(downloadManagerProvider)
      .initialize(startProcessing: appWindow.isMainWindow);

  WindowHelper.init(container.read(settingsRepositoryProvider));

  runBitsdojoWindowApp(
    routes: {
      'player': (context, arguments) =>
          VideoPlayerWindowApp(arguments: arguments),
    },
    windowConfigurations: _buildWindowConfigurations(),
    app: EasyLocalization(
      supportedLocales: const [Locale('zh'), Locale('en')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      startLocale: savedLocale != null ? Locale(savedLocale) : null,
      child: UncontrolledProviderScope(
        container: container,
        child: const MyApp(),
      ),
    ),
  );
}

List<WindowConfiguration> _buildWindowConfigurations() {
  final readyAnimation = Platform.isLinux
      ? const WindowReadyAnimation.none()
      : const WindowReadyAnimation.popIn();
  return [
    WindowConfiguration(
      mainWindow: true,
      title: 'Vidra',
      sizeBuilder: (window) {
        final screenSize = window.workingScreenSize;
        return Size(screenSize.width * 0.8, screenSize.height * 0.8);
      },
      minSizeBuilder: (window) {
        final screenSize = window.workingScreenSize;
        return Size(screenSize.width * 0.6, screenSize.height * 0.6);
      },
      alignment: Alignment.center,
      backgroundEffectBuilder: _resolveBackgroundEffect,
      alwaysOnTop: false,
      readyAnimation: readyAnimation,
    ),
    WindowConfiguration(
      name: 'player',
      title: 'Vidra Player',
      sizeBuilder: (_) => WindowHelper.playerSize(),
      minSize: AppConfig.playerMiniSize,
      alignment: Alignment.center,
      backgroundEffectBuilder: _resolveBackgroundEffect,
      alwaysOnTop: false,
      buttonVisibilityBuilder: _resolvePlayerButtonVisibility,
      readyAnimation: readyAnimation,
    ),
    WindowConfiguration(
      backgroundEffectBuilder: _resolveBackgroundEffect,
      alwaysOnTop: false,
      readyAnimation: readyAnimation,
    ),
  ];
}

WindowEffect _resolveBackgroundEffect(DesktopWindow window) {
  return platformWindowCapabilities.supportsBackgroundEffects
      ? WindowEffect.acrylic
      : WindowEffect.disabled;
}

Map<DesktopWindowButton, bool>? _resolvePlayerButtonVisibility(
  DesktopWindow window,
) {
  if (!platformWindowCapabilities.supportsTitleBarButtonVisibility) {
    return null;
  }

  return WindowTitleBarButtonsConfig.resolve(
    window.arguments,
    defaultVisibleButtons: const {},
  );
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  bool _isExitDialogShowing = false;
  GoRouter? _router;

  Future<bool> _handleMainWindowClose(
    BuildContext context,
    DesktopWindow window,
  ) async {
    if (!window.isMainWindow) {
      return true;
    }
    if (_isExitDialogShowing) {
      return false;
    }

    _isExitDialogShowing = true;
    window.show();
    final dialogContext = _router?.routerDelegate.navigatorKey.currentContext;

    final shouldClose =
        await showDialog<bool>(
          context: dialogContext ?? context,
          barrierDismissible: false,
          builder: (context) {
            return AlertDialog(
              title: Text(tr('dashboard.exit_dialog.title')),
              content: Text(tr('dashboard.exit_dialog.content')),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(tr('dashboard.exit_dialog.cancel')),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(tr('dashboard.exit_dialog.confirm')),
                ),
              ],
            );
          },
        ) ??
        false;

    if (mounted) {
      setState(() {
        _isExitDialogShowing = false;
      });
    } else {
      _isExitDialogShowing = false;
    }

    return shouldClose;
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    _router = router;
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp.router(
      title: 'Vidra',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      scrollBehavior: NoScrollbarBehavior(),
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      showSemanticsDebugger: false,
      builder: (context, child) {
        return RoutedWindowHost(
          onCloseRequested: _handleMainWindowClose,
          defaultChild: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
