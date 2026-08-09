import 'package:flutter/material.dart';

/// A dark round action laid on a poster — remove-from-history, unfollow,
/// remove-from-想看. One shape, because it was hand-copied into three screens
/// and had already started to drift.
class PosterCardAction extends StatelessWidget {
  const PosterCardAction({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    child: Material(
      color: Colors.black.withValues(alpha: 0.47),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(icon, size: 14, color: Colors.white),
        ),
      ),
    ),
  );
}
