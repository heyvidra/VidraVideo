import 'dart:math' as math;

import 'package:flutter/material.dart';

/// The six key-art washes the design cycles through, `.art-1` … `.art-6`.
///
/// They stand in for a frame. Real per-episode thumbnails come from the frame
/// sweep, which runs inside the PLAYER process and has nothing to hand the
/// catalog window — and a grid of identical grey rectangles reads as a page
/// that failed to load. A deterministic wash per episode number gives the grid
/// the rhythm the design has, and never claims to be a frame.
class KeyArt extends StatelessWidget {
  const KeyArt({super.key, required this.seed, this.grain = true});

  /// Anything stable for this tile — an episode number works.
  final int seed;
  final bool grain;

  static const _sets = <_ArtSet>[
    _ArtSet(
      Color(0xFF1D3F52),
      Color(0xFF0B1A26),
      Alignment(-0.56, -0.72),
      Color(0xFF4E86A8),
      Alignment(0.72, 0.64),
      Color(0xFFA2543E),
    ),
    _ArtSet(
      Color(0xFF252C58),
      Color(0xFF0D1220),
      Alignment(0.52, -0.60),
      Color(0xFF7663B0),
      Alignment(-0.64, 0.72),
      Color(0xFF2A7A84),
    ),
    _ArtSet(
      Color(0xFF3A3116),
      Color(0xFF101814),
      Alignment(-0.40, 0.60),
      Color(0xFFB4862B),
      Alignment(0.64, -0.72),
      Color(0xFF3B8272),
    ),
    _ArtSet(
      Color(0xFF183449),
      Color(0xFF0A1018),
      Alignment(0.24, -0.52),
      Color(0xFF3B79A2),
      Alignment(-0.72, 0.80),
      Color(0xFF8E3E5A),
    ),
    _ArtSet(
      Color(0xFF22351E),
      Color(0xFF0B1310),
      Alignment(-0.52, -0.48),
      Color(0xFF628C46),
      Alignment(0.72, 0.52),
      Color(0xFF38648F),
    ),
    _ArtSet(
      Color(0xFF2C2234),
      Color(0xFF0D1117),
      Alignment(0.32, 0.60),
      Color(0xFF9A4160),
      Alignment(-0.60, -0.72),
      Color(0xFF4A7793),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final a = _sets[seed.abs() % _sets.length];
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: const Alignment(0.4, -1),
              end: const Alignment(-0.4, 1),
              colors: [a.baseA, a.baseB],
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: a.c1,
              radius: 0.95,
              colors: [a.tint1, a.tint1.withAlpha(0)],
              stops: const [0, 0.62],
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: a.c2,
              radius: 0.9,
              colors: [a.tint2, a.tint2.withAlpha(0)],
              stops: const [0, 0.64],
            ),
          ),
        ),
        if (grain) const CustomPaint(painter: _GrainPainter()),
      ],
    );
  }
}

class _ArtSet {
  const _ArtSet(
    this.baseA,
    this.baseB,
    this.c1,
    this.tint1,
    this.c2,
    this.tint2,
  );
  final Color baseA, baseB;
  final Alignment c1, c2;
  final Color tint1, tint2;
}

/// `.grain` — 1px diagonal hairlines every 5px. It is what keeps a flat
/// gradient from reading as a colour swatch.
class _GrainPainter extends CustomPainter {
  const _GrainPainter();

  static const _angle = 112 * math.pi / 180;
  static const _gap = 5.0;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x0AFFFFFF)
      ..strokeWidth = 1;
    // Step along the line's normal so the stripes stay 5px apart whatever the
    // angle, and run each one well past the box; the clip does the trimming.
    final dx = math.cos(_angle), dy = math.sin(_angle);
    final span = size.width.abs() + size.height.abs();
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    for (var d = -span; d < span; d += _gap) {
      final ox = -dy * d, oy = dx * d;
      canvas.drawLine(
        Offset(ox - dx * span, oy - dy * span),
        Offset(ox + dx * span, oy + dy * span),
        paint,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _GrainPainter oldDelegate) => false;
}
