import 'package:flutter_test/flutter_test.dart';
import 'package:liftbig/utils/distance_units.dart';
import 'package:liftbig/utils/height_entry.dart';

void main() {
  test('metric height carries a rounded centimeter into the next meter', () {
    final entry = heightEntryFromInches(78.74, DistanceUnit.km);
    expect(entry.primary, '2');
    expect(entry.secondary, '0');
  });

  test('imperial height carries a rounded inch into the next foot', () {
    final entry = heightEntryFromInches(71.96, DistanceUnit.mi);
    expect(entry.primary, '6');
    expect(entry.secondary, '0');
  });

  test('five foot eleven stays one meter and about eighty centimeters', () {
    final entry = heightEntryFromInches(71, DistanceUnit.km);
    expect(entry.primary, '1');
    expect(entry.secondary, '80.3');
    final back = inchesFromHeightFields(
      unit: DistanceUnit.km,
      primary: entry.primary,
      secondary: entry.secondary,
    );
    expect(back, closeTo(71, 0.05));
  });

  test('blank height fields clear the stored inches', () {
    expect(
      inchesFromHeightFields(
        unit: DistanceUnit.mi,
        primary: '',
        secondary: '',
      ),
      isNull,
    );
    expect(
      inchesFromHeightFields(
        unit: DistanceUnit.km,
        primary: '0',
        secondary: '0',
      ),
      isNull,
    );
  });
}
