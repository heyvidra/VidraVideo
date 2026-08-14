import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer_animation/shimmer_animation.dart';

import '../../config/design_tokens.dart';
import '../../config/reduce_effects.dart';

/// One placeholder block — a static fill, deliberately without its own sweep.
///
/// Every skeleton in the app was building its own fill: `withAlpha(10)` over
/// `colorScheme.inverseSurface`, which on the glass palette is a block you
/// cannot see. The fill is a token now.
///
/// The sweep lives in [SkeletonShimmer], once per screen, because
/// shimmer_animation runs a setState per animation tick per instance with
/// `shouldRepaint => true` — and a first-load screen holds 36–50 of these
/// blocks, so per-box shimmers put dozens of tickers on the same cores that
/// are parsing JSON and decoding covers at exactly that moment.
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
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: t.fg.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: child,
    );
  }
}

/// The single sweep for a whole skeleton screen.
///
/// Every [SkeletonBox] used to carry this exact shimmer itself, and since
/// they all mounted in the same frame their sweeps were already synchronized
/// — so one ancestor painting one band over all of them is the same picture
/// at one animation ticker instead of dozens. The parameters are the ones
/// the per-box shimmer shipped with: a white sweep that reads over both the
/// light theme's grey blocks and the dark theme's near-black ones.
class SkeletonShimmer extends ConsumerWidget {
  const SkeletonShimmer({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 减少特效: the blocks alone already say "loading"; the sweep is the one
    // animation a low-power machine would otherwise run during its most
    // contended phase.
    if (ref.watch(reduceEffectsProvider)) return child;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer(
      duration: const Duration(milliseconds: 1600),
      interval: const Duration(milliseconds: 300),
      color: Colors.white,
      colorOpacity: dark ? 0.05 : 0.55,
      enabled: true,
      direction: const ShimmerDirection.fromLTRB(),
      child: child,
    );
  }
}
