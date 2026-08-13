import 'package:flutter/foundation.dart';

import 'pet_state.dart';

/// Drives a [PetWidget] from outside: `controller.jump()` and the cat jumps.
///
/// The controller only decides WHAT the pet is doing; the widget owns the
/// ticker and reports back when a one-shot (jump, wink) finishes so the pet
/// can fall back to whatever looping state was last requested.
class PetController extends ChangeNotifier {
  PetState _state = PetState.idle;

  /// The looping state to return to after a one-shot.
  PetState _base = PetState.idle;

  /// Bumped on every request, so asking for the same one-shot twice restarts
  /// it instead of being swallowed by a `state == newState` check.
  int _generation = 0;

  PetState get state => _state;
  int get generation => _generation;

  void idle() => _request(PetState.idle);
  void walk() => _request(PetState.walk);
  void jump() => _request(PetState.jump);
  void wink() => _request(PetState.wink);

  void _request(PetState next) {
    if (next.loops) _base = next;
    _state = next;
    _generation++;
    notifyListeners();
  }

  /// Called by the widget when a one-shot animation completes.
  void onOneShotComplete() {
    if (_state.loops) return;
    _state = _base;
    _generation++;
    notifyListeners();
  }

  /// Ends a walk without cutting short whatever else is playing: walking now
  /// stops now; a walk merely PENDING as the fallback behind a one-shot is
  /// retired to idle. Without the second half, a walk interrupted by a tap
  /// becomes the fallback state and nothing ever stops it again.
  void endWalk() {
    if (_state == PetState.walk) {
      idle();
      return;
    }
    if (_base == PetState.walk) _base = PetState.idle;
  }
}
