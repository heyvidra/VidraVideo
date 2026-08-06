// "Mark as watched" writes the same shape playback writes — position ==
// duration — rather than inventing a separate flag, so every reader that
// already knows what finished looks like picks it up unchanged: the tile
// checkmark (progress > 0.9), the resume target (>= kEpisodeFinishedRatio),
// the cross-source badge.
//
// The two things worth pinning: an episode with a REAL duration keeps it (only
// the position moves to the end, so a later resume is not measured against a
// fabricated length), and an episode never opened still reads as finished.

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vidra/src/data/database/app_database.dart' show AppDatabase;
import 'package:vidra/src/features/video/data/history_repository.dart';
import 'package:vidra/src/features/video/domain/play_history.dart';
import 'package:vidra/src/features/video/domain/resume_target.dart';

/// The write the menu action performs, in the same order, against the real
/// repository — this is the code that would regress.
Future<void> markWatched(
  HistoryRepository repo, {
  required int videoId,
  required String sourceId,
  required int episodeCount,
}) async {
  for (var i = 0; i < episodeCount; i++) {
    final existing = await repo.getEpisodeHistory(videoId, i, sourceId);
    final duration = (existing?.durationMillis ?? 0) > 0
        ? existing!.durationMillis
        : 1;
    await repo.saveEpisodeHistory(
      EpisodeHistory(
        id: existing?.id ?? 0,
        sourceId: sourceId,
        videoId: videoId,
        episodeIndex: i,
        positionMillis: duration,
        durationMillis: duration,
      ),
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('every episode reads as finished, real durations survive', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = HistoryRepository(db, 'dbku');

    // Episode 1 was genuinely watched a third of the way through a 30-minute
    // instalment; episodes 0 and 2 were never opened.
    await repo.saveEpisodeHistory(
      EpisodeHistory(
        sourceId: 'dbku',
        videoId: 42,
        episodeIndex: 1,
        positionMillis: 600000,
        durationMillis: 1800000,
      ),
    );

    await markWatched(repo, videoId: 42, sourceId: 'dbku', episodeCount: 3);

    final rows = await repo.getEpisodeHistories(42, 'dbku');
    expect(rows, hasLength(3));

    for (final row in rows) {
      expect(row.durationMillis, greaterThan(0));
      expect(
        row.positionMillis / row.durationMillis,
        greaterThanOrEqualTo(kEpisodeFinishedRatio),
        reason: 'episode ${row.episodeIndex} must read as finished',
      );
    }

    // The real duration is kept, not replaced by the 1/1 sentinel — a resume
    // measured against a fabricated length would put the viewer anywhere.
    final watched = rows.firstWhere((r) => r.episodeIndex == 1);
    expect(watched.durationMillis, 1800000);
    expect(watched.positionMillis, 1800000);
  });

  test('marking twice is idempotent, not duplicated', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = HistoryRepository(db, 'dbku');

    await markWatched(repo, videoId: 7, sourceId: 'dbku', episodeCount: 2);
    await markWatched(repo, videoId: 7, sourceId: 'dbku', episodeCount: 2);

    // saveEpisodeHistory preserves the existing row id, so a second pass
    // updates rather than inserting a parallel set.
    expect(await repo.getEpisodeHistories(7, 'dbku'), hasLength(2));
  });

  test(
    'a marked show resumes at its finale rather than starting over',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final repo = HistoryRepository(db, 'dbku');

      await markWatched(repo, videoId: 9, sourceId: 'dbku', episodeCount: 4);
      final rows = await repo.getEpisodeHistories(9, 'dbku');
      final map = {for (final r in rows) r.episodeIndex: r};

      final target = resolveResumeTarget(
        histories: map,
        lastEpisodeIndex: 3,
        episodeCount: 4,
      );
      // Nothing left to advance to: the last episode is finished and there is no
      // episode 5, so it offers the finale rather than silently bouncing to 1.
      expect(target.episodeIndex, 3);
      expect(target.isFirstTime, isFalse);
    },
  );
}
