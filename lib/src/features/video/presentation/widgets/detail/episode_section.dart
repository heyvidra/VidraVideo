import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:vidra/src/common/skeleton/skeleton_box.dart';
import 'package:vidra/src/config/ambient_background.dart';
import 'package:vidra/src/config/design_tokens.dart';
import 'package:vidra/src/features/video/domain/video_collection.dart';
import 'package:vidra/src/features/video/domain/play_history.dart'
    show EpisodeHistory, isEpisodicType;
import 'package:vidra/src/features/video/domain/episode_number.dart';
import 'package:vidra/src/features/video/domain/merged_history.dart';
import 'package:vidra/src/features/video/data/cross_source_catalog.dart';
import 'package:vidra/src/features/download/data/download_provider.dart';
import 'package:vidra/src/features/video/presentation/widgets/detail/episode_item.dart';
import 'package:vidra/src/features/video/presentation/play_history_provider.dart';
import 'package:vidra/src/features/video/data/video_repository.dart';
import 'package:vidra/src/features/video/presentation/widgets/cross_source_watch_badge.dart';

/// The episode list and the controls that drive it, as slivers.
///
/// Slivers rather than one widget because the bar PINS: switching source is
/// only ever done to see what it does to the grid, and on a 40-episode show
/// the control and its effect had scrolled apart. A pinned header needs a
/// sliver, and a sliver needs the page to be a [CustomScrollView] — hence the
/// shape of [VideoDetailScreen].
///
/// The source picker IS this bar, not a panel of its own further up the page.
/// It has exactly one job — decide who supplies this grid — and 200px away
/// from the grid it was being read as metadata about the show.
class EpisodeSection extends ConsumerWidget {
  final Video video;
  final ValueNotifier<bool> isAscending;
  final ValueNotifier<bool> isDownloadMode;

  /// Which catalog feeds the grid — a sourceId, or null for this page's own.
  ///
  /// Held by the caller, not here, because the pinned bar and the grid are two
  /// separate slivers that have to agree on it. A sourceId rather than the "is
  /// the alternate showing" boolean it started as: two catalogs today, and a
  /// third makes "the alternate" a question with no answer.
  final ValueNotifier<String?> selectedSource;

  /// When the manual refresh last fired, for its cooldown.
  final ValueNotifier<DateTime?> lastRefresh;

  /// Whether the field-by-field source comparison is expanded.
  final ValueNotifier<bool> showComparison;

  const EpisodeSection({
    super.key,
    required this.video,
    required this.isAscending,
    required this.isDownloadMode,
    required this.selectedSource,
    required this.lastRefresh,
    required this.showComparison,
  });

  /// The content column's gutter — `margin: … 8px` in the design.
  static const _gutter = 8.0;

  /// The bar's two rows. Fixed, because a pinned header must declare its
  /// height before it can be laid out — so the rows inside must not wrap.
  static const _titleRow = 30.0;
  static const _sourceRow = 34.0;

  /// `margin-top:16` + the card's border, padding (9/9), rows, the 8px between
  /// them, and the 12px gap to whatever comes next. The border is easy to
  /// forget and cost exactly the two pixels the pinned header once overflowed
  /// by.
  static double _barHeight(bool hasSources) =>
      16 + 1 + 9 + _titleRow + (hasSources ? 8 + _sourceRow : 0) + 9 + 1 + 12;

  /// Not built as a box — [VideoDetailScreen] composes [slivers] directly, and
  /// a pinned header only pins inside a real [CustomScrollView].
  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      CustomScrollView(slivers: slivers(context, ref));

  List<Widget> slivers(BuildContext context, WidgetRef ref) {
    final t = VidraTokens.of(context);

    if (video.urls == null || video.urls!.isEmpty) {
      return [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24.0),
            child: Center(
              child: Text(
                tr('video.player.no_episodes'),
                style: TextStyle(color: t.fg3),
              ),
            ),
          ),
        ),
      ];
    }

    final counterparts = _counterpartsOf(ref, video);
    // A selection can outlive the catalogs it named — the counterpart list is
    // rebuilt from the local cache, and clearing history drops rows from it.
    // Falling back to this page's own source beats rendering an empty grid for
    // a catalog that is no longer on the list.
    final picked = counterparts.any((c) => c.sourceId == selectedSource.value)
        ? selectedSource.value
        : null;
    // The bar renders whenever there is more than one catalog CONFIGURED, not
    // when a counterpart happens to be cached — see _SourceBar.
    final hasSources =
        ref
            .watch(availableDataSourcesProvider)
            .where((s) => s.id != 'mock')
            .length >
        1;
    final takes = _takes(ref, video, counterparts);
    final diffs = _disagreements(takes).length;

    return [
      SliverPersistentHeader(
        pinned: true,
        delegate: _EpisodeBarDelegate(
          extent: _barHeight(hasSources),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(_gutter, 16, _gutter, 12),
            child: GlassPanel(
              radius: 16,
              blur: 14,
              saturation: 1.8,
              tint: t.barBg,
              border: t.edgeSoft,
              shadow: t.drop2,
              padding: const EdgeInsets.fromLTRB(14, 9, 12, 9),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: _titleRow,
                    child: _BarTop(
                      video: video,
                      diffs: diffs,
                      comparable: takes.length > 1,
                      showComparison: showComparison,
                      isAscending: isAscending,
                      isDownloadMode: isDownloadMode,
                      lastRefresh: lastRefresh,
                      onDownloadAll: () => _downloadAll(context, ref),
                    ),
                  ),
                  if (hasSources) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      height: _sourceRow,
                      child: _SourceBar(
                        video: video,
                        counterparts: counterparts,
                        selected: picked,
                        onPick: (id) => selectedSource.value = id,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),

      // Below the pinned card rather than inside it: a pinned header has to
      // declare its height before layout, and a table whose row count depends
      // on how many catalogs are configured cannot. It carries the bar's own
      // fill so it still reads as the bar's drawer.
      if (showComparison.value && takes.length > 1)
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(_gutter, 0, _gutter, 12),
          sliver: SliverToBoxAdapter(
            child: _ComparisonTable(takes: takes, ownSourceId: video.sourceId),
          ),
        ),

      // Says what the checkmarks mean before the grid shows them. Borrowed
      // progress is the one thing on this page nobody would guess: a tick on a
      // catalog you have never played is either magic or a bug until the rule
      // is stated once.
      if (hasSources)
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(_gutter + 4, 0, _gutter + 4, 12),
          sliver: SliverToBoxAdapter(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '→',
                  style: TextStyle(fontSize: 12, height: 1.5, color: t.cyan),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    tr('video.detail.cross_source_note'),
                    style: TextStyle(fontSize: 12, height: 1.5, color: t.fg3),
                  ),
                ),
              ],
            ),
          ),
        ),

      SliverPadding(
        padding: const EdgeInsets.fromLTRB(_gutter, 0, _gutter, 24),
        sliver: SliverToBoxAdapter(
          child: picked == null
              ? _MergedGrid(
                  gridVideo: video,
                  others: [
                    for (final c in counterparts)
                      (videoId: c.videoId, sourceId: c.sourceId),
                  ],
                  buildGrid: _episodeGrid,
                )
              : _AltEpisodes(
                  video: video,
                  pick: counterparts.firstWhere((c) => c.sourceId == picked),
                  counterparts: counterparts,
                  buildGrid: _episodeGrid,
                ),
        ),
      ),
    ];
  }

  /// One grid for either source. [gridVideo] decides whose ids, whose
  /// sourceId and therefore whose playback and progress the tiles carry.
  ///
  /// `repeat(auto-fill, minmax(104px, 1fr))`: as many columns of at least
  /// 104px as fit, then every column stretches to share the remainder. A wrap
  /// of fixed-width tiles leaves a ragged margin down the right of the page,
  /// which is what this looked like before.
  Widget _episodeGrid({
    required Video gridVideo,
    required Map<int, EpisodeHistory> histories,
  }) {
    const min = 104.0, gap = 11.0;
    return ValueListenableBuilder2<bool, bool>(
      first: isAscending,
      second: isDownloadMode,
      builder: (context, ascending, downloadMode, _) {
        final urls = gridVideo.urls ?? const <VideoEpisode>[];
        final episodes = ascending ? urls : urls.reversed.toList();
        return LayoutBuilder(
          builder: (context, c) {
            final columns = ((c.maxWidth + gap) / (min + gap)).floor().clamp(
              1,
              99,
            );
            final width = (c.maxWidth - (columns - 1) * gap) / columns;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: episodes.asMap().entries.map((entry) {
                final originalIndex = ascending
                    ? entry.key
                    : urls.length - 1 - entry.key;
                return SizedBox(
                  width: width,
                  child: EpisodeItem(
                    videoId: gridVideo.apiId,
                    video: gridVideo,
                    originalIndex: originalIndex,
                    episode: entry.value,
                    isDownloadMode: downloadMode,
                    history: histories[originalIndex],
                  ),
                );
              }).toList(),
            );
          },
        );
      },
    );
  }

  void _downloadAll(BuildContext context, WidgetRef ref) {
    final manager = ref.read(downloadManagerProvider);
    final episodes = video.urls!;
    manager.addTask(
      videoId: video.apiId,
      videoTitle: video.title,
      coverUrl: video.coverUrl,
      episodes: episodes
          .asMap()
          .entries
          .map(
            (e) => {
              'index': e.key,
              'title':
                  e.value.title ??
                  tr(
                    'video.detail.episode_prefix',
                    args: [(e.key + 1).toString()],
                  ),
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
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
    isDownloadMode.value = false;
  }
}

/// `.epbar-top` — what the grid is, where you are in it, and the two controls
/// that change it.
class _BarTop extends ConsumerWidget {
  const _BarTop({
    required this.video,
    required this.diffs,
    required this.comparable,
    required this.showComparison,
    required this.isAscending,
    required this.isDownloadMode,
    required this.lastRefresh,
    required this.onDownloadAll,
  });

  final Video video;
  final int diffs;
  final bool comparable;
  final ValueNotifier<bool> showComparison;
  final ValueNotifier<bool> isAscending;
  final ValueNotifier<bool> isDownloadMode;
  final ValueNotifier<DateTime?> lastRefresh;
  final VoidCallback onDownloadAll;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = VidraTokens.of(context);
    final episodes = video.urls ?? const <VideoEpisode>[];
    final fresh = episodes.where((e) => e.isNew == true).length;

    return Row(
      children: [
        Text(
          tr('video.section.episodes'),
          style: TextStyle(
            fontSize: 16,
            height: 1.3,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
            color: t.fg,
          ),
        ),
        const SizedBox(width: 9),
        // Capped, NOT Flexible: a Flexible child shares the row's free space
        // with the Spacer below it, which parked the controls in the middle of
        // the bar instead of at its right edge.
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 260),
          child: _WatchChip(video: video),
        ),
        if (fresh > 0) ...[
          const SizedBox(width: 9),
          _Chip(
            label: tr('video.detail.unwatched_count', args: ['$fresh']),
            tone: t.amber,
          ),
        ],
        const Spacer(),
        ValueListenableBuilder<bool>(
          valueListenable: isDownloadMode,
          builder: (context, on, _) => on
              ? Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _TextAction(
                    label: tr('video.detail.download_all'),
                    onTap: onDownloadAll,
                    tone: t.cyan,
                  ),
                )
              : const SizedBox.shrink(),
        ),
        if (comparable && diffs > 0)
          _ComparisonToggle(
            diffs: diffs,
            open: showComparison.value,
            onTap: () => showComparison.value = !showComparison.value,
          ),
        _BarIcon(
          icon: Icons.refresh_rounded,
          tooltip: tr('common.refresh'),
          onTap: () => _refresh(context, ref),
        ),
        ValueListenableBuilder<bool>(
          valueListenable: isAscending,
          builder: (context, ascending, _) => _BarIcon(
            icon: ascending
                ? Icons.arrow_downward_rounded
                : Icons.arrow_upward_rounded,
            tooltip: ascending
                ? tr('video.detail.sort_asc')
                : tr('video.detail.sort_desc'),
            onTap: () => isAscending.value = !isAscending.value,
          ),
        ),
      ],
    );
  }

  void _refresh(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    if (lastRefresh.value != null &&
        now.difference(lastRefresh.value!).inSeconds < 30) {
      final remaining = 30 - now.difference(lastRefresh.value!).inSeconds;
      ScaffoldMessenger.of(context)
        ..removeCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              tr('video.detail.refresh_cooldown', args: ['$remaining']),
            ),
            duration: const Duration(seconds: 1),
          ),
        );
      return;
    }
    lastRefresh.value = now;
    ref.invalidate(
      videoByIdProvider((id: video.apiId, sourceId: video.sourceId)),
    );
    ref.invalidate(
      episodeHistoriesProvider((
        videoId: video.apiId,
        sourceId: video.sourceId,
      )),
    );
    ref.read(playHistoryProvider.notifier).manualRefresh();
  }
}

/// `.chip.cyan` — where you are. Reads local progress first and falls back to
/// another catalog's, which is the case the chip exists for: a show you have
/// been watching elsewhere opens here looking untouched.
class _WatchChip extends ConsumerWidget {
  const _WatchChip({required this.video});

  final Video video;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = VidraTokens.of(context);
    final episodes = video.urls ?? const <VideoEpisode>[];
    final histories =
        ref
            .watch(
              episodeHistoriesProvider((
                videoId: video.apiId,
                sourceId: video.sourceId,
              )),
            )
            .value ??
        const <int, EpisodeHistory>{};

    int? furthest;
    for (final e in histories.entries) {
      if (e.value.positionMillis <= 0) continue;
      if (furthest == null || e.key > furthest) furthest = e.key;
    }
    if (furthest != null) {
      final label = episodeLabel(
        furthest < episodes.length ? episodes[furthest].title : null,
        index: furthest,
      );
      return _Chip(
        label: tr('video.detail.watched_upto', args: [label]),
        tone: t.cyan,
      );
    }

    // Nothing here, but the same show has been watched on another catalog.
    final match = crossSourceWatchFor(ref, video);
    if (match == null) return const SizedBox.shrink();
    return _Chip(
      label: tr(
        'video.detail.watched_upto_on',
        args: [
          sourceDisplayName(ref, match.sourceId),
          episodeLabel(match.lastEpisodeTitle, index: match.lastEpisodeIndex),
        ],
      ),
      tone: t.cyan,
    );
  }
}

/// `.chip` — a stated fact, not a control.
class _Chip extends StatelessWidget {
  const _Chip({required this.label, this.tone});

  final String label;
  final Color? tone;

  @override
  Widget build(BuildContext context) {
    final t = VidraTokens.of(context);
    final c = tone ?? t.fg2;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: c.withValues(alpha: 0.12),
        border: Border.all(color: c.withValues(alpha: 0.34)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 11.5, height: 1.4, color: c),
      ),
    );
  }
}

/// One of the bar's own controls, sized to the row rather than to Material's
/// 48px default — the bar is 30px tall.
class _BarIcon extends StatelessWidget {
  const _BarIcon({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = VidraTokens.of(context);
    return IconButton(
      icon: Icon(icon, size: 17, color: t.fg2),
      tooltip: tooltip,
      onPressed: onTap,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: 28, height: 28),
    );
  }
}

class _TextAction extends StatelessWidget {
  const _TextAction({required this.label, required this.onTap, this.tone});

  final String label;
  final VoidCallback onTap;
  final Color? tone;

  @override
  Widget build(BuildContext context) {
    final t = VidraTokens.of(context);
    final c = tone ?? t.fg2;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: c.withValues(alpha: 0.38)),
            color: c.withValues(alpha: 0.10),
          ),
          child: Text(
            label,
            style: TextStyle(fontSize: 11.5, height: 1.4, color: c),
          ),
        ),
      ),
    );
  }
}

// Helper for listening to two value listenables
class ValueListenableBuilder2<A, B> extends StatelessWidget {
  final ValueListenable<A> first;
  final ValueListenable<B> second;
  final Widget Function(BuildContext context, A a, B b, Widget? child) builder;
  final Widget? child;

  const ValueListenableBuilder2({
    super.key,
    required this.first,
    required this.second,
    required this.builder,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<A>(
      valueListenable: first,
      builder: (context, a, _) {
        return ValueListenableBuilder<B>(
          valueListenable: second,
          builder: (context, b, _) {
            return builder(context, a, b, child);
          },
        );
      },
    );
  }
}

/// One catalog's account of the show, for the comparison.
typedef _Take = ({String name, String? sourceId, Video? video});

/// What each catalog says, this page's own source first.
///
/// A counterpart with nothing cached yet comes back with a null video rather
/// than being dropped: "we have not looked" and "they agree" are different
/// answers, and a table that quietly omits the second source is the more
/// misleading of the two.
List<_Take> _takes(
  WidgetRef ref,
  Video video,
  List<CrossSourceEntry> counterparts,
) {
  return [
    (
      name: sourceDisplayName(ref, video.sourceId ?? ''),
      sourceId: video.sourceId,
      video: video,
    ),
    for (final c in counterparts)
      (
        name: sourceDisplayName(ref, c.sourceId),
        sourceId: c.sourceId,
        video: ref
            .watch(
              locallyCachedVideoProvider((id: c.videoId, sourceId: c.sourceId)),
            )
            .value,
      ),
  ];
}

/// The four things the catalogs are asked, and what each one answers.
///
/// Only these four: they are what a viewer actually decides on, and they are
/// the fields where the catalogs were observed to disagree. Adding every column
/// the tables happen to carry would bury the three that matter.
const _comparedFields = <({String labelKey, String Function(Video) read})>[
  (labelKey: 'video.section.episodes', read: _readEpisodes),
  (labelKey: 'video.detail.rating', read: _readRating),
  (labelKey: 'video.detail.type', read: _readType),
  (labelKey: 'video.detail.year', read: _readYear),
];

String _readEpisodes(Video v) => '${v.urls?.length ?? 0}';
String _readRating(Video v) => '${v.rating}';
String _readType(Video v) => v.type;
String _readYear(Video v) => v.year ?? '';

/// Indices of the fields the catalogs answer differently.
///
/// Computed over the takes we actually HAVE — a source with nothing cached
/// cannot disagree with anything, and counting it as a difference would put a
/// number on the button that the table then fails to explain.
List<int> _disagreements(List<_Take> takes) {
  final known = [
    for (final t in takes)
      if (t.video != null) t.video!,
  ];
  if (known.length < 2) return const [];
  final out = <int>[];
  for (var i = 0; i < _comparedFields.length; i++) {
    final first = _comparedFields[i].read(known.first);
    if (known.any((v) => _comparedFields[i].read(v) != first)) out.add(i);
  }
  return out;
}

/// `.diffbtn` — a count at rest, a table when asked.
///
/// The count is the whole point of it being collapsed: "3 处不同" is already
/// the answer most people want, and the field-by-field breakdown is for the one
/// time in ten that it matters which three.
class _ComparisonToggle extends StatelessWidget {
  const _ComparisonToggle({
    required this.diffs,
    required this.open,
    required this.onTap,
  });

  final int diffs;
  final bool open;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = VidraTokens.of(context);
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: t.clash.withValues(alpha: 0.36)),
                  color: t.clash.withValues(alpha: 0.12),
                ),
                child: Text(
                  tr('video.detail.source_diffs', args: ['$diffs']),
                  style: TextStyle(
                    fontSize: 9.5,
                    height: 1.5,
                    letterSpacing: 0.8,
                    color: t.clash,
                    fontFeatures: VidraType.data,
                  ),
                ),
              ),
              const SizedBox(width: 7),
              Text(
                tr('video.detail.compare'),
                style: TextStyle(fontSize: 12, height: 1.4, color: t.fg3),
              ),
              Icon(
                open ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                size: 15,
                color: t.fg3,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Field by field, catalog by catalog, with the disagreements marked.
class _ComparisonTable extends StatelessWidget {
  const _ComparisonTable({required this.takes, required this.ownSourceId});

  final List<_Take> takes;
  final String? ownSourceId;

  @override
  Widget build(BuildContext context) {
    final t = VidraTokens.of(context);
    final diffs = _disagreements(takes).toSet();
    final head = VidraType.eyebrow(t.fg3).copyWith(fontSize: 9.5);

    return GlassPanel(
      radius: 14,
      blur: 14,
      saturation: 1.8,
      tint: t.barBg,
      border: t.edgeSoft,
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
      // Horizontal scroll rather than a wrap: source count is a config
      // question, and four catalogs on a narrow window must scroll rather than
      // reflow into something that is no longer a table.
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Table(
          defaultColumnWidth: const IntrinsicColumnWidth(),
          children: [
            TableRow(
              children: [
                _cell(Text('', style: head)),
                for (final take in takes)
                  _cell(
                    Text(
                      take.name,
                      style: head.copyWith(
                        color: take.sourceId == ownSourceId ? t.cyan : t.fg3,
                      ),
                    ),
                  ),
              ],
            ),
            for (var i = 0; i < _comparedFields.length; i++)
              TableRow(
                children: [
                  _cell(
                    Text(
                      tr(_comparedFields[i].labelKey),
                      style: TextStyle(fontSize: 12, height: 1.4, color: t.fg3),
                    ),
                  ),
                  for (final take in takes)
                    _cell(
                      Text(
                        take.video == null
                            ? '—'
                            : _comparedFields[i].read(take.video!),
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.4,
                          fontFeatures: VidraType.data,
                          fontWeight: take.sourceId == ownSourceId
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: take.video == null
                              ? t.fg4
                              : diffs.contains(i)
                              ? t.clash
                              : t.fg2,
                        ),
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _cell(Widget child) =>
      Padding(padding: const EdgeInsets.fromLTRB(0, 4, 24, 4), child: child);
}

/// Pins the episode controls to the top of the scroll view.
///
/// The extent is declared, not measured — that is the contract for a pinned
/// header, and it is why the rows inside are fixed-height and never wrap. It
/// changes only with the source row's presence, which the caller recomputes.
class _EpisodeBarDelegate extends SliverPersistentHeaderDelegate {
  const _EpisodeBarDelegate({required this.extent, required this.child});

  final double extent;
  final Widget child;

  @override
  double get minExtent => extent;

  @override
  double get maxExtent => extent;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlaps) =>
      child;

  @override
  bool shouldRebuild(covariant _EpisodeBarDelegate old) =>
      old.extent != extent || old.child != child;
}

/// Every OTHER catalog known to carry this show, newest-cached first.
///
/// Reads the locally cached catalog rather than the watch history. The history
/// answer excluded the show's own source by construction, so the switcher
/// appeared on every detail page EXCEPT the one the user had actually watched
/// on — the page where switching is most obviously wanted. See
/// [crossSourceCounterpartsProvider], which is also local-only: this fires on
/// every detail page open, and the sources ban IPs under request storms.
List<CrossSourceEntry> _counterpartsOf(WidgetRef ref, Video video) {
  return ref
          .watch(
            crossSourceCounterpartsProvider((
              title: video.title,
              year: video.year,
              sourceId: video.sourceId,
            )),
          )
          .value ??
      const [];
}

/// `.srcrow` — chooses which catalog feeds the episode grid.
///
/// A row of pills rather than a two-tab bar: the number of sources is a config
/// question, not a design constant, and tabs stop working the moment there are
/// four. The row scrolls horizontally instead of wrapping — it sits inside a
/// pinned bar whose height is declared in advance, and a wrapping row would
/// change that height as sources come and go.
class _SourceBar extends ConsumerWidget {
  const _SourceBar({
    required this.video,
    required this.counterparts,
    required this.selected,
    required this.onPick,
  });

  final Video video;
  final List<CrossSourceEntry> counterparts;

  /// The chosen catalog's id, or null for this page's own.
  final String? selected;
  final ValueChanged<String?> onPick;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // EVERY configured catalog, not just the ones already cached. Gating the
    // whole bar on "we have a local counterpart" was true for four shows out of
    // fifty-seven on this database — the cross-source feature was implemented
    // and invisible. A catalog we have not matched yet gets a pill that says so
    // and offers to go and look.
    final all = ref
        .watch(availableDataSourcesProvider)
        .where((s) => s.id != 'mock')
        .toList();
    if (all.length < 2) return const SizedBox.shrink();

    final byId = {for (final c in counterparts) c.sourceId: c};

    // The yardstick: whichever catalog is feeding the grid right now. Deltas
    // are the point of the row — an absolute episode count on four pills makes
    // the reader do the subtraction, which is the one job a UI can do for them.
    final refId = selected;
    final refVideo = refId == null
        ? video
        : ref
              .watch(
                locallyCachedVideoProvider((
                  id: byId[refId]?.videoId ?? video.apiId,
                  sourceId: refId,
                )),
              )
              .value;

    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.zero,
      itemCount: all.length,
      separatorBuilder: (_, _) => const SizedBox(width: 7),
      itemBuilder: (context, i) {
        final source = all[i];
        if (source.id == video.sourceId) {
          return _SourcePill(
            label: source.name,
            videoId: video.apiId,
            sourceId: video.sourceId,
            selected: selected == null,
            reference: refVideo,
            onTap: () => onPick(null),
          );
        }
        final match = byId[source.id];
        if (match != null) {
          return _SourcePill(
            label: source.name,
            videoId: match.videoId,
            sourceId: source.id,
            selected: selected == source.id,
            reference: refVideo,
            onTap: () => onPick(source.id),
          );
        }
        return _UnmatchedSourcePill(
          label: source.name,
          sourceId: source.id,
          title: video.title,
          year: video.year,
        );
      },
    );
  }
}

/// The pill shape both source states share.
class _PillShell extends StatelessWidget {
  const _PillShell({
    required this.children,
    required this.selected,
    required this.onTap,
    this.dimmed = false,
  });

  final List<Widget> children;
  final bool selected;
  final bool dimmed;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = VidraTokens.of(context);
    return Opacity(
      opacity: dimmed ? 0.6 : 1,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Container(
            padding: const EdgeInsets.fromLTRB(10, 5, 13, 5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              gradient: selected
                  ? LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        t.cyan.withValues(alpha: 0.22),
                        t.cyan.withValues(alpha: 0.07),
                      ],
                    )
                  : null,
              color: selected ? null : t.fg.withValues(alpha: 0.045),
              border: Border.all(
                color: selected ? t.cyan.withValues(alpha: 0.42) : t.edgeSoft,
              ),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: children),
          ),
        ),
      ),
    );
  }
}

/// `.src .radio` — which catalog is feeding the grid, stated as a radio
/// because that is exactly what the row is.
class _Radio extends StatelessWidget {
  const _Radio({required this.on});
  final bool on;

  @override
  Widget build(BuildContext context) {
    final t = VidraTokens.of(context);
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: on ? t.cyan : t.fg4, width: 1.5),
        color: on ? t.cyan : Colors.transparent,
        boxShadow: on ? [BoxShadow(color: t.cyanGlow, blurRadius: 10)] : null,
      ),
    );
  }
}

/// `.src .dl` — a delta, not an absolute. Cyan for ahead, clash for behind.
class _Delta extends StatelessWidget {
  const _Delta({required this.text, this.tone});
  final String text;
  final Color? tone;

  @override
  Widget build(BuildContext context) {
    final t = VidraTokens.of(context);
    final c = tone ?? t.fg3;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: tone == null ? t.edgeSoft : c.withValues(alpha: 0.32),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10.5,
          height: 1.5,
          color: c,
          fontFeatures: VidraType.data,
        ),
      ),
    );
  }
}

/// A catalog we have never matched this show on.
///
/// Present rather than omitted, because "not on that catalog" and "we have not
/// looked" are different answers and only one of them is worth acting on. The
/// lookup runs on tap and nowhere else: it costs a search plus a detail fetch
/// against a source that bans IPs under request storms, which is a fine price
/// for something asked for and an unacceptable one for something automatic.
class _UnmatchedSourcePill extends ConsumerStatefulWidget {
  const _UnmatchedSourcePill({
    required this.label,
    required this.sourceId,
    required this.title,
    required this.year,
  });

  final String label;
  final String sourceId;
  final String title;
  final String? year;

  @override
  ConsumerState<_UnmatchedSourcePill> createState() =>
      _UnmatchedSourcePillState();
}

class _UnmatchedSourcePillState extends ConsumerState<_UnmatchedSourcePill> {
  bool _searching = false;
  bool _missing = false;

  Future<void> _look() async {
    if (_searching || _missing) return;
    setState(() => _searching = true);
    try {
      final found = await ref
          .read(videoRepositoryProvider)
          .findOnSource(
            sourceId: widget.sourceId,
            title: widget.title,
            year: widget.year,
          );
      if (!mounted) return;
      // Found: the row is filed now, so the counterpart provider will hand it
      // back as a real pill on the next build.
      if (found != null) {
        ref.invalidate(crossSourceCounterpartsProvider);
      } else {
        setState(() => _missing = true);
      }
    } catch (_) {
      if (mounted) setState(() => _missing = true);
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = VidraTokens.of(context);
    return _PillShell(
      selected: false,
      dimmed: true,
      onTap: _missing ? null : _look,
      children: [
        const _Radio(on: false),
        const SizedBox(width: 8),
        Text(
          widget.label,
          style: TextStyle(fontSize: 12.5, height: 1.4, color: t.fg2),
        ),
        const SizedBox(width: 8),
        if (_searching)
          SizedBox(
            width: 11,
            height: 11,
            child: CircularProgressIndicator(strokeWidth: 1.6, color: t.cyan),
          )
        else
          Text(
            _missing
                ? tr('video.detail.source_absent')
                : tr('video.detail.source_lookup'),
            style: TextStyle(fontSize: 11, height: 1.4, color: t.fg3),
          ),
      ],
    );
  }
}

/// One catalog, with the episode count that decides whether to switch to it.
///
/// The count is the whole reason to offer the switch — one catalog is routinely
/// an episode or two ahead — so it is read here rather than left for the user to
/// discover by switching. Strictly from the local cache: this renders once per
/// source on every detail page open, and a network read per pill is exactly the
/// traffic that gets an IP banned.
class _SourcePill extends ConsumerWidget {
  const _SourcePill({
    required this.label,
    required this.videoId,
    required this.sourceId,
    required this.selected,
    required this.reference,
    required this.onTap,
  });

  final String label;
  final int videoId;
  final String? sourceId;
  final bool selected;

  /// The catalog currently feeding the grid, which this one is measured
  /// against. Null while its own cache read is still in flight.
  final Video? reference;
  final VoidCallback onTap;

  /// "3 小时" / "2 天" — coarse on purpose. The question is which catalog moved
  /// more recently, and to the minute is precision nobody acts on.
  static String _span(Duration d) {
    final h = d.inHours.abs();
    if (h < 1) {
      return tr('common.minutes_short', args: ['${d.inMinutes.abs()}']);
    }
    if (h < 48) return tr('common.hours_short', args: ['$h']);
    return tr('common.days_short', args: ['${d.inDays.abs()}']);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = VidraTokens.of(context);
    final mine = ref
        .watch(locallyCachedVideoProvider((id: videoId, sourceId: sourceId)))
        .value;
    final count = mine?.urls?.length;

    // Only against a DIFFERENT catalog, and only when both sides are known.
    final deltas = <({String text, Color? tone})>[];
    if (!selected && mine != null && reference != null) {
      final ours = mine.urls?.length ?? 0;
      final theirs = reference!.urls?.length ?? 0;
      if (ours != theirs) {
        final diff = ours - theirs;
        deltas.add((
          text: '${diff > 0 ? '+' : '−'}${diff.abs()}',
          tone: diff > 0 ? t.cyan : t.clash,
        ));
      }
      final a = mine.vodTime, b = reference!.vodTime;
      if (a != null && b != null && a > 0 && b > 0 && a != b) {
        final gap = Duration(seconds: (a - b).abs());
        deltas.add((
          text:
              (a > b
                      ? tr('video.detail.newer_by')
                      : tr('video.detail.older_by'))
                  .replaceFirst('{}', _span(gap)),
          tone: null,
        ));
      }
    }

    return _PillShell(
      selected: selected,
      onTap: onTap,
      children: [
        _Radio(on: selected),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            height: 1.4,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected ? t.fg : t.fg2,
          ),
        ),
        // Absent while the catalog has been seen in a listing but never
        // opened, so there is no episode list cached to count.
        if (count != null) ...[
          const SizedBox(width: 8),
          Text(
            tr('video.detail.episode_count', args: ['$count']),
            style: TextStyle(
              fontSize: 12,
              height: 1.4,
              color: selected ? t.fg : t.fg2,
              fontFeatures: VidraType.data,
            ),
          ),
        ],
        for (final d in deltas) ...[
          const SizedBox(width: 6),
          _Delta(text: d.text, tone: d.tone),
        ],
      ],
    );
  }
}

/// One catalog's grid, with every OTHER catalog's progress folded in.
///
/// Watch state belongs to the show, not to whichever catalog served the stream
/// — they are different encodes of the same episode. Before this, opening the
/// source you had NOT watched on showed a wall of untouched tiles beside a badge
/// announcing you were on episode 14, which reads as the app having lost your
/// place.
///
/// [others] is a list because the source count is a config question. Each is
/// read strictly from the local cache and each is optional: whichever ones have
/// a cached episode list contribute, the rest simply do not.
///
/// The join goes through [mergeHistoriesByEpisodeNumber] and never through array
/// position; see its doc for why, and for why the merged map must not be handed
/// to `resolveResumeTarget`.
class _MergedGrid extends ConsumerWidget {
  const _MergedGrid({
    required this.gridVideo,
    required this.others,
    required this.buildGrid,
  });

  final Video gridVideo;

  /// The catalogs to borrow progress from. Empty when this show is known on one
  /// catalog only.
  final List<({int videoId, String? sourceId})> others;

  final Widget Function({
    required Video gridVideo,
    required Map<int, EpisodeHistory> histories,
  })
  buildGrid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ownAsync = ref.watch(
      episodeHistoriesProvider((
        videoId: gridVideo.apiId,
        sourceId: gridVideo.sourceId,
      )),
    );
    return ownAsync.when(
      loading: () => const _EpisodeGridSkeleton(),
      error: (error, _) => Text('Error: $error'),
      data: (own) {
        final borrowFrom = <CatalogProgress>[];
        for (final o in others) {
          // Strictly the local copy. This runs on every detail page open, once
          // per source, and videoByIdProvider would turn each one into a detail
          // request against that catalog — a per-page-open request to sources
          // that ban IPs for exactly that, to draw a checkmark.
          final otherVideo = ref
              .watch(
                locallyCachedVideoProvider((
                  id: o.videoId,
                  sourceId: o.sourceId,
                )),
              )
              .value;
          final otherHistories = ref
              .watch(
                episodeHistoriesProvider((
                  videoId: o.videoId,
                  sourceId: o.sourceId,
                )),
              )
              .value;
          // The borrow is an enhancement, not a precondition. Drawing as soon
          // as this source's own progress is in hand keeps the grid off the
          // other catalogs' critical path; borrowed checkmarks appear as they
          // land, which is a tile repaint rather than a page that sat blank.
          if (otherVideo == null || otherHistories == null) continue;
          if (otherHistories.isEmpty) continue;
          borrowFrom.add((
            episodes: otherVideo.urls ?? const <VideoEpisode>[],
            histories: otherHistories,
          ));
        }
        if (borrowFrom.isEmpty) {
          return buildGrid(gridVideo: gridVideo, histories: own);
        }
        return buildGrid(
          gridVideo: gridVideo,
          histories: mergeHistoriesByEpisodeNumber(
            localEpisodes: gridVideo.urls ?? const <VideoEpisode>[],
            localHistories: own,
            others: borrowFrom,
            episodic: isEpisodicType(gridVideo.type),
          ),
        );
      },
    );
  }
}

/// Placeholder grid while the other catalog's detail loads.
///
/// The real grid's columns and tile height, so switching source reads as "the
/// same list, arriving" rather than a page change. Count is a plausible middle
/// — the real episode count is precisely what is still loading.
class _EpisodeGridSkeleton extends StatelessWidget {
  const _EpisodeGridSkeleton();

  @override
  Widget build(BuildContext context) {
    const min = 104.0, gap = 11.0;
    return LayoutBuilder(
      builder: (context, c) {
        final columns = ((c.maxWidth + gap) / (min + gap)).floor().clamp(1, 99);
        final width = (c.maxWidth - (columns - 1) * gap) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: List.generate(
            columns * 2,
            (_) => SkeletonBox(width: width, height: 86, radius: 14),
          ),
        );
      },
    );
  }
}

/// A chosen catalog's episode list, fetched on demand.
///
/// The one place a network fetch is right: the user asked for this catalog by
/// tapping its pill, so unlike everything else on this page it may reach past
/// the local cache. Everything else — the pills' counts, the borrowed progress
/// — stays local precisely so that this stays the only request.
///
/// Only the GRID switches: playback, per-episode progress and downloads all key
/// on the grid video's own (sourceId, videoId), so watching episode 9 over there
/// records progress over there. The catalogs stay separate histories, exactly
/// like the subscription side of this feature — they are only ever joined for
/// READING, by episode number.
class _AltEpisodes extends ConsumerWidget {
  const _AltEpisodes({
    required this.video,
    required this.pick,
    required this.counterparts,
    required this.buildGrid,
  });

  /// This page's own show — one of the catalogs the chosen grid borrows from.
  final Video video;

  /// The catalog the user picked.
  final CrossSourceEntry pick;

  /// Every counterpart, so the ones NOT picked can still lend progress.
  final List<CrossSourceEntry> counterparts;

  final Widget Function({
    required Video gridVideo,
    required Map<int, EpisodeHistory> histories,
  })
  buildGrid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final altAsync = ref.watch(
      videoByIdProvider((id: pick.videoId, sourceId: pick.sourceId)),
    );
    return altAsync.when(
      loading: () => const _EpisodeGridSkeleton(),
      error: (e, _) => Text('$e'),
      data: (alt) {
        if (alt == null || alt.urls == null || alt.urls!.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(tr('video.player.no_episodes')),
          );
        }
        // Symmetric with the own-source grid: over here it is this page's
        // source, plus every catalog the user did not pick, that has progress
        // to lend.
        return _MergedGrid(
          gridVideo: alt,
          others: [
            (videoId: video.apiId, sourceId: video.sourceId),
            for (final c in counterparts)
              if (c.sourceId != pick.sourceId)
                (videoId: c.videoId, sourceId: c.sourceId),
          ],
          buildGrid: buildGrid,
        );
      },
    );
  }
}
