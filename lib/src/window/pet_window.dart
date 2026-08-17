import 'dart:async';
import 'dart:math' as math;

import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/gestures.dart' show kSecondaryMouseButton;
import 'package:flutter/material.dart';

import '../core/utils/log.dart';
import '../core/utils/window.dart';
import '../pet/pet_animation.dart';
import '../pet/pet_controller.dart';
import '../pet/pet_state.dart';
import '../pet/pet_widget.dart';

/// A small always-on-top transparent window holding a creature that reacts to
/// what the app is doing.
///
/// The window is deliberately tight around the pet: the fork has no
/// click-through support, so every pixel of this window's rectangle swallows
/// mouse input from whatever is underneath it.
class PetWindowLauncher {
  const PetWindowLauncher._();

  static const windowName = 'pet';
  static const moodKey = 'mood';
  static const messageKey = 'message';

  /// Bumped on every send. Two identical payloads in a row must still read as
  /// two separate events — the same show finishing twice is a real case.
  static const nonceKey = 'nonce';

  /// The creature's own box, and the window's size while it is quiet. Every
  /// pixel of the window blocks mouse input to whatever is behind it, so
  /// slack costs the user directly.
  static const petSize = Size(130, 150);

  /// Grown to only while a speech bubble is up, anchored so the creature
  /// itself does not move.
  static const speakingSize = Size(250, 190);

  /// Opens the pet, or — because the native side reuses windows by name —
  /// hands a new state to the one already on screen.
  static Future<void> show({PetMood mood = PetMood.idle, String? message}) {
    return _send({moodKey: mood.name, messageKey: ?message});
  }

  /// Closes the pet window. A no-op when it is not open.
  static Future<void> dismiss() => closeWindow(windowName);

  static int _nonce = 0;

  static Future<void> _send(Map<String, dynamic> arguments) async {
    // Where the user last parked it, or bottom-right clear of the dock on a
    // first-ever open. Only used when the window is actually created: reuse
    // leaves it wherever it already sits.
    final anchor = await WindowHelper.savedPetAnchor();
    final screen = appWindow.workingScreenRect;
    final position = anchor != null
        ? Offset(anchor.dx - petSize.width, anchor.dy - petSize.height)
        : Offset(
            screen.right - petSize.width - 32,
            screen.bottom - petSize.height - 32,
          );
    // Breadcrumbs on both banks of the channel hop: the 1.11.x invisible
    // pet failed at a different link on different launches of the same
    // binary, and only these prints said which.
    // Spelled-out numbers: release builds strip Offset/Rect.toString down
    // to "Instance of 'Offset'", which is what these prints exist to avoid.
    logR(
      'Pet',
      'openNewWindow -> pos=${position.dx.round()},${position.dy.round()} '
      'screen=${screen.right.round()}x${screen.bottom.round()}',
    );
    await appWindow.openNewWindow(
      name: windowName,
      size: petSize,
      position: position,
      arguments: {...arguments, nonceKey: ++_nonce},
    );
    logR('Pet', 'openNewWindow returned');
  }
}

enum PetMood {
  idle,
  happy;

  static PetMood fromArguments(Map<String, dynamic>? arguments) {
    final raw = arguments?[PetWindowLauncher.moodKey];
    return PetMood.values.firstWhere(
      (mood) => mood.name == raw,
      orElse: () => PetMood.idle,
    );
  }
}

class PetWindowApp extends StatefulWidget {
  const PetWindowApp({super.key, this.arguments});

  final Map<String, dynamic>? arguments;

  @override
  State<PetWindowApp> createState() => _PetWindowAppState();
}

/// How long the pet holds a line before going quiet again.
const _bubbleDuration = Duration(seconds: 6);

class _PetWindowAppState extends State<PetWindowApp> {
  late final Map<String, dynamic>? _initialArguments =
      widget.arguments ?? appWindow.arguments;
  late PetMood _mood = PetMood.fromArguments(_initialArguments);
  late String? _message = _initialArguments?[PetWindowLauncher.messageKey]
      ?.toString();

  int _lastNonce = 0;
  Timer? _hushTimer;
  final _petKey = GlobalKey<_PetState>();

  @override
  void initState() {
    super.initState();
    logR('Pet', 'engine up: window built, args=$_initialArguments');
    // Deferred: the window is still being configured while this frame is
    // built, and resizing into that would race the config's own geometry.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _startHushTimer();
      _resizeFor(speaking: _message != null);
    });
  }

  @override
  void dispose() {
    _hushTimer?.cancel();
    super.dispose();
  }

  void _handleArgumentsChanged(DesktopWindow window) {
    if (!mounted) return;
    final arguments = window.arguments;
    if (arguments == null) return;

    // The sender bumps a nonce on every send, so two identical payloads still
    // read as two events — and a redelivery of one already applied does not.
    final nonce = arguments[PetWindowLauncher.nonceKey];
    if (nonce is int) {
      if (nonce <= _lastNonce) return;
      _lastNonce = nonce;
    }

    final mood = PetMood.fromArguments(arguments);
    setState(() {
      _mood = mood;
      _message = arguments[PetWindowLauncher.messageKey]?.toString();
    });
    if (mood != PetMood.idle) _petKey.currentState?.react();
    _startHushTimer();
    _resizeFor(speaking: _message != null);
  }

  void _startHushTimer() {
    _hushTimer?.cancel();
    if (_message == null) return;
    _hushTimer = Timer(_bubbleDuration, _goQuiet);
  }

  void _goQuiet() {
    if (!mounted || _message == null) return;
    setState(() => _message = null);
    _resizeFor(speaking: false);
  }

  /// Grows and shrinks the window around a FIXED bottom-right corner, where
  /// the creature is anchored — so a bubble appears beside it rather than
  /// shoving it across the screen. Set as a rect, in one native call, so the
  /// move and the resize cannot land on different frames and jump.
  void _resizeFor({required bool speaking}) {
    final target = speaking
        ? PetWindowLauncher.speakingSize
        : PetWindowLauncher.petSize;
    final rect = appWindow.rect;
    if (rect.size == target) return;
    // Anchored to the bottom-right corner, then clamped: with the pet parked
    // near the screen's top or left edge, growing up-left would carry the
    // bubble off-screen. Clamping shifts the anchor instead — the cat budges,
    // the words stay readable.
    final screen = appWindow.workingScreenRect;
    final left = (rect.right - target.width).clamp(
      screen.left,
      screen.right - target.width,
    );
    final top = (rect.bottom - target.height).clamp(
      screen.top,
      screen.bottom - target.height,
    );
    appWindow.rect = Rect.fromLTWH(left, top, target.width, target.height);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Vidra Pet',
      // No theme: the pet paints itself and the window must stay see-through.
      color: Colors.transparent,
      builder: (context, child) => WindowEventListener(
        onArgumentsChanged: _handleArgumentsChanged,
        rebuildOnArgumentsChanged: false,
        child: child ?? const SizedBox.shrink(),
      ),
      // MaterialType.transparency: paints nothing, so the window stays
      // see-through, but it gives text a Material ancestor. Without one,
      // MaterialApp hands Text its debug fallback style and every label in
      // here comes out with yellow double underlines.
      home: Material(
        type: MaterialType.transparency,
        child: Stack(
          children: [
            // The creature keeps its own fixed box in the bottom-right
            // corner, so growing the window for a bubble neither moves nor
            // stretches it. While quiet, this box IS the whole window.
            Positioned(
              right: 0,
              bottom: 0,
              width: PetWindowLauncher.petSize.width,
              height: PetWindowLauncher.petSize.height,
              child: Pet(key: _petKey, mood: _mood),
            ),
            if (_message case final message?)
              Positioned(
                right: 6,
                top: 6,
                child: _SpeechBubble(text: message, onTap: _goQuiet),
              ),
          ],
        ),
      ),
    );
  }
}

class Pet extends StatefulWidget {
  const Pet({super.key, this.mood = PetMood.idle});

  final PetMood mood;

  @override
  State<Pet> createState() => _PetState();
}

/// Movement that turns a press into a window drag. Small enough to feel
/// immediate, large enough that the shake in a normal click is still a click.
const _dragSlop = 2.0;

/// The window-side shell around [PetWidget]: raw-pointer dragging of the
/// whole window, the right-click menu, and the mood channel from the main
/// window. The creature itself — drawing, states, animation — lives in
/// lib/src/pet/.
class _PetState extends State<Pet> {
  final _petController = PetController();
  final _random = math.Random();
  Timer? _behavior;

  @override
  void initState() {
    super.initState();
    _scheduleBehavior();
  }

  @override
  void didUpdateWidget(Pet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mood != widget.mood && widget.mood != PetMood.idle) react();
  }

  @override
  void dispose() {
    _behavior?.cancel();
    _petController.dispose();
    super.dispose();
  }

  /// News from the main window: the design sheet's jump, happy face and all.
  void react() => _petController.jump();

  /// A creature that only stands there is a sticker. Every so often the cat
  /// does something on its own — usually a few steps in place, sometimes a
  /// wink, rarely a jump — and only from rest, never interrupting a gesture
  /// or an announcement already playing.
  void _scheduleBehavior() {
    _behavior = Timer(Duration(seconds: 6 + _random.nextInt(14)), () {
      if (!mounted) return;
      if (_petController.state != PetState.idle) {
        _scheduleBehavior();
        return;
      }
      final roll = _random.nextDouble();
      if (roll < 0.5) {
        _petController.walk();
        _behavior = Timer(
          Duration(milliseconds: 1800 + _random.nextInt(2400)),
          () {
            if (!mounted) return;
            // endWalk, not idle(): a tap mid-stroll replaces the walk with a
            // wink/jump that must not be cut short — but the walk waiting
            // BEHIND it as the fallback still has to be retired, or the pet
            // resumes marching when the one-shot ends and never stops.
            _petController.endWalk();
            _scheduleBehavior();
          },
        );
        return;
      }
      if (roll < 0.85) {
        _petController.wink();
      } else {
        _petController.jump();
      }
      _scheduleBehavior();
    });
  }

  /// Where inside the window the press landed. Held under the cursor for as
  /// long as the drag lasts.
  Offset? _grabbedAt;
  bool _moved = false;

  void _onPointerDown(PointerDownEvent event) {
    if (event.buttons == kSecondaryMouseButton) {
      // No drag from a right press: the menu is the whole gesture.
      _grabbedAt = null;
      _openMenu(event.localPosition);
      return;
    }
    _grabbedAt = event.localPosition;
    _moved = false;
  }

  /// The pet's context menu, drawn by the OS.
  ///
  /// It used to be a panel painted inside this window, and the window is
  /// 130x150 — so the menu had to be small enough to fit the pet, and was
  /// clamped away from the edges to avoid being clipped by them. A native menu
  /// is not part of this window's surface and so is not bounded by it: the
  /// size constraint and the clamping both stop existing.
  ///
  /// No dismiss layer either. `popUp` spins its own run loop and returns only
  /// once the menu closes, which is also what stops the press underneath from
  /// starting a drag.
  Future<void> _openMenu(Offset at) async {
    final picked = await showNativeMenu([
      NativeMenuItem('close', tr('common.close')),
    ], position: at);
    if (picked == 'close') appWindow.close();
  }

  void _onPointerMove(PointerMoveEvent event) {
    final grab = _grabbedAt;
    if (grab == null) return;
    if (!_moved && (event.localPosition - grab).distance <= _dragSlop) return;
    _moved = true;

    // Moved from Dart rather than through appWindow.startDragging(). That
    // call hops to the main thread asynchronously and the native side drops
    // it unless, by the time it lands, the left button is still down AND the
    // window's current event is a mouse down/dragged — so most presses lost
    // the gesture and the pet felt undraggable except by luck. position is a
    // synchronous dart:ffi read/write, so this cannot miss.
    //
    // The cursor sits at window-top-left + localPosition; keeping the grabbed
    // point under it is the rest of the algebra. Re-reading the live position
    // each move makes it self-correcting instead of accumulating drift.
    appWindow.position = appWindow.position + (event.localPosition - grab);
  }

  void _onPointerUp(PointerUpEvent event) {
    // A right press cleared the grab when it opened the menu, and its release
    // still routes here — without this it would react to the menu tap too.
    final wasLeftPress = _grabbedAt != null;
    _grabbedAt = null;
    if (wasLeftPress && _moved) {
      // The drag just ended: remember where the pet was parked, by its
      // bottom-right corner so the speaking-size window stores the same spot.
      WindowHelper.savePetAnchor(appWindow.rect.bottomRight);
    }
    if (wasLeftPress && !_moved) {
      // The tap ritual: wink, then jump. PetWidget's own GestureDetector
      // never sees the tap (the drag Listener owns the pointer), so the
      // sequence is driven from here.
      _tapSequence();
    }
  }

  Future<void> _tapSequence() async {
    _petController.wink();
    await Future.delayed(PetChoreography.durationOf(PetState.wink));
    if (mounted) _petController.jump();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Listener, not GestureDetector: a pan recogniser only fires after
        // kTouchSlop (18px) and has to win an arena against tap and
        // long-press first, which made the drag feel dead over the first few
        // pixels.
        //
        // opaque, so the whole window drags — not just wherever the painter
        // happens to be opaque.
        Positioned.fill(
          child: Listener(
            behavior: HitTestBehavior.opaque,
            onPointerDown: _onPointerDown,
            onPointerMove: _onPointerMove,
            onPointerUp: _onPointerUp,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: IgnorePointer(
                // The shell owns every pointer; the widget only animates.
                //
                // 128 = the 2x cell of the 48x64 sprite, and it leaves the
                // 22px of air above that the jump hop needs — the window's
                // top edge must never decapitate the cat mid-flight.
                child: PetWidget(size: 128, controller: _petController),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// What the pet says. Sized to its text between a floor that keeps the tail
/// under the bubble and a ceiling that keeps it inside the widened window.
class _SpeechBubble extends StatelessWidget {
  const _SpeechBubble({required this.text, required this.onTap});

  final String text;
  final VoidCallback onTap;

  static const _fill = Color(0xF2FFFFFF);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 78, maxWidth: 236),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: _fill,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 10,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Text(
                text,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  height: 1.35,
                  color: Color(0xFF1B2340),
                ),
              ),
            ),
            // The tail, aimed down at the creature's head. Drawn after the
            // body so the two merge instead of showing the body's shadow
            // across the joint.
            Positioned(
              right: 54,
              bottom: -4,
              child: Transform.rotate(
                angle: math.pi / 4,
                child: Container(width: 10, height: 10, color: _fill),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
