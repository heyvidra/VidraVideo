import 'package:flutter/material.dart';

import '../../config/design_tokens.dart';
import 'skeleton_box.dart';

/// The catalog card, before it has anything to say.
///
/// Shaped like the real [PopularVideoCard] down to its corner radius, border
/// and footer padding — it stands in a grid cell of exactly that size, so any
/// difference shows up as the whole wall of cards twitching when the data
/// lands. It used to be a square-cornered column with no card surface at all,
/// which is a different object rather than the same one arriving.
class VideoCardSkeleton extends StatelessWidget {
  const VideoCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final t = VidraTokens.of(context);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: t.glass2,
        ),
        border: Border.all(color: t.edgeSoft),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Expanded(child: SkeletonBox(radius: 0)),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SkeletonBox(
                  height: 13,
                  width: double.infinity,
                  radius: 4,
                ),
                const SizedBox(height: 5),
                SizedBox(
                  width: 78,
                  child: const SkeletonBox(height: 10, radius: 4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
