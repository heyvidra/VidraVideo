import 'package:flutter/material.dart';
import 'package:shimmer_animation/shimmer_animation.dart';

class VideoCardSkeleton extends StatelessWidget {
  const VideoCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Cover Image Skeleton - Flexible to avoid overflow
        Expanded(
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            child: Shimmer(
              duration: const Duration(seconds: 2),
              color: Theme.of(context).colorScheme.inverseSurface,
              colorOpacity: 0.1,
              enabled: true,
              direction: const ShimmerDirection.fromLTRB(),
              child: Container(
                color: Theme.of(context).colorScheme.onSurface.withAlpha(10),
              ),
            ),
          ),
        ),

        // Details Skeleton
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Shimmer(
                duration: const Duration(seconds: 2),
                color: Theme.of(context).colorScheme.inverseSurface,
                colorOpacity: 0.1,
                enabled: true,
                direction: const ShimmerDirection.fromLTRB(),
                child: Container(
                  height: 14,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withAlpha(10),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              // Subtitle
              Shimmer(
                duration: const Duration(seconds: 2),
                color: Theme.of(context).colorScheme.inverseSurface,
                colorOpacity: 0.1,
                enabled: true,
                direction: const ShimmerDirection.fromLTRB(),
                child: Container(
                  height: 12,
                  width: 80,
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withAlpha(10),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
