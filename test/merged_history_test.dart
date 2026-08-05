// The two catalogs number the same show differently — olevod files 第1集 where
// dbku files 第01集 — and carry different counts of it, 14 against 15 on the
// titles compared locally. Every test here exists because mapping progress
// across by ARRAY INDEX passes under exactly one of those conditions and marks
// the wrong episode under the other, and a wrongly ticked episode is
// indistinguishable, on screen, from the app having lost the viewer's place.

import 'package:flutter_test/flutter_test.dart';
import 'package:vidra/src/features/video/domain/merged_history.dart';
import 'package:vidra/src/features/video/domain/play_history.dart';
import 'package:vidra/src/features/video/domain/video_collection.dart';

void main() {
  List<VideoEpisode> titled(Iterable<String> titles) => [
    for (final t in titles) VideoEpisode(title: t),
  ];

  /// olevod's spelling: 第1集 … 第N集, unpadded.
  List<VideoEpisode> unpadded(int from, int to) =>
      titled([for (var n = from; n <= to; n++) '第$n集']);

  /// dbku's spelling: the same episodes, zero padded to two digits.
  List<VideoEpisode> padded(int from, int to) => titled([
    for (var n = from; n <= to; n++) '第${n.toString().padLeft(2, '0')}集',
  ]);

  EpisodeHistory watched(
    int index, {
    required String source,
    int videoId = 1,
    int position = 60000,
    int duration = 120000,
    DateTime? at,
  }) => EpisodeHistory(
    sourceId: source,
    videoId: videoId,
    episodeIndex: index,
    positionMillis: position,
    durationMillis: duration,
    updatedAt: at ?? DateTime(2026, 8, 1),
  );

  test(
    'this source answers for its own episodes even when it answers worse',
    () {
      final local = {2: watched(2, source: 'olevod', position: 30000)};
      final merged = mergeHistoriesByEpisodeNumber(
        localEpisodes: unpadded(1, 14),
        localHistories: local,
        otherEpisodes: padded(1, 15),
        // Further in AND more recent, and still the wrong answer: it measures a
        // different encode, so 90s into dbku's file is not 90s into olevod's.
        otherHistories: {
          2: watched(
            2,
            source: 'dbku',
            position: 90000,
            at: DateTime(2026, 8, 4),
          ),
        },
        episodic: true,
      );

      expect(merged[2]!.sourceId, 'olevod');
      expect(merged[2]!.positionMillis, 30000);
    },
  );

  test('zero padding on the other side does not hide the same episode', () {
    final merged = mergeHistoriesByEpisodeNumber(
      localEpisodes: unpadded(1, 14),
      localHistories: const {},
      otherEpisodes: padded(1, 15),
      otherHistories: {6: watched(6, source: 'dbku')},
      episodic: true,
    );

    // 第7集 and 第07集 are one episode; nothing else on either list is touched.
    expect(merged[6]!.sourceId, 'dbku');
    expect(merged.keys, [6]);
  });

  test('the borrowed row follows the number, not the row it sat in', () {
    // The clearest case the index shortcut gets wrong: this catalog's list
    // begins at 第2集 (the pilot is missing here), so every episode sits one row
    // earlier than it does on the other side.
    final merged = mergeHistoriesByEpisodeNumber(
      localEpisodes: unpadded(2, 15),
      localHistories: const {},
      otherEpisodes: padded(1, 15),
      otherHistories: {4: watched(4, source: 'dbku', videoId: 77)},
      episodic: true,
    );

    // Row 4 over there is 第05集; here 第5集 is row 3.
    expect(merged.keys, [3]);
    // Carried through untouched. Those three fields still describe the dbku
    // row, which is what a "continue on the other source" action opens and what
    // stops a save against this tile writing over the wrong catalog's progress.
    expect(merged[3]!.sourceId, 'dbku');
    expect(merged[3]!.videoId, 77);
    expect(merged[3]!.episodeIndex, 4);
  });

  test('an episode this catalog does not carry is dropped, not appended', () {
    final local = <int, EpisodeHistory>{};
    final merged = mergeHistoriesByEpisodeNumber(
      localEpisodes: unpadded(1, 14),
      localHistories: local,
      otherEpisodes: padded(1, 15),
      // 第15集 exists only over there — a bonus instalment this catalog never
      // listed. There is no tile for it and inventing key 14 would hand the
      // episode grid an index past the end of its own list.
      otherHistories: {14: watched(14, source: 'dbku')},
      episodic: true,
    );

    expect(merged, isEmpty);
    // Nothing borrowed means the caller keeps the map it already had, so the
    // tiles have no reason to repaint.
    expect(identical(merged, local), isTrue);
  });

  test('an episode with no readable number gets nothing', () {
    final merged = mergeHistoriesByEpisodeNumber(
      // A dubbed track parked mid-list, which happens on both catalogs.
      localEpisodes: titled(['第1集', '粤语版', '第3集']),
      localHistories: const {},
      otherEpisodes: padded(1, 3),
      otherHistories: {
        0: watched(0, source: 'dbku'),
        1: watched(1, source: 'dbku'),
        2: watched(2, source: 'dbku'),
      },
      episodic: true,
    );

    // 粤语版 states no number, so it is left blank rather than being handed
    // 第02集's progress by virtue of sitting in row 1. 第02集's progress is then
    // dropped entirely — no local episode claims it.
    expect(merged.keys, unorderedEquals([0, 2]));
    expect(merged[1], isNull);
  });

  test('one number listed twice resolves to the later viewing', () {
    // A re-upload beside the original: both rows are 第02集, so the only
    // question is which viewing says where the viewer is now.
    Map<int, EpisodeHistory> mergeWithNewerAt(int row) =>
        mergeHistoriesByEpisodeNumber(
          localEpisodes: unpadded(1, 2),
          localHistories: const {},
          otherEpisodes: titled(['第01集', '第02集', '第02集']),
          otherHistories: {
            1: watched(
              1,
              source: 'dbku',
              at: row == 1 ? DateTime(2026, 8, 4) : DateTime(2026, 7, 1),
            ),
            2: watched(
              2,
              source: 'dbku',
              at: row == 2 ? DateTime(2026, 8, 4) : DateTime(2026, 7, 1),
            ),
          },
          episodic: true,
        );

    // Asserted from both directions, because "the last row wins" would pass one
    // of these on its own.
    expect(mergeWithNewerAt(2)[1]!.episodeIndex, 2);
    expect(mergeWithNewerAt(1)[1]!.episodeIndex, 1);
  });

  test('a film borrows nothing, even when its lines look numbered', () {
    // Films park their audio tracks and mirrors in the episode list, and some
    // catalogs name them '1' and '2'. Those are ways to play one thing, so
    // track 2 on dbku is not track 2 on olevod and the numbers are a
    // coincidence — the type is the only thing that knows.
    final local = {0: watched(0, source: 'olevod')};
    final args = (
      localEpisodes: titled(['1', '2']),
      localHistories: local,
      otherEpisodes: titled(['1', '2']),
      otherHistories: {1: watched(1, source: 'dbku')},
    );

    final film = mergeHistoriesByEpisodeNumber(
      localEpisodes: args.localEpisodes,
      localHistories: args.localHistories,
      otherEpisodes: args.otherEpisodes,
      otherHistories: args.otherHistories,
      episodic: false,
    );
    expect(identical(film, local), isTrue);

    // Same input, episodic: the flag is what stopped it, not the titles.
    final show = mergeHistoriesByEpisodeNumber(
      localEpisodes: args.localEpisodes,
      localHistories: args.localHistories,
      otherEpisodes: args.otherEpisodes,
      otherHistories: args.otherHistories,
      episodic: true,
    );
    expect(show[1]!.sourceId, 'dbku');
  });

  test('a blank row among numbered ones does not take its position as its '
      'number', () {
    // The list opens with an unnamed row, so from index 1 on, position and
    // episode number are off by one. Numbering the blank by its position hands
    // index 1 the number 2 — the same number 第2集 at index 2 legitimately
    // carries — and both tiles then borrow episode 2's progress, one of them
    // showing a checkmark for an episode the viewer never opened.
    final merged = mergeHistoriesByEpisodeNumber(
      localEpisodes: titled(['', '第2集', '第3集']),
      localHistories: const {},
      otherEpisodes: padded(1, 3),
      otherHistories: {
        0: watched(0, source: 'dbku'),
        1: watched(1, source: 'dbku'),
        2: watched(2, source: 'dbku'),
      },
      episodic: true,
    );

    expect(merged.containsKey(0), isFalse, reason: 'the blank row is refused');
    expect(merged[1]!.episodeIndex, 1, reason: '第2集 borrows 第02集');
    expect(merged[2]!.episodeIndex, 2, reason: '第3集 borrows 第03集');
  });

  test('a list that is unnamed THROUGHOUT still counts in order', () {
    // The refusal above keys on a numbered neighbour, not on blankness itself.
    // A source that ships no titles at all is still listing episodes in order,
    // and position is the only numbering there is — refusing here would drop
    // every borrow for that catalog rather than one ambiguous row.
    final merged = mergeHistoriesByEpisodeNumber(
      localEpisodes: [VideoEpisode(), VideoEpisode(), VideoEpisode()],
      localHistories: const {},
      otherEpisodes: padded(1, 3),
      otherHistories: {1: watched(1, source: 'dbku')},
      episodic: true,
    );

    expect(merged[1]!.episodeIndex, 1);
  });
}
