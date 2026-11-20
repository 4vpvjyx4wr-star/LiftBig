import 'package:flutter_test/flutter_test.dart';
import 'package:liftbig/utils/weight_units.dart';

void main() {
  test('typed body weight converts with the unit that was on screen', () {
    expect(
      bodyWeightFieldAfterUnitChange(
        raw: '180',
        from: WeightUnit.lb,
        to: WeightUnit.kg,
        storedLbs: 200,
      ),
      '81.6',
    );
    expect(
      bodyWeightFieldAfterUnitChange(
        raw: '81.6',
        from: WeightUnit.kg,
        to: WeightUnit.lb,
        storedLbs: null,
      ),
      '179.9',
    );
  });

  test('empty body weight uses the stored pounds', () {
    expect(
      bodyWeightFieldAfterUnitChange(
        raw: '',
        from: WeightUnit.lb,
        to: WeightUnit.kg,
        storedLbs: 180,
      ),
      '81.6',
    );
    expect(
      bodyWeightFieldAfterUnitChange(
        raw: '   ',
        from: WeightUnit.kg,
        to: WeightUnit.lb,
        storedLbs: null,
      ),
      isNull,
    );
  });

  test('a displayed stored weight converts back to the same pounds', () {
    expect(
      bodyWeightFieldAfterUnitChange(
        raw: '81.6',
        from: WeightUnit.kg,
        to: WeightUnit.lb,
        storedLbs: 180,
      ),
      '180',
    );
    expect(
      bodyWeightFieldAfterUnitChange(
        raw: '180',
        from: WeightUnit.lb,
        to: WeightUnit.kg,
        storedLbs: 180,
      ),
      '81.6',
    );
  });

  test('unreadable body weight is left alone', () {
    expect(
      bodyWeightFieldAfterUnitChange(
        raw: 'abc',
        from: WeightUnit.lb,
        to: WeightUnit.kg,
        storedLbs: 180,
      ),
      isNull,
    );
  });
}
