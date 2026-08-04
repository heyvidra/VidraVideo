import 'dart:convert';

import 'package:vidra/src/features/video/domain/video_collection.dart';

/// Every bit of dbku.tv HTML knowledge lives in this file.
///
/// The site is MacCMS10 on the "mytheme" template and its JSON collection API
/// is switched off (`/api.php/provide/vod` answers 404, `/index.php/api/vod`
/// answers `{"code":0}`), so listings, details and stream URLs all come from
/// scraping. Keeping the selectors here means a theme change — or a Cloudflare
/// challenge that forces a different fetch strategy — only touches one file.
class DbkuParser {
  DbkuParser._();

  // --- list / search -------------------------------------------------------

  /// Thumb anchor, shared verbatim by the grid pages (`/vodtype`, `/vodshow`)
  /// and the search page (`/vodsearch`) — same attributes in the same order.
  /// The trailing group runs to the item's own `</li>` so the sibling
  /// `myui-vodlist__detail` block (which carries the cast line on grid
  /// pages) is in reach; non-greedy keeps it from crossing into the next
  /// item.
  static final _item = RegExp(
    r'<a class="myui-vodlist__thumb[^"]*"\s+href="/voddetail/(\d+)\.html"\s+'
    r'title="([^"]*)"\s+data-original="([^"]*)"(.*?)</a>(.*?)</li>',
    dotAll: true,
  );
  static final _score = RegExp(r'>([\d.]+)分<');
  static final _remarks = RegExp(r'<span class="pic-text[^"]*">([^<]*)</span>');

  /// Cast line under a grid thumb: already comma-separated plain text.
  static final _listActor = RegExp(r'<p class="text[^"]*">([^<]*)</p>');

  static List<Video> parseVideoList(String html) {
    return _item.allMatches(html).map((m) {
      final body = m.group(4) ?? '';
      final detail = m.group(5) ?? '';
      final rawActor = _listActor.firstMatch(detail)?.group(1);
      final actor = rawActor == null ? null : _unescape(rawActor).trim();
      return Video(
        apiId: int.parse(m.group(1)!),
        sourceId: 'dbku',
        title: _unescape(m.group(2)!),
        coverUrl: m.group(3)!,
        rating: double.tryParse(_score.firstMatch(body)?.group(1) ?? '') ?? 0.0,
        remarks: _remarks.firstMatch(body)?.group(1),
        actor: (actor == null || actor.isEmpty) ? null : actor,
      );
    }).toList();
  }

  // --- search --------------------------------------------------------------

  // The search page renders a media list, not a thumb grid: every item
  // carries 导演/主演/分类/地区/年份 and a 简介 teaser as plain text after
  // labelled spans. The grid parser above still MATCHES these items (the
  // thumb anchor is identical), it just cannot see the extra fields — so
  // this parser reuses it for the shared part and layers the rest on top.
  static final _mDirector = RegExp(r'导演：</span>([^<]*)');
  static final _mActor = RegExp(r'主演：</span>([^<]*)');
  static final _mTypeName = RegExp(r'分类：</span>([^<]*)');
  static final _mRegion = RegExp(r'地区：</span>([^<]*)');
  static final _mYear = RegExp(r'年份：</span>\s*(\d{4})');
  static final _mBlurb = RegExp(r'简介：</span>([^<]*)');

  static List<Video> parseSearchList(String html) {
    return _item.allMatches(html).map((m) {
      final body = m.group(4) ?? '';
      final detail = m.group(5) ?? '';
      String? field(RegExp re) {
        final raw = re.firstMatch(detail)?.group(1);
        if (raw == null) return null;
        final text = _unescape(raw).trim();
        // The site prints a literal 未知 placeholder; keep our "missing"
        // convention (null) so the UI's own fallback stays in charge.
        return (text.isEmpty || text == '未知') ? null : text;
      }

      return Video(
        apiId: int.parse(m.group(1)!),
        sourceId: 'dbku',
        title: _unescape(m.group(2)!),
        coverUrl: m.group(3)!,
        rating: double.tryParse(_score.firstMatch(body)?.group(1) ?? '') ?? 0.0,
        remarks: _remarks.firstMatch(body)?.group(1),
        director: field(_mDirector),
        actor: field(_mActor),
        type: field(_mTypeName) ?? '',
        region: field(_mRegion),
        year: field(_mYear),
        blurb: field(_mBlurb),
      );
    }).toList();
  }

  // --- detail --------------------------------------------------------------

  static final _title = RegExp(r'<h1 class="title">([^<]*)</h1>');
  static final _cover = RegExp(
    r'<div class="myui-content__thumb">.*?data-original="([^"]*)"',
    dotAll: true,
  );
  static final _rating = RegExp(r'<span class="branch">([\d.]+)</span>');
  static final _type = RegExp(r'分类：</span><a href="/vodshow/(\d+)[^"]*">([^<]*)</a>');
  static final _region = RegExp(r'地区：</span><a[^>]*>([^<]*)</a>');
  static final _year = RegExp(r'年份：</span><a[^>]*>(\d{4})</a>');
  static final _updated = RegExp(r'更新：</span><span class="text-red">([^<]*)</span>');
  static final _actor = RegExp(r'主演：</span>(.*?)</p>', dotAll: true);
  static final _director = RegExp(r'导演：</span>(.*?)</p>', dotAll: true);
  static final _anchorText = RegExp(r'>([^<]+)</a>');
  static final _blurb = RegExp(r'<span class="sketch content">([^<]*)</span>');
  static final _content = RegExp(
    r'<span class="data" style="display: none;">(.*?)</span>',
    dotAll: true,
  );
  static final _tags = RegExp(r'<[^>]+>');
  static final _episode = RegExp(
    r'<a class="btn btn-default" href="/vodplay/(\d+)-(\d+)-(\d+)\.html">([^<]*)</a>',
  );

  /// Returns the show with each episode's [VideoQuality.url] holding the
  /// *play page path* (`/vodplay/{id}-{sid}-{nid}.html`), not a stream URL —
  /// dbku hides the stream behind one more request per episode. The data
  /// source resolves those before handing the video to the player.
  static Video? parseVideoDetail(String html, int id) {
    final title = _title.firstMatch(html)?.group(1);
    if (title == null) return null;

    final type = _type.firstMatch(html);
    final content = _content.firstMatch(html)?.group(1);

    return Video(
      apiId: id,
      sourceId: 'dbku',
      title: _unescape(title),
      coverUrl: _cover.firstMatch(html)?.group(1) ?? '',
      rating: double.tryParse(_rating.firstMatch(html)?.group(1) ?? '') ?? 0.0,
      year: _year.firstMatch(html)?.group(1),
      region: _region.firstMatch(html)?.group(1),
      type: type?.group(2) ?? '',
      typeId: int.tryParse(type?.group(1) ?? ''),
      actor: _joinNames(_actor.firstMatch(html)?.group(1)),
      director: _joinNames(_director.firstMatch(html)?.group(1)),
      blurb: _blurb.firstMatch(html)?.group(1),
      content: content == null
          ? null
          : _unescape(content.replaceAll(_tags, '')).trim(),
      vodTime: _parseUpdated(_updated.firstMatch(html)?.group(1)),
      urls: _parseEpisodes(html),
    );
  }

  /// Only the first play source (`sid`) is kept. dbku has shipped a single
  /// source (`from=vidjs25`) on every title sampled; if a second one ever
  /// appears the UI would need a source picker to make use of it.
  static List<VideoEpisode> _parseEpisodes(String html) {
    final matches = _episode.allMatches(html).toList();
    if (matches.isEmpty) return const [];
    final sid = matches.first.group(2);

    final episodes = <VideoEpisode>[];
    for (final m in matches.where((m) => m.group(2) == sid)) {
      episodes.add(
        VideoEpisode(
          index: episodes.length,
          title: _unescape(m.group(4)!),
          qualities: [
            VideoQuality(
              name: '标清',
              url: '/vodplay/${m.group(1)}-$sid-${m.group(3)}.html',
            ),
          ],
        ),
      );
    }
    return episodes;
  }

  // --- play page -----------------------------------------------------------

  static final _playerCfg = RegExp(
    r'player_\w+\s*=\s*(\{.*?\})\s*</script>',
    dotAll: true,
  );

  /// Pulls the stream URL out of the `player_aaaa = {...}` blob a
  /// `/vodplay/` page embeds. Returns null when the page carries no config or
  /// the payload does not decode — callers treat that as "episode has no
  /// stream" rather than an error, since a single dud episode should not fail
  /// the whole show.
  static String? parsePlayUrl(String html) {
    final match = _playerCfg.firstMatch(html);
    if (match == null) return null;

    try {
      final cfg = jsonDecode(match.group(1)!) as Map<String, dynamic>;
      final raw = cfg['url'] as String?;
      if (raw == null || raw.isEmpty) return null;

      // MacCMS `encrypt`: 0 = plain, 1 = urlencoded, 2 = base64(urlencoded).
      switch (cfg['encrypt']) {
        case 2:
          return Uri.decodeComponent(
            utf8.decode(base64.decode(base64.normalize(raw))),
          );
        case 1:
          return Uri.decodeComponent(raw);
        default:
          return raw;
      }
    } on FormatException {
      return null;
    }
  }

  // --- helpers -------------------------------------------------------------

  /// Comma-joins the anchor texts in a `主演：`/`导演：` paragraph, matching the
  /// comma-separated shape [Video.actor] already carries from olevod.
  static String? _joinNames(String? block) {
    if (block == null) return null;
    final names = _anchorText
        .allMatches(block)
        .map((m) => _unescape(m.group(1)!).trim())
        .where((n) => n.isNotEmpty);
    return names.isEmpty ? null : names.join(',');
  }

  /// `2026-07-20 12:30:00` (site-local, treated as UTC) to epoch seconds —
  /// the unit [Video.vodTime] uses.
  static int? _parseUpdated(String? text) {
    if (text == null) return null;
    final parsed = DateTime.tryParse('${text.trim().replaceAll(' ', 'T')}Z');
    return parsed == null ? null : parsed.millisecondsSinceEpoch ~/ 1000;
  }

  static String _unescape(String s) => s
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .replaceAll('&nbsp;', ' ');
}
