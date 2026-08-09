import 'dart:io';

import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:vidra/src/config/ambient_background.dart';
import 'package:vidra/src/config/design_tokens.dart';
import 'package:vidra/src/features/download/data/download_provider.dart';
import 'package:vidra/src/features/download/domain/download_task.dart';
import 'package:vidra/src/features/video/data/video_repository.dart';
import '../subscription/data/subscription_checker.dart';
import '../subscription/presentation/subscription_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../video/presentation/play_history_provider.dart';
import 'widgets/sidebar.dart';
import 'domain/app_navigation_item.dart';
import 'package:vidra/src/features/dashboard/widgets/titlebar.dart';

/// The toolbar pill: the window's top row, with the platform's own window
/// controls sitting on it.
///
/// Its height and top margin are load-bearing on macOS — see
/// `MainFlutterWindow.bitsdojo_window_title_bar_height`, which centres the
/// traffic lights on this pill.
const _pillHeight = 44.0;
const _pillTop = 6.0;

class DashboardScreen extends ConsumerStatefulWidget {
  final Widget child;
  const DashboardScreen({super.key, required this.child});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with WidgetsBindingObserver {
  Timer? _subscriptionTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Followed shows: one sweep now, then occasionally while the window is
    // open. No background service — a desktop app that is not running has
    // nobody to tell, and the checker's own floor keeps repeated triggers from
    // becoming a poll.
    _checkSubscriptions();
    _subscriptionTimer = Timer.periodic(
      const Duration(minutes: 30),
      (_) => _checkSubscriptions(),
    );
  }

  Future<void> _checkSubscriptions() async {
    final updated = await ref.read(subscriptionCheckerProvider).run();
    if (updated.isEmpty || !mounted) return;
    ref.invalidate(subscriptionsProvider);
    await ref.read(subscriptionsProvider.notifier).announceUnread(updated);
  }

  @override
  void dispose() {
    _subscriptionTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // When the main window gains focus again (e.g. after closing the player window)
    if (state == AppLifecycleState.resumed) {
      ref.read(playHistoryProvider.notifier).manualRefresh();
      _checkSubscriptions();
    }
  }

  int _getCurrentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/downloads')) return 1;
    if (location.startsWith('/download-url')) return 4;
    if (location.startsWith('/recent')) return 2;
    if (location.startsWith('/settings')) return 3;
    if (location.startsWith('/subscriptions')) return 5;
    if (location.startsWith('/favorites')) return 6;
    return 0;
  }

  void _onDestinationSelected(BuildContext context, int index) {
    final item = AppNavigationItem.fromBranchIndex(index);
    if (item != null) {
      context.go(item.route);
    }
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    // The one toolbar. A detail page used to bring its own, eight pixels below
    // this one and carrying a second search field.
    final canGoBack =
        location.contains('/detail/') || location.startsWith('/search/');

    return Scaffold(
      // Painted by AmbientBackground instead: every translucent surface in the
      // app is standing in the light it casts, and a Scaffold colour under it
      // would just be a second opaque layer to punch through.
      backgroundColor: Colors.transparent,
      body: AmbientBackground(
        child: WindowBorder(
          color: Colors.transparent,
          width: 1,
          // The window is one column: the toolbar pill, then the rail and the
          // content side by side, then the status line. The rail starts BELOW
          // the toolbar — a full-height rail put the search box in the
          // content's column, where it read as belonging to the page rather
          // than to the window.
          child: Column(
            children: [
              _TopBar(
                showBack: canGoBack,
                onSearchSubmitted: (value) {
                  if (value.isNotEmpty) context.push('/search/$value');
                },
                onHomeRequested: () => context.go('/'),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 0),
                  // Stretch, or the rail sizes to its rows and floats in the
                  // vertical middle of the window.
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Sidebar(
                        selectedIndex: _getCurrentIndex(context),
                        onDestinationSelected: (index) =>
                            _onDestinationSelected(context, index),
                      ),
                      Expanded(child: widget.child),
                    ],
                  ),
                ),
              ),
              const AppStatusBar(),
            ],
          ),
        ),
      ),
    );
  }
}

/// The window's top row: one pill carrying the platform's window controls and
/// the app's own.
///
/// The pill used to sit BELOW a separate 46px strip that held nothing but the
/// traffic lights and the wordmark — two bars of chrome where the window needs
/// one. Every platform's window controls are ON this pill now: macOS centres
/// its traffic lights on it (see [MainFlutterWindow]) at the left, Windows and
/// Linux get theirs at the right, drawn in the app's own icon family.
class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.showBack,
    required this.onSearchSubmitted,
    required this.onHomeRequested,
  });

  final bool showBack;
  final void Function(String) onSearchSubmitted;
  final VoidCallback onHomeRequested;

  @override
  Widget build(BuildContext context) {
    final mac = Platform.isMacOS;
    final bar = DashboardTitleBar(
      showBack: showBack,
      // Nothing of ours may be drawn under the traffic lights.
      leadingInset: mac ? 78 : 14,
      onSearchSubmitted: onSearchSubmitted,
      onHomeRequested: onHomeRequested,
    );

    // MoveWindow alone, without WindowTitleBarBox: that widget's only job is
    // to reserve the platform title-bar HEIGHT, and this row sets its own —
    // wrapped in one, the 44pt pill would be squeezed into Windows' 32pt band.
    //
    // The pill spans the full width on every platform; Windows' own
    // minimise/maximise/close live INSIDE it, after the language switcher,
    // rather than loose in the corner in a different icon family.
    return SizedBox(
      height: _pillTop + _pillHeight + 10,
      child: MoveWindow(
        child: Padding(
          padding: EdgeInsets.fromLTRB(14, _pillTop, 14, 10),
          child: bar,
        ),
      ),
    );
  }
}

/// The strip a desktop app has and a web page does not.
///
/// It answers two questions that otherwise send someone hunting: which catalog
/// am I browsing, and is anything waiting for me. Both were already known to
/// the app and neither had anywhere to be said — the source only showed inside
/// a dropdown, and the unread count only on a nav badge you had to be looking
/// at the sidebar to see.
class AppStatusBar extends ConsumerWidget {
  const AppStatusBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = VidraTokens.of(context);
    final source = ref.watch(activeDataSourceProvider);
    final subs = ref.watch(unreadSubscriptionCountProvider);
    final active = ref
        .watch(downloadTasksProvider)
        .maybeWhen(
          data: (tasks) =>
              tasks.where((t) => t.status == DownloadStatus.downloading).length,
          orElse: () => 0,
        );

    final style = TextStyle(
      fontSize: 10.5,
      height: 1.4,
      letterSpacing: 0.2,
      color: t.fg3,
      fontFeatures: VidraType.data,
    );

    return SizedBox(
      height: 30,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
        child: Row(
          children: [
            Container(
              width: 6,
              height: 6,
              margin: const EdgeInsets.only(right: 7),
              decoration: BoxDecoration(
                color: t.cyan,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: t.cyanGlow, blurRadius: 10)],
              ),
            ),
            Text(source.name, style: style),
            if (active > 0) ...[
              const SizedBox(width: 18),
              Text(
                tr('download.active_count', args: ['$active']),
                style: style,
              ),
            ],
            const Spacer(),
            if (subs > 0)
              Text(
                tr('subscription.updates_waiting', args: ['$subs']),
                style: style.copyWith(color: t.amber),
              ),
          ],
        ),
      ),
    );
  }
}
