import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:vidra/src/features/video/domain/video_collection.dart';

class VideoInfoSection extends StatelessWidget {
  final Video video;

  const VideoInfoSection({super.key, required this.video});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left column: Storyline
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr('video.section.storyline'),
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    video.content ??
                        video.blurb ??
                        tr('video.section.no_description'),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      height: 1.6,
                      color: theme.colorScheme.onSurface.withAlpha(200),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 48),
            // Right column: Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr('video.section.details'),
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  _DetailRow(
                    label: tr('video.detail.director'),
                    value: video.director ?? tr('video.detail.unknown'),
                  ),
                  // _DetailRow(
                  //   label: tr('video.detail.writer'),
                  //   value: video.writer ?? tr('video.detail.unknown'),
                  // ),
                  _DetailRow(
                    label: tr('video.detail.cast'),
                    value: video.actor ?? tr('video.detail.unknown'),
                  ),
                  _DetailRow(
                    label: tr('video.detail.updated'),
                    value: video.vodTime != null && video.vodTime! > 0
                        ? DateFormat('yyyy-MM-dd HH:mm').format(
                            DateTime.fromMillisecondsSinceEpoch(
                              video.vodTime! > 9999999999
                                  ? video.vodTime!
                                  : video.vodTime! * 1000,
                            ),
                          )
                        : tr('video.detail.unknown'),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 48),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurface.withAlpha(120),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
