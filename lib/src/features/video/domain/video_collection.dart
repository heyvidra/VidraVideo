import 'package:flutter/foundation.dart' show listEquals;

/// Immutable domain models. All post-construction mutation goes through
/// [copyWith] so instances shared across Riverpod state can never change
/// underneath a listener, and value equality lets widgets skip rebuilds.
class Video {
  final int id;
  final String? sourceId; // Which data source this video came from
  final int apiId; // The ID provided by the data source
  final String title;
  final String coverUrl;
  final String? thumbUrl;
  final String? backdropUrl;
  final double rating;
  final String? year;
  final String? region;
  final String type;

  // API provided fields
  final int? typeId;
  final int? typeId1;
  final String? actor;
  final String? blurb;
  final String? remarks;
  final String? version;
  final bool? vip;
  final int? vodTime;
  final int? hits;

  final List<String>? genres;

  final String? description;
  final String? content;
  final String? director;
  final String? writer;
  final String? lang;

  final List<VideoEpisode>? urls; // Episodes

  const Video({
    this.id = 0,
    this.sourceId,
    required this.apiId,
    required this.title,
    required this.coverUrl,
    this.thumbUrl,
    this.backdropUrl,
    this.rating = 0.0,
    this.year,
    this.region,
    this.type = '',
    this.typeId,
    this.typeId1,
    this.actor,
    this.blurb,
    this.remarks,
    this.version,
    this.vip,
    this.vodTime,
    this.hits,
    this.genres,
    this.description,
    this.content,
    this.director,
    this.writer,
    this.lang,
    this.urls,
  });

  /// Null arguments keep the current value (no field is reset to null).
  Video copyWith({
    int? id,
    String? sourceId,
    int? apiId,
    String? title,
    String? coverUrl,
    String? thumbUrl,
    String? backdropUrl,
    double? rating,
    String? year,
    String? region,
    String? type,
    int? typeId,
    int? typeId1,
    String? actor,
    String? blurb,
    String? remarks,
    String? version,
    bool? vip,
    int? vodTime,
    int? hits,
    List<String>? genres,
    String? description,
    String? content,
    String? director,
    String? writer,
    String? lang,
    List<VideoEpisode>? urls,
  }) {
    return Video(
      id: id ?? this.id,
      sourceId: sourceId ?? this.sourceId,
      apiId: apiId ?? this.apiId,
      title: title ?? this.title,
      coverUrl: coverUrl ?? this.coverUrl,
      thumbUrl: thumbUrl ?? this.thumbUrl,
      backdropUrl: backdropUrl ?? this.backdropUrl,
      rating: rating ?? this.rating,
      year: year ?? this.year,
      region: region ?? this.region,
      type: type ?? this.type,
      typeId: typeId ?? this.typeId,
      typeId1: typeId1 ?? this.typeId1,
      actor: actor ?? this.actor,
      blurb: blurb ?? this.blurb,
      remarks: remarks ?? this.remarks,
      version: version ?? this.version,
      vip: vip ?? this.vip,
      vodTime: vodTime ?? this.vodTime,
      hits: hits ?? this.hits,
      genres: genres ?? this.genres,
      description: description ?? this.description,
      content: content ?? this.content,
      director: director ?? this.director,
      writer: writer ?? this.writer,
      lang: lang ?? this.lang,
      urls: urls ?? this.urls,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Video &&
        other.id == id &&
        other.sourceId == sourceId &&
        other.apiId == apiId &&
        other.title == title &&
        other.coverUrl == coverUrl &&
        other.thumbUrl == thumbUrl &&
        other.backdropUrl == backdropUrl &&
        other.rating == rating &&
        other.year == year &&
        other.region == region &&
        other.type == type &&
        other.typeId == typeId &&
        other.typeId1 == typeId1 &&
        other.actor == actor &&
        other.blurb == blurb &&
        other.remarks == remarks &&
        other.version == version &&
        other.vip == vip &&
        other.vodTime == vodTime &&
        other.hits == hits &&
        listEquals(other.genres, genres) &&
        other.description == description &&
        other.content == content &&
        other.director == director &&
        other.writer == writer &&
        other.lang == lang &&
        listEquals(other.urls, urls);
  }

  @override
  int get hashCode => Object.hash(sourceId, apiId, title, coverUrl, urls?.length);
}

class VideoQuality {
  final String? name;
  final String? url;

  const VideoQuality({this.name, this.url});

  VideoQuality copyWith({String? name, String? url}) =>
      VideoQuality(name: name ?? this.name, url: url ?? this.url);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VideoQuality && other.name == name && other.url == url;

  @override
  int get hashCode => Object.hash(name, url);
}

class VideoEpisode {
  final int? index;
  final String? title;
  final List<VideoQuality>? qualities;
  final bool? vip;
  final bool? isNew;

  const VideoEpisode({
    this.index,
    this.title,
    this.qualities,
    this.vip,
    this.isNew,
  });

  // Compatibility getter
  String? get url => qualities?.firstOrNull?.url;

  VideoEpisode copyWith({
    int? index,
    String? title,
    List<VideoQuality>? qualities,
    bool? vip,
    bool? isNew,
  }) {
    return VideoEpisode(
      index: index ?? this.index,
      title: title ?? this.title,
      qualities: qualities ?? this.qualities,
      vip: vip ?? this.vip,
      isNew: isNew ?? this.isNew,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is VideoEpisode &&
        other.index == index &&
        other.title == title &&
        other.vip == vip &&
        other.isNew == isNew &&
        listEquals(other.qualities, qualities);
  }

  @override
  int get hashCode => Object.hash(index, title, vip, isNew, qualities?.length);
}
