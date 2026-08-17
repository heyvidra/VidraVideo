// vidraDlp keeps `<output>.vidradlp.tmp` and a `.tmp.hls` manifest so an
// interrupted download can carry on. This app never carries one on — a failed
// or cancelled episode restarts from scratch — and nothing deleted them, so
// every interruption left a partial behind permanently.
//
// The sweep that fixes that runs at startup, which is exactly when it is most
// dangerous: an installed build and a debug build DO run side by side against
// the same downloads folder, and one of them may be mid-download. The age gate
// is what stops the sweep eating the other one's partial, so it is the part
// worth pinning.

import 'package:flutter_test/flutter_test.dart';
import 'package:vidra/src/core/services/download_service.dart';

void main() {
  final now = DateTime(2026, 8, 17, 20, 30);
  const age = Duration(minutes: 10);

  bool sweepable(DateTime lastModified) => DownloadService.sweepable(
    lastModified: lastModified,
    now: now,
    minimumAge: age,
  );

  test('a partial being written right now is left alone', () {
    // The case this exists for: another copy of the app is downloading into
    // this folder. Its temp is rewritten continuously, so it reads as seconds
    // old — and deleting it would destroy a download in progress.
    expect(sweepable(now), isFalse);
    expect(sweepable(now.subtract(const Duration(seconds: 30))), isFalse);
    expect(sweepable(now.subtract(const Duration(minutes: 9))), isFalse);
  });

  test('a leftover nobody has touched is swept', () {
    expect(sweepable(now.subtract(const Duration(minutes: 11))), isTrue);
    expect(sweepable(now.subtract(const Duration(hours: 6))), isTrue);
    expect(sweepable(now.subtract(const Duration(days: 30))), isTrue);
  });

  test('the boundary itself sweeps, and is not off by a tick', () {
    expect(sweepable(now.subtract(age)), isTrue);
    expect(
      sweepable(now.subtract(age - const Duration(milliseconds: 1))),
      isFalse,
    );
  });

  test('a clock that jumped backwards does not license a delete', () {
    // A file stamped in the future yields a negative difference. Treating that
    // as "old enough" would sweep a live partial on any machine whose clock
    // just moved — the one input where a naive `<` comparison is wrong.
    expect(sweepable(now.add(const Duration(hours: 1))), isFalse);
  });
}
