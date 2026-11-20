import 'package:easy_localization/easy_localization.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vidra_player/vidra_player.dart' show PlayerController;

import '../common/cover_image.dart';
import '../config/app_theme.dart';
import '../features/favorites/presentation/favorites_provider.dart';
import '../features/settings/presentation/settings_provider.dart';
import '../features/video/data/video_repository.dart';
import '../features/video/domain/episode_number.dart';
import '../features/video/domain/play_history.dart';
import '../features/video/domain/resume_target.dart';
import '../features/video/domain/video_collection.dart';
import '../features/video/presentation/play_history_provider.dart';
import '../features/video/presentation/search_history_provider.dart';
import '../features/video/presentation/video_list_provider.dart';
import 'tv_voice.dart';

// Everything on a TV is read from three metres away and driven by five keys.
// So: one focus primitive ([TvFocusable]), one poster grid, and screens that
// are nothing but those two arranged.

const _overscan = 32.0;
const _fg = Colors.white;
const _fgDim = Color(0xA8FFFFFF);

String _playerLocation(int videoId, int index, String? sourceId) => Uri(
  path: '/player/$videoId',
  queryParameters: {'index': '$index', 'sourceId': ?sourceId},
).toString();

String _detailLocation(int videoId, String? sourceId) => Uri(
  path: '/detail/$videoId',
  queryParameters: {'sourceId': ?sourceId},
).toString();

/// The one thing a remote can land on. Grows and rings when focused, and
/// scrolls itself into view — which is the whole of "scrolling" on a TV.
class TvFocusable extends StatefulWidget {
  const TvFocusable({
    super.key,
    required this.onPressed,
    required this.builder,
    this.autofocus = false,
    this.focusNode,
    this.radius = 12,
    this.scale = 1.06,
  });

  final FocusNode? focusNode;

  final VoidCallback onPressed;
  final Widget Function(BuildContext context, bool focused) builder;
  final bool autofocus;
  final double radius;
  final double scale;

  @override
  State<TvFocusable> createState() => _TvFocusableState();
}

class _TvFocusableState extends State<TvFocusable> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(widget.radius);
    return AnimatedScale(
      scale: _focused ? widget.scale : 1,
      duration: const Duration(milliseconds: 120),
      child: InkWell(
        autofocus: widget.autofocus,
        focusNode: widget.focusNode,
        borderRadius: radius,
        focusColor: Colors.transparent,
        onTap: widget.onPressed,
        onFocusChange: (focused) {
          setState(() => _focused = focused);
          if (focused) {
            Scrollable.ensureVisible(
              context,
              alignment: 0.5,
              duration: const Duration(milliseconds: 200),
            );
          }
        },
        child: DecoratedBox(
          position: DecorationPosition.foreground,
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(
              color: _focused ? AppTheme.accent : Colors.transparent,
              width: 3,
            ),
          ),
          child: widget.builder(context, _focused),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.onPressed,
    this.icon,
    this.selected = false,
    this.autofocus = false,
    this.focusNode,
  });

  final FocusNode? focusNode;
  final String label;
  final IconData? icon;
  final bool selected;
  final bool autofocus;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TvFocusable(
      autofocus: autofocus,
      focusNode: focusNode,
      radius: 24,
      onPressed: onPressed,
      builder: (context, focused) {
        final on = focused || selected;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: focused
                ? AppTheme.accent
                : Colors.white.withValues(alpha: selected ? 0.22 : 0.08),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20, color: focused ? Colors.black : _fg),
                const SizedBox(width: 8),
              ],
              // Flexible: a label is translated text of no fixed length, and
              // a pill in a fixed-width rail must clip rather than spill onto
              // the content beside it.
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: on ? FontWeight.w600 : FontWeight.w400,
                    color: focused ? Colors.black : _fg,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------- shell

class TvShell extends StatefulWidget {
  const TvShell({super.key, required this.location, required this.child});

  final String location;
  final Widget child;

  @override
  State<TvShell> createState() => _TvShellState();
}

class _TvShellState extends State<TvShell> {
  static const _items = [
    ('/search', Icons.search_rounded, 'dashboard.search_hint'),
    ('/', Icons.home_rounded, 'navigation.home'),
    ('/recent', Icons.history_rounded, 'navigation.recent'),
    ('/favorites', Icons.bookmark_rounded, 'navigation.favorites'),
    ('/settings', Icons.settings_rounded, 'navigation.settings'),
  ];

  final _nodes = [for (final _ in _items) FocusNode()];
  bool _inRail = false;
  DateTime? _exitArmedAt;

  FocusNode get _currentTab =>
      _nodes[_items.indexWhere((i) => i.$1 == widget.location).clamp(0, 4)];

  /// Back walks out one level at a time, the way a TV app is expected to:
  /// content → the rail → Home → (asked twice) out of the app. Without this
  /// the first Back anywhere on a tab closed the app.
  void _onBack() {
    if (!_inRail) return _currentTab.requestFocus();
    if (widget.location != '/') return context.go('/');
    final armed = _exitArmedAt;
    if (armed != null &&
        DateTime.now().difference(armed) < const Duration(seconds: 2)) {
      SystemNavigator.pop();
      return;
    }
    _exitArmedAt = DateTime.now();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(tr('tv.exit_hint'), textAlign: TextAlign.center),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          width: 320,
        ),
      );
  }

  @override
  void dispose() {
    for (final n in _nodes) {
      n.dispose();
    }
    super.dispose();
  }

  /// Up and down stay in the rail. Left to the framework, "up" from the top
  /// item finds nothing above it in line and falls back to the nearest thing
  /// that is higher on screen at all — a category chip, across the page.
  KeyEventResult _onKey(FocusNode _, KeyEvent event) {
    final step = switch (event.logicalKey) {
      LogicalKeyboardKey.arrowUp => -1,
      LogicalKeyboardKey.arrowDown => 1,
      _ => 0,
    };
    if (step == 0) return KeyEventResult.ignored;
    if (event is KeyUpEvent) return KeyEventResult.handled;
    final at = _nodes.indexWhere((n) => n.hasFocus);
    final to = at + step;
    if (at >= 0 && to >= 0 && to < _nodes.length) _nodes[to].requestFocus();
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _onBack();
      },
      child: _buildShell(context),
    );
  }

  Widget _buildShell(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkScaffoldBg,
      body: Padding(
        padding: const EdgeInsets.all(_overscan),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              // Wide enough for the longest label in either language
              // ("Continue Watching") at rest and focused.
              width: 196,
              child: Focus(
                canRequestFocus: false,
                skipTraversal: true,
                onKeyEvent: _onKey,
                // Coming in from the content lands on the tab you are on, not
                // on whichever pill happened to be level with the card you
                // left — the rail should always open where you are.
                onFocusChange: (has) {
                  if (has && !_inRail) _currentTab.requestFocus();
                  _inRail = has;
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(left: 8),
                      child: Text(
                        'Vidra',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.accent,
                        ),
                      ),
                    ),
                    // Which catalog this is: the same title plays differently
                    // per source, and the switch is three screens away.
                    Padding(
                      padding: const EdgeInsets.only(left: 8, bottom: 20),
                      child: Consumer(
                        builder: (context, ref, _) => Text(
                          ref.watch(activeDataSourceProvider).name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, color: _fgDim),
                        ),
                      ),
                    ),
                    for (final (i, (path, icon, key)) in _items.indexed)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _Pill(
                          focusNode: _nodes[i],
                          icon: icon,
                          label: tr(key),
                          selected: widget.location == path,
                          onPressed: () => context.go(path),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 24),
            Expanded(child: widget.child),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- posters

typedef TvPoster = ({
  String title,
  String? subtitle,
  String coverUrl,
  String? sourceId,
  double progress,
  VoidCallback onPressed,
});

TvPoster _posterOf(BuildContext context, Video v) => (
  title: v.title,
  subtitle: v.remarks,
  coverUrl: v.coverUrl,
  sourceId: v.sourceId,
  progress: 0,
  onPressed: () => context.push(_detailLocation(v.apiId, v.sourceId)),
);

class TvPosterGrid extends ConsumerWidget {
  const TvPosterGrid({
    super.key,
    required this.posters,
    this.onNearEnd,
    this.autofocusFirst = false,
    this.header,
  });

  /// Scrolls away with the grid — a TV screen is 540 points tall, and a row
  /// pinned above the posters would cost a third of them.
  final Widget? header;
  final List<TvPoster> posters;
  final VoidCallback? onNearEnd;
  final bool autofocusFirst;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(videoRepositoryProvider);
    return CustomScrollView(
      slivers: [
        if (header != null) SliverToBoxAdapter(child: header),
        SliverPadding(
          // Room for the focused card to grow without being clipped.
          padding: const EdgeInsets.all(14),
          sliver: _grid(repo),
        ),
      ],
    );
  }

  Widget _grid(VideoRepository repo) {
    return SliverGrid.builder(
      // Five across: at a TV's 960 points six left each title ~5 characters.
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        childAspectRatio: 0.55,
        crossAxisSpacing: 18,
        mainAxisSpacing: 18,
      ),
      itemCount: posters.length,
      itemBuilder: (context, i) {
        if (onNearEnd != null && i >= posters.length - 6) {
          // Not during build: this ends in a provider write.
          WidgetsBinding.instance.addPostFrameCallback((_) => onNearEnd!());
        }
        final p = posters[i];
        return TvFocusable(
          autofocus: autofocusFirst && i == 0,
          onPressed: p.onPressed,
          builder: (context, focused) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CoverImage(
                        imageUrl: p.coverUrl.startsWith('http')
                            ? p.coverUrl
                            : repo.resolveUrl(p.coverUrl, sourceId: p.sourceId),
                        memCacheWidth: 400,
                        errorWidget: const ColoredBox(color: Color(0x14FFFFFF)),
                      ),
                      if (p.progress > 0)
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: LinearProgressIndicator(
                            value: p.progress,
                            minHeight: 4,
                            color: AppTheme.accent,
                            backgroundColor: Colors.black54,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(6, 8, 6, 2),
                child: Text(
                  p.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 15, color: _fg),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(6, 0, 6, 6),
                child: Text(
                  p.subtitle ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: _fgDim),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Message extends StatelessWidget {
  const _Message(this.text, {this.onRetry});

  final String text;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, color: _fgDim),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 20),
            _Pill(
              label: tr('common.retry'),
              icon: Icons.refresh_rounded,
              autofocus: true,
              onPressed: onRetry!,
            ),
          ],
        ],
      ),
    );
  }
}

const _loading = Center(child: CircularProgressIndicator());

// ---------------------------------------------------------------- home

class TvHomeScreen extends ConsumerWidget {
  const TvHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider);
    final filter = ref.watch(videoListFilterProvider);
    final list = ref.watch(videoListProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 64,
          child: categories.when(
            loading: () => const SizedBox.shrink(),
            error: (e, _) => _Message(
              tr('video.list.categories_failed'),
              onRetry: () => ref.invalidate(categoriesProvider),
            ),
            data: (cats) => ListView.separated(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              padding: const EdgeInsets.all(8),
              itemCount: cats.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, i) {
                final c = cats[i];
                return _Pill(
                  autofocus: i == 0,
                  label: c.name,
                  selected: c.id == filter.category.id,
                  onPressed: () =>
                      ref.read(videoListFilterProvider.notifier).state =
                          VideoListFilter(category: c),
                );
              },
            ),
          ),
        ),
        Expanded(
          child: list.videos.isEmpty
              ? (list.error != null
                    ? _Message(
                        tr('common.error', args: ['${list.error}']),
                        onRetry: () =>
                            ref.read(videoListProvider.notifier).refresh(),
                      )
                    : list.isLoading
                    ? _loading
                    : _Message(tr('search.no_results')))
              : TvPosterGrid(
                  header: const _ContinueRow(),
                  posters: [for (final v in list.videos) _posterOf(context, v)],
                  onNearEnd: () =>
                      ref.read(videoListProvider.notifier).loadNextPage(),
                ),
        ),
      ],
    );
  }
}

/// The last few things watched, one press from playing again. On a TV this is
/// what most sessions open the app for.
class _ContinueRow extends ConsumerWidget {
  const _ContinueRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // One card per show: watched on two catalogs it is two history rows, and
    // the list is newest first, so the first one seen is the one to resume.
    final seen = <String>{};
    final items = [
      for (final r
          in ref.watch(visiblePlayHistoryProvider).value ??
              const <RecentPlayback>[])
        if (seen.add(crossSourceKey(r.video.videoTitle, r.video.year))) r,
    ].take(8).toList();
    if (items.isEmpty) return const SizedBox.shrink();
    final repo = ref.watch(videoRepositoryProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
          child: Text(
            tr('navigation.recent'),
            style: const TextStyle(fontSize: 15, color: _fgDim),
          ),
        ),
        SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            padding: const EdgeInsets.all(14),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(width: 14),
            itemBuilder: (context, i) {
              final v = items[i].video;
              return TvFocusable(
                radius: 10,
                onPressed: () async {
                  await context.push(
                    _playerLocation(v.videoId, v.lastEpisodeIndex, v.sourceId),
                  );
                  ref.invalidate(playHistoryProvider);
                },
                builder: (context, focused) => Container(
                  width: 210,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Row(
                    children: [
                      CoverImage(
                        imageUrl: v.coverUrl.startsWith('http')
                            ? v.coverUrl
                            : repo.resolveUrl(v.coverUrl, sourceId: v.sourceId),
                        width: 50,
                        height: 72,
                        memCacheWidth: 200,
                        errorWidget: const ColoredBox(color: Color(0x14FFFFFF)),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                v.videoTitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: _fg,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isEpisodicType(v.type)
                                    ? episodeLabel(
                                        v.lastEpisodeTitle,
                                        index: v.lastEpisodeIndex,
                                      )
                                    : (v.remarks ?? ''),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: _fgDim,
                                ),
                              ),
                              const SizedBox(height: 8),
                              LinearProgressIndicator(
                                value: items[i].progress,
                                minHeight: 3,
                                color: AppTheme.accent,
                                backgroundColor: Colors.white12,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------- search

class TvSearchScreen extends ConsumerStatefulWidget {
  const TvSearchScreen({super.key});

  @override
  ConsumerState<TvSearchScreen> createState() => _TvSearchScreenState();
}

class _TvSearchScreenState extends ConsumerState<TvSearchScreen> {
  String _keyword = '';
  final _text = TextEditingController();
  bool _voice = false;
  PhoneInput? _phone;
  bool _phoneDialogUp = false;

  @override
  void initState() {
    super.initState();
    TvVoice.available().then((v) {
      if (mounted && v) setState(() => _voice = true);
    });
  }

  @override
  void dispose() {
    _phone?.close();
    _text.dispose();
    super.dispose();
  }

  Future<void> _listen() async {
    final text = await TvVoice.listen(
      context.locale.languageCode == 'zh' ? 'zh-CN' : 'en-US',
    );
    if (text != null && mounted) _search(text);
  }

  /// The server outlives the dialog on purpose: once the phone has the page
  /// open, it stays a keyboard for this screen — each send is a new search,
  /// with no second scan.
  Future<void> _showPhone() async {
    final messenger = ScaffoldMessenger.of(context);
    final phone = _phone ??= await PhoneInput.start((keyword) {
      if (!mounted) return;
      if (_phoneDialogUp) Navigator.of(context, rootNavigator: true).pop();
      _search(keyword);
    });
    if (!mounted) return;
    if (phone == null) {
      messenger.showSnackBar(
        SnackBar(content: Text(tr('tv.phone_no_network'))),
      );
      return;
    }
    _phoneDialogUp = true;
    await showDialog<void>(
      context: context,
      builder: (_) => PhoneInputDialog(url: phone.url),
    );
    _phoneDialogUp = false;
  }

  void _search(String value) {
    final keyword = value.trim();
    if (keyword.isNotEmpty) {
      ref.read(searchHistoryProvider.notifier).push(keyword);
    }
    _text.text = keyword;
    setState(() => _keyword = keyword);
  }

  /// Typing on a remote is the worst thing a TV asks of anyone, so a search
  /// already made is one press instead of a keyboard.
  Widget _history() {
    final history = ref.watch(searchHistoryProvider).value ?? const [];
    if (history.isEmpty) return _Message(tr('search.prompt'));
    return Align(
      alignment: Alignment.topLeft,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final k in history)
              _Pill(
                icon: Icons.history_rounded,
                label: k,
                onPressed: () => _search(k),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final results = _keyword.isEmpty
        ? null
        : ref.watch(crossSearchProvider(_keyword));
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          // A focused text field eats the arrow keys for its caret, which on a
          // remote means focus can never leave it. Vertical arrows are no use
          // in a one-line field, so they go back to focus traversal.
          child: Focus(
            canRequestFocus: false,
            onKeyEvent: (node, event) {
              if (event is! KeyDownEvent) return KeyEventResult.ignored;
              final direction = switch (event.logicalKey) {
                LogicalKeyboardKey.arrowDown => TraversalDirection.down,
                LogicalKeyboardKey.arrowUp => TraversalDirection.up,
                _ => null,
              };
              if (direction == null) return KeyEventResult.ignored;
              FocusManager.instance.primaryFocus?.focusInDirection(direction);
              return KeyEventResult.handled;
            },
            child: TextField(
              controller: _text,
              textInputAction: TextInputAction.search,
              style: const TextStyle(fontSize: 20, color: _fg),
              decoration: InputDecoration(
                hintText: tr('search.placeholder'),
                prefixIcon: const Icon(Icons.search_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: AppTheme.accent,
                    width: 3,
                  ),
                ),
              ),
              onSubmitted: _search,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 6, 14, 6),
          child: Row(
            children: [
              if (_voice) ...[
                _Pill(
                  icon: Icons.mic_rounded,
                  label: tr('tv.voice'),
                  onPressed: _listen,
                ),
                const SizedBox(width: 12),
              ],
              _Pill(
                icon: Icons.smartphone_rounded,
                label: tr('tv.phone'),
                onPressed: _showPhone,
              ),
            ],
          ),
        ),
        Expanded(
          child: results == null
              ? _history()
              : results.when(
                  loading: () => _loading,
                  error: (e, _) => _Message(tr('search.error', args: ['$e'])),
                  data: (hits) => hits.isEmpty
                      ? _Message(tr('search.no_results'))
                      : TvPosterGrid(
                          // The keyboard just closed; put the remote on the
                          // first answer rather than back in the field.
                          key: ValueKey(_keyword),
                          autofocusFirst: true,
                          posters: [
                            for (final h in hits) _posterOf(context, h.primary),
                          ],
                        ),
                ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------- library

class TvRecentScreen extends ConsumerWidget {
  const TvRecentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(visiblePlayHistoryProvider)
        .when(
          loading: () => _loading,
          error: (e, _) => _Message(tr('common.error', args: ['$e'])),
          data: (items) => items.isEmpty
              ? _Message(tr('recent.empty'))
              : TvPosterGrid(
                  autofocusFirst: true,
                  posters: [
                    for (final r in items)
                      (
                        title: r.video.videoTitle,
                        subtitle: isEpisodicType(r.video.type)
                            ? episodeLabel(
                                r.video.lastEpisodeTitle,
                                index: r.video.lastEpisodeIndex,
                              )
                            : r.video.remarks,
                        coverUrl: r.video.coverUrl,
                        sourceId: r.video.sourceId,
                        progress: r.progress,
                        // Straight back into the episode: this list exists to
                        // be resumed from, and the player's own resume dialog
                        // handles the position.
                        onPressed: () async {
                          await context.push(
                            _playerLocation(
                              r.video.videoId,
                              r.video.lastEpisodeIndex,
                              r.video.sourceId,
                            ),
                          );
                          // Back from the player: order and progress moved.
                          ref.invalidate(playHistoryProvider);
                        },
                      ),
                  ],
                ),
        );
  }
}

class TvFavoritesScreen extends ConsumerWidget {
  const TvFavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(visibleFavoritesProvider)
        .when(
          loading: () => _loading,
          error: (e, _) => _Message(tr('common.error', args: ['$e'])),
          data: (videos) => videos.isEmpty
              ? _Message(
                  '${tr('favorites.empty')}\n${tr('favorites.empty_hint')}',
                )
              : TvPosterGrid(
                  autofocusFirst: true,
                  posters: [for (final v in videos) _posterOf(context, v)],
                ),
        );
  }
}

// ---------------------------------------------------------------- detail

class TvDetailScreen extends ConsumerWidget {
  const TvDetailScreen({super.key, required this.videoId, this.sourceId});

  final int videoId;
  final String? sourceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = (id: videoId, sourceId: sourceId);
    final async = ref.watch(videoByIdProvider(key));
    return Scaffold(
      backgroundColor: AppTheme.darkScaffoldBg,
      body: async.when(
        loading: () => _loading,
        error: (e, _) => _Message(
          tr('video.detail.error', args: ['$e']),
          onRetry: () => ref.invalidate(videoByIdProvider(key)),
        ),
        data: (video) => video == null
            ? _Message(tr('video.detail.not_found'))
            : _Detail(video: video, sourceId: sourceId),
      ),
    );
  }
}

class _Detail extends ConsumerWidget {
  const _Detail({required this.video, required this.sourceId});

  final Video video;
  final String? sourceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(videoRepositoryProvider);
    final historyKey = (videoId: video.apiId, sourceId: sourceId);
    final histories =
        ref.watch(episodeHistoriesProvider(historyKey)).value ??
        const <int, EpisodeHistory>{};
    final videoHistory = ref.watch(videoHistoryProvider(historyKey)).value;
    final favorited = ref.watch(
      isFavoritedProvider((title: video.title, year: video.year)),
    );

    final episodes = video.urls ?? const <VideoEpisode>[];
    final target = resolveResumeTarget(
      histories: histories,
      lastEpisodeIndex: videoHistory?.lastEpisodeIndex,
      episodeCount: episodes.isEmpty ? null : episodes.length,
    );

    Future<void> play(int index) async {
      await context.push(_playerLocation(video.apiId, index, sourceId));
      // Back from the player: the resume button and the watched marks are
      // both stale now.
      ref.invalidate(episodeHistoriesProvider(historyKey));
      ref.invalidate(videoHistoryProvider(historyKey));
      ref.invalidate(playHistoryProvider);
    }

    String label(int i) => episodeLabel(episodes[i].title, index: i);

    final cover = video.coverUrl.startsWith('http')
        ? video.coverUrl
        : repo.resolveUrl(video.coverUrl, sourceId: video.sourceId);
    final meta = [
      if (video.rating > 0) '★ ${video.rating.toStringAsFixed(1)}',
      video.year,
      video.region,
      video.type,
      video.remarks,
    ].where((s) => s != null && s.isNotEmpty).join('  ·  ');
    final blurb = (video.blurb ?? video.description ?? video.content ?? '')
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .trim();

    return Stack(
      children: [
        // The cover again, washed out behind the page: a wall of flat navy
        // reads as an error screen from across a room.
        Positioned.fill(
          child: Opacity(
            opacity: 0.16,
            child: CoverImage(imageUrl: cover, memCacheWidth: 600),
          ),
        ),
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.0, 0.75],
                colors: [Color(0x000A1220), AppTheme.darkScaffoldBg],
              ),
            ),
          ),
        ),
        _page(
          context,
          ref,
          video,
          cover,
          meta,
          blurb,
          episodes,
          histories,
          target,
          favorited,
          play,
          label,
        ),
      ],
    );
  }

  Widget _page(
    BuildContext context,
    WidgetRef ref,
    Video video,
    String cover,
    String meta,
    String blurb,
    List<VideoEpisode> episodes,
    Map<int, EpisodeHistory> histories,
    ResumeTarget target,
    bool favorited,
    Future<void> Function(int) play,
    String Function(int) label,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(_overscan + 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: CoverImage(
                  imageUrl: cover,
                  width: 220,
                  height: 320,
                  memCacheWidth: 600,
                  errorWidget: const ColoredBox(color: Color(0x14FFFFFF)),
                ),
              ),
              const SizedBox(width: 36),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      video.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w700,
                        color: _fg,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      meta,
                      style: const TextStyle(fontSize: 16, color: _fgDim),
                    ),
                    if ((video.actor ?? '').isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        tr('video.detail.cast_info', args: [video.actor!]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 15, color: _fgDim),
                      ),
                    ],
                    const SizedBox(height: 14),
                    Text(
                      blurb,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.5,
                        color: _fg,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        if (episodes.isNotEmpty)
                          _Pill(
                            autofocus: true,
                            icon: Icons.play_arrow_rounded,
                            label: target.isFirstTime
                                ? tr('video.detail.play_now')
                                // A film's "episodes" are mirrors and dubs;
                                // naming one back reads as nonsense.
                                : isEpisodicType(video.type)
                                ? tr(
                                    'video.detail.continue_watching',
                                    args: [label(target.episodeIndex)],
                                  )
                                : tr('video.detail.continue_watching_short'),
                            onPressed: () => play(target.episodeIndex),
                          ),
                        const SizedBox(width: 16),
                        _Pill(
                          autofocus: episodes.isEmpty,
                          icon: favorited
                              ? Icons.bookmark_rounded
                              : Icons.bookmark_border_rounded,
                          label: tr(
                            favorited ? 'favorites.saved' : 'favorites.save',
                          ),
                          selected: favorited,
                          onPressed: () => ref
                              .read(favoritesProvider.notifier)
                              .toggle(video),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          if (episodes.isEmpty)
            Text(
              tr('video.detail.no_episodes'),
              style: const TextStyle(fontSize: 16, color: _fgDim),
            )
          else
            // ponytail: a Wrap builds every chip up front. Fine into the low
            // hundreds of episodes; a 1000-episode show wants a lazy grid.
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (var i = 0; i < episodes.length; i++)
                  SizedBox(
                    width: 132,
                    child: TvFocusable(
                      radius: 10,
                      onPressed: () => play(i),
                      builder: (context, focused) {
                        final h = histories[i];
                        final watched =
                            h != null &&
                            h.durationMillis > 0 &&
                            h.positionMillis / h.durationMillis >=
                                kEpisodeFinishedRatio;
                        return Container(
                          height: 48,
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            color: focused
                                ? AppTheme.accent
                                : Colors.white.withValues(
                                    alpha:
                                        i == target.episodeIndex &&
                                            !target.isFirstTime
                                        ? 0.22
                                        : 0.08,
                                  ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            label(i),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 15,
                              color: focused
                                  ? Colors.black
                                  : watched
                                  ? _fgDim
                                  : _fg,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- settings

class TvSettingsScreen extends ConsumerWidget {
  const TvSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sources = ref.watch(availableDataSourcesProvider);
    final activeId = ref.watch(activeDataSourceIdProvider);

    Future<void> setLocale(String code) async {
      await context.setLocale(Locale(code));
      final repo = ref.read(settingsRepositoryProvider);
      final settings = await repo.getSettings();
      settings.locale = code;
      await repo.updateSettings(settings);
    }

    Widget section(String title, List<Widget> pills) => Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, color: _fgDim)),
          const SizedBox(height: 14),
          Wrap(spacing: 14, runSpacing: 14, children: pills),
        ],
      ),
    );

    return ListView(
      children: [
        section(tr('settings.sources.title'), [
          for (final (i, s) in sources.indexed)
            _Pill(
              autofocus: i == 0,
              label: s.name,
              selected: s.id == activeId,
              onPressed: () =>
                  ref.read(activeDataSourceIdProvider.notifier).setSource(s.id),
            ),
        ]),
        section(tr('common.language'), [
          for (final code in const ['zh', 'en'])
            _Pill(
              label: tr('common.$code'),
              selected: context.locale.languageCode == code,
              onPressed: () => setLocale(code),
            ),
        ]),
      ],
    );
  }
}

// ---------------------------------------------------------------- player menu

/// Episodes, quality and source for the playing video, on a remote.
///
/// The player's own panels for these open on hover and are clicked; a remote
/// can do neither. This is a dialog rather than more player chrome because a
/// route has its own focus scope — the arrows move between pills here instead
/// of seeking the video underneath, and Back closes it for free.
Future<void> showTvPlayerMenu(
  BuildContext context, {
  required PlayerController controller,
  Video? video,
  String? sourceId,
}) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black54,
    builder: (_) =>
        _PlayerMenu(controller: controller, video: video, sourceId: sourceId),
  );
}

class _PlayerMenu extends ConsumerStatefulWidget {
  const _PlayerMenu({required this.controller, this.video, this.sourceId});

  final PlayerController controller;
  final Video? video;
  final String? sourceId;

  @override
  ConsumerState<_PlayerMenu> createState() => _PlayerMenuState();
}

class _PlayerMenuState extends ConsumerState<_PlayerMenu> {
  String? _looking;
  final _absent = <String>{};
  final _failed = <String>{};

  /// Opens the same show on [target], at the same episode NUMBER — the two
  /// catalogs list a show in different orders and lengths, so position in the
  /// list is not the episode.
  Future<void> _switchSource(String target) async {
    final video = widget.video;
    if (video == null || _looking != null) return;
    final router = GoRouter.of(context);
    final navigator = Navigator.of(context);
    setState(() => _looking = target);
    Video? other;
    try {
      other = await ref
          .read(videoRepositoryProvider)
          .findOnSource(sourceId: target, title: video.title, year: video.year);
    } catch (_) {
      // A failed lookup is not "this catalog does not have it": say retry,
      // and leave the pill pressable.
      if (!mounted) return;
      setState(() {
        _looking = null;
        _failed.add(target);
      });
      return;
    }
    if (!mounted) return;
    _failed.remove(target);
    final theirs = other?.urls ?? const <VideoEpisode>[];
    if (other == null || theirs.isEmpty) {
      setState(() {
        _looking = null;
        _absent.add(target);
      });
      return;
    }
    final episodic = isEpisodicType(video.type);
    final at = widget.controller.media.currentEpisodeIndex;
    final mine = video.urls ?? const <VideoEpisode>[];
    final number = at < mine.length
        ? episodeNumberOf(mine[at].title, index: at, episodic: episodic)
        : null;
    var index = 0;
    if (number != null) {
      for (var i = 0; i < theirs.length; i++) {
        if (episodeNumberOf(theirs[i].title, index: i, episodic: episodic) ==
            number) {
          index = i;
          break;
        }
      }
    }
    navigator.pop();
    router.pushReplacement(_playerLocation(other.apiId, index, target));
  }

  @override
  Widget build(BuildContext context) {
    final media = widget.controller.media;
    final episodes = media.episodes;
    final qualities = media.availableQualities;
    final current = widget.sourceId ?? ref.watch(activeDataSourceIdProvider);
    final sources = widget.video == null
        ? const []
        : ref
              .watch(availableDataSourcesProvider)
              .where((s) => s.id != current)
              .toList();
    // A film's single "episode" is not a choice.
    final showEpisodes = episodes.length > 1;
    // One landing spot: where you are in the first list that is shown.
    final focusQuality = !showEpisodes && qualities.length > 1;
    final focusSource = !showEpisodes && !focusQuality;

    Widget section(String title, List<Widget> pills) => Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, color: _fgDim)),
          const SizedBox(height: 12),
          Wrap(spacing: 12, runSpacing: 12, children: pills),
        ],
      ),
    );

    return Align(
      alignment: Alignment.bottomCenter,
      child: Material(
        color: const Color(0xF20A1220),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.7,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              _overscan + 8,
              28,
              _overscan + 8,
              8,
            ),
            child: SizedBox(
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (showEpisodes)
                    section(tr('video.player.episode_list'), [
                      for (final (i, e) in episodes.indexed)
                        _Pill(
                          autofocus: i == media.currentEpisodeIndex,
                          selected: i == media.currentEpisodeIndex,
                          label: episodeLabel(e.title, index: i),
                          onPressed: () {
                            Navigator.of(context).pop();
                            widget.controller.switchEpisode(i);
                          },
                        ),
                    ]),
                  if (qualities.length > 1)
                    section(tr('video.player.playback_quality'), [
                      for (final (i, q) in qualities.indexed)
                        _Pill(
                          autofocus:
                              focusQuality && i == media.currentQualityIndex,
                          selected: i == media.currentQualityIndex,
                          label: q.label,
                          onPressed: () {
                            Navigator.of(context).pop();
                            widget.controller.switchQuality(i);
                          },
                        ),
                    ]),
                  if (sources.isNotEmpty)
                    section(tr('video.detail.source'), [
                      for (final (i, s) in sources.indexed)
                        _Pill(
                          autofocus: focusSource && i == 0,
                          icon: Icons.swap_horiz_rounded,
                          label: _looking == s.id
                              ? '${s.name} …'
                              : _failed.contains(s.id)
                              ? '${s.name} · ${tr('common.retry')}'
                              : _absent.contains(s.id)
                              ? '${s.name} · ${tr('video.detail.source_absent')}'
                              : s.name,
                          onPressed: () => _switchSource(s.id),
                        ),
                    ]),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Says once, at the start of playback, that the menu exists. Nothing on a
/// remote suggests "down" opens anything.
class TvPlayerHint extends StatefulWidget {
  const TvPlayerHint({super.key});

  @override
  State<TvPlayerHint> createState() => _TvPlayerHintState();
}

class _TvPlayerHintState extends State<TvPlayerHint> {
  bool _visible = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 6), () {
      if (mounted) setState(() => _visible = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Align(
        // Top, not bottom: the bottom is where subtitles are burned in.
        alignment: const Alignment(0, -0.86),
        child: AnimatedOpacity(
          opacity: _visible ? 1 : 0,
          duration: const Duration(milliseconds: 400),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              tr('tv.menu_hint'),
              style: const TextStyle(fontSize: 14, color: _fg),
            ),
          ),
        ),
      ),
    );
  }
}
