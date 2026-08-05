import 'package:flutter/material.dart';
import 'package:shimmer_animation/shimmer_animation.dart';

import '../../config/design_tokens.dart';

/// One shimmering placeholder block.
///
/// Every skeleton in the app was building its own: `withAlpha(10)` over
/// `colorScheme.inverseSurface`, which on the glass palette is a block you
/// cannot see being swept by a highlight you cannot see either. The fill is a
/// token now, and the sweep is white on both themes — on the light one it
/// passes over a grey block, on the dark one over a near-black one, and it
/// reads either way.
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    super.key,
    this.width,
    this.height,
    this.radius = 8,
    this.child,
  });

  final double? width;
  final double? height;
  final double radius;

  /// For blocks that must size themselves — a poster filling an [Expanded].
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final t = VidraTokens.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer(
      duration: const Duration(milliseconds: 1600),
      interval: const Duration(milliseconds: 300),
      color: Colors.white,
      colorOpacity: dark ? 0.05 : 0.55,
      enabled: true,
      direction: const ShimmerDirection.fromLTRB(),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: t.fg.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(radius),
        ),
        child: child,
      ),
    );
  }
}
