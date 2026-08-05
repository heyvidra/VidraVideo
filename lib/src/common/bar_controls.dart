import 'package:flutter/material.dart';

import '../config/design_tokens.dart';

/// The two control shapes the window's bars are built from.
///
/// They exist because the toolbar had grown four: the bell was a 24px filled
/// glyph in a 48px Material hit box, the language switcher a 20px one in a
/// 36px circle, the pin and theme toggles 17px in 32px, and the source
/// switcher a 24px filled icon beside unstyled text — each with its own idea
/// of what "the muted colour" was (`white70`, `onSurface`, `fg2`). Nothing was
/// wrong individually; together they read as a row assembled from spare parts.
///
/// One size (17), one colour pair (`fg2` at rest, `cyan` when active), one hit
/// box (32), one hover treatment. Outlined and rounded throughout — a filled
/// glyph beside outlined ones reads as permanently selected.

/// A control in a window bar: one icon, nothing else.
///
/// [onTap] is optional because some of these are the trigger for a dropdown
/// that handles the gesture itself; the hover state does not depend on it.
class BarIcon extends StatefulWidget {
  const BarIcon({
    super.key,
    required this.icon,
    this.tooltip,
    this.onTap,
    this.active = false,
    this.badge,
    this.wrap,
  });

  final IconData icon;
  final String? tooltip;
  final VoidCallback? onTap;

  /// Carries a meaning, not just a pressed state — the pin when the window is
  /// actually on top, the bell when something is actually waiting.
  final bool active;

  /// A count laid over the icon's top-right corner.
  final String? badge;

  /// Wraps the icon before it is placed — for the bell's swing, which has to
  /// rotate the glyph without owning its size or colour.
  final Widget Function(BuildContext context, Widget icon)? wrap;

  /// The one icon size in the bars.
  static const double iconSize = 17;

  /// The one hit box.
  static const double boxSize = 32;

  @override
  State<BarIcon> createState() => _BarIconState();
}

class _BarIconState extends State<BarIcon> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final t = VidraTokens.of(context);
    final color = widget.active ? t.cyan : t.fg2;

    Widget glyph = Icon(widget.icon, size: BarIcon.iconSize, color: color);
    if (widget.wrap != null) glyph = widget.wrap!(context, glyph);

    Widget box = Container(
      width: BarIcon.boxSize,
      height: BarIcon.boxSize,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _hover ? t.fg.withValues(alpha: 0.07) : Colors.transparent,
      ),
      child: widget.badge == null
          ? glyph
          : Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                glyph,
                Positioned(top: 1, right: 1, child: _Badge(widget.badge!)),
              ],
            ),
    );

    if (widget.onTap != null) {
      box = GestureDetector(onTap: widget.onTap, child: box);
    }
    box = MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: box,
    );
    return widget.tooltip == null
        ? box
        : Tooltip(message: widget.tooltip!, child: box);
  }
}

/// The count over the bell.
///
/// Ringed in the PAGE colour rather than `colorScheme.surface`: every surface
/// in this design is translucent, so a ring in one was a ring in nothing and
/// the badge bled into the glyph underneath it.
class _Badge extends StatelessWidget {
  const _Badge(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final t = VidraTokens.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      constraints: const BoxConstraints(minWidth: 14),
      decoration: BoxDecoration(
        color: t.amber,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: t.pageB, width: 1.5),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: t.onAmber,
          fontSize: 8.5,
          height: 1.45,
          fontWeight: FontWeight.w800,
          fontFeatures: VidraType.data,
        ),
      ),
    );
  }
}

/// `.chipbtn` — a named value you can change: "片源 测试欧乐影院 ▾".
///
/// The label stays visible beside the value, because a lone 测试欧乐影院 on a
/// toolbar does not say what it is the source OF. The value is capped and
/// elided rather than allowed to push its neighbours off the bar.
class BarChip extends StatelessWidget {
  const BarChip({
    super.key,
    required this.label,
    required this.value,
    this.active = false,
    this.maxValueWidth = 150,
    this.onTap,
  });

  final String label;
  final String value;

  /// Whether this chip is narrowing something — a filter with a value picked.
  final bool active;
  final double maxValueWidth;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = VidraTokens.of(context);
    final chip = Container(
      padding: const EdgeInsets.fromLTRB(12, 5, 8, 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: active
            ? t.cyan.withValues(alpha: 0.10)
            : t.fg.withValues(alpha: 0.05),
        border: Border.all(
          color: active ? t.cyan.withValues(alpha: 0.40) : t.edgeSoft,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 12.5, height: 1.4, color: t.fg3),
          ),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxValueWidth),
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12.5,
                height: 1.4,
                fontWeight: FontWeight.w600,
                color: active ? t.cyan : t.fg,
              ),
            ),
          ),
          Icon(Icons.expand_more_rounded, size: 15, color: t.fg3),
        ],
      ),
    );

    if (onTap == null) return chip;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: chip,
      ),
    );
  }
}
