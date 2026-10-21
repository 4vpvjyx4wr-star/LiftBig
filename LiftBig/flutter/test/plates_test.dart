import 'package:flutter_test/flutter_test.dart';
import 'package:liftbig/utils/plates.dart';

void main() {
  test('calculatePlates matches Vue example for 225 on a 45 bar', () {
    const target = 225.0;
    const bar = 45.0;
    final result = calculatePlates(target, bar, plateSizesLb);
    expect(result.plates, [45, 45]);
    expect(result.remainder, 0);
    expect(totalWeightLb(bar, result.plates), target);
    expect(platesAreExact(result.remainder), isTrue);
  });
}
