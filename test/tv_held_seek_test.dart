import 'package:flutter_test/flutter_test.dart';
import 'package:vidra/src/features/video/presentation/video_player_screen.dart';

void main() {
  test('a held seek key speeds up, a tap does not', () {
    expect(tvHeldSeekSeconds(0), isNull);
    expect(tvHeldSeekSeconds(7), isNull);
    expect(tvHeldSeekSeconds(8), 15);
    expect(tvHeldSeekSeconds(23), 15);
    expect(tvHeldSeekSeconds(24), 60);
  });
}
