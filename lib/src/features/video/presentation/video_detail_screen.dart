import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
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
    final theme = Theme.of(context);
    // Robust ID parsing
    final id =
        int.tryParse(videoId) ?? (double.tryParse(videoId)?.toInt() ?? -1);

    final videoAsync = ref.watch(
      videoByIdProvider((id: id, sourceId: sourceId)),
    );
    final isAscending = useState(true);
    final isDownloadMode = useState(false);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        iconTheme: IconThemeData(color: theme.colorScheme.onSurface),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        backgroundColor: Colors.transparent,
      ),
      body: videoAsync.when(
        data: (video) {
          if (video == null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.search_off, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    '${tr('video.detail.not_found')}\n(ID: $videoId, Source: ${sourceId ?? 'default'})',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }
          return ScrollConfiguration(
            behavior: ScrollConfiguration.of(
              context,
            ).copyWith(scrollbars: false),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header section (Backdrop, title, action buttons)
                  VideoDetailHeader(
                    video: video,
                    isDownloadMode: isDownloadMode,
                  ),

                  // Content section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Episode list and sorting
                        EpisodeSection(
                          video: video,
                          isAscending: isAscending,
                          isDownloadMode: isDownloadMode,
                        ),

                        // Storyline and additional details
                        VideoInfoSection(video: video),

                        const SizedBox(height: 48),
                      ],
                    ),
                  ),
                ],
              ),
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

    final theme = Theme.of(context);
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 500,
            width: double.infinity,
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
                    errorWidget: (_, _, _) => Container(
                      color: theme.brightness == Brightness.dark
                          ? Colors.grey[900]
                          : Colors.grey[300],
                    ),
                  ),
                ),
                // The same wash the real header uses, so the moment the data
                // lands nothing shifts.
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.0, 0.5, 0.95],
                      colors: [
                        Colors.transparent,
                        theme.scaffoldBackgroundColor.withValues(alpha: 0.5),
                        theme.scaffoldBackgroundColor,
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 24,
                  right: 24,
                  child: Text(
                    video.title,
                    style: theme.textTheme.displayLarge?.copyWith(fontSize: 48),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: VideoDetailSkeleton(),
          ),
        ],
      ),
    );
  }
}
