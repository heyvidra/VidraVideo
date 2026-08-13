import 'package:flutter/material.dart';

import 'pet_animation.dart';

/// Draws the cat of the design sheet, laid out from its 48x64 pixel-style
/// reference (the sheet's own implementation blueprint): oversized rounded
/// head, small corner ears with pink inners, wide-set bean eyes, a short
/// plush body with stubby legs, and the big open-spiral tail.
///
/// All coordinates live on that 48x64 grid and are scaled uniformly to the
/// canvas, so they can be read straight off the design.
class PetPainter extends CustomPainter {
  PetPainter({required this.pose, this.showShadow = true}) : super();

  /// Repaint-driven variant: recomputes the pose from [progress] on every
  /// tick without rebuilding any widget.
  PetPainter.animated({
    required Animation<double> progress,
    required PetPose Function(double t) poseFor,
  }) : _progress = progress,
       _poseFor = poseFor,
       pose = null,
       showShadow = true,
       super(repaint: progress);

  /// Off when rasterising sprite cells: a blurred shadow quantises into a
  /// hard black slab, and the sprite's hop keeps its own ground anyway.
  final bool showShadow;

  /// Fixed pose (tests, previews). Null when driven by [_progress].
  final PetPose? pose;
  Animation<double>? _progress;
  PetPose Function(double t)? _poseFor;

  // The design sheet's palette.
  static const cream = Color(0xFFF5EFE4);
  static const outline = Color(0xFFC9BCA6);
  static const earPink = Color(0xFFF5C9CF);
  static const blush = Color(0x2EF2A7AE);
  static const ink = Color(0xFF211E1C);

  static const _designSize = Size(48, 64);

  Paint get _fill => Paint()..color = cream;
  Paint get _edge => Paint()
    ..color = outline
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.0
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  @override
  void paint(Canvas canvas, Size size) {
    final p = pose ?? _poseFor!(_progress!.value);

    // Uniform scale, centred — the cat keeps its proportions in any box.
    final scale = size.shortestSide == 0
        ? 1.0
        : (size.width / _designSize.width < size.height / _designSize.height
              ? size.width / _designSize.width
              : size.height / _designSize.height);
    canvas.save();
    canvas.translate(
      (size.width - _designSize.width * scale) / 2,
      (size.height - _designSize.height * scale) / 2,
    );
    canvas.scale(scale);

    if (showShadow) _paintShadow(canvas, p);

    // Squash and tilt both pivot on the ground under the cat: weight lives
    // in the paws, not the waist.
    const ground = Offset(24, 60);
    canvas.save();
    canvas.translate(ground.dx, ground.dy);
    final widen = 1 + (1 - p.squash) * 0.9;
    canvas.scale(widen, p.squash);
    canvas.rotate(p.tilt);
    canvas.translate(-ground.dx, -ground.dy);
    canvas.translate(0, -p.lift);

    _paintTail(canvas, p);
    _paintLegs(canvas, p);
    _paintBody(canvas, p);
    _paintArms(canvas, p);
    _paintEars(canvas, p);
    _paintHead(canvas, p);
    _paintFace(canvas, p);

    canvas.restore();
    canvas.restore();
  }

  void _paintShadow(Canvas canvas, PetPose p) {
    // Shrinks as the cat leaves the ground — the cue that sells the jump
    // when there is no floor to land on.
    final spread = 1 - (p.lift / 16).clamp(0.0, 1.0) * 0.35;
    canvas.drawOval(
      Rect.fromCenter(
        center: const Offset(24, 61.4),
        width: 27 * spread,
        height: 4.4 * spread,
      ),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.14 * spread)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.6),
    );
  }

  /// The identity feature: a thick tail that leaves the hip, sweeps up the
  /// right, and rolls ONE full open loop whose centre stays hollow — the
  /// design's "9". A tube made by stroking one path twice, outline-wide then
  /// cream, so both edges come from a single curve.
  void _paintTail(Canvas canvas, PetPose p) {
    const root = Offset(29.5, 50.5);
    canvas.save();
    canvas.translate(root.dx, root.dy);
    canvas.rotate(p.tailSway * 0.10 - p.legTuck * 0.10);
    canvas.translate(-root.dx, -root.dy);

    final path = Path()
      ..moveTo(root.dx, root.dy)
      // Out of the hip, swinging low then up the right side of the loop.
      ..cubicTo(34.5, 53.0, 39.5, 52.5, 42.2, 48.6)
      // Up and over the top of the loop.
      ..cubicTo(45.4, 43.8, 44.2, 37.0, 39.2, 36.4)
      // Down the left side of the loop.
      ..cubicTo(34.6, 35.9, 32.6, 40.6, 34.4, 44.4)
      // The tip hooks into the hollow centre and stops — never filling it.
      ..cubicTo(35.8, 47.2, 39.4, 47.5, 41.0, 45.2);

    canvas.drawPath(
      path,
      Paint()
        ..color = outline
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6.0
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = cream
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.4
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.restore();
  }

  /// Two stubby legs with round feet, drawn before the body so its bottom
  /// edge covers their tops. Walking lifts them alternately; the airborne
  /// tuck draws both up under the body.
  void _paintLegs(Canvas canvas, PetPose p) {
    final toe = Paint()
      ..color = outline.withValues(alpha: 0.75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7
      ..strokeCap = StrokeCap.round;
    for (final side in const [-1.0, 1.0]) {
      final step = (side < 0 ? p.legPhase : -p.legPhase).clamp(0.0, 1.0);
      final rise = step * 3.0 + p.legTuck * 4.5;
      final leg = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          24 + side * 8.2 - 3.8 + side * step * 0.8 - side * p.legTuck * 1.6,
          48.0 - rise,
          7.6,
          11.0 - p.legTuck * 2.5,
        ),
        const Radius.circular(3.8),
      );
      canvas.drawRRect(leg, _fill);
      canvas.drawRRect(leg, _edge);
      final foot = Offset(leg.center.dx, leg.bottom - 1.2);
      canvas.drawLine(
        foot + const Offset(-1.1, 0),
        foot + const Offset(-1.1, 1.0),
        toe,
      );
      canvas.drawLine(
        foot + const Offset(1.1, 0),
        foot + const Offset(1.1, 1.0),
        toe,
      );
    }
  }

  void _paintBody(Canvas canvas, PetPose p) {
    // Short plush torso under the big head, slightly wider at the hips —
    // proportioned to the sheet: about half the head's width.
    final bottom = 53.5 - p.legTuck * 3.5;
    final body = Path()
      ..moveTo(15.8, 33.0)
      ..cubicTo(14.4, 38.5, 14.2, bottom - 5.5, 15.4, bottom - 1.8)
      ..quadraticBezierTo(16.2, bottom, 19.0, bottom)
      ..lineTo(29.0, bottom)
      ..quadraticBezierTo(31.8, bottom, 32.6, bottom - 1.8)
      ..cubicTo(33.8, bottom - 5.5, 33.6, 38.5, 32.2, 33.0)
      ..close();
    canvas.drawPath(body, _fill);
    canvas.drawPath(body, _edge);
  }

  void _paintArms(Canvas canvas, PetPose p) {
    for (final side in const [-1.0, 1.0]) {
      // Hugging the body's flanks, ending well above the legs — any lower
      // or wider and the silhouette reads as four legs.
      final shoulder = Offset(24 + side * 9.4, 34.8);
      // Hanging at rest; swings a little while walking; rotates up and OUT
      // for the airborne pose. Sign flipped against intuition: with y down,
      // a positive rotation carries a downward-pointing arm towards the
      // body's centre, so spreading outwards needs -side.
      final angle =
          -side * (p.armRaise * 0.95) +
          (side < 0 ? p.armSwing : -p.armSwing) * 0.16;
      canvas.save();
      canvas.translate(shoulder.dx, shoulder.dy);
      canvas.rotate(angle);
      final arm = RRect.fromRectAndRadius(
        Rect.fromCenter(center: const Offset(0, 4.8), width: 5.0, height: 10.5),
        const Radius.circular(2.5),
      );
      canvas.drawRRect(arm, _fill);
      canvas.drawRRect(arm, _edge);
      canvas.restore();
    }
  }

  /// Before the head, so the head's fill swallows the ear bases and the two
  /// read as one silhouette. Small triangles parked on the head's top
  /// corners, as on the sheet — not tall horns.
  void _paintEars(Canvas canvas, PetPose p) {
    for (final side in const [-1.0, 1.0]) {
      // The tip leans OUT past its own base, as on the sheet.
      final baseInner = Offset(24 + side * 7.0, 9.2);
      final baseOuter = Offset(24 + side * 17.0, 13.0);
      final tip = Offset(24 + side * 18.2, 1.2);

      final ear = Path()
        ..moveTo(baseInner.dx, baseInner.dy)
        ..lineTo(tip.dx, tip.dy)
        ..lineTo(baseOuter.dx, baseOuter.dy)
        ..close();
      canvas.drawPath(ear, _fill);
      canvas.drawPath(ear, _edge);

      // Inner ear: the same triangle shrunk towards the tip.
      Offset toTip(Offset from, double t) => Offset.lerp(tip, from, t)!;
      final ia = toTip(baseInner, 0.55);
      final ib = toTip(baseOuter, 0.55);
      final inner = Path()
        ..moveTo(ia.dx, ia.dy)
        ..lineTo(tip.dx, tip.dy)
        ..lineTo(ib.dx, ib.dy)
        ..close();
      canvas.drawPath(inner, Paint()..color = earPink);
    }
  }

  void _paintHead(Canvas canvas, PetPose p) {
    // The sheet's head: a wide rounded square, nearly the full canvas width,
    // flat-ish on top with full cheeks.
    final head = RRect.fromRectAndRadius(
      const Rect.fromLTRB(5.0, 5.5, 43.0, 35.5),
      const Radius.circular(13),
    );
    canvas.drawRRect(head, _fill);
    canvas.drawRRect(head, _edge);
  }

  void _paintFace(Canvas canvas, PetPose p) {
    final line = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round;

    // Cheek blush, faint as on the render.
    for (final side in const [-1.0, 1.0]) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(24 + side * 12.2, 27.0),
          width: 5.4,
          height: 2.8,
        ),
        Paint()..color = blush,
      );
    }

    for (final side in const [-1.0, 1.0]) {
      final open = side < 0 ? p.leftEyeOpen : p.rightEyeOpen;
      // Wide-set, as on the sheet: the eyes sit far apart on the big face.
      final eye = Offset(24 + side * 7.6, 22.0);
      if (open < 0.3) {
        if (p.happy > 0.5) {
          // Closed-happy: the ^ ^ of the design's happy pose.
          canvas.drawPath(
            Path()
              ..moveTo(eye.dx - 2.7, eye.dy + 1.1)
              ..quadraticBezierTo(
                eye.dx,
                eye.dy - 2.3,
                eye.dx + 2.7,
                eye.dy + 1.1,
              ),
            line,
          );
        } else {
          canvas.drawLine(
            eye + const Offset(-2.5, 0.4),
            eye + const Offset(2.5, 0.4),
            line,
          );
        }
      } else {
        // The glossy black bean of the 3D render, with its catchlight.
        final rect = Rect.fromCenter(
          center: eye,
          width: 4.4,
          height: 7.2 * open.clamp(0.3, 1.0),
        );
        canvas.drawOval(rect, Paint()..color = ink);
        canvas.drawCircle(
          eye + const Offset(-1.0, -1.9),
          0.85,
          Paint()..color = Colors.white.withValues(alpha: 0.9),
        );
      }
    }

    // Nose dot and the cat "w", low on the big face as on the sheet.
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(24, 27.2), width: 2.0, height: 1.5),
      Paint()..color = ink,
    );
    final drop = 1.7 + p.happy * 1.2;
    for (final side in const [-1.0, 1.0]) {
      canvas.drawPath(
        Path()
          ..moveTo(24 + side * 0.2, 28.4)
          ..quadraticBezierTo(
            24 + side * 2.0,
            28.4 + drop,
            24 + side * 3.9,
            28.2 + p.happy * 0.4,
          ),
        line..strokeWidth = 1.15,
      );
    }
  }

  @override
  bool shouldRepaint(PetPainter old) =>
      old.pose != pose ||
      old._progress != _progress ||
      old._poseFor != _poseFor;
}
