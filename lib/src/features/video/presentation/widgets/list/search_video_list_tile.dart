import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vidra/src/config/design_tokens.dart';
import 'package:vidra/src/features/video/domain/search_hit.dart';
import 'package:vidra/src/features/video/domain/video_collection.dart';
import 'package:vidra/src/features/video/presentation/widgets/cards/popular_video_card.dart';
import 'package:vidra/src/features/video/presentation/widgets/cross_source_watch_badge.dart';

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

/// One SHOW in the search results, on the app's glass panel. The card is one
/// hit across every catalog: the poster and facts come from [SearchHit.primary]
/// and a chip row names each source that has it, with the catalog's own
/// progress line. Tapping the card opens the primary source; tapping a chip
/// opens that source.
class SearchVideoListTile extends ConsumerStatefulWidget {
  final SearchHit hit;
  final String keyword;

  const SearchVideoListTile({
    super.key,
    required this.hit,
    required this.keyword,
  });

  @override
  ConsumerState<SearchVideoListTile> createState() =>
      _SearchVideoListTileState();
}

class _SearchVideoListTileState extends ConsumerState<SearchVideoListTile> {
  bool isHovered = false;

  // Same poster size as the detail header — the page this card opens.
  static const _posterW = 100.0;
  static const _posterH = 142.0;

  Video get video => widget.hit.primary;

  void _openDetail(Video v) {
    final sid = v.sourceId;
    final path = sid != null
        ? '/detail/${v.apiId}?sourceId=$sid'
        : '/detail/${v.apiId}';
    context.push(path);
  }

  @override
  Widget build(BuildContext context) {
    final t = VidraTokens.of(context);
    final meta = [video.year, video.region, video.lang]
        .where((s) => s != null && s.isNotEmpty)
        .join(' / ');

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: GestureDetector(
        onTap: () => _openDetail(video),
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
                  video: video,
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
                                video.title,
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
                            video.type,
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
                    if (video.actor != null && video.actor!.isNotEmpty)
                      _buildInfoRow(tr('video.detail.cast'), video.actor!),
                    if (video.director != null && video.director!.isNotEmpty)
                      _buildInfoRow(
                        tr('video.detail.director'),
                        video.director!,
                      ),
                    if (video.blurb != null && video.blurb!.isNotEmpty)
                      _buildInfoRow(
                        tr('video.detail.storyline'),
                        video.blurb!,
                        maxLines: 2,
                      ),
                    const SizedBox(height: 10),
                    // Which source has it, and how far along — the question a
                    // multi-source search exists to answer. One chip per
                    // catalog, each opening that catalog's page.
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final v in [video, ...widget.hit.others])
                          _sourceChip(v),
                      ],
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

  Widget _sourceChip(Video v) {
    final sid = v.sourceId;
    if (sid == null) return const SizedBox.shrink();
    final t = VidraTokens.of(context);
    final remarks = (v.remarks ?? '').trim();
    final name = sourceDisplayName(ref, sid);
    return GestureDetector(
      onTap: () => _openDetail(v),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: t.edgeSoft),
          color: t.fg.withValues(alpha: 0.05),
        ),
        child: Text(
          remarks.isEmpty ? name : '$name · $remarks',
          style: TextStyle(fontSize: 11.5, height: 1.4, color: t.fg2),
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
