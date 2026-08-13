import 'dart:ui';

import 'package:flutter/animation.dart' show AlwaysStoppedAnimation;
import 'package:flutter_test/flutter_test.dart';
import 'package:vidra/src/pet/pet_animation.dart';
import 'package:vidra/src/pet/pet_controller.dart';
import 'package:vidra/src/pet/pet_painter.dart';
import 'package:vidra/src/pet/pet_state.dart';

void main() {
  group('PetChoreography', () {
    test('jump actually leaves the ground and strikes the airborne pose', () {
      final top = PetChoreography.pose(PetState.jump, 0.47);
      expect(top.lift, greaterThan(10));
      expect(top.legTuck, greaterThan(0.8));
      expect(top.armRaise, greaterThan(0.8));
      expect(top.tilt, isNot(0));
      // And it is not just idle shifted upwards: it starts and ends grounded.
      expect(PetChoreography.pose(PetState.jump, 0.0).lift, 0);
      expect(PetChoreography.pose(PetState.jump, 1.0).lift, 0);
    });

    test('walk alternates legs across the cycle', () {
      final a = PetChoreography.pose(PetState.walk, 0.25).legPhase;
      final b = PetChoreography.pose(PetState.walk, 0.75).legPhase;
      expect(a.sign, isNot(b.sign));
    });

    test('wink closes exactly one eye and reopens it', () {
      final held = PetChoreography.pose(PetState.wink, 0.45);
      expect(held.rightEyeOpen, 0);
      expect(held.leftEyeOpen, 1);
      final done = PetChoreography.pose(PetState.wink, 1.0);
      expect(done.rightEyeOpen, 1);
    });

    test('idle breathes without ever un-grounding the cat', () {
      for (var i = 0; i <= 20; i++) {
        final pose = PetChoreography.pose(PetState.idle, i / 20);
        expect(pose.lift.abs(), lessThan(3));
        expect(pose.legTuck, 0);
      }
    });
  });

  group('PetController', () {
    test('one-shot falls back to the last looping state', () {
      final c = PetController();
      c.walk();
      c.jump();
      expect(c.state, PetState.jump);
      c.onOneShotComplete();
      expect(c.state, PetState.walk);
    });

    test('re-requesting the same one-shot restarts it', () {
      final c = PetController();
      c.jump();
      final g = c.generation;
      c.jump();
      expect(c.generation, greaterThan(g));
    });

    test('endWalk stops a walk in progress', () {
      final c = PetController();
      c.walk();
      c.endWalk();
      expect(c.state, PetState.idle);
    });

    test('endWalk retires a walk pending behind a one-shot', () {
      // The forever-march bug: behaviour starts a stroll (base=walk), a tap
      // interrupts it with a wink, the stroll's stop timer fires mid-wink.
      final c = PetController();
      c.walk();
      c.wink();
      c.endWalk();
      expect(c.state, PetState.wink, reason: 'the one-shot must not be cut');
      c.onOneShotComplete();
      expect(
        c.state,
        PetState.idle,
        reason: 'the retired walk must not resume',
      );
    });
  });

  test(
    'PetPainter paints every state across the timeline without throwing',
    () {
      for (final state in PetState.values) {
        for (var i = 0; i <= 10; i++) {
          final recorder = PictureRecorder();
          PetPainter(
            pose: PetChoreography.pose(state, i / 10),
          ).paint(Canvas(recorder), const Size(96, 128));
          recorder.endRecording().dispose();
        }
      }
      // The repaint-driven constructor takes the same path.
      final recorder = PictureRecorder();
      PetPainter.animated(
        progress: const AlwaysStoppedAnimation(0.5),
        poseFor: (t) => PetChoreography.pose(PetState.jump, t),
      ).paint(Canvas(recorder), const Size(96, 128));
      recorder.endRecording().dispose();
    },
  );
}
