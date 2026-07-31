// What a recent-play card says it is showing.
//
// Sources file a film's playback lines under the episode list and name them
// 立即播放 / 粤语播放 / 英语播放 — audio tracks and mirrors, not instalments.
// Echoing one back produced "看到 立即播放", so films are located by timestamp
// and only episodic content gets a "which one".

import 'package:flutter_test/flutter_test.dart';
import 'package:vidra/src/features/video/domain/play_history.dart';

void main() {
  test('films are not episodic; series and variety shows are', () {
    expect(isEpisodicType('电影'), isFalse);
    expect(isEpisodicType('电视剧'), isTrue);
    expect(isEpisodicType('陆剧'), isTrue);
    expect(isEpisodicType('综艺'), isTrue);
    expect(
      isEpisodicType(null),
      isTrue,
      reason: 'unknown defaults to episodic',
    );
  });

  test('progress comes from the episode actually stopped on', () {
    final entry = RecentPlayback(
      video: VideoHistory(
        videoId: 1,
        videoTitle: '金刚不坏',
        coverUrl: 'c',
        type: '电影',
        lastEpisodeIndex: 0,
        lastEpisodeTitle: '立即播放',
      ),
      lastEpisode: EpisodeHistory(
        videoId: 1,
        episodeIndex: 0,
        positionMillis: 933000,
        durationMillis: 2725000,
      ),
    );

    expect(entry.position, const Duration(milliseconds: 933000));
    expect(entry.progress, closeTo(0.342, 0.005));
  });

  test('a row with no episode history reports no progress, not a crash', () {
    final entry = RecentPlayback(
      video: VideoHistory(
        videoId: 2,
        videoTitle: 'x',
        coverUrl: 'c',
        type: '电视剧',
        lastEpisodeIndex: 3,
      ),
    );

    expect(entry.progress, 0.0);
    expect(entry.position, Duration.zero);
  });

  test('a zero-duration episode does not divide by zero', () {
    final entry = RecentPlayback(
      video: VideoHistory(
        videoId: 3,
        videoTitle: 'x',
        coverUrl: 'c',
        type: '电影',
        lastEpisodeIndex: 0,
      ),
      lastEpisode: EpisodeHistory(
        videoId: 3,
        episodeIndex: 0,
        positionMillis: 5000,
        durationMillis: 0,
      ),
    );

    expect(entry.progress, 0.0);
  });
}
