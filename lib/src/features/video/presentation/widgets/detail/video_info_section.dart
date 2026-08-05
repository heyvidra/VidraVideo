import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:vidra/src/config/design_tokens.dart';
import 'package:vidra/src/features/video/domain/video_collection.dart';

/// `.info` — the storyline, and the facts as a key/value ledger.
///
/// Two columns at 1.4 : 1, because prose wants a measure and a table does not.
/// Both headings are eyebrows rather than titles: nothing down here competes
/// with the episode grid, it is what you read after you have decided.
class VideoInfoSection extends StatelessWidget {
  final Video video;

  const VideoInfoSection({super.key, required this.video});

  @override
  Widget build(BuildContext context) {
    final t = VidraTokens.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 14,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr('video.section.storyline').toUpperCase(),
                  style: VidraType.eyebrow(t.fg3),
                ),
                const SizedBox(height: 9),
                Text(
                  video.content ??
                      video.blurb ??
                      tr('video.section.no_description'),
                  style: TextStyle(fontSize: 13, height: 1.7, color: t.fg2),
                ),
              ],
            ),
          ),
          const SizedBox(width: 28),
          Expanded(
            flex: 10,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr('video.section.details').toUpperCase(),
                  style: VidraType.eyebrow(t.fg3),
                ),
                const SizedBox(height: 9),
                _Ledger(
                  rows: [
                    (
                      tr('video.detail.director'),
                      video.director ?? tr('video.detail.unknown'),
                    ),
                    (
                      tr('video.detail.cast'),
                      video.actor ?? tr('video.detail.unknown'),
                    ),
                    (
                      tr('video.detail.updated'),
                      video.vodTime != null && video.vodTime! > 0
                          ? DateFormat('yyyy-MM-dd HH:mm').format(
                              DateTime.fromMillisecondsSinceEpoch(
                                video.vodTime! > 9999999999
                                    ? video.vodTime!
                                    : video.vodTime! * 1000,
                              ),
                            )
                          : tr('video.detail.unknown'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// `.kv` — label left, value right, a hairline between every pair.
class _Ledger extends StatelessWidget {
  const _Ledger({required this.rows});

  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context) {
    final t = VidraTokens.of(context);
    return Column(
      children: [
        for (var i = 0; i < rows.length; i++)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              border: Border(
                top: i == 0
                    ? BorderSide(color: t.edgeSoft)
                    : BorderSide.none,
                bottom: BorderSide(color: t.edgeSoft),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rows[i].$1,
                  style: TextStyle(fontSize: 12, height: 1.5, color: t.fg3),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    rows[i].$2,
                    textAlign: TextAlign.end,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.45,
                      color: t.fg,
                      fontFeatures: VidraType.data,
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
