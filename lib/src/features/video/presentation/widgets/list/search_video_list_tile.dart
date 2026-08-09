import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:vidra/src/config/design_tokens.dart';
import 'package:vidra/src/features/video/domain/video_collection.dart';
import 'package:vidra/src/features/video/presentation/widgets/cards/popular_video_card.dart';

/// Splits [text] into spans, colouring case-insensitive matches of [keyword]
/// with [color]. Non-matching spans carry no style and inherit the parent's.
List<TextSpan> highlightKeyword(String text, String keyword, Color color) {
  final kw = keyword.trim();
  if (kw.isEmpty) return [TextSpan(text: text)];
  final spans = <TextSpan>[];
  final lower = text.toLowerCase();
  final lowerKw = kw.toLowerCase();
  var start = 0;
  var i = lower.indexOf(lowerKw);
  while (i >= 0) {
    if (i > start) spans.add(TextSpan(text: text.substring(start, i)));
    spans.add(
      TextSpan(
        text: text.substring(i, i + kw.length),
        style: TextStyle(color: color),
      ),
    );
    start = i + kw.length;
    i = lower.indexOf(lowerKw, start);
  }
  if (start < text.length) spans.add(TextSpan(text: text.substring(start)));
  return spans;
}

/// One search hit, on the same glass panel every other surface in the app
/// sits on. The whole card opens the detail page, like every poster card
/// elsewhere — no dedicated button.
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

  // Same poster size as the detail header — the page this card opens.
  static const _posterW = 100.0;
  static const _posterH = 142.0;

  void _openDetail() {
    final sid = widget.video.sourceId;
    final path = sid != null
        ? '/detail/${widget.video.apiId}?sourceId=$sid'
        : '/detail/${widget.video.apiId}';
    context.push(path);
  }

  @override
  Widget build(BuildContext context) {
    final t = VidraTokens.of(context);
    final meta = [widget.video.year, widget.video.region, widget.video.lang]
        .where((s) => s != null && s.isNotEmpty)
        .join(' / ');

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: GestureDetector(
        onTap: _openDetail,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isHovered ? t.glass3 : t.glass2,
            ),
            border: Border.all(color: t.edgeSoft),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: _posterW,
                height: _posterH,
                child: PopularVideoCard(
                  video: widget.video,
                  showDetails: false,
                  enableHover: false,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text.rich(
                            TextSpan(
                              style: TextStyle(
                                color: t.fg,
                                fontSize: 16,
                                height: 1.3,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.3,
                              ),
                              children: highlightKeyword(
                                widget.video.title,
                                widget.keyword,
                                t.cyan,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Type badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: t.edgeSoft),
                            color: t.fg.withValues(alpha: 0.05),
                          ),
                          child: Text(
                            widget.video.type,
                            style: TextStyle(
                              color: t.fg2,
                              fontSize: 11,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (meta.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        meta,
                        style: TextStyle(
                          color: t.fg3,
                          fontSize: 12.5,
                          height: 1.4,
                          fontFeatures: VidraType.data,
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    if (widget.video.actor != null &&
                        widget.video.actor!.isNotEmpty)
                      _buildInfoRow(
                        tr('video.detail.cast'),
                        widget.video.actor!,
                      ),
                    if (widget.video.director != null &&
                        widget.video.director!.isNotEmpty)
                      _buildInfoRow(
                        tr('video.detail.director'),
                        widget.video.director!,
                      ),
                    if (widget.video.blurb != null &&
                        widget.video.blurb!.isNotEmpty)
                      _buildInfoRow(
                        tr('video.detail.storyline'),
                        widget.video.blurb!,
                        maxLines: 2,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String content, {int maxLines = 1}) {
    final t = VidraTokens.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: TextStyle(color: t.fg3, fontSize: 13, height: 1.5),
          ),
          Expanded(
            child: Text(
              content,
              style: TextStyle(color: t.fg2, fontSize: 13, height: 1.5),
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
