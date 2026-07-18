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

class VideoDetailScreen extends HookConsumerWidget {
  final String videoId;
  final String? sourceId;

  const VideoDetailScreen({super.key, required this.videoId, this.sourceId});

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
        loading: () => const VideoDetailSkeleton(),
        error: (error, stack) => Center(
          child: Text('${tr("video.detail.error")}: $error (ID: $videoId)'),
        ),
      ),
    );
  }
}
