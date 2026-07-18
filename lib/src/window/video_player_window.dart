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

  Future<bool> _handleCloseRequest(BuildContext context, DesktopWindow window) {
    return _closeController.requestClose();
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
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_videoId == null) {
      return Scaffold(
        // backgroundColor: Colors.black,
        body: Center(
          child: Text(
            tr('common.waiting_for_video'),
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
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
          key: ValueKey('$_videoId-$_sourceId'),
          videoId: _videoId!,
          sourceId: _sourceId,
          initialEpisodeIndex: _episodeIndex,
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
