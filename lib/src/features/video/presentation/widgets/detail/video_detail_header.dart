import 'package:vidra/src/common/cover_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:vidra/src/config/design_tokens.dart';
import 'package:vidra/src/features/video/domain/video_collection.dart';
import 'package:vidra/src/features/video/data/video_repository.dart';
import 'package:vidra/src/features/video/presentation/widgets/cards/popular_video_card.dart';
import 'package:vidra/src/features/video/domain/play_history.dart';
import 'package:vidra/src/features/video/domain/episode_number.dart';
import 'package:vidra/src/features/video/domain/resume_target.dart';
import 'package:vidra/src/features/video/presentation/widgets/cross_source_watch_badge.dart';
import 'package:vidra/src/features/video/presentation/play_history_provider.dart';
import 'package:vidra/src/features/subscription/presentation/subscription_provider.dart';
import 'package:vidra/src/features/favorites/presentation/favorites_provider.dart';
import 'package:vidra/src/features/cast/presentation/cast_button.dart';
import 'package:vidra/src/window/player_window_launcher.dart';

/// `.dhero` + `.dhead`.
///
/// A 176px backdrop card with the poster standing on its lower edge, the title
/// and facts on the dark half of the backdrop beside it, and the actions
/// landing just below. The measurements are the design's: the hero used to be
/// 500px of full-bleed cover art, which put the episode list — the reason
/// anyone opens this page — off the first screen entirely.
class VideoDetailHeader extends ConsumerWidget {
  final Video video;
  final ValueNotifier<bool> isDownloadMode;

  const VideoDetailHeader({
    super.key,
    required this.video,
    required this.isDownloadMode,
  });

  static const _hero = 176.0;
  static const _posterW = 100.0;
  static const _posterH = 142.0;

  /// How far the head row starts above the hero's bottom edge: `margin-top:
  /// -116px` on a 176px hero.
  static const _headTop = _hero - 116.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.read(videoRepositoryProvider);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: 8,
          right: 8,
          top: 4,
          height: _hero,
          child: _Backdrop(video: video, repository: repository),
        ),
        Padding(
          padding: const EdgeInsets.only(top: _headTop + 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(width: 20),
              SizedBox(
                width: _posterW,
                height: _posterH,
                child: _Poster(video: video, repository: repository),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // The design's `padding-top: 42px` — what puts the title
                    // on the dark half of the backdrop rather than above it.
                    const SizedBox(height: 42),
                    Text(
                      video.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 30,
                        height: 1,
                        letterSpacing: -1.05,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: Colors.black.withAlpha(128),
                            blurRadius: 20,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 9),
                    _FactPills(video: video),
                    const SizedBox(height: 12),
                    _Actions(video: video, isDownloadMode: isDownloadMode),
                  ],
                ),
              ),
              const SizedBox(width: 20),
            ],
          ),
        ),
      ],
    );
  }
}

/// The backdrop card. Dark on the left, where the text lands.
class _Backdrop extends StatelessWidget {
  const _Backdrop({required this.video, required this.repository});

  final Video video;
  final VideoRepository repository;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final art = video.backdropUrl ?? video.coverUrl;
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Hero(
            tag: videoPosterHeroTag(video),
            child: CoverImage(
              imageUrl: art.startsWith('http')
                  ? art
                  : repository.resolveUrl(art, sourceId: video.sourceId),
              // Cover fit in a strip this wide scales the art by width, not
              // by the fixed 176px height, and the width tracks the window —
              // so the decode must be capped at a typical maximized window's
              // physical width, the one axis bound the layout cannot give.
              memCacheWidth: 1600,
              placeholder: ColoredBox(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.06),
              ),
              errorWidget: ColoredBox(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
              ),
            ),
          ),
          // Two washes, exactly as the design: one across (the text sits on
          // the left half, so that is the half that has to be dark) and one
          // up from the bottom so the poster has something to stand on.
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment(-1, -0.2),
                end: Alignment(1, 0.2),
                stops: [0.06, 0.62, 0.94],
                colors: [
                  Color(0xDB060A12),
                  Color(0x4D060A12),
                  Color(0x00060A12),
                ],
              ),
            ),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                stops: [0.0, 0.6],
                colors: [Color(0xB8060A12), Color(0x00060A12)],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The cover, standing on the backdrop's edge.
class _Poster extends StatelessWidget {
  const _Poster({required this.video, required this.repository});

  final Video video;
  final VideoRepository repository;

  @override
  Widget build(BuildContext context) {
    final t = VidraTokens.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: t.drop3,
        border: Border.all(color: t.edge, width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(13),
        child: CoverImage(
          imageUrl: video.coverUrl.startsWith('http')
              ? video.coverUrl
              : repository.resolveUrl(video.coverUrl, sourceId: video.sourceId),
          memCacheWidth:
              (VideoDetailHeader._posterW *
                      MediaQuery.devicePixelRatioOf(context))
                  .round(),
          placeholder: const ColoredBox(color: Color(0x33000000)),
          errorWidget: const ColoredBox(color: Color(0x33000000)),
        ),
      ),
    );
  }
}

/// Everything the catalog claims about the show, on one line.
///
/// Episode count and airing state are in here because they are what a viewer
/// checks before committing an evening.
class _FactPills extends StatelessWidget {
  const _FactPills({required this.video});

  final Video video;

  /// Whether the catalog's remarks line is an AIRING state rather than a
  /// quality tag.
  ///
  /// Amber is reserved for "this is still gaining episodes". The catalogs put
  /// 更新至第22集 and 超清 in the same field, and painting 超清 amber spends
  /// the one colour that means something on a codec.
  static final _airing = RegExp(r'更新|连载|集|期|話|话|完结|完結');

  @override
  Widget build(BuildContext context) {
    final remarks = video.remarks?.trim() ?? '';
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        // Formatted, never interpolated raw: a rating derived by arithmetic
        // rather than parsed from a string carries binary-float noise, and
        // "★ 4.6999999999999999" duly reached the page.
        if (video.rating > 0)
          _Pill(label: '★ ${video.rating.toStringAsFixed(1)}', mono: true),
        if ((video.year ?? '').isNotEmpty) _Pill(label: video.year!),
        if (video.type.isNotEmpty) _Pill(label: video.type),
        // Deliberately NO "全 N 集": that number was `urls.length`, which is
        // how many playback lines this catalog lists — mirrors, dubs and
        // trailers included — not how many episodes the show has. It sat next
        // to the catalog's own 更新至第30集, which is the real answer, and
        // contradicted it whenever a source filed an extra line.
        if (remarks.isNotEmpty)
          _Pill(label: remarks, live: _airing.hasMatch(remarks)),
      ],
    );
  }
}

/// `.pill`. Deliberately white-based rather than the theme's `--fg-2`: these
/// sit ON the darkened backdrop, and in the light theme `--fg-2` is near-black.
class _Pill extends StatelessWidget {
  const _Pill({required this.label, this.mono = false, this.live = false});

  final String label;
  final bool mono;
  final bool live;

  @override
  Widget build(BuildContext context) {
    const amber = Color(0xFFFFC559);
    final fg = live ? amber : Colors.white;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: live
              ? const [Color(0x38FFC559), Color(0x0FFFC559)]
              : const [Color(0x24FFFFFF), Color(0x0FFFFFFF)],
        ),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: live ? const Color(0x57FFC559) : const Color(0x2EFFFFFF),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg.withValues(alpha: live ? 1 : 0.92),
          fontSize: 11.5,
          height: 1.35,
          fontWeight: FontWeight.w500,
          fontFeatures: mono ? VidraType.data : null,
        ),
      ),
    );
  }
}

/// `.acts` — play, download, follow. Follow moved up here from the episode
/// bar: all three are things you do to the SHOW, and the episode bar is for
/// things you do to the grid.
class _Actions extends StatelessWidget {
  const _Actions({required this.video, required this.isDownloadMode});

  final Video video;
  final ValueNotifier<bool> isDownloadMode;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _PlayButton(video: video),
        _DownloadButton(video: video, isDownloadMode: isDownloadMode),
        _SubscribeButton(video: video),
        _FavoriteButton(video: video),
        CastButton(video: video),
        // Follows the cast button because it is that button's consequence:
        // once a television is showing this show, the grid below stops
        // opening the local player and starts choosing what the TV plays.
        CastEpisodeHint(video: video, isDownloadMode: isDownloadMode),
      ],
    );
  }
}

/// `.btn` — the design's one button shape.
class ActionButton extends StatelessWidget {
  const ActionButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.primary = false,
    this.amber = false,
    this.danger = false,
    this.busy = false,
  });

  final String label;
  final IconData? icon;
  final VoidCallback onTap;
  final bool primary;
  final bool amber;
  final bool danger;

  /// Working on it: the icon becomes a spinner and taps stop landing.
  ///
  /// Casting takes seconds — device probe, pairing, connect — and without
  /// this the page looked untouched the whole time, so the obvious thing to
  /// do was press it again and start a second one.
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final t = VidraTokens.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;

    // `.btn-primary` is a white pill with dark ink — right on the dark theme,
    // invisible on the light one, so light flips it. It is the page's single
    // brightest thing either way, which is what "primary" has to mean.
    final Color fg = primary
        ? (dark ? const Color(0xFF0C1420) : Colors.white)
        : danger
        ? t.clash
        : amber
        ? t.amber
        : t.fg;
    final List<Color> fill = primary
        ? (dark
              ? const [Color(0xFAFFFFFF), Color(0xCCFFFFFF)]
              : const [Color(0xFF1B2C36), Color(0xFF14232A)])
        : amber
        ? [t.amber.withValues(alpha: 0.22), t.amber.withValues(alpha: 0.07)]
        : danger
        ? [t.clash.withValues(alpha: 0.20), t.clash.withValues(alpha: 0.06)]
        : t.glass2;
    final Color edge = primary
        ? Colors.transparent
        : amber
        ? t.amber.withValues(alpha: 0.42)
        : danger
        ? t.clash.withValues(alpha: 0.42)
        : t.edgeSoft;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: busy ? null : onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: EdgeInsets.fromLTRB(icon == null && !busy ? 17 : 13, 8, 17, 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: edge),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: fill,
            ),
            boxShadow: primary ? t.drop1 : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (busy) ...[
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2, color: fg),
                ),
                const SizedBox(width: 8),
              ] else if (icon != null) ...[
                Icon(icon, size: 16, color: fg),
                const SizedBox(width: 7),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.35,
                  fontWeight: primary ? FontWeight.w600 : FontWeight.w500,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The page's primary action. Reads history so a viewer on episode 12 is
/// offered episode 12 — it used to be hardcoded to `episodeIndex: 0`, which
/// made the biggest button on the page a one-click trip back to the start.
class _PlayButton extends ConsumerWidget {
  final Video video;
  const _PlayButton({required this.video});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = (videoId: video.apiId, sourceId: video.sourceId);
    final episodes = video.urls ?? [];

    // Both are already in flight for this page (the episode grid watches the
    // same episodeHistoriesProvider), so this costs no extra query.
    final histories =
        ref.watch(episodeHistoriesProvider(key)).value ??
        const <int, EpisodeHistory>{};
    final videoHistory = ref.watch(videoHistoryProvider(key)).value;

    // A newer viewing of the same show on another catalog outranks every row
    // this one holds — the newest-wins rule the episode grid merges by. That
    // viewing may sit PAST this catalog's last episode (watched 第21集 where
    // this list stops at 20), so the button follows the progress to its own
    // source — where the index is valid and the position is exact — rather
    // than mapping the episode number back into this list and starting over.
    // Films keep their local-only behaviour: their "episodes" are audio
    // tracks and mirrors, so another source's index names a different thing.
    final newer = isEpisodicType(video.type)
        ? crossSourceResumeOverride(
            match: crossSourceWatchFor(ref, video),
            histories: histories,
            lastWriteAt: videoHistory?.updatedAt,
          )
        : null;
    if (newer != null) {
      return ActionButton(
        primary: true,
        icon: Icons.play_circle_outline_rounded,
        label: tr(
          'video.detail.continue_watching',
          args: [
            episodeLabel(
              newer.lastEpisodeTitle,
              index: newer.lastEpisodeIndex,
            ),
          ],
        ),
        onTap: () => PlayerLauncher.open(
          context,
          videoId: newer.videoId,
          episodeIndex: newer.lastEpisodeIndex,
          sourceId: newer.sourceId,
        ),
      );
    }

    final target = resolveResumeTarget(
      histories: histories,
      lastEpisodeIndex: videoHistory?.lastEpisodeIndex,
      episodeCount: episodes.isEmpty ? null : episodes.length,
    );

    final label = episodeLabel(
      target.episodeIndex < episodes.length
          ? episodes[target.episodeIndex].title
          : null,
      index: target.episodeIndex,
    );

    return ActionButton(
      primary: true,
      icon: target.isFirstTime
          ? Icons.play_arrow_rounded
          : Icons.play_circle_outline_rounded,
      label: target.isFirstTime
          ? tr('video.detail.play_now')
          // Same rule as the recent-play cards: naming a film's "episode"
          // surfaces the source's 立即播放 / 粤语播放 line labels, which read
          // as gibberish next to "continue watching".
          : isEpisodicType(video.type)
          ? tr('video.detail.continue_watching', args: [label])
          : tr('video.detail.continue_watching_short'),
      onTap: () async {
        if (episodes.isNotEmpty) {
          await PlayerLauncher.open(
            context,
            videoId: video.apiId,
            episodeIndex: target.episodeIndex,
            sourceId: video.sourceId,
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(tr('video.detail.no_episodes_play'))),
          );
        }
      },
    );
  }
}

class _DownloadButton extends StatelessWidget {
  final Video video;
  final ValueNotifier<bool> isDownloadMode;

  const _DownloadButton({required this.video, required this.isDownloadMode});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isDownloadMode,
      builder: (context, downloadMode, child) {
        return ActionButton(
          danger: downloadMode,
          icon: downloadMode ? Icons.close_rounded : Icons.download_rounded,
          label: downloadMode
              ? tr('video.detail.done')
              : tr('video.detail.download'),
          onTap: () {
            if ((video.urls ?? []).isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(tr('video.detail.no_episodes'))),
              );
              return;
            }
            isDownloadMode.value = !isDownloadMode.value;
          },
        );
      },
    );
  }
}

/// Follow this show. By show, not by catalog row: the same 九门 followed from
/// the other source used to read 订阅 here, and tapping it added a second row
/// rather than undoing the first.
class _SubscribeButton extends ConsumerWidget {
  const _SubscribeButton({required this.video});

  final Video video;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final following = ref.watch(
      isSubscribedProvider((title: video.title, year: video.year)),
    );
    return ActionButton(
      amber: following,
      icon: following
          ? Icons.notifications_active_outlined
          : Icons.notifications_none_rounded,
      label: following
          ? tr('subscription.subscribed')
          : tr('subscription.subscribe'),
      onTap: () => ref.read(subscriptionsProvider.notifier).toggle(video),
    );
  }
}

/// Save this show to watch later. Same identity rule as the subscribe
/// button: by show, not by catalog row. Lives in the 想看 tab beside
/// 继续观看 — the show was found now but is not being started now.
class _FavoriteButton extends ConsumerWidget {
  const _FavoriteButton({required this.video});

  final Video video;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saved = ref.watch(
      isFavoritedProvider((title: video.title, year: video.year)),
    );
    return ActionButton(
      icon: saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
      label: saved ? tr('favorites.saved') : tr('favorites.save'),
      onTap: () => ref.read(favoritesProvider.notifier).toggle(video),
    );
  }
}
