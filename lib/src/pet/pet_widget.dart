import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'pet_controller.dart';
import 'pet_state.dart';
import 'pixel_sprite.dart';

/// The pixel cat, ready to drop into any screen:
///
/// ```dart
/// PetWidget(size: 192)                          // idles forever
/// PetWidget(size: 192, state: PetState.walk)    // walks forever
/// PetWidget(size: 192, controller: controller)  // driven from outside
/// ```
///
/// [size] is the target height. The sprite is 48x64, so the widget snaps to
/// the largest whole multiple that fits — integer scaling is what keeps
/// pixel art crisp. A tap plays wink -> jump -> back to the looping state,
/// unless [onTap] replaces that.
class PetWidget extends StatefulWidget {
  const PetWidget({
    super.key,
    this.size = 192,
    this.state,
    this.controller,
    this.onTap,
  });

  final double size;

  /// Initial looping state when no [controller] is given.
  final PetState? state;
  final PetController? controller;
  final VoidCallback? onTap;

  @override
  State<PetWidget> createState() => _PetWidgetState();
}

class _PetWidgetState extends State<PetWidget> {
  PetController? _ownController;
  PetController get _controller =>
      widget.controller ?? (_ownController ??= PetController());

  /// Set while a tap sequence is running: the wink's completion should chain
  /// into a jump instead of falling back to the base state.
  bool _jumpAfterWink = false;

  int get _scale => math.max(1, widget.size ~/ 64);

  @override
  void initState() {
    super.initState();
    _applyInitialState();
    _controller.addListener(_onControllerChanged);
  }

  /// The tap chain (wink then jump) survives only an UNDISTURBED wink. If
  /// anything else takes over mid-wink — a subscription jump, a state set
  /// from outside — the pending jump is stale and firing it later would
  /// double-jump.
  void _onControllerChanged() {
    if (_jumpAfterWink && _controller.state != PetState.wink) {
      _jumpAfterWink = false;
    }
  }

  void _applyInitialState() {
    if (widget.state == null || widget.controller != null) return;
    switch (widget.state!) {
      case PetState.idle:
        _controller.idle();
      case PetState.walk:
        _controller.walk();
      case PetState.jump:
        _controller.jump();
      case PetState.wink:
        _controller.wink();
    }
  }

  @override
  void didUpdateWidget(PetWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      (oldWidget.controller ?? _ownController)?.removeListener(
        _onControllerChanged,
      );
      _controller.addListener(_onControllerChanged);
    }
    if (oldWidget.state != widget.state) _applyInitialState();
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _ownController?.dispose();
    super.dispose();
  }

  void _handleOneShotComplete() {
    if (_jumpAfterWink) {
      _jumpAfterWink = false;
      _controller.jump();
    } else {
      _controller.onOneShotComplete();
    }
  }

  void _handleTap() {
    final onTap = widget.onTap;
    if (onTap != null) {
      onTap();
      return;
    }
    _jumpAfterWink = true;
    _controller.wink();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: SizedBox(
        width: 48.0 * _scale,
        height: 64.0 * _scale,
        child: PixelSpriteAnimation(
          controller: _controller,
          scale: _scale,
          onOneShotComplete: _handleOneShotComplete,
        ),
      ),
    );
  }
}
