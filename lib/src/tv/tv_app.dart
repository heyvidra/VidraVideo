import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vidra_player/vidra_player.dart' show VidraPlayer;
import 'package:vidra_player_kit/vidra_player_kit.dart';

import '../config/app_theme.dart';
import '../config/player_window_mode.dart';
import '../config/reduce_effects.dart';
import '../core/network/browser_identity.dart';
import '../core/network/player_browser_headers.dart';
import '../core/utils/log.dart';
import '../data/database/app_database.dart';
import '../data/database/app_database_provider.dart';
import '../features/settings/data/settings_repository.dart';
import '../features/settings/domain/app_settings.dart' show parseSourceIds;
import '../features/video/data/video_repository.dart';
import '../features/video/presentation/video_player_screen.dart';
import 'tv_screens.dart';

/// Android TV boot. The desktop boot in main.dart is window management from
/// the first line (bitsdojo, pet, notifications); none of that exists here,
/// so this is the same data layer under a remote-driven shell.
///
/// ponytail: no downloads, cast, subscriptions refresh or telemetry on TV v1 —
/// add each when someone asks for it on a couch.
Future<void> runTvApp() async {
  WidgetsFlutterBinding.ensureInitialized();
  BrowserIdentity.seed();
  // No bars on a TV; on a tablet this is what makes it look like one.
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  final database = AppDatabase();
  final settingsLoad = SettingsRepository(database).getSettings();
  await Future.wait([settingsLoad, EasyLocalization.ensureInitialized()]);
  final settings = await settingsLoad;

  try {
    VidraPlayerKit.ensureInitialized();
    VidraPlayer.setPlayerFactory(
      BrowserHeaderPlayerAdapter.new,
      adapterLabel: 'fvp',
    );
  } catch (e) {
    logR('TV', 'player init failed: $e');
  }

  ReduceEffects.seed(settings);
  // One window, one engine: playback is always a route.
  PlayerWindow.inApp = true;

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('zh'), Locale('en')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      startLocale: settings.locale != null ? Locale(settings.locale!) : null,
      child: ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(database),
          initialDataSourceIdProvider.overrideWithValue(
            settings.lastDataSourceId ?? kDefaultDataSourceId,
          ),
          initialDisabledDataSourceIdsProvider.overrideWithValue(
            parseSourceIds(settings.disabledDataSourceIds),
          ),
        ],
        child: const _TvApp(),
      ),
    ),
  );
}

// Not a ShellRoute: that nests a Navigator, a Navigator is a focus scope, and
// directional focus does not leave its scope — "left" could never reach the
// rail. Each tab carries the rail itself, in the same scope as its content.
GoRoute _tab(String path, Widget screen) => GoRoute(
  path: path,
  pageBuilder: (_, _) => NoTransitionPage(
    child: TvShell(location: path, child: screen),
  ),
);

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    _tab('/', const TvHomeScreen()),
    _tab('/search', const TvSearchScreen()),
    _tab('/recent', const TvRecentScreen()),
    _tab('/favorites', const TvFavoritesScreen()),
    _tab('/settings', const TvSettingsScreen()),
    GoRoute(
      path: '/detail/:id',
      builder: (_, state) => TvDetailScreen(
        videoId: int.tryParse(state.pathParameters['id']!) ?? -1,
        sourceId: state.uri.queryParameters['sourceId'],
      ),
    ),
    // Same path and query as the desktop router, so PlayerLauncher-style
    // locations mean the same thing on both.
    GoRoute(
      path: '/player/:id',
      builder: (_, state) => VideoPlayerScreen(
        videoId: state.pathParameters['id']!,
        sourceId: state.uri.queryParameters['sourceId'],
        initialEpisodeIndex:
            int.tryParse(state.uri.queryParameters['index'] ?? '0') ?? 0,
      ),
    ),
  ],
);

class _TvApp extends StatelessWidget {
  const _TvApp();

  @override
  Widget build(BuildContext context) {
    // D-pad arrows and the centre button already map to directional focus and
    // ActivateIntent in WidgetsApp's default shortcuts — no key code here.
    return MaterialApp.router(
      title: 'Vidra',
      // A TV is a dark room; the light theme stays on the desk.
      theme: AppTheme.darkTheme,
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
    );
  }
}
