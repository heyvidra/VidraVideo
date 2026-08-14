import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import 'design_tokens.dart';

/// The lit room every translucent surface in the app is standing in.
///
/// Glass is only glass when there is something behind it. On a flat page a
/// translucent panel resolves to a slightly lighter flat rectangle — the blur
/// has nothing to blur and the material reads as a plastic overlay. A 168°
/// ramp with four soft, widely separated colour washes over it gives the
/// surfaces something to pick up, and gives the window a direction of light so
/// the specular edge along a panel's top border has a reason to be there.
///
/// Deliberately static. An animated gradient behind a scrolling catalog is a
/// full-screen repaint competing with image decoding for the same frame
/// budget, and the effect is one nobody looks at twice.
///
/// Both the ramp and the washes are [VidraTokens] — the same numbers as the
/// design's `body { background: … }`.
class AmbientBackground extends StatelessWidget {
  const AmbientBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = VidraTokens.of(context);

    return DecoratedBox(
      // 168° in CSS is measured from "up", clockwise: very nearly top-to-bottom
      // with a slight lean to the left.
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: const Alignment(0.35, -1),
          end: const Alignment(-0.35, 1),
          colors: [t.pageA, t.pageB],
        ),
      ),
      child: Stack(
        children: [
          // One layer per wash: a BoxDecoration carries a single gradient, and
          // stacking them is also what lets each keep its own centre and reach.
          for (final w in t.blobs)
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: w.center,
                      radius: w.radius,
                      colors: [w.color, w.color.withAlpha(0)],
                    ),
                  ),
                ),
              ),
            ),
          child,
        ],
      ),
    );
  }
}

/// A translucent panel: the app's one surface material.
///
/// Blur plus a raised saturation — the saturation is what separates glass from
/// a grey box, because it is what lets the colour behind the panel come through
/// rather than being averaged into mud. The hairline along the top edge is the
/// specular highlight; without it a rounded translucent rectangle reads as a
/// hole rather than a pane.
///
/// [level] picks which of the design's three fills to use: 1 for the window
/// itself, 2 for the panels inside it, 3 for a selected or raised element.
class GlassPanel extends StatelessWidget {
  const GlassPanel({
    super.key,
    required this.child,
    this.radius = 18,
    this.blur = 13,
    this.level = 2,
    this.saturation = 1.6,
    this.padding = EdgeInsets.zero,
    this.tint,
    this.shadow,
    this.border,
    this.flat = false,
  });

  final Widget child;
  final double radius;

  /// Blur SIGMA, which is half the CSS `blur()` radius the design specifies.
  final double blur;

  /// 1 = window, 2 = panel, 3 = raised/selected. See [VidraTokens.glass1].
  final int level;

  final double saturation;
  final EdgeInsetsGeometry padding;

  /// Overrides the level's gradient with one flat colour — for the surfaces
  /// the design gives their own fill, like the pinned episode bar.
  final Color? tint;

  final List<BoxShadow>? shadow;
  final Color? border;

  /// 减少特效: same fill, border and specular, no backdrop filter. For panels
  /// whose tint is already 72–80% opaque the blur contributes only the last
  /// fifth of the pixels, and on a low-power GPU that fifth costs a full
  /// readback + Gaussian of everything beneath, every repainted frame.
  final bool flat;

  /// The standard saturation matrix, rather than a hand-tuned diagonal: the
  /// design asks for `saturate(160%)` and this is what that means.
  static ColorFilter _saturate(double s) {
    const lr = 0.213, lg = 0.715, lb = 0.072;
    return ColorFilter.matrix(<double>[
      lr + (1 - lr) * s, lg - lg * s, lb - lb * s, 0, 0, //
      lr - lr * s, lg + (1 - lg) * s, lb - lb * s, 0, 0, //
      lr - lr * s, lg - lg * s, lb + (1 - lb) * s, 0, 0, //
      0, 0, 0, 1, 0,
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final t = VidraTokens.of(context);
    final stops = switch (level) {
      1 => t.glass1,
      3 => t.glass3,
      _ => t.glass2,
    };
    final rr = BorderRadius.circular(radius);

    final pane = ClipRRect(
      borderRadius: rr,
      child: _maybeBackdrop(
        child: Stack(
          children: [
            Container(
              padding: padding,
              decoration: BoxDecoration(
                color: tint,
                gradient: tint != null
                    ? null
                    : LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: stops,
                      ),
                borderRadius: rr,
                border: Border.all(color: border ?? t.edge, width: 1),
              ),
              child: child,
            ),
            // The specular highlight, inset one pixel like the CSS
            // `inset 0 1px 0`. Inside the clip, so the rounded corners cut it.
            Positioned(
              top: 0,
              left: 1,
              right: 1,
              height: 1,
              child: IgnorePointer(child: ColoredBox(color: t.specSoft)),
            ),
          ],
        ),
      ),
    );

    if (shadow == null) return pane;
    return DecoratedBox(
      decoration: BoxDecoration(borderRadius: rr, boxShadow: shadow),
      child: pane,
    );
  }

  Widget _maybeBackdrop({required Widget child}) {
    if (flat) return child;
    return BackdropFilter(
      // Saturation before blur: blurring alone averages the wash behind the
      // panel toward grey, and grey is exactly what a pane of glass is not.
      filter: ImageFilter.compose(
        outer: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        inner: _saturate(saturation),
      ),
      child: child,
    );
  }
}
