import 'package:flutter/material.dart';

import '../../config/design_tokens.dart';
import 'skeleton_box.dart';

/// The detail page, before its fetch returns.
///
/// Every measurement here is the real page's: a 176px backdrop card inset 8,
/// the poster 100×142 hanging 116px into it, the pinned episode bar 92 tall,
/// tiles in the same stretch grid. It described a 500px hero with 100×50
/// episode chips and 48px square buttons — a page that has not existed since
/// the redesign, so the load read as one screen replaced by another.
///
/// Only seen on a deep link or a cold restore; a card that was tapped hands
/// over its cover and gets [VideoDetailScreen]'s own seeded loader instead.
class VideoDetailSkeleton extends StatelessWidget {
  const VideoDetailSkeleton({super.key});

  /// The grid's `minmax(104px, 1fr)` with an 11px gap, resolved the same way
  /// the real grid resolves it.
  static const _min = 104.0, _gap = 11.0;

  @override
  Widget build(BuildContext context) {
    final t = VidraTokens.of(context);

    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero card + the head row that overlaps it.
          SizedBox(
            height: 4 + 60 + 149,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                const Positioned(
                  left: 8,
                  right: 8,
                  top: 4,
                  height: 176,
                  child: SkeletonBox(radius: 18),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 64),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(width: 20),
                      const SkeletonBox(width: 100, height: 142, radius: 14),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 42),
                            const SkeletonBox(
                              width: 220,
                              height: 30,
                              radius: 6,
                            ),
                            const SizedBox(height: 9),
                            Row(
                              children: const [
                                SkeletonBox(width: 58, height: 22, radius: 999),
                                SizedBox(width: 6),
                                SkeletonBox(width: 48, height: 22, radius: 999),
                                SizedBox(width: 6),
                                SkeletonBox(width: 48, height: 22, radius: 999),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: const [
                                SkeletonBox(
                                  width: 132,
                                  height: 34,
                                  radius: 999,
                                ),
                                SizedBox(width: 8),
                                SkeletonBox(width: 92, height: 34, radius: 999),
                                SizedBox(width: 8),
                                SkeletonBox(width: 92, height: 34, radius: 999),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // The episode bar, at the height its two rows give it.
          const Padding(
            padding: EdgeInsets.fromLTRB(8, 16, 8, 12),
            child: SkeletonBox(height: 92, radius: 16),
          ),

          // The grid, in the real grid's columns.
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 24),
            child: LayoutBuilder(
              builder: (context, c) {
                final columns = ((c.maxWidth + _gap) / (_min + _gap))
                    .floor()
                    .clamp(1, 99);
                final width = (c.maxWidth - (columns - 1) * _gap) / columns;
                return Wrap(
                  spacing: _gap,
                  runSpacing: _gap,
                  children: List.generate(
                    columns * 2,
                    (_) => SkeletonBox(width: width, height: 86, radius: 14),
                  ),
                );
              },
            ),
          ),

          // Storyline and the fact ledger, at 14 : 10.
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 32),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 14,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      SkeletonBox(width: 72, height: 10, radius: 3),
                      SizedBox(height: 12),
                      SkeletonBox(height: 12, radius: 3),
                      SizedBox(height: 8),
                      SkeletonBox(height: 12, radius: 3),
                      SizedBox(height: 8),
                      SkeletonBox(width: 220, height: 12, radius: 3),
                    ],
                  ),
                ),
                const SizedBox(width: 28),
                Expanded(
                  flex: 10,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SkeletonBox(width: 72, height: 10, radius: 3),
                      const SizedBox(height: 12),
                      for (var i = 0; i < 3; i++)
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 7),
                          decoration: BoxDecoration(
                            border: Border(
                              top: i == 0
                                  ? BorderSide(color: t.edgeSoft)
                                  : BorderSide.none,
                              bottom: BorderSide(color: t.edgeSoft),
                            ),
                          ),
                          child: Row(
                            children: const [
                              SkeletonBox(width: 44, height: 11, radius: 3),
                              Spacer(),
                              SkeletonBox(width: 96, height: 11, radius: 3),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
