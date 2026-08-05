import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:vidra/src/config/design_tokens.dart';
import 'package:vidra/src/features/video/data/video_repository.dart';
import 'package:vidra/src/features/video/presentation/widgets/detail/video_detail_header.dart';
import 'package:vidra/src/features/video/presentation/widgets/detail/episode_section.dart';
import 'package:vidra/src/features/video/presentation/widgets/detail/video_info_section.dart';
import 'package:vidra/src/common/skeleton/video_detail_skeleton.dart';
import 'package:vidra/src/features/video/domain/video_collection.dart';
import 'package:vidra/src/features/video/presentation/widgets/cards/popular_video_card.dart';

class VideoDetailScreen extends HookConsumerWidget {
  final String videoId;
  final String? sourceId;

  /// What the tapped card already knew, handed over at push time.
  ///
  /// The page's own fetch is async, so without this the route opens on a
  /// skeleton — and a Hero with nothing to fly TO simply does not animate.
  /// That is why the transition worked on the way back (the card was still
  /// there) and did nothing on the way in. Null on a deep link.
  final Video? seed;

  const VideoDetailScreen({
    super.key,
    required this.videoId,
    this.sourceId,
    this.seed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Robust ID parsing
    final id =
        int.tryParse(videoId) ?? (double.tryParse(videoId)?.toInt() ?? -1);

    final videoAsync = ref.watch(
      videoByIdProvider((id: id, sourceId: sourceId)),
    );
    final isAscending = useState(true);
    final isDownloadMode = useState(false);
    // Owned here rather than inside EpisodeSection: its pinned bar and its grid
    // are two separate slivers now, and they have to agree on which catalog is
    // selected.
    final selectedSource = useState<String?>(null);
    final lastRefresh = useState<DateTime?>(null);
    final showComparison = useState(false);

    // No app bar. The window's own toolbar carries the back button and the
    // search field — a page-level toolbar here put a second search box eight
    // pixels below the first one.
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: videoAsync.when(
        data: (video) {
          if (video == null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.search_off,
                    size: 64,
                    color: VidraTokens.of(context).fg4,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${tr('video.detail.not_found')}\n(ID: $videoId, Source: ${sourceId ?? 'default'})',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: VidraTokens.of(context).fg3),
                  ),
                ],
              ),
            );
          }
          return ScrollConfiguration(
            behavior: ScrollConfiguration.of(
              context,
            ).copyWith(scrollbars: false),
            // Slivers, not a Column in a SingleChildScrollView: the episode
            // controls pin to the top while the grid scrolls under them, and
            // only a sliver can do that. Switching source is only ever done to
            // see what it does to the grid, so on a long show the control and
            // its effect must not scroll apart.
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: VideoDetailHeader(
                    video: video,
                    isDownloadMode: isDownloadMode,
                  ),
                ),

                // Episode controls (pinned) and the grid
                ...EpisodeSection(
                  video: video,
                  isAscending: isAscending,
                  isDownloadMode: isDownloadMode,
                  selectedSource: selectedSource,
                  lastRefresh: lastRefresh,
                  showComparison: showComparison,
                ).slivers(context, ref),

                // Storyline and additional details
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 32),
                  sliver: SliverToBoxAdapter(
                    child: VideoInfoSection(video: video),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => _LoadingWithCover(seed: seed),
        error: (error, stack) => Center(
          child: Text('${tr("video.detail.error")}: $error (ID: $videoId)'),
        ),
      ),
    );
  }
}

/// The skeleton, but with the real cover already in place at the top.
///
/// The cover is the Hero's landing pad: it has to exist the instant the route
/// is pushed, not when the fetch returns, or the flight has no destination and
/// the card simply blinks out of existence. Everything below it stays a
/// skeleton until the data arrives.
class _LoadingWithCover extends StatelessWidget {
  const _LoadingWithCover({required this.seed});

  final Video? seed;

  @override
  Widget build(BuildContext context) {
    final video = seed;
    if (video == null) return const VideoDetailSkeleton();

    final t = VidraTokens.of(context);
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // The same 176px card the loaded page opens with, so nothing jumps
          // when the fetch lands.
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
            child: SizedBox(
              height: 176,
              width: double.infinity,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Hero(
                      tag: videoPosterHeroTag(video),
                      child: CachedNetworkImage(
                        imageUrl: video.coverUrl.startsWith('http')
                            ? video.coverUrl
                            : ProviderScope.containerOf(context)
                                  .read(videoRepositoryProvider)
                                  .resolveUrl(
                                    video.coverUrl,
                                    sourceId: video.sourceId,
                                  ),
                        fit: BoxFit.cover,
                        errorWidget: (_, _, _) =>
                            ColoredBox(color: t.fg.withValues(alpha: 0.08)),
                      ),
                    ),
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
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: VideoDetailSkeleton(),
          ),
        ],
      ),
    );
  }
}
