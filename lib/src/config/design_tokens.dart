import 'package:flutter/material.dart';

/// The design's variables, transcribed.
///
/// Every colour, edge and shadow in the redesign comes from one CSS `:root`
/// block with a light and a dark set. Reproducing that as scattered
/// `withValues(alpha: 0.08)` calls is how a design drifts: each site picks a
/// slightly different number, nobody can tell which was intended, and there is
/// no single place to correct. This is that block, in Dart.
///
/// Names match the CSS so the two can be diffed by eye: `fg2` is `--fg-2`,
/// `edgeSoft` is `--edge-soft`, `glass2` is `--glass-2`.
class VidraTokens {
  const VidraTokens._({
    required this.fg,
    required this.fg2,
    required this.fg3,
    required this.fg4,
    required this.glass1,
    required this.glass2,
    required this.glass3,
    required this.edge,
    required this.edgeSoft,
    required this.spec,
    required this.specSoft,
    required this.amber,
    required this.amberGlow,
    required this.cyan,
    required this.cyanGlow,
    required this.clash,
    required this.barBg,
    required this.pageA,
    required this.pageB,
    required this.blobs,
    required this.drop1,
    required this.drop2,
    required this.drop3,
    required this.onAmber,
    required this.onCyan,
  });

  /// Text, in four weights of presence.
  final Color fg, fg2, fg3, fg4;

  /// Panel fills, top-to-bottom gradient stops. 1 is the window, 2 the panels
  /// inside it, 3 the selected/raised state.
  final List<Color> glass1, glass2, glass3;

  /// Panel outline, and the quieter one used inside a panel.
  final Color edge, edgeSoft;

  /// The specular hairline along a panel's top edge — what makes a translucent
  /// rounded rectangle read as a pane rather than a hole.
  final Color spec, specSoft;

  /// Reserved: amber means "this gained an episode", cyan means "where you
  /// are", clash means "the catalogs disagree". Nothing else may use them.
  final Color amber, amberGlow, cyan, cyanGlow, clash;

  /// Legible ink for a filled amber / cyan chip.
  final Color onAmber, onCyan;

  /// The pinned episode bar, which must stay readable with a grid sliding
  /// under it — the one surface that is more opaque than glass.
  final Color barBg;

  /// The page itself: a 168° ramp with four colour washes over it.
  final Color pageA, pageB;
  final List<VidraBlob> blobs;

  final List<BoxShadow> drop1, drop2, drop3;

  static VidraTokens of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;

  static const light = VidraTokens._(
    fg: Color(0xF20C141E),
    fg2: Color(0x9E0C141E),
    fg3: Color(0x6B0C141E),
    fg4: Color(0x330C141E),
    glass1: [Color(0xC7FFFFFF), Color(0x8CFFFFFF)],
    glass2: [Color(0x9EFFFFFF), Color(0x66FFFFFF)],
    glass3: [Color(0xEBFFFFFF), Color(0xB8FFFFFF)],
    edge: Color(0xD9FFFFFF),
    edgeSoft: Color(0x140C141E),
    spec: Color(0xF2FFFFFF),
    specSoft: Color(0xB3FFFFFF),
    amber: Color(0xFFA96A00),
    amberGlow: Color(0x59FFC559),
    cyan: Color(0xFF0C7C87),
    cyanGlow: Color(0x380C7C87),
    clash: Color(0xFFC24A28),
    onAmber: Color(0xFFFFFFFF),
    onCyan: Color(0xFFFFFFFF),
    barBg: Color(0xCCF6F9FC),
    pageA: Color(0xFFDCE6F2),
    pageB: Color(0xFFEFF3F8),
    blobs: [
      VidraBlob(Alignment(-0.76, -0.88), 1.16, Color(0x737896F0)),
      VidraBlob(Alignment(0.84, -0.64), 0.96, Color(0x66F0A078)),
      VidraBlob(Alignment(0.56, 0.76), 1.20, Color(0x666ED7DC)),
      VidraBlob(Alignment(-0.52, 0.52), 0.92, Color(0x59B48CE6)),
    ],
    drop1: [
      BoxShadow(
        color: Color(0x3D142030),
        offset: Offset(0, 8),
        blurRadius: 21,
        spreadRadius: -12,
      ),
    ],
    drop2: [
      BoxShadow(
        color: Color(0x4D142030),
        offset: Offset(0, 30),
        blurRadius: 61,
        spreadRadius: -22,
      ),
      BoxShadow(
        color: Color(0x29142030),
        offset: Offset(0, 4),
        blurRadius: 12,
        spreadRadius: -6,
      ),
    ],
    drop3: [
      BoxShadow(
        color: Color(0x5C142030),
        offset: Offset(0, 60),
        blurRadius: 113,
        spreadRadius: -34,
      ),
      BoxShadow(
        color: Color(0x33142030),
        offset: Offset(0, 8),
        blurRadius: 23,
        spreadRadius: -10,
      ),
    ],
  );

  static const dark = VidraTokens._(
    fg: Color(0xF5FFFFFF),
    fg2: Color(0xA8FFFFFF),
    fg3: Color(0x6BFFFFFF),
    fg4: Color(0x3DFFFFFF),
    glass1: [Color(0x1DFFFFFF), Color(0x0BFFFFFF)],
    glass2: [Color(0x13FFFFFF), Color(0x07FFFFFF)],
    glass3: [Color(0x29FFFFFF), Color(0x12FFFFFF)],
    edge: Color(0x29FFFFFF),
    edgeSoft: Color(0x16FFFFFF),
    spec: Color(0x42FFFFFF),
    specSoft: Color(0x24FFFFFF),
    amber: Color(0xFFFFC559),
    amberGlow: Color(0x4DFFC559),
    cyan: Color(0xFF7BE7F0),
    cyanGlow: Color(0x527BE7F0),
    clash: Color(0xFFFF9A7A),
    onAmber: Color(0xFF38270A),
    onCyan: Color(0xFF05323A),
    barBg: Color(0xB8101A2C),
    pageA: Color(0xFF101A2E),
    pageB: Color(0xFF0A1220),
    blobs: [
      VidraBlob(Alignment(-0.76, -0.88), 1.16, Color(0x805878DC)),
      VidraBlob(Alignment(0.84, -0.64), 0.96, Color(0x57D8785A)),
      VidraBlob(Alignment(0.56, 0.76), 1.20, Color(0x4D3CBEC8)),
      VidraBlob(Alignment(-0.52, 0.52), 0.92, Color(0x4D965AC8)),
    ],
    drop1: [
      BoxShadow(
        color: Color(0x8C000000),
        offset: Offset(0, 8),
        blurRadius: 21,
        spreadRadius: -10,
      ),
    ],
    drop2: [
      BoxShadow(
        color: Color(0xB8000000),
        offset: Offset(0, 30),
        blurRadius: 61,
        spreadRadius: -18,
      ),
      BoxShadow(
        color: Color(0x66000000),
        offset: Offset(0, 4),
        blurRadius: 12,
        spreadRadius: -4,
      ),
    ],
    drop3: [
      BoxShadow(
        color: Color(0xD9000000),
        offset: Offset(0, 60),
        blurRadius: 113,
        spreadRadius: -30,
      ),
      BoxShadow(
        color: Color(0x80000000),
        offset: Offset(0, 8),
        blurRadius: 23,
        spreadRadius: -8,
      ),
    ],
  );
}

/// One of the four colour washes the page is lit by.
class VidraBlob {
  const VidraBlob(this.center, this.radius, this.color);
  final Alignment center;
  final double radius;
  final Color color;
}

/// The design's type roles.
///
/// Three faces in the CSS: a display face for headings, the body face for
/// prose, and a monospace for anything the eye has to compare down a column —
/// counts, deltas, timestamps, table cells. Flutter has no `--f-data`, so the
/// data role is tabular figures on the body face plus the letter-spacing the
/// mono face was carrying.
class VidraType {
  const VidraType._();

  /// Digits that line up. Everything the design set in `--f-data`.
  static const List<FontFeature> data = [FontFeature.tabularFigures()];

  /// `.rail-h`, `.info h4` — a 10px all-caps label, widely tracked.
  ///
  /// Callers pass `fg3`, not the design's `fg4`: at 10px, 20% black on the
  /// light page is below the threshold where it reads as text at all. On the
  /// dark theme 24% white had the contrast the design assumed.
  static TextStyle eyebrow(Color color) => TextStyle(
    fontSize: 10,
    height: 1.3,
    letterSpacing: 2,
    fontWeight: FontWeight.w500,
    color: color,
  );
}
