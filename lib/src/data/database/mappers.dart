import 'package:flutter/material.dart';
import 'package:drift/drift.dart';
import 'app_database.dart' as db; // Same directory
import '../../features/video/domain/video_collection.dart' as domain;
import '../../features/video/domain/video_settings.dart' as domain;
import '../../features/video/domain/play_history.dart' as domain;
import '../../features/download/domain/download_task.dart' as domain;
import '../../features/settings/domain/app_settings.dart' as domain;

// --- Video ---
extension VideoMapper on db.Video {
  domain.Video toDomain() {
    return domain.Video(
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
    );
  }
}

extension VideoCompanionMapper on domain.Video {
  db.VideosCompanion toCompanion() {
    return db.VideosCompanion.insert(
      id: id == 0 ? const Value.absent() : Value(id),
      sourceId: Value(sourceId),
      apiId: apiId,
      title: title,
      coverUrl: coverUrl,
      thumbUrl: Value(thumbUrl),
      backdropUrl: Value(backdropUrl),
      rating: rating,
      year: Value(year),
      region: Value(region),
      type: type,
      typeId: Value(typeId),
      typeId1: Value(typeId1),
      actor: Value(actor),
      blurb: Value(blurb),
      remarks: Value(remarks),
      version: Value(version),
      vip: Value(vip),
      vodTime: Value(vodTime),
      hits: Value(hits),
      genres: Value(genres ?? []),
      description: Value(description),
      content: Value(content),
      director: Value(director),
      writer: Value(writer),
      lang: Value(lang),
      urls: Value(urls ?? []),
    );
  }
}

// --- VideoSettings ---
extension VideoSettingMapper on db.VideoSetting {
  domain.VideoSettings toDomain() {
    return domain.VideoSettings(
      id: id,
      sourceId: sourceId,
      videoId: videoId,
      introDuration: introDuration,
      outroDuration: outroDuration,
      autoSkip: autoSkip,
    );
  }
}

extension VideoSettingsCompanionMapper on domain.VideoSettings {
  db.VideoSettingsCompanion toCompanion() {
    return db.VideoSettingsCompanion.insert(
      id: id == 0 ? const Value.absent() : Value(id),
      sourceId: Value(sourceId),
      videoId: videoId,
      introDuration: Value(introDuration),
      outroDuration: Value(outroDuration),
      autoSkip: Value(autoSkip),
    );
  }
}

// --- VideoHistory ---
extension VideoHistoryMapper on db.VideoHistoryData {
  domain.VideoHistory toDomain() {
    return domain.VideoHistory(
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
    );
  }
}

extension VideoHistoryCompanionMapper on domain.VideoHistory {
  db.VideoHistoryCompanion toCompanion() {
    return db.VideoHistoryCompanion.insert(
      id: id == 0 ? const Value.absent() : Value(id),
      sourceId: Value(sourceId),
      videoId: videoId,
      videoTitle: videoTitle,
      coverUrl: coverUrl,
      rating: Value(rating),
      type: type,
      region: Value(region),
      year: Value(year),
      actor: Value(actor),
      version: Value(version),
      hits: Value(hits),
      remarks: Value(remarks),
      blurb: Value(blurb),
      lastEpisodeIndex: lastEpisodeIndex,
      lastEpisodeTitle: Value(lastEpisodeTitle),
      updatedAt: updatedAt,
    );
  }
}

// --- AppSettings ---
extension AppSettingMapper on db.AppSetting {
  domain.AppSettings toDomain() {
    return domain.AppSettings()
      ..id = id
      ..downloadPath = downloadPath
      ..maxConcurrentDownloads = maxConcurrentDownloads
      ..segmentConcurrency = segmentConcurrency
      ..lastDataSourceId = lastDataSourceId
      ..cookieFile = cookieFile
      ..themeMode = ThemeMode.values[themeMode]
      ..playerNormalWidth = playerNormalWidth
      ..playerNormalHeight = playerNormalHeight
      ..playerPipWidth = playerPipWidth
      ..playerPipHeight = playerPipHeight
      ..locale = locale;
  }
}

extension AppSettingsCompanionMapper on domain.AppSettings {
  db.AppSettingsCompanion toCompanion() {
    return db.AppSettingsCompanion.insert(
      id: Value(id <= 0 ? domain.AppSettings.singletonId : id),
      downloadPath: Value(downloadPath),
      maxConcurrentDownloads: Value(maxConcurrentDownloads),
      segmentConcurrency: Value(segmentConcurrency),
      lastDataSourceId: Value(lastDataSourceId),
      cookieFile: Value(cookieFile),
      themeMode: Value(themeMode.index),
      playerNormalWidth: Value(playerNormalWidth),
      playerNormalHeight: Value(playerNormalHeight),
      playerPipWidth: Value(playerPipWidth),
      playerPipHeight: Value(playerPipHeight),
      locale: Value(locale),
    );
  }
}

// --- EpisodeHistory ---
extension EpisodeHistoryMapper on db.EpisodeHistoryData {
  domain.EpisodeHistory toDomain() {
    return domain.EpisodeHistory(
      id: id,
      sourceId: sourceId,
      videoId: videoId,
      episodeIndex: episodeIndex,
      positionMillis: positionMillis,
      durationMillis: durationMillis,
      updatedAt: updatedAt,
    );
  }
}

extension EpisodeHistoryCompanionMapper on domain.EpisodeHistory {
  db.EpisodeHistoryCompanion toCompanion() {
    return db.EpisodeHistoryCompanion.insert(
      id: id == 0 ? const Value.absent() : Value(id),
      sourceId: Value(sourceId),
      videoId: videoId,
      episodeIndex: episodeIndex,
      positionMillis: positionMillis,
      durationMillis: durationMillis,
      updatedAt: updatedAt,
    );
  }
}

// --- DownloadTask ---
extension DownloadTaskMapper on db.DownloadTask {
  domain.DownloadTask toDomain() {
    return domain.DownloadTask(
      taskId: taskId,
      videoId: videoId,
      videoTitle: videoTitle,
      coverUrl: coverUrl,
      episodes: episodes,
      createdAt: createdAt,
      completedAt: completedAt,
    )..id = id;
  }
}

extension DownloadTaskCompanionMapper on domain.DownloadTask {
  db.DownloadTasksCompanion toCompanion() {
    return db.DownloadTasksCompanion.insert(
      id: id == 0 ? const Value.absent() : Value(id),
      taskId: taskId,
      videoId: videoId,
      videoTitle: videoTitle,
      coverUrl: Value(coverUrl),
      episodes: episodes,
      createdAt: createdAt,
      completedAt: Value(completedAt),
    );
  }
}
