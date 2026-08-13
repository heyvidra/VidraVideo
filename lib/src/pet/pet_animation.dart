import 'dart:math' as math;

import 'pet_state.dart';

/// One drawable instant of the cat, in design-space units (48x64 grid).
///
/// The painter consumes this blindly; every judgement about HOW the cat
/// moves lives in [PetChoreography], where it can be unit-tested without a
/// canvas.
class PetPose {
  const PetPose({
    this.lift = 0,
    this.squash = 1,
    this.tilt = 0,
    this.legPhase = 0,
    this.legTuck = 0,
    this.armRaise = 0,
    this.armSwing = 0,
    this.tailSway = 0,
    this.leftEyeOpen = 1,
    this.rightEyeOpen = 1,
    this.happy = 0,
  });

  /// Height above the ground, design px. Positive is up.
  final double lift;

  /// Vertical scale about the ground line: <1 crouches, >1 stretches.
  final double squash;

  /// Whole-body lean, radians. Positive tips the cat to its right.
  final double tilt;

  /// Walk cycle, -1..1: which leg is forward.
  final double legPhase;

  /// 0..1: how far the feet are pulled up under the body (airborne pose).
  final double legTuck;

  /// 0..1: how far the arms are lifted away from the body.
  final double armRaise;

  /// Walk-cycle arm counter-swing, -1..1.
  final double armSwing;

  /// -1..1: tail swing about its root.
  final double tailSway;

  /// 0..1 per eye. 0 is fully closed.
  final double leftEyeOpen;
  final double rightEyeOpen;

  /// 0..1: relaxed mouth -> open happy mouth.
  final double happy;
}

/// Turns (state, time 0..1) into a [PetPose]. Pure functions only.
class PetChoreography {
  const PetChoreography._();

  static Duration durationOf(PetState state) => switch (state) {
    PetState.idle => const Duration(milliseconds: 3400),
    PetState.walk => const Duration(milliseconds: 640),
    PetState.jump => const Duration(milliseconds: 950),
    PetState.wink => const Duration(milliseconds: 450),
  };

  static PetPose pose(PetState state, double t) => switch (state) {
    PetState.idle => _idle(t),
    PetState.walk => _walk(t),
    PetState.jump => _jump(t),
    PetState.wink => _wink(t),
  };

  /// Breath, a slow tail stir, and a deterministic blink parked late in the
  /// cycle — no timers, no Random, yet it never looks metronomic because the
  /// three run at different phases.
  static PetPose _idle(double t) {
    final wave = math.sin(t * 2 * math.pi);
    final blinking = t > 0.90 && t < 0.955;
    return PetPose(
      lift: wave * 1.3,
      squash: 1 + wave * 0.012,
      tailSway: math.sin(t * 2 * math.pi + 1.1) * 0.45,
      leftEyeOpen: blinking ? 0 : 1,
      rightEyeOpen: blinking ? 0 : 1,
    );
  }

  static PetPose _walk(double t) {
    final cycle = math.sin(t * 2 * math.pi);
    // Two footfalls per cycle, so the bob runs at double frequency.
    final bob = math.sin(t * 4 * math.pi).abs();
    return PetPose(
      lift: bob * 1.1,
      squash: 1 + bob * 0.01,
      tilt: cycle * 0.025,
      legPhase: cycle,
      armSwing: -cycle,
      tailSway: math.sin(t * 2 * math.pi - 0.9) * 0.7,
    );
  }

  /// crouch -> launch -> airborne pose -> land -> recover.
  ///
  /// The airborne section is the design sheet's jump render: feet tucked
  /// forward under the plush body, arms lifted out, a visible backward lean
  /// and the large spiral tail carrying through the motion. The lift curve is
  /// a sine hump over the airborne window, zero at both ends of it.
  static PetPose _jump(double t) {
    const up = 16.5; // peak height, design px

    if (t < 0.16) {
      // Crouch into the ground.
      final k = t / 0.16;
      return PetPose(
        squash: 1 - 0.14 * _easeOut(k),
        tailSway: -0.15 * k,
        happy: k,
      );
    }
    if (t < 0.78) {
      // Airborne. Pose fades in fast at the start and out by the landing.
      final k = (t - 0.16) / (0.78 - 0.16);
      final air = math.sin(k * math.pi);
      final pose =
          _easeOut((k * 3).clamp(0, 1)) *
          (1 - _easeIn(((k - 0.75) * 4).clamp(0, 1)));
      return PetPose(
        lift: air * up,
        // Stretch on the way up, back to neutral by the top.
        squash: 1 + 0.08 * math.sin((1 - k) * math.pi) * (k < 0.5 ? 1 : 0.25),
        tilt: -0.16 * pose,
        legTuck: pose,
        armRaise: pose,
        tailSway: -0.85 * pose,
        happy: 1,
      );
    }
    if (t < 0.88) {
      // Contact: squash.
      final k = (t - 0.78) / 0.10;
      return PetPose(
        squash: 1 - 0.13 * math.sin(k * math.pi),
        tailSway: 0.25 * math.sin(k * math.pi),
        happy: 1 - k,
      );
    }
    // Recover to neutral.
    return const PetPose();
  }

  /// One eye shuts, holds, and reopens; a small head tilt sells the charm.
  static PetPose _wink(double t) {
    final double closed;
    if (t < 0.25) {
      closed = _easeOut(t / 0.25);
    } else if (t < 0.70) {
      closed = 1;
    } else {
      // Clamped: 0.30/0.30 lands a couple of ulps past 1 in floating point,
      // which would push the reopened eye past fully-open.
      closed = 1 - _easeIn(((t - 0.70) / 0.30).clamp(0.0, 1.0));
    }
    return PetPose(
      rightEyeOpen: 1 - closed,
      tilt: 0.04 * closed,
      happy: closed * 0.5,
    );
  }

  static double _easeOut(double t) => 1 - (1 - t) * (1 - t);
  static double _easeIn(double t) => t * t;
}
