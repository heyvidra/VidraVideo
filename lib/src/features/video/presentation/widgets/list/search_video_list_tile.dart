import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:vidra/src/features/video/domain/video_collection.dart';
import 'package:vidra/src/features/video/presentation/widgets/cards/popular_video_card.dart';

class SearchVideoListTile extends StatefulWidget {
  final Video video;
  final String keyword;

  const SearchVideoListTile({
    super.key,
    required this.video,
    required this.keyword,
  });

  @override
  State<SearchVideoListTile> createState() => _SearchVideoListTileState();
}

class _SearchVideoListTileState extends State<SearchVideoListTile> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isHovered
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Poster Image
            SizedBox(
              width: 180, // Adjust width as needed
              height: 240, // Adjust height as needed
              child: PopularVideoCard(
                video: widget.video,
                showDetails: false,
                enableHover: false,
              ),
            ),
            const SizedBox(width: 24),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title with keyword highlighting (simulated)
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: widget.video.title,
                          style: const TextStyle(
                            color: Color(0xFF00E5FF), // Cyan title
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Metadata Row
                  Text(
                    '${widget.video.year ?? 'Unk'} / ${widget.video.region ?? 'Unk'} / ${widget.video.lang ?? 'Unk'}',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 16),

                  // Actors
                  if (widget.video.actor != null &&
                      widget.video.actor!.isNotEmpty)
                    _buildInfoRow(tr('video.detail.cast'), widget.video.actor!),

                  const SizedBox(height: 8),

                  // Director
                  if (widget.video.director != null &&
                      widget.video.director!.isNotEmpty)
                    _buildInfoRow(
                      tr('video.detail.director'),
                      widget.video.director!,
                    ),

                  const SizedBox(height: 8),

                  // Description
                  if (widget.video.blurb != null &&
                      widget.video.blurb!.isNotEmpty)
                    _buildInfoRow(
                      tr('video.detail.storyline'),
                      widget.video.blurb!,
                      maxLines: 2,
                    ),

                  const SizedBox(height: 24),

                  // Action Button
                  ElevatedButton(
                    onPressed: () {
                      final sid = widget.video.sourceId;
                      final path = sid != null
                          ? '/detail/${widget.video.apiId}?sourceId=$sid'
                          : '/detail/${widget.video.apiId}';
                      context.push(path);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2196F3),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text(tr('common.view_details')),
                  ),
                ],
              ),
            ),
            // Type Badge (top right)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white24),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                widget.video.type,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String content, {int maxLines = 1}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: ',
          style: const TextStyle(color: Colors.grey, fontSize: 14),
        ),
        Expanded(
          child: Text(
            content,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
