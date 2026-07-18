import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:vidra/src/features/video/domain/video_collection.dart';
import 'package:vidra/src/features/video/data/video_repository.dart';
import 'package:vidra/src/window/player_window_launcher.dart';

class VideoDetailHeader extends ConsumerWidget {
  final Video video;
  final ValueNotifier<bool> isDownloadMode;

  const VideoDetailHeader({
    super.key,
    required this.video,
    required this.isDownloadMode,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final repository = ref.read(videoRepositoryProvider);

    return SizedBox(
      height: 500,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CachedNetworkImage(
            imageUrl: (video.backdropUrl ?? video.coverUrl).startsWith('http')
                ? (video.backdropUrl ?? video.coverUrl)
                : repository.resolveUrl(video.backdropUrl ?? video.coverUrl),
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: theme.brightness == Brightness.dark
                  ? Colors.black
                  : Colors.grey[200],
            ),
            errorWidget: (context, url, error) => Container(
              color: theme.brightness == Brightness.dark
                  ? Colors.grey[900]
                  : Colors.grey[300],
            ),
          ),
          // Gradient Overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [
                  0.0,
                  0.5,
                  0.95,
                ], // Ensure fully opaque before edge
                colors: [
                  Colors.transparent,
                  theme.scaffoldBackgroundColor.withValues(alpha: 0.5),
                  theme.scaffoldBackgroundColor,
                ],
              ),
            ),
          ),
          // Anti-aliasing sub-pixel gap fix
          Positioned(
            bottom: -1,
            left: 0,
            right: 0,
            height: 2,
            child: Container(color: theme.scaffoldBackgroundColor),
          ),
          // Content Overlay
          Positioned(
            bottom: 0,
            left: 24,
            right: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  video.title,
                  style: theme.textTheme.displayLarge?.copyWith(
                    fontSize: 48,
                    shadows: [
                      Shadow(
                        color: isDark
                            ? Colors.black.withAlpha(150)
                            : Colors.white.withAlpha(150),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 20),
                    const SizedBox(width: 8),
                    _InfoBadge(
                      label:
                          '${video.rating}${tr("video.detail.rating_suffix")}',
                    ),
                    const SizedBox(width: 16),
                    _InfoBadge(label: video.year.toString()),
                    const SizedBox(width: 16),
                    _TypeBadge(label: video.type.toUpperCase()),
                  ],
                ),
                const SizedBox(height: 24),
                // Action Buttons
                Row(
                  children: [
                    _PlayButton(video: video),
                    const SizedBox(width: 16),
                    _DownloadButton(
                      video: video,
                      isDownloadMode: isDownloadMode,
                    ),
                  ],
                ),
                const SizedBox(height: 48),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoBadge extends StatelessWidget {
  final String label;
  const _InfoBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface.withAlpha(isDark ? 30 : 15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.onSurface,
        ),
      ),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  final String label;
  const _TypeBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.onSurface.withAlpha(50)),
        borderRadius: BorderRadius.circular(4),
        color: theme.colorScheme.onSurface.withAlpha(isDark ? 30 : 15),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: theme.colorScheme.onSurface,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _PlayButton extends StatelessWidget {
  final Video video;
  const _PlayButton({required this.video});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ElevatedButton.icon(
      onPressed: () async {
        final episodes = video.urls ?? [];
        if (episodes.isNotEmpty) {
          await PlayerWindowLauncher.open(
            videoId: video.apiId,
            episodeIndex: 0,
            sourceId: video.sourceId,
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(tr('video.detail.no_episodes_play'))),
          );
        }
      },
      icon: const Icon(Icons.play_arrow),
      label: Text(tr('video.detail.play_now')),
      style: ElevatedButton.styleFrom(
        backgroundColor: theme.primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

class _DownloadButton extends StatelessWidget {
  final Video video;
  final ValueNotifier<bool> isDownloadMode;

  const _DownloadButton({required this.video, required this.isDownloadMode});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ValueListenableBuilder<bool>(
      valueListenable: isDownloadMode,
      builder: (context, downloadMode, child) {
        return OutlinedButton.icon(
          onPressed: () {
            if ((video.urls ?? []).isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(tr('video.detail.no_episodes'))),
              );
              return;
            }
            isDownloadMode.value = !isDownloadMode.value;
          },
          icon: Icon(downloadMode ? Icons.close : Icons.download),
          label: Text(
            downloadMode
                ? tr('video.detail.done')
                : tr('video.detail.download'),
          ),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            side: BorderSide(
              color: downloadMode ? Colors.red : theme.colorScheme.onSurface,
            ),
            foregroundColor: downloadMode
                ? Colors.red
                : theme.colorScheme.onSurface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      },
    );
  }
}
