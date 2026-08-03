import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/services/media_info_service.dart';
import '../../../core/utils/format.dart';
import '../data/download_provider.dart';
import '../data/media_info_provider.dart';
import '../domain/media_info.dart';
import '../../../window/player_window_launcher.dart';
import 'widgets/download_ui.dart';

typedef _QualityOption = ({String value, String label});

class DownloadUrlScreen extends HookConsumerWidget {
  const DownloadUrlScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final parseState = ref.watch(urlParseControllerProvider);

    Future<void> parseUrl(String url) async {
      FocusScope.of(context).unfocus();
      await ref.read(urlParseControllerProvider.notifier).parse(url);
    }

    Future<void> pasteAndParse() async {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      final text = data?.text?.trim();
      if (text == null || text.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(tr('download.url.clipboard_empty'))),
          );
        }
        return;
      }
      await parseUrl(text);
    }

    return Scaffold(
      appBar: AppBar(title: Text(tr('download.url.title'))),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          fullWidthContent(
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: _DropZone(
                loading: parseState.isLoading,
                onTap: parseState.isLoading ? null : pasteAndParse,
              ),
            ),
          ),
          Expanded(
            child: parseState.when(
              loading: () => const SizedBox.shrink(),
              error: (e, _) => fullWidthContent(
                ListView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  children: [
                    _ErrorCard(
                      message: e is String ? e : e.toString(),
                      onRetry: pasteAndParse,
                    ),
                  ],
                ),
              ),
              data: (media) =>
                  media == null ? const SizedBox.shrink() : _ResultList(media),
            ),
          ),
        ],
      ),
    );
  }
}

/// The dashed drop-zone empty state (图1): tap to paste a link and parse.
class _DropZone extends StatelessWidget {
  const _DropZone({required this.loading, required this.onTap});
  final bool loading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    return CustomPaint(
      painter: _DashedRectPainter(
        color: theme.colorScheme.outline.withAlpha(120),
        radius: 12,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 168,
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withAlpha(30),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: loading
                    ? SizedBox(
                        width: 26,
                        height: 26,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          color: theme.colorScheme.primary,
                        ),
                      )
                    : Icon(
                        Icons.download_rounded,
                        size: 26,
                        color: theme.colorScheme.primary,
                      ),
              ),
              const SizedBox(height: 14),
              Text(
                loading
                    ? tr('download.url.parsing')
                    : tr('download.url.dropzone'),
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withAlpha(220),
                  fontSize: 14,
                ),
              ),
              if (!loading) ...[
                const SizedBox(height: 6),
                Text(
                  tr('download.url.dropzone_hint'),
                  style: TextStyle(color: muted, fontSize: 12),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultList extends StatelessWidget {
  const _ResultList(this.media);
  final MediaInfo media;

  @override
  Widget build(BuildContext context) {
    if (media.isPlaylist) {
      return _PlaylistResult(media);
    }

    return fullWidthContent(
      ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          _ResultItemCard(
            title: media.title,
            thumbnailUrl: media.thumbnailUrl,
            durationSecs: media.durationSecs,
            resolution: _maxResolution(media),
            options: _singleQualityOptions(media),
            videoId: videoIdFromUrl(media.webpageUrl),
            episodeUrl: media.webpageUrl,
            coverUrl: media.thumbnailUrl,
            preview: _previewFormat(media),
          ),
        ],
      ),
    );
  }
}

/// Playlist result: a "download all" header (count + one quality + button) over
/// the per-entry cards (each of which can still be grabbed individually).
class _PlaylistResult extends HookConsumerWidget {
  const _PlaylistResult(this.media);
  final MediaInfo media;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final options = _playlistQualityOptions();
    final selected = useState(options.first.value);
    final added = useState(false);
    final busy = useState(false);
    final entries = media.playlistEntries;

    Future<void> downloadAll() async {
      if (busy.value) return;
      busy.value = true;
      final manager = ref.read(downloadManagerProvider);
      final label = options
          .firstWhere(
            (o) => o.value == selected.value,
            orElse: () => (value: selected.value, label: selected.value),
          )
          .label;
      for (var i = 0; i < entries.length; i++) {
        final e = entries[i];
        if (e.url == null) continue;
        await manager.addTask(
          videoId: videoIdFromUrl(e.url!),
          videoTitle: e.title ?? 'Item ${i + 1}',
          coverUrl: e.thumbnail,
          episodes: [
            {
              'index': 0,
              'title': label,
              'url': e.url,
              'formatId': selected.value,
            },
          ],
        );
      }
      busy.value = false;
      added.value = true;
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              tr('download.url.added_all', args: ['${entries.length}']),
            ),
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        fullWidthContent(
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Row(
              children: [
                Text(
                  tr(
                    'download.url.playlist_count',
                    args: ['${entries.length}'],
                  ),
                  style: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 13,
                  ),
                ),
                const Spacer(),
                _QualityDropdown(
                  options: options,
                  value: selected.value,
                  onChanged: (v) => selected.value = v,
                ),
                const SizedBox(width: 10),
                FilledButton.icon(
                  onPressed: busy.value ? null : downloadAll,
                  icon: busy.value
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          added.value
                              ? Icons.check
                              : Icons.download_for_offline,
                          size: 18,
                        ),
                  label: Text(
                    added.value
                        ? tr('download.url.added_badge')
                        : tr('download.url.download_all'),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: fullWidthContent(
            ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              itemCount: entries.length,
              itemBuilder: (context, i) {
                final e = entries[i];
                return _ResultItemCard(
                  title: e.title ?? 'Item ${i + 1}',
                  thumbnailUrl: e.thumbnail,
                  durationSecs: e.duration,
                  resolution: null,
                  options: options,
                  videoId: videoIdFromUrl(e.url ?? '$i'),
                  episodeUrl: e.url,
                  coverUrl: e.thumbnail,
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

/// One parsed media row (图2): thumbnail + title + meta chips, with a quality
/// dropdown and a download button that adds it to the download tasks.
class _ResultItemCard extends HookConsumerWidget {
  const _ResultItemCard({
    required this.title,
    required this.thumbnailUrl,
    required this.durationSecs,
    required this.resolution,
    required this.options,
    required this.videoId,
    required this.episodeUrl,
    required this.coverUrl,
    this.preview,
  });

  final String title;
  final String? thumbnailUrl;
  final double? durationSecs;
  final String? resolution;
  final List<_QualityOption> options;
  final int videoId;
  final String? episodeUrl;
  final String? coverUrl;

  /// The best format that is playable AS IS, or null when none is.
  ///
  /// Independent of the quality dropdown on purpose: the dropdown's HD entries
  /// are `<id>+bestaudio` merge selectors, which are two streams that become
  /// playable only after the muxer runs at download time. A play button wired
  /// to the dropdown would claim to play 1920p and quietly play something else.
  final MediaFormat? preview;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final selected = useState(options.first.value);
    final added = useState(false);
    final busy = useState(false);

    Future<void> download() async {
      if (episodeUrl == null || busy.value) return;
      busy.value = true;
      final label = options
          .firstWhere(
            (o) => o.value == selected.value,
            orElse: () => (value: selected.value, label: selected.value),
          )
          .label;
      await ref
          .read(downloadManagerProvider)
          .addTask(
            videoId: videoId,
            videoTitle: title,
            coverUrl: coverUrl,
            episodes: [
              {
                'index': 0,
                'title': label,
                'url': episodeUrl,
                'formatId': selected.value,
              },
            ],
          );
      busy.value = false;
      added.value = true;
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(tr('download.url.added'))));
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: downloadCardDecoration(theme),
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ThumbWithBadge(
            imageUrl: thumbnailUrl,
            duration: durationSecs != null
                ? formatDuration(durationSecs!.round(), clock: true)
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (resolution != null)
                      MetaChip(resolution!, icon: Icons.aspect_ratio),
                    if (durationSecs != null)
                      MetaChip(
                        '${tr('download.url.duration')} ${formatDuration(durationSecs!.round(), clock: true)}',
                        icon: Icons.schedule,
                        color: theme.colorScheme.primary,
                        filled: false,
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                _PreviewButton(
                  format: preview,
                  title: title,
                  coverUrl: coverUrl,
                  videoId: videoId,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _QualityDropdown(
            options: options,
            value: selected.value,
            onChanged: (v) => selected.value = v,
          ),
          const SizedBox(width: 10),
          if (added.value)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 4),
                Text(
                  tr('download.url.added_badge'),
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            )
          else
            FilledButton.icon(
              onPressed: busy.value ? null : download,
              icon: busy.value
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.download, size: 18),
              label: Text(tr('download.url.download')),
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 11,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _QualityDropdown extends StatelessWidget {
  const _QualityDropdown({
    required this.options,
    required this.value,
    required this.onChanged,
  });
  final List<_QualityOption> options;
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outline.withAlpha(80)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isDense: true,
          borderRadius: BorderRadius.circular(8),
          items: [
            for (final o in options)
              DropdownMenuItem(
                value: o.value,
                child: Text(o.label, style: const TextStyle(fontSize: 13)),
              ),
          ],
          onChanged: (v) => v == null ? null : onChanged(v),
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.error_outline,
                  color: theme.colorScheme.onErrorContainer,
                ),
                const SizedBox(width: 8),
                Text(
                  tr('download.url.parse_failed'),
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.onErrorContainer,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onErrorContainer,
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onRetry,
                child: Text(tr('download.url.retry')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---- quality options -------------------------------------------------------

/// Single-video options: muxed takes precedence at its resolution; higher
/// resolutions are AVC video-only + AAC merges (muxed in-SDK). `/`-fallback
/// drops to a muxed stream when no separate streams exist.
List<_QualityOption> _singleQualityOptions(MediaInfo media) {
  final byHeight = <int, _QualityOption>{};
  for (final f in media.formats.where(
    (f) => f.isAvcMp4VideoOnly && f.height != null,
  )) {
    byHeight.putIfAbsent(
      f.height!,
      () => (value: '${f.formatId}+bestaudio[ext=m4a]', label: '${f.height}p'),
    );
  }
  for (final f in media.muxedFormats.where((f) => f.height != null)) {
    byHeight[f.height!] = (value: f.formatId, label: '${f.height}p');
  }
  final heights = byHeight.keys.toList()..sort((a, b) => b.compareTo(a));
  return [
    for (final h in heights) byHeight[h]!,
    (value: 'bestaudio[ext=m4a]', label: tr('download.url.quality_audio')),
    (value: 'best', label: tr('download.url.quality_best')),
  ];
}

/// Playlist entries are flat (no per-entry formats), so use generic selectors
/// re-applied per entry at download time.
List<_QualityOption> _playlistQualityOptions() {
  _QualityOption res(int h) => (
    value: 'bestvideo[ext=mp4][height<=$h]+bestaudio[ext=m4a]/best[height<=$h]',
    label: '${h}p',
  );
  return [
    (
      value: 'bestvideo[ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]/best',
      label: tr('download.url.quality_best'),
    ),
    res(1080),
    res(720),
    res(480),
    (value: 'bestaudio[ext=m4a]', label: tr('download.url.quality_audio')),
  ];
}

String? _maxResolution(MediaInfo media) {
  MediaFormat? best;
  for (final f in media.formats) {
    if (f.height == null) continue;
    if (best == null || (f.height ?? 0) > (best.height ?? 0)) best = f;
  }
  if (best?.height == null) return null;
  return best!.width != null
      ? '${best.width}x${best.height}'
      : '${best.height}p';
}

/// Dashed rounded-rectangle border for the drop-zone.
class _DashedRectPainter extends CustomPainter {
  _DashedRectPainter({required this.color, required this.radius});
  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);
    const dash = 6.0;
    const gap = 4.0;
    for (final metric in path.computeMetrics()) {
      var dist = 0.0;
      while (dist < metric.length) {
        canvas.drawPath(metric.extractPath(dist, dist + dash), paint);
        dist += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedRectPainter old) =>
      old.color != color || old.radius != radius;
}

/// The highest-resolution format that plays without muxing, or null.
///
/// Single-file only: everything above it in the dropdown is a video-only
/// stream paired with `bestaudio`, and two streams are not something a player
/// can open. Selected by [MediaFormat.isPlayableAlone] rather than isMuxed —
/// a progressive file described without codec info is still one file, and
/// requiring both codecs to be *stated* silently excluded every Bilibili
/// link. The button names the resolution it will actually play rather than
/// borrowing the dropdown's.
MediaFormat? _previewFormat(MediaInfo media) {
  MediaFormat? best;
  for (final f in media.formats.where((f) => f.isPlayableAlone)) {
    if (f.url == null || f.url!.isEmpty) continue;
    if (best == null || (f.height ?? 0) > (best.height ?? 0)) best = f;
  }
  return best;
}

/// Plays the one format that needs no muxing.
///
/// Deliberately quiet: the download button beside it is the primary action and
/// owns the accent colour. Two red controls side by side read as two equal
/// choices, and this one is a preview at whatever resolution happens to ship
/// muxed — usually well below what the dropdown offers.
class _PreviewButton extends StatelessWidget {
  const _PreviewButton({
    required this.format,
    required this.title,
    required this.coverUrl,
    required this.videoId,
  });

  final MediaFormat? format;
  final String title;
  final String? coverUrl;
  final int videoId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final f = format;
    // Disabled-with-a-reason, never absent. A button that vanishes when the
    // link has no single-stream format is indistinguishable from one that
    // broke — which is exactly the question it prompted the first time a
    // three-hour video (no progressive format on YouTube) came through.
    if (f == null) {
      return Tooltip(
        message: tr('download.url.preview_none'),
        child: OutlinedButton.icon(
          onPressed: null,
          icon: const Icon(Icons.play_disabled_rounded, size: 16),
          label: Text(tr('download.url.preview_unavailable')),
          style: OutlinedButton.styleFrom(
            foregroundColor: theme.colorScheme.onSurfaceVariant.withAlpha(110),
            side: BorderSide(color: theme.colorScheme.outline.withAlpha(45)),
            textStyle: const TextStyle(fontSize: 12.5),
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      );
    }
    final quality = f.height != null ? '${f.height}p' : f.ext;
    return Tooltip(
      message: tr('download.url.preview_hint', args: [quality]),
      child: OutlinedButton.icon(
        onPressed: () => PlayerWindowLauncher.open(
          videoId: videoId,
          episodeIndex: 0,
          directUrl: f.url,
          directTitle: title,
          directCoverUrl: coverUrl,
        ),
        icon: const Icon(Icons.play_arrow_rounded, size: 16),
        label: Text('${tr('download.url.preview')} $quality'),
        style: OutlinedButton.styleFrom(
          foregroundColor: theme.colorScheme.onSurfaceVariant,
          side: BorderSide(color: theme.colorScheme.outline.withAlpha(80)),
          textStyle: const TextStyle(fontSize: 12.5),
          visualDensity: VisualDensity.compact,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}
