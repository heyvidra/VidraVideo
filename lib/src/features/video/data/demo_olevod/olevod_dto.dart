import 'package:vidra/src/features/video/domain/video_collection.dart';

class OlevodVideoDto {
  final int id;
  final String name;
  final String pic;
  final String? picThumb;
  final double score;
  final String? year;
  final String? area;
  final int? typeId;
  final int? typeId1;
  final String? typeIdName;
  final String? typeId1Name;
  final String? actor;
  final String? blurb;
  final String? remarks;
  final String? version;
  final bool? vip;
  final int? vodTime;
  final int? hits;
  final int? hitsDay;
  final int? hitsMonth;
  final int? hitsWeek;
  final String? content;
  final String? director;
  final String? writer;
  final String? lang;
  final String? author;
  final String? behind;
  final String? duration;
  final String? en;
  final String? letter;
  final String? pubDate;
  final String? state;
  final String? sub;
  final String? tag;
  final List<OlevodEpisodeDto>? urls;
  final double? douBanScore;
  final int? up;
  final int? down;
  final int? commentTotal;
  final bool? status;

  OlevodVideoDto({
    required this.id,
    required this.name,
    required this.pic,
    this.picThumb,
    required this.score,
    this.year,
    this.area,
    this.typeId,
    this.typeId1,
    this.typeIdName,
    this.typeId1Name,
    this.actor,
    this.blurb,
    this.remarks,
    this.version,
    this.vip,
    this.vodTime,
    this.hits,
    this.hitsDay,
    this.hitsMonth,
    this.hitsWeek,
    this.content,
    this.director,
    this.writer,
    this.lang,
    this.author,
    this.behind,
    this.duration,
    this.en,
    this.letter,
    this.pubDate,
    this.state,
    this.sub,
    this.tag,
    this.urls,
    this.douBanScore,
    this.up,
    this.down,
    this.commentTotal,
    this.status,
  });

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  factory OlevodVideoDto.fromJson(Map<String, dynamic> json) {
    // Prefer non-zero IDs from common keys
    int id = _parseInt(json['id']);
    if (id == 0) id = _parseInt(json['vod_id']);
    if (id == 0) id = _parseInt(json['vodId']);

    return OlevodVideoDto(
      id: id,
      name: json['name'] ?? json['vod_name'] ?? '',
      pic: json['pic'] ?? json['vod_pic'] ?? '',
      picThumb: json['picThumb'] ?? json['vod_pic_thumb'],
      score: _parseDouble(
        json['score'] ?? json['vod_score'] ?? json['vod_douban_score'],
      ),
      year: (json['year'] ?? json['vod_year'])?.toString(),
      area: json['area'] ?? json['vod_area'],
      typeId: _parseInt(json['typeId'] ?? json['type_id']),
      typeId1: _parseInt(json['typeId1'] ?? json['type_id_1']),
      typeIdName: json['typeIdName'] ?? json['type_name'],
      typeId1Name: json['typeId1Name'] ?? json['type_name_1'],
      actor: json['actor'] ?? json['vod_actor'],
      blurb: json['blurb'] ?? json['vod_blurb'],
      remarks: json['remarks'] ?? json['vod_remarks'],
      version: json['version'] ?? json['vod_version'],
      vip: json['vip'] ?? json['vod_vip'],
      vodTime: _parseInt(json['vodTime'] ?? json['vod_time']),
      hits: _parseInt(json['hits'] ?? json['vod_hits']),
      hitsDay: _parseInt(json['hitsDay'] ?? json['vod_hits_day']),
      hitsMonth: _parseInt(json['hitsMonth'] ?? json['vod_hits_month']),
      hitsWeek: _parseInt(json['hitsWeek'] ?? json['vod_hits_week']),
      content: json['content'] ?? json['vod_content'],
      director: json['director'] ?? json['vod_director'],
      writer: json['writer'] ?? json['vod_writer'],
      lang: json['lang'] ?? json['vod_lang'],
      author: json['author'] ?? json['vod_author'],
      behind: json['behind'] ?? json['vod_behind'],
      duration: json['duration'] ?? json['vod_duration'],
      en: json['en'] ?? json['vod_en'],
      letter: json['letter'] ?? json['vod_letter'],
      pubDate: json['pubDate'] ?? json['vod_pubdate'],
      state: json['state'] ?? json['vod_state'],
      sub: json['sub'] ?? json['vod_sub'],
      tag: json['tag'] ?? json['vod_tag'],
      urls: _parseUrls(json),
      douBanScore: _parseDouble(
        json['douBanScore'] ?? json['vod_douban_score'],
      ),
      up: _parseInt(json['up'] ?? json['vod_up']),
      down: _parseInt(json['down'] ?? json['vod_down']),
      commentTotal: _parseInt(
        json['commentTotal'] ?? json['vod_comment_total'],
      ),
      status:
          json['status'] ??
          (json['vod_status'] != null ? json['vod_status'] == 1 : null),
    );
  }

  static List<OlevodEpisodeDto>? _parseUrls(Map<String, dynamic> json) {
    if (json['urls'] != null && json['urls'] is List) {
      return (json['urls'] as List)
          .map((e) => OlevodEpisodeDto.fromJson(e))
          .toList();
    }

    // Fallback for CMS-style vod_play_url: "Title1$Url1#Title2$Url2"
    final playUrl = json['vod_play_url'] ?? json['vodPlayUrl'];
    if (playUrl is String && playUrl.isNotEmpty) {
      final episodes = <OlevodEpisodeDto>[];
      final lines = playUrl.split('#');
      for (int i = 0; i < lines.length; i++) {
        final line = lines[i];
        if (line.isEmpty) continue;
        final parts = line.split('\$');
        if (parts.length >= 2) {
          episodes.add(
            OlevodEpisodeDto(index: i, title: parts[0], url: parts[1]),
          );
        } else if (line.isNotEmpty) {
          episodes.add(
            OlevodEpisodeDto(index: i, title: '第${i + 1}集', url: line),
          );
        }
      }
      return episodes.isNotEmpty ? episodes : null;
    }
    return null;
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  /// [resolve] maps relative CDN paths to absolute URLs at construction time —
  /// the domain Video is immutable, so no post-hoc URL rewriting.
  Video toDomain(String Function(String url) resolve) {
    return Video(
      apiId: id,
      sourceId: 'olevod',
      title: name,
      coverUrl: resolve(pic),
      thumbUrl: picThumb != null ? resolve(picThumb!) : null,
      rating: score,
      year: year,
      region: area,
      typeId: typeId,
      typeId1: typeId1,
      actor: actor,
      blurb: blurb,
      remarks: remarks,
      version: version,
      vip: vip,
      vodTime: vodTime,
      hits: hits,
      content: content,
      director: director,
      writer: writer,
      lang: lang,
      urls: urls
          ?.where((e) => e.vip != true || (e.url != null && e.url!.isNotEmpty))
          .map((e) => e.toDomain(resolve))
          .toList(),
      type: _mapType(),
    );
  }

  String _mapType() {
    if (typeId1 == 14 || typeId == 1200) return '短剧';
    if (typeId1 == 3) return '综艺';
    if (typeId1 == 4) return '动漫';
    return (typeId1 == 2) ? '电视剧' : '电影';
  }
}

class OlevodEpisodeDto {
  final int? index;
  final String? title;
  final String? url;
  final bool? vip;
  final bool? isNew;
  final int? seekStart;
  final int? seekEnd;
  final List<OlevodEpisodeVipUrlDto>? vipUrls;

  OlevodEpisodeDto({
    this.index,
    this.title,
    this.url,
    this.vip,
    this.isNew,
    this.seekStart,
    this.seekEnd,
    this.vipUrls,
  });

  factory OlevodEpisodeDto.fromJson(Map<String, dynamic> json) {
    return OlevodEpisodeDto(
      index: json['index'],
      title: json['title'],
      url: json['url'],
      vip: json['vip'],
      isNew: json['new'],
      seekStart: json['seek_start'],
      seekEnd: json['seek_end'],
      vipUrls: json['vip_urls'] != null
          ? (json['vip_urls'] as List)
                .map((e) => OlevodEpisodeVipUrlDto.fromJson(e))
                .toList()
          : null,
    );
  }

  VideoEpisode toDomain(String Function(String url) resolve) {
    final List<VideoQuality> qualities = [];

    if (url != null && url!.isNotEmpty) {
      qualities.add(VideoQuality(name: '标清', url: resolve(url!)));
    }

    if (vipUrls != null) {
      final urlLen = vipUrls!.length;
      for (int i = 0; i < urlLen; i++) {
        final v = vipUrls![i];
        if (v.url != null && v.url!.isNotEmpty) {
          qualities.add(
            VideoQuality(
              name: '高清${urlLen > 1 ? i + 1 : ''}',
              url: resolve(v.url!),
            ),
          );
        }
      }
    }

    return VideoEpisode(
      index: index,
      title: title?.replaceAll('第第', '第').replaceAll('集集', '集'),
      qualities: qualities,
      vip: vip,
      isNew: isNew,
    );
  }
}

class OlevodEpisodeVipUrlDto {
  final String? title;
  final String? url;
  final bool? vip;

  OlevodEpisodeVipUrlDto({this.title, this.url, this.vip});

  factory OlevodEpisodeVipUrlDto.fromJson(Map<String, dynamic> json) {
    return OlevodEpisodeVipUrlDto(
      title: json['title'],
      url: json['url'],
      vip: json['vip'],
    );
  }
}
