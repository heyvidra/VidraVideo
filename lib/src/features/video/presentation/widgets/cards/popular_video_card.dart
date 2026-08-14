import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vidra/src/common/dropdown_menu.dart';
import 'package:vidra/src/common/screen_chrome.dart';
import 'package:vidra/src/config/design_tokens.dart';
import 'package:vidra/src/config/reduce_effects.dart';
import 'package:vidra/src/features/video/data/video_repository.dart';
import 'package:vidra/src/features/video/domain/video_collection.dart';
import 'package:vidra/src/features/video/domain/play_history.dart';
import 'package:vidra/src/features/video/data/history_repository.dart';
import 'package:vidra/src/window/player_window_launcher.dart';
import 'package:vidra/src/features/download/data/download_provider.dart';
import 'package:vidra/src/features/video/presentation/play_history_provider.dart';
import 'package:vidra/src/features/video/domain/episode_number.dart';
import 'package:vidra/src/features/subscription/domain/subscription_identity.dart';
import 'package:vidra/src/features/subscription/presentation/subscription_provider.dart';
import 'package:vidra/src/features/video/data/cross_source_catalog.dart';
import 'package:vidra/src/features/video/presentation/widgets/cross_source_watch_badge.dart';

/// Ties a card's cover to the same image on the detail page it opens.
///
/// Both catalogs return a null backdrop, so the detail header falls back to
/// this exact cover — the flight morphs ONE image rather than cross-fading two
/// different ones, which is the only case where a Hero reads as motion instead
/// of a glitch. Source id is in the tag because the same apiId means different
/// shows on different sources.
String videoPosterHeroTag(Video video) =>
    'poster:${video.sourceId ?? ''}:${video.apiId}';

class PopularVideoCard extends ConsumerStatefulWidget {
  final Video video;
  final bool showDetails;
  final bool enableHover;

  /// Replaces the default "open the detail page" tap. The recent-play list
  /// passes a straight-to-playback action: for a show already in progress the
  /// detail page is a detour, not a destination.
  final VoidCallback? onTap;

  /// How far into the remembered episode, 0..1. Drawn as a hairline across the
  /// bottom of the cover, so "where was I" is answerable without opening it.
  final double? watchProgress;

  /// e.g. "看到 第 5 集" — replaces the catalog's own remarks line, which says
  /// how many episodes exist, not how many you have watched.
  final String? watchLabel;

  /// Replaces the card's own second line. 追更 has something better to say
  /// there than a date — which catalog moved, and how far.
  final String? subtitle;

  /// Overrides the card's own guess. A followed show KNOWS whether it has
  /// gained an episode since you last looked; the catalog can only infer it
  /// from a timestamp.
  final bool? isNew;

  /// An action for this card, in the poster's top-right beside the rating.
  /// Beside, not on top of: the recent list's delete button was drawn over the
  /// rating chip, and both were unreadable.
  final Widget? trailing;

  const PopularVideoCard({
    super.key,
    required this.video,
    this.showDetails = true,
    this.enableHover = true,
    this.onTap,
    this.watchProgress,
    this.watchLabel,
    this.subtitle,
    this.isNew,
    this.trailing,
  });

  @override
  ConsumerState<PopularVideoCard> createState() => _PopularVideoCardState();
}

class _PopularVideoCardState extends ConsumerState<PopularVideoCard>
    with SingleTickerProviderStateMixin {
  /// Corner radius shared by the card, its cover and the chips laid over it —
  /// three different radii on one card is what makes a grid look assembled
  /// rather than designed.
  static const _radius = 14.0;

  /// Where progress and "new" are drawn. Deliberately the two accents that mean
  /// something: cyan is only ever playback progress, amber is only ever "this
  /// gained an episode".
  ///
  /// The DARK variants of both tokens whatever the theme: everything here sits
  /// on a poster under a black scrim, and the light theme's `--cyan` is a deep
  /// teal that disappears against it.
  static const _progressColor = Color(0xFF7BE7F0);
  static const _freshColor = Color(0xFFFFC559);
  static const _onFresh = Color(0xFF38270A);

  bool isHovered = false;

  /// True only while the hover animation is parked at its end. The two-shadow
  /// hover set waits for this instead of following [isHovered]: the resting
  /// shadow is cheap to drag through the scale flight, while a 28px blur under
  /// a card re-rasterizing at a changing scale every frame is not.
  bool _hoverShadowSettled = false;

  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  /// Fades in everything only a hovered card shows; [_restingFade] is its
  /// reverse and fades out the resting bits the hover panel replaces. Both
  /// hang off the one 200ms controller, so a pointer crossing is a repaint of
  /// two opacity layers — not, as it used to be, a teardown and rebuild of the
  /// card's entire element tree on every enter AND exit.
  late CurvedAnimation _hoverFade;
  late Animation<double> _restingFade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _hoverFade = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _restingFade = ReverseAnimation(_hoverFade);
    _controller.addStatusListener(_onHoverStatus);
  }

  void _onHoverStatus(AnimationStatus status) {
    final settled = status == AnimationStatus.completed;
    if (settled != _hoverShadowSettled) {
      setState(() => _hoverShadowSettled = settled);
    }
  }

  @override
  void dispose() {
    // The curve holds a listener on the controller and must go first: a grid
    // scroll disposes cards by the dozen, and a leaked CurvedAnimation per card
    // is exactly the kind of drip nobody notices until a long session.
    _hoverFade.dispose();
    _controller.dispose();
    super.dispose();
  }

  String _formatHits(int? hits) {
    if (hits == null) return '0';
    if (hits < 10000) return hits.toString();

    String format(double n, String suffix) {
      String s = n.toStringAsFixed(1);
      if (s.endsWith('.0')) s = s.substring(0, s.length - 2);
      return '$s$suffix';
    }

    if (hits < 1000000) return format(hits / 1000, 'k');
    if (hits < 1000000000) return format(hits / 1000000, 'm');
    return format(hits / 1000000000, 'b');
  }

  /// "今天 · 更新至第 15 集", or whichever half of it exists.
  ///
  /// Relative for the first two days and absolute after: "3 天前" is a worse
  /// answer than "08-05" once it stops meaning "since you last looked", and a
  /// show that updates weekly is read by its date.
  String _subtitle() {
    if (widget.subtitle != null) return widget.subtitle!;
    final parts = <String>[];
    final t = widget.video.vodTime;
    if (t != null && t > 0) {
      final at = DateTime.fromMillisecondsSinceEpoch(t * 1000);
      final days = DateTime.now().difference(at).inDays;
      parts.add(
        days < 1
            ? tr('common.today')
            : days < 2
            ? tr('common.yesterday')
            : '${at.month.toString().padLeft(2, '0')}-'
                  '${at.day.toString().padLeft(2, '0')}',
      );
    }
    final remarks = widget.video.remarks;
    if (remarks != null && remarks.trim().isNotEmpty) parts.add(remarks.trim());
    // Falls back to the cast rather than to an empty line: a card with a blank
    // second row looks broken, and some catalog rows carry neither date nor
    // progress line.
    if (parts.isEmpty) {
      return widget.video.actor ?? widget.video.blurb ?? '';
    }
    return parts.join(' · ');
  }

  void _openDetail() {
    final sourceId = widget.video.sourceId;
    final path = sourceId != null
        ? '/detail/${widget.video.apiId}?sourceId=$sourceId'
        : '/detail/${widget.video.apiId}';
    context.push(path, extra: widget.video);
  }

  /// The desktop path a click cannot offer: things you want to do TO a show
  /// without opening it.
  ///
  /// Every entry acts on THIS row. The ones that need an episode list — play,
  /// download — fetch the detail when chosen and not before: a menu that
  /// spends a request on a catalog that bans IPs just for being opened is not
  /// a shortcut, but one the user explicitly picked has earned it.
  Future<void> _openMenu(Offset position) async {
    final video = widget.video;
    final following = isShowSubscribed(
      ref.read(subscriptionsProvider).value ?? const [],
      title: video.title,
      year: video.year,
    );
    final elsewhere =
        ref
            .read(
              crossSourceCounterpartsProvider((
                title: video.title,
                year: video.year,
                sourceId: video.sourceId,
              )),
            )
            .value ??
        const <CrossSourceEntry>[];

    // Local DB read, so the menu can name the episode it would resume at
    // without waiting on the network.
    final history = await ref.read(
      videoHistoryProvider((
        videoId: video.apiId,
        sourceId: video.sourceId,
      )).future,
    );
    if (!mounted) return;

    // The app's own menu material, not Material's: showMenu draws a
    // square-cornered sheet with edge-to-edge rows and hard full-bleed
    // dividers, which sat next to this app's own dropdown looking like a
    // different application's widget. Same panel, same rows, opened at the
    // pointer instead of under a trigger.
    final picked = await showVidraMenu<VoidCallback>(
      context: context,
      globalPosition: position,
      builder: (context, select) => [
        PlayerMenuItem(
          text: tr('video.menu.play_latest'),
          onTap: () => select(() => _playEpisode(latest: true)),
        ),
        if (history != null)
          PlayerMenuItem(
            text: tr(
              'video.menu.continue',
              args: [
                episodeLabel(
                  history.lastEpisodeTitle,
                  index: history.lastEpisodeIndex,
                ),
              ],
            ),
            onTap: () =>
                select(() => _playEpisode(index: history.lastEpisodeIndex)),
          ),
        const PlayerMenuDivider(),
        PlayerMenuItem(
          text: following
              ? tr('subscription.unfollow')
              : tr('video.menu.follow'),
          onTap: () => select(
            () => ref.read(subscriptionsProvider.notifier).toggle(video),
          ),
        ),
        PlayerMenuItem(
          text: tr('video.menu.download_season'),
          onTap: () => select(_downloadSeason),
        ),
        // One entry per catalog that also carries this show. Read from the
        // local cache, so an unbrowsed catalog simply does not appear rather
        // than the menu going and looking for one.
        for (final other in elsewhere)
          PlayerMenuItem(
            text: tr(
              'video.detail.open_on_source',
              args: [sourceDisplayName(ref, other.sourceId)],
            ),
            onTap: () => select(
              () => context.push(
                '/detail/${other.videoId}?sourceId=${other.sourceId}',
              ),
            ),
          ),
        const PlayerMenuDivider(),
        PlayerMenuItem(
          text: tr('common.view_details'),
          onTap: () => select(_openDetail),
        ),
        PlayerMenuItem(
          text: tr('video.menu.mark_watched'),
          onTap: () => select(_markWatched),
        ),
        if (history != null)
          PlayerMenuItem(
            text: tr('video.menu.remove_history'),
            onTap: () => select(
              () => ref
                  .read(playHistoryProvider.notifier)
                  .deleteVideoHistory(history.id),
            ),
          ),
      ],
    );
    picked?.call();
  }

  /// Open the player without going through the detail page.
  ///
  /// A catalog row carries no episode list, so this is the one place the menu
  /// reaches the network — once, on an explicit choice.
  Future<void> _playEpisode({int? index, bool latest = false}) async {
    final video = widget.video;
    var episodeIndex = index ?? 0;
    if (latest) {
      final detail = await ref
          .read(videoRepositoryProvider)
          .getVideo(video.apiId, sourceId: video.sourceId);
      final count = detail?.urls?.length ?? 0;
      if (count == 0) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('video.detail.no_episodes_play'))),
        );
        return;
      }
      episodeIndex = count - 1;
    }
    await PlayerWindowLauncher.open(
      videoId: video.apiId,
      episodeIndex: episodeIndex,
      sourceId: video.sourceId,
    );
  }

  /// Mark every episode of this show as finished.
  ///
  /// Writes the same shape playback writes — position == duration — rather
  /// than a separate "watched" flag, so every reader that already knows what
  /// finished looks like (the tile checkmarks, the resume target, the
  /// cross-source badge) picks it up with no new concept. Where an episode
  /// already has a real duration that duration is kept; only the position
  /// moves to the end. Episodes never opened get a 1/1 pair — equal, so the
  /// ratio is 1.0, and overwritten with real numbers the moment one is
  /// actually played.
  ///
  /// Undone by 从历史移除, which is why this asks nothing first.
  Future<void> _markWatched() async {
    final video = widget.video;
    final detail = await ref
        .read(videoRepositoryProvider)
        .getVideo(video.apiId, sourceId: video.sourceId);
    final episodes = detail?.urls ?? const <VideoEpisode>[];
    if (!mounted) return;
    if (episodes.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(tr('video.detail.no_episodes'))));
      return;
    }

    final repository = ref.read(historyRepositoryProvider);
    for (var i = 0; i < episodes.length; i++) {
      final existing = await repository.getEpisodeHistory(
        video.apiId,
        i,
        video.sourceId,
      );
      final duration = (existing?.durationMillis ?? 0) > 0
          ? existing!.durationMillis
          : 1;
      await repository.saveEpisodeHistory(
        EpisodeHistory(
          id: existing?.id ?? 0,
          sourceId: video.sourceId,
          videoId: video.apiId,
          episodeIndex: i,
          positionMillis: duration,
          durationMillis: duration,
        ),
      );
    }

    // The show also has to READ as finished where progress is summarised —
    // the resume target keys off this row, not off the episode map.
    final last = episodes.length - 1;
    await repository.saveVideoHistory(
      VideoHistory(
        sourceId: video.sourceId,
        videoId: video.apiId,
        videoTitle: video.title,
        coverUrl: video.coverUrl,
        rating: video.rating > 0 ? '${video.rating}' : null,
        type: video.type,
        region: video.region,
        year: video.year,
        actor: video.actor,
        version: video.version,
        hits: video.hits,
        remarks: video.remarks,
        blurb: video.blurb,
        lastEpisodeIndex: last,
        lastEpisodeTitle: episodes[last].title,
      ),
    );

    ref.invalidate(episodeHistoriesProvider);
    ref.invalidate(videoHistoryProvider);
    ref.invalidate(crossSourceWatchesProvider);
    await ref.read(playHistoryProvider.notifier).manualRefresh();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          tr('video.menu.marked_watched', args: ['${episodes.length}']),
        ),
      ),
    );
  }

  Future<void> _downloadSeason() async {
    final video = widget.video;
    final detail = await ref
        .read(videoRepositoryProvider)
        .getVideo(video.apiId, sourceId: video.sourceId);
    final episodes = detail?.urls ?? const <VideoEpisode>[];
    if (!mounted) return;
    if (episodes.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(tr('video.detail.no_episodes'))));
      return;
    }
    ref
        .read(downloadManagerProvider)
        .addTask(
          videoId: video.apiId,
          videoTitle: video.title,
          coverUrl: video.coverUrl,
          episodes: episodes
              .asMap()
              .entries
              .map(
                (e) => {
                  'index': e.key,
                  'title': episodeLabel(e.value.title, index: e.key),
                  'url': e.value.url ?? '',
                },
              )
              .toList(),
        );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          tr(
            'video.detail.download_batch_added',
            args: [episodes.length.toString()],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // 减少特效: the hover overlay still appears (it carries the actions), but
    // it snaps in instead of fading, and the card neither scales nor swaps
    // shadows — ~12 frames each way of re-rasterizing a Retina poster under a
    // 28px-blur shadow at a changing scale, per card the pointer crosses. The
    // strengthened border is the remaining hover cue.
    final reduced = ref.watch(reduceEffectsProvider);
    return GestureDetector(
      onSecondaryTapUp: (d) => _openMenu(d.globalPosition),
      // Trackpads and touch report a long press where a mouse reports a right
      // click.
      onLongPressStart: (d) => _openMenu(d.globalPosition),
      child: InkWell(
        onTap: widget.onTap ?? _openDetail,
        child: MouseRegion(
          // Crossings drive the controller; [isHovered] exists only for what
          // an animation cannot express — the reduced-mode border colour and
          // the overlay's hit-testing.
          onEnter: widget.enableHover
              ? (_) {
                  setState(() => isHovered = true);
                  if (reduced) {
                    // Jumping the controller keeps reduced mode's instant
                    // swap: the overlay lands fully visible with no scale
                    // flight and no fade.
                    _controller.value = 1.0;
                  } else {
                    _controller.forward();
                  }
                }
              : null,
          onExit: widget.enableHover
              ? (_) {
                  setState(() => isHovered = false);
                  if (reduced) {
                    _controller.value = 0.0;
                  } else {
                    _controller.reverse();
                  }
                }
              : null,
          child: AnimatedBuilder(
            animation: _scaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                // The controller runs even in reduced mode — it carries the
                // overlay's visibility — so the no-scale rule is enforced here
                // rather than by never starting the animation.
                scale: reduced ? 1.0 : _scaleAnimation.value,
                child: child,
              );
            },
            child: Container(
              decoration: BoxDecoration(
                // `--glass-2` with `--edge-soft`, the same material as every
                // other panel in the window.
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: VidraTokens.of(context).glass2,
                ),
                borderRadius: BorderRadius.circular(_radius),
                border: Border.all(
                  color: reduced && isHovered
                      ? VidraTokens.of(context).edge
                      : VidraTokens.of(context).edgeSoft,
                ),
                // Two shadows rather than one: a tight contact shadow keeps the
                // card attached to the page while a wide, soft one carries the
                // lift. A single blur does one job or the other, and hover with
                // only the wide shadow reads as the card floating off.
                //
                // The pair waits for [_hoverShadowSettled] rather than for the
                // pointer: the lift lands after the scale flight, so the card
                // never re-rasterizes with a 28px blur mid-animation.
                boxShadow: _hoverShadowSettled && !reduced
                    ? [
                        BoxShadow(
                          color: Colors.black.withAlpha(isDark ? 130 : 40),
                          blurRadius: 28,
                          offset: const Offset(0, 14),
                        ),
                        BoxShadow(
                          color: Colors.black.withAlpha(isDark ? 90 : 26),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withAlpha(isDark ? 60 : 18),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
              ),
              clipBehavior: Clip.antiAlias,
              // One shared element tree for both pointer states. The resting
              // layer is always there; the hover layer fades over it; the
              // corner chrome both states show is pinned above the hover scrim
              // so it neither fades nor dims.
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _buildRestingLayer(),
                  _buildHoverOverlay(),
                  Positioned(top: 8, left: 8, child: _buildBadgeRow()),
                  Positioned(top: 8, right: 8, child: _buildCornerRow()),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Decode covers at the size the grid can actually show: [kPosterGrid] caps
  /// a cell at 168 logical points and hover scales the card by 1.05, so any
  /// wider decode is memory the screen never displays. The card holds exactly
  /// ONE cover — hover dims and annotates it in an overlay instead of swapping
  /// in a second image — so this is also the only decode it ever requests.
  int _coverDecodeWidth(BuildContext context) =>
      (kPosterGrid.maxCrossAxisExtent *
              MediaQuery.devicePixelRatioOf(context) *
              1.05)
          .round();

  /// Everything the resting card shows, minus the corner chrome [build] pins
  /// above the hover overlay. Built once and kept for the life of the card:
  /// pointer crossings repaint the fading pieces, they no longer rebuild this
  /// tree.
  Widget _buildRestingLayer() {
    final theme = Theme.of(context);
    // Resolved here rather than at every call site: cards are built by the
    // catalog, search and category screens, and threading a lookup through all
    // of them to say one line would be the same wiring three times.
    final label = widget.watchLabel ?? crossSourceWatchLabel(ref, widget.video);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Image Area
        Expanded(
          child: Stack(
            fit: StackFit.expand,
            children: [
              // The one cover both pointer states share. Hover used to swap in
              // a second CachedNetworkImage of the same URL and decode width;
              // the overlay now dims and annotates this one, so there is no
              // second subtree to keep in sync and nothing to refetch or
              // re-decode when the pointer arrives. The sourceId must still
              // ride along: without it a non-active source's cover resolves
              // against the wrong base URL entirely.
              Hero(
                tag: videoPosterHeroTag(widget.video),
                child: CachedNetworkImage(
                  imageUrl: ref
                      .read(videoRepositoryProvider)
                      .resolveUrl(
                        widget.video.coverUrl,
                        sourceId: widget.video.sourceId,
                      ),
                  fit: BoxFit.cover,
                  memCacheWidth: _coverDecodeWidth(context),
                  // The skeleton grid's fill, minus its shimmer: each Shimmer
                  // is its own AnimationController repainting every vsync, and
                  // a scroll puts dozens of loading covers on screen at once.
                  placeholder: (context, url) => ColoredBox(
                    color: VidraTokens.of(context).fg.withValues(alpha: 0.07),
                  ),
                  errorWidget: (context, url, err) => ColoredBox(
                    color: VidraTokens.of(context).fg.withValues(alpha: 0.09),
                  ),
                ),
              ),

              // Bottom overlay carries YOUR progress and nothing else. The
              // catalog's own "更新至第 N 集" moved below the poster, where the
              // date that qualifies it can sit beside it — the two were saying
              // the same thing in two places, and neither said when. Fades out
              // under the hover panel, which replaces it.
              if (label != null)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: FadeTransition(
                    opacity: _restingFade,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(9, 14, 9, 7),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withAlpha(190),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: Text(
                        label,
                        style: const TextStyle(
                          color: _progressColor,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ),
                ),

              // Above the gradient so it never fades out with it, and inset so
              // it reads as a control rather than as the card's bottom edge.
              if ((widget.watchProgress ?? 0) > 0.01)
                Positioned(
                  bottom: 6,
                  left: 9,
                  right: 9,
                  child: FadeTransition(
                    opacity: _restingFade,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: widget.watchProgress!.clamp(0.0, 1.0),
                        minHeight: 3,
                        backgroundColor: Colors.white.withAlpha(64),
                        valueColor: const AlwaysStoppedAnimation(
                          _progressColor,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Items below image (Image 1 style)
        if (widget.showDetails)
          // The hover panel that lands on this region is translucent, so these
          // rows fade out with the rest of the resting chrome — left opaque,
          // the title would ghost through the panel at full hover.
          FadeTransition(
            opacity: _restingFade,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.video.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 3),
                  // When it last moved, and how far it has got. The cast used
                  // to be here; it is in the hover panel now, because a name
                  // you do not recognise answers nothing while a date answers
                  // "is this still running" at a glance.
                  Text(
                    _subtitle(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 11.5,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  /// Version and "new" badges, top-left. They read the same in both pointer
  /// states, so [build] pins them above the hover scrim instead of fading them
  /// with either layer — hover must not dim them.
  Widget _buildBadgeRow() {
    return Row(
      children: [
        if (widget.video.version != null && widget.video.version!.isNotEmpty)
          _buildBadge(widget.video.version!),
        if (widget.video.version != null) const SizedBox(width: 5),
        if (_isFresh)
          _buildBadge(tr('video.detail.new_badge'), fill: _freshColor),
      ],
    );
  }

  /// Score and the card's action share the top-right corner, in a row. The
  /// recent list used to Position its delete button at the same 8,8 as the
  /// rating chip, so the two were drawn on top of each other and neither could
  /// be read.
  ///
  /// Pinned above the hover overlay and never swapped: hovering is the only
  /// moment anyone reaches for [PopularVideoCard.trailing], and the old
  /// swap-in hover subtree forgot to render it — the delete button and the
  /// unfollow bell vanished the moment the pointer arrived. A single shared
  /// row makes that impossible by construction.
  Widget _buildCornerRow() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // The rating is the one thing the two states draw differently — a chip
        // at rest, bare glyphs once the hover scrim supplies the contrast — so
        // only the rating cross-fades in place while `trailing` holds still.
        if (widget.video.rating > 0)
          Stack(
            alignment: Alignment.topRight,
            children: [
              // On its own chip, not bare text: an orange number sat directly
              // on the poster, and half the covers in a catalog are bright
              // enough to swallow it whole — a shadow only smears it.
              FadeTransition(
                opacity: _restingFade,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(120),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        size: 12,
                        color: _freshColor,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '${widget.video.rating}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              FadeTransition(
                opacity: _hoverFade,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      size: 13,
                      color: _freshColor,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '${widget.video.rating}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        if (widget.trailing != null) ...[
          const SizedBox(width: 5),
          widget.trailing!,
        ],
      ],
    );
  }

  /// Everything only a hovered card shows, over the shared resting layer.
  ///
  /// The cover, the badges and the corner row are NOT here: they are the same
  /// picture in both states, so hover fades this panel over them instead of
  /// rebuilding them. What remains is the darkening scrim, the detail panel,
  /// and the two ways in.
  ///
  /// [IgnorePointer] while the pointer is away, because a fully transparent
  /// overlay still hit-tests: the "view details" button would otherwise swallow
  /// taps meant for the card underneath it.
  Widget _buildHoverOverlay() {
    final theme = Theme.of(context);

    return IgnorePointer(
      ignoring: !isHovered,
      child: FadeTransition(
        opacity: _hoverFade,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // The darkening is its own layer rather than a blend mode on the
            // image: on the image it sat INSIDE the Hero, so the cover flew to
            // the detail page dark and snapped bright on arrival. Here it stays
            // behind on the card and the flight carries the picture unchanged.
            Container(color: Colors.black.withAlpha(100)),

            // Info Overlay (Bottom)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(12),
                color: Colors.black.withAlpha(120),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      widget.video.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // Tags (Type, Region, Year), plus the play count that used to
                    // lead the resting card. It compares shows against each other,
                    // which is a question for the moment you are weighing one — not
                    // for every card in a scrolling grid.
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        for (final t in [
                          widget.video.type,
                          widget.video.region ?? '',
                          widget.video.year ?? '',
                          if ((widget.video.hits ?? 0) > 0)
                            tr(
                              'video.detail.play_count',
                              args: [_formatHits(widget.video.hits)],
                            ),
                        ])
                          if (t.isNotEmpty) _buildTag(theme, t),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Date/Add time. Absent on a Video rebuilt from our own rows
                    // (追更 / 想看 / 继续观看 cards) — hidden then, because the
                    // only date `?? 0` can render is 1970-01-01.
                    if ((widget.video.vodTime ?? 0) > 0)
                      Text(
                        tr(
                          'video.detail.added_date',
                          args: [
                            DateTime.fromMillisecondsSinceEpoch(
                              widget.video.vodTime! * 1000,
                            ).toString().split(' ')[0],
                          ],
                        ),
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 11,
                        ),
                      ),
                    const SizedBox(height: 2),

                    // Actor
                    if (widget.video.actor != null)
                      Text(
                        tr(
                          'video.detail.cast_info',
                          args: [widget.video.actor!],
                        ),
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 2),

                    // Simple Blurb/Summary
                    if (widget.video.blurb != null)
                      Text(
                        "${tr('video.detail.storyline')}: ${widget.video.blurb}",
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 11,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ),
            // Centred in the cover rather than parked at a hardcoded offset: the
            // grid sizes cards to the window, so `top: 70` put the play ring
            // anywhere from mid-poster to behind the info panel. Aligned slightly
            // above centre so it clears that panel at every card height.
            Align(
              alignment: const Alignment(0, -0.35),
              child: Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withAlpha(70),
                  border: Border.all(color: Colors.white70, width: 3),
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 30,
                ),
              ),
            ),

            // Secondary way in, shown only when tapping the card does something
            // OTHER than open the detail page. Without it, giving the recent-play
            // cards a straight-to-playback tap left the episode list unreachable
            // from the one screen a viewer returns to.
            if (widget.onTap != null)
              Align(
                alignment: const Alignment(0, 0.15),
                child: Center(
                  child: Material(
                    color: Colors.black45,
                    borderRadius: BorderRadius.circular(999),
                    child: InkWell(
                      // Its own tap target: the card's InkWell sits underneath and
                      // would otherwise start playback instead.
                      onTap: _openDetail,
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.list,
                              color: Colors.white,
                              size: 14,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              tr('common.view_details'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Listed within the last week, which is what the catalog's own timestamp can
  /// actually support. Per-episode "new" is computed against our own previous
  /// snapshot — see `VideoRepository._markNewEpisodes` — but that lives on the
  /// episode list, and a card has no episodes to compare.
  bool get _isFresh {
    if (widget.isNew != null) return widget.isNew!;
    final t = widget.video.vodTime;
    if (t == null || t <= 0) return false;
    final at = DateTime.fromMillisecondsSinceEpoch(t * 1000);
    return DateTime.now().difference(at).inDays < 7;
  }

  /// One badge shape for everything laid on a cover.
  ///
  /// [fill] is for the one badge that must be seen from across the grid;
  /// everything else is the same neutral darkening, because a card that answers
  /// with four saturated colours answers with none.
  Widget _buildBadge(String text, {Color? fill}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: BoxDecoration(
        color: fill ?? Colors.black.withAlpha(120),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: fill == null ? Colors.white : _onFresh,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildTag(ThemeData theme, String text) {
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(isDark ? 34 : 54),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 10),
      ),
    );
  }
}
