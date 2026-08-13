/// What the pet is doing. [idle] and [walk] loop until replaced; [jump] and
/// [wink] play once and fall back to the last looping state.
enum PetState {
  idle,
  walk,
  jump,
  wink;

  bool get loops => this == idle || this == walk;
}
