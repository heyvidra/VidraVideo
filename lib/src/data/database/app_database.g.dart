// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $VideosTable extends Videos with TableInfo<$VideosTable, Video> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VideosTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _sourceIdMeta = const VerificationMeta(
    'sourceId',
  );
  @override
  late final GeneratedColumn<String> sourceId = GeneratedColumn<String>(
    'source_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _apiIdMeta = const VerificationMeta('apiId');
  @override
  late final GeneratedColumn<int> apiId = GeneratedColumn<int>(
    'api_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _coverUrlMeta = const VerificationMeta(
    'coverUrl',
  );
  @override
  late final GeneratedColumn<String> coverUrl = GeneratedColumn<String>(
    'cover_url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _thumbUrlMeta = const VerificationMeta(
    'thumbUrl',
  );
  @override
  late final GeneratedColumn<String> thumbUrl = GeneratedColumn<String>(
    'thumb_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _backdropUrlMeta = const VerificationMeta(
    'backdropUrl',
  );
  @override
  late final GeneratedColumn<String> backdropUrl = GeneratedColumn<String>(
    'backdrop_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ratingMeta = const VerificationMeta('rating');
  @override
  late final GeneratedColumn<double> rating = GeneratedColumn<double>(
    'rating',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _yearMeta = const VerificationMeta('year');
  @override
  late final GeneratedColumn<String> year = GeneratedColumn<String>(
    'year',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _regionMeta = const VerificationMeta('region');
  @override
  late final GeneratedColumn<String> region = GeneratedColumn<String>(
    'region',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeIdMeta = const VerificationMeta('typeId');
  @override
  late final GeneratedColumn<int> typeId = GeneratedColumn<int>(
    'type_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _typeId1Meta = const VerificationMeta(
    'typeId1',
  );
  @override
  late final GeneratedColumn<int> typeId1 = GeneratedColumn<int>(
    'type_id1',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _actorMeta = const VerificationMeta('actor');
  @override
  late final GeneratedColumn<String> actor = GeneratedColumn<String>(
    'actor',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _blurbMeta = const VerificationMeta('blurb');
  @override
  late final GeneratedColumn<String> blurb = GeneratedColumn<String>(
    'blurb',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _remarksMeta = const VerificationMeta(
    'remarks',
  );
  @override
  late final GeneratedColumn<String> remarks = GeneratedColumn<String>(
    'remarks',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<String> version = GeneratedColumn<String>(
    'version',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _vipMeta = const VerificationMeta('vip');
  @override
  late final GeneratedColumn<bool> vip = GeneratedColumn<bool>(
    'vip',
    aliasedName,
    true,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("vip" IN (0, 1))',
    ),
  );
  static const VerificationMeta _vodTimeMeta = const VerificationMeta(
    'vodTime',
  );
  @override
  late final GeneratedColumn<int> vodTime = GeneratedColumn<int>(
    'vod_time',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _hitsMeta = const VerificationMeta('hits');
  @override
  late final GeneratedColumn<int> hits = GeneratedColumn<int>(
    'hits',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<List<String>?, String> genres =
      GeneratedColumn<String>(
        'genres',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<List<String>?>($VideosTable.$convertergenresn);
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _directorMeta = const VerificationMeta(
    'director',
  );
  @override
  late final GeneratedColumn<String> director = GeneratedColumn<String>(
    'director',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _writerMeta = const VerificationMeta('writer');
  @override
  late final GeneratedColumn<String> writer = GeneratedColumn<String>(
    'writer',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _langMeta = const VerificationMeta('lang');
  @override
  late final GeneratedColumn<String> lang = GeneratedColumn<String>(
    'lang',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<List<VideoEpisode>?, String>
  urls = GeneratedColumn<String>(
    'urls',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  ).withConverter<List<VideoEpisode>?>($VideosTable.$converterurlsn);
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sourceId,
    apiId,
    title,
    coverUrl,
    thumbUrl,
    backdropUrl,
    rating,
    year,
    region,
    type,
    typeId,
    typeId1,
    actor,
    blurb,
    remarks,
    version,
    vip,
    vodTime,
    hits,
    genres,
    description,
    content,
    director,
    writer,
    lang,
    urls,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'videos';
  @override
  VerificationContext validateIntegrity(
    Insertable<Video> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('source_id')) {
      context.handle(
        _sourceIdMeta,
        sourceId.isAcceptableOrUnknown(data['source_id']!, _sourceIdMeta),
      );
    }
    if (data.containsKey('api_id')) {
      context.handle(
        _apiIdMeta,
        apiId.isAcceptableOrUnknown(data['api_id']!, _apiIdMeta),
      );
    } else if (isInserting) {
      context.missing(_apiIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('cover_url')) {
      context.handle(
        _coverUrlMeta,
        coverUrl.isAcceptableOrUnknown(data['cover_url']!, _coverUrlMeta),
      );
    } else if (isInserting) {
      context.missing(_coverUrlMeta);
    }
    if (data.containsKey('thumb_url')) {
      context.handle(
        _thumbUrlMeta,
        thumbUrl.isAcceptableOrUnknown(data['thumb_url']!, _thumbUrlMeta),
      );
    }
    if (data.containsKey('backdrop_url')) {
      context.handle(
        _backdropUrlMeta,
        backdropUrl.isAcceptableOrUnknown(
          data['backdrop_url']!,
          _backdropUrlMeta,
        ),
      );
    }
    if (data.containsKey('rating')) {
      context.handle(
        _ratingMeta,
        rating.isAcceptableOrUnknown(data['rating']!, _ratingMeta),
      );
    } else if (isInserting) {
      context.missing(_ratingMeta);
    }
    if (data.containsKey('year')) {
      context.handle(
        _yearMeta,
        year.isAcceptableOrUnknown(data['year']!, _yearMeta),
      );
    }
    if (data.containsKey('region')) {
      context.handle(
        _regionMeta,
        region.isAcceptableOrUnknown(data['region']!, _regionMeta),
      );
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('type_id')) {
      context.handle(
        _typeIdMeta,
        typeId.isAcceptableOrUnknown(data['type_id']!, _typeIdMeta),
      );
    }
    if (data.containsKey('type_id1')) {
      context.handle(
        _typeId1Meta,
        typeId1.isAcceptableOrUnknown(data['type_id1']!, _typeId1Meta),
      );
    }
    if (data.containsKey('actor')) {
      context.handle(
        _actorMeta,
        actor.isAcceptableOrUnknown(data['actor']!, _actorMeta),
      );
    }
    if (data.containsKey('blurb')) {
      context.handle(
        _blurbMeta,
        blurb.isAcceptableOrUnknown(data['blurb']!, _blurbMeta),
      );
    }
    if (data.containsKey('remarks')) {
      context.handle(
        _remarksMeta,
        remarks.isAcceptableOrUnknown(data['remarks']!, _remarksMeta),
      );
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    }
    if (data.containsKey('vip')) {
      context.handle(
        _vipMeta,
        vip.isAcceptableOrUnknown(data['vip']!, _vipMeta),
      );
    }
    if (data.containsKey('vod_time')) {
      context.handle(
        _vodTimeMeta,
        vodTime.isAcceptableOrUnknown(data['vod_time']!, _vodTimeMeta),
      );
    }
    if (data.containsKey('hits')) {
      context.handle(
        _hitsMeta,
        hits.isAcceptableOrUnknown(data['hits']!, _hitsMeta),
      );
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    }
    if (data.containsKey('director')) {
      context.handle(
        _directorMeta,
        director.isAcceptableOrUnknown(data['director']!, _directorMeta),
      );
    }
    if (data.containsKey('writer')) {
      context.handle(
        _writerMeta,
        writer.isAcceptableOrUnknown(data['writer']!, _writerMeta),
      );
    }
    if (data.containsKey('lang')) {
      context.handle(
        _langMeta,
        lang.isAcceptableOrUnknown(data['lang']!, _langMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Video map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Video(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      sourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_id'],
      ),
      apiId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}api_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      coverUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cover_url'],
      )!,
      thumbUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}thumb_url'],
      ),
      backdropUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}backdrop_url'],
      ),
      rating: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}rating'],
      )!,
      year: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}year'],
      ),
      region: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}region'],
      ),
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      typeId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}type_id'],
      ),
      typeId1: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}type_id1'],
      ),
      actor: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}actor'],
      ),
      blurb: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}blurb'],
      ),
      remarks: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remarks'],
      ),
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}version'],
      ),
      vip: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}vip'],
      ),
      vodTime: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}vod_time'],
      ),
      hits: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}hits'],
      ),
      genres: $VideosTable.$convertergenresn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}genres'],
        ),
      ),
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      ),
      director: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}director'],
      ),
      writer: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}writer'],
      ),
      lang: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}lang'],
      ),
      urls: $VideosTable.$converterurlsn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}urls'],
        ),
      ),
    );
  }

  @override
  $VideosTable createAlias(String alias) {
    return $VideosTable(attachedDatabase, alias);
  }

  static TypeConverter<List<String>, String> $convertergenres =
      const StringListConverter();
  static TypeConverter<List<String>?, String?> $convertergenresn =
      NullAwareTypeConverter.wrap($convertergenres);
  static TypeConverter<List<VideoEpisode>, String> $converterurls =
      const VideoEpisodeListConverter();
  static TypeConverter<List<VideoEpisode>?, String?> $converterurlsn =
      NullAwareTypeConverter.wrap($converterurls);
}

class Video extends DataClass implements Insertable<Video> {
  final int id;
  final String? sourceId;
  final int apiId;
  final String title;
  final String coverUrl;
  final String? thumbUrl;
  final String? backdropUrl;
  final double rating;
  final String? year;
  final String? region;
  final String type;
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
  final List<VideoEpisode>? urls;
  const Video({
    required this.id,
    this.sourceId,
    required this.apiId,
    required this.title,
    required this.coverUrl,
    this.thumbUrl,
    this.backdropUrl,
    required this.rating,
    this.year,
    this.region,
    required this.type,
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
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || sourceId != null) {
      map['source_id'] = Variable<String>(sourceId);
    }
    map['api_id'] = Variable<int>(apiId);
    map['title'] = Variable<String>(title);
    map['cover_url'] = Variable<String>(coverUrl);
    if (!nullToAbsent || thumbUrl != null) {
      map['thumb_url'] = Variable<String>(thumbUrl);
    }
    if (!nullToAbsent || backdropUrl != null) {
      map['backdrop_url'] = Variable<String>(backdropUrl);
    }
    map['rating'] = Variable<double>(rating);
    if (!nullToAbsent || year != null) {
      map['year'] = Variable<String>(year);
    }
    if (!nullToAbsent || region != null) {
      map['region'] = Variable<String>(region);
    }
    map['type'] = Variable<String>(type);
    if (!nullToAbsent || typeId != null) {
      map['type_id'] = Variable<int>(typeId);
    }
    if (!nullToAbsent || typeId1 != null) {
      map['type_id1'] = Variable<int>(typeId1);
    }
    if (!nullToAbsent || actor != null) {
      map['actor'] = Variable<String>(actor);
    }
    if (!nullToAbsent || blurb != null) {
      map['blurb'] = Variable<String>(blurb);
    }
    if (!nullToAbsent || remarks != null) {
      map['remarks'] = Variable<String>(remarks);
    }
    if (!nullToAbsent || version != null) {
      map['version'] = Variable<String>(version);
    }
    if (!nullToAbsent || vip != null) {
      map['vip'] = Variable<bool>(vip);
    }
    if (!nullToAbsent || vodTime != null) {
      map['vod_time'] = Variable<int>(vodTime);
    }
    if (!nullToAbsent || hits != null) {
      map['hits'] = Variable<int>(hits);
    }
    if (!nullToAbsent || genres != null) {
      map['genres'] = Variable<String>(
        $VideosTable.$convertergenresn.toSql(genres),
      );
    }
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || content != null) {
      map['content'] = Variable<String>(content);
    }
    if (!nullToAbsent || director != null) {
      map['director'] = Variable<String>(director);
    }
    if (!nullToAbsent || writer != null) {
      map['writer'] = Variable<String>(writer);
    }
    if (!nullToAbsent || lang != null) {
      map['lang'] = Variable<String>(lang);
    }
    if (!nullToAbsent || urls != null) {
      map['urls'] = Variable<String>($VideosTable.$converterurlsn.toSql(urls));
    }
    return map;
  }

  VideosCompanion toCompanion(bool nullToAbsent) {
    return VideosCompanion(
      id: Value(id),
      sourceId: sourceId == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceId),
      apiId: Value(apiId),
      title: Value(title),
      coverUrl: Value(coverUrl),
      thumbUrl: thumbUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(thumbUrl),
      backdropUrl: backdropUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(backdropUrl),
      rating: Value(rating),
      year: year == null && nullToAbsent ? const Value.absent() : Value(year),
      region: region == null && nullToAbsent
          ? const Value.absent()
          : Value(region),
      type: Value(type),
      typeId: typeId == null && nullToAbsent
          ? const Value.absent()
          : Value(typeId),
      typeId1: typeId1 == null && nullToAbsent
          ? const Value.absent()
          : Value(typeId1),
      actor: actor == null && nullToAbsent
          ? const Value.absent()
          : Value(actor),
      blurb: blurb == null && nullToAbsent
          ? const Value.absent()
          : Value(blurb),
      remarks: remarks == null && nullToAbsent
          ? const Value.absent()
          : Value(remarks),
      version: version == null && nullToAbsent
          ? const Value.absent()
          : Value(version),
      vip: vip == null && nullToAbsent ? const Value.absent() : Value(vip),
      vodTime: vodTime == null && nullToAbsent
          ? const Value.absent()
          : Value(vodTime),
      hits: hits == null && nullToAbsent ? const Value.absent() : Value(hits),
      genres: genres == null && nullToAbsent
          ? const Value.absent()
          : Value(genres),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      content: content == null && nullToAbsent
          ? const Value.absent()
          : Value(content),
      director: director == null && nullToAbsent
          ? const Value.absent()
          : Value(director),
      writer: writer == null && nullToAbsent
          ? const Value.absent()
          : Value(writer),
      lang: lang == null && nullToAbsent ? const Value.absent() : Value(lang),
      urls: urls == null && nullToAbsent ? const Value.absent() : Value(urls),
    );
  }

  factory Video.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Video(
      id: serializer.fromJson<int>(json['id']),
      sourceId: serializer.fromJson<String?>(json['sourceId']),
      apiId: serializer.fromJson<int>(json['apiId']),
      title: serializer.fromJson<String>(json['title']),
      coverUrl: serializer.fromJson<String>(json['coverUrl']),
      thumbUrl: serializer.fromJson<String?>(json['thumbUrl']),
      backdropUrl: serializer.fromJson<String?>(json['backdropUrl']),
      rating: serializer.fromJson<double>(json['rating']),
      year: serializer.fromJson<String?>(json['year']),
      region: serializer.fromJson<String?>(json['region']),
      type: serializer.fromJson<String>(json['type']),
      typeId: serializer.fromJson<int?>(json['typeId']),
      typeId1: serializer.fromJson<int?>(json['typeId1']),
      actor: serializer.fromJson<String?>(json['actor']),
      blurb: serializer.fromJson<String?>(json['blurb']),
      remarks: serializer.fromJson<String?>(json['remarks']),
      version: serializer.fromJson<String?>(json['version']),
      vip: serializer.fromJson<bool?>(json['vip']),
      vodTime: serializer.fromJson<int?>(json['vodTime']),
      hits: serializer.fromJson<int?>(json['hits']),
      genres: serializer.fromJson<List<String>?>(json['genres']),
      description: serializer.fromJson<String?>(json['description']),
      content: serializer.fromJson<String?>(json['content']),
      director: serializer.fromJson<String?>(json['director']),
      writer: serializer.fromJson<String?>(json['writer']),
      lang: serializer.fromJson<String?>(json['lang']),
      urls: serializer.fromJson<List<VideoEpisode>?>(json['urls']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'sourceId': serializer.toJson<String?>(sourceId),
      'apiId': serializer.toJson<int>(apiId),
      'title': serializer.toJson<String>(title),
      'coverUrl': serializer.toJson<String>(coverUrl),
      'thumbUrl': serializer.toJson<String?>(thumbUrl),
      'backdropUrl': serializer.toJson<String?>(backdropUrl),
      'rating': serializer.toJson<double>(rating),
      'year': serializer.toJson<String?>(year),
      'region': serializer.toJson<String?>(region),
      'type': serializer.toJson<String>(type),
      'typeId': serializer.toJson<int?>(typeId),
      'typeId1': serializer.toJson<int?>(typeId1),
      'actor': serializer.toJson<String?>(actor),
      'blurb': serializer.toJson<String?>(blurb),
      'remarks': serializer.toJson<String?>(remarks),
      'version': serializer.toJson<String?>(version),
      'vip': serializer.toJson<bool?>(vip),
      'vodTime': serializer.toJson<int?>(vodTime),
      'hits': serializer.toJson<int?>(hits),
      'genres': serializer.toJson<List<String>?>(genres),
      'description': serializer.toJson<String?>(description),
      'content': serializer.toJson<String?>(content),
      'director': serializer.toJson<String?>(director),
      'writer': serializer.toJson<String?>(writer),
      'lang': serializer.toJson<String?>(lang),
      'urls': serializer.toJson<List<VideoEpisode>?>(urls),
    };
  }

  Video copyWith({
    int? id,
    Value<String?> sourceId = const Value.absent(),
    int? apiId,
    String? title,
    String? coverUrl,
    Value<String?> thumbUrl = const Value.absent(),
    Value<String?> backdropUrl = const Value.absent(),
    double? rating,
    Value<String?> year = const Value.absent(),
    Value<String?> region = const Value.absent(),
    String? type,
    Value<int?> typeId = const Value.absent(),
    Value<int?> typeId1 = const Value.absent(),
    Value<String?> actor = const Value.absent(),
    Value<String?> blurb = const Value.absent(),
    Value<String?> remarks = const Value.absent(),
    Value<String?> version = const Value.absent(),
    Value<bool?> vip = const Value.absent(),
    Value<int?> vodTime = const Value.absent(),
    Value<int?> hits = const Value.absent(),
    Value<List<String>?> genres = const Value.absent(),
    Value<String?> description = const Value.absent(),
    Value<String?> content = const Value.absent(),
    Value<String?> director = const Value.absent(),
    Value<String?> writer = const Value.absent(),
    Value<String?> lang = const Value.absent(),
    Value<List<VideoEpisode>?> urls = const Value.absent(),
  }) => Video(
    id: id ?? this.id,
    sourceId: sourceId.present ? sourceId.value : this.sourceId,
    apiId: apiId ?? this.apiId,
    title: title ?? this.title,
    coverUrl: coverUrl ?? this.coverUrl,
    thumbUrl: thumbUrl.present ? thumbUrl.value : this.thumbUrl,
    backdropUrl: backdropUrl.present ? backdropUrl.value : this.backdropUrl,
    rating: rating ?? this.rating,
    year: year.present ? year.value : this.year,
    region: region.present ? region.value : this.region,
    type: type ?? this.type,
    typeId: typeId.present ? typeId.value : this.typeId,
    typeId1: typeId1.present ? typeId1.value : this.typeId1,
    actor: actor.present ? actor.value : this.actor,
    blurb: blurb.present ? blurb.value : this.blurb,
    remarks: remarks.present ? remarks.value : this.remarks,
    version: version.present ? version.value : this.version,
    vip: vip.present ? vip.value : this.vip,
    vodTime: vodTime.present ? vodTime.value : this.vodTime,
    hits: hits.present ? hits.value : this.hits,
    genres: genres.present ? genres.value : this.genres,
    description: description.present ? description.value : this.description,
    content: content.present ? content.value : this.content,
    director: director.present ? director.value : this.director,
    writer: writer.present ? writer.value : this.writer,
    lang: lang.present ? lang.value : this.lang,
    urls: urls.present ? urls.value : this.urls,
  );
  Video copyWithCompanion(VideosCompanion data) {
    return Video(
      id: data.id.present ? data.id.value : this.id,
      sourceId: data.sourceId.present ? data.sourceId.value : this.sourceId,
      apiId: data.apiId.present ? data.apiId.value : this.apiId,
      title: data.title.present ? data.title.value : this.title,
      coverUrl: data.coverUrl.present ? data.coverUrl.value : this.coverUrl,
      thumbUrl: data.thumbUrl.present ? data.thumbUrl.value : this.thumbUrl,
      backdropUrl: data.backdropUrl.present
          ? data.backdropUrl.value
          : this.backdropUrl,
      rating: data.rating.present ? data.rating.value : this.rating,
      year: data.year.present ? data.year.value : this.year,
      region: data.region.present ? data.region.value : this.region,
      type: data.type.present ? data.type.value : this.type,
      typeId: data.typeId.present ? data.typeId.value : this.typeId,
      typeId1: data.typeId1.present ? data.typeId1.value : this.typeId1,
      actor: data.actor.present ? data.actor.value : this.actor,
      blurb: data.blurb.present ? data.blurb.value : this.blurb,
      remarks: data.remarks.present ? data.remarks.value : this.remarks,
      version: data.version.present ? data.version.value : this.version,
      vip: data.vip.present ? data.vip.value : this.vip,
      vodTime: data.vodTime.present ? data.vodTime.value : this.vodTime,
      hits: data.hits.present ? data.hits.value : this.hits,
      genres: data.genres.present ? data.genres.value : this.genres,
      description: data.description.present
          ? data.description.value
          : this.description,
      content: data.content.present ? data.content.value : this.content,
      director: data.director.present ? data.director.value : this.director,
      writer: data.writer.present ? data.writer.value : this.writer,
      lang: data.lang.present ? data.lang.value : this.lang,
      urls: data.urls.present ? data.urls.value : this.urls,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Video(')
          ..write('id: $id, ')
          ..write('sourceId: $sourceId, ')
          ..write('apiId: $apiId, ')
          ..write('title: $title, ')
          ..write('coverUrl: $coverUrl, ')
          ..write('thumbUrl: $thumbUrl, ')
          ..write('backdropUrl: $backdropUrl, ')
          ..write('rating: $rating, ')
          ..write('year: $year, ')
          ..write('region: $region, ')
          ..write('type: $type, ')
          ..write('typeId: $typeId, ')
          ..write('typeId1: $typeId1, ')
          ..write('actor: $actor, ')
          ..write('blurb: $blurb, ')
          ..write('remarks: $remarks, ')
          ..write('version: $version, ')
          ..write('vip: $vip, ')
          ..write('vodTime: $vodTime, ')
          ..write('hits: $hits, ')
          ..write('genres: $genres, ')
          ..write('description: $description, ')
          ..write('content: $content, ')
          ..write('director: $director, ')
          ..write('writer: $writer, ')
          ..write('lang: $lang, ')
          ..write('urls: $urls')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    sourceId,
    apiId,
    title,
    coverUrl,
    thumbUrl,
    backdropUrl,
    rating,
    year,
    region,
    type,
    typeId,
    typeId1,
    actor,
    blurb,
    remarks,
    version,
    vip,
    vodTime,
    hits,
    genres,
    description,
    content,
    director,
    writer,
    lang,
    urls,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Video &&
          other.id == this.id &&
          other.sourceId == this.sourceId &&
          other.apiId == this.apiId &&
          other.title == this.title &&
          other.coverUrl == this.coverUrl &&
          other.thumbUrl == this.thumbUrl &&
          other.backdropUrl == this.backdropUrl &&
          other.rating == this.rating &&
          other.year == this.year &&
          other.region == this.region &&
          other.type == this.type &&
          other.typeId == this.typeId &&
          other.typeId1 == this.typeId1 &&
          other.actor == this.actor &&
          other.blurb == this.blurb &&
          other.remarks == this.remarks &&
          other.version == this.version &&
          other.vip == this.vip &&
          other.vodTime == this.vodTime &&
          other.hits == this.hits &&
          other.genres == this.genres &&
          other.description == this.description &&
          other.content == this.content &&
          other.director == this.director &&
          other.writer == this.writer &&
          other.lang == this.lang &&
          other.urls == this.urls);
}

class VideosCompanion extends UpdateCompanion<Video> {
  final Value<int> id;
  final Value<String?> sourceId;
  final Value<int> apiId;
  final Value<String> title;
  final Value<String> coverUrl;
  final Value<String?> thumbUrl;
  final Value<String?> backdropUrl;
  final Value<double> rating;
  final Value<String?> year;
  final Value<String?> region;
  final Value<String> type;
  final Value<int?> typeId;
  final Value<int?> typeId1;
  final Value<String?> actor;
  final Value<String?> blurb;
  final Value<String?> remarks;
  final Value<String?> version;
  final Value<bool?> vip;
  final Value<int?> vodTime;
  final Value<int?> hits;
  final Value<List<String>?> genres;
  final Value<String?> description;
  final Value<String?> content;
  final Value<String?> director;
  final Value<String?> writer;
  final Value<String?> lang;
  final Value<List<VideoEpisode>?> urls;
  const VideosCompanion({
    this.id = const Value.absent(),
    this.sourceId = const Value.absent(),
    this.apiId = const Value.absent(),
    this.title = const Value.absent(),
    this.coverUrl = const Value.absent(),
    this.thumbUrl = const Value.absent(),
    this.backdropUrl = const Value.absent(),
    this.rating = const Value.absent(),
    this.year = const Value.absent(),
    this.region = const Value.absent(),
    this.type = const Value.absent(),
    this.typeId = const Value.absent(),
    this.typeId1 = const Value.absent(),
    this.actor = const Value.absent(),
    this.blurb = const Value.absent(),
    this.remarks = const Value.absent(),
    this.version = const Value.absent(),
    this.vip = const Value.absent(),
    this.vodTime = const Value.absent(),
    this.hits = const Value.absent(),
    this.genres = const Value.absent(),
    this.description = const Value.absent(),
    this.content = const Value.absent(),
    this.director = const Value.absent(),
    this.writer = const Value.absent(),
    this.lang = const Value.absent(),
    this.urls = const Value.absent(),
  });
  VideosCompanion.insert({
    this.id = const Value.absent(),
    this.sourceId = const Value.absent(),
    required int apiId,
    required String title,
    required String coverUrl,
    this.thumbUrl = const Value.absent(),
    this.backdropUrl = const Value.absent(),
    required double rating,
    this.year = const Value.absent(),
    this.region = const Value.absent(),
    required String type,
    this.typeId = const Value.absent(),
    this.typeId1 = const Value.absent(),
    this.actor = const Value.absent(),
    this.blurb = const Value.absent(),
    this.remarks = const Value.absent(),
    this.version = const Value.absent(),
    this.vip = const Value.absent(),
    this.vodTime = const Value.absent(),
    this.hits = const Value.absent(),
    this.genres = const Value.absent(),
    this.description = const Value.absent(),
    this.content = const Value.absent(),
    this.director = const Value.absent(),
    this.writer = const Value.absent(),
    this.lang = const Value.absent(),
    this.urls = const Value.absent(),
  }) : apiId = Value(apiId),
       title = Value(title),
       coverUrl = Value(coverUrl),
       rating = Value(rating),
       type = Value(type);
  static Insertable<Video> custom({
    Expression<int>? id,
    Expression<String>? sourceId,
    Expression<int>? apiId,
    Expression<String>? title,
    Expression<String>? coverUrl,
    Expression<String>? thumbUrl,
    Expression<String>? backdropUrl,
    Expression<double>? rating,
    Expression<String>? year,
    Expression<String>? region,
    Expression<String>? type,
    Expression<int>? typeId,
    Expression<int>? typeId1,
    Expression<String>? actor,
    Expression<String>? blurb,
    Expression<String>? remarks,
    Expression<String>? version,
    Expression<bool>? vip,
    Expression<int>? vodTime,
    Expression<int>? hits,
    Expression<String>? genres,
    Expression<String>? description,
    Expression<String>? content,
    Expression<String>? director,
    Expression<String>? writer,
    Expression<String>? lang,
    Expression<String>? urls,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sourceId != null) 'source_id': sourceId,
      if (apiId != null) 'api_id': apiId,
      if (title != null) 'title': title,
      if (coverUrl != null) 'cover_url': coverUrl,
      if (thumbUrl != null) 'thumb_url': thumbUrl,
      if (backdropUrl != null) 'backdrop_url': backdropUrl,
      if (rating != null) 'rating': rating,
      if (year != null) 'year': year,
      if (region != null) 'region': region,
      if (type != null) 'type': type,
      if (typeId != null) 'type_id': typeId,
      if (typeId1 != null) 'type_id1': typeId1,
      if (actor != null) 'actor': actor,
      if (blurb != null) 'blurb': blurb,
      if (remarks != null) 'remarks': remarks,
      if (version != null) 'version': version,
      if (vip != null) 'vip': vip,
      if (vodTime != null) 'vod_time': vodTime,
      if (hits != null) 'hits': hits,
      if (genres != null) 'genres': genres,
      if (description != null) 'description': description,
      if (content != null) 'content': content,
      if (director != null) 'director': director,
      if (writer != null) 'writer': writer,
      if (lang != null) 'lang': lang,
      if (urls != null) 'urls': urls,
    });
  }

  VideosCompanion copyWith({
    Value<int>? id,
    Value<String?>? sourceId,
    Value<int>? apiId,
    Value<String>? title,
    Value<String>? coverUrl,
    Value<String?>? thumbUrl,
    Value<String?>? backdropUrl,
    Value<double>? rating,
    Value<String?>? year,
    Value<String?>? region,
    Value<String>? type,
    Value<int?>? typeId,
    Value<int?>? typeId1,
    Value<String?>? actor,
    Value<String?>? blurb,
    Value<String?>? remarks,
    Value<String?>? version,
    Value<bool?>? vip,
    Value<int?>? vodTime,
    Value<int?>? hits,
    Value<List<String>?>? genres,
    Value<String?>? description,
    Value<String?>? content,
    Value<String?>? director,
    Value<String?>? writer,
    Value<String?>? lang,
    Value<List<VideoEpisode>?>? urls,
  }) {
    return VideosCompanion(
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
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (sourceId.present) {
      map['source_id'] = Variable<String>(sourceId.value);
    }
    if (apiId.present) {
      map['api_id'] = Variable<int>(apiId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (coverUrl.present) {
      map['cover_url'] = Variable<String>(coverUrl.value);
    }
    if (thumbUrl.present) {
      map['thumb_url'] = Variable<String>(thumbUrl.value);
    }
    if (backdropUrl.present) {
      map['backdrop_url'] = Variable<String>(backdropUrl.value);
    }
    if (rating.present) {
      map['rating'] = Variable<double>(rating.value);
    }
    if (year.present) {
      map['year'] = Variable<String>(year.value);
    }
    if (region.present) {
      map['region'] = Variable<String>(region.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (typeId.present) {
      map['type_id'] = Variable<int>(typeId.value);
    }
    if (typeId1.present) {
      map['type_id1'] = Variable<int>(typeId1.value);
    }
    if (actor.present) {
      map['actor'] = Variable<String>(actor.value);
    }
    if (blurb.present) {
      map['blurb'] = Variable<String>(blurb.value);
    }
    if (remarks.present) {
      map['remarks'] = Variable<String>(remarks.value);
    }
    if (version.present) {
      map['version'] = Variable<String>(version.value);
    }
    if (vip.present) {
      map['vip'] = Variable<bool>(vip.value);
    }
    if (vodTime.present) {
      map['vod_time'] = Variable<int>(vodTime.value);
    }
    if (hits.present) {
      map['hits'] = Variable<int>(hits.value);
    }
    if (genres.present) {
      map['genres'] = Variable<String>(
        $VideosTable.$convertergenresn.toSql(genres.value),
      );
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (director.present) {
      map['director'] = Variable<String>(director.value);
    }
    if (writer.present) {
      map['writer'] = Variable<String>(writer.value);
    }
    if (lang.present) {
      map['lang'] = Variable<String>(lang.value);
    }
    if (urls.present) {
      map['urls'] = Variable<String>(
        $VideosTable.$converterurlsn.toSql(urls.value),
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VideosCompanion(')
          ..write('id: $id, ')
          ..write('sourceId: $sourceId, ')
          ..write('apiId: $apiId, ')
          ..write('title: $title, ')
          ..write('coverUrl: $coverUrl, ')
          ..write('thumbUrl: $thumbUrl, ')
          ..write('backdropUrl: $backdropUrl, ')
          ..write('rating: $rating, ')
          ..write('year: $year, ')
          ..write('region: $region, ')
          ..write('type: $type, ')
          ..write('typeId: $typeId, ')
          ..write('typeId1: $typeId1, ')
          ..write('actor: $actor, ')
          ..write('blurb: $blurb, ')
          ..write('remarks: $remarks, ')
          ..write('version: $version, ')
          ..write('vip: $vip, ')
          ..write('vodTime: $vodTime, ')
          ..write('hits: $hits, ')
          ..write('genres: $genres, ')
          ..write('description: $description, ')
          ..write('content: $content, ')
          ..write('director: $director, ')
          ..write('writer: $writer, ')
          ..write('lang: $lang, ')
          ..write('urls: $urls')
          ..write(')'))
        .toString();
  }
}

class $VideoSettingsTable extends VideoSettings
    with TableInfo<$VideoSettingsTable, VideoSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VideoSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _sourceIdMeta = const VerificationMeta(
    'sourceId',
  );
  @override
  late final GeneratedColumn<String> sourceId = GeneratedColumn<String>(
    'source_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _videoIdMeta = const VerificationMeta(
    'videoId',
  );
  @override
  late final GeneratedColumn<int> videoId = GeneratedColumn<int>(
    'video_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _introDurationMeta = const VerificationMeta(
    'introDuration',
  );
  @override
  late final GeneratedColumn<int> introDuration = GeneratedColumn<int>(
    'intro_duration',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _outroDurationMeta = const VerificationMeta(
    'outroDuration',
  );
  @override
  late final GeneratedColumn<int> outroDuration = GeneratedColumn<int>(
    'outro_duration',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _autoSkipMeta = const VerificationMeta(
    'autoSkip',
  );
  @override
  late final GeneratedColumn<bool> autoSkip = GeneratedColumn<bool>(
    'auto_skip',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("auto_skip" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sourceId,
    videoId,
    introDuration,
    outroDuration,
    autoSkip,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'video_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<VideoSetting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('source_id')) {
      context.handle(
        _sourceIdMeta,
        sourceId.isAcceptableOrUnknown(data['source_id']!, _sourceIdMeta),
      );
    }
    if (data.containsKey('video_id')) {
      context.handle(
        _videoIdMeta,
        videoId.isAcceptableOrUnknown(data['video_id']!, _videoIdMeta),
      );
    } else if (isInserting) {
      context.missing(_videoIdMeta);
    }
    if (data.containsKey('intro_duration')) {
      context.handle(
        _introDurationMeta,
        introDuration.isAcceptableOrUnknown(
          data['intro_duration']!,
          _introDurationMeta,
        ),
      );
    }
    if (data.containsKey('outro_duration')) {
      context.handle(
        _outroDurationMeta,
        outroDuration.isAcceptableOrUnknown(
          data['outro_duration']!,
          _outroDurationMeta,
        ),
      );
    }
    if (data.containsKey('auto_skip')) {
      context.handle(
        _autoSkipMeta,
        autoSkip.isAcceptableOrUnknown(data['auto_skip']!, _autoSkipMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  VideoSetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return VideoSetting(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      sourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_id'],
      ),
      videoId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}video_id'],
      )!,
      introDuration: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}intro_duration'],
      )!,
      outroDuration: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}outro_duration'],
      )!,
      autoSkip: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}auto_skip'],
      )!,
    );
  }

  @override
  $VideoSettingsTable createAlias(String alias) {
    return $VideoSettingsTable(attachedDatabase, alias);
  }
}

class VideoSetting extends DataClass implements Insertable<VideoSetting> {
  final int id;
  final String? sourceId;
  final int videoId;
  final int introDuration;
  final int outroDuration;

  /// Master switch for intro/outro skipping. Lives here, per show, because
  /// "this one has a post-credits scene" is a property of the show. It was
  /// hardcoded true on read and dropped on write, so turning it off survived
  /// exactly until the next launch.
  final bool autoSkip;
  const VideoSetting({
    required this.id,
    this.sourceId,
    required this.videoId,
    required this.introDuration,
    required this.outroDuration,
    required this.autoSkip,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || sourceId != null) {
      map['source_id'] = Variable<String>(sourceId);
    }
    map['video_id'] = Variable<int>(videoId);
    map['intro_duration'] = Variable<int>(introDuration);
    map['outro_duration'] = Variable<int>(outroDuration);
    map['auto_skip'] = Variable<bool>(autoSkip);
    return map;
  }

  VideoSettingsCompanion toCompanion(bool nullToAbsent) {
    return VideoSettingsCompanion(
      id: Value(id),
      sourceId: sourceId == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceId),
      videoId: Value(videoId),
      introDuration: Value(introDuration),
      outroDuration: Value(outroDuration),
      autoSkip: Value(autoSkip),
    );
  }

  factory VideoSetting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return VideoSetting(
      id: serializer.fromJson<int>(json['id']),
      sourceId: serializer.fromJson<String?>(json['sourceId']),
      videoId: serializer.fromJson<int>(json['videoId']),
      introDuration: serializer.fromJson<int>(json['introDuration']),
      outroDuration: serializer.fromJson<int>(json['outroDuration']),
      autoSkip: serializer.fromJson<bool>(json['autoSkip']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'sourceId': serializer.toJson<String?>(sourceId),
      'videoId': serializer.toJson<int>(videoId),
      'introDuration': serializer.toJson<int>(introDuration),
      'outroDuration': serializer.toJson<int>(outroDuration),
      'autoSkip': serializer.toJson<bool>(autoSkip),
    };
  }

  VideoSetting copyWith({
    int? id,
    Value<String?> sourceId = const Value.absent(),
    int? videoId,
    int? introDuration,
    int? outroDuration,
    bool? autoSkip,
  }) => VideoSetting(
    id: id ?? this.id,
    sourceId: sourceId.present ? sourceId.value : this.sourceId,
    videoId: videoId ?? this.videoId,
    introDuration: introDuration ?? this.introDuration,
    outroDuration: outroDuration ?? this.outroDuration,
    autoSkip: autoSkip ?? this.autoSkip,
  );
  VideoSetting copyWithCompanion(VideoSettingsCompanion data) {
    return VideoSetting(
      id: data.id.present ? data.id.value : this.id,
      sourceId: data.sourceId.present ? data.sourceId.value : this.sourceId,
      videoId: data.videoId.present ? data.videoId.value : this.videoId,
      introDuration: data.introDuration.present
          ? data.introDuration.value
          : this.introDuration,
      outroDuration: data.outroDuration.present
          ? data.outroDuration.value
          : this.outroDuration,
      autoSkip: data.autoSkip.present ? data.autoSkip.value : this.autoSkip,
    );
  }

  @override
  String toString() {
    return (StringBuffer('VideoSetting(')
          ..write('id: $id, ')
          ..write('sourceId: $sourceId, ')
          ..write('videoId: $videoId, ')
          ..write('introDuration: $introDuration, ')
          ..write('outroDuration: $outroDuration, ')
          ..write('autoSkip: $autoSkip')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    sourceId,
    videoId,
    introDuration,
    outroDuration,
    autoSkip,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is VideoSetting &&
          other.id == this.id &&
          other.sourceId == this.sourceId &&
          other.videoId == this.videoId &&
          other.introDuration == this.introDuration &&
          other.outroDuration == this.outroDuration &&
          other.autoSkip == this.autoSkip);
}

class VideoSettingsCompanion extends UpdateCompanion<VideoSetting> {
  final Value<int> id;
  final Value<String?> sourceId;
  final Value<int> videoId;
  final Value<int> introDuration;
  final Value<int> outroDuration;
  final Value<bool> autoSkip;
  const VideoSettingsCompanion({
    this.id = const Value.absent(),
    this.sourceId = const Value.absent(),
    this.videoId = const Value.absent(),
    this.introDuration = const Value.absent(),
    this.outroDuration = const Value.absent(),
    this.autoSkip = const Value.absent(),
  });
  VideoSettingsCompanion.insert({
    this.id = const Value.absent(),
    this.sourceId = const Value.absent(),
    required int videoId,
    this.introDuration = const Value.absent(),
    this.outroDuration = const Value.absent(),
    this.autoSkip = const Value.absent(),
  }) : videoId = Value(videoId);
  static Insertable<VideoSetting> custom({
    Expression<int>? id,
    Expression<String>? sourceId,
    Expression<int>? videoId,
    Expression<int>? introDuration,
    Expression<int>? outroDuration,
    Expression<bool>? autoSkip,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sourceId != null) 'source_id': sourceId,
      if (videoId != null) 'video_id': videoId,
      if (introDuration != null) 'intro_duration': introDuration,
      if (outroDuration != null) 'outro_duration': outroDuration,
      if (autoSkip != null) 'auto_skip': autoSkip,
    });
  }

  VideoSettingsCompanion copyWith({
    Value<int>? id,
    Value<String?>? sourceId,
    Value<int>? videoId,
    Value<int>? introDuration,
    Value<int>? outroDuration,
    Value<bool>? autoSkip,
  }) {
    return VideoSettingsCompanion(
      id: id ?? this.id,
      sourceId: sourceId ?? this.sourceId,
      videoId: videoId ?? this.videoId,
      introDuration: introDuration ?? this.introDuration,
      outroDuration: outroDuration ?? this.outroDuration,
      autoSkip: autoSkip ?? this.autoSkip,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (sourceId.present) {
      map['source_id'] = Variable<String>(sourceId.value);
    }
    if (videoId.present) {
      map['video_id'] = Variable<int>(videoId.value);
    }
    if (introDuration.present) {
      map['intro_duration'] = Variable<int>(introDuration.value);
    }
    if (outroDuration.present) {
      map['outro_duration'] = Variable<int>(outroDuration.value);
    }
    if (autoSkip.present) {
      map['auto_skip'] = Variable<bool>(autoSkip.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VideoSettingsCompanion(')
          ..write('id: $id, ')
          ..write('sourceId: $sourceId, ')
          ..write('videoId: $videoId, ')
          ..write('introDuration: $introDuration, ')
          ..write('outroDuration: $outroDuration, ')
          ..write('autoSkip: $autoSkip')
          ..write(')'))
        .toString();
  }
}

class $VideoHistoryTable extends VideoHistory
    with TableInfo<$VideoHistoryTable, VideoHistoryData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VideoHistoryTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _sourceIdMeta = const VerificationMeta(
    'sourceId',
  );
  @override
  late final GeneratedColumn<String> sourceId = GeneratedColumn<String>(
    'source_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _videoIdMeta = const VerificationMeta(
    'videoId',
  );
  @override
  late final GeneratedColumn<int> videoId = GeneratedColumn<int>(
    'video_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _videoTitleMeta = const VerificationMeta(
    'videoTitle',
  );
  @override
  late final GeneratedColumn<String> videoTitle = GeneratedColumn<String>(
    'video_title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _coverUrlMeta = const VerificationMeta(
    'coverUrl',
  );
  @override
  late final GeneratedColumn<String> coverUrl = GeneratedColumn<String>(
    'cover_url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ratingMeta = const VerificationMeta('rating');
  @override
  late final GeneratedColumn<String> rating = GeneratedColumn<String>(
    'rating',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _regionMeta = const VerificationMeta('region');
  @override
  late final GeneratedColumn<String> region = GeneratedColumn<String>(
    'region',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _yearMeta = const VerificationMeta('year');
  @override
  late final GeneratedColumn<String> year = GeneratedColumn<String>(
    'year',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _actorMeta = const VerificationMeta('actor');
  @override
  late final GeneratedColumn<String> actor = GeneratedColumn<String>(
    'actor',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<String> version = GeneratedColumn<String>(
    'version',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _hitsMeta = const VerificationMeta('hits');
  @override
  late final GeneratedColumn<int> hits = GeneratedColumn<int>(
    'hits',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _remarksMeta = const VerificationMeta(
    'remarks',
  );
  @override
  late final GeneratedColumn<String> remarks = GeneratedColumn<String>(
    'remarks',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _blurbMeta = const VerificationMeta('blurb');
  @override
  late final GeneratedColumn<String> blurb = GeneratedColumn<String>(
    'blurb',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastEpisodeIndexMeta = const VerificationMeta(
    'lastEpisodeIndex',
  );
  @override
  late final GeneratedColumn<int> lastEpisodeIndex = GeneratedColumn<int>(
    'last_episode_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastEpisodeTitleMeta = const VerificationMeta(
    'lastEpisodeTitle',
  );
  @override
  late final GeneratedColumn<String> lastEpisodeTitle = GeneratedColumn<String>(
    'last_episode_title',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sourceId,
    videoId,
    videoTitle,
    coverUrl,
    rating,
    type,
    region,
    year,
    actor,
    version,
    hits,
    remarks,
    blurb,
    lastEpisodeIndex,
    lastEpisodeTitle,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'video_history';
  @override
  VerificationContext validateIntegrity(
    Insertable<VideoHistoryData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('source_id')) {
      context.handle(
        _sourceIdMeta,
        sourceId.isAcceptableOrUnknown(data['source_id']!, _sourceIdMeta),
      );
    }
    if (data.containsKey('video_id')) {
      context.handle(
        _videoIdMeta,
        videoId.isAcceptableOrUnknown(data['video_id']!, _videoIdMeta),
      );
    } else if (isInserting) {
      context.missing(_videoIdMeta);
    }
    if (data.containsKey('video_title')) {
      context.handle(
        _videoTitleMeta,
        videoTitle.isAcceptableOrUnknown(data['video_title']!, _videoTitleMeta),
      );
    } else if (isInserting) {
      context.missing(_videoTitleMeta);
    }
    if (data.containsKey('cover_url')) {
      context.handle(
        _coverUrlMeta,
        coverUrl.isAcceptableOrUnknown(data['cover_url']!, _coverUrlMeta),
      );
    } else if (isInserting) {
      context.missing(_coverUrlMeta);
    }
    if (data.containsKey('rating')) {
      context.handle(
        _ratingMeta,
        rating.isAcceptableOrUnknown(data['rating']!, _ratingMeta),
      );
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('region')) {
      context.handle(
        _regionMeta,
        region.isAcceptableOrUnknown(data['region']!, _regionMeta),
      );
    }
    if (data.containsKey('year')) {
      context.handle(
        _yearMeta,
        year.isAcceptableOrUnknown(data['year']!, _yearMeta),
      );
    }
    if (data.containsKey('actor')) {
      context.handle(
        _actorMeta,
        actor.isAcceptableOrUnknown(data['actor']!, _actorMeta),
      );
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    }
    if (data.containsKey('hits')) {
      context.handle(
        _hitsMeta,
        hits.isAcceptableOrUnknown(data['hits']!, _hitsMeta),
      );
    }
    if (data.containsKey('remarks')) {
      context.handle(
        _remarksMeta,
        remarks.isAcceptableOrUnknown(data['remarks']!, _remarksMeta),
      );
    }
    if (data.containsKey('blurb')) {
      context.handle(
        _blurbMeta,
        blurb.isAcceptableOrUnknown(data['blurb']!, _blurbMeta),
      );
    }
    if (data.containsKey('last_episode_index')) {
      context.handle(
        _lastEpisodeIndexMeta,
        lastEpisodeIndex.isAcceptableOrUnknown(
          data['last_episode_index']!,
          _lastEpisodeIndexMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastEpisodeIndexMeta);
    }
    if (data.containsKey('last_episode_title')) {
      context.handle(
        _lastEpisodeTitleMeta,
        lastEpisodeTitle.isAcceptableOrUnknown(
          data['last_episode_title']!,
          _lastEpisodeTitleMeta,
        ),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  VideoHistoryData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return VideoHistoryData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      sourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_id'],
      ),
      videoId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}video_id'],
      )!,
      videoTitle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}video_title'],
      )!,
      coverUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cover_url'],
      )!,
      rating: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rating'],
      ),
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      region: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}region'],
      ),
      year: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}year'],
      ),
      actor: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}actor'],
      ),
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}version'],
      ),
      hits: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}hits'],
      ),
      remarks: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remarks'],
      ),
      blurb: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}blurb'],
      ),
      lastEpisodeIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_episode_index'],
      )!,
      lastEpisodeTitle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_episode_title'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $VideoHistoryTable createAlias(String alias) {
    return $VideoHistoryTable(attachedDatabase, alias);
  }
}

class VideoHistoryData extends DataClass
    implements Insertable<VideoHistoryData> {
  final int id;
  final String? sourceId;
  final int videoId;
  final String videoTitle;
  final String coverUrl;
  final String? rating;
  final String type;
  final String? region;
  final String? year;
  final String? actor;
  final String? version;
  final int? hits;
  final String? remarks;
  final String? blurb;
  final int lastEpisodeIndex;
  final String? lastEpisodeTitle;
  final DateTime updatedAt;
  const VideoHistoryData({
    required this.id,
    this.sourceId,
    required this.videoId,
    required this.videoTitle,
    required this.coverUrl,
    this.rating,
    required this.type,
    this.region,
    this.year,
    this.actor,
    this.version,
    this.hits,
    this.remarks,
    this.blurb,
    required this.lastEpisodeIndex,
    this.lastEpisodeTitle,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || sourceId != null) {
      map['source_id'] = Variable<String>(sourceId);
    }
    map['video_id'] = Variable<int>(videoId);
    map['video_title'] = Variable<String>(videoTitle);
    map['cover_url'] = Variable<String>(coverUrl);
    if (!nullToAbsent || rating != null) {
      map['rating'] = Variable<String>(rating);
    }
    map['type'] = Variable<String>(type);
    if (!nullToAbsent || region != null) {
      map['region'] = Variable<String>(region);
    }
    if (!nullToAbsent || year != null) {
      map['year'] = Variable<String>(year);
    }
    if (!nullToAbsent || actor != null) {
      map['actor'] = Variable<String>(actor);
    }
    if (!nullToAbsent || version != null) {
      map['version'] = Variable<String>(version);
    }
    if (!nullToAbsent || hits != null) {
      map['hits'] = Variable<int>(hits);
    }
    if (!nullToAbsent || remarks != null) {
      map['remarks'] = Variable<String>(remarks);
    }
    if (!nullToAbsent || blurb != null) {
      map['blurb'] = Variable<String>(blurb);
    }
    map['last_episode_index'] = Variable<int>(lastEpisodeIndex);
    if (!nullToAbsent || lastEpisodeTitle != null) {
      map['last_episode_title'] = Variable<String>(lastEpisodeTitle);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  VideoHistoryCompanion toCompanion(bool nullToAbsent) {
    return VideoHistoryCompanion(
      id: Value(id),
      sourceId: sourceId == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceId),
      videoId: Value(videoId),
      videoTitle: Value(videoTitle),
      coverUrl: Value(coverUrl),
      rating: rating == null && nullToAbsent
          ? const Value.absent()
          : Value(rating),
      type: Value(type),
      region: region == null && nullToAbsent
          ? const Value.absent()
          : Value(region),
      year: year == null && nullToAbsent ? const Value.absent() : Value(year),
      actor: actor == null && nullToAbsent
          ? const Value.absent()
          : Value(actor),
      version: version == null && nullToAbsent
          ? const Value.absent()
          : Value(version),
      hits: hits == null && nullToAbsent ? const Value.absent() : Value(hits),
      remarks: remarks == null && nullToAbsent
          ? const Value.absent()
          : Value(remarks),
      blurb: blurb == null && nullToAbsent
          ? const Value.absent()
          : Value(blurb),
      lastEpisodeIndex: Value(lastEpisodeIndex),
      lastEpisodeTitle: lastEpisodeTitle == null && nullToAbsent
          ? const Value.absent()
          : Value(lastEpisodeTitle),
      updatedAt: Value(updatedAt),
    );
  }

  factory VideoHistoryData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return VideoHistoryData(
      id: serializer.fromJson<int>(json['id']),
      sourceId: serializer.fromJson<String?>(json['sourceId']),
      videoId: serializer.fromJson<int>(json['videoId']),
      videoTitle: serializer.fromJson<String>(json['videoTitle']),
      coverUrl: serializer.fromJson<String>(json['coverUrl']),
      rating: serializer.fromJson<String?>(json['rating']),
      type: serializer.fromJson<String>(json['type']),
      region: serializer.fromJson<String?>(json['region']),
      year: serializer.fromJson<String?>(json['year']),
      actor: serializer.fromJson<String?>(json['actor']),
      version: serializer.fromJson<String?>(json['version']),
      hits: serializer.fromJson<int?>(json['hits']),
      remarks: serializer.fromJson<String?>(json['remarks']),
      blurb: serializer.fromJson<String?>(json['blurb']),
      lastEpisodeIndex: serializer.fromJson<int>(json['lastEpisodeIndex']),
      lastEpisodeTitle: serializer.fromJson<String?>(json['lastEpisodeTitle']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'sourceId': serializer.toJson<String?>(sourceId),
      'videoId': serializer.toJson<int>(videoId),
      'videoTitle': serializer.toJson<String>(videoTitle),
      'coverUrl': serializer.toJson<String>(coverUrl),
      'rating': serializer.toJson<String?>(rating),
      'type': serializer.toJson<String>(type),
      'region': serializer.toJson<String?>(region),
      'year': serializer.toJson<String?>(year),
      'actor': serializer.toJson<String?>(actor),
      'version': serializer.toJson<String?>(version),
      'hits': serializer.toJson<int?>(hits),
      'remarks': serializer.toJson<String?>(remarks),
      'blurb': serializer.toJson<String?>(blurb),
      'lastEpisodeIndex': serializer.toJson<int>(lastEpisodeIndex),
      'lastEpisodeTitle': serializer.toJson<String?>(lastEpisodeTitle),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  VideoHistoryData copyWith({
    int? id,
    Value<String?> sourceId = const Value.absent(),
    int? videoId,
    String? videoTitle,
    String? coverUrl,
    Value<String?> rating = const Value.absent(),
    String? type,
    Value<String?> region = const Value.absent(),
    Value<String?> year = const Value.absent(),
    Value<String?> actor = const Value.absent(),
    Value<String?> version = const Value.absent(),
    Value<int?> hits = const Value.absent(),
    Value<String?> remarks = const Value.absent(),
    Value<String?> blurb = const Value.absent(),
    int? lastEpisodeIndex,
    Value<String?> lastEpisodeTitle = const Value.absent(),
    DateTime? updatedAt,
  }) => VideoHistoryData(
    id: id ?? this.id,
    sourceId: sourceId.present ? sourceId.value : this.sourceId,
    videoId: videoId ?? this.videoId,
    videoTitle: videoTitle ?? this.videoTitle,
    coverUrl: coverUrl ?? this.coverUrl,
    rating: rating.present ? rating.value : this.rating,
    type: type ?? this.type,
    region: region.present ? region.value : this.region,
    year: year.present ? year.value : this.year,
    actor: actor.present ? actor.value : this.actor,
    version: version.present ? version.value : this.version,
    hits: hits.present ? hits.value : this.hits,
    remarks: remarks.present ? remarks.value : this.remarks,
    blurb: blurb.present ? blurb.value : this.blurb,
    lastEpisodeIndex: lastEpisodeIndex ?? this.lastEpisodeIndex,
    lastEpisodeTitle: lastEpisodeTitle.present
        ? lastEpisodeTitle.value
        : this.lastEpisodeTitle,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  VideoHistoryData copyWithCompanion(VideoHistoryCompanion data) {
    return VideoHistoryData(
      id: data.id.present ? data.id.value : this.id,
      sourceId: data.sourceId.present ? data.sourceId.value : this.sourceId,
      videoId: data.videoId.present ? data.videoId.value : this.videoId,
      videoTitle: data.videoTitle.present
          ? data.videoTitle.value
          : this.videoTitle,
      coverUrl: data.coverUrl.present ? data.coverUrl.value : this.coverUrl,
      rating: data.rating.present ? data.rating.value : this.rating,
      type: data.type.present ? data.type.value : this.type,
      region: data.region.present ? data.region.value : this.region,
      year: data.year.present ? data.year.value : this.year,
      actor: data.actor.present ? data.actor.value : this.actor,
      version: data.version.present ? data.version.value : this.version,
      hits: data.hits.present ? data.hits.value : this.hits,
      remarks: data.remarks.present ? data.remarks.value : this.remarks,
      blurb: data.blurb.present ? data.blurb.value : this.blurb,
      lastEpisodeIndex: data.lastEpisodeIndex.present
          ? data.lastEpisodeIndex.value
          : this.lastEpisodeIndex,
      lastEpisodeTitle: data.lastEpisodeTitle.present
          ? data.lastEpisodeTitle.value
          : this.lastEpisodeTitle,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('VideoHistoryData(')
          ..write('id: $id, ')
          ..write('sourceId: $sourceId, ')
          ..write('videoId: $videoId, ')
          ..write('videoTitle: $videoTitle, ')
          ..write('coverUrl: $coverUrl, ')
          ..write('rating: $rating, ')
          ..write('type: $type, ')
          ..write('region: $region, ')
          ..write('year: $year, ')
          ..write('actor: $actor, ')
          ..write('version: $version, ')
          ..write('hits: $hits, ')
          ..write('remarks: $remarks, ')
          ..write('blurb: $blurb, ')
          ..write('lastEpisodeIndex: $lastEpisodeIndex, ')
          ..write('lastEpisodeTitle: $lastEpisodeTitle, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    sourceId,
    videoId,
    videoTitle,
    coverUrl,
    rating,
    type,
    region,
    year,
    actor,
    version,
    hits,
    remarks,
    blurb,
    lastEpisodeIndex,
    lastEpisodeTitle,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is VideoHistoryData &&
          other.id == this.id &&
          other.sourceId == this.sourceId &&
          other.videoId == this.videoId &&
          other.videoTitle == this.videoTitle &&
          other.coverUrl == this.coverUrl &&
          other.rating == this.rating &&
          other.type == this.type &&
          other.region == this.region &&
          other.year == this.year &&
          other.actor == this.actor &&
          other.version == this.version &&
          other.hits == this.hits &&
          other.remarks == this.remarks &&
          other.blurb == this.blurb &&
          other.lastEpisodeIndex == this.lastEpisodeIndex &&
          other.lastEpisodeTitle == this.lastEpisodeTitle &&
          other.updatedAt == this.updatedAt);
}

class VideoHistoryCompanion extends UpdateCompanion<VideoHistoryData> {
  final Value<int> id;
  final Value<String?> sourceId;
  final Value<int> videoId;
  final Value<String> videoTitle;
  final Value<String> coverUrl;
  final Value<String?> rating;
  final Value<String> type;
  final Value<String?> region;
  final Value<String?> year;
  final Value<String?> actor;
  final Value<String?> version;
  final Value<int?> hits;
  final Value<String?> remarks;
  final Value<String?> blurb;
  final Value<int> lastEpisodeIndex;
  final Value<String?> lastEpisodeTitle;
  final Value<DateTime> updatedAt;
  const VideoHistoryCompanion({
    this.id = const Value.absent(),
    this.sourceId = const Value.absent(),
    this.videoId = const Value.absent(),
    this.videoTitle = const Value.absent(),
    this.coverUrl = const Value.absent(),
    this.rating = const Value.absent(),
    this.type = const Value.absent(),
    this.region = const Value.absent(),
    this.year = const Value.absent(),
    this.actor = const Value.absent(),
    this.version = const Value.absent(),
    this.hits = const Value.absent(),
    this.remarks = const Value.absent(),
    this.blurb = const Value.absent(),
    this.lastEpisodeIndex = const Value.absent(),
    this.lastEpisodeTitle = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  VideoHistoryCompanion.insert({
    this.id = const Value.absent(),
    this.sourceId = const Value.absent(),
    required int videoId,
    required String videoTitle,
    required String coverUrl,
    this.rating = const Value.absent(),
    required String type,
    this.region = const Value.absent(),
    this.year = const Value.absent(),
    this.actor = const Value.absent(),
    this.version = const Value.absent(),
    this.hits = const Value.absent(),
    this.remarks = const Value.absent(),
    this.blurb = const Value.absent(),
    required int lastEpisodeIndex,
    this.lastEpisodeTitle = const Value.absent(),
    required DateTime updatedAt,
  }) : videoId = Value(videoId),
       videoTitle = Value(videoTitle),
       coverUrl = Value(coverUrl),
       type = Value(type),
       lastEpisodeIndex = Value(lastEpisodeIndex),
       updatedAt = Value(updatedAt);
  static Insertable<VideoHistoryData> custom({
    Expression<int>? id,
    Expression<String>? sourceId,
    Expression<int>? videoId,
    Expression<String>? videoTitle,
    Expression<String>? coverUrl,
    Expression<String>? rating,
    Expression<String>? type,
    Expression<String>? region,
    Expression<String>? year,
    Expression<String>? actor,
    Expression<String>? version,
    Expression<int>? hits,
    Expression<String>? remarks,
    Expression<String>? blurb,
    Expression<int>? lastEpisodeIndex,
    Expression<String>? lastEpisodeTitle,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sourceId != null) 'source_id': sourceId,
      if (videoId != null) 'video_id': videoId,
      if (videoTitle != null) 'video_title': videoTitle,
      if (coverUrl != null) 'cover_url': coverUrl,
      if (rating != null) 'rating': rating,
      if (type != null) 'type': type,
      if (region != null) 'region': region,
      if (year != null) 'year': year,
      if (actor != null) 'actor': actor,
      if (version != null) 'version': version,
      if (hits != null) 'hits': hits,
      if (remarks != null) 'remarks': remarks,
      if (blurb != null) 'blurb': blurb,
      if (lastEpisodeIndex != null) 'last_episode_index': lastEpisodeIndex,
      if (lastEpisodeTitle != null) 'last_episode_title': lastEpisodeTitle,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  VideoHistoryCompanion copyWith({
    Value<int>? id,
    Value<String?>? sourceId,
    Value<int>? videoId,
    Value<String>? videoTitle,
    Value<String>? coverUrl,
    Value<String?>? rating,
    Value<String>? type,
    Value<String?>? region,
    Value<String?>? year,
    Value<String?>? actor,
    Value<String?>? version,
    Value<int?>? hits,
    Value<String?>? remarks,
    Value<String?>? blurb,
    Value<int>? lastEpisodeIndex,
    Value<String?>? lastEpisodeTitle,
    Value<DateTime>? updatedAt,
  }) {
    return VideoHistoryCompanion(
      id: id ?? this.id,
      sourceId: sourceId ?? this.sourceId,
      videoId: videoId ?? this.videoId,
      videoTitle: videoTitle ?? this.videoTitle,
      coverUrl: coverUrl ?? this.coverUrl,
      rating: rating ?? this.rating,
      type: type ?? this.type,
      region: region ?? this.region,
      year: year ?? this.year,
      actor: actor ?? this.actor,
      version: version ?? this.version,
      hits: hits ?? this.hits,
      remarks: remarks ?? this.remarks,
      blurb: blurb ?? this.blurb,
      lastEpisodeIndex: lastEpisodeIndex ?? this.lastEpisodeIndex,
      lastEpisodeTitle: lastEpisodeTitle ?? this.lastEpisodeTitle,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (sourceId.present) {
      map['source_id'] = Variable<String>(sourceId.value);
    }
    if (videoId.present) {
      map['video_id'] = Variable<int>(videoId.value);
    }
    if (videoTitle.present) {
      map['video_title'] = Variable<String>(videoTitle.value);
    }
    if (coverUrl.present) {
      map['cover_url'] = Variable<String>(coverUrl.value);
    }
    if (rating.present) {
      map['rating'] = Variable<String>(rating.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (region.present) {
      map['region'] = Variable<String>(region.value);
    }
    if (year.present) {
      map['year'] = Variable<String>(year.value);
    }
    if (actor.present) {
      map['actor'] = Variable<String>(actor.value);
    }
    if (version.present) {
      map['version'] = Variable<String>(version.value);
    }
    if (hits.present) {
      map['hits'] = Variable<int>(hits.value);
    }
    if (remarks.present) {
      map['remarks'] = Variable<String>(remarks.value);
    }
    if (blurb.present) {
      map['blurb'] = Variable<String>(blurb.value);
    }
    if (lastEpisodeIndex.present) {
      map['last_episode_index'] = Variable<int>(lastEpisodeIndex.value);
    }
    if (lastEpisodeTitle.present) {
      map['last_episode_title'] = Variable<String>(lastEpisodeTitle.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VideoHistoryCompanion(')
          ..write('id: $id, ')
          ..write('sourceId: $sourceId, ')
          ..write('videoId: $videoId, ')
          ..write('videoTitle: $videoTitle, ')
          ..write('coverUrl: $coverUrl, ')
          ..write('rating: $rating, ')
          ..write('type: $type, ')
          ..write('region: $region, ')
          ..write('year: $year, ')
          ..write('actor: $actor, ')
          ..write('version: $version, ')
          ..write('hits: $hits, ')
          ..write('remarks: $remarks, ')
          ..write('blurb: $blurb, ')
          ..write('lastEpisodeIndex: $lastEpisodeIndex, ')
          ..write('lastEpisodeTitle: $lastEpisodeTitle, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $EpisodeHistoryTable extends EpisodeHistory
    with TableInfo<$EpisodeHistoryTable, EpisodeHistoryData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EpisodeHistoryTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _sourceIdMeta = const VerificationMeta(
    'sourceId',
  );
  @override
  late final GeneratedColumn<String> sourceId = GeneratedColumn<String>(
    'source_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _videoIdMeta = const VerificationMeta(
    'videoId',
  );
  @override
  late final GeneratedColumn<int> videoId = GeneratedColumn<int>(
    'video_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _episodeIndexMeta = const VerificationMeta(
    'episodeIndex',
  );
  @override
  late final GeneratedColumn<int> episodeIndex = GeneratedColumn<int>(
    'episode_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _positionMillisMeta = const VerificationMeta(
    'positionMillis',
  );
  @override
  late final GeneratedColumn<int> positionMillis = GeneratedColumn<int>(
    'position_millis',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _durationMillisMeta = const VerificationMeta(
    'durationMillis',
  );
  @override
  late final GeneratedColumn<int> durationMillis = GeneratedColumn<int>(
    'duration_millis',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sourceId,
    videoId,
    episodeIndex,
    positionMillis,
    durationMillis,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'episode_history';
  @override
  VerificationContext validateIntegrity(
    Insertable<EpisodeHistoryData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('source_id')) {
      context.handle(
        _sourceIdMeta,
        sourceId.isAcceptableOrUnknown(data['source_id']!, _sourceIdMeta),
      );
    }
    if (data.containsKey('video_id')) {
      context.handle(
        _videoIdMeta,
        videoId.isAcceptableOrUnknown(data['video_id']!, _videoIdMeta),
      );
    } else if (isInserting) {
      context.missing(_videoIdMeta);
    }
    if (data.containsKey('episode_index')) {
      context.handle(
        _episodeIndexMeta,
        episodeIndex.isAcceptableOrUnknown(
          data['episode_index']!,
          _episodeIndexMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_episodeIndexMeta);
    }
    if (data.containsKey('position_millis')) {
      context.handle(
        _positionMillisMeta,
        positionMillis.isAcceptableOrUnknown(
          data['position_millis']!,
          _positionMillisMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_positionMillisMeta);
    }
    if (data.containsKey('duration_millis')) {
      context.handle(
        _durationMillisMeta,
        durationMillis.isAcceptableOrUnknown(
          data['duration_millis']!,
          _durationMillisMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_durationMillisMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  EpisodeHistoryData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EpisodeHistoryData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      sourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_id'],
      ),
      videoId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}video_id'],
      )!,
      episodeIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}episode_index'],
      )!,
      positionMillis: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position_millis'],
      )!,
      durationMillis: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_millis'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $EpisodeHistoryTable createAlias(String alias) {
    return $EpisodeHistoryTable(attachedDatabase, alias);
  }
}

class EpisodeHistoryData extends DataClass
    implements Insertable<EpisodeHistoryData> {
  final int id;
  final String? sourceId;
  final int videoId;
  final int episodeIndex;
  final int positionMillis;
  final int durationMillis;
  final DateTime updatedAt;
  const EpisodeHistoryData({
    required this.id,
    this.sourceId,
    required this.videoId,
    required this.episodeIndex,
    required this.positionMillis,
    required this.durationMillis,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || sourceId != null) {
      map['source_id'] = Variable<String>(sourceId);
    }
    map['video_id'] = Variable<int>(videoId);
    map['episode_index'] = Variable<int>(episodeIndex);
    map['position_millis'] = Variable<int>(positionMillis);
    map['duration_millis'] = Variable<int>(durationMillis);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  EpisodeHistoryCompanion toCompanion(bool nullToAbsent) {
    return EpisodeHistoryCompanion(
      id: Value(id),
      sourceId: sourceId == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceId),
      videoId: Value(videoId),
      episodeIndex: Value(episodeIndex),
      positionMillis: Value(positionMillis),
      durationMillis: Value(durationMillis),
      updatedAt: Value(updatedAt),
    );
  }

  factory EpisodeHistoryData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EpisodeHistoryData(
      id: serializer.fromJson<int>(json['id']),
      sourceId: serializer.fromJson<String?>(json['sourceId']),
      videoId: serializer.fromJson<int>(json['videoId']),
      episodeIndex: serializer.fromJson<int>(json['episodeIndex']),
      positionMillis: serializer.fromJson<int>(json['positionMillis']),
      durationMillis: serializer.fromJson<int>(json['durationMillis']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'sourceId': serializer.toJson<String?>(sourceId),
      'videoId': serializer.toJson<int>(videoId),
      'episodeIndex': serializer.toJson<int>(episodeIndex),
      'positionMillis': serializer.toJson<int>(positionMillis),
      'durationMillis': serializer.toJson<int>(durationMillis),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  EpisodeHistoryData copyWith({
    int? id,
    Value<String?> sourceId = const Value.absent(),
    int? videoId,
    int? episodeIndex,
    int? positionMillis,
    int? durationMillis,
    DateTime? updatedAt,
  }) => EpisodeHistoryData(
    id: id ?? this.id,
    sourceId: sourceId.present ? sourceId.value : this.sourceId,
    videoId: videoId ?? this.videoId,
    episodeIndex: episodeIndex ?? this.episodeIndex,
    positionMillis: positionMillis ?? this.positionMillis,
    durationMillis: durationMillis ?? this.durationMillis,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  EpisodeHistoryData copyWithCompanion(EpisodeHistoryCompanion data) {
    return EpisodeHistoryData(
      id: data.id.present ? data.id.value : this.id,
      sourceId: data.sourceId.present ? data.sourceId.value : this.sourceId,
      videoId: data.videoId.present ? data.videoId.value : this.videoId,
      episodeIndex: data.episodeIndex.present
          ? data.episodeIndex.value
          : this.episodeIndex,
      positionMillis: data.positionMillis.present
          ? data.positionMillis.value
          : this.positionMillis,
      durationMillis: data.durationMillis.present
          ? data.durationMillis.value
          : this.durationMillis,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EpisodeHistoryData(')
          ..write('id: $id, ')
          ..write('sourceId: $sourceId, ')
          ..write('videoId: $videoId, ')
          ..write('episodeIndex: $episodeIndex, ')
          ..write('positionMillis: $positionMillis, ')
          ..write('durationMillis: $durationMillis, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    sourceId,
    videoId,
    episodeIndex,
    positionMillis,
    durationMillis,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EpisodeHistoryData &&
          other.id == this.id &&
          other.sourceId == this.sourceId &&
          other.videoId == this.videoId &&
          other.episodeIndex == this.episodeIndex &&
          other.positionMillis == this.positionMillis &&
          other.durationMillis == this.durationMillis &&
          other.updatedAt == this.updatedAt);
}

class EpisodeHistoryCompanion extends UpdateCompanion<EpisodeHistoryData> {
  final Value<int> id;
  final Value<String?> sourceId;
  final Value<int> videoId;
  final Value<int> episodeIndex;
  final Value<int> positionMillis;
  final Value<int> durationMillis;
  final Value<DateTime> updatedAt;
  const EpisodeHistoryCompanion({
    this.id = const Value.absent(),
    this.sourceId = const Value.absent(),
    this.videoId = const Value.absent(),
    this.episodeIndex = const Value.absent(),
    this.positionMillis = const Value.absent(),
    this.durationMillis = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  EpisodeHistoryCompanion.insert({
    this.id = const Value.absent(),
    this.sourceId = const Value.absent(),
    required int videoId,
    required int episodeIndex,
    required int positionMillis,
    required int durationMillis,
    required DateTime updatedAt,
  }) : videoId = Value(videoId),
       episodeIndex = Value(episodeIndex),
       positionMillis = Value(positionMillis),
       durationMillis = Value(durationMillis),
       updatedAt = Value(updatedAt);
  static Insertable<EpisodeHistoryData> custom({
    Expression<int>? id,
    Expression<String>? sourceId,
    Expression<int>? videoId,
    Expression<int>? episodeIndex,
    Expression<int>? positionMillis,
    Expression<int>? durationMillis,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sourceId != null) 'source_id': sourceId,
      if (videoId != null) 'video_id': videoId,
      if (episodeIndex != null) 'episode_index': episodeIndex,
      if (positionMillis != null) 'position_millis': positionMillis,
      if (durationMillis != null) 'duration_millis': durationMillis,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  EpisodeHistoryCompanion copyWith({
    Value<int>? id,
    Value<String?>? sourceId,
    Value<int>? videoId,
    Value<int>? episodeIndex,
    Value<int>? positionMillis,
    Value<int>? durationMillis,
    Value<DateTime>? updatedAt,
  }) {
    return EpisodeHistoryCompanion(
      id: id ?? this.id,
      sourceId: sourceId ?? this.sourceId,
      videoId: videoId ?? this.videoId,
      episodeIndex: episodeIndex ?? this.episodeIndex,
      positionMillis: positionMillis ?? this.positionMillis,
      durationMillis: durationMillis ?? this.durationMillis,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (sourceId.present) {
      map['source_id'] = Variable<String>(sourceId.value);
    }
    if (videoId.present) {
      map['video_id'] = Variable<int>(videoId.value);
    }
    if (episodeIndex.present) {
      map['episode_index'] = Variable<int>(episodeIndex.value);
    }
    if (positionMillis.present) {
      map['position_millis'] = Variable<int>(positionMillis.value);
    }
    if (durationMillis.present) {
      map['duration_millis'] = Variable<int>(durationMillis.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EpisodeHistoryCompanion(')
          ..write('id: $id, ')
          ..write('sourceId: $sourceId, ')
          ..write('videoId: $videoId, ')
          ..write('episodeIndex: $episodeIndex, ')
          ..write('positionMillis: $positionMillis, ')
          ..write('durationMillis: $durationMillis, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $EpisodeSkipDataTable extends EpisodeSkipData
    with TableInfo<$EpisodeSkipDataTable, EpisodeSkipDataData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EpisodeSkipDataTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _sourceIdMeta = const VerificationMeta(
    'sourceId',
  );
  @override
  late final GeneratedColumn<String> sourceId = GeneratedColumn<String>(
    'source_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _videoIdMeta = const VerificationMeta(
    'videoId',
  );
  @override
  late final GeneratedColumn<int> videoId = GeneratedColumn<int>(
    'video_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _episodeIndexMeta = const VerificationMeta(
    'episodeIndex',
  );
  @override
  late final GeneratedColumn<int> episodeIndex = GeneratedColumn<int>(
    'episode_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _introEndMillisMeta = const VerificationMeta(
    'introEndMillis',
  );
  @override
  late final GeneratedColumn<int> introEndMillis = GeneratedColumn<int>(
    'intro_end_millis',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _outroStartMillisMeta = const VerificationMeta(
    'outroStartMillis',
  );
  @override
  late final GeneratedColumn<int> outroStartMillis = GeneratedColumn<int>(
    'outro_start_millis',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _markerSourceMeta = const VerificationMeta(
    'markerSource',
  );
  @override
  late final GeneratedColumn<int> markerSource = GeneratedColumn<int>(
    'marker_source',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sweepHashesMeta = const VerificationMeta(
    'sweepHashes',
  );
  @override
  late final GeneratedColumn<Uint8List> sweepHashes =
      GeneratedColumn<Uint8List>(
        'sweep_hashes',
        aliasedName,
        true,
        type: DriftSqlType.blob,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sourceId,
    videoId,
    episodeIndex,
    introEndMillis,
    outroStartMillis,
    markerSource,
    sweepHashes,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'episode_skip_data';
  @override
  VerificationContext validateIntegrity(
    Insertable<EpisodeSkipDataData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('source_id')) {
      context.handle(
        _sourceIdMeta,
        sourceId.isAcceptableOrUnknown(data['source_id']!, _sourceIdMeta),
      );
    }
    if (data.containsKey('video_id')) {
      context.handle(
        _videoIdMeta,
        videoId.isAcceptableOrUnknown(data['video_id']!, _videoIdMeta),
      );
    } else if (isInserting) {
      context.missing(_videoIdMeta);
    }
    if (data.containsKey('episode_index')) {
      context.handle(
        _episodeIndexMeta,
        episodeIndex.isAcceptableOrUnknown(
          data['episode_index']!,
          _episodeIndexMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_episodeIndexMeta);
    }
    if (data.containsKey('intro_end_millis')) {
      context.handle(
        _introEndMillisMeta,
        introEndMillis.isAcceptableOrUnknown(
          data['intro_end_millis']!,
          _introEndMillisMeta,
        ),
      );
    }
    if (data.containsKey('outro_start_millis')) {
      context.handle(
        _outroStartMillisMeta,
        outroStartMillis.isAcceptableOrUnknown(
          data['outro_start_millis']!,
          _outroStartMillisMeta,
        ),
      );
    }
    if (data.containsKey('marker_source')) {
      context.handle(
        _markerSourceMeta,
        markerSource.isAcceptableOrUnknown(
          data['marker_source']!,
          _markerSourceMeta,
        ),
      );
    }
    if (data.containsKey('sweep_hashes')) {
      context.handle(
        _sweepHashesMeta,
        sweepHashes.isAcceptableOrUnknown(
          data['sweep_hashes']!,
          _sweepHashesMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  EpisodeSkipDataData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EpisodeSkipDataData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      sourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_id'],
      ),
      videoId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}video_id'],
      )!,
      episodeIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}episode_index'],
      )!,
      introEndMillis: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}intro_end_millis'],
      ),
      outroStartMillis: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}outro_start_millis'],
      ),
      markerSource: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}marker_source'],
      ),
      sweepHashes: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}sweep_hashes'],
      ),
    );
  }

  @override
  $EpisodeSkipDataTable createAlias(String alias) {
    return $EpisodeSkipDataTable(attachedDatabase, alias);
  }
}

class EpisodeSkipDataData extends DataClass
    implements Insertable<EpisodeSkipDataData> {
  final int id;
  final String? sourceId;
  final int videoId;
  final int episodeIndex;

  /// Absolute boundaries into the media. Null means "not set for this episode",
  /// which is not the same as zero.
  final int? introEndMillis;
  final int? outroStartMillis;

  /// `MarkerSource.index` from the player SDK. Stored so precedence survives a
  /// restart: without it a re-detected intro would overwrite one the user
  /// placed by hand.
  final int? markerSource;

  /// Perceptual hashes from one sweep, in the SDK's own versioned format.
  /// Opaque here on purpose — this app stores and returns the bytes unchanged,
  /// and the SDK discards a blob it does not recognise.
  final Uint8List? sweepHashes;
  const EpisodeSkipDataData({
    required this.id,
    this.sourceId,
    required this.videoId,
    required this.episodeIndex,
    this.introEndMillis,
    this.outroStartMillis,
    this.markerSource,
    this.sweepHashes,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || sourceId != null) {
      map['source_id'] = Variable<String>(sourceId);
    }
    map['video_id'] = Variable<int>(videoId);
    map['episode_index'] = Variable<int>(episodeIndex);
    if (!nullToAbsent || introEndMillis != null) {
      map['intro_end_millis'] = Variable<int>(introEndMillis);
    }
    if (!nullToAbsent || outroStartMillis != null) {
      map['outro_start_millis'] = Variable<int>(outroStartMillis);
    }
    if (!nullToAbsent || markerSource != null) {
      map['marker_source'] = Variable<int>(markerSource);
    }
    if (!nullToAbsent || sweepHashes != null) {
      map['sweep_hashes'] = Variable<Uint8List>(sweepHashes);
    }
    return map;
  }

  EpisodeSkipDataCompanion toCompanion(bool nullToAbsent) {
    return EpisodeSkipDataCompanion(
      id: Value(id),
      sourceId: sourceId == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceId),
      videoId: Value(videoId),
      episodeIndex: Value(episodeIndex),
      introEndMillis: introEndMillis == null && nullToAbsent
          ? const Value.absent()
          : Value(introEndMillis),
      outroStartMillis: outroStartMillis == null && nullToAbsent
          ? const Value.absent()
          : Value(outroStartMillis),
      markerSource: markerSource == null && nullToAbsent
          ? const Value.absent()
          : Value(markerSource),
      sweepHashes: sweepHashes == null && nullToAbsent
          ? const Value.absent()
          : Value(sweepHashes),
    );
  }

  factory EpisodeSkipDataData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EpisodeSkipDataData(
      id: serializer.fromJson<int>(json['id']),
      sourceId: serializer.fromJson<String?>(json['sourceId']),
      videoId: serializer.fromJson<int>(json['videoId']),
      episodeIndex: serializer.fromJson<int>(json['episodeIndex']),
      introEndMillis: serializer.fromJson<int?>(json['introEndMillis']),
      outroStartMillis: serializer.fromJson<int?>(json['outroStartMillis']),
      markerSource: serializer.fromJson<int?>(json['markerSource']),
      sweepHashes: serializer.fromJson<Uint8List?>(json['sweepHashes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'sourceId': serializer.toJson<String?>(sourceId),
      'videoId': serializer.toJson<int>(videoId),
      'episodeIndex': serializer.toJson<int>(episodeIndex),
      'introEndMillis': serializer.toJson<int?>(introEndMillis),
      'outroStartMillis': serializer.toJson<int?>(outroStartMillis),
      'markerSource': serializer.toJson<int?>(markerSource),
      'sweepHashes': serializer.toJson<Uint8List?>(sweepHashes),
    };
  }

  EpisodeSkipDataData copyWith({
    int? id,
    Value<String?> sourceId = const Value.absent(),
    int? videoId,
    int? episodeIndex,
    Value<int?> introEndMillis = const Value.absent(),
    Value<int?> outroStartMillis = const Value.absent(),
    Value<int?> markerSource = const Value.absent(),
    Value<Uint8List?> sweepHashes = const Value.absent(),
  }) => EpisodeSkipDataData(
    id: id ?? this.id,
    sourceId: sourceId.present ? sourceId.value : this.sourceId,
    videoId: videoId ?? this.videoId,
    episodeIndex: episodeIndex ?? this.episodeIndex,
    introEndMillis: introEndMillis.present
        ? introEndMillis.value
        : this.introEndMillis,
    outroStartMillis: outroStartMillis.present
        ? outroStartMillis.value
        : this.outroStartMillis,
    markerSource: markerSource.present ? markerSource.value : this.markerSource,
    sweepHashes: sweepHashes.present ? sweepHashes.value : this.sweepHashes,
  );
  EpisodeSkipDataData copyWithCompanion(EpisodeSkipDataCompanion data) {
    return EpisodeSkipDataData(
      id: data.id.present ? data.id.value : this.id,
      sourceId: data.sourceId.present ? data.sourceId.value : this.sourceId,
      videoId: data.videoId.present ? data.videoId.value : this.videoId,
      episodeIndex: data.episodeIndex.present
          ? data.episodeIndex.value
          : this.episodeIndex,
      introEndMillis: data.introEndMillis.present
          ? data.introEndMillis.value
          : this.introEndMillis,
      outroStartMillis: data.outroStartMillis.present
          ? data.outroStartMillis.value
          : this.outroStartMillis,
      markerSource: data.markerSource.present
          ? data.markerSource.value
          : this.markerSource,
      sweepHashes: data.sweepHashes.present
          ? data.sweepHashes.value
          : this.sweepHashes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EpisodeSkipDataData(')
          ..write('id: $id, ')
          ..write('sourceId: $sourceId, ')
          ..write('videoId: $videoId, ')
          ..write('episodeIndex: $episodeIndex, ')
          ..write('introEndMillis: $introEndMillis, ')
          ..write('outroStartMillis: $outroStartMillis, ')
          ..write('markerSource: $markerSource, ')
          ..write('sweepHashes: $sweepHashes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    sourceId,
    videoId,
    episodeIndex,
    introEndMillis,
    outroStartMillis,
    markerSource,
    $driftBlobEquality.hash(sweepHashes),
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EpisodeSkipDataData &&
          other.id == this.id &&
          other.sourceId == this.sourceId &&
          other.videoId == this.videoId &&
          other.episodeIndex == this.episodeIndex &&
          other.introEndMillis == this.introEndMillis &&
          other.outroStartMillis == this.outroStartMillis &&
          other.markerSource == this.markerSource &&
          $driftBlobEquality.equals(other.sweepHashes, this.sweepHashes));
}

class EpisodeSkipDataCompanion extends UpdateCompanion<EpisodeSkipDataData> {
  final Value<int> id;
  final Value<String?> sourceId;
  final Value<int> videoId;
  final Value<int> episodeIndex;
  final Value<int?> introEndMillis;
  final Value<int?> outroStartMillis;
  final Value<int?> markerSource;
  final Value<Uint8List?> sweepHashes;
  const EpisodeSkipDataCompanion({
    this.id = const Value.absent(),
    this.sourceId = const Value.absent(),
    this.videoId = const Value.absent(),
    this.episodeIndex = const Value.absent(),
    this.introEndMillis = const Value.absent(),
    this.outroStartMillis = const Value.absent(),
    this.markerSource = const Value.absent(),
    this.sweepHashes = const Value.absent(),
  });
  EpisodeSkipDataCompanion.insert({
    this.id = const Value.absent(),
    this.sourceId = const Value.absent(),
    required int videoId,
    required int episodeIndex,
    this.introEndMillis = const Value.absent(),
    this.outroStartMillis = const Value.absent(),
    this.markerSource = const Value.absent(),
    this.sweepHashes = const Value.absent(),
  }) : videoId = Value(videoId),
       episodeIndex = Value(episodeIndex);
  static Insertable<EpisodeSkipDataData> custom({
    Expression<int>? id,
    Expression<String>? sourceId,
    Expression<int>? videoId,
    Expression<int>? episodeIndex,
    Expression<int>? introEndMillis,
    Expression<int>? outroStartMillis,
    Expression<int>? markerSource,
    Expression<Uint8List>? sweepHashes,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sourceId != null) 'source_id': sourceId,
      if (videoId != null) 'video_id': videoId,
      if (episodeIndex != null) 'episode_index': episodeIndex,
      if (introEndMillis != null) 'intro_end_millis': introEndMillis,
      if (outroStartMillis != null) 'outro_start_millis': outroStartMillis,
      if (markerSource != null) 'marker_source': markerSource,
      if (sweepHashes != null) 'sweep_hashes': sweepHashes,
    });
  }

  EpisodeSkipDataCompanion copyWith({
    Value<int>? id,
    Value<String?>? sourceId,
    Value<int>? videoId,
    Value<int>? episodeIndex,
    Value<int?>? introEndMillis,
    Value<int?>? outroStartMillis,
    Value<int?>? markerSource,
    Value<Uint8List?>? sweepHashes,
  }) {
    return EpisodeSkipDataCompanion(
      id: id ?? this.id,
      sourceId: sourceId ?? this.sourceId,
      videoId: videoId ?? this.videoId,
      episodeIndex: episodeIndex ?? this.episodeIndex,
      introEndMillis: introEndMillis ?? this.introEndMillis,
      outroStartMillis: outroStartMillis ?? this.outroStartMillis,
      markerSource: markerSource ?? this.markerSource,
      sweepHashes: sweepHashes ?? this.sweepHashes,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (sourceId.present) {
      map['source_id'] = Variable<String>(sourceId.value);
    }
    if (videoId.present) {
      map['video_id'] = Variable<int>(videoId.value);
    }
    if (episodeIndex.present) {
      map['episode_index'] = Variable<int>(episodeIndex.value);
    }
    if (introEndMillis.present) {
      map['intro_end_millis'] = Variable<int>(introEndMillis.value);
    }
    if (outroStartMillis.present) {
      map['outro_start_millis'] = Variable<int>(outroStartMillis.value);
    }
    if (markerSource.present) {
      map['marker_source'] = Variable<int>(markerSource.value);
    }
    if (sweepHashes.present) {
      map['sweep_hashes'] = Variable<Uint8List>(sweepHashes.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EpisodeSkipDataCompanion(')
          ..write('id: $id, ')
          ..write('sourceId: $sourceId, ')
          ..write('videoId: $videoId, ')
          ..write('episodeIndex: $episodeIndex, ')
          ..write('introEndMillis: $introEndMillis, ')
          ..write('outroStartMillis: $outroStartMillis, ')
          ..write('markerSource: $markerSource, ')
          ..write('sweepHashes: $sweepHashes')
          ..write(')'))
        .toString();
  }
}

class $SubscriptionsTable extends Subscriptions
    with TableInfo<$SubscriptionsTable, Subscription> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SubscriptionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _sourceIdMeta = const VerificationMeta(
    'sourceId',
  );
  @override
  late final GeneratedColumn<String> sourceId = GeneratedColumn<String>(
    'source_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _videoIdMeta = const VerificationMeta(
    'videoId',
  );
  @override
  late final GeneratedColumn<int> videoId = GeneratedColumn<int>(
    'video_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _yearMeta = const VerificationMeta('year');
  @override
  late final GeneratedColumn<String> year = GeneratedColumn<String>(
    'year',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _coverUrlMeta = const VerificationMeta(
    'coverUrl',
  );
  @override
  late final GeneratedColumn<String> coverUrl = GeneratedColumn<String>(
    'cover_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastSeenRemarksMeta = const VerificationMeta(
    'lastSeenRemarks',
  );
  @override
  late final GeneratedColumn<String> lastSeenRemarks = GeneratedColumn<String>(
    'last_seen_remarks',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastUpdateAtMeta = const VerificationMeta(
    'lastUpdateAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastUpdateAt = GeneratedColumn<DateTime>(
    'last_update_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updateHistoryMeta = const VerificationMeta(
    'updateHistory',
  );
  @override
  late final GeneratedColumn<String> updateHistory = GeneratedColumn<String>(
    'update_history',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nextCheckAtMeta = const VerificationMeta(
    'nextCheckAt',
  );
  @override
  late final GeneratedColumn<DateTime> nextCheckAt = GeneratedColumn<DateTime>(
    'next_check_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _unreadMeta = const VerificationMeta('unread');
  @override
  late final GeneratedColumn<bool> unread = GeneratedColumn<bool>(
    'unread',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("unread" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _finishedMeta = const VerificationMeta(
    'finished',
  );
  @override
  late final GeneratedColumn<bool> finished = GeneratedColumn<bool>(
    'finished',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("finished" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _crossSeenSourceIdMeta = const VerificationMeta(
    'crossSeenSourceId',
  );
  @override
  late final GeneratedColumn<String> crossSeenSourceId =
      GeneratedColumn<String>(
        'cross_seen_source_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _crossSeenRemarksMeta = const VerificationMeta(
    'crossSeenRemarks',
  );
  @override
  late final GeneratedColumn<String> crossSeenRemarks = GeneratedColumn<String>(
    'cross_seen_remarks',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sourceId,
    videoId,
    title,
    year,
    coverUrl,
    lastSeenRemarks,
    lastUpdateAt,
    updateHistory,
    nextCheckAt,
    unread,
    finished,
    crossSeenSourceId,
    crossSeenRemarks,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'subscriptions';
  @override
  VerificationContext validateIntegrity(
    Insertable<Subscription> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('source_id')) {
      context.handle(
        _sourceIdMeta,
        sourceId.isAcceptableOrUnknown(data['source_id']!, _sourceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceIdMeta);
    }
    if (data.containsKey('video_id')) {
      context.handle(
        _videoIdMeta,
        videoId.isAcceptableOrUnknown(data['video_id']!, _videoIdMeta),
      );
    } else if (isInserting) {
      context.missing(_videoIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('year')) {
      context.handle(
        _yearMeta,
        year.isAcceptableOrUnknown(data['year']!, _yearMeta),
      );
    }
    if (data.containsKey('cover_url')) {
      context.handle(
        _coverUrlMeta,
        coverUrl.isAcceptableOrUnknown(data['cover_url']!, _coverUrlMeta),
      );
    }
    if (data.containsKey('last_seen_remarks')) {
      context.handle(
        _lastSeenRemarksMeta,
        lastSeenRemarks.isAcceptableOrUnknown(
          data['last_seen_remarks']!,
          _lastSeenRemarksMeta,
        ),
      );
    }
    if (data.containsKey('last_update_at')) {
      context.handle(
        _lastUpdateAtMeta,
        lastUpdateAt.isAcceptableOrUnknown(
          data['last_update_at']!,
          _lastUpdateAtMeta,
        ),
      );
    }
    if (data.containsKey('update_history')) {
      context.handle(
        _updateHistoryMeta,
        updateHistory.isAcceptableOrUnknown(
          data['update_history']!,
          _updateHistoryMeta,
        ),
      );
    }
    if (data.containsKey('next_check_at')) {
      context.handle(
        _nextCheckAtMeta,
        nextCheckAt.isAcceptableOrUnknown(
          data['next_check_at']!,
          _nextCheckAtMeta,
        ),
      );
    }
    if (data.containsKey('unread')) {
      context.handle(
        _unreadMeta,
        unread.isAcceptableOrUnknown(data['unread']!, _unreadMeta),
      );
    }
    if (data.containsKey('finished')) {
      context.handle(
        _finishedMeta,
        finished.isAcceptableOrUnknown(data['finished']!, _finishedMeta),
      );
    }
    if (data.containsKey('cross_seen_source_id')) {
      context.handle(
        _crossSeenSourceIdMeta,
        crossSeenSourceId.isAcceptableOrUnknown(
          data['cross_seen_source_id']!,
          _crossSeenSourceIdMeta,
        ),
      );
    }
    if (data.containsKey('cross_seen_remarks')) {
      context.handle(
        _crossSeenRemarksMeta,
        crossSeenRemarks.isAcceptableOrUnknown(
          data['cross_seen_remarks']!,
          _crossSeenRemarksMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Subscription map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Subscription(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      sourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_id'],
      )!,
      videoId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}video_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      year: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}year'],
      ),
      coverUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cover_url'],
      ),
      lastSeenRemarks: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_seen_remarks'],
      ),
      lastUpdateAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_update_at'],
      ),
      updateHistory: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}update_history'],
      ),
      nextCheckAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}next_check_at'],
      ),
      unread: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}unread'],
      )!,
      finished: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}finished'],
      )!,
      crossSeenSourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cross_seen_source_id'],
      ),
      crossSeenRemarks: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cross_seen_remarks'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $SubscriptionsTable createAlias(String alias) {
    return $SubscriptionsTable(attachedDatabase, alias);
  }
}

class Subscription extends DataClass implements Insertable<Subscription> {
  final int id;
  final String sourceId;
  final int videoId;
  final String title;
  final String? year;
  final String? coverUrl;

  /// The catalog's own progress line, as last seen. Any change to it is the
  /// update signal — and it arrives free with every listing the user scrolls
  /// past, which is why this feature costs no requests most of the time.
  final String? lastSeenRemarks;
  final DateTime? lastUpdateAt;

  /// Observed update times, JSON, oldest first and capped. The release
  /// schedule is inferred from these — see `UpdateCadence`.
  final String? updateHistory;

  /// Earliest moment a request for this show is worth making. Before it, the
  /// show is skipped entirely.
  final DateTime? nextCheckAt;
  final bool unread;

  /// Finished airing. Never checked again — the cheapest request is the one
  /// never made.
  final bool finished;

  /// The same show's progress as last seen on ANOTHER source (matched by
  /// title + year, like the cross-source watch badge). A drama often lands on
  /// one catalog hours before the other, and a viewer following the slow one
  /// still wants the news when the fast one has it first.
  ///
  /// Kept apart from [lastSeenRemarks] on purpose: sources word their progress
  /// differently ("更新至第 05 集" vs "更新至5集"), so cross-source text must
  /// never enter the same-source comparison — every sweep would read the
  /// wording difference as an update.
  final String? crossSeenSourceId;
  final String? crossSeenRemarks;
  final DateTime createdAt;
  const Subscription({
    required this.id,
    required this.sourceId,
    required this.videoId,
    required this.title,
    this.year,
    this.coverUrl,
    this.lastSeenRemarks,
    this.lastUpdateAt,
    this.updateHistory,
    this.nextCheckAt,
    required this.unread,
    required this.finished,
    this.crossSeenSourceId,
    this.crossSeenRemarks,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['source_id'] = Variable<String>(sourceId);
    map['video_id'] = Variable<int>(videoId);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || year != null) {
      map['year'] = Variable<String>(year);
    }
    if (!nullToAbsent || coverUrl != null) {
      map['cover_url'] = Variable<String>(coverUrl);
    }
    if (!nullToAbsent || lastSeenRemarks != null) {
      map['last_seen_remarks'] = Variable<String>(lastSeenRemarks);
    }
    if (!nullToAbsent || lastUpdateAt != null) {
      map['last_update_at'] = Variable<DateTime>(lastUpdateAt);
    }
    if (!nullToAbsent || updateHistory != null) {
      map['update_history'] = Variable<String>(updateHistory);
    }
    if (!nullToAbsent || nextCheckAt != null) {
      map['next_check_at'] = Variable<DateTime>(nextCheckAt);
    }
    map['unread'] = Variable<bool>(unread);
    map['finished'] = Variable<bool>(finished);
    if (!nullToAbsent || crossSeenSourceId != null) {
      map['cross_seen_source_id'] = Variable<String>(crossSeenSourceId);
    }
    if (!nullToAbsent || crossSeenRemarks != null) {
      map['cross_seen_remarks'] = Variable<String>(crossSeenRemarks);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  SubscriptionsCompanion toCompanion(bool nullToAbsent) {
    return SubscriptionsCompanion(
      id: Value(id),
      sourceId: Value(sourceId),
      videoId: Value(videoId),
      title: Value(title),
      year: year == null && nullToAbsent ? const Value.absent() : Value(year),
      coverUrl: coverUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(coverUrl),
      lastSeenRemarks: lastSeenRemarks == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSeenRemarks),
      lastUpdateAt: lastUpdateAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastUpdateAt),
      updateHistory: updateHistory == null && nullToAbsent
          ? const Value.absent()
          : Value(updateHistory),
      nextCheckAt: nextCheckAt == null && nullToAbsent
          ? const Value.absent()
          : Value(nextCheckAt),
      unread: Value(unread),
      finished: Value(finished),
      crossSeenSourceId: crossSeenSourceId == null && nullToAbsent
          ? const Value.absent()
          : Value(crossSeenSourceId),
      crossSeenRemarks: crossSeenRemarks == null && nullToAbsent
          ? const Value.absent()
          : Value(crossSeenRemarks),
      createdAt: Value(createdAt),
    );
  }

  factory Subscription.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Subscription(
      id: serializer.fromJson<int>(json['id']),
      sourceId: serializer.fromJson<String>(json['sourceId']),
      videoId: serializer.fromJson<int>(json['videoId']),
      title: serializer.fromJson<String>(json['title']),
      year: serializer.fromJson<String?>(json['year']),
      coverUrl: serializer.fromJson<String?>(json['coverUrl']),
      lastSeenRemarks: serializer.fromJson<String?>(json['lastSeenRemarks']),
      lastUpdateAt: serializer.fromJson<DateTime?>(json['lastUpdateAt']),
      updateHistory: serializer.fromJson<String?>(json['updateHistory']),
      nextCheckAt: serializer.fromJson<DateTime?>(json['nextCheckAt']),
      unread: serializer.fromJson<bool>(json['unread']),
      finished: serializer.fromJson<bool>(json['finished']),
      crossSeenSourceId: serializer.fromJson<String?>(
        json['crossSeenSourceId'],
      ),
      crossSeenRemarks: serializer.fromJson<String?>(json['crossSeenRemarks']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'sourceId': serializer.toJson<String>(sourceId),
      'videoId': serializer.toJson<int>(videoId),
      'title': serializer.toJson<String>(title),
      'year': serializer.toJson<String?>(year),
      'coverUrl': serializer.toJson<String?>(coverUrl),
      'lastSeenRemarks': serializer.toJson<String?>(lastSeenRemarks),
      'lastUpdateAt': serializer.toJson<DateTime?>(lastUpdateAt),
      'updateHistory': serializer.toJson<String?>(updateHistory),
      'nextCheckAt': serializer.toJson<DateTime?>(nextCheckAt),
      'unread': serializer.toJson<bool>(unread),
      'finished': serializer.toJson<bool>(finished),
      'crossSeenSourceId': serializer.toJson<String?>(crossSeenSourceId),
      'crossSeenRemarks': serializer.toJson<String?>(crossSeenRemarks),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Subscription copyWith({
    int? id,
    String? sourceId,
    int? videoId,
    String? title,
    Value<String?> year = const Value.absent(),
    Value<String?> coverUrl = const Value.absent(),
    Value<String?> lastSeenRemarks = const Value.absent(),
    Value<DateTime?> lastUpdateAt = const Value.absent(),
    Value<String?> updateHistory = const Value.absent(),
    Value<DateTime?> nextCheckAt = const Value.absent(),
    bool? unread,
    bool? finished,
    Value<String?> crossSeenSourceId = const Value.absent(),
    Value<String?> crossSeenRemarks = const Value.absent(),
    DateTime? createdAt,
  }) => Subscription(
    id: id ?? this.id,
    sourceId: sourceId ?? this.sourceId,
    videoId: videoId ?? this.videoId,
    title: title ?? this.title,
    year: year.present ? year.value : this.year,
    coverUrl: coverUrl.present ? coverUrl.value : this.coverUrl,
    lastSeenRemarks: lastSeenRemarks.present
        ? lastSeenRemarks.value
        : this.lastSeenRemarks,
    lastUpdateAt: lastUpdateAt.present ? lastUpdateAt.value : this.lastUpdateAt,
    updateHistory: updateHistory.present
        ? updateHistory.value
        : this.updateHistory,
    nextCheckAt: nextCheckAt.present ? nextCheckAt.value : this.nextCheckAt,
    unread: unread ?? this.unread,
    finished: finished ?? this.finished,
    crossSeenSourceId: crossSeenSourceId.present
        ? crossSeenSourceId.value
        : this.crossSeenSourceId,
    crossSeenRemarks: crossSeenRemarks.present
        ? crossSeenRemarks.value
        : this.crossSeenRemarks,
    createdAt: createdAt ?? this.createdAt,
  );
  Subscription copyWithCompanion(SubscriptionsCompanion data) {
    return Subscription(
      id: data.id.present ? data.id.value : this.id,
      sourceId: data.sourceId.present ? data.sourceId.value : this.sourceId,
      videoId: data.videoId.present ? data.videoId.value : this.videoId,
      title: data.title.present ? data.title.value : this.title,
      year: data.year.present ? data.year.value : this.year,
      coverUrl: data.coverUrl.present ? data.coverUrl.value : this.coverUrl,
      lastSeenRemarks: data.lastSeenRemarks.present
          ? data.lastSeenRemarks.value
          : this.lastSeenRemarks,
      lastUpdateAt: data.lastUpdateAt.present
          ? data.lastUpdateAt.value
          : this.lastUpdateAt,
      updateHistory: data.updateHistory.present
          ? data.updateHistory.value
          : this.updateHistory,
      nextCheckAt: data.nextCheckAt.present
          ? data.nextCheckAt.value
          : this.nextCheckAt,
      unread: data.unread.present ? data.unread.value : this.unread,
      finished: data.finished.present ? data.finished.value : this.finished,
      crossSeenSourceId: data.crossSeenSourceId.present
          ? data.crossSeenSourceId.value
          : this.crossSeenSourceId,
      crossSeenRemarks: data.crossSeenRemarks.present
          ? data.crossSeenRemarks.value
          : this.crossSeenRemarks,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Subscription(')
          ..write('id: $id, ')
          ..write('sourceId: $sourceId, ')
          ..write('videoId: $videoId, ')
          ..write('title: $title, ')
          ..write('year: $year, ')
          ..write('coverUrl: $coverUrl, ')
          ..write('lastSeenRemarks: $lastSeenRemarks, ')
          ..write('lastUpdateAt: $lastUpdateAt, ')
          ..write('updateHistory: $updateHistory, ')
          ..write('nextCheckAt: $nextCheckAt, ')
          ..write('unread: $unread, ')
          ..write('finished: $finished, ')
          ..write('crossSeenSourceId: $crossSeenSourceId, ')
          ..write('crossSeenRemarks: $crossSeenRemarks, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    sourceId,
    videoId,
    title,
    year,
    coverUrl,
    lastSeenRemarks,
    lastUpdateAt,
    updateHistory,
    nextCheckAt,
    unread,
    finished,
    crossSeenSourceId,
    crossSeenRemarks,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Subscription &&
          other.id == this.id &&
          other.sourceId == this.sourceId &&
          other.videoId == this.videoId &&
          other.title == this.title &&
          other.year == this.year &&
          other.coverUrl == this.coverUrl &&
          other.lastSeenRemarks == this.lastSeenRemarks &&
          other.lastUpdateAt == this.lastUpdateAt &&
          other.updateHistory == this.updateHistory &&
          other.nextCheckAt == this.nextCheckAt &&
          other.unread == this.unread &&
          other.finished == this.finished &&
          other.crossSeenSourceId == this.crossSeenSourceId &&
          other.crossSeenRemarks == this.crossSeenRemarks &&
          other.createdAt == this.createdAt);
}

class SubscriptionsCompanion extends UpdateCompanion<Subscription> {
  final Value<int> id;
  final Value<String> sourceId;
  final Value<int> videoId;
  final Value<String> title;
  final Value<String?> year;
  final Value<String?> coverUrl;
  final Value<String?> lastSeenRemarks;
  final Value<DateTime?> lastUpdateAt;
  final Value<String?> updateHistory;
  final Value<DateTime?> nextCheckAt;
  final Value<bool> unread;
  final Value<bool> finished;
  final Value<String?> crossSeenSourceId;
  final Value<String?> crossSeenRemarks;
  final Value<DateTime> createdAt;
  const SubscriptionsCompanion({
    this.id = const Value.absent(),
    this.sourceId = const Value.absent(),
    this.videoId = const Value.absent(),
    this.title = const Value.absent(),
    this.year = const Value.absent(),
    this.coverUrl = const Value.absent(),
    this.lastSeenRemarks = const Value.absent(),
    this.lastUpdateAt = const Value.absent(),
    this.updateHistory = const Value.absent(),
    this.nextCheckAt = const Value.absent(),
    this.unread = const Value.absent(),
    this.finished = const Value.absent(),
    this.crossSeenSourceId = const Value.absent(),
    this.crossSeenRemarks = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  SubscriptionsCompanion.insert({
    this.id = const Value.absent(),
    required String sourceId,
    required int videoId,
    required String title,
    this.year = const Value.absent(),
    this.coverUrl = const Value.absent(),
    this.lastSeenRemarks = const Value.absent(),
    this.lastUpdateAt = const Value.absent(),
    this.updateHistory = const Value.absent(),
    this.nextCheckAt = const Value.absent(),
    this.unread = const Value.absent(),
    this.finished = const Value.absent(),
    this.crossSeenSourceId = const Value.absent(),
    this.crossSeenRemarks = const Value.absent(),
    required DateTime createdAt,
  }) : sourceId = Value(sourceId),
       videoId = Value(videoId),
       title = Value(title),
       createdAt = Value(createdAt);
  static Insertable<Subscription> custom({
    Expression<int>? id,
    Expression<String>? sourceId,
    Expression<int>? videoId,
    Expression<String>? title,
    Expression<String>? year,
    Expression<String>? coverUrl,
    Expression<String>? lastSeenRemarks,
    Expression<DateTime>? lastUpdateAt,
    Expression<String>? updateHistory,
    Expression<DateTime>? nextCheckAt,
    Expression<bool>? unread,
    Expression<bool>? finished,
    Expression<String>? crossSeenSourceId,
    Expression<String>? crossSeenRemarks,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sourceId != null) 'source_id': sourceId,
      if (videoId != null) 'video_id': videoId,
      if (title != null) 'title': title,
      if (year != null) 'year': year,
      if (coverUrl != null) 'cover_url': coverUrl,
      if (lastSeenRemarks != null) 'last_seen_remarks': lastSeenRemarks,
      if (lastUpdateAt != null) 'last_update_at': lastUpdateAt,
      if (updateHistory != null) 'update_history': updateHistory,
      if (nextCheckAt != null) 'next_check_at': nextCheckAt,
      if (unread != null) 'unread': unread,
      if (finished != null) 'finished': finished,
      if (crossSeenSourceId != null) 'cross_seen_source_id': crossSeenSourceId,
      if (crossSeenRemarks != null) 'cross_seen_remarks': crossSeenRemarks,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  SubscriptionsCompanion copyWith({
    Value<int>? id,
    Value<String>? sourceId,
    Value<int>? videoId,
    Value<String>? title,
    Value<String?>? year,
    Value<String?>? coverUrl,
    Value<String?>? lastSeenRemarks,
    Value<DateTime?>? lastUpdateAt,
    Value<String?>? updateHistory,
    Value<DateTime?>? nextCheckAt,
    Value<bool>? unread,
    Value<bool>? finished,
    Value<String?>? crossSeenSourceId,
    Value<String?>? crossSeenRemarks,
    Value<DateTime>? createdAt,
  }) {
    return SubscriptionsCompanion(
      id: id ?? this.id,
      sourceId: sourceId ?? this.sourceId,
      videoId: videoId ?? this.videoId,
      title: title ?? this.title,
      year: year ?? this.year,
      coverUrl: coverUrl ?? this.coverUrl,
      lastSeenRemarks: lastSeenRemarks ?? this.lastSeenRemarks,
      lastUpdateAt: lastUpdateAt ?? this.lastUpdateAt,
      updateHistory: updateHistory ?? this.updateHistory,
      nextCheckAt: nextCheckAt ?? this.nextCheckAt,
      unread: unread ?? this.unread,
      finished: finished ?? this.finished,
      crossSeenSourceId: crossSeenSourceId ?? this.crossSeenSourceId,
      crossSeenRemarks: crossSeenRemarks ?? this.crossSeenRemarks,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (sourceId.present) {
      map['source_id'] = Variable<String>(sourceId.value);
    }
    if (videoId.present) {
      map['video_id'] = Variable<int>(videoId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (year.present) {
      map['year'] = Variable<String>(year.value);
    }
    if (coverUrl.present) {
      map['cover_url'] = Variable<String>(coverUrl.value);
    }
    if (lastSeenRemarks.present) {
      map['last_seen_remarks'] = Variable<String>(lastSeenRemarks.value);
    }
    if (lastUpdateAt.present) {
      map['last_update_at'] = Variable<DateTime>(lastUpdateAt.value);
    }
    if (updateHistory.present) {
      map['update_history'] = Variable<String>(updateHistory.value);
    }
    if (nextCheckAt.present) {
      map['next_check_at'] = Variable<DateTime>(nextCheckAt.value);
    }
    if (unread.present) {
      map['unread'] = Variable<bool>(unread.value);
    }
    if (finished.present) {
      map['finished'] = Variable<bool>(finished.value);
    }
    if (crossSeenSourceId.present) {
      map['cross_seen_source_id'] = Variable<String>(crossSeenSourceId.value);
    }
    if (crossSeenRemarks.present) {
      map['cross_seen_remarks'] = Variable<String>(crossSeenRemarks.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SubscriptionsCompanion(')
          ..write('id: $id, ')
          ..write('sourceId: $sourceId, ')
          ..write('videoId: $videoId, ')
          ..write('title: $title, ')
          ..write('year: $year, ')
          ..write('coverUrl: $coverUrl, ')
          ..write('lastSeenRemarks: $lastSeenRemarks, ')
          ..write('lastUpdateAt: $lastUpdateAt, ')
          ..write('updateHistory: $updateHistory, ')
          ..write('nextCheckAt: $nextCheckAt, ')
          ..write('unread: $unread, ')
          ..write('finished: $finished, ')
          ..write('crossSeenSourceId: $crossSeenSourceId, ')
          ..write('crossSeenRemarks: $crossSeenRemarks, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $FavoritesTable extends Favorites
    with TableInfo<$FavoritesTable, Favorite> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FavoritesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _sourceIdMeta = const VerificationMeta(
    'sourceId',
  );
  @override
  late final GeneratedColumn<String> sourceId = GeneratedColumn<String>(
    'source_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _videoIdMeta = const VerificationMeta(
    'videoId',
  );
  @override
  late final GeneratedColumn<int> videoId = GeneratedColumn<int>(
    'video_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _yearMeta = const VerificationMeta('year');
  @override
  late final GeneratedColumn<String> year = GeneratedColumn<String>(
    'year',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _coverUrlMeta = const VerificationMeta(
    'coverUrl',
  );
  @override
  late final GeneratedColumn<String> coverUrl = GeneratedColumn<String>(
    'cover_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ratingMeta = const VerificationMeta('rating');
  @override
  late final GeneratedColumn<String> rating = GeneratedColumn<String>(
    'rating',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _regionMeta = const VerificationMeta('region');
  @override
  late final GeneratedColumn<String> region = GeneratedColumn<String>(
    'region',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _remarksMeta = const VerificationMeta(
    'remarks',
  );
  @override
  late final GeneratedColumn<String> remarks = GeneratedColumn<String>(
    'remarks',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sourceId,
    videoId,
    title,
    year,
    coverUrl,
    rating,
    type,
    region,
    remarks,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'favorites';
  @override
  VerificationContext validateIntegrity(
    Insertable<Favorite> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('source_id')) {
      context.handle(
        _sourceIdMeta,
        sourceId.isAcceptableOrUnknown(data['source_id']!, _sourceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceIdMeta);
    }
    if (data.containsKey('video_id')) {
      context.handle(
        _videoIdMeta,
        videoId.isAcceptableOrUnknown(data['video_id']!, _videoIdMeta),
      );
    } else if (isInserting) {
      context.missing(_videoIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('year')) {
      context.handle(
        _yearMeta,
        year.isAcceptableOrUnknown(data['year']!, _yearMeta),
      );
    }
    if (data.containsKey('cover_url')) {
      context.handle(
        _coverUrlMeta,
        coverUrl.isAcceptableOrUnknown(data['cover_url']!, _coverUrlMeta),
      );
    }
    if (data.containsKey('rating')) {
      context.handle(
        _ratingMeta,
        rating.isAcceptableOrUnknown(data['rating']!, _ratingMeta),
      );
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    }
    if (data.containsKey('region')) {
      context.handle(
        _regionMeta,
        region.isAcceptableOrUnknown(data['region']!, _regionMeta),
      );
    }
    if (data.containsKey('remarks')) {
      context.handle(
        _remarksMeta,
        remarks.isAcceptableOrUnknown(data['remarks']!, _remarksMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Favorite map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Favorite(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      sourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_id'],
      )!,
      videoId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}video_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      year: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}year'],
      ),
      coverUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cover_url'],
      ),
      rating: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rating'],
      ),
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      region: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}region'],
      ),
      remarks: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remarks'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $FavoritesTable createAlias(String alias) {
    return $FavoritesTable(attachedDatabase, alias);
  }
}

class Favorite extends DataClass implements Insertable<Favorite> {
  final int id;
  final String sourceId;
  final int videoId;
  final String title;
  final String? year;
  final String? coverUrl;
  final String? rating;
  final String type;
  final String? region;
  final String? remarks;
  final DateTime createdAt;
  const Favorite({
    required this.id,
    required this.sourceId,
    required this.videoId,
    required this.title,
    this.year,
    this.coverUrl,
    this.rating,
    required this.type,
    this.region,
    this.remarks,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['source_id'] = Variable<String>(sourceId);
    map['video_id'] = Variable<int>(videoId);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || year != null) {
      map['year'] = Variable<String>(year);
    }
    if (!nullToAbsent || coverUrl != null) {
      map['cover_url'] = Variable<String>(coverUrl);
    }
    if (!nullToAbsent || rating != null) {
      map['rating'] = Variable<String>(rating);
    }
    map['type'] = Variable<String>(type);
    if (!nullToAbsent || region != null) {
      map['region'] = Variable<String>(region);
    }
    if (!nullToAbsent || remarks != null) {
      map['remarks'] = Variable<String>(remarks);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  FavoritesCompanion toCompanion(bool nullToAbsent) {
    return FavoritesCompanion(
      id: Value(id),
      sourceId: Value(sourceId),
      videoId: Value(videoId),
      title: Value(title),
      year: year == null && nullToAbsent ? const Value.absent() : Value(year),
      coverUrl: coverUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(coverUrl),
      rating: rating == null && nullToAbsent
          ? const Value.absent()
          : Value(rating),
      type: Value(type),
      region: region == null && nullToAbsent
          ? const Value.absent()
          : Value(region),
      remarks: remarks == null && nullToAbsent
          ? const Value.absent()
          : Value(remarks),
      createdAt: Value(createdAt),
    );
  }

  factory Favorite.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Favorite(
      id: serializer.fromJson<int>(json['id']),
      sourceId: serializer.fromJson<String>(json['sourceId']),
      videoId: serializer.fromJson<int>(json['videoId']),
      title: serializer.fromJson<String>(json['title']),
      year: serializer.fromJson<String?>(json['year']),
      coverUrl: serializer.fromJson<String?>(json['coverUrl']),
      rating: serializer.fromJson<String?>(json['rating']),
      type: serializer.fromJson<String>(json['type']),
      region: serializer.fromJson<String?>(json['region']),
      remarks: serializer.fromJson<String?>(json['remarks']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'sourceId': serializer.toJson<String>(sourceId),
      'videoId': serializer.toJson<int>(videoId),
      'title': serializer.toJson<String>(title),
      'year': serializer.toJson<String?>(year),
      'coverUrl': serializer.toJson<String?>(coverUrl),
      'rating': serializer.toJson<String?>(rating),
      'type': serializer.toJson<String>(type),
      'region': serializer.toJson<String?>(region),
      'remarks': serializer.toJson<String?>(remarks),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Favorite copyWith({
    int? id,
    String? sourceId,
    int? videoId,
    String? title,
    Value<String?> year = const Value.absent(),
    Value<String?> coverUrl = const Value.absent(),
    Value<String?> rating = const Value.absent(),
    String? type,
    Value<String?> region = const Value.absent(),
    Value<String?> remarks = const Value.absent(),
    DateTime? createdAt,
  }) => Favorite(
    id: id ?? this.id,
    sourceId: sourceId ?? this.sourceId,
    videoId: videoId ?? this.videoId,
    title: title ?? this.title,
    year: year.present ? year.value : this.year,
    coverUrl: coverUrl.present ? coverUrl.value : this.coverUrl,
    rating: rating.present ? rating.value : this.rating,
    type: type ?? this.type,
    region: region.present ? region.value : this.region,
    remarks: remarks.present ? remarks.value : this.remarks,
    createdAt: createdAt ?? this.createdAt,
  );
  Favorite copyWithCompanion(FavoritesCompanion data) {
    return Favorite(
      id: data.id.present ? data.id.value : this.id,
      sourceId: data.sourceId.present ? data.sourceId.value : this.sourceId,
      videoId: data.videoId.present ? data.videoId.value : this.videoId,
      title: data.title.present ? data.title.value : this.title,
      year: data.year.present ? data.year.value : this.year,
      coverUrl: data.coverUrl.present ? data.coverUrl.value : this.coverUrl,
      rating: data.rating.present ? data.rating.value : this.rating,
      type: data.type.present ? data.type.value : this.type,
      region: data.region.present ? data.region.value : this.region,
      remarks: data.remarks.present ? data.remarks.value : this.remarks,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Favorite(')
          ..write('id: $id, ')
          ..write('sourceId: $sourceId, ')
          ..write('videoId: $videoId, ')
          ..write('title: $title, ')
          ..write('year: $year, ')
          ..write('coverUrl: $coverUrl, ')
          ..write('rating: $rating, ')
          ..write('type: $type, ')
          ..write('region: $region, ')
          ..write('remarks: $remarks, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    sourceId,
    videoId,
    title,
    year,
    coverUrl,
    rating,
    type,
    region,
    remarks,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Favorite &&
          other.id == this.id &&
          other.sourceId == this.sourceId &&
          other.videoId == this.videoId &&
          other.title == this.title &&
          other.year == this.year &&
          other.coverUrl == this.coverUrl &&
          other.rating == this.rating &&
          other.type == this.type &&
          other.region == this.region &&
          other.remarks == this.remarks &&
          other.createdAt == this.createdAt);
}

class FavoritesCompanion extends UpdateCompanion<Favorite> {
  final Value<int> id;
  final Value<String> sourceId;
  final Value<int> videoId;
  final Value<String> title;
  final Value<String?> year;
  final Value<String?> coverUrl;
  final Value<String?> rating;
  final Value<String> type;
  final Value<String?> region;
  final Value<String?> remarks;
  final Value<DateTime> createdAt;
  const FavoritesCompanion({
    this.id = const Value.absent(),
    this.sourceId = const Value.absent(),
    this.videoId = const Value.absent(),
    this.title = const Value.absent(),
    this.year = const Value.absent(),
    this.coverUrl = const Value.absent(),
    this.rating = const Value.absent(),
    this.type = const Value.absent(),
    this.region = const Value.absent(),
    this.remarks = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  FavoritesCompanion.insert({
    this.id = const Value.absent(),
    required String sourceId,
    required int videoId,
    required String title,
    this.year = const Value.absent(),
    this.coverUrl = const Value.absent(),
    this.rating = const Value.absent(),
    this.type = const Value.absent(),
    this.region = const Value.absent(),
    this.remarks = const Value.absent(),
    required DateTime createdAt,
  }) : sourceId = Value(sourceId),
       videoId = Value(videoId),
       title = Value(title),
       createdAt = Value(createdAt);
  static Insertable<Favorite> custom({
    Expression<int>? id,
    Expression<String>? sourceId,
    Expression<int>? videoId,
    Expression<String>? title,
    Expression<String>? year,
    Expression<String>? coverUrl,
    Expression<String>? rating,
    Expression<String>? type,
    Expression<String>? region,
    Expression<String>? remarks,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sourceId != null) 'source_id': sourceId,
      if (videoId != null) 'video_id': videoId,
      if (title != null) 'title': title,
      if (year != null) 'year': year,
      if (coverUrl != null) 'cover_url': coverUrl,
      if (rating != null) 'rating': rating,
      if (type != null) 'type': type,
      if (region != null) 'region': region,
      if (remarks != null) 'remarks': remarks,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  FavoritesCompanion copyWith({
    Value<int>? id,
    Value<String>? sourceId,
    Value<int>? videoId,
    Value<String>? title,
    Value<String?>? year,
    Value<String?>? coverUrl,
    Value<String?>? rating,
    Value<String>? type,
    Value<String?>? region,
    Value<String?>? remarks,
    Value<DateTime>? createdAt,
  }) {
    return FavoritesCompanion(
      id: id ?? this.id,
      sourceId: sourceId ?? this.sourceId,
      videoId: videoId ?? this.videoId,
      title: title ?? this.title,
      year: year ?? this.year,
      coverUrl: coverUrl ?? this.coverUrl,
      rating: rating ?? this.rating,
      type: type ?? this.type,
      region: region ?? this.region,
      remarks: remarks ?? this.remarks,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (sourceId.present) {
      map['source_id'] = Variable<String>(sourceId.value);
    }
    if (videoId.present) {
      map['video_id'] = Variable<int>(videoId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (year.present) {
      map['year'] = Variable<String>(year.value);
    }
    if (coverUrl.present) {
      map['cover_url'] = Variable<String>(coverUrl.value);
    }
    if (rating.present) {
      map['rating'] = Variable<String>(rating.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (region.present) {
      map['region'] = Variable<String>(region.value);
    }
    if (remarks.present) {
      map['remarks'] = Variable<String>(remarks.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FavoritesCompanion(')
          ..write('id: $id, ')
          ..write('sourceId: $sourceId, ')
          ..write('videoId: $videoId, ')
          ..write('title: $title, ')
          ..write('year: $year, ')
          ..write('coverUrl: $coverUrl, ')
          ..write('rating: $rating, ')
          ..write('type: $type, ')
          ..write('region: $region, ')
          ..write('remarks: $remarks, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $DownloadTasksTable extends DownloadTasks
    with TableInfo<$DownloadTasksTable, DownloadTask> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DownloadTasksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _taskIdMeta = const VerificationMeta('taskId');
  @override
  late final GeneratedColumn<String> taskId = GeneratedColumn<String>(
    'task_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _videoIdMeta = const VerificationMeta(
    'videoId',
  );
  @override
  late final GeneratedColumn<int> videoId = GeneratedColumn<int>(
    'video_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _videoTitleMeta = const VerificationMeta(
    'videoTitle',
  );
  @override
  late final GeneratedColumn<String> videoTitle = GeneratedColumn<String>(
    'video_title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _coverUrlMeta = const VerificationMeta(
    'coverUrl',
  );
  @override
  late final GeneratedColumn<String> coverUrl = GeneratedColumn<String>(
    'cover_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<List<EpisodeDownloadInfo>, String>
  episodes =
      GeneratedColumn<String>(
        'episodes',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<List<EpisodeDownloadInfo>>(
        $DownloadTasksTable.$converterepisodes,
      );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
    'completed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    taskId,
    videoId,
    videoTitle,
    coverUrl,
    episodes,
    createdAt,
    completedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'download_tasks';
  @override
  VerificationContext validateIntegrity(
    Insertable<DownloadTask> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('task_id')) {
      context.handle(
        _taskIdMeta,
        taskId.isAcceptableOrUnknown(data['task_id']!, _taskIdMeta),
      );
    } else if (isInserting) {
      context.missing(_taskIdMeta);
    }
    if (data.containsKey('video_id')) {
      context.handle(
        _videoIdMeta,
        videoId.isAcceptableOrUnknown(data['video_id']!, _videoIdMeta),
      );
    } else if (isInserting) {
      context.missing(_videoIdMeta);
    }
    if (data.containsKey('video_title')) {
      context.handle(
        _videoTitleMeta,
        videoTitle.isAcceptableOrUnknown(data['video_title']!, _videoTitleMeta),
      );
    } else if (isInserting) {
      context.missing(_videoTitleMeta);
    }
    if (data.containsKey('cover_url')) {
      context.handle(
        _coverUrlMeta,
        coverUrl.isAcceptableOrUnknown(data['cover_url']!, _coverUrlMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DownloadTask map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DownloadTask(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      taskId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}task_id'],
      )!,
      videoId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}video_id'],
      )!,
      videoTitle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}video_title'],
      )!,
      coverUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cover_url'],
      ),
      episodes: $DownloadTasksTable.$converterepisodes.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}episodes'],
        )!,
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}completed_at'],
      ),
    );
  }

  @override
  $DownloadTasksTable createAlias(String alias) {
    return $DownloadTasksTable(attachedDatabase, alias);
  }

  static TypeConverter<List<EpisodeDownloadInfo>, String> $converterepisodes =
      const EpisodeDownloadListConverter();
}

class DownloadTask extends DataClass implements Insertable<DownloadTask> {
  final int id;
  final String taskId;
  final int videoId;
  final String videoTitle;
  final String? coverUrl;
  final List<EpisodeDownloadInfo> episodes;
  final DateTime createdAt;
  final DateTime? completedAt;
  const DownloadTask({
    required this.id,
    required this.taskId,
    required this.videoId,
    required this.videoTitle,
    this.coverUrl,
    required this.episodes,
    required this.createdAt,
    this.completedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['task_id'] = Variable<String>(taskId);
    map['video_id'] = Variable<int>(videoId);
    map['video_title'] = Variable<String>(videoTitle);
    if (!nullToAbsent || coverUrl != null) {
      map['cover_url'] = Variable<String>(coverUrl);
    }
    {
      map['episodes'] = Variable<String>(
        $DownloadTasksTable.$converterepisodes.toSql(episodes),
      );
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<DateTime>(completedAt);
    }
    return map;
  }

  DownloadTasksCompanion toCompanion(bool nullToAbsent) {
    return DownloadTasksCompanion(
      id: Value(id),
      taskId: Value(taskId),
      videoId: Value(videoId),
      videoTitle: Value(videoTitle),
      coverUrl: coverUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(coverUrl),
      episodes: Value(episodes),
      createdAt: Value(createdAt),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
    );
  }

  factory DownloadTask.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DownloadTask(
      id: serializer.fromJson<int>(json['id']),
      taskId: serializer.fromJson<String>(json['taskId']),
      videoId: serializer.fromJson<int>(json['videoId']),
      videoTitle: serializer.fromJson<String>(json['videoTitle']),
      coverUrl: serializer.fromJson<String?>(json['coverUrl']),
      episodes: serializer.fromJson<List<EpisodeDownloadInfo>>(
        json['episodes'],
      ),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      completedAt: serializer.fromJson<DateTime?>(json['completedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'taskId': serializer.toJson<String>(taskId),
      'videoId': serializer.toJson<int>(videoId),
      'videoTitle': serializer.toJson<String>(videoTitle),
      'coverUrl': serializer.toJson<String?>(coverUrl),
      'episodes': serializer.toJson<List<EpisodeDownloadInfo>>(episodes),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'completedAt': serializer.toJson<DateTime?>(completedAt),
    };
  }

  DownloadTask copyWith({
    int? id,
    String? taskId,
    int? videoId,
    String? videoTitle,
    Value<String?> coverUrl = const Value.absent(),
    List<EpisodeDownloadInfo>? episodes,
    DateTime? createdAt,
    Value<DateTime?> completedAt = const Value.absent(),
  }) => DownloadTask(
    id: id ?? this.id,
    taskId: taskId ?? this.taskId,
    videoId: videoId ?? this.videoId,
    videoTitle: videoTitle ?? this.videoTitle,
    coverUrl: coverUrl.present ? coverUrl.value : this.coverUrl,
    episodes: episodes ?? this.episodes,
    createdAt: createdAt ?? this.createdAt,
    completedAt: completedAt.present ? completedAt.value : this.completedAt,
  );
  DownloadTask copyWithCompanion(DownloadTasksCompanion data) {
    return DownloadTask(
      id: data.id.present ? data.id.value : this.id,
      taskId: data.taskId.present ? data.taskId.value : this.taskId,
      videoId: data.videoId.present ? data.videoId.value : this.videoId,
      videoTitle: data.videoTitle.present
          ? data.videoTitle.value
          : this.videoTitle,
      coverUrl: data.coverUrl.present ? data.coverUrl.value : this.coverUrl,
      episodes: data.episodes.present ? data.episodes.value : this.episodes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DownloadTask(')
          ..write('id: $id, ')
          ..write('taskId: $taskId, ')
          ..write('videoId: $videoId, ')
          ..write('videoTitle: $videoTitle, ')
          ..write('coverUrl: $coverUrl, ')
          ..write('episodes: $episodes, ')
          ..write('createdAt: $createdAt, ')
          ..write('completedAt: $completedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    taskId,
    videoId,
    videoTitle,
    coverUrl,
    episodes,
    createdAt,
    completedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DownloadTask &&
          other.id == this.id &&
          other.taskId == this.taskId &&
          other.videoId == this.videoId &&
          other.videoTitle == this.videoTitle &&
          other.coverUrl == this.coverUrl &&
          other.episodes == this.episodes &&
          other.createdAt == this.createdAt &&
          other.completedAt == this.completedAt);
}

class DownloadTasksCompanion extends UpdateCompanion<DownloadTask> {
  final Value<int> id;
  final Value<String> taskId;
  final Value<int> videoId;
  final Value<String> videoTitle;
  final Value<String?> coverUrl;
  final Value<List<EpisodeDownloadInfo>> episodes;
  final Value<DateTime> createdAt;
  final Value<DateTime?> completedAt;
  const DownloadTasksCompanion({
    this.id = const Value.absent(),
    this.taskId = const Value.absent(),
    this.videoId = const Value.absent(),
    this.videoTitle = const Value.absent(),
    this.coverUrl = const Value.absent(),
    this.episodes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.completedAt = const Value.absent(),
  });
  DownloadTasksCompanion.insert({
    this.id = const Value.absent(),
    required String taskId,
    required int videoId,
    required String videoTitle,
    this.coverUrl = const Value.absent(),
    required List<EpisodeDownloadInfo> episodes,
    required DateTime createdAt,
    this.completedAt = const Value.absent(),
  }) : taskId = Value(taskId),
       videoId = Value(videoId),
       videoTitle = Value(videoTitle),
       episodes = Value(episodes),
       createdAt = Value(createdAt);
  static Insertable<DownloadTask> custom({
    Expression<int>? id,
    Expression<String>? taskId,
    Expression<int>? videoId,
    Expression<String>? videoTitle,
    Expression<String>? coverUrl,
    Expression<String>? episodes,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? completedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (taskId != null) 'task_id': taskId,
      if (videoId != null) 'video_id': videoId,
      if (videoTitle != null) 'video_title': videoTitle,
      if (coverUrl != null) 'cover_url': coverUrl,
      if (episodes != null) 'episodes': episodes,
      if (createdAt != null) 'created_at': createdAt,
      if (completedAt != null) 'completed_at': completedAt,
    });
  }

  DownloadTasksCompanion copyWith({
    Value<int>? id,
    Value<String>? taskId,
    Value<int>? videoId,
    Value<String>? videoTitle,
    Value<String?>? coverUrl,
    Value<List<EpisodeDownloadInfo>>? episodes,
    Value<DateTime>? createdAt,
    Value<DateTime?>? completedAt,
  }) {
    return DownloadTasksCompanion(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      videoId: videoId ?? this.videoId,
      videoTitle: videoTitle ?? this.videoTitle,
      coverUrl: coverUrl ?? this.coverUrl,
      episodes: episodes ?? this.episodes,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (taskId.present) {
      map['task_id'] = Variable<String>(taskId.value);
    }
    if (videoId.present) {
      map['video_id'] = Variable<int>(videoId.value);
    }
    if (videoTitle.present) {
      map['video_title'] = Variable<String>(videoTitle.value);
    }
    if (coverUrl.present) {
      map['cover_url'] = Variable<String>(coverUrl.value);
    }
    if (episodes.present) {
      map['episodes'] = Variable<String>(
        $DownloadTasksTable.$converterepisodes.toSql(episodes.value),
      );
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DownloadTasksCompanion(')
          ..write('id: $id, ')
          ..write('taskId: $taskId, ')
          ..write('videoId: $videoId, ')
          ..write('videoTitle: $videoTitle, ')
          ..write('coverUrl: $coverUrl, ')
          ..write('episodes: $episodes, ')
          ..write('createdAt: $createdAt, ')
          ..write('completedAt: $completedAt')
          ..write(')'))
        .toString();
  }
}

class $AppSettingsTable extends AppSettings
    with TableInfo<$AppSettingsTable, AppSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _downloadPathMeta = const VerificationMeta(
    'downloadPath',
  );
  @override
  late final GeneratedColumn<String> downloadPath = GeneratedColumn<String>(
    'download_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _enableThumbnailPreviewMeta =
      const VerificationMeta('enableThumbnailPreview');
  @override
  late final GeneratedColumn<bool> enableThumbnailPreview =
      GeneratedColumn<bool>(
        'enable_thumbnail_preview',
        aliasedName,
        false,
        type: DriftSqlType.bool,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("enable_thumbnail_preview" IN (0, 1))',
        ),
        defaultValue: const Constant(false),
      );
  static const VerificationMeta _maxConcurrentDownloadsMeta =
      const VerificationMeta('maxConcurrentDownloads');
  @override
  late final GeneratedColumn<int> maxConcurrentDownloads = GeneratedColumn<int>(
    'max_concurrent_downloads',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(3),
  );
  static const VerificationMeta _segmentConcurrencyMeta =
      const VerificationMeta('segmentConcurrency');
  @override
  late final GeneratedColumn<int> segmentConcurrency = GeneratedColumn<int>(
    'segment_concurrency',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(6),
  );
  static const VerificationMeta _lastDataSourceIdMeta = const VerificationMeta(
    'lastDataSourceId',
  );
  @override
  late final GeneratedColumn<String> lastDataSourceId = GeneratedColumn<String>(
    'last_data_source_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cookieFileMeta = const VerificationMeta(
    'cookieFile',
  );
  @override
  late final GeneratedColumn<String> cookieFile = GeneratedColumn<String>(
    'cookie_file',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _themeModeMeta = const VerificationMeta(
    'themeMode',
  );
  @override
  late final GeneratedColumn<int> themeMode = GeneratedColumn<int>(
    'theme_mode',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _subscriptionCheckedAtMeta =
      const VerificationMeta('subscriptionCheckedAt');
  @override
  late final GeneratedColumn<DateTime> subscriptionCheckedAt =
      GeneratedColumn<DateTime>(
        'subscription_checked_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _playerNormalWidthMeta = const VerificationMeta(
    'playerNormalWidth',
  );
  @override
  late final GeneratedColumn<double> playerNormalWidth =
      GeneratedColumn<double>(
        'player_normal_width',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _playerNormalHeightMeta =
      const VerificationMeta('playerNormalHeight');
  @override
  late final GeneratedColumn<double> playerNormalHeight =
      GeneratedColumn<double>(
        'player_normal_height',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _playerPipWidthMeta = const VerificationMeta(
    'playerPipWidth',
  );
  @override
  late final GeneratedColumn<double> playerPipWidth = GeneratedColumn<double>(
    'player_pip_width',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _playerPipHeightMeta = const VerificationMeta(
    'playerPipHeight',
  );
  @override
  late final GeneratedColumn<double> playerPipHeight = GeneratedColumn<double>(
    'player_pip_height',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _playerWindowXMeta = const VerificationMeta(
    'playerWindowX',
  );
  @override
  late final GeneratedColumn<double> playerWindowX = GeneratedColumn<double>(
    'player_window_x',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _playerWindowYMeta = const VerificationMeta(
    'playerWindowY',
  );
  @override
  late final GeneratedColumn<double> playerWindowY = GeneratedColumn<double>(
    'player_window_y',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _playerPipXMeta = const VerificationMeta(
    'playerPipX',
  );
  @override
  late final GeneratedColumn<double> playerPipX = GeneratedColumn<double>(
    'player_pip_x',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _playerPipYMeta = const VerificationMeta(
    'playerPipY',
  );
  @override
  late final GeneratedColumn<double> playerPipY = GeneratedColumn<double>(
    'player_pip_y',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _localeMeta = const VerificationMeta('locale');
  @override
  late final GeneratedColumn<String> locale = GeneratedColumn<String>(
    'locale',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _searchHistoryMeta = const VerificationMeta(
    'searchHistory',
  );
  @override
  late final GeneratedColumn<String> searchHistory = GeneratedColumn<String>(
    'search_history',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _showPetMeta = const VerificationMeta(
    'showPet',
  );
  @override
  late final GeneratedColumn<bool> showPet = GeneratedColumn<bool>(
    'show_pet',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("show_pet" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _petWindowXMeta = const VerificationMeta(
    'petWindowX',
  );
  @override
  late final GeneratedColumn<double> petWindowX = GeneratedColumn<double>(
    'pet_window_x',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _petWindowYMeta = const VerificationMeta(
    'petWindowY',
  );
  @override
  late final GeneratedColumn<double> petWindowY = GeneratedColumn<double>(
    'pet_window_y',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    downloadPath,
    enableThumbnailPreview,
    maxConcurrentDownloads,
    segmentConcurrency,
    lastDataSourceId,
    cookieFile,
    themeMode,
    subscriptionCheckedAt,
    playerNormalWidth,
    playerNormalHeight,
    playerPipWidth,
    playerPipHeight,
    playerWindowX,
    playerWindowY,
    playerPipX,
    playerPipY,
    locale,
    searchHistory,
    showPet,
    petWindowX,
    petWindowY,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppSetting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('download_path')) {
      context.handle(
        _downloadPathMeta,
        downloadPath.isAcceptableOrUnknown(
          data['download_path']!,
          _downloadPathMeta,
        ),
      );
    }
    if (data.containsKey('enable_thumbnail_preview')) {
      context.handle(
        _enableThumbnailPreviewMeta,
        enableThumbnailPreview.isAcceptableOrUnknown(
          data['enable_thumbnail_preview']!,
          _enableThumbnailPreviewMeta,
        ),
      );
    }
    if (data.containsKey('max_concurrent_downloads')) {
      context.handle(
        _maxConcurrentDownloadsMeta,
        maxConcurrentDownloads.isAcceptableOrUnknown(
          data['max_concurrent_downloads']!,
          _maxConcurrentDownloadsMeta,
        ),
      );
    }
    if (data.containsKey('segment_concurrency')) {
      context.handle(
        _segmentConcurrencyMeta,
        segmentConcurrency.isAcceptableOrUnknown(
          data['segment_concurrency']!,
          _segmentConcurrencyMeta,
        ),
      );
    }
    if (data.containsKey('last_data_source_id')) {
      context.handle(
        _lastDataSourceIdMeta,
        lastDataSourceId.isAcceptableOrUnknown(
          data['last_data_source_id']!,
          _lastDataSourceIdMeta,
        ),
      );
    }
    if (data.containsKey('cookie_file')) {
      context.handle(
        _cookieFileMeta,
        cookieFile.isAcceptableOrUnknown(data['cookie_file']!, _cookieFileMeta),
      );
    }
    if (data.containsKey('theme_mode')) {
      context.handle(
        _themeModeMeta,
        themeMode.isAcceptableOrUnknown(data['theme_mode']!, _themeModeMeta),
      );
    }
    if (data.containsKey('subscription_checked_at')) {
      context.handle(
        _subscriptionCheckedAtMeta,
        subscriptionCheckedAt.isAcceptableOrUnknown(
          data['subscription_checked_at']!,
          _subscriptionCheckedAtMeta,
        ),
      );
    }
    if (data.containsKey('player_normal_width')) {
      context.handle(
        _playerNormalWidthMeta,
        playerNormalWidth.isAcceptableOrUnknown(
          data['player_normal_width']!,
          _playerNormalWidthMeta,
        ),
      );
    }
    if (data.containsKey('player_normal_height')) {
      context.handle(
        _playerNormalHeightMeta,
        playerNormalHeight.isAcceptableOrUnknown(
          data['player_normal_height']!,
          _playerNormalHeightMeta,
        ),
      );
    }
    if (data.containsKey('player_pip_width')) {
      context.handle(
        _playerPipWidthMeta,
        playerPipWidth.isAcceptableOrUnknown(
          data['player_pip_width']!,
          _playerPipWidthMeta,
        ),
      );
    }
    if (data.containsKey('player_pip_height')) {
      context.handle(
        _playerPipHeightMeta,
        playerPipHeight.isAcceptableOrUnknown(
          data['player_pip_height']!,
          _playerPipHeightMeta,
        ),
      );
    }
    if (data.containsKey('player_window_x')) {
      context.handle(
        _playerWindowXMeta,
        playerWindowX.isAcceptableOrUnknown(
          data['player_window_x']!,
          _playerWindowXMeta,
        ),
      );
    }
    if (data.containsKey('player_window_y')) {
      context.handle(
        _playerWindowYMeta,
        playerWindowY.isAcceptableOrUnknown(
          data['player_window_y']!,
          _playerWindowYMeta,
        ),
      );
    }
    if (data.containsKey('player_pip_x')) {
      context.handle(
        _playerPipXMeta,
        playerPipX.isAcceptableOrUnknown(
          data['player_pip_x']!,
          _playerPipXMeta,
        ),
      );
    }
    if (data.containsKey('player_pip_y')) {
      context.handle(
        _playerPipYMeta,
        playerPipY.isAcceptableOrUnknown(
          data['player_pip_y']!,
          _playerPipYMeta,
        ),
      );
    }
    if (data.containsKey('locale')) {
      context.handle(
        _localeMeta,
        locale.isAcceptableOrUnknown(data['locale']!, _localeMeta),
      );
    }
    if (data.containsKey('search_history')) {
      context.handle(
        _searchHistoryMeta,
        searchHistory.isAcceptableOrUnknown(
          data['search_history']!,
          _searchHistoryMeta,
        ),
      );
    }
    if (data.containsKey('show_pet')) {
      context.handle(
        _showPetMeta,
        showPet.isAcceptableOrUnknown(data['show_pet']!, _showPetMeta),
      );
    }
    if (data.containsKey('pet_window_x')) {
      context.handle(
        _petWindowXMeta,
        petWindowX.isAcceptableOrUnknown(
          data['pet_window_x']!,
          _petWindowXMeta,
        ),
      );
    }
    if (data.containsKey('pet_window_y')) {
      context.handle(
        _petWindowYMeta,
        petWindowY.isAcceptableOrUnknown(
          data['pet_window_y']!,
          _petWindowYMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AppSetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppSetting(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      downloadPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}download_path'],
      ),
      enableThumbnailPreview: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}enable_thumbnail_preview'],
      )!,
      maxConcurrentDownloads: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}max_concurrent_downloads'],
      )!,
      segmentConcurrency: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}segment_concurrency'],
      )!,
      lastDataSourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_data_source_id'],
      ),
      cookieFile: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cookie_file'],
      ),
      themeMode: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}theme_mode'],
      )!,
      subscriptionCheckedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}subscription_checked_at'],
      ),
      playerNormalWidth: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}player_normal_width'],
      ),
      playerNormalHeight: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}player_normal_height'],
      ),
      playerPipWidth: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}player_pip_width'],
      ),
      playerPipHeight: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}player_pip_height'],
      ),
      playerWindowX: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}player_window_x'],
      ),
      playerWindowY: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}player_window_y'],
      ),
      playerPipX: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}player_pip_x'],
      ),
      playerPipY: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}player_pip_y'],
      ),
      locale: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}locale'],
      ),
      searchHistory: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}search_history'],
      ),
      showPet: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}show_pet'],
      )!,
      petWindowX: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}pet_window_x'],
      ),
      petWindowY: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}pet_window_y'],
      ),
    );
  }

  @override
  $AppSettingsTable createAlias(String alias) {
    return $AppSettingsTable(attachedDatabase, alias);
  }
}

class AppSetting extends DataClass implements Insertable<AppSetting> {
  final int id;
  final String? downloadPath;
  final bool enableThumbnailPreview;
  final int maxConcurrentDownloads;
  final int segmentConcurrency;
  final String? lastDataSourceId;
  final String? cookieFile;
  final int themeMode;

  /// When the subscription checker last ran. Persisted because the 20-minute
  /// floor lived only in memory, so the one habit desktop users actually have
  /// — closing and reopening the app — reset it and swept every launch.
  final DateTime? subscriptionCheckedAt;
  final double? playerNormalWidth;
  final double? playerNormalHeight;
  final double? playerPipWidth;
  final double? playerPipHeight;

  /// Last top-left of the player window in NORMAL mode. Size alone cannot
  /// restore "where I left it" — and window MOVES emit no metric events,
  /// so these are captured at close/pip-enter snapshots, not on resize.
  final double? playerWindowX;
  final double? playerWindowY;

  /// Same for PIP mode: where the user parked the mini window. Without it
  /// every pip entry flies to the bottom-right default, discarding the
  /// user's chosen corner.
  final double? playerPipX;
  final double? playerPipY;
  final String? locale;

  /// Recent search keywords, JSON array, newest first and capped — see
  /// SearchHistoryNotifier. A column rather than a table: it is one small
  /// ordered list with no queries against it.
  final String? searchHistory;

  /// Whether the desktop pet window comes up with the app. Off by default:
  /// an always-on-top window that appears uninvited on first launch is a
  /// thing to close, not a thing to like.
  final bool showPet;

  /// Where the user parked the pet: its window's BOTTOM-RIGHT corner. The
  /// anchor rather than the top-left because the window changes size while
  /// the pet speaks, and only the bottom-right corner survives that.
  final double? petWindowX;
  final double? petWindowY;
  const AppSetting({
    required this.id,
    this.downloadPath,
    required this.enableThumbnailPreview,
    required this.maxConcurrentDownloads,
    required this.segmentConcurrency,
    this.lastDataSourceId,
    this.cookieFile,
    required this.themeMode,
    this.subscriptionCheckedAt,
    this.playerNormalWidth,
    this.playerNormalHeight,
    this.playerPipWidth,
    this.playerPipHeight,
    this.playerWindowX,
    this.playerWindowY,
    this.playerPipX,
    this.playerPipY,
    this.locale,
    this.searchHistory,
    required this.showPet,
    this.petWindowX,
    this.petWindowY,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || downloadPath != null) {
      map['download_path'] = Variable<String>(downloadPath);
    }
    map['enable_thumbnail_preview'] = Variable<bool>(enableThumbnailPreview);
    map['max_concurrent_downloads'] = Variable<int>(maxConcurrentDownloads);
    map['segment_concurrency'] = Variable<int>(segmentConcurrency);
    if (!nullToAbsent || lastDataSourceId != null) {
      map['last_data_source_id'] = Variable<String>(lastDataSourceId);
    }
    if (!nullToAbsent || cookieFile != null) {
      map['cookie_file'] = Variable<String>(cookieFile);
    }
    map['theme_mode'] = Variable<int>(themeMode);
    if (!nullToAbsent || subscriptionCheckedAt != null) {
      map['subscription_checked_at'] = Variable<DateTime>(
        subscriptionCheckedAt,
      );
    }
    if (!nullToAbsent || playerNormalWidth != null) {
      map['player_normal_width'] = Variable<double>(playerNormalWidth);
    }
    if (!nullToAbsent || playerNormalHeight != null) {
      map['player_normal_height'] = Variable<double>(playerNormalHeight);
    }
    if (!nullToAbsent || playerPipWidth != null) {
      map['player_pip_width'] = Variable<double>(playerPipWidth);
    }
    if (!nullToAbsent || playerPipHeight != null) {
      map['player_pip_height'] = Variable<double>(playerPipHeight);
    }
    if (!nullToAbsent || playerWindowX != null) {
      map['player_window_x'] = Variable<double>(playerWindowX);
    }
    if (!nullToAbsent || playerWindowY != null) {
      map['player_window_y'] = Variable<double>(playerWindowY);
    }
    if (!nullToAbsent || playerPipX != null) {
      map['player_pip_x'] = Variable<double>(playerPipX);
    }
    if (!nullToAbsent || playerPipY != null) {
      map['player_pip_y'] = Variable<double>(playerPipY);
    }
    if (!nullToAbsent || locale != null) {
      map['locale'] = Variable<String>(locale);
    }
    if (!nullToAbsent || searchHistory != null) {
      map['search_history'] = Variable<String>(searchHistory);
    }
    map['show_pet'] = Variable<bool>(showPet);
    if (!nullToAbsent || petWindowX != null) {
      map['pet_window_x'] = Variable<double>(petWindowX);
    }
    if (!nullToAbsent || petWindowY != null) {
      map['pet_window_y'] = Variable<double>(petWindowY);
    }
    return map;
  }

  AppSettingsCompanion toCompanion(bool nullToAbsent) {
    return AppSettingsCompanion(
      id: Value(id),
      downloadPath: downloadPath == null && nullToAbsent
          ? const Value.absent()
          : Value(downloadPath),
      enableThumbnailPreview: Value(enableThumbnailPreview),
      maxConcurrentDownloads: Value(maxConcurrentDownloads),
      segmentConcurrency: Value(segmentConcurrency),
      lastDataSourceId: lastDataSourceId == null && nullToAbsent
          ? const Value.absent()
          : Value(lastDataSourceId),
      cookieFile: cookieFile == null && nullToAbsent
          ? const Value.absent()
          : Value(cookieFile),
      themeMode: Value(themeMode),
      subscriptionCheckedAt: subscriptionCheckedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(subscriptionCheckedAt),
      playerNormalWidth: playerNormalWidth == null && nullToAbsent
          ? const Value.absent()
          : Value(playerNormalWidth),
      playerNormalHeight: playerNormalHeight == null && nullToAbsent
          ? const Value.absent()
          : Value(playerNormalHeight),
      playerPipWidth: playerPipWidth == null && nullToAbsent
          ? const Value.absent()
          : Value(playerPipWidth),
      playerPipHeight: playerPipHeight == null && nullToAbsent
          ? const Value.absent()
          : Value(playerPipHeight),
      playerWindowX: playerWindowX == null && nullToAbsent
          ? const Value.absent()
          : Value(playerWindowX),
      playerWindowY: playerWindowY == null && nullToAbsent
          ? const Value.absent()
          : Value(playerWindowY),
      playerPipX: playerPipX == null && nullToAbsent
          ? const Value.absent()
          : Value(playerPipX),
      playerPipY: playerPipY == null && nullToAbsent
          ? const Value.absent()
          : Value(playerPipY),
      locale: locale == null && nullToAbsent
          ? const Value.absent()
          : Value(locale),
      searchHistory: searchHistory == null && nullToAbsent
          ? const Value.absent()
          : Value(searchHistory),
      showPet: Value(showPet),
      petWindowX: petWindowX == null && nullToAbsent
          ? const Value.absent()
          : Value(petWindowX),
      petWindowY: petWindowY == null && nullToAbsent
          ? const Value.absent()
          : Value(petWindowY),
    );
  }

  factory AppSetting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppSetting(
      id: serializer.fromJson<int>(json['id']),
      downloadPath: serializer.fromJson<String?>(json['downloadPath']),
      enableThumbnailPreview: serializer.fromJson<bool>(
        json['enableThumbnailPreview'],
      ),
      maxConcurrentDownloads: serializer.fromJson<int>(
        json['maxConcurrentDownloads'],
      ),
      segmentConcurrency: serializer.fromJson<int>(json['segmentConcurrency']),
      lastDataSourceId: serializer.fromJson<String?>(json['lastDataSourceId']),
      cookieFile: serializer.fromJson<String?>(json['cookieFile']),
      themeMode: serializer.fromJson<int>(json['themeMode']),
      subscriptionCheckedAt: serializer.fromJson<DateTime?>(
        json['subscriptionCheckedAt'],
      ),
      playerNormalWidth: serializer.fromJson<double?>(
        json['playerNormalWidth'],
      ),
      playerNormalHeight: serializer.fromJson<double?>(
        json['playerNormalHeight'],
      ),
      playerPipWidth: serializer.fromJson<double?>(json['playerPipWidth']),
      playerPipHeight: serializer.fromJson<double?>(json['playerPipHeight']),
      playerWindowX: serializer.fromJson<double?>(json['playerWindowX']),
      playerWindowY: serializer.fromJson<double?>(json['playerWindowY']),
      playerPipX: serializer.fromJson<double?>(json['playerPipX']),
      playerPipY: serializer.fromJson<double?>(json['playerPipY']),
      locale: serializer.fromJson<String?>(json['locale']),
      searchHistory: serializer.fromJson<String?>(json['searchHistory']),
      showPet: serializer.fromJson<bool>(json['showPet']),
      petWindowX: serializer.fromJson<double?>(json['petWindowX']),
      petWindowY: serializer.fromJson<double?>(json['petWindowY']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'downloadPath': serializer.toJson<String?>(downloadPath),
      'enableThumbnailPreview': serializer.toJson<bool>(enableThumbnailPreview),
      'maxConcurrentDownloads': serializer.toJson<int>(maxConcurrentDownloads),
      'segmentConcurrency': serializer.toJson<int>(segmentConcurrency),
      'lastDataSourceId': serializer.toJson<String?>(lastDataSourceId),
      'cookieFile': serializer.toJson<String?>(cookieFile),
      'themeMode': serializer.toJson<int>(themeMode),
      'subscriptionCheckedAt': serializer.toJson<DateTime?>(
        subscriptionCheckedAt,
      ),
      'playerNormalWidth': serializer.toJson<double?>(playerNormalWidth),
      'playerNormalHeight': serializer.toJson<double?>(playerNormalHeight),
      'playerPipWidth': serializer.toJson<double?>(playerPipWidth),
      'playerPipHeight': serializer.toJson<double?>(playerPipHeight),
      'playerWindowX': serializer.toJson<double?>(playerWindowX),
      'playerWindowY': serializer.toJson<double?>(playerWindowY),
      'playerPipX': serializer.toJson<double?>(playerPipX),
      'playerPipY': serializer.toJson<double?>(playerPipY),
      'locale': serializer.toJson<String?>(locale),
      'searchHistory': serializer.toJson<String?>(searchHistory),
      'showPet': serializer.toJson<bool>(showPet),
      'petWindowX': serializer.toJson<double?>(petWindowX),
      'petWindowY': serializer.toJson<double?>(petWindowY),
    };
  }

  AppSetting copyWith({
    int? id,
    Value<String?> downloadPath = const Value.absent(),
    bool? enableThumbnailPreview,
    int? maxConcurrentDownloads,
    int? segmentConcurrency,
    Value<String?> lastDataSourceId = const Value.absent(),
    Value<String?> cookieFile = const Value.absent(),
    int? themeMode,
    Value<DateTime?> subscriptionCheckedAt = const Value.absent(),
    Value<double?> playerNormalWidth = const Value.absent(),
    Value<double?> playerNormalHeight = const Value.absent(),
    Value<double?> playerPipWidth = const Value.absent(),
    Value<double?> playerPipHeight = const Value.absent(),
    Value<double?> playerWindowX = const Value.absent(),
    Value<double?> playerWindowY = const Value.absent(),
    Value<double?> playerPipX = const Value.absent(),
    Value<double?> playerPipY = const Value.absent(),
    Value<String?> locale = const Value.absent(),
    Value<String?> searchHistory = const Value.absent(),
    bool? showPet,
    Value<double?> petWindowX = const Value.absent(),
    Value<double?> petWindowY = const Value.absent(),
  }) => AppSetting(
    id: id ?? this.id,
    downloadPath: downloadPath.present ? downloadPath.value : this.downloadPath,
    enableThumbnailPreview:
        enableThumbnailPreview ?? this.enableThumbnailPreview,
    maxConcurrentDownloads:
        maxConcurrentDownloads ?? this.maxConcurrentDownloads,
    segmentConcurrency: segmentConcurrency ?? this.segmentConcurrency,
    lastDataSourceId: lastDataSourceId.present
        ? lastDataSourceId.value
        : this.lastDataSourceId,
    cookieFile: cookieFile.present ? cookieFile.value : this.cookieFile,
    themeMode: themeMode ?? this.themeMode,
    subscriptionCheckedAt: subscriptionCheckedAt.present
        ? subscriptionCheckedAt.value
        : this.subscriptionCheckedAt,
    playerNormalWidth: playerNormalWidth.present
        ? playerNormalWidth.value
        : this.playerNormalWidth,
    playerNormalHeight: playerNormalHeight.present
        ? playerNormalHeight.value
        : this.playerNormalHeight,
    playerPipWidth: playerPipWidth.present
        ? playerPipWidth.value
        : this.playerPipWidth,
    playerPipHeight: playerPipHeight.present
        ? playerPipHeight.value
        : this.playerPipHeight,
    playerWindowX: playerWindowX.present
        ? playerWindowX.value
        : this.playerWindowX,
    playerWindowY: playerWindowY.present
        ? playerWindowY.value
        : this.playerWindowY,
    playerPipX: playerPipX.present ? playerPipX.value : this.playerPipX,
    playerPipY: playerPipY.present ? playerPipY.value : this.playerPipY,
    locale: locale.present ? locale.value : this.locale,
    searchHistory: searchHistory.present
        ? searchHistory.value
        : this.searchHistory,
    showPet: showPet ?? this.showPet,
    petWindowX: petWindowX.present ? petWindowX.value : this.petWindowX,
    petWindowY: petWindowY.present ? petWindowY.value : this.petWindowY,
  );
  AppSetting copyWithCompanion(AppSettingsCompanion data) {
    return AppSetting(
      id: data.id.present ? data.id.value : this.id,
      downloadPath: data.downloadPath.present
          ? data.downloadPath.value
          : this.downloadPath,
      enableThumbnailPreview: data.enableThumbnailPreview.present
          ? data.enableThumbnailPreview.value
          : this.enableThumbnailPreview,
      maxConcurrentDownloads: data.maxConcurrentDownloads.present
          ? data.maxConcurrentDownloads.value
          : this.maxConcurrentDownloads,
      segmentConcurrency: data.segmentConcurrency.present
          ? data.segmentConcurrency.value
          : this.segmentConcurrency,
      lastDataSourceId: data.lastDataSourceId.present
          ? data.lastDataSourceId.value
          : this.lastDataSourceId,
      cookieFile: data.cookieFile.present
          ? data.cookieFile.value
          : this.cookieFile,
      themeMode: data.themeMode.present ? data.themeMode.value : this.themeMode,
      subscriptionCheckedAt: data.subscriptionCheckedAt.present
          ? data.subscriptionCheckedAt.value
          : this.subscriptionCheckedAt,
      playerNormalWidth: data.playerNormalWidth.present
          ? data.playerNormalWidth.value
          : this.playerNormalWidth,
      playerNormalHeight: data.playerNormalHeight.present
          ? data.playerNormalHeight.value
          : this.playerNormalHeight,
      playerPipWidth: data.playerPipWidth.present
          ? data.playerPipWidth.value
          : this.playerPipWidth,
      playerPipHeight: data.playerPipHeight.present
          ? data.playerPipHeight.value
          : this.playerPipHeight,
      playerWindowX: data.playerWindowX.present
          ? data.playerWindowX.value
          : this.playerWindowX,
      playerWindowY: data.playerWindowY.present
          ? data.playerWindowY.value
          : this.playerWindowY,
      playerPipX: data.playerPipX.present
          ? data.playerPipX.value
          : this.playerPipX,
      playerPipY: data.playerPipY.present
          ? data.playerPipY.value
          : this.playerPipY,
      locale: data.locale.present ? data.locale.value : this.locale,
      searchHistory: data.searchHistory.present
          ? data.searchHistory.value
          : this.searchHistory,
      showPet: data.showPet.present ? data.showPet.value : this.showPet,
      petWindowX: data.petWindowX.present
          ? data.petWindowX.value
          : this.petWindowX,
      petWindowY: data.petWindowY.present
          ? data.petWindowY.value
          : this.petWindowY,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppSetting(')
          ..write('id: $id, ')
          ..write('downloadPath: $downloadPath, ')
          ..write('enableThumbnailPreview: $enableThumbnailPreview, ')
          ..write('maxConcurrentDownloads: $maxConcurrentDownloads, ')
          ..write('segmentConcurrency: $segmentConcurrency, ')
          ..write('lastDataSourceId: $lastDataSourceId, ')
          ..write('cookieFile: $cookieFile, ')
          ..write('themeMode: $themeMode, ')
          ..write('subscriptionCheckedAt: $subscriptionCheckedAt, ')
          ..write('playerNormalWidth: $playerNormalWidth, ')
          ..write('playerNormalHeight: $playerNormalHeight, ')
          ..write('playerPipWidth: $playerPipWidth, ')
          ..write('playerPipHeight: $playerPipHeight, ')
          ..write('playerWindowX: $playerWindowX, ')
          ..write('playerWindowY: $playerWindowY, ')
          ..write('playerPipX: $playerPipX, ')
          ..write('playerPipY: $playerPipY, ')
          ..write('locale: $locale, ')
          ..write('searchHistory: $searchHistory, ')
          ..write('showPet: $showPet, ')
          ..write('petWindowX: $petWindowX, ')
          ..write('petWindowY: $petWindowY')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    downloadPath,
    enableThumbnailPreview,
    maxConcurrentDownloads,
    segmentConcurrency,
    lastDataSourceId,
    cookieFile,
    themeMode,
    subscriptionCheckedAt,
    playerNormalWidth,
    playerNormalHeight,
    playerPipWidth,
    playerPipHeight,
    playerWindowX,
    playerWindowY,
    playerPipX,
    playerPipY,
    locale,
    searchHistory,
    showPet,
    petWindowX,
    petWindowY,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppSetting &&
          other.id == this.id &&
          other.downloadPath == this.downloadPath &&
          other.enableThumbnailPreview == this.enableThumbnailPreview &&
          other.maxConcurrentDownloads == this.maxConcurrentDownloads &&
          other.segmentConcurrency == this.segmentConcurrency &&
          other.lastDataSourceId == this.lastDataSourceId &&
          other.cookieFile == this.cookieFile &&
          other.themeMode == this.themeMode &&
          other.subscriptionCheckedAt == this.subscriptionCheckedAt &&
          other.playerNormalWidth == this.playerNormalWidth &&
          other.playerNormalHeight == this.playerNormalHeight &&
          other.playerPipWidth == this.playerPipWidth &&
          other.playerPipHeight == this.playerPipHeight &&
          other.playerWindowX == this.playerWindowX &&
          other.playerWindowY == this.playerWindowY &&
          other.playerPipX == this.playerPipX &&
          other.playerPipY == this.playerPipY &&
          other.locale == this.locale &&
          other.searchHistory == this.searchHistory &&
          other.showPet == this.showPet &&
          other.petWindowX == this.petWindowX &&
          other.petWindowY == this.petWindowY);
}

class AppSettingsCompanion extends UpdateCompanion<AppSetting> {
  final Value<int> id;
  final Value<String?> downloadPath;
  final Value<bool> enableThumbnailPreview;
  final Value<int> maxConcurrentDownloads;
  final Value<int> segmentConcurrency;
  final Value<String?> lastDataSourceId;
  final Value<String?> cookieFile;
  final Value<int> themeMode;
  final Value<DateTime?> subscriptionCheckedAt;
  final Value<double?> playerNormalWidth;
  final Value<double?> playerNormalHeight;
  final Value<double?> playerPipWidth;
  final Value<double?> playerPipHeight;
  final Value<double?> playerWindowX;
  final Value<double?> playerWindowY;
  final Value<double?> playerPipX;
  final Value<double?> playerPipY;
  final Value<String?> locale;
  final Value<String?> searchHistory;
  final Value<bool> showPet;
  final Value<double?> petWindowX;
  final Value<double?> petWindowY;
  const AppSettingsCompanion({
    this.id = const Value.absent(),
    this.downloadPath = const Value.absent(),
    this.enableThumbnailPreview = const Value.absent(),
    this.maxConcurrentDownloads = const Value.absent(),
    this.segmentConcurrency = const Value.absent(),
    this.lastDataSourceId = const Value.absent(),
    this.cookieFile = const Value.absent(),
    this.themeMode = const Value.absent(),
    this.subscriptionCheckedAt = const Value.absent(),
    this.playerNormalWidth = const Value.absent(),
    this.playerNormalHeight = const Value.absent(),
    this.playerPipWidth = const Value.absent(),
    this.playerPipHeight = const Value.absent(),
    this.playerWindowX = const Value.absent(),
    this.playerWindowY = const Value.absent(),
    this.playerPipX = const Value.absent(),
    this.playerPipY = const Value.absent(),
    this.locale = const Value.absent(),
    this.searchHistory = const Value.absent(),
    this.showPet = const Value.absent(),
    this.petWindowX = const Value.absent(),
    this.petWindowY = const Value.absent(),
  });
  AppSettingsCompanion.insert({
    this.id = const Value.absent(),
    this.downloadPath = const Value.absent(),
    this.enableThumbnailPreview = const Value.absent(),
    this.maxConcurrentDownloads = const Value.absent(),
    this.segmentConcurrency = const Value.absent(),
    this.lastDataSourceId = const Value.absent(),
    this.cookieFile = const Value.absent(),
    this.themeMode = const Value.absent(),
    this.subscriptionCheckedAt = const Value.absent(),
    this.playerNormalWidth = const Value.absent(),
    this.playerNormalHeight = const Value.absent(),
    this.playerPipWidth = const Value.absent(),
    this.playerPipHeight = const Value.absent(),
    this.playerWindowX = const Value.absent(),
    this.playerWindowY = const Value.absent(),
    this.playerPipX = const Value.absent(),
    this.playerPipY = const Value.absent(),
    this.locale = const Value.absent(),
    this.searchHistory = const Value.absent(),
    this.showPet = const Value.absent(),
    this.petWindowX = const Value.absent(),
    this.petWindowY = const Value.absent(),
  });
  static Insertable<AppSetting> custom({
    Expression<int>? id,
    Expression<String>? downloadPath,
    Expression<bool>? enableThumbnailPreview,
    Expression<int>? maxConcurrentDownloads,
    Expression<int>? segmentConcurrency,
    Expression<String>? lastDataSourceId,
    Expression<String>? cookieFile,
    Expression<int>? themeMode,
    Expression<DateTime>? subscriptionCheckedAt,
    Expression<double>? playerNormalWidth,
    Expression<double>? playerNormalHeight,
    Expression<double>? playerPipWidth,
    Expression<double>? playerPipHeight,
    Expression<double>? playerWindowX,
    Expression<double>? playerWindowY,
    Expression<double>? playerPipX,
    Expression<double>? playerPipY,
    Expression<String>? locale,
    Expression<String>? searchHistory,
    Expression<bool>? showPet,
    Expression<double>? petWindowX,
    Expression<double>? petWindowY,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (downloadPath != null) 'download_path': downloadPath,
      if (enableThumbnailPreview != null)
        'enable_thumbnail_preview': enableThumbnailPreview,
      if (maxConcurrentDownloads != null)
        'max_concurrent_downloads': maxConcurrentDownloads,
      if (segmentConcurrency != null) 'segment_concurrency': segmentConcurrency,
      if (lastDataSourceId != null) 'last_data_source_id': lastDataSourceId,
      if (cookieFile != null) 'cookie_file': cookieFile,
      if (themeMode != null) 'theme_mode': themeMode,
      if (subscriptionCheckedAt != null)
        'subscription_checked_at': subscriptionCheckedAt,
      if (playerNormalWidth != null) 'player_normal_width': playerNormalWidth,
      if (playerNormalHeight != null)
        'player_normal_height': playerNormalHeight,
      if (playerPipWidth != null) 'player_pip_width': playerPipWidth,
      if (playerPipHeight != null) 'player_pip_height': playerPipHeight,
      if (playerWindowX != null) 'player_window_x': playerWindowX,
      if (playerWindowY != null) 'player_window_y': playerWindowY,
      if (playerPipX != null) 'player_pip_x': playerPipX,
      if (playerPipY != null) 'player_pip_y': playerPipY,
      if (locale != null) 'locale': locale,
      if (searchHistory != null) 'search_history': searchHistory,
      if (showPet != null) 'show_pet': showPet,
      if (petWindowX != null) 'pet_window_x': petWindowX,
      if (petWindowY != null) 'pet_window_y': petWindowY,
    });
  }

  AppSettingsCompanion copyWith({
    Value<int>? id,
    Value<String?>? downloadPath,
    Value<bool>? enableThumbnailPreview,
    Value<int>? maxConcurrentDownloads,
    Value<int>? segmentConcurrency,
    Value<String?>? lastDataSourceId,
    Value<String?>? cookieFile,
    Value<int>? themeMode,
    Value<DateTime?>? subscriptionCheckedAt,
    Value<double?>? playerNormalWidth,
    Value<double?>? playerNormalHeight,
    Value<double?>? playerPipWidth,
    Value<double?>? playerPipHeight,
    Value<double?>? playerWindowX,
    Value<double?>? playerWindowY,
    Value<double?>? playerPipX,
    Value<double?>? playerPipY,
    Value<String?>? locale,
    Value<String?>? searchHistory,
    Value<bool>? showPet,
    Value<double?>? petWindowX,
    Value<double?>? petWindowY,
  }) {
    return AppSettingsCompanion(
      id: id ?? this.id,
      downloadPath: downloadPath ?? this.downloadPath,
      enableThumbnailPreview:
          enableThumbnailPreview ?? this.enableThumbnailPreview,
      maxConcurrentDownloads:
          maxConcurrentDownloads ?? this.maxConcurrentDownloads,
      segmentConcurrency: segmentConcurrency ?? this.segmentConcurrency,
      lastDataSourceId: lastDataSourceId ?? this.lastDataSourceId,
      cookieFile: cookieFile ?? this.cookieFile,
      themeMode: themeMode ?? this.themeMode,
      subscriptionCheckedAt:
          subscriptionCheckedAt ?? this.subscriptionCheckedAt,
      playerNormalWidth: playerNormalWidth ?? this.playerNormalWidth,
      playerNormalHeight: playerNormalHeight ?? this.playerNormalHeight,
      playerPipWidth: playerPipWidth ?? this.playerPipWidth,
      playerPipHeight: playerPipHeight ?? this.playerPipHeight,
      playerWindowX: playerWindowX ?? this.playerWindowX,
      playerWindowY: playerWindowY ?? this.playerWindowY,
      playerPipX: playerPipX ?? this.playerPipX,
      playerPipY: playerPipY ?? this.playerPipY,
      locale: locale ?? this.locale,
      searchHistory: searchHistory ?? this.searchHistory,
      showPet: showPet ?? this.showPet,
      petWindowX: petWindowX ?? this.petWindowX,
      petWindowY: petWindowY ?? this.petWindowY,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (downloadPath.present) {
      map['download_path'] = Variable<String>(downloadPath.value);
    }
    if (enableThumbnailPreview.present) {
      map['enable_thumbnail_preview'] = Variable<bool>(
        enableThumbnailPreview.value,
      );
    }
    if (maxConcurrentDownloads.present) {
      map['max_concurrent_downloads'] = Variable<int>(
        maxConcurrentDownloads.value,
      );
    }
    if (segmentConcurrency.present) {
      map['segment_concurrency'] = Variable<int>(segmentConcurrency.value);
    }
    if (lastDataSourceId.present) {
      map['last_data_source_id'] = Variable<String>(lastDataSourceId.value);
    }
    if (cookieFile.present) {
      map['cookie_file'] = Variable<String>(cookieFile.value);
    }
    if (themeMode.present) {
      map['theme_mode'] = Variable<int>(themeMode.value);
    }
    if (subscriptionCheckedAt.present) {
      map['subscription_checked_at'] = Variable<DateTime>(
        subscriptionCheckedAt.value,
      );
    }
    if (playerNormalWidth.present) {
      map['player_normal_width'] = Variable<double>(playerNormalWidth.value);
    }
    if (playerNormalHeight.present) {
      map['player_normal_height'] = Variable<double>(playerNormalHeight.value);
    }
    if (playerPipWidth.present) {
      map['player_pip_width'] = Variable<double>(playerPipWidth.value);
    }
    if (playerPipHeight.present) {
      map['player_pip_height'] = Variable<double>(playerPipHeight.value);
    }
    if (playerWindowX.present) {
      map['player_window_x'] = Variable<double>(playerWindowX.value);
    }
    if (playerWindowY.present) {
      map['player_window_y'] = Variable<double>(playerWindowY.value);
    }
    if (playerPipX.present) {
      map['player_pip_x'] = Variable<double>(playerPipX.value);
    }
    if (playerPipY.present) {
      map['player_pip_y'] = Variable<double>(playerPipY.value);
    }
    if (locale.present) {
      map['locale'] = Variable<String>(locale.value);
    }
    if (searchHistory.present) {
      map['search_history'] = Variable<String>(searchHistory.value);
    }
    if (showPet.present) {
      map['show_pet'] = Variable<bool>(showPet.value);
    }
    if (petWindowX.present) {
      map['pet_window_x'] = Variable<double>(petWindowX.value);
    }
    if (petWindowY.present) {
      map['pet_window_y'] = Variable<double>(petWindowY.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsCompanion(')
          ..write('id: $id, ')
          ..write('downloadPath: $downloadPath, ')
          ..write('enableThumbnailPreview: $enableThumbnailPreview, ')
          ..write('maxConcurrentDownloads: $maxConcurrentDownloads, ')
          ..write('segmentConcurrency: $segmentConcurrency, ')
          ..write('lastDataSourceId: $lastDataSourceId, ')
          ..write('cookieFile: $cookieFile, ')
          ..write('themeMode: $themeMode, ')
          ..write('subscriptionCheckedAt: $subscriptionCheckedAt, ')
          ..write('playerNormalWidth: $playerNormalWidth, ')
          ..write('playerNormalHeight: $playerNormalHeight, ')
          ..write('playerPipWidth: $playerPipWidth, ')
          ..write('playerPipHeight: $playerPipHeight, ')
          ..write('playerWindowX: $playerWindowX, ')
          ..write('playerWindowY: $playerWindowY, ')
          ..write('playerPipX: $playerPipX, ')
          ..write('playerPipY: $playerPipY, ')
          ..write('locale: $locale, ')
          ..write('searchHistory: $searchHistory, ')
          ..write('showPet: $showPet, ')
          ..write('petWindowX: $petWindowX, ')
          ..write('petWindowY: $petWindowY')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $VideosTable videos = $VideosTable(this);
  late final $VideoSettingsTable videoSettings = $VideoSettingsTable(this);
  late final $VideoHistoryTable videoHistory = $VideoHistoryTable(this);
  late final $EpisodeHistoryTable episodeHistory = $EpisodeHistoryTable(this);
  late final $EpisodeSkipDataTable episodeSkipData = $EpisodeSkipDataTable(
    this,
  );
  late final $SubscriptionsTable subscriptions = $SubscriptionsTable(this);
  late final $FavoritesTable favorites = $FavoritesTable(this);
  late final $DownloadTasksTable downloadTasks = $DownloadTasksTable(this);
  late final $AppSettingsTable appSettings = $AppSettingsTable(this);
  late final Index videosIdx = Index(
    'videos_idx',
    'CREATE UNIQUE INDEX videos_idx ON videos (source_id, api_id)',
  );
  late final Index videoSettingsIdx = Index(
    'video_settings_idx',
    'CREATE UNIQUE INDEX video_settings_idx ON video_settings (source_id, video_id)',
  );
  late final Index videoHistoryIdx = Index(
    'video_history_idx',
    'CREATE UNIQUE INDEX video_history_idx ON video_history (source_id, video_id)',
  );
  late final Index episodeHistoryIdx = Index(
    'episode_history_idx',
    'CREATE UNIQUE INDEX episode_history_idx ON episode_history (video_id, episode_index, source_id)',
  );
  late final Index episodeSkipDataIdx = Index(
    'episode_skip_data_idx',
    'CREATE UNIQUE INDEX episode_skip_data_idx ON episode_skip_data (video_id, episode_index, source_id)',
  );
  late final Index subscriptionsIdx = Index(
    'subscriptions_idx',
    'CREATE UNIQUE INDEX subscriptions_idx ON subscriptions (video_id, source_id)',
  );
  late final Index favoritesIdx = Index(
    'favorites_idx',
    'CREATE UNIQUE INDEX favorites_idx ON favorites (video_id, source_id)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    videos,
    videoSettings,
    videoHistory,
    episodeHistory,
    episodeSkipData,
    subscriptions,
    favorites,
    downloadTasks,
    appSettings,
    videosIdx,
    videoSettingsIdx,
    videoHistoryIdx,
    episodeHistoryIdx,
    episodeSkipDataIdx,
    subscriptionsIdx,
    favoritesIdx,
  ];
}

typedef $$VideosTableCreateCompanionBuilder =
    VideosCompanion Function({
      Value<int> id,
      Value<String?> sourceId,
      required int apiId,
      required String title,
      required String coverUrl,
      Value<String?> thumbUrl,
      Value<String?> backdropUrl,
      required double rating,
      Value<String?> year,
      Value<String?> region,
      required String type,
      Value<int?> typeId,
      Value<int?> typeId1,
      Value<String?> actor,
      Value<String?> blurb,
      Value<String?> remarks,
      Value<String?> version,
      Value<bool?> vip,
      Value<int?> vodTime,
      Value<int?> hits,
      Value<List<String>?> genres,
      Value<String?> description,
      Value<String?> content,
      Value<String?> director,
      Value<String?> writer,
      Value<String?> lang,
      Value<List<VideoEpisode>?> urls,
    });
typedef $$VideosTableUpdateCompanionBuilder =
    VideosCompanion Function({
      Value<int> id,
      Value<String?> sourceId,
      Value<int> apiId,
      Value<String> title,
      Value<String> coverUrl,
      Value<String?> thumbUrl,
      Value<String?> backdropUrl,
      Value<double> rating,
      Value<String?> year,
      Value<String?> region,
      Value<String> type,
      Value<int?> typeId,
      Value<int?> typeId1,
      Value<String?> actor,
      Value<String?> blurb,
      Value<String?> remarks,
      Value<String?> version,
      Value<bool?> vip,
      Value<int?> vodTime,
      Value<int?> hits,
      Value<List<String>?> genres,
      Value<String?> description,
      Value<String?> content,
      Value<String?> director,
      Value<String?> writer,
      Value<String?> lang,
      Value<List<VideoEpisode>?> urls,
    });

class $$VideosTableFilterComposer
    extends Composer<_$AppDatabase, $VideosTable> {
  $$VideosTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceId => $composableBuilder(
    column: $table.sourceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get apiId => $composableBuilder(
    column: $table.apiId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get coverUrl => $composableBuilder(
    column: $table.coverUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get thumbUrl => $composableBuilder(
    column: $table.thumbUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get backdropUrl => $composableBuilder(
    column: $table.backdropUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get rating => $composableBuilder(
    column: $table.rating,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get year => $composableBuilder(
    column: $table.year,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get region => $composableBuilder(
    column: $table.region,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get typeId => $composableBuilder(
    column: $table.typeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get typeId1 => $composableBuilder(
    column: $table.typeId1,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get actor => $composableBuilder(
    column: $table.actor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get blurb => $composableBuilder(
    column: $table.blurb,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remarks => $composableBuilder(
    column: $table.remarks,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get vip => $composableBuilder(
    column: $table.vip,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get vodTime => $composableBuilder(
    column: $table.vodTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get hits => $composableBuilder(
    column: $table.hits,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<List<String>?, List<String>, String>
  get genres => $composableBuilder(
    column: $table.genres,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get director => $composableBuilder(
    column: $table.director,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get writer => $composableBuilder(
    column: $table.writer,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lang => $composableBuilder(
    column: $table.lang,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<
    List<VideoEpisode>?,
    List<VideoEpisode>,
    String
  >
  get urls => $composableBuilder(
    column: $table.urls,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );
}

class $$VideosTableOrderingComposer
    extends Composer<_$AppDatabase, $VideosTable> {
  $$VideosTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceId => $composableBuilder(
    column: $table.sourceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get apiId => $composableBuilder(
    column: $table.apiId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get coverUrl => $composableBuilder(
    column: $table.coverUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get thumbUrl => $composableBuilder(
    column: $table.thumbUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get backdropUrl => $composableBuilder(
    column: $table.backdropUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get rating => $composableBuilder(
    column: $table.rating,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get year => $composableBuilder(
    column: $table.year,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get region => $composableBuilder(
    column: $table.region,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get typeId => $composableBuilder(
    column: $table.typeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get typeId1 => $composableBuilder(
    column: $table.typeId1,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get actor => $composableBuilder(
    column: $table.actor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get blurb => $composableBuilder(
    column: $table.blurb,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remarks => $composableBuilder(
    column: $table.remarks,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get vip => $composableBuilder(
    column: $table.vip,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get vodTime => $composableBuilder(
    column: $table.vodTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get hits => $composableBuilder(
    column: $table.hits,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get genres => $composableBuilder(
    column: $table.genres,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get director => $composableBuilder(
    column: $table.director,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get writer => $composableBuilder(
    column: $table.writer,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lang => $composableBuilder(
    column: $table.lang,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get urls => $composableBuilder(
    column: $table.urls,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$VideosTableAnnotationComposer
    extends Composer<_$AppDatabase, $VideosTable> {
  $$VideosTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get sourceId =>
      $composableBuilder(column: $table.sourceId, builder: (column) => column);

  GeneratedColumn<int> get apiId =>
      $composableBuilder(column: $table.apiId, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get coverUrl =>
      $composableBuilder(column: $table.coverUrl, builder: (column) => column);

  GeneratedColumn<String> get thumbUrl =>
      $composableBuilder(column: $table.thumbUrl, builder: (column) => column);

  GeneratedColumn<String> get backdropUrl => $composableBuilder(
    column: $table.backdropUrl,
    builder: (column) => column,
  );

  GeneratedColumn<double> get rating =>
      $composableBuilder(column: $table.rating, builder: (column) => column);

  GeneratedColumn<String> get year =>
      $composableBuilder(column: $table.year, builder: (column) => column);

  GeneratedColumn<String> get region =>
      $composableBuilder(column: $table.region, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<int> get typeId =>
      $composableBuilder(column: $table.typeId, builder: (column) => column);

  GeneratedColumn<int> get typeId1 =>
      $composableBuilder(column: $table.typeId1, builder: (column) => column);

  GeneratedColumn<String> get actor =>
      $composableBuilder(column: $table.actor, builder: (column) => column);

  GeneratedColumn<String> get blurb =>
      $composableBuilder(column: $table.blurb, builder: (column) => column);

  GeneratedColumn<String> get remarks =>
      $composableBuilder(column: $table.remarks, builder: (column) => column);

  GeneratedColumn<String> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<bool> get vip =>
      $composableBuilder(column: $table.vip, builder: (column) => column);

  GeneratedColumn<int> get vodTime =>
      $composableBuilder(column: $table.vodTime, builder: (column) => column);

  GeneratedColumn<int> get hits =>
      $composableBuilder(column: $table.hits, builder: (column) => column);

  GeneratedColumnWithTypeConverter<List<String>?, String> get genres =>
      $composableBuilder(column: $table.genres, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<String> get director =>
      $composableBuilder(column: $table.director, builder: (column) => column);

  GeneratedColumn<String> get writer =>
      $composableBuilder(column: $table.writer, builder: (column) => column);

  GeneratedColumn<String> get lang =>
      $composableBuilder(column: $table.lang, builder: (column) => column);

  GeneratedColumnWithTypeConverter<List<VideoEpisode>?, String> get urls =>
      $composableBuilder(column: $table.urls, builder: (column) => column);
}

class $$VideosTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $VideosTable,
          Video,
          $$VideosTableFilterComposer,
          $$VideosTableOrderingComposer,
          $$VideosTableAnnotationComposer,
          $$VideosTableCreateCompanionBuilder,
          $$VideosTableUpdateCompanionBuilder,
          (Video, BaseReferences<_$AppDatabase, $VideosTable, Video>),
          Video,
          PrefetchHooks Function()
        > {
  $$VideosTableTableManager(_$AppDatabase db, $VideosTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VideosTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$VideosTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$VideosTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> sourceId = const Value.absent(),
                Value<int> apiId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> coverUrl = const Value.absent(),
                Value<String?> thumbUrl = const Value.absent(),
                Value<String?> backdropUrl = const Value.absent(),
                Value<double> rating = const Value.absent(),
                Value<String?> year = const Value.absent(),
                Value<String?> region = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<int?> typeId = const Value.absent(),
                Value<int?> typeId1 = const Value.absent(),
                Value<String?> actor = const Value.absent(),
                Value<String?> blurb = const Value.absent(),
                Value<String?> remarks = const Value.absent(),
                Value<String?> version = const Value.absent(),
                Value<bool?> vip = const Value.absent(),
                Value<int?> vodTime = const Value.absent(),
                Value<int?> hits = const Value.absent(),
                Value<List<String>?> genres = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String?> content = const Value.absent(),
                Value<String?> director = const Value.absent(),
                Value<String?> writer = const Value.absent(),
                Value<String?> lang = const Value.absent(),
                Value<List<VideoEpisode>?> urls = const Value.absent(),
              }) => VideosCompanion(
                id: id,
                sourceId: sourceId,
                apiId: apiId,
                title: title,
                coverUrl: coverUrl,
                thumbUrl: thumbUrl,
                backdropUrl: backdropUrl,
                rating: rating,
                year: year,
                region: region,
                type: type,
                typeId: typeId,
                typeId1: typeId1,
                actor: actor,
                blurb: blurb,
                remarks: remarks,
                version: version,
                vip: vip,
                vodTime: vodTime,
                hits: hits,
                genres: genres,
                description: description,
                content: content,
                director: director,
                writer: writer,
                lang: lang,
                urls: urls,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> sourceId = const Value.absent(),
                required int apiId,
                required String title,
                required String coverUrl,
                Value<String?> thumbUrl = const Value.absent(),
                Value<String?> backdropUrl = const Value.absent(),
                required double rating,
                Value<String?> year = const Value.absent(),
                Value<String?> region = const Value.absent(),
                required String type,
                Value<int?> typeId = const Value.absent(),
                Value<int?> typeId1 = const Value.absent(),
                Value<String?> actor = const Value.absent(),
                Value<String?> blurb = const Value.absent(),
                Value<String?> remarks = const Value.absent(),
                Value<String?> version = const Value.absent(),
                Value<bool?> vip = const Value.absent(),
                Value<int?> vodTime = const Value.absent(),
                Value<int?> hits = const Value.absent(),
                Value<List<String>?> genres = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String?> content = const Value.absent(),
                Value<String?> director = const Value.absent(),
                Value<String?> writer = const Value.absent(),
                Value<String?> lang = const Value.absent(),
                Value<List<VideoEpisode>?> urls = const Value.absent(),
              }) => VideosCompanion.insert(
                id: id,
                sourceId: sourceId,
                apiId: apiId,
                title: title,
                coverUrl: coverUrl,
                thumbUrl: thumbUrl,
                backdropUrl: backdropUrl,
                rating: rating,
                year: year,
                region: region,
                type: type,
                typeId: typeId,
                typeId1: typeId1,
                actor: actor,
                blurb: blurb,
                remarks: remarks,
                version: version,
                vip: vip,
                vodTime: vodTime,
                hits: hits,
                genres: genres,
                description: description,
                content: content,
                director: director,
                writer: writer,
                lang: lang,
                urls: urls,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$VideosTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $VideosTable,
      Video,
      $$VideosTableFilterComposer,
      $$VideosTableOrderingComposer,
      $$VideosTableAnnotationComposer,
      $$VideosTableCreateCompanionBuilder,
      $$VideosTableUpdateCompanionBuilder,
      (Video, BaseReferences<_$AppDatabase, $VideosTable, Video>),
      Video,
      PrefetchHooks Function()
    >;
typedef $$VideoSettingsTableCreateCompanionBuilder =
    VideoSettingsCompanion Function({
      Value<int> id,
      Value<String?> sourceId,
      required int videoId,
      Value<int> introDuration,
      Value<int> outroDuration,
      Value<bool> autoSkip,
    });
typedef $$VideoSettingsTableUpdateCompanionBuilder =
    VideoSettingsCompanion Function({
      Value<int> id,
      Value<String?> sourceId,
      Value<int> videoId,
      Value<int> introDuration,
      Value<int> outroDuration,
      Value<bool> autoSkip,
    });

class $$VideoSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $VideoSettingsTable> {
  $$VideoSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceId => $composableBuilder(
    column: $table.sourceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get videoId => $composableBuilder(
    column: $table.videoId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get introDuration => $composableBuilder(
    column: $table.introDuration,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get outroDuration => $composableBuilder(
    column: $table.outroDuration,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get autoSkip => $composableBuilder(
    column: $table.autoSkip,
    builder: (column) => ColumnFilters(column),
  );
}

class $$VideoSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $VideoSettingsTable> {
  $$VideoSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceId => $composableBuilder(
    column: $table.sourceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get videoId => $composableBuilder(
    column: $table.videoId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get introDuration => $composableBuilder(
    column: $table.introDuration,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get outroDuration => $composableBuilder(
    column: $table.outroDuration,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get autoSkip => $composableBuilder(
    column: $table.autoSkip,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$VideoSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $VideoSettingsTable> {
  $$VideoSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get sourceId =>
      $composableBuilder(column: $table.sourceId, builder: (column) => column);

  GeneratedColumn<int> get videoId =>
      $composableBuilder(column: $table.videoId, builder: (column) => column);

  GeneratedColumn<int> get introDuration => $composableBuilder(
    column: $table.introDuration,
    builder: (column) => column,
  );

  GeneratedColumn<int> get outroDuration => $composableBuilder(
    column: $table.outroDuration,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get autoSkip =>
      $composableBuilder(column: $table.autoSkip, builder: (column) => column);
}

class $$VideoSettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $VideoSettingsTable,
          VideoSetting,
          $$VideoSettingsTableFilterComposer,
          $$VideoSettingsTableOrderingComposer,
          $$VideoSettingsTableAnnotationComposer,
          $$VideoSettingsTableCreateCompanionBuilder,
          $$VideoSettingsTableUpdateCompanionBuilder,
          (
            VideoSetting,
            BaseReferences<_$AppDatabase, $VideoSettingsTable, VideoSetting>,
          ),
          VideoSetting,
          PrefetchHooks Function()
        > {
  $$VideoSettingsTableTableManager(_$AppDatabase db, $VideoSettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VideoSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$VideoSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$VideoSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> sourceId = const Value.absent(),
                Value<int> videoId = const Value.absent(),
                Value<int> introDuration = const Value.absent(),
                Value<int> outroDuration = const Value.absent(),
                Value<bool> autoSkip = const Value.absent(),
              }) => VideoSettingsCompanion(
                id: id,
                sourceId: sourceId,
                videoId: videoId,
                introDuration: introDuration,
                outroDuration: outroDuration,
                autoSkip: autoSkip,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> sourceId = const Value.absent(),
                required int videoId,
                Value<int> introDuration = const Value.absent(),
                Value<int> outroDuration = const Value.absent(),
                Value<bool> autoSkip = const Value.absent(),
              }) => VideoSettingsCompanion.insert(
                id: id,
                sourceId: sourceId,
                videoId: videoId,
                introDuration: introDuration,
                outroDuration: outroDuration,
                autoSkip: autoSkip,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$VideoSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $VideoSettingsTable,
      VideoSetting,
      $$VideoSettingsTableFilterComposer,
      $$VideoSettingsTableOrderingComposer,
      $$VideoSettingsTableAnnotationComposer,
      $$VideoSettingsTableCreateCompanionBuilder,
      $$VideoSettingsTableUpdateCompanionBuilder,
      (
        VideoSetting,
        BaseReferences<_$AppDatabase, $VideoSettingsTable, VideoSetting>,
      ),
      VideoSetting,
      PrefetchHooks Function()
    >;
typedef $$VideoHistoryTableCreateCompanionBuilder =
    VideoHistoryCompanion Function({
      Value<int> id,
      Value<String?> sourceId,
      required int videoId,
      required String videoTitle,
      required String coverUrl,
      Value<String?> rating,
      required String type,
      Value<String?> region,
      Value<String?> year,
      Value<String?> actor,
      Value<String?> version,
      Value<int?> hits,
      Value<String?> remarks,
      Value<String?> blurb,
      required int lastEpisodeIndex,
      Value<String?> lastEpisodeTitle,
      required DateTime updatedAt,
    });
typedef $$VideoHistoryTableUpdateCompanionBuilder =
    VideoHistoryCompanion Function({
      Value<int> id,
      Value<String?> sourceId,
      Value<int> videoId,
      Value<String> videoTitle,
      Value<String> coverUrl,
      Value<String?> rating,
      Value<String> type,
      Value<String?> region,
      Value<String?> year,
      Value<String?> actor,
      Value<String?> version,
      Value<int?> hits,
      Value<String?> remarks,
      Value<String?> blurb,
      Value<int> lastEpisodeIndex,
      Value<String?> lastEpisodeTitle,
      Value<DateTime> updatedAt,
    });

class $$VideoHistoryTableFilterComposer
    extends Composer<_$AppDatabase, $VideoHistoryTable> {
  $$VideoHistoryTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceId => $composableBuilder(
    column: $table.sourceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get videoId => $composableBuilder(
    column: $table.videoId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get videoTitle => $composableBuilder(
    column: $table.videoTitle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get coverUrl => $composableBuilder(
    column: $table.coverUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rating => $composableBuilder(
    column: $table.rating,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get region => $composableBuilder(
    column: $table.region,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get year => $composableBuilder(
    column: $table.year,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get actor => $composableBuilder(
    column: $table.actor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get hits => $composableBuilder(
    column: $table.hits,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remarks => $composableBuilder(
    column: $table.remarks,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get blurb => $composableBuilder(
    column: $table.blurb,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastEpisodeIndex => $composableBuilder(
    column: $table.lastEpisodeIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastEpisodeTitle => $composableBuilder(
    column: $table.lastEpisodeTitle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$VideoHistoryTableOrderingComposer
    extends Composer<_$AppDatabase, $VideoHistoryTable> {
  $$VideoHistoryTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceId => $composableBuilder(
    column: $table.sourceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get videoId => $composableBuilder(
    column: $table.videoId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get videoTitle => $composableBuilder(
    column: $table.videoTitle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get coverUrl => $composableBuilder(
    column: $table.coverUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rating => $composableBuilder(
    column: $table.rating,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get region => $composableBuilder(
    column: $table.region,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get year => $composableBuilder(
    column: $table.year,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get actor => $composableBuilder(
    column: $table.actor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get hits => $composableBuilder(
    column: $table.hits,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remarks => $composableBuilder(
    column: $table.remarks,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get blurb => $composableBuilder(
    column: $table.blurb,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastEpisodeIndex => $composableBuilder(
    column: $table.lastEpisodeIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastEpisodeTitle => $composableBuilder(
    column: $table.lastEpisodeTitle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$VideoHistoryTableAnnotationComposer
    extends Composer<_$AppDatabase, $VideoHistoryTable> {
  $$VideoHistoryTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get sourceId =>
      $composableBuilder(column: $table.sourceId, builder: (column) => column);

  GeneratedColumn<int> get videoId =>
      $composableBuilder(column: $table.videoId, builder: (column) => column);

  GeneratedColumn<String> get videoTitle => $composableBuilder(
    column: $table.videoTitle,
    builder: (column) => column,
  );

  GeneratedColumn<String> get coverUrl =>
      $composableBuilder(column: $table.coverUrl, builder: (column) => column);

  GeneratedColumn<String> get rating =>
      $composableBuilder(column: $table.rating, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get region =>
      $composableBuilder(column: $table.region, builder: (column) => column);

  GeneratedColumn<String> get year =>
      $composableBuilder(column: $table.year, builder: (column) => column);

  GeneratedColumn<String> get actor =>
      $composableBuilder(column: $table.actor, builder: (column) => column);

  GeneratedColumn<String> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<int> get hits =>
      $composableBuilder(column: $table.hits, builder: (column) => column);

  GeneratedColumn<String> get remarks =>
      $composableBuilder(column: $table.remarks, builder: (column) => column);

  GeneratedColumn<String> get blurb =>
      $composableBuilder(column: $table.blurb, builder: (column) => column);

  GeneratedColumn<int> get lastEpisodeIndex => $composableBuilder(
    column: $table.lastEpisodeIndex,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastEpisodeTitle => $composableBuilder(
    column: $table.lastEpisodeTitle,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$VideoHistoryTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $VideoHistoryTable,
          VideoHistoryData,
          $$VideoHistoryTableFilterComposer,
          $$VideoHistoryTableOrderingComposer,
          $$VideoHistoryTableAnnotationComposer,
          $$VideoHistoryTableCreateCompanionBuilder,
          $$VideoHistoryTableUpdateCompanionBuilder,
          (
            VideoHistoryData,
            BaseReferences<_$AppDatabase, $VideoHistoryTable, VideoHistoryData>,
          ),
          VideoHistoryData,
          PrefetchHooks Function()
        > {
  $$VideoHistoryTableTableManager(_$AppDatabase db, $VideoHistoryTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VideoHistoryTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$VideoHistoryTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$VideoHistoryTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> sourceId = const Value.absent(),
                Value<int> videoId = const Value.absent(),
                Value<String> videoTitle = const Value.absent(),
                Value<String> coverUrl = const Value.absent(),
                Value<String?> rating = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String?> region = const Value.absent(),
                Value<String?> year = const Value.absent(),
                Value<String?> actor = const Value.absent(),
                Value<String?> version = const Value.absent(),
                Value<int?> hits = const Value.absent(),
                Value<String?> remarks = const Value.absent(),
                Value<String?> blurb = const Value.absent(),
                Value<int> lastEpisodeIndex = const Value.absent(),
                Value<String?> lastEpisodeTitle = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => VideoHistoryCompanion(
                id: id,
                sourceId: sourceId,
                videoId: videoId,
                videoTitle: videoTitle,
                coverUrl: coverUrl,
                rating: rating,
                type: type,
                region: region,
                year: year,
                actor: actor,
                version: version,
                hits: hits,
                remarks: remarks,
                blurb: blurb,
                lastEpisodeIndex: lastEpisodeIndex,
                lastEpisodeTitle: lastEpisodeTitle,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> sourceId = const Value.absent(),
                required int videoId,
                required String videoTitle,
                required String coverUrl,
                Value<String?> rating = const Value.absent(),
                required String type,
                Value<String?> region = const Value.absent(),
                Value<String?> year = const Value.absent(),
                Value<String?> actor = const Value.absent(),
                Value<String?> version = const Value.absent(),
                Value<int?> hits = const Value.absent(),
                Value<String?> remarks = const Value.absent(),
                Value<String?> blurb = const Value.absent(),
                required int lastEpisodeIndex,
                Value<String?> lastEpisodeTitle = const Value.absent(),
                required DateTime updatedAt,
              }) => VideoHistoryCompanion.insert(
                id: id,
                sourceId: sourceId,
                videoId: videoId,
                videoTitle: videoTitle,
                coverUrl: coverUrl,
                rating: rating,
                type: type,
                region: region,
                year: year,
                actor: actor,
                version: version,
                hits: hits,
                remarks: remarks,
                blurb: blurb,
                lastEpisodeIndex: lastEpisodeIndex,
                lastEpisodeTitle: lastEpisodeTitle,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$VideoHistoryTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $VideoHistoryTable,
      VideoHistoryData,
      $$VideoHistoryTableFilterComposer,
      $$VideoHistoryTableOrderingComposer,
      $$VideoHistoryTableAnnotationComposer,
      $$VideoHistoryTableCreateCompanionBuilder,
      $$VideoHistoryTableUpdateCompanionBuilder,
      (
        VideoHistoryData,
        BaseReferences<_$AppDatabase, $VideoHistoryTable, VideoHistoryData>,
      ),
      VideoHistoryData,
      PrefetchHooks Function()
    >;
typedef $$EpisodeHistoryTableCreateCompanionBuilder =
    EpisodeHistoryCompanion Function({
      Value<int> id,
      Value<String?> sourceId,
      required int videoId,
      required int episodeIndex,
      required int positionMillis,
      required int durationMillis,
      required DateTime updatedAt,
    });
typedef $$EpisodeHistoryTableUpdateCompanionBuilder =
    EpisodeHistoryCompanion Function({
      Value<int> id,
      Value<String?> sourceId,
      Value<int> videoId,
      Value<int> episodeIndex,
      Value<int> positionMillis,
      Value<int> durationMillis,
      Value<DateTime> updatedAt,
    });

class $$EpisodeHistoryTableFilterComposer
    extends Composer<_$AppDatabase, $EpisodeHistoryTable> {
  $$EpisodeHistoryTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceId => $composableBuilder(
    column: $table.sourceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get videoId => $composableBuilder(
    column: $table.videoId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get episodeIndex => $composableBuilder(
    column: $table.episodeIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get positionMillis => $composableBuilder(
    column: $table.positionMillis,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationMillis => $composableBuilder(
    column: $table.durationMillis,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$EpisodeHistoryTableOrderingComposer
    extends Composer<_$AppDatabase, $EpisodeHistoryTable> {
  $$EpisodeHistoryTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceId => $composableBuilder(
    column: $table.sourceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get videoId => $composableBuilder(
    column: $table.videoId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get episodeIndex => $composableBuilder(
    column: $table.episodeIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get positionMillis => $composableBuilder(
    column: $table.positionMillis,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationMillis => $composableBuilder(
    column: $table.durationMillis,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$EpisodeHistoryTableAnnotationComposer
    extends Composer<_$AppDatabase, $EpisodeHistoryTable> {
  $$EpisodeHistoryTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get sourceId =>
      $composableBuilder(column: $table.sourceId, builder: (column) => column);

  GeneratedColumn<int> get videoId =>
      $composableBuilder(column: $table.videoId, builder: (column) => column);

  GeneratedColumn<int> get episodeIndex => $composableBuilder(
    column: $table.episodeIndex,
    builder: (column) => column,
  );

  GeneratedColumn<int> get positionMillis => $composableBuilder(
    column: $table.positionMillis,
    builder: (column) => column,
  );

  GeneratedColumn<int> get durationMillis => $composableBuilder(
    column: $table.durationMillis,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$EpisodeHistoryTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EpisodeHistoryTable,
          EpisodeHistoryData,
          $$EpisodeHistoryTableFilterComposer,
          $$EpisodeHistoryTableOrderingComposer,
          $$EpisodeHistoryTableAnnotationComposer,
          $$EpisodeHistoryTableCreateCompanionBuilder,
          $$EpisodeHistoryTableUpdateCompanionBuilder,
          (
            EpisodeHistoryData,
            BaseReferences<
              _$AppDatabase,
              $EpisodeHistoryTable,
              EpisodeHistoryData
            >,
          ),
          EpisodeHistoryData,
          PrefetchHooks Function()
        > {
  $$EpisodeHistoryTableTableManager(
    _$AppDatabase db,
    $EpisodeHistoryTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EpisodeHistoryTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EpisodeHistoryTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EpisodeHistoryTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> sourceId = const Value.absent(),
                Value<int> videoId = const Value.absent(),
                Value<int> episodeIndex = const Value.absent(),
                Value<int> positionMillis = const Value.absent(),
                Value<int> durationMillis = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => EpisodeHistoryCompanion(
                id: id,
                sourceId: sourceId,
                videoId: videoId,
                episodeIndex: episodeIndex,
                positionMillis: positionMillis,
                durationMillis: durationMillis,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> sourceId = const Value.absent(),
                required int videoId,
                required int episodeIndex,
                required int positionMillis,
                required int durationMillis,
                required DateTime updatedAt,
              }) => EpisodeHistoryCompanion.insert(
                id: id,
                sourceId: sourceId,
                videoId: videoId,
                episodeIndex: episodeIndex,
                positionMillis: positionMillis,
                durationMillis: durationMillis,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$EpisodeHistoryTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EpisodeHistoryTable,
      EpisodeHistoryData,
      $$EpisodeHistoryTableFilterComposer,
      $$EpisodeHistoryTableOrderingComposer,
      $$EpisodeHistoryTableAnnotationComposer,
      $$EpisodeHistoryTableCreateCompanionBuilder,
      $$EpisodeHistoryTableUpdateCompanionBuilder,
      (
        EpisodeHistoryData,
        BaseReferences<_$AppDatabase, $EpisodeHistoryTable, EpisodeHistoryData>,
      ),
      EpisodeHistoryData,
      PrefetchHooks Function()
    >;
typedef $$EpisodeSkipDataTableCreateCompanionBuilder =
    EpisodeSkipDataCompanion Function({
      Value<int> id,
      Value<String?> sourceId,
      required int videoId,
      required int episodeIndex,
      Value<int?> introEndMillis,
      Value<int?> outroStartMillis,
      Value<int?> markerSource,
      Value<Uint8List?> sweepHashes,
    });
typedef $$EpisodeSkipDataTableUpdateCompanionBuilder =
    EpisodeSkipDataCompanion Function({
      Value<int> id,
      Value<String?> sourceId,
      Value<int> videoId,
      Value<int> episodeIndex,
      Value<int?> introEndMillis,
      Value<int?> outroStartMillis,
      Value<int?> markerSource,
      Value<Uint8List?> sweepHashes,
    });

class $$EpisodeSkipDataTableFilterComposer
    extends Composer<_$AppDatabase, $EpisodeSkipDataTable> {
  $$EpisodeSkipDataTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceId => $composableBuilder(
    column: $table.sourceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get videoId => $composableBuilder(
    column: $table.videoId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get episodeIndex => $composableBuilder(
    column: $table.episodeIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get introEndMillis => $composableBuilder(
    column: $table.introEndMillis,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get outroStartMillis => $composableBuilder(
    column: $table.outroStartMillis,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get markerSource => $composableBuilder(
    column: $table.markerSource,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get sweepHashes => $composableBuilder(
    column: $table.sweepHashes,
    builder: (column) => ColumnFilters(column),
  );
}

class $$EpisodeSkipDataTableOrderingComposer
    extends Composer<_$AppDatabase, $EpisodeSkipDataTable> {
  $$EpisodeSkipDataTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceId => $composableBuilder(
    column: $table.sourceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get videoId => $composableBuilder(
    column: $table.videoId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get episodeIndex => $composableBuilder(
    column: $table.episodeIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get introEndMillis => $composableBuilder(
    column: $table.introEndMillis,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get outroStartMillis => $composableBuilder(
    column: $table.outroStartMillis,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get markerSource => $composableBuilder(
    column: $table.markerSource,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get sweepHashes => $composableBuilder(
    column: $table.sweepHashes,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$EpisodeSkipDataTableAnnotationComposer
    extends Composer<_$AppDatabase, $EpisodeSkipDataTable> {
  $$EpisodeSkipDataTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get sourceId =>
      $composableBuilder(column: $table.sourceId, builder: (column) => column);

  GeneratedColumn<int> get videoId =>
      $composableBuilder(column: $table.videoId, builder: (column) => column);

  GeneratedColumn<int> get episodeIndex => $composableBuilder(
    column: $table.episodeIndex,
    builder: (column) => column,
  );

  GeneratedColumn<int> get introEndMillis => $composableBuilder(
    column: $table.introEndMillis,
    builder: (column) => column,
  );

  GeneratedColumn<int> get outroStartMillis => $composableBuilder(
    column: $table.outroStartMillis,
    builder: (column) => column,
  );

  GeneratedColumn<int> get markerSource => $composableBuilder(
    column: $table.markerSource,
    builder: (column) => column,
  );

  GeneratedColumn<Uint8List> get sweepHashes => $composableBuilder(
    column: $table.sweepHashes,
    builder: (column) => column,
  );
}

class $$EpisodeSkipDataTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EpisodeSkipDataTable,
          EpisodeSkipDataData,
          $$EpisodeSkipDataTableFilterComposer,
          $$EpisodeSkipDataTableOrderingComposer,
          $$EpisodeSkipDataTableAnnotationComposer,
          $$EpisodeSkipDataTableCreateCompanionBuilder,
          $$EpisodeSkipDataTableUpdateCompanionBuilder,
          (
            EpisodeSkipDataData,
            BaseReferences<
              _$AppDatabase,
              $EpisodeSkipDataTable,
              EpisodeSkipDataData
            >,
          ),
          EpisodeSkipDataData,
          PrefetchHooks Function()
        > {
  $$EpisodeSkipDataTableTableManager(
    _$AppDatabase db,
    $EpisodeSkipDataTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EpisodeSkipDataTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EpisodeSkipDataTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EpisodeSkipDataTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> sourceId = const Value.absent(),
                Value<int> videoId = const Value.absent(),
                Value<int> episodeIndex = const Value.absent(),
                Value<int?> introEndMillis = const Value.absent(),
                Value<int?> outroStartMillis = const Value.absent(),
                Value<int?> markerSource = const Value.absent(),
                Value<Uint8List?> sweepHashes = const Value.absent(),
              }) => EpisodeSkipDataCompanion(
                id: id,
                sourceId: sourceId,
                videoId: videoId,
                episodeIndex: episodeIndex,
                introEndMillis: introEndMillis,
                outroStartMillis: outroStartMillis,
                markerSource: markerSource,
                sweepHashes: sweepHashes,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> sourceId = const Value.absent(),
                required int videoId,
                required int episodeIndex,
                Value<int?> introEndMillis = const Value.absent(),
                Value<int?> outroStartMillis = const Value.absent(),
                Value<int?> markerSource = const Value.absent(),
                Value<Uint8List?> sweepHashes = const Value.absent(),
              }) => EpisodeSkipDataCompanion.insert(
                id: id,
                sourceId: sourceId,
                videoId: videoId,
                episodeIndex: episodeIndex,
                introEndMillis: introEndMillis,
                outroStartMillis: outroStartMillis,
                markerSource: markerSource,
                sweepHashes: sweepHashes,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$EpisodeSkipDataTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EpisodeSkipDataTable,
      EpisodeSkipDataData,
      $$EpisodeSkipDataTableFilterComposer,
      $$EpisodeSkipDataTableOrderingComposer,
      $$EpisodeSkipDataTableAnnotationComposer,
      $$EpisodeSkipDataTableCreateCompanionBuilder,
      $$EpisodeSkipDataTableUpdateCompanionBuilder,
      (
        EpisodeSkipDataData,
        BaseReferences<
          _$AppDatabase,
          $EpisodeSkipDataTable,
          EpisodeSkipDataData
        >,
      ),
      EpisodeSkipDataData,
      PrefetchHooks Function()
    >;
typedef $$SubscriptionsTableCreateCompanionBuilder =
    SubscriptionsCompanion Function({
      Value<int> id,
      required String sourceId,
      required int videoId,
      required String title,
      Value<String?> year,
      Value<String?> coverUrl,
      Value<String?> lastSeenRemarks,
      Value<DateTime?> lastUpdateAt,
      Value<String?> updateHistory,
      Value<DateTime?> nextCheckAt,
      Value<bool> unread,
      Value<bool> finished,
      Value<String?> crossSeenSourceId,
      Value<String?> crossSeenRemarks,
      required DateTime createdAt,
    });
typedef $$SubscriptionsTableUpdateCompanionBuilder =
    SubscriptionsCompanion Function({
      Value<int> id,
      Value<String> sourceId,
      Value<int> videoId,
      Value<String> title,
      Value<String?> year,
      Value<String?> coverUrl,
      Value<String?> lastSeenRemarks,
      Value<DateTime?> lastUpdateAt,
      Value<String?> updateHistory,
      Value<DateTime?> nextCheckAt,
      Value<bool> unread,
      Value<bool> finished,
      Value<String?> crossSeenSourceId,
      Value<String?> crossSeenRemarks,
      Value<DateTime> createdAt,
    });

class $$SubscriptionsTableFilterComposer
    extends Composer<_$AppDatabase, $SubscriptionsTable> {
  $$SubscriptionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceId => $composableBuilder(
    column: $table.sourceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get videoId => $composableBuilder(
    column: $table.videoId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get year => $composableBuilder(
    column: $table.year,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get coverUrl => $composableBuilder(
    column: $table.coverUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastSeenRemarks => $composableBuilder(
    column: $table.lastSeenRemarks,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastUpdateAt => $composableBuilder(
    column: $table.lastUpdateAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updateHistory => $composableBuilder(
    column: $table.updateHistory,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get nextCheckAt => $composableBuilder(
    column: $table.nextCheckAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get unread => $composableBuilder(
    column: $table.unread,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get finished => $composableBuilder(
    column: $table.finished,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get crossSeenSourceId => $composableBuilder(
    column: $table.crossSeenSourceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get crossSeenRemarks => $composableBuilder(
    column: $table.crossSeenRemarks,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SubscriptionsTableOrderingComposer
    extends Composer<_$AppDatabase, $SubscriptionsTable> {
  $$SubscriptionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceId => $composableBuilder(
    column: $table.sourceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get videoId => $composableBuilder(
    column: $table.videoId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get year => $composableBuilder(
    column: $table.year,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get coverUrl => $composableBuilder(
    column: $table.coverUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastSeenRemarks => $composableBuilder(
    column: $table.lastSeenRemarks,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastUpdateAt => $composableBuilder(
    column: $table.lastUpdateAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updateHistory => $composableBuilder(
    column: $table.updateHistory,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get nextCheckAt => $composableBuilder(
    column: $table.nextCheckAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get unread => $composableBuilder(
    column: $table.unread,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get finished => $composableBuilder(
    column: $table.finished,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get crossSeenSourceId => $composableBuilder(
    column: $table.crossSeenSourceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get crossSeenRemarks => $composableBuilder(
    column: $table.crossSeenRemarks,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SubscriptionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SubscriptionsTable> {
  $$SubscriptionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get sourceId =>
      $composableBuilder(column: $table.sourceId, builder: (column) => column);

  GeneratedColumn<int> get videoId =>
      $composableBuilder(column: $table.videoId, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get year =>
      $composableBuilder(column: $table.year, builder: (column) => column);

  GeneratedColumn<String> get coverUrl =>
      $composableBuilder(column: $table.coverUrl, builder: (column) => column);

  GeneratedColumn<String> get lastSeenRemarks => $composableBuilder(
    column: $table.lastSeenRemarks,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastUpdateAt => $composableBuilder(
    column: $table.lastUpdateAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get updateHistory => $composableBuilder(
    column: $table.updateHistory,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get nextCheckAt => $composableBuilder(
    column: $table.nextCheckAt,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get unread =>
      $composableBuilder(column: $table.unread, builder: (column) => column);

  GeneratedColumn<bool> get finished =>
      $composableBuilder(column: $table.finished, builder: (column) => column);

  GeneratedColumn<String> get crossSeenSourceId => $composableBuilder(
    column: $table.crossSeenSourceId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get crossSeenRemarks => $composableBuilder(
    column: $table.crossSeenRemarks,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$SubscriptionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SubscriptionsTable,
          Subscription,
          $$SubscriptionsTableFilterComposer,
          $$SubscriptionsTableOrderingComposer,
          $$SubscriptionsTableAnnotationComposer,
          $$SubscriptionsTableCreateCompanionBuilder,
          $$SubscriptionsTableUpdateCompanionBuilder,
          (
            Subscription,
            BaseReferences<_$AppDatabase, $SubscriptionsTable, Subscription>,
          ),
          Subscription,
          PrefetchHooks Function()
        > {
  $$SubscriptionsTableTableManager(_$AppDatabase db, $SubscriptionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SubscriptionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SubscriptionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SubscriptionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> sourceId = const Value.absent(),
                Value<int> videoId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> year = const Value.absent(),
                Value<String?> coverUrl = const Value.absent(),
                Value<String?> lastSeenRemarks = const Value.absent(),
                Value<DateTime?> lastUpdateAt = const Value.absent(),
                Value<String?> updateHistory = const Value.absent(),
                Value<DateTime?> nextCheckAt = const Value.absent(),
                Value<bool> unread = const Value.absent(),
                Value<bool> finished = const Value.absent(),
                Value<String?> crossSeenSourceId = const Value.absent(),
                Value<String?> crossSeenRemarks = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => SubscriptionsCompanion(
                id: id,
                sourceId: sourceId,
                videoId: videoId,
                title: title,
                year: year,
                coverUrl: coverUrl,
                lastSeenRemarks: lastSeenRemarks,
                lastUpdateAt: lastUpdateAt,
                updateHistory: updateHistory,
                nextCheckAt: nextCheckAt,
                unread: unread,
                finished: finished,
                crossSeenSourceId: crossSeenSourceId,
                crossSeenRemarks: crossSeenRemarks,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String sourceId,
                required int videoId,
                required String title,
                Value<String?> year = const Value.absent(),
                Value<String?> coverUrl = const Value.absent(),
                Value<String?> lastSeenRemarks = const Value.absent(),
                Value<DateTime?> lastUpdateAt = const Value.absent(),
                Value<String?> updateHistory = const Value.absent(),
                Value<DateTime?> nextCheckAt = const Value.absent(),
                Value<bool> unread = const Value.absent(),
                Value<bool> finished = const Value.absent(),
                Value<String?> crossSeenSourceId = const Value.absent(),
                Value<String?> crossSeenRemarks = const Value.absent(),
                required DateTime createdAt,
              }) => SubscriptionsCompanion.insert(
                id: id,
                sourceId: sourceId,
                videoId: videoId,
                title: title,
                year: year,
                coverUrl: coverUrl,
                lastSeenRemarks: lastSeenRemarks,
                lastUpdateAt: lastUpdateAt,
                updateHistory: updateHistory,
                nextCheckAt: nextCheckAt,
                unread: unread,
                finished: finished,
                crossSeenSourceId: crossSeenSourceId,
                crossSeenRemarks: crossSeenRemarks,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SubscriptionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SubscriptionsTable,
      Subscription,
      $$SubscriptionsTableFilterComposer,
      $$SubscriptionsTableOrderingComposer,
      $$SubscriptionsTableAnnotationComposer,
      $$SubscriptionsTableCreateCompanionBuilder,
      $$SubscriptionsTableUpdateCompanionBuilder,
      (
        Subscription,
        BaseReferences<_$AppDatabase, $SubscriptionsTable, Subscription>,
      ),
      Subscription,
      PrefetchHooks Function()
    >;
typedef $$FavoritesTableCreateCompanionBuilder =
    FavoritesCompanion Function({
      Value<int> id,
      required String sourceId,
      required int videoId,
      required String title,
      Value<String?> year,
      Value<String?> coverUrl,
      Value<String?> rating,
      Value<String> type,
      Value<String?> region,
      Value<String?> remarks,
      required DateTime createdAt,
    });
typedef $$FavoritesTableUpdateCompanionBuilder =
    FavoritesCompanion Function({
      Value<int> id,
      Value<String> sourceId,
      Value<int> videoId,
      Value<String> title,
      Value<String?> year,
      Value<String?> coverUrl,
      Value<String?> rating,
      Value<String> type,
      Value<String?> region,
      Value<String?> remarks,
      Value<DateTime> createdAt,
    });

class $$FavoritesTableFilterComposer
    extends Composer<_$AppDatabase, $FavoritesTable> {
  $$FavoritesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceId => $composableBuilder(
    column: $table.sourceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get videoId => $composableBuilder(
    column: $table.videoId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get year => $composableBuilder(
    column: $table.year,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get coverUrl => $composableBuilder(
    column: $table.coverUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rating => $composableBuilder(
    column: $table.rating,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get region => $composableBuilder(
    column: $table.region,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remarks => $composableBuilder(
    column: $table.remarks,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FavoritesTableOrderingComposer
    extends Composer<_$AppDatabase, $FavoritesTable> {
  $$FavoritesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceId => $composableBuilder(
    column: $table.sourceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get videoId => $composableBuilder(
    column: $table.videoId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get year => $composableBuilder(
    column: $table.year,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get coverUrl => $composableBuilder(
    column: $table.coverUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rating => $composableBuilder(
    column: $table.rating,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get region => $composableBuilder(
    column: $table.region,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remarks => $composableBuilder(
    column: $table.remarks,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FavoritesTableAnnotationComposer
    extends Composer<_$AppDatabase, $FavoritesTable> {
  $$FavoritesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get sourceId =>
      $composableBuilder(column: $table.sourceId, builder: (column) => column);

  GeneratedColumn<int> get videoId =>
      $composableBuilder(column: $table.videoId, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get year =>
      $composableBuilder(column: $table.year, builder: (column) => column);

  GeneratedColumn<String> get coverUrl =>
      $composableBuilder(column: $table.coverUrl, builder: (column) => column);

  GeneratedColumn<String> get rating =>
      $composableBuilder(column: $table.rating, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get region =>
      $composableBuilder(column: $table.region, builder: (column) => column);

  GeneratedColumn<String> get remarks =>
      $composableBuilder(column: $table.remarks, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$FavoritesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FavoritesTable,
          Favorite,
          $$FavoritesTableFilterComposer,
          $$FavoritesTableOrderingComposer,
          $$FavoritesTableAnnotationComposer,
          $$FavoritesTableCreateCompanionBuilder,
          $$FavoritesTableUpdateCompanionBuilder,
          (Favorite, BaseReferences<_$AppDatabase, $FavoritesTable, Favorite>),
          Favorite,
          PrefetchHooks Function()
        > {
  $$FavoritesTableTableManager(_$AppDatabase db, $FavoritesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FavoritesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FavoritesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FavoritesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> sourceId = const Value.absent(),
                Value<int> videoId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> year = const Value.absent(),
                Value<String?> coverUrl = const Value.absent(),
                Value<String?> rating = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String?> region = const Value.absent(),
                Value<String?> remarks = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => FavoritesCompanion(
                id: id,
                sourceId: sourceId,
                videoId: videoId,
                title: title,
                year: year,
                coverUrl: coverUrl,
                rating: rating,
                type: type,
                region: region,
                remarks: remarks,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String sourceId,
                required int videoId,
                required String title,
                Value<String?> year = const Value.absent(),
                Value<String?> coverUrl = const Value.absent(),
                Value<String?> rating = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String?> region = const Value.absent(),
                Value<String?> remarks = const Value.absent(),
                required DateTime createdAt,
              }) => FavoritesCompanion.insert(
                id: id,
                sourceId: sourceId,
                videoId: videoId,
                title: title,
                year: year,
                coverUrl: coverUrl,
                rating: rating,
                type: type,
                region: region,
                remarks: remarks,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FavoritesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FavoritesTable,
      Favorite,
      $$FavoritesTableFilterComposer,
      $$FavoritesTableOrderingComposer,
      $$FavoritesTableAnnotationComposer,
      $$FavoritesTableCreateCompanionBuilder,
      $$FavoritesTableUpdateCompanionBuilder,
      (Favorite, BaseReferences<_$AppDatabase, $FavoritesTable, Favorite>),
      Favorite,
      PrefetchHooks Function()
    >;
typedef $$DownloadTasksTableCreateCompanionBuilder =
    DownloadTasksCompanion Function({
      Value<int> id,
      required String taskId,
      required int videoId,
      required String videoTitle,
      Value<String?> coverUrl,
      required List<EpisodeDownloadInfo> episodes,
      required DateTime createdAt,
      Value<DateTime?> completedAt,
    });
typedef $$DownloadTasksTableUpdateCompanionBuilder =
    DownloadTasksCompanion Function({
      Value<int> id,
      Value<String> taskId,
      Value<int> videoId,
      Value<String> videoTitle,
      Value<String?> coverUrl,
      Value<List<EpisodeDownloadInfo>> episodes,
      Value<DateTime> createdAt,
      Value<DateTime?> completedAt,
    });

class $$DownloadTasksTableFilterComposer
    extends Composer<_$AppDatabase, $DownloadTasksTable> {
  $$DownloadTasksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get taskId => $composableBuilder(
    column: $table.taskId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get videoId => $composableBuilder(
    column: $table.videoId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get videoTitle => $composableBuilder(
    column: $table.videoTitle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get coverUrl => $composableBuilder(
    column: $table.coverUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<
    List<EpisodeDownloadInfo>,
    List<EpisodeDownloadInfo>,
    String
  >
  get episodes => $composableBuilder(
    column: $table.episodes,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DownloadTasksTableOrderingComposer
    extends Composer<_$AppDatabase, $DownloadTasksTable> {
  $$DownloadTasksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get taskId => $composableBuilder(
    column: $table.taskId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get videoId => $composableBuilder(
    column: $table.videoId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get videoTitle => $composableBuilder(
    column: $table.videoTitle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get coverUrl => $composableBuilder(
    column: $table.coverUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get episodes => $composableBuilder(
    column: $table.episodes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DownloadTasksTableAnnotationComposer
    extends Composer<_$AppDatabase, $DownloadTasksTable> {
  $$DownloadTasksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get taskId =>
      $composableBuilder(column: $table.taskId, builder: (column) => column);

  GeneratedColumn<int> get videoId =>
      $composableBuilder(column: $table.videoId, builder: (column) => column);

  GeneratedColumn<String> get videoTitle => $composableBuilder(
    column: $table.videoTitle,
    builder: (column) => column,
  );

  GeneratedColumn<String> get coverUrl =>
      $composableBuilder(column: $table.coverUrl, builder: (column) => column);

  GeneratedColumnWithTypeConverter<List<EpisodeDownloadInfo>, String>
  get episodes =>
      $composableBuilder(column: $table.episodes, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );
}

class $$DownloadTasksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DownloadTasksTable,
          DownloadTask,
          $$DownloadTasksTableFilterComposer,
          $$DownloadTasksTableOrderingComposer,
          $$DownloadTasksTableAnnotationComposer,
          $$DownloadTasksTableCreateCompanionBuilder,
          $$DownloadTasksTableUpdateCompanionBuilder,
          (
            DownloadTask,
            BaseReferences<_$AppDatabase, $DownloadTasksTable, DownloadTask>,
          ),
          DownloadTask,
          PrefetchHooks Function()
        > {
  $$DownloadTasksTableTableManager(_$AppDatabase db, $DownloadTasksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DownloadTasksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DownloadTasksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DownloadTasksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> taskId = const Value.absent(),
                Value<int> videoId = const Value.absent(),
                Value<String> videoTitle = const Value.absent(),
                Value<String?> coverUrl = const Value.absent(),
                Value<List<EpisodeDownloadInfo>> episodes =
                    const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> completedAt = const Value.absent(),
              }) => DownloadTasksCompanion(
                id: id,
                taskId: taskId,
                videoId: videoId,
                videoTitle: videoTitle,
                coverUrl: coverUrl,
                episodes: episodes,
                createdAt: createdAt,
                completedAt: completedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String taskId,
                required int videoId,
                required String videoTitle,
                Value<String?> coverUrl = const Value.absent(),
                required List<EpisodeDownloadInfo> episodes,
                required DateTime createdAt,
                Value<DateTime?> completedAt = const Value.absent(),
              }) => DownloadTasksCompanion.insert(
                id: id,
                taskId: taskId,
                videoId: videoId,
                videoTitle: videoTitle,
                coverUrl: coverUrl,
                episodes: episodes,
                createdAt: createdAt,
                completedAt: completedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DownloadTasksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DownloadTasksTable,
      DownloadTask,
      $$DownloadTasksTableFilterComposer,
      $$DownloadTasksTableOrderingComposer,
      $$DownloadTasksTableAnnotationComposer,
      $$DownloadTasksTableCreateCompanionBuilder,
      $$DownloadTasksTableUpdateCompanionBuilder,
      (
        DownloadTask,
        BaseReferences<_$AppDatabase, $DownloadTasksTable, DownloadTask>,
      ),
      DownloadTask,
      PrefetchHooks Function()
    >;
typedef $$AppSettingsTableCreateCompanionBuilder =
    AppSettingsCompanion Function({
      Value<int> id,
      Value<String?> downloadPath,
      Value<bool> enableThumbnailPreview,
      Value<int> maxConcurrentDownloads,
      Value<int> segmentConcurrency,
      Value<String?> lastDataSourceId,
      Value<String?> cookieFile,
      Value<int> themeMode,
      Value<DateTime?> subscriptionCheckedAt,
      Value<double?> playerNormalWidth,
      Value<double?> playerNormalHeight,
      Value<double?> playerPipWidth,
      Value<double?> playerPipHeight,
      Value<double?> playerWindowX,
      Value<double?> playerWindowY,
      Value<double?> playerPipX,
      Value<double?> playerPipY,
      Value<String?> locale,
      Value<String?> searchHistory,
      Value<bool> showPet,
      Value<double?> petWindowX,
      Value<double?> petWindowY,
    });
typedef $$AppSettingsTableUpdateCompanionBuilder =
    AppSettingsCompanion Function({
      Value<int> id,
      Value<String?> downloadPath,
      Value<bool> enableThumbnailPreview,
      Value<int> maxConcurrentDownloads,
      Value<int> segmentConcurrency,
      Value<String?> lastDataSourceId,
      Value<String?> cookieFile,
      Value<int> themeMode,
      Value<DateTime?> subscriptionCheckedAt,
      Value<double?> playerNormalWidth,
      Value<double?> playerNormalHeight,
      Value<double?> playerPipWidth,
      Value<double?> playerPipHeight,
      Value<double?> playerWindowX,
      Value<double?> playerWindowY,
      Value<double?> playerPipX,
      Value<double?> playerPipY,
      Value<String?> locale,
      Value<String?> searchHistory,
      Value<bool> showPet,
      Value<double?> petWindowX,
      Value<double?> petWindowY,
    });

class $$AppSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get downloadPath => $composableBuilder(
    column: $table.downloadPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get enableThumbnailPreview => $composableBuilder(
    column: $table.enableThumbnailPreview,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get maxConcurrentDownloads => $composableBuilder(
    column: $table.maxConcurrentDownloads,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get segmentConcurrency => $composableBuilder(
    column: $table.segmentConcurrency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastDataSourceId => $composableBuilder(
    column: $table.lastDataSourceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cookieFile => $composableBuilder(
    column: $table.cookieFile,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get themeMode => $composableBuilder(
    column: $table.themeMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get subscriptionCheckedAt => $composableBuilder(
    column: $table.subscriptionCheckedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get playerNormalWidth => $composableBuilder(
    column: $table.playerNormalWidth,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get playerNormalHeight => $composableBuilder(
    column: $table.playerNormalHeight,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get playerPipWidth => $composableBuilder(
    column: $table.playerPipWidth,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get playerPipHeight => $composableBuilder(
    column: $table.playerPipHeight,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get playerWindowX => $composableBuilder(
    column: $table.playerWindowX,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get playerWindowY => $composableBuilder(
    column: $table.playerWindowY,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get playerPipX => $composableBuilder(
    column: $table.playerPipX,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get playerPipY => $composableBuilder(
    column: $table.playerPipY,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get locale => $composableBuilder(
    column: $table.locale,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get searchHistory => $composableBuilder(
    column: $table.searchHistory,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get showPet => $composableBuilder(
    column: $table.showPet,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get petWindowX => $composableBuilder(
    column: $table.petWindowX,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get petWindowY => $composableBuilder(
    column: $table.petWindowY,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AppSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get downloadPath => $composableBuilder(
    column: $table.downloadPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get enableThumbnailPreview => $composableBuilder(
    column: $table.enableThumbnailPreview,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get maxConcurrentDownloads => $composableBuilder(
    column: $table.maxConcurrentDownloads,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get segmentConcurrency => $composableBuilder(
    column: $table.segmentConcurrency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastDataSourceId => $composableBuilder(
    column: $table.lastDataSourceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cookieFile => $composableBuilder(
    column: $table.cookieFile,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get themeMode => $composableBuilder(
    column: $table.themeMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get subscriptionCheckedAt => $composableBuilder(
    column: $table.subscriptionCheckedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get playerNormalWidth => $composableBuilder(
    column: $table.playerNormalWidth,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get playerNormalHeight => $composableBuilder(
    column: $table.playerNormalHeight,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get playerPipWidth => $composableBuilder(
    column: $table.playerPipWidth,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get playerPipHeight => $composableBuilder(
    column: $table.playerPipHeight,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get playerWindowX => $composableBuilder(
    column: $table.playerWindowX,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get playerWindowY => $composableBuilder(
    column: $table.playerWindowY,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get playerPipX => $composableBuilder(
    column: $table.playerPipX,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get playerPipY => $composableBuilder(
    column: $table.playerPipY,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get locale => $composableBuilder(
    column: $table.locale,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get searchHistory => $composableBuilder(
    column: $table.searchHistory,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get showPet => $composableBuilder(
    column: $table.showPet,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get petWindowX => $composableBuilder(
    column: $table.petWindowX,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get petWindowY => $composableBuilder(
    column: $table.petWindowY,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AppSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get downloadPath => $composableBuilder(
    column: $table.downloadPath,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get enableThumbnailPreview => $composableBuilder(
    column: $table.enableThumbnailPreview,
    builder: (column) => column,
  );

  GeneratedColumn<int> get maxConcurrentDownloads => $composableBuilder(
    column: $table.maxConcurrentDownloads,
    builder: (column) => column,
  );

  GeneratedColumn<int> get segmentConcurrency => $composableBuilder(
    column: $table.segmentConcurrency,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastDataSourceId => $composableBuilder(
    column: $table.lastDataSourceId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get cookieFile => $composableBuilder(
    column: $table.cookieFile,
    builder: (column) => column,
  );

  GeneratedColumn<int> get themeMode =>
      $composableBuilder(column: $table.themeMode, builder: (column) => column);

  GeneratedColumn<DateTime> get subscriptionCheckedAt => $composableBuilder(
    column: $table.subscriptionCheckedAt,
    builder: (column) => column,
  );

  GeneratedColumn<double> get playerNormalWidth => $composableBuilder(
    column: $table.playerNormalWidth,
    builder: (column) => column,
  );

  GeneratedColumn<double> get playerNormalHeight => $composableBuilder(
    column: $table.playerNormalHeight,
    builder: (column) => column,
  );

  GeneratedColumn<double> get playerPipWidth => $composableBuilder(
    column: $table.playerPipWidth,
    builder: (column) => column,
  );

  GeneratedColumn<double> get playerPipHeight => $composableBuilder(
    column: $table.playerPipHeight,
    builder: (column) => column,
  );

  GeneratedColumn<double> get playerWindowX => $composableBuilder(
    column: $table.playerWindowX,
    builder: (column) => column,
  );

  GeneratedColumn<double> get playerWindowY => $composableBuilder(
    column: $table.playerWindowY,
    builder: (column) => column,
  );

  GeneratedColumn<double> get playerPipX => $composableBuilder(
    column: $table.playerPipX,
    builder: (column) => column,
  );

  GeneratedColumn<double> get playerPipY => $composableBuilder(
    column: $table.playerPipY,
    builder: (column) => column,
  );

  GeneratedColumn<String> get locale =>
      $composableBuilder(column: $table.locale, builder: (column) => column);

  GeneratedColumn<String> get searchHistory => $composableBuilder(
    column: $table.searchHistory,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get showPet =>
      $composableBuilder(column: $table.showPet, builder: (column) => column);

  GeneratedColumn<double> get petWindowX => $composableBuilder(
    column: $table.petWindowX,
    builder: (column) => column,
  );

  GeneratedColumn<double> get petWindowY => $composableBuilder(
    column: $table.petWindowY,
    builder: (column) => column,
  );
}

class $$AppSettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AppSettingsTable,
          AppSetting,
          $$AppSettingsTableFilterComposer,
          $$AppSettingsTableOrderingComposer,
          $$AppSettingsTableAnnotationComposer,
          $$AppSettingsTableCreateCompanionBuilder,
          $$AppSettingsTableUpdateCompanionBuilder,
          (
            AppSetting,
            BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>,
          ),
          AppSetting,
          PrefetchHooks Function()
        > {
  $$AppSettingsTableTableManager(_$AppDatabase db, $AppSettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> downloadPath = const Value.absent(),
                Value<bool> enableThumbnailPreview = const Value.absent(),
                Value<int> maxConcurrentDownloads = const Value.absent(),
                Value<int> segmentConcurrency = const Value.absent(),
                Value<String?> lastDataSourceId = const Value.absent(),
                Value<String?> cookieFile = const Value.absent(),
                Value<int> themeMode = const Value.absent(),
                Value<DateTime?> subscriptionCheckedAt = const Value.absent(),
                Value<double?> playerNormalWidth = const Value.absent(),
                Value<double?> playerNormalHeight = const Value.absent(),
                Value<double?> playerPipWidth = const Value.absent(),
                Value<double?> playerPipHeight = const Value.absent(),
                Value<double?> playerWindowX = const Value.absent(),
                Value<double?> playerWindowY = const Value.absent(),
                Value<double?> playerPipX = const Value.absent(),
                Value<double?> playerPipY = const Value.absent(),
                Value<String?> locale = const Value.absent(),
                Value<String?> searchHistory = const Value.absent(),
                Value<bool> showPet = const Value.absent(),
                Value<double?> petWindowX = const Value.absent(),
                Value<double?> petWindowY = const Value.absent(),
              }) => AppSettingsCompanion(
                id: id,
                downloadPath: downloadPath,
                enableThumbnailPreview: enableThumbnailPreview,
                maxConcurrentDownloads: maxConcurrentDownloads,
                segmentConcurrency: segmentConcurrency,
                lastDataSourceId: lastDataSourceId,
                cookieFile: cookieFile,
                themeMode: themeMode,
                subscriptionCheckedAt: subscriptionCheckedAt,
                playerNormalWidth: playerNormalWidth,
                playerNormalHeight: playerNormalHeight,
                playerPipWidth: playerPipWidth,
                playerPipHeight: playerPipHeight,
                playerWindowX: playerWindowX,
                playerWindowY: playerWindowY,
                playerPipX: playerPipX,
                playerPipY: playerPipY,
                locale: locale,
                searchHistory: searchHistory,
                showPet: showPet,
                petWindowX: petWindowX,
                petWindowY: petWindowY,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> downloadPath = const Value.absent(),
                Value<bool> enableThumbnailPreview = const Value.absent(),
                Value<int> maxConcurrentDownloads = const Value.absent(),
                Value<int> segmentConcurrency = const Value.absent(),
                Value<String?> lastDataSourceId = const Value.absent(),
                Value<String?> cookieFile = const Value.absent(),
                Value<int> themeMode = const Value.absent(),
                Value<DateTime?> subscriptionCheckedAt = const Value.absent(),
                Value<double?> playerNormalWidth = const Value.absent(),
                Value<double?> playerNormalHeight = const Value.absent(),
                Value<double?> playerPipWidth = const Value.absent(),
                Value<double?> playerPipHeight = const Value.absent(),
                Value<double?> playerWindowX = const Value.absent(),
                Value<double?> playerWindowY = const Value.absent(),
                Value<double?> playerPipX = const Value.absent(),
                Value<double?> playerPipY = const Value.absent(),
                Value<String?> locale = const Value.absent(),
                Value<String?> searchHistory = const Value.absent(),
                Value<bool> showPet = const Value.absent(),
                Value<double?> petWindowX = const Value.absent(),
                Value<double?> petWindowY = const Value.absent(),
              }) => AppSettingsCompanion.insert(
                id: id,
                downloadPath: downloadPath,
                enableThumbnailPreview: enableThumbnailPreview,
                maxConcurrentDownloads: maxConcurrentDownloads,
                segmentConcurrency: segmentConcurrency,
                lastDataSourceId: lastDataSourceId,
                cookieFile: cookieFile,
                themeMode: themeMode,
                subscriptionCheckedAt: subscriptionCheckedAt,
                playerNormalWidth: playerNormalWidth,
                playerNormalHeight: playerNormalHeight,
                playerPipWidth: playerPipWidth,
                playerPipHeight: playerPipHeight,
                playerWindowX: playerWindowX,
                playerWindowY: playerWindowY,
                playerPipX: playerPipX,
                playerPipY: playerPipY,
                locale: locale,
                searchHistory: searchHistory,
                showPet: showPet,
                petWindowX: petWindowX,
                petWindowY: petWindowY,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AppSettingsTable,
      AppSetting,
      $$AppSettingsTableFilterComposer,
      $$AppSettingsTableOrderingComposer,
      $$AppSettingsTableAnnotationComposer,
      $$AppSettingsTableCreateCompanionBuilder,
      $$AppSettingsTableUpdateCompanionBuilder,
      (
        AppSetting,
        BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>,
      ),
      AppSetting,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$VideosTableTableManager get videos =>
      $$VideosTableTableManager(_db, _db.videos);
  $$VideoSettingsTableTableManager get videoSettings =>
      $$VideoSettingsTableTableManager(_db, _db.videoSettings);
  $$VideoHistoryTableTableManager get videoHistory =>
      $$VideoHistoryTableTableManager(_db, _db.videoHistory);
  $$EpisodeHistoryTableTableManager get episodeHistory =>
      $$EpisodeHistoryTableTableManager(_db, _db.episodeHistory);
  $$EpisodeSkipDataTableTableManager get episodeSkipData =>
      $$EpisodeSkipDataTableTableManager(_db, _db.episodeSkipData);
  $$SubscriptionsTableTableManager get subscriptions =>
      $$SubscriptionsTableTableManager(_db, _db.subscriptions);
  $$FavoritesTableTableManager get favorites =>
      $$FavoritesTableTableManager(_db, _db.favorites);
  $$DownloadTasksTableTableManager get downloadTasks =>
      $$DownloadTasksTableTableManager(_db, _db.downloadTasks);
  $$AppSettingsTableTableManager get appSettings =>
      $$AppSettingsTableTableManager(_db, _db.appSettings);
}
