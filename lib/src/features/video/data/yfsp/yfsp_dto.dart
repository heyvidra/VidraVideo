import 'package:vidra/src/features/video/domain/video_collection.dart';

/// Scheme for an episode whose stream URL has not been minted yet.
///
/// yfsp signs a stream URL per playback (`vendtime`/`vhash`, ~48h) and
/// rate-limits the endpoint that mints them hard enough that resolving a
/// 60-episode show up front trips its bot challenge. So an episode is stored
/// as its key under this scheme and exchanged for a real URL at the moment
/// playback starts — see [YfspDataSource.resolveEpisodeUrl], which the player
/// reaches through the `SourceResolver` hook.
const String kYfspEpisodeScheme = 'yfsp://';

/// A stable local handle for a yfsp show key.
///
/// The catalog keys shows by an 11-character base62 token; the domain [Video]
/// and the `videos` table key on an int, and 62^11 needs 66 bits, so the token
/// cannot be encoded into one. This folds it into an int instead, which is why
/// the token itself has to be carried alongside in [Video.sourceKey] — this is
/// one-way and nothing can invert it.
///
/// ponytail: a multiply-and-add fold, not a cryptographic hash. Two keys
/// colliding would show one show under another's cached row; at 62 bits and a
/// catalog of ~10^5 the odds are ~10^-9. Swap in a wider identity only if the
/// `videos` table ever grows a real composite key.
int yfspHandle(String key) {
  var h = 0;
  for (final unit in key.codeUnits) {
    h = h * 131 + unit;
  }
  return h & 0x3FFFFFFFFFFFFFFF;
}

/// One row of `list/Search` (also `list/index`, `list/GetLastAdd` — same shape).
class YfspListItemDto {
  const YfspListItemDto(this.json);

  final Map<String, dynamic> json;

  String get key => json['key'] as String? ?? '';

  /// The class path ("0,1,4,131"), which the episode playlist call needs
  /// verbatim. Deliberately NOT stored on the domain [Video]: the detail
  /// response carries its own copy, so the source keeps this in a session map
  /// and nothing has to find a column to hide it in.
  String? get videoClassID => json['videoClassID'] as String?;

  Video toDomain() {
    final cover = json['image'] as String? ?? '';
    return Video(
      apiId: yfspHandle(key),
      sourceKey: key,
      sourceId: 'yfsp',
      title: json['title'] as String? ?? '',
      coverUrl: _sizedCover(cover),
      thumbUrl: cover.isEmpty ? null : cover,
      rating: _round1(_toDouble(json['rating'])),
      year: json['year']?.toString(),
      region: json['regional'] as String?,
      lang: json['lang'] as String?,
      type: json['atypeName'] as String? ?? '',
      // The badge the grid prints over the poster. "60集全" passes through;
      // a bare "06" becomes 第6集 — see [yfspAiringLabel].
      remarks: yfspAiringLabel(json['lastName']),
      version: json['vipResource'] as String?,
      actor: _nonEmpty(json['starring']),
      director: _nonEmpty(json['directed']),
      // The detail screen reads `content ?? blurb` for 剧情简介, so whatever
      // lands in `content` IS the synopsis the user reads. It briefly held the
      // class path here — a field used as a courier — and the page duly
      // printed "0,1,4,131" where the story should be. The class path needs no
      // home on the row at all: the detail response carries it live.
      blurb: _nonEmpty(json['contxt']),
      content: _nonEmpty(json['contxt']),
      genres: _splitTags(json['cidMapper']),
    );
  }
}

/// `video/detail` — everything the detail screen shows except the episodes,
/// which come from `video/languagesplaylist` and arrive here as [episodes].
class YfspDetailDto {
  const YfspDetailDto(this.json);

  final Map<String, dynamic> json;

  String get key => json['key'] as String? ?? '';

  /// The class path the episode playlist call needs.
  String? get cid => json['cid'] as String?;

  Video toDomain(List<VideoEpisode> episodes) {
    final cover = json['imgPath'] as String? ?? '';
    final stars = _joinNames(json['stars']);
    final directors = _joinNames(json['directors']);
    return Video(
      apiId: yfspHandle(key),
      sourceKey: key,
      sourceId: 'yfsp',
      title: json['title'] as String? ?? '',
      coverUrl: _sizedCover(cover),
      thumbUrl: cover.isEmpty ? null : cover,
      // `score` is a label ("暂无评分") until a show has enough votes; the
      // 0..1 `pinfenRate` behind it is what the site's own star bar draws.
      rating: _round1(
        double.tryParse(json['score']?.toString() ?? '') ??
            _toDouble(json['pinfenRate']) * 10,
      ),
      year: json['post_Year']?.toString(),
      region: json['regional'] as String?,
      lang: json['language'] as String?,
      type: json['channel'] as String? ?? '',
      remarks: yfspAiringLabel(json['lastName']),
      actor: stars,
      director: directors,
      description: _nonEmpty(json['contxt']),
      blurb: _nonEmpty(json['contxt']),
      // See the note in [YfspListItemDto.toDomain]: `content` is what the
      // detail screen prints as 剧情简介, not a spare field.
      content: _nonEmpty(json['contxt']),
      genres: _splitTags(json['videoType'] ?? json['cidMapper']),
      urls: episodes,
    );
  }
}

/// One entry of `video/languagesplaylist`'s `playList`.
VideoEpisode yfspEpisode(Map<String, dynamic> json, int index) {
  final key = json['key'] as String? ?? '';
  return VideoEpisode(
    index: index,
    title: json['name']?.toString() ?? '${index + 1}',
    vip: json['isVip'] as bool?,
    isNew: json['isNew'] as bool?,
    // One quality, because the real ladder is only known once `video/play`
    // answers and the master playlist it returns is adaptive anyway.
    qualities: [VideoQuality(name: '自动', url: '$kYfspEpisodeScheme$key')],
  );
}

/// Rewrites every URI in an HLS playlist through [signUri].
///
/// yfsp's CDN refuses an unsigned request by RESETTING the connection — not
/// 403, not 404, and it does it for any path it does not recognise, so the
/// symptom reads like a network fault rather than a missing signature. The
/// playlist the API hands back names its segments unsigned, and the player
/// fetches those itself, straight from the CDN, where every one of them is
/// dropped. Signing them here is what turns the list into something a player
/// can actually walk.
///
/// Line-for-line with the input so that the tags describing a segment keep the
/// segment they describe. Comment lines pass through byte for byte except the
/// four whose URI hides in a quoted attribute — the playlists seen so far
/// carry none of them, and a `#EXT-X-KEY` left unsigned would be an episode
/// that never decrypts.
String signHlsPlaylist({
  required String playlist,
  required Uri playlistUrl,
  required String Function(Uri target) signUri,
}) {
  final lines = playlist.split('\n');
  final out = StringBuffer();
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i].trimRight();
    if (line.isEmpty) {
      out.write(line);
    } else if (line.startsWith('#')) {
      out.write(_signTagUri(line, playlistUrl, signUri));
    } else {
      out.write(signUri(playlistUrl.resolve(line.trim())));
    }
    if (i != lines.length - 1) out.write('\n');
  }
  return out.toString();
}

final _uriAttributeTag = RegExp(
  r'^#EXT-X-(?:I-FRAME-STREAM-INF|KEY|SESSION-KEY|MAP):',
);
final _uriAttribute = RegExp(r'URI="([^"]*)"');

String _signTagUri(
  String line,
  Uri playlistUrl,
  String Function(Uri) signUri,
) {
  if (!_uriAttributeTag.hasMatch(line)) return line;
  return line.replaceAllMapped(_uriAttribute, (m) {
    final value = m.group(1)!.trim();
    // An empty URI resolves to the playlist itself; leave nonsense alone.
    if (value.isEmpty) return m.group(0)!;
    return 'URI="${signUri(playlistUrl.resolve(value))}"';
  });
}

/// Picks the show out of a `video/play` response's `flvPathList`.
///
/// The list leads with the PRE-ROLL AD — an mp4 carrying a `link` to the
/// advertiser — and the feature follows as the HLS entry. Taking `first` plays
/// the advert and calls it the episode, so match on `isHls`, and only fall
/// back to an entry that carries no `link`.
String? yfspPickStream(Object? flvPathList) {
  if (flvPathList is! List) return null;
  final entries = flvPathList.whereType<Map<String, dynamic>>().toList();
  for (final e in entries) {
    final url = e['result'] as String?;
    if (e['isHls'] == true && url != null && url.isNotEmpty) return url;
  }
  for (final e in entries) {
    final url = e['result'] as String?;
    if (e['link'] == null && url != null && url.isNotEmpty) return url;
  }
  return null;
}

/// Posters are served as `.gif` often enough that the grid pays for animation
/// it never shows; the CDN's own resize takes a format. Same parameters the
/// site's card component uses.
String _sizedCover(String url) =>
    url.isEmpty ? url : '$url?w=216&h=309&format=jpg&mode=stretch';

String? _nonEmpty(Object? v) {
  final s = v?.toString().trim();
  return (s == null || s.isEmpty) ? null : s;
}

String? _joinNames(Object? v) {
  if (v is! List || v.isEmpty) return null;
  return v.map((e) => e.toString()).where((e) => e.isNotEmpty).join(' / ');
}

List<String>? _splitTags(Object? v) {
  final s = _nonEmpty(v);
  if (s == null) return null;
  final parts = s.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty);
  return parts.isEmpty ? null : parts.toList();
}

double _toDouble(Object? v) {
  if (v is num) return v.toDouble();
  return double.tryParse(v?.toString() ?? '') ?? 0.0;
}

/// One decimal, as a number rather than as a string.
///
/// The rating is DERIVED here (`pinfenRate * 10`) rather than parsed from a
/// string the way the other sources get theirs, and 0.47 * 10 is
/// 4.699999999999999 in binary floating point — which duly reached the detail
/// page. Rounded at the source so the noise never enters the database either;
/// one decimal because that is the scale the catalogs actually rate on.
double _round1(double v) => (v * 10).roundToDouble() / 10;

/// yfsp's `lastName` in the shape the rest of the app writes airing state.
///
/// The field holds either a bare episode number ("05") or a finished-run label
/// ("60集全"). A bare number reached the detail page as a pill reading "05",
/// which says nothing on its own and misses the regex that paints airing shows
/// amber. Anything already carrying words is the catalog's own phrasing and is
/// left exactly as found.
String? yfspAiringLabel(Object? lastName) {
  final raw = _nonEmpty(lastName);
  if (raw == null) return null;
  final n = int.tryParse(raw);
  return n == null ? raw : '第$n集';
}
