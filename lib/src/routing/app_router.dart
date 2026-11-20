import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:vidra/src/features/video/domain/video_collection.dart';
import 'package:vidra/src/features/subscription/presentation/subscription_screen.dart';
import 'package:vidra/src/features/favorites/presentation/favorites_screen.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

// Placeholder for screens
import '../features/video/presentation/video_list_screen.dart';
import '../features/video/presentation/video_detail_screen.dart';
import '../features/video/presentation/video_player_screen.dart';
import '../features/video/presentation/search_screen.dart'; // Search Screen
import '../features/dashboard/dashboard_screen.dart';
import '../features/download/presentation/download_list_screen.dart';
import '../features/download/presentation/download_url_screen.dart';
import '../features/video/presentation/recent_list_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../pet/pet_demo_screen.dart';
import '../config/reduce_effects.dart';

Page<void> myTransitionPage(Widget child) {
  // 减少特效: a cross-fade is 300ms of two full pages composited together.
  if (ReduceEffects.current) return NoTransitionPage(child: child);
  return CustomTransitionPage(
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: animation.drive(
          Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.linear)),
        ),
        child: child,
      );
    },
  );
}

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      ShellRoute(
        builder: (context, state, child) {
          return DashboardScreen(child: child);
        },
        routes: [
          GoRoute(
            path: '/',
            pageBuilder: (context, state) =>
                myTransitionPage(VideoListScreen()),
            routes: [
              GoRoute(
                path: 'detail/:id',
                pageBuilder: (context, state) {
                  final id = state.pathParameters['id']!;
                  final sourceId = state.uri.queryParameters['sourceId'];
                  // The tapped card hands over what it already knows, so the
                  // page can paint the cover before the fetch returns. Null on
                  // a deep link or a restored route, which the screen handles.
                  final seed = state.extra;
                  return myTransitionPage(
                    VideoDetailScreen(
                      videoId: id,
                      sourceId: sourceId,
                      seed: seed is Video ? seed : null,
                    ),
                  );
                },
              ),
            ],
          ),
          GoRoute(
            path: '/downloads',
            pageBuilder: (context, state) =>
                myTransitionPage(DownloadListScreen()),
          ),
          GoRoute(
            path: '/download-url',
            pageBuilder: (context, state) =>
                myTransitionPage(const DownloadUrlScreen()),
          ),
          GoRoute(
            path: '/recent',
            pageBuilder: (context, state) =>
                myTransitionPage(RecentListScreen()),
          ),
          GoRoute(
            path: '/subscriptions',
            pageBuilder: (context, state) =>
                myTransitionPage(const SubscriptionScreen()),
          ),
          GoRoute(
            path: '/favorites',
            pageBuilder: (context, state) =>
                myTransitionPage(const FavoritesScreen()),
          ),
          GoRoute(
            path: '/settings',
            pageBuilder: (context, state) => myTransitionPage(SettingsScreen()),
          ),
          GoRoute(
            path: '/pet-demo',
            pageBuilder: (context, state) =>
                myTransitionPage(const PetDemoScreen()),
          ),
          GoRoute(
            path: '/search/:keyword',
            pageBuilder: (context, state) {
              final keyword = state.pathParameters['keyword']!;
              return myTransitionPage(SearchScreen(keyword: keyword));
            },
          ),
        ],
      ),
      // Outside the shell on purpose: a video does not want the sidebar next
      // to it. This is the whole of "play in this window" — the same screen
      // the player window hosts, mounted in the main engine instead of a
      // second one. See [PlayerWindow] for which machines take this path.
      GoRoute(
        path: '/player/:id',
        pageBuilder: (context, state) {
          final id = state.pathParameters['id']!;
          final q = state.uri.queryParameters;
          final index = int.tryParse(q['index'] ?? '0') ?? 0;
          return myTransitionPage(
            _InAppPlayer(
              child: VideoPlayerScreen(
                videoId: id,
                sourceId: q['sourceId'],
                // A pasted link that was parsed but never downloaded: nothing in
                // the catalog describes it, so its address and titles ride along
                // here exactly as they ride in the window's arguments map.
                directUrl: q['directUrl'],
                directTitle: q['directTitle'],
                directCoverUrl: q['directCoverUrl'],
                initialEpisodeIndex: index,
              ),
            ),
          );
        },
      ),
    ],
  );
});

/// The player as a page of the main window, with a strip to drag it by.
///
/// The main window has no native title bar: it is moved by the catalog's
/// toolbar, and on Windows and Linux that toolbar also carries minimise,
/// maximise and close. This page covers the toolbar, so without a handle of
/// its own a playing window could not be moved at all — and since 1.16.8
/// this page is where low-core Windows machines play by default. Same strip,
/// same height, as the player's own window; double-click maximises.
///
/// ponytail: a drag handle only. Minimise and close stay on the taskbar and
/// the keyboard while a video is up; give this page its own window buttons
/// if that turns out to matter.
class _InAppPlayer extends StatelessWidget {
  const _InAppPlayer({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        // Inset past the back button on the left and the player's own
        // top-bar actions on the right, so both stay clickable.
        Positioned(
          top: 0,
          left: 150,
          right: 120,
          height: 26,
          child: MoveWindow(),
        ),
      ],
    );
  }
}
