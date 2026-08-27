import 'dart:async';
import 'dart:io' show Platform;

import 'package:easy_localization/easy_localization.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';
import 'package:local_notifier/local_notifier.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vidra_player/vidra_player.dart';
import 'package:vidra_player_kit/vidra_player_kit.dart';

import 'src/config/app_config.dart';
import 'src/core/network/browser_identity.dart';
import 'src/core/network/player_browser_headers.dart';
import 'src/core/network/bundled_roots.dart';
import 'src/core/telemetry/telemetry.dart';
import 'src/core/utils/log.dart';
import 'src/core/utils/window.dart';

import 'src/config/app_theme.dart';
import 'src/config/no_scrollbar_behavior.dart';
import 'src/config/player_window_mode.dart';
import 'src/config/reduce_effects.dart';
import 'src/core/providers/theme_provider.dart'; // Import theme_provider
import 'src/features/video/data/video_repository.dart';
import 'src/routing/app_router.dart';
import 'src/features/settings/data/settings_repository.dart';
import 'src/features/settings/domain/app_settings.dart' show parseSourceIds;
import 'src/features/settings/presentation/settings_provider.dart';
import 'src/features/download/data/download_provider.dart';
import 'src/window/pet_window.dart';
import 'src/window/video_player_window.dart';
import 'src/window/window_title_bar_buttons.dart';

import 'src/data/database/app_database.dart';
import 'src/data/database/app_database_provider.dart';

/// Desktop notification channel. Named explicitly so the OS attributes the
/// toast to Vidra rather than to the Flutter runner.
///
/// Best-effort: a platform without a notification centre, or a user who has
/// refused permission, must not stop the app from starting. The subscription
/// badge carries the same news either way.
Future<void> _setupNotifications() async {
  try {
    await localNotifier.setup(appName: 'Vidra');
  } catch (e) {
    logR('Notifications', 'setup failed: $e');
  }
}

Future<void> main(List<String> args) async {
  // A secondary window learns WHICH window it is from its engine's entrypoint
  // arguments. The native side also posts a `windowReady` message carrying the
  // same thing, but it fires during plugin registration — before this handler
  // exists — so on Windows the player window came up nameless and rendered the
  // default child: a blank sheet. Seed synchronously, before the first build.
  seedWindowIdentityFromArgs(args);
  await _runApp();
}

Future<void> _runApp() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Window identity was seeded synchronously from the entrypoint args in
  // main(), so it is already trustworthy here — and it decides how much of
  // this boot the engine actually runs. Only a POSITIVELY identified pet
  // gets the trimmed boot: a secondary window that arrives nameless (an
  // un-updated runner, where identity only lands with the native windowReady
  // message) is booted like a player, because over-booting a window wastes a
  // few hundred milliseconds while under-booting one is a broken player.
  final isMainWindow = appWindow.isMainWindow;
  final isPetWindow =
      !isMainWindow && appWindow.name == PetWindowLauncher.windowName;

  // Roll this run's browser before anything can send a request. Every engine
  // rolls its own, which is fine — each is a separate process's worth of
  // traffic to an origin, and nothing ties them together.
  BrowserIdentity.seed();

  await EasyLocalization.ensureInitialized();
  // The pet does no Dart-side HTTP — the sprite is painted locally and the
  // bubble text arrives through window arguments — so the Windows root-CA
  // seeding has nothing there to protect.
  if (!isPetWindow) {
    await installBundledRoots();
  }
  // Toasts are only ever sent by the subscription refresh, which lives in
  // the main engine; secondary engines were paying this setup for nothing.
  if (isMainWindow) {
    await _setupNotifications();
  }

  // The pet never hosts playback; every other window may.
  if (!isPetWindow) {
    try {
      VidraPlayerKit.ensureInitialized();
      // AFTER ensureInitialized, which registers the stock adapter — this
      // replaces it so the stream fetch presents the same browser the rest of
      // the app does. Same label, so nothing downstream reads a different
      // engine than the one actually playing.
      VidraPlayer.setPlayerFactory(
        BrowserHeaderPlayerAdapter.new,
        adapterLabel: 'fvp',
      );
    } catch (e) {
      logR('Main', 'Error initializing VidraPlayerKit: $e');
    }
  }

  // 2. Data layers — every engine, the pet included: MyApp's provider shell
  // (theme, router) reads the database provider unconditionally, and the pet
  // itself writes its parked position through the settings repository.
  final database = AppDatabase();
  final settingsRepository = SettingsRepository(database);
  final appSettings = await settingsRepository.getSettings();

  // Before the window configurations resolve: the background-effect builders
  // read this synchronously, and seeding it here is what keeps an Intel Mac
  // from flashing acrylic for a frame before the setting loads.
  ReduceEffects.seed(appSettings);
  // Same reason and the same moment: the launch sites are tap handlers with
  // no time to await a database, and this runs in every engine — including
  // the player's own window, where "open in this window" has to resolve the
  // same way it did on the page that opened it.
  PlayerWindow.seed(appSettings);

  final initialDataSourceId =
      appSettings.lastDataSourceId ?? kDefaultDataSourceId;
  final savedLocale = appSettings.locale;
  final initialThemeMode = appSettings.themeMode;

  final container = ProviderContainer(
    overrides: [
      appDatabaseProvider.overrideWithValue(database),
      initialDataSourceIdProvider.overrideWithValue(initialDataSourceId),
      initialDisabledDataSourceIdsProvider.overrideWithValue(
        parseSourceIds(appSettings.disabledDataSourceIds),
      ),
      initialThemeModeProvider.overrideWithValue(
        initialThemeMode,
      ), // Override theme
    ],
  );

  // 3. Services initialization
  //
  // The pet's tree never touches download state, so its engine does not even
  // construct the manager — and a stray future read would still be safe, just
  // empty. A player engine reads the persisted tasks synchronously (allTasks,
  // to map completed downloads onto their on-disk files), so secondary
  // engines still load the list once but skip the drift watch and the queue.
  if (!isPetWindow) {
    await container
        .read(downloadManagerProvider)
        .initialize(startProcessing: isMainWindow, watchDb: isMainWindow);
  }

  WindowHelper.init(container.read(settingsRepositoryProvider));

  void startApp() {
    runBitsdojoWindowApp(
      routes: {
        'player': (context, arguments) =>
            VideoPlayerWindowApp(arguments: arguments),
        PetWindowLauncher.windowName: (context, arguments) =>
            PetWindowApp(arguments: arguments),
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

  // Diagnostics wrap the app rather than sitting beside it, so an error that
  // escapes a widget still gets reported. The pet is left out: it is a sprite
  // in a window, it was just cut down to the smallest boot in the app, and a
  // third Sentry client per process buys nothing. Only the main engine may
  // arm the native crash handler — that one is process-global.
  if (isPetWindow || !appSettings.telemetryEnabled) {
    startApp();
    return;
  }

  // The real version, not AppConfig's: that constant says 1.0.0 and has since
  // 1.0.0, and a report that lies about its version cannot answer whether a
  // fix reached the machine that needed it.
  final packageInfo = await PackageInfo.fromPlatform();

  await Telemetry.run(
    windowKind: isMainWindow ? 'main' : 'player',
    userOptedIn: true,
    isMainEngine: isMainWindow,
    release: 'vidra@${packageInfo.version}+${packageInfo.buildNumber}',
    deviceTags: Telemetry.deviceTags(reduceEffects: ReduceEffects.current),
    appRunner: startApp,
  );
}

List<WindowConfiguration> _buildWindowConfigurations() {
  // No pop-in on Windows either. It animates size AND position at the moment
  // the window first composites, and this codebase already documents that
  // exact pattern producing a white DWM flash there — the PiP path avoids it
  // for the same reason. On a window that is slow to present its first frame
  // the "flash" is simply what you are left looking at.
  final readyAnimation = Platform.isLinux || Platform.isWindows
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
      // Only re-assert the size on the CENTERED path. With a restored
      // position the alignment below resolves null, and the size setter's
      // no-alignment branch passes logical pixels straight to SetWindowPos —
      // no DPI scaling — so re-applying there halves the window on a scaled
      // display. The native factory already sized the window at creation;
      // there is nothing to re-apply.
      sizeBuilder: (_) async =>
          await WindowHelper.savedPlayerPosition() == null
          ? WindowHelper.playerSize()
          : null,
      minSize: AppConfig.playerMiniSize,
      // Center only when no position survived — a non-null alignment here
      // would re-center the window on ready and discard the restored
      // top-left passed to openNewWindow.
      alignmentBuilder: (_) async =>
          await WindowHelper.savedPlayerPosition() == null
          ? Alignment.center
          : null,
      backgroundEffectBuilder: _resolveBackgroundEffect,
      alwaysOnTop: false,
      buttonVisibilityBuilder: _resolvePlayerButtonVisibility,
      readyAnimation: readyAnimation,
    ),
    WindowConfiguration(
      name: PetWindowLauncher.windowName,
      title: 'Vidra Pet',
      // No size and no alignment on purpose. The native factory already
      // sized and placed the window from openNewWindow; re-applying either
      // here would discard the position the pet was opened at — and on a
      // scaled Windows display the size setter's no-alignment branch skips
      // DPI scaling, which halves the window (see the player config above).
      backgroundEffect: WindowEffect.transparent,
      alwaysOnTop: true,
      hasShadow: false,
      titleBarHeight: 0,
      buttonVisibility: const {
        DesktopWindowButton.close: false,
        DesktopWindowButton.minimize: false,
        DesktopWindowButton.zoom: false,
      },
      readyAnimation: const WindowReadyAnimation.none(),
      // These two prints bracket the whole native-handle dance: between
      // "engine up" and "config applied" sits windowReady delivery,
      // every geometry/effect setter and the show() call. The 1.11.x
      // invisible pet was diagnosed by which bracket was missing.
      beforeApply: (_) => logR('Pet', 'config apply begins (handle ready)'),
      afterApply: (_) => logR('Pet', 'config applied — window shown'),
    ),
    WindowConfiguration(
      backgroundEffectBuilder: _resolveBackgroundEffect,
      alwaysOnTop: false,
      readyAnimation: readyAnimation,
    ),
  ];
}

WindowEffect _resolveBackgroundEffect(DesktopWindow window) {
  if (!platformWindowCapabilities.supportsBackgroundEffects) {
    return WindowEffect.disabled;
  }
  // Acrylic makes the HWND's background non-opaque through a DWM composition
  // attribute. Behind a video that is worth nothing — the picture covers the
  // window — and a non-opaque window that has not yet presented a frame is
  // exactly what shows up as a blank white sheet in the taskbar preview.
  // macOS keeps it only for the catalog: its blur is behind the catalog's
  // glass, where it reads. The player's Scaffold is opaque black, so behind
  // it the blur is invisible yet WindowServer still recomputes it every
  // frame — the picture covers that window on every platform.
  if (Platform.isWindows) return WindowEffect.disabled;
  if (window.name == 'player') return WindowEffect.disabled;
  // 减少特效: the desktop blur plus full-window alpha compositing is the
  // single largest standing GPU cost on the machines this switch exists for.
  if (ReduceEffects.current) return WindowEffect.disabled;
  return WindowEffect.acrylic;
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

    // The OS draws this one, which is why it needs no BuildContext.
    //
    // The Flutter dialog it replaces had to go hunting for a context — the
    // router's navigator, falling back to whatever the callback was handed —
    // because this runs while the window is being torn down, and the tree
    // that would host a dialog is exactly what is going away. A native alert
    // has no such dependency: it is not part of the scene it is asking about.
    final shouldClose = await appWindow.showNativeConfirm(
      title: tr('dashboard.exit_dialog.title'),
      message: tr('dashboard.exit_dialog.content'),
      confirmLabel: tr('dashboard.exit_dialog.confirm'),
      cancelLabel: tr('dashboard.exit_dialog.cancel'),
    );

    if (mounted) {
      setState(() {
        _isExitDialogShowing = false;
      });
    } else {
      _isExitDialogShowing = false;
    }

    // A confirmed exit closes every window; the pet's close broadcast must
    // not land on the dying main engine and record "the user closed the pet"
    // — that write would stop the pet auto-restoring next launch.
    if (shouldClose) {
      petWindowClosedSub?.cancel();
      petWindowClosedSub = null;
    }

    return shouldClose;
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
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
