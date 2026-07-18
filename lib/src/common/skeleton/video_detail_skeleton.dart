import 'package:flutter/material.dart';
import 'package:shimmer_animation/shimmer_animation.dart';

class VideoDetailSkeleton extends StatelessWidget {
  const VideoDetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    // Helper to reduce boilerplate for simple boxes
    Widget skeletonBox({
      required double height,
      required double width,
      double radius = 4,
    }) {
      return Shimmer(
        duration: const Duration(seconds: 2),
        color: Theme.of(context).colorScheme.inverseSurface,
        colorOpacity: 0.1,
        enabled: true,
        direction: const ShimmerDirection.fromLTRB(),
        child: Container(
          height: height,
          width: width,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.onSurface.withAlpha(10),
            borderRadius: BorderRadius.circular(radius),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero Header Skeleton
          SizedBox(
            height: 500,
            width: double.infinity,
            child: Shimmer(
              duration: const Duration(seconds: 2),
              color: Theme.of(context).colorScheme.inverseSurface,
              colorOpacity: 0.05,
              enabled: true,
              direction: const ShimmerDirection.fromLTRB(),
              child: Container(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                // Title Area
                skeletonBox(height: 48, width: 300, radius: 8),
                const SizedBox(height: 16),

                // Metadata Row (Rating, Year, Type)
                Row(
                  children: [
                    skeletonBox(height: 20, width: 20, radius: 2), // Star icon
                    const SizedBox(width: 8),
                    skeletonBox(
                      height: 24,
                      width: 80,
                      radius: 4,
                    ), // Rating badge
                    const SizedBox(width: 16),
                    skeletonBox(height: 24, width: 60, radius: 4), // Year
                    const SizedBox(width: 16),
                    skeletonBox(height: 24, width: 50, radius: 4), // Type
                  ],
                ),
                const SizedBox(height: 24),

                // Action Buttons
                Row(
                  children: [
                    skeletonBox(
                      height: 48,
                      width: 140,
                      radius: 8,
                    ), // Play Button
                    const SizedBox(width: 16),
                    skeletonBox(
                      height: 48,
                      width: 140,
                      radius: 8,
                    ), // Download Button
                  ],
                ),
                const SizedBox(height: 48),

                // Episodes Section
                skeletonBox(
                  height: 32,
                  width: 120,
                  radius: 4,
                ), // "Episodes" header
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: List.generate(
                    8,
                    (index) => skeletonBox(height: 50, width: 100, radius: 8),
                  ),
                ),
                const SizedBox(height: 48),

                // Content Row (Storyline + Details)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Storyline
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          skeletonBox(height: 32, width: 100, radius: 4),
                          const SizedBox(height: 16),
                          skeletonBox(
                            height: 14,
                            width: double.infinity,
                            radius: 2,
                          ),
                          const SizedBox(height: 8),
                          skeletonBox(
                            height: 14,
                            width: double.infinity,
                            radius: 2,
                          ),
                          const SizedBox(height: 8),
                          skeletonBox(height: 14, width: 200, radius: 2),
                        ],
                      ),
                    ),
                    const SizedBox(width: 32),
                    // Details
                    Expanded(
                      flex: 1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          skeletonBox(height: 32, width: 100, radius: 4),
                          const SizedBox(height: 16),
                          ...List.generate(
                            5,
                            (index) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  skeletonBox(height: 12, width: 60, radius: 2),
                                  const SizedBox(height: 4),
                                  skeletonBox(
                                    height: 14,
                                    width: 100,
                                    radius: 2,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }
}
