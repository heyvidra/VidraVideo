import 'package:flutter/material.dart';
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

CustomTransitionPage myTransitionPage(Widget child) {
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
      GoRoute(
        path: '/player/:id', // Fullscreen player outside shell
        pageBuilder: (context, state) {
          final id = state.pathParameters['id']!;
          final sourceId = state.uri.queryParameters['sourceId'];
          final index =
              int.tryParse(state.uri.queryParameters['index'] ?? '0') ?? 0;
          return myTransitionPage(
            VideoPlayerScreen(
              videoId: id,
              sourceId: sourceId,
              initialEpisodeIndex: index,
            ),
          );
        },
      ),
    ],
  );
});
