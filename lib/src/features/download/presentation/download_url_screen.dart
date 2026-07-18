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
          constrainedContent(
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
              error: (e, _) => constrainedContent(
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

    return constrainedContent(ListView(
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
        ),
      ],
    ));
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
          .firstWhere((o) => o.value == selected.value,
              orElse: () => (value: selected.value, label: selected.value))
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
        constrainedContent(
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Row(
              children: [
                Text(
                  tr('download.url.playlist_count', args: ['${entries.length}']),
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
                      : Icon(added.value ? Icons.check : Icons.download_for_offline,
                          size: 18),
                  label: Text(
                    added.value
                        ? tr('download.url.added_badge')
                        : tr('download.url.download_all'),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: constrainedContent(
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
  });

  final String title;
  final String? thumbnailUrl;
  final double? durationSecs;
  final String? resolution;
  final List<_QualityOption> options;
  final int videoId;
  final String? episodeUrl;
  final String? coverUrl;

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
          .firstWhere((o) => o.value == selected.value,
              orElse: () => (value: selected.value, label: selected.value))
          .label;
      await ref.read(downloadManagerProvider).addTask(
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('download.url.added'))),
        );
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
            duration: durationSecs != null ? formatDuration(durationSecs!.round(), clock: true) : null,
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
                Icon(Icons.check_circle,
                    size: 16, color: theme.colorScheme.primary),
                const SizedBox(width: 4),
                Text(tr('download.url.added_badge'),
                    style: TextStyle(
                        fontSize: 12, color: theme.colorScheme.primary)),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
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
                Icon(Icons.error_outline,
                    color: theme.colorScheme.onErrorContainer),
                const SizedBox(width: 8),
                Text(tr('download.url.parse_failed'),
                    style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.onErrorContainer)),
              ],
            ),
            const SizedBox(height: 8),
            Text(message,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onErrorContainer)),
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
  for (final f
      in media.formats.where((f) => f.isAvcMp4VideoOnly && f.height != null)) {
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
  return best!.width != null ? '${best.width}x${best.height}' : '${best.height}p';
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
        canvas.drawPath(
          metric.extractPath(dist, dist + dash),
          paint,
        );
        dist += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedRectPainter old) =>
      old.color != color || old.radius != radius;
}
