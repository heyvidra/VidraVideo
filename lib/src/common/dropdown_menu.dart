import 'dart:ui';
import 'package:flutter/material.dart';

/// 流畅的下拉菜单组件，基于 PlayerOverlayPanel 样式
class DropdownMenu extends StatefulWidget {
  /// 触发按钮
  final Widget child;

  /// 菜单项构建器
  final List<Widget> Function(BuildContext context, VoidCallback close)
  menuBuilder;

  /// 菜单宽度
  final double menuWidth;

  /// 是否使用模糊效果
  final bool useBlur;

  /// 菜单标题（可选）
  final String? title;

  /// 对齐方式
  final Alignment alignment;

  /// 偏移量
  final Offset offset;

  /// 菜单打开/关闭回调
  final VoidCallback? onOpen;
  final VoidCallback? onClose;

  const DropdownMenu({
    super.key,
    required this.child,
    required this.menuBuilder,
    this.menuWidth = 200,
    this.useBlur = true,
    this.title,
    this.alignment = Alignment.bottomRight,
    this.offset = const Offset(0, 8),
    this.onOpen,
    this.onClose,
  });

  @override
  State<DropdownMenu> createState() => _DropdownMenuState();
}

class _DropdownMenuState extends State<DropdownMenu>
    with SingleTickerProviderStateMixin {
  OverlayEntry? _overlayEntry;
  late AnimationController _animationController;
  late Animation<double> _opacityAnimation;

  final LayerLink _layerLink = LayerLink();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _closeMenu();
    _animationController.dispose();
    super.dispose();
  }

  void _toggleMenu() {
    if (_overlayEntry == null) {
      _openMenu();
    } else {
      _closeMenu();
    }
  }

  void _openMenu() {
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
    _animationController.forward();

    // Call onOpen after menu is shown
    widget.onOpen?.call();
  }

  void _closeMenu() {
    if (_overlayEntry == null) return;

    _animationController.reverse().then((_) {
      _overlayEntry?.remove();
      _overlayEntry = null;

      // Call onClose after menu is hidden
      widget.onClose?.call();
    });
  }

  OverlayEntry _createOverlayEntry() {
    return OverlayEntry(
      builder: (context) => Stack(
        children: [
          // 点击外部关闭
          Positioned.fill(
            child: GestureDetector(
              onTap: _closeMenu,
              behavior: HitTestBehavior.translucent,
              child: Container(color: Colors.transparent),
            ),
          ),
          // 菜单内容
          Positioned(
            width: widget.menuWidth,
            child: CompositedTransformFollower(
              link: _layerLink,
              targetAnchor: _getTargetAnchor(),
              followerAnchor: _getFollowerAnchor(),
              offset: widget.offset,
              child: FadeTransition(
                opacity: _opacityAnimation,
                child: Material(
                  type: MaterialType.transparency,
                  child: _buildMenuPanel(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuPanel() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Widget panelContent = Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.6,
      ),
      decoration: BoxDecoration(
        color: widget.useBlur
            ? Colors.black.withValues(alpha: 0.5)
            : (theme.cardTheme.color?.withValues(alpha: 0.95) ??
                  (isDark
                      ? const Color(0xFF1C1C1C).withValues(alpha: 0.95)
                      : Colors.white.withValues(alpha: 0.95))),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.1),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 可选标题
          if (widget.title != null) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  widget.title!,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            Divider(color: Colors.white.withValues(alpha: 0.1), height: 1),
          ],
          // 菜单项
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: widget.menuBuilder(context, _closeMenu),
              ),
            ),
          ),
        ],
      ),
    );

    if (widget.useBlur) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: panelContent,
        ),
      );
    }

    return panelContent;
  }

  Alignment _getTargetAnchor() {
    switch (widget.alignment) {
      case Alignment.topLeft:
        return Alignment.topLeft;
      case Alignment.topRight:
        return Alignment.topRight;
      case Alignment.bottomLeft:
        return Alignment.bottomLeft;
      case Alignment.bottomRight:
      default:
        return Alignment.bottomRight;
    }
  }

  Alignment _getFollowerAnchor() {
    switch (widget.alignment) {
      case Alignment.topLeft:
        return Alignment.bottomLeft;
      case Alignment.topRight:
        return Alignment.bottomRight;
      case Alignment.bottomLeft:
        return Alignment.topLeft;
      case Alignment.bottomRight:
      default:
        return Alignment.topRight;
    }
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(onTap: _toggleMenu, child: widget.child),
      ),
    );
  }
}

/// 菜单项组件
class PlayerMenuItem extends StatefulWidget {
  final Widget? leading;
  final String text;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool enabled;
  final Color? textColor;

  const PlayerMenuItem({
    super.key,
    this.leading,
    required this.text,
    this.trailing,
    this.onTap,
    this.enabled = true,
    this.textColor,
  });

  @override
  State<PlayerMenuItem> createState() => _PlayerMenuItemState();
}

class _PlayerMenuItemState extends State<PlayerMenuItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.enabled ? widget.onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: _isHovered && widget.enabled
                ? (isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.05))
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              if (widget.leading != null) ...[
                IconTheme(
                  data: IconThemeData(
                    color: widget.enabled
                        ? (widget.textColor ??
                              (isDark ? Colors.white : Colors.black87))
                        : Colors.grey,
                    size: 20,
                  ),
                  child: widget.leading!,
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Text(
                  widget.text,
                  style: TextStyle(
                    color: widget.enabled
                        ? (widget.textColor ??
                              (isDark ? Colors.white : Colors.black87))
                        : Colors.grey,
                    fontSize: 14,
                  ),
                ),
              ),
              if (widget.trailing != null) ...[
                const SizedBox(width: 8),
                IconTheme(
                  data: IconThemeData(
                    color: widget.enabled
                        ? (widget.textColor ??
                              (isDark ? Colors.white70 : Colors.black54))
                        : Colors.grey,
                    size: 18,
                  ),
                  child: widget.trailing!,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// 菜单分割线
class PlayerMenuDivider extends StatelessWidget {
  const PlayerMenuDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Divider(color: Colors.white.withValues(alpha: 0.1), height: 1),
    );
  }
}
