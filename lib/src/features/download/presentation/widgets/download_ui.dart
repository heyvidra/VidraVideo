import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Shared flat card box for download rows: surface fill, 14 radius, hairline.
BoxDecoration downloadCardDecoration(ThemeData theme) => BoxDecoration(
  color: theme.colorScheme.surface,
  borderRadius: BorderRadius.circular(14),
  border: Border.all(color: theme.colorScheme.onSurface.withAlpha(16)),
);

/// Left-align content next to the sidebar and cap its width, so it neither
/// stretches across ultra-wide windows nor floats in the middle with a big gap.
/// The link-download screen fills its pane instead of capping at [maxWidth].
///
/// A parsed result is one wide row — thumbnail, a long title, meta chips, then
/// the controls — and the 1000px cap squeezed the title into two truncated
/// lines while leaving a third of the window empty beside it. The download LIST
/// keeps the cap: it is a column of short rows, and a full-width line of them
/// on a wide display is harder to read, not easier.
Widget fullWidthContent(Widget child) => child;

Widget constrainedContent(Widget child, {double maxWidth = 1000}) {
  return Align(
    alignment: Alignment.topLeft,
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: child,
    ),
  );
}

/// Subtle surface overlay that adapts to light/dark (white-ish on dark bg,
/// black-ish on light). Used for chip/ghost-button backgrounds.
Color _overlay(ThemeData theme, int alpha) =>
    theme.colorScheme.onSurface.withAlpha(alpha);

/// Small rounded meta pill (resolution, size, status…). [color] tints text+icon;
/// [filled] false renders bare text (e.g. the red "时长/速度" bits).
class MetaChip extends StatelessWidget {
  const MetaChip(
    this.text, {
    super.key,
    this.icon,
    this.color,
    this.filled = true,
  });

  final String text;
  final IconData? icon;
  final Color? color;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fg = color ?? theme.colorScheme.onSurfaceVariant;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: filled ? 7 : 0, vertical: 2),
      decoration: filled
          ? BoxDecoration(
              color: _overlay(theme, 16),
              borderRadius: BorderRadius.circular(5),
            )
          : null,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(
              fontSize: 11.5,
              color: fg,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// 34×34 ghost icon button — the unified action control on download cards.
class GhostIconButton extends StatelessWidget {
  const GhostIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.color,
    this.size = 34,
    this.iconSize = 18,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final Color? color;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final btn = SizedBox(
      width: size,
      height: size,
      child: Material(
        color: _overlay(theme, 16),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onPressed,
          child: Icon(
            icon,
            size: iconSize,
            color: color ?? theme.colorScheme.onSurface.withAlpha(210),
          ),
        ),
      ),
    );
    return tooltip == null ? btn : Tooltip(message: tooltip!, child: btn);
  }
}

/// Rounded thumbnail with an optional duration pill (bottom-right) and a corner
/// badge (top-left, e.g. status dot / completed check). [imageUrl] must already
/// be resolved (http URL); null → placeholder.
class ThumbWithBadge extends StatelessWidget {
  const ThumbWithBadge({
    super.key,
    required this.imageUrl,
    this.width = 118,
    this.height = 70,
    this.radius = 8,
    this.duration,
    this.cornerBadge,
  });

  final String? imageUrl;
  final double width;
  final double height;
  final double radius;
  final String? duration;
  final Widget? cornerBadge;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget placeholder() => Container(
      width: width,
      height: height,
      color: theme.colorScheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: Icon(
        Icons.movie_outlined,
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );

    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(radius),
            child: imageUrl == null
                ? placeholder()
                : CachedNetworkImage(
                    imageUrl: imageUrl!,
                    width: width,
                    height: height,
                    fit: BoxFit.cover,
                    placeholder: (_, _) => placeholder(),
                    errorWidget: (_, _, _) => placeholder(),
                  ),
          ),
          if (duration != null)
            Positioned(
              right: 4,
              bottom: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(180),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  duration!,
                  style: const TextStyle(fontSize: 10.5, color: Colors.white),
                ),
              ),
            ),
          if (cornerBadge != null)
            Positioned(left: 4, top: 4, child: cornerBadge!),
        ],
      ),
    );
  }
}
