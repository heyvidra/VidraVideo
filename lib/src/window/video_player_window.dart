import 'package:easy_localization/easy_localization.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_theme.dart';
import '../core/providers/theme_provider.dart';
import '../features/video/presentation/video_player_screen.dart';
import '../core/utils/window.dart';

import '../config/no_scrollbar_behavior.dart';

class VideoPlayerWindowCloseController {
  Future<bool> Function()? _handler;

  void bind(Future<bool> Function() handler) {
    _handler = handler;
  }

  void unbind(Future<bool> Function() handler) {
    if (_handler == handler) {
      _handler = null;
    }
  }

  Future<bool> requestClose() async {
    final handler = _handler;
    if (handler == null) return true;
    return handler();
  }
}

class VideoPlayerWindowApp extends ConsumerStatefulWidget {
  final Map<String, dynamic>? arguments;

  const VideoPlayerWindowApp({super.key, this.arguments});

  @override
  ConsumerState<VideoPlayerWindowApp> createState() =>
      _VideoPlayerWindowAppState();
}

class _VideoPlayerWindowAppState extends ConsumerState<VideoPlayerWindowApp> {
  final _closeController = VideoPlayerWindowCloseController();
  Map<String, dynamic>? _currentArguments;

  @override
  void initState() {
    super.initState();
    _currentArguments = widget.arguments ?? appWindow.arguments;
  }

  Future<bool> _handleCloseRequest(
    BuildContext context,
    DesktopWindow window,
  ) async {
    final allow = await _closeController.requestClose();
    if (allow) {
      // Final frame, written before this engine (and its debounce timers)
      // dies. Also the only capture point for pure window moves — dragging
      // the window emits no metric events.
      await WindowHelper.saveNow();
    }
    return allow;
  }

  void _handleArgumentsChanged(DesktopWindow window) {
    if (!mounted) return;
    setState(() {
      _currentArguments = window.arguments ?? widget.arguments;
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Vidra Player',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      scrollBehavior: NoScrollbarBehavior(),
      builder: (context, child) {
        return WindowEventListener(
          onCloseRequested: _handleCloseRequest,
          onArgumentsChanged: _handleArgumentsChanged,
          rebuildOnArgumentsChanged: false,
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: VideoPlayerWindow(
        arguments: _currentArguments,
        closeController: _closeController,
      ),
    );
  }
}

class VideoPlayerWindow extends StatefulWidget {
  final Map<String, dynamic>? arguments;
  final VideoPlayerWindowCloseController closeController;

  const VideoPlayerWindow({
    super.key,
    this.arguments,
    required this.closeController,
  });

  @override
  State<VideoPlayerWindow> createState() => _VideoPlayerWindowState();
}

class _VideoPlayerWindowState extends State<VideoPlayerWindow>
    with WidgetsBindingObserver {
  String? _videoId;
  String? _sourceId;
  int _episodeIndex = 0;

  /// A stream that exists nowhere in the catalog — a pasted link, parsed but
  /// not downloaded. There is no videoId to resolve, so what the player needs
  /// travels with the launch request instead.
  String? _directUrl;
  String? _directTitle;
  String? _directCoverUrl;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _updateFromArguments(widget.arguments);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didUpdateWidget(VideoPlayerWindow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.arguments != widget.arguments) {
      _updateFromArguments(widget.arguments);
    }
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    WindowHelper.saveWindowSize();
  }

  void _updateFromArguments(Map<String, dynamic>? args) {
    if (args != null) {
      if (args.containsKey('videoId')) {
        _videoId = args['videoId'].toString();
      }
      if (args.containsKey('sourceId')) {
        _sourceId = args['sourceId']?.toString();
      }
      if (args.containsKey('episodeIndex')) {
        _episodeIndex = int.tryParse(args['episodeIndex'].toString()) ?? 0;
      }
      // Read unconditionally: a second launch into the same window must be able
      // to CLEAR these, or a catalog video opened after a pasted link would
      // still play the link.
      _directUrl = args['directUrl']?.toString();
      _directTitle = args['directTitle']?.toString();
      _directCoverUrl = args['directCoverUrl']?.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_videoId == null) {
      return Scaffold(
        // Black, uncommented. A player window has no light state: with this
        // commented out it fell through to the theme's scaffold colour, which
        // after the redesign is 0xFFE7EDF5 — near-white, and indistinguishable
        // from a window that never painted at all. Now the two look different,
        // which is the whole point of having a waiting state.
        backgroundColor: Colors.black,
        body: Center(
          child: Text(
            tr('common.waiting_for_video'),
            style: const TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    // Using Key to force rebuild only when video/source changes.
    //
    // Window dragging is confined to a thin top strip. A whole-surface drag
    // gesture competed with normal player interactions (scrubbing the
    // progress bar IS a pan gesture) and repeatedly launched native
    // window-drag sessions that swallow ALL mouse input for the window —
    // the recurring "controls dead for seconds" freeze. Verified live:
    // every freeze was preceded by a startDragging burst while pointer
    // events stopped reaching Flutter.
    return Stack(
      children: [
        VideoPlayerScreen(
          key: ValueKey('$_videoId-$_sourceId-$_directUrl'),
          videoId: _videoId!,
          sourceId: _sourceId,
          initialEpisodeIndex: _episodeIndex,
          directUrl: _directUrl,
          directTitle: _directTitle,
          directCoverUrl: _directCoverUrl,
          closeController: widget.closeController,
        ),
        // Move handle over the top-bar title area, inset so the close button
        // (left) and the top-bar action buttons (right) stay clickable.
        Positioned(
          top: 0,
          left: 120,
          right: 120,
          height: 26,
          child: MoveWindow(),
        ),
      ],
    );
  }
}
