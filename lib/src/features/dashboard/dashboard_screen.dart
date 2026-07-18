import 'dart:io';

import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../video/presentation/play_history_provider.dart';
import 'widgets/sidebar.dart';
import 'domain/app_navigation_item.dart';
import 'package:vidra/src/features/dashboard/widgets/titlebar.dart';

const _desktopTitleBarHeight = 65.0;

class DashboardScreen extends ConsumerStatefulWidget {
  final Widget child;
  const DashboardScreen({super.key, required this.child});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // When the main window gains focus again (e.g. after closing the player window)
    if (state == AppLifecycleState.resumed) {
      ref.read(playHistoryProvider.notifier).manualRefresh();
    }
  }

  int _getCurrentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location == '/') return 0;
    if (location.startsWith('/downloads')) return 1;
    if (location.startsWith('/download-url')) return 4;
    if (location.startsWith('/recent')) return 2;
    if (location.startsWith('/settings')) return 3;
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
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: WindowBorder(
        color: Colors.transparent,
        width: 1,
        child: Row(
          children: [
            Sidebar(
              selectedIndex: _getCurrentIndex(context),
              onDestinationSelected: (index) =>
                  _onDestinationSelected(context, index),
            ),
            Expanded(
              child: Column(
                children: [
                  Platform.isMacOS
                      ? SizedBox(
                          height: _desktopTitleBarHeight,
                          child: MoveWindow(
                            child: Padding(
                              padding: const EdgeInsets.only(
                                right: 16,
                                top: 10,
                                bottom: 10,
                              ),
                              child: DashboardTitleBar(
                                onSearchSubmitted: (value) {
                                  if (value.isNotEmpty) {
                                    context.push('/search/$value');
                                  }
                                },
                                onHomeRequested: () {
                                  context.go('/');
                                },
                              ),
                            ),
                          ),
                        )
                      : SizedBox(
                          height: _desktopTitleBarHeight,
                          child: WindowTitleBarBox(
                            child: Padding(
                              padding: const EdgeInsets.only(
                                left: 16,
                                right: 16,
                                top: 10,
                                bottom: 10,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: MoveWindow(
                                      child: DashboardTitleBar(
                                        onSearchSubmitted: (value) {
                                          if (value.isNotEmpty) {
                                            context.push('/search/$value');
                                          }
                                        },
                                        onHomeRequested: () {
                                          context.go('/');
                                        },
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const WindowButtons(),
                                ],
                              ),
                            ),
                          ),
                        ),
                  Expanded(child: widget.child),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final buttonColors = WindowButtonColors(
  iconNormal: const Color(0xFF805306),
  mouseOver: const Color(0xFFF6A00C),
  mouseDown: const Color(0xFF805306),
  iconMouseOver: const Color(0xFF805306),
  iconMouseDown: const Color(0xFFFFD500),
);

final closeButtonColors = WindowButtonColors(
  mouseOver: const Color(0xFFD32F2F),
  mouseDown: const Color(0xFFB71C1C),
  iconNormal: const Color(0xFF805306),
  iconMouseOver: Colors.white,
);

class WindowButtons extends StatefulWidget {
  const WindowButtons({super.key});

  @override
  State<WindowButtons> createState() => _WindowButtonsState();
}

class _WindowButtonsState extends State<WindowButtons> {
  void maximizeOrRestore() {
    setState(() {
      appWindow.maximizeOrRestore();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        MinimizeWindowButton(colors: buttonColors),
        appWindow.isMaximized
            ? RestoreWindowButton(
                colors: buttonColors,
                onPressed: maximizeOrRestore,
              )
            : MaximizeWindowButton(
                colors: buttonColors,
                onPressed: maximizeOrRestore,
              ),
        CloseWindowButton(colors: closeButtonColors),
      ],
    );
  }
}
