// Tool, not a test of the app: slices the pixel sprites out of the
// character design sheet and bakes assets/pixel_cat_spritesheet.png
// (288x64, idle|walk1|walk2|jump|wink|blink — blink is derived from idle).
// Skipped unless PET_SHEET points at the sheet image:
//
//   PET_SHEET=~/Downloads/flutter_pet_character_design.png \
//     flutter test test/spritesheet_extractor_test.dart
//
// The crop boxes below are for that sheet's 1536x1024 layout.
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _boxes = <String, Rect>{
  'idle': Rect.fromLTRB(573, 420, 716, 568),
  'walk1': Rect.fromLTRB(781, 420, 911, 568),
  'walk2': Rect.fromLTRB(968, 420, 1106, 568),
  'jump': Rect.fromLTRB(1122, 383, 1282, 565),
  'wink': Rect.fromLTRB(1341, 422, 1486, 568),
};

const _cream = Color(0xFFF5F0E6);
const _black = Color(0xFF262227);
const _pink = Color(0xFFF4C7CE);
const _white = Color(0xFFFFFFFF);
const _transparent = Color(0x00000000);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final sheetPath = Platform.environment['PET_SHEET'];

  test('extract spritesheet', skip: sheetPath == null, () async {
    final bytes = File(sheetPath!).readAsBytesSync();
    final codec = await ui.instantiateImageCodec(bytes);
    final sheet = (await codec.getNextFrame()).image;

    // Pass 1: crop and key every frame at native resolution, and measure
    // the opaque bounding box + the shadow's horizontal centre.
    final keyedFrames = <ui.Image>[];
    final boxes = <_BBox>[];
    for (final box in _boxes.values) {
      final crop = await _draw(box.width.toInt(), box.height.toInt(), (canvas) {
        canvas.drawImageRect(
          sheet,
          box,
          Rect.fromLTWH(0, 0, box.width, box.height),
          Paint()..filterQuality = FilterQuality.none,
        );
      });
      final keyed = await _keyBackdrop(crop);
      keyedFrames.add(keyed);
      boxes.add(await _measure(keyed));
    }

    // One scale for EVERY frame, from the widest bounding box: per-frame
    // fit-scaling is what made the cat change size between frames and the
    // animation shudder.
    final maxW = boxes.map((b) => b.width).reduce((a, b) => a > b ? a : b);
    final scale = 47.0 / maxW;

    // Pass 2: scale each frame identically, feet (shadow bottom) on a shared
    // baseline, shadow centre on the cell's midline.
    final cells = <ui.Image>[];
    for (var i = 0; i < keyedFrames.length; i++) {
      final b = boxes[i];
      final dstW = b.width * scale;
      final dstH = b.height * scale;
      // Shadow-centre alignment, then clamped into the cell: the jump pose
      // leans, its shadow sits off-centre, and un-clamped alignment pushed
      // the tail past the cell's right edge.
      final dstX = (22.0 - (b.shadowCenterX - b.minX) * scale).clamp(
        0.0,
        48.0 - dstW,
      );
      final dstY = 62.0 - dstH;
      final small = await _draw(48, 64, (canvas) {
        canvas.drawImageRect(
          keyedFrames[i],
          Rect.fromLTWH(
            b.minX.toDouble(),
            b.minY.toDouble(),
            b.width.toDouble(),
            b.height.toDouble(),
          ),
          Rect.fromLTWH(dstX.roundToDouble(), dstY.roundToDouble(), dstW, dstH),
          Paint()..filterQuality = FilterQuality.medium,
        );
      });
      cells.add(await _classify(small));
    }

    // The sheet's 走路1/走路2 are two nearly identical drawings — a pixel
    // diff shows no alternating stride, so played back they twitch instead
    // of stepping. Synthesize the opposite stride from walk1 itself: first
    // symmetrise its shadow (so the shared ground doesn't flip sides), then
    // mirror the leg band. Same drawing everywhere else, so only the legs
    // move between the two stride frames.
    cells[1] = await _symmetriseShadow(cells[1]);
    cells[2] = await _mirrorLegBand(cells[1]);

    // Blink is idle with its eyes shut — derived from the SAME drawing, so
    // an idle<->blink swap moves nothing but the eyes. A sixth sheet cell
    // rather than a runtime effect, so hand-drawn sheets can override it.
    cells.add(await _deriveBlink(cells[0]));

    final strip = await _draw(48 * cells.length, 64, (canvas) {
      for (var i = 0; i < cells.length; i++) {
        canvas.drawImage(cells[i], Offset(i * 48.0, 0), Paint());
      }
    });
    final png = await strip.toByteData(format: ui.ImageByteFormat.png);
    File(
      'assets/pixel_cat_spritesheet.png',
    ).writeAsBytesSync(png!.buffer.asUint8List());
  });
}

Future<ui.Image> _draw(int w, int h, void Function(Canvas) body) async {
  final recorder = ui.PictureRecorder();
  body(Canvas(recorder));
  return recorder.endRecording().toImage(w, h);
}

/// Classify every pixel against the sprite palette + the backdrop, then
/// re-ink the silhouette so the outline the soft source lost comes back.
Future<ui.Image> _classify(ui.Image src) async {
  final data = (await src.toByteData(
    format: ui.ImageByteFormat.rawStraightRgba,
  ))!;
  final px = data.buffer.asUint8List();

  final palette = <(Color, Color)>[
    (_cream, _cream),
    (_black, _black),
    (_pink, _pink),
    (_white, _white),
    // Midtone anchors: cream/black edge blends must not land on pink.
    (Color.lerp(_cream, _black, 0.5)!, _black),
    (Color.lerp(_pink, _cream, 0.5)!, _cream),
  ];

  const w = 48, h = 64;
  final kind = List<int>.filled(w * h, 0); // 0 transparent, 1 body, 2 black
  for (var i = 0; i < px.length; i += 4) {
    Color best = _transparent;
    var bestD = 1 << 30;
    // Alpha, not colour, says what is backdrop now.
    if (px[i + 3] >= 128) {
      for (final (m, paint) in palette) {
        final dr = px[i] - (m.r * 255).round();
        final dg = px[i + 1] - (m.g * 255).round();
        final db = px[i + 2] - (m.b * 255).round();
        final d = dr * dr + dg * dg + db * db;
        if (d < bestD) {
          bestD = d;
          best = paint;
        }
      }
    }
    final n = i ~/ 4;
    if (best == _transparent) {
      kind[n] = 0;
    } else if (best == _black) {
      kind[n] = 2;
    } else {
      kind[n] = 1;
    }
    px[i] = (best.r * 255).round();
    px[i + 1] = (best.g * 255).round();
    px[i + 2] = (best.b * 255).round();
    px[i + 3] = best == _transparent ? 0 : 255;
  }

  // --- Structural cleanup. Per-pixel classification of soft AI "pixel
  // art" leaves debris that no palette tweak can fix: floating islands,
  // ragged edges, pink smears. These passes operate on the SHAPE. ---

  // 1. Connected components: keep only real matter. Anything smaller than
  // 20px is keying debris, not cat.
  final seen = List<bool>.filled(w * h, false);
  for (var start = 0; start < w * h; start++) {
    if (kind[start] == 0 || seen[start]) continue;
    final component = <int>[];
    final queue = <int>[start];
    seen[start] = true;
    while (queue.isNotEmpty) {
      final n = queue.removeLast();
      component.add(n);
      final x = n % w, y = n ~/ w;
      for (final m in [
        if (x > 0) n - 1,
        if (x < w - 1) n + 1,
        if (y > 0) n - w,
        if (y < h - 1) n + w,
      ]) {
        if (kind[m] != 0 && !seen[m]) {
          seen[m] = true;
          queue.add(m);
        }
      }
    }
    if (component.length < 20) {
      for (final n in component) {
        kind[n] = 0;
        final i = n * 4;
        px[i] = px[i + 1] = px[i + 2] = px[i + 3] = 0;
      }
    }
  }

  // 2. Morphology: shave 1px spurs (opaque with 3+ air neighbours), then
  // fill 1px notches (air with 3+ opaque neighbours). Two rounds each.
  for (var round = 0; round < 2; round++) {
    final shaved = <int>[];
    for (var n = 0; n < w * h; n++) {
      if (kind[n] == 0) continue;
      if (_airNeighbours(kind, n, w, h) >= 3) shaved.add(n);
    }
    for (final n in shaved) {
      kind[n] = 0;
      final i = n * 4;
      px[i] = px[i + 1] = px[i + 2] = px[i + 3] = 0;
    }
    final filled = <int>[];
    for (var n = 0; n < w * h; n++) {
      if (kind[n] != 0) continue;
      if (_airNeighbours(kind, n, w, h) <= 1) filled.add(n);
    }
    for (final n in filled) {
      kind[n] = 2;
      final i = n * 4;
      px[i] = (_black.r * 255).round();
      px[i + 1] = (_black.g * 255).round();
      px[i + 2] = (_black.b * 255).round();
      px[i + 3] = 255;
    }
  }

  // 3. Pink discipline: pink belongs inside the body (ears, cheeks). Any
  // pink pixel on the silhouette is a blend artefact — make it cream.
  for (var n = 0; n < w * h; n++) {
    if (kind[n] != 1) continue;
    final i = n * 4;
    final isPink =
        px[i + 3] == 255 &&
        (px[i] - (_pink.r * 255).round()).abs() < 8 &&
        (px[i + 1] - (_pink.g * 255).round()).abs() < 8;
    if (isPink && _airNeighbours(kind, n, w, h) > 0) {
      px[i] = (_cream.r * 255).round();
      px[i + 1] = (_cream.g * 255).round();
      px[i + 2] = (_cream.b * 255).round();
    }
  }

  // 4. Re-ink: any body pixel touching transparency becomes outline, so the
  // silhouette ends in a closed line whatever the passes above did to it.
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final n = y * w + x;
      if (kind[n] != 1) continue;
      final touchesAir =
          _airNeighbours(kind, n, w, h) > 0 ||
          x == 0 ||
          x == w - 1 ||
          y == 0 ||
          y == h - 1;
      if (touchesAir) {
        final i = n * 4;
        px[i] = (_black.r * 255).round();
        px[i + 1] = (_black.g * 255).round();
        px[i + 2] = (_black.b * 255).round();
      }
    }
  }

  final c = Completer<ui.Image>();
  ui.decodeImageFromPixels(px, w, h, ui.PixelFormat.rgba8888, c.complete);
  return c.future;
}

int _airNeighbours(List<int> kind, int n, int w, int h) {
  final x = n % w, y = n ~/ w;
  var air = 0;
  if (x == 0 || kind[n - 1] == 0) air++;
  if (x == w - 1 || kind[n + 1] == 0) air++;
  if (y == 0 || kind[n - w] == 0) air++;
  if (y == h - 1 || kind[n + w] == 0) air++;
  return air;
}

/// Turns every pixel within a tight distance of the corner-sampled backdrop
/// colour transparent. Native resolution only — after any averaging the
/// backdrop has already bled into everything it touches.
Future<ui.Image> _keyBackdrop(ui.Image src) async {
  final data = (await src.toByteData(
    format: ui.ImageByteFormat.rawStraightRgba,
  ))!;
  final px = data.buffer.asUint8List();
  final br = px[0], bg = px[1], bb = px[2];
  for (var i = 0; i < px.length; i += 4) {
    final dr = px[i] - br, dg = px[i + 1] - bg, db = px[i + 2] - bb;
    if (dr * dr + dg * dg + db * db < 200) {
      px[i] = px[i + 1] = px[i + 2] = px[i + 3] = 0;
    }
  }
  final c = Completer<ui.Image>();
  ui.decodeImageFromPixels(
    px,
    src.width,
    src.height,
    ui.PixelFormat.rgba8888,
    c.complete,
  );
  return c.future;
}

class _BBox {
  _BBox(this.minX, this.minY, this.maxX, this.maxY, this.shadowCenterX);
  final int minX, minY, maxX, maxY;
  final double shadowCenterX;
  int get width => maxX - minX + 1;
  int get height => maxY - minY + 1;
}

/// Opaque bounding box plus the horizontal centre of the bottom three
/// opaque rows — the baked ground shadow, the one landmark every frame
/// shares, grounded or airborne.
Future<_BBox> _measure(ui.Image img) async {
  final data = (await img.toByteData(
    format: ui.ImageByteFormat.rawStraightRgba,
  ))!;
  final px = data.buffer.asUint8List();
  var minX = img.width, minY = img.height, maxX = -1, maxY = -1;
  for (var y = 0; y < img.height; y++) {
    for (var x = 0; x < img.width; x++) {
      if (px[(y * img.width + x) * 4 + 3] < 128) continue;
      if (x < minX) minX = x;
      if (x > maxX) maxX = x;
      if (y < minY) minY = y;
      if (y > maxY) maxY = y;
    }
  }
  var sum = 0.0, count = 0;
  for (var y = maxY - 2; y <= maxY; y++) {
    for (var x = minX; x <= maxX; x++) {
      if (px[(y * img.width + x) * 4 + 3] < 128) continue;
      sum += x;
      count++;
    }
  }
  final shadowCenterX = count == 0 ? (minX + maxX) / 2 : sum / count;
  return _BBox(minX, minY, maxX, maxY, shadowCenterX);
}

/// Mirrors rows 50..63, columns 9..31 (the legs) about x=20, leaving the
/// body's own bottom edge, the tail and everything above untouched.
Future<ui.Image> _mirrorLegBand(ui.Image src) async {
  final data = (await src.toByteData(
    format: ui.ImageByteFormat.rawStraightRgba,
  ))!;
  final px = data.buffer.asUint8List();
  final out = Uint8List.fromList(px);
  for (var y = 50; y < 64; y++) {
    for (var x = 9; x <= 31; x++) {
      final from = (y * 48 + (40 - x)) * 4;
      final to = (y * 48 + x) * 4;
      out[to] = px[from];
      out[to + 1] = px[from + 1];
      out[to + 2] = px[from + 2];
      out[to + 3] = px[from + 3];
    }
  }
  final c = Completer<ui.Image>();
  ui.decodeImageFromPixels(out, 48, 64, ui.PixelFormat.rgba8888, c.complete);
  return c.future;
}

/// Makes the ground shadow symmetric about x=20 by unioning each pixel with
/// its mirror across the shadow rows, so the walk frames share one ground.
Future<ui.Image> _symmetriseShadow(ui.Image src) async {
  final data = (await src.toByteData(
    format: ui.ImageByteFormat.rawStraightRgba,
  ))!;
  final px = data.buffer.asUint8List();
  final out = Uint8List.fromList(px);
  for (var y = 57; y < 64; y++) {
    for (var x = 8; x <= 32; x++) {
      final m = (y * 48 + (40 - x)) * 4;
      final i = (y * 48 + x) * 4;
      if (out[i + 3] < 128 && px[m + 3] >= 128) {
        out[i] = px[m];
        out[i + 1] = px[m + 1];
        out[i + 2] = px[m + 2];
        out[i + 3] = px[m + 3];
      }
    }
  }
  final c = Completer<ui.Image>();
  ui.decodeImageFromPixels(out, 48, 64, ui.PixelFormat.rgba8888, c.complete);
  return c.future;
}

/// Idle with closed eyes: finds the two largest interior ink blobs in the
/// upper face (the eyes — the outline is excluded because it touches
/// transparency), erases them to cream, and draws a lash line along each
/// blob's bottom edge.
Future<ui.Image> _deriveBlink(ui.Image idle) async {
  final data = (await idle.toByteData(
    format: ui.ImageByteFormat.rawStraightRgba,
  ))!;
  final px = Uint8List.fromList(data.buffer.asUint8List());
  const w = 48, h = 64;

  bool isInk(int n) {
    final i = n * 4;
    return px[i + 3] >= 128 && px[i] < 90;
  }

  bool isAir(int n) => px[n * 4 + 3] < 128;

  final seen = List<bool>.filled(w * h, false);
  final eyes = <List<int>>[];
  for (var y = 14; y <= 32; y++) {
    for (var x = 6; x <= 41; x++) {
      final start = y * w + x;
      if (!isInk(start) || seen[start]) continue;
      final component = <int>[];
      final queue = [start];
      seen[start] = true;
      var touchesAir = false;
      while (queue.isNotEmpty) {
        final n = queue.removeLast();
        component.add(n);
        final cx = n % w, cy = n ~/ w;
        for (final m in [
          if (cx > 0) n - 1,
          if (cx < w - 1) n + 1,
          if (cy > 0) n - w,
          if (cy < h - 1) n + w,
        ]) {
          if (isAir(m)) touchesAir = true;
          if (isInk(m) && !seen[m]) {
            seen[m] = true;
            queue.add(m);
          }
        }
      }
      if (!touchesAir && component.length >= 5) eyes.add(component);
    }
  }
  eyes.sort((a, b) => b.length.compareTo(a.length));

  for (final eye in eyes.take(2)) {
    var minX = w, maxX = -1, maxY = -1;
    for (final n in eye) {
      final x = n % w, y = n ~/ w;
      if (x < minX) minX = x;
      if (x > maxX) maxX = x;
      if (y > maxY) maxY = y;
      final i = n * 4;
      px[i] = (_cream.r * 255).round();
      px[i + 1] = (_cream.g * 255).round();
      px[i + 2] = (_cream.b * 255).round();
    }
    for (var x = minX; x <= maxX; x++) {
      final i = (maxY * w + x) * 4;
      px[i] = (_black.r * 255).round();
      px[i + 1] = (_black.g * 255).round();
      px[i + 2] = (_black.b * 255).round();
    }
  }

  final c = Completer<ui.Image>();
  ui.decodeImageFromPixels(px, w, h, ui.PixelFormat.rgba8888, c.complete);
  return c.future;
}
