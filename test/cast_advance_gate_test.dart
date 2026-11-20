import 'package:flutter_test/flutter_test.dart';
import 'package:vidra/src/features/cast/presentation/cast_provider.dart';

void main() {
  bool landed(int pos, int stale, int since) => CastController.advanceLanded(
    position: Duration(seconds: pos),
    staleFrom: Duration(seconds: stale),
    sinceChange: Duration(seconds: since),
  );

  test(
    'the old track\'s dying seconds are not the new episode\'s position',
    () {
      // Old episode was at 44:50; the renderer still says 44:52 under the new
      // index two seconds after the change.
      expect(landed(2692, 2690, 2), isFalse);
      // The new episode has really started.
      expect(landed(3, 2690, 6), isTrue);
      // A renderer that never reports lower is believed after half a minute.
      expect(landed(2692, 2690, 31), isTrue);
    },
  );
}
