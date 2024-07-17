///Abstraction for random number providers
abstract class RngProvider {
  ///Provides a random integer modulused by the max value
  int nextInt(int max);

  ///provides a random fp64 from 0-1
  double nextDouble();

  ///Shuffles the given list of items using this randomizer
  void shuffle<T>(List<T> n) {
    for (int i = n.length - 1; i > 0; i--) {
      int j = nextInt(i + 1);
      var temp = n[i];
      n[i] = n[j];
      n[j] = temp;
    }
  }
}

///A simple LCG randomizer that we can use for generating grids and things.
///
///The inbuilt Random class is slower and more robust than necessary, but
///even more annoyingly, doesn't provide platform-consistency.
class Rng extends RngProvider {
  int _seed;
  static const int _modulus = 0x7FFFFFFF;
  static const int _multiplier = 16525;
  static const int _increment = 10139223;

  Rng(this._seed) {
    ///Dart is surprisingly inconsistent with how it handles
    ///bits above the 31st, which seems to make the RNG
    //inconsistent across different platforms.
    _seed &= _modulus;
  }

  @override
  int nextInt(int max) {
    _seed = (_multiplier * _seed + _increment) % _modulus;
    return _seed % max;
  }

  @override
  double nextDouble() {
    return nextInt(_modulus) / _modulus;
  }
}
