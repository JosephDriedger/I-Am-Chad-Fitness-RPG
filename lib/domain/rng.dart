/// Small deterministic PRNG (mulberry32).
///
/// Implemented by hand rather than using `dart:math` Random so that a given
/// seed produces the same encounters on every platform and Dart version,
/// which keeps tests and saved expedition seeds reproducible.
library;

class GameRng {
  GameRng(int seed) : _state = seed & 0xFFFFFFFF;

  int _state;

  int _next32() {
    _state = (_state + 0x6D2B79F5) & 0xFFFFFFFF;
    var t = _state;
    t = ((t ^ (t >> 15)) * (t | 1)) & 0xFFFFFFFF;
    t = (t ^ ((t + (((t ^ (t >> 7)) * (t | 61)) & 0xFFFFFFFF)) & 0xFFFFFFFF)) &
        0xFFFFFFFF;
    return (t ^ (t >> 14)) & 0xFFFFFFFF;
  }

  /// Uniform integer in `[0, max)`.
  int nextInt(int max) {
    assert(max > 0);
    return _next32() % max;
  }

  double nextDouble() => _next32() / 4294967296.0;

  bool chance(double probability) => nextDouble() < probability;

  /// In-place Fisher-Yates shuffle; returns the list for chaining.
  List<T> shuffle<T>(List<T> list) {
    for (var i = list.length - 1; i > 0; i--) {
      final j = nextInt(i + 1);
      final tmp = list[i];
      list[i] = list[j];
      list[j] = tmp;
    }
    return list;
  }
}
