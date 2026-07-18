import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer_animation/shimmer_animation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vidra/src/features/video/data/video_repository.dart';
import 'package:vidra/src/features/video/domain/video_collection.dart';

class PopularVideoCard extends ConsumerStatefulWidget {
  final Video video;
  final bool showDetails;
  final bool enableHover;

  const PopularVideoCard({
    super.key,
    required this.video,
    this.showDetails = true,
    this.enableHover = true,
  });

  @override
  ConsumerState<PopularVideoCard> createState() => _PopularVideoCardState();
}

class _PopularVideoCardState extends ConsumerState<PopularVideoCard>
    with SingleTickerProviderStateMixin {
  bool isHovered = false;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

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
  }

  @override
  void dispose() {
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: () {
        final sourceId = widget.video.sourceId;
        final path = sourceId != null
            ? '/detail/${widget.video.apiId}?sourceId=$sourceId'
            : '/detail/${widget.video.apiId}';
        context.push(path);
      },
      child: MouseRegion(
        onEnter: widget.enableHover
            ? (_) {
                setState(() => isHovered = true);
                _controller.forward();
              }
            : null,
        onExit: widget.enableHover
            ? (_) {
                setState(() => isHovered = false);
                _controller.reverse();
              }
            : null,
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(scale: _scaleAnimation.value, child: child);
          },
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(8),
              border:
                  Theme.of(context).cardTheme.shape is RoundedRectangleBorder
                  ? Border.fromBorderSide(
                      (Theme.of(context).cardTheme.shape
                              as RoundedRectangleBorder)
                          .side,
                    )
                  : null,
              boxShadow: isHovered
                  ? [
                      BoxShadow(
                        color: Colors.black.withAlpha(50),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withAlpha(isDark ? 0 : 15),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            clipBehavior: Clip.antiAlias,
            child: isHovered ? _buildHoverContent() : _buildNormalContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildNormalContent() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Image Area
        Expanded(
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Cover Image
              CachedNetworkImage(
                imageUrl: ref
                    .read(videoRepositoryProvider)
                    .resolveUrl(
                      widget.video.coverUrl,
                      sourceId: widget.video.sourceId,
                    ),
                fit: BoxFit.cover,
                placeholder: (context, url) => Shimmer(
                  duration: const Duration(seconds: 2),
                  interval: const Duration(milliseconds: 500),
                  color: isDark
                      ? Colors.white.withAlpha(80)
                      : Colors.black.withAlpha(20),
                  enabled: true,
                  direction: const ShimmerDirection.fromLTRB(),
                  child: Container(
                    color: isDark ? Colors.grey[800] : Colors.grey[200],
                  ),
                ),
                errorWidget: (context, url, err) => Container(
                  color: isDark ? Colors.grey[900] : Colors.grey[300],
                ),
              ),

              // Badges (Top Left)
              Positioned(
                top: 8,
                left: 8,
                child: Row(
                  children: [
                    if (widget.video.version != null &&
                        widget.video.version!.isNotEmpty)
                      _buildBadge(
                        widget.video.version!,
                        const Color(0xFF2196F3),
                      ), // Blue
                    if (widget.video.version != null) const SizedBox(width: 4),
                    // "Latest" or other badges
                    if ((DateTime.now()
                            .difference(
                              DateTime.fromMillisecondsSinceEpoch(
                                (widget.video.vodTime ?? 0) * 1000,
                              ),
                            )
                            .inDays <
                        7))
                      _buildBadge(
                        tr('video.detail.new_badge'),
                        const Color(0xFFFF9800),
                      ), // Orange
                  ],
                ),
              ),

              // Score (Top Right)
              Positioned(
                top: 8,
                right: 8,
                child: Text(
                  "${widget.video.rating}",
                  style: TextStyle(
                    color: const Color(0xFFFF9800), // Orange
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    shadows: [
                      Shadow(
                        blurRadius: 4,
                        color: Colors.black.withAlpha(150),
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom Overlay
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Colors.black.withAlpha(180), Colors.transparent],
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.whatshot,
                        color: Color(0xFFFF5722),
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatHits(widget.video.hits),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (widget.video.remarks != null)
                        Expanded(
                          child: Text(
                            widget.video.remarks!, // e.g. "更新至第05集"
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            textAlign: TextAlign.right,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Items below image (Image 1 style)
        if (widget.showDetails)
          Padding(
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
                const SizedBox(height: 4),
                Text(
                  widget.video.actor ?? (widget.video.blurb ?? ""),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildHoverContent() {
    final theme = Theme.of(context);

    return Stack(
      fit: StackFit.expand,
      children: [
        // Background Image (Darkened)
        CachedNetworkImage(
          imageUrl: ref
              .read(videoRepositoryProvider)
              .resolveUrl(widget.video.coverUrl),
          fit: BoxFit.cover,
          color: Colors.black.withAlpha(100),
          colorBlendMode: BlendMode.darken,
          placeholder: (context, url) => Shimmer(
            duration: const Duration(seconds: 2),
            interval: const Duration(milliseconds: 500),
            color: Colors.white.withAlpha(50),
            enabled: true,
            direction: const ShimmerDirection.fromLTRB(),
            child: Container(color: Colors.grey[800]),
          ),
        ),

        // Badges & Rating (Keep them visible)
        Positioned(
          top: 8,
          left: 8,
          child: Row(
            children: [
              if (widget.video.version != null &&
                  widget.video.version!.isNotEmpty)
                _buildBadge(widget.video.version!, const Color(0xFF2196F3)),
              if ((DateTime.now()
                      .difference(
                        DateTime.fromMillisecondsSinceEpoch(
                          (widget.video.vodTime ?? 0) * 1000,
                        ),
                      )
                      .inDays <
                  7))
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: _buildBadge(
                    tr('video.detail.new_badge'),
                    const Color(0xFFFF9800),
                  ),
                ),
            ],
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: Text(
            "${widget.video.rating}",
            style: const TextStyle(
              color: Color(0xFFFF9800),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

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

                // Tags (Type, Region, Year)
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    _buildTag(theme, widget.video.type),
                    _buildTag(theme, widget.video.region ?? ''),
                    _buildTag(theme, widget.video.year ?? ''),
                  ],
                ),
                const SizedBox(height: 4),

                // Date/Add time
                Text(
                  tr(
                    'video.detail.added_date',
                    args: [
                      DateTime.fromMillisecondsSinceEpoch(
                        (widget.video.vodTime ?? 0) * 1000,
                      ).toString().split(' ')[0],
                    ],
                  ),
                  style: const TextStyle(color: Colors.grey, fontSize: 11),
                ),
                const SizedBox(height: 2),

                // Actor
                if (widget.video.actor != null)
                  Text(
                    tr('video.detail.cast_info', args: [widget.video.actor!]),
                    style: const TextStyle(color: Colors.grey, fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 2),

                // Simple Blurb/Summary
                if (widget.video.blurb != null)
                  Text(
                    "${tr('video.detail.storyline')}: ${widget.video.blurb}",
                    style: const TextStyle(color: Colors.grey, fontSize: 11),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ),
        Positioned(
          top: 70,
          left: 0,
          right: 0,
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white70, width: 5),
            ),
            child: const Icon(
              Icons.play_arrow,
              color: Colors.white70,
              size: 32,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildTag(ThemeData theme, String text) {
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(isDark ? 30 : 50),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 10),
      ),
    );
  }
}
