// The one rule three surfaces share for "which episode does continue-watching
// open". The detail page's main button used to ignore history entirely and
// always open episode 1, so a viewer on episode 12 got sent back to the start
// by the biggest button on the page.

import 'package:flutter_test/flutter_test.dart';
import 'package:vidra/src/features/video/domain/play_history.dart';
import 'package:vidra/src/features/video/domain/resume_target.dart';

EpisodeHistory _h(int index, int pos, int dur) => EpisodeHistory(
  videoId: 1,
  episodeIndex: index,
  positionMillis: pos,
  durationMillis: dur,
);

void main() {
  test('no history at all reads as a first play', () {
    final t = resolveResumeTarget(histories: const {}, episodeCount: 10);
    expect(t.isFirstTime, isTrue);
    expect(t.episodeIndex, 0);
  });

  test('resumes the remembered episode, not the first one', () {
    final t = resolveResumeTarget(
      histories: {11: _h(11, 600000, 2400000)},
      lastEpisodeIndex: 11,
      episodeCount: 20,
    );
    expect(t.episodeIndex, 11);
    expect(t.isFirstTime, isFalse);
    expect(t.progress, closeTo(0.25, 0.01));
  });

  test('a finished episode advances to the next one', () {
    final t = resolveResumeTarget(
      histories: {3: _h(3, 2390000, 2400000)},
      lastEpisodeIndex: 3,
      episodeCount: 10,
    );
    expect(t.episodeIndex, 4);
    expect(t.advanced, isTrue);
  });

  test(
    'the last episode finished stays put rather than running off the end',
    () {
      final t = resolveResumeTarget(
        histories: {9: _h(9, 2390000, 2400000)},
        lastEpisodeIndex: 9,
        episodeCount: 10,
      );
      expect(t.episodeIndex, 9);
      expect(t.advanced, isFalse);
    },
  );

  test(
    'a stale index from a shortened source is clamped, not passed through',
    () {
      // Opening a player at an index the episode list no longer has leaves it
      // with nothing to play.
      final t = resolveResumeTarget(
        histories: const {},
        lastEpisodeIndex: 40,
        episodeCount: 12,
      );
      expect(t.episodeIndex, 11);
    },
  );

  test(
    'falls back to the most recently touched episode without a video row',
    () {
      final t = resolveResumeTarget(
        histories: {
          1: EpisodeHistory(
            videoId: 1,
            episodeIndex: 1,
            positionMillis: 100,
            durationMillis: 1000,
            updatedAt: DateTime(2026, 1, 1),
          ),
          7: EpisodeHistory(
            videoId: 1,
            episodeIndex: 7,
            positionMillis: 100,
            durationMillis: 1000,
            updatedAt: DateTime(2026, 6, 1),
          ),
        },
        episodeCount: 20,
      );
      expect(t.episodeIndex, 7);
    },
  );

  // Newest-wins across catalogs: 1-15 watched here, 16-21 continued on the
  // other source days later. The chip said 看到 第15集 and the button offered
  // 第16集 because the other catalog was only consulted when this one had
  // nothing at all.
  group('crossSourceResumeOverride', () {
    EpisodeHistory row(int index, DateTime at) => EpisodeHistory(
      videoId: 1,
      episodeIndex: index,
      positionMillis: 100,
      durationMillis: 1000,
      updatedAt: at,
    );
    CrossSourceWatch watch(DateTime at) => CrossSourceWatch(
      sourceId: 'olevod',
      videoId: 2,
      lastEpisodeIndex: 20,
      lastEpisodeTitle: '第21集',
      updatedAt: at,
    );

    test('a newer viewing elsewhere outranks the local rows', () {
      final match = watch(DateTime(2026, 8, 9));
      final got = crossSourceResumeOverride(
        match: match,
        histories: {14: row(14, DateTime(2026, 8, 5))},
      );
      expect(got, same(match));
    });

    test('an older viewing elsewhere leaves the local resume alone', () {
      final got = crossSourceResumeOverride(
        match: watch(DateTime(2026, 8, 1)),
        histories: {14: row(14, DateTime(2026, 8, 5))},
      );
      expect(got, isNull);
    });

    test('no local history at all: the other catalog wins by default', () {
      final match = watch(DateTime(2026, 8, 1));
      final got = crossSourceResumeOverride(match: match, histories: const {});
      expect(got, same(match));
    });

    test('a tie is not newer — the local row stands', () {
      final at = DateTime(2026, 8, 5);
      final got = crossSourceResumeOverride(
        match: watch(at),
        histories: {14: row(14, at)},
      );
      expect(got, isNull);
    });

    test('lastWriteAt counts even when the episode rows are gone', () {
      final got = crossSourceResumeOverride(
        match: watch(DateTime(2026, 8, 1)),
        histories: const {},
        lastWriteAt: DateTime(2026, 8, 5),
      );
      expect(got, isNull);
    });

    test('no match, no override', () {
      final got = crossSourceResumeOverride(match: null, histories: const {});
      expect(got, isNull);
    });
  });
}
