import 'package:flutter_test/flutter_test.dart';
import 'package:vidra/src/pet/pixel_sprite.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'the shipped spritesheet loads and slices into five 48x64 cells',
    () async {
      final frames = await PixelCatSprites.frames();
      expect(frames.length, PixelFrame.values.length);
      for (final image in frames.values) {
        expect((image.width, image.height), (48, 64));
      }
    },
  );

  test('walk alternates the two stride poses', () {
    final seen = [for (var i = 0; i < 4; i++) PixelChoreography.walkFrameAt(i)];
    expect(seen, const [
      PixelFrame.walk1,
      PixelFrame.walk2,
      PixelFrame.walk1,
      PixelFrame.walk2,
    ]);
  });

  test('spritesheet cells are indexed in PixelFrame order', () {
    // The slicer reads cell i at x = i * 48; the enum order IS the sheet
    // contract, so a reorder must fail loudly here.
    expect(PixelFrame.values.map((f) => f.index).toList(), [0, 1, 2, 3, 4, 5]);
    expect(PixelFrame.values.last, PixelFrame.blink);
  });
}
