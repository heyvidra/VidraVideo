import 'package:flutter/material.dart';

import '../config/design_tokens.dart';

/// The chrome every content screen shares.
///
/// Five screens hang off the rail — 追更, 继续观看, 下载, 链接下载, 设置 — and
/// each had invented its own opening: a Material `AppBar` with a 22px title
/// here, a hand-rolled `headlineSmall` there, gutters of 16 / 24 / 8, grids at
/// 200 / 220 / 168 wide. Nothing was broken; they just did not look like the
/// same application. This is the one answer.

/// The content column's gutter, measured from the rail.
const double kContentGutter = 12;

/// One grid for every wall of posters in the app — the catalog, 继续观看 and
/// 追更 all show the same cards and had three different card sizes.
const SliverGridDelegateWithMaxCrossAxisExtent kPosterGrid =
    SliverGridDelegateWithMaxCrossAxisExtent(
      maxCrossAxisExtent: 168,
      childAspectRatio: 0.62,
      mainAxisSpacing: 20,
      crossAxisSpacing: 20,
    );

/// The line a screen opens with: what this is, how much of it there is, and
/// what you can do to all of it.
class ScreenHeader extends StatelessWidget {
  const ScreenHeader({
    super.key,
    required this.title,
    this.count,
    this.actions = const [],
  });

  final String title;

  /// e.g. "12 部" — sits beside the title rather than under it, because it is
  /// a property of the title, not a second heading.
  final String? count;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final t = VidraTokens.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(kContentGutter, 8, kContentGutter, 12),
      child: SizedBox(
        height: 34,
        child: Row(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 17,
                height: 1.3,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
                color: t.fg,
              ),
            ),
            if (count != null) ...[
              const SizedBox(width: 10),
              Text(
                count!,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.4,
                  color: t.fg3,
                  fontFeatures: VidraType.data,
                ),
              ),
            ],
            const Spacer(),
            ...actions,
          ],
        ),
      ),
    );
  }
}

/// A worded action in a screen header.
///
/// [danger] is for the ones that destroy something — the same clash colour the
/// detail page uses when catalogs disagree, and the only red in the app.
class ScreenAction extends StatelessWidget {
  const ScreenAction({
    super.key,
    required this.label,
    required this.onTap,
    this.danger = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final t = VidraTokens.of(context);
    final c = danger ? t.clash : t.fg2;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: c.withValues(alpha: danger ? 0.36 : 0.0)),
            color: danger
                ? t.clash.withValues(alpha: 0.09)
                : t.fg.withValues(alpha: 0.05),
          ),
          child: Text(
            label,
            style: TextStyle(fontSize: 12.5, height: 1.4, color: c),
          ),
        ),
      ),
    );
  }
}

/// Nothing here yet, and why.
///
/// The hint is not decoration: an empty 追更 list and a broken 追更 list look
/// identical without one.
class ScreenEmpty extends StatelessWidget {
  const ScreenEmpty({
    super.key,
    required this.icon,
    required this.title,
    this.hint,
  });

  final IconData icon;
  final String title;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final t = VidraTokens.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 44, color: t.fg4),
          const SizedBox(height: 14),
          Text(
            title,
            style: TextStyle(fontSize: 14, height: 1.4, color: t.fg2),
          ),
          if (hint != null) ...[
            const SizedBox(height: 5),
            Text(
              hint!,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, height: 1.5, color: t.fg3),
            ),
          ],
        ],
      ),
    );
  }
}

/// A titled group of rows on one surface — settings, and anything else that
/// is a list of labelled controls rather than a wall of cards.
class ScreenSection extends StatelessWidget {
  const ScreenSection({
    super.key,
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final t = VidraTokens.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 9),
          child: Text(title.toUpperCase(), style: VidraType.eyebrow(t.fg3)),
        ),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: t.glass2,
            ),
            border: Border.all(color: t.edgeSoft),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}
