import 'package:flutter_test/flutter_test.dart';
import 'package:word_puzzles/utils/logging.dart';
import 'package:word_puzzles/utils/rng.dart';

void main() {
  test("RNG Seed Consistency", () {
    Rng a = Rng(28395);
    Rng b = Rng(28395);
    expect(a.nextInt(999), equals(b.nextInt(999)));
    expect(a.nextDouble(), equals(b.nextDouble()));
  });

  test("RNG Robustness", () {
    double count = 0;
    double bucketSize = 1e-2;
    List<double> plonks = List<double>.filled(1 + (1 / bucketSize).ceil(), 0);
    for (int i = 0; i < 10; i++) {
      int seed = DateTime.now().millisecondsSinceEpoch;
      Rng r = Rng(seed);
      for (int j = 0; j < 5000; j++) {
        var x = r.nextDouble();
        //the buckets represent an interval
        int a = (x / bucketSize).floor();
        int b = a + 1;
        double frac = x - x.floor();
        plonks[a] = frac;
        plonks[b] = 1 - frac;
        ++count;
      }
    }

    var mean = plonks.reduce((a, b) => a + b) / count;

    // Calculate the variance
    var variance = plonks
            .map((value) => (value - mean) * (value - mean))
            .reduce((a, b) => a + b) /
        count;

    if (variance >= 0.01) {
      logger.w(
          "The RNG algorithm does not provide a good distribution.\nDistribution Nonniformity: ${(100000 * variance).round() / 1000.0}%.");
    } else {
      logger.i(
          "RNG distribution Uniformity: ${100 - (100000 * variance).round() / 1000.0}%.\nUniform RNG distributions indicate good randomneess.");
    }

    expect(variance, lessThan(0.01));
  });
}
