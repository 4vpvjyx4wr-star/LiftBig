import 'package:flutter_test/flutter_test.dart';
import 'package:liftbig/journal/app_settings.dart';
import 'package:liftbig/journal/logged_day.dart';
import 'package:liftbig/journal/progressive_overload.dart';
import 'package:liftbig/journal/strength_standards.dart';
import 'package:liftbig/utils/distance_units.dart';
import 'package:liftbig/utils/weight_units.dart';

void main() {
  group('weight units', () {
    test('lb/kg display round-trip for storage', () {
      expect(displayWeightToLbs('225', WeightUnit.lb), 225);
      final storedKg = displayToStoredLbsString('100', WeightUnit.kg);
      expect(storedKg, isNotNull);
      expect(double.parse(storedKg!), closeTo(220.5, 1));
      expect(
        storedLbsToDisplay('225', WeightUnit.kg),
        isNot('225'),
      );
    });
  });

  group('distance units', () {
    test('mi/km display round-trip for storage', () {
      expect(displayDistanceToMiles('3.1', DistanceUnit.mi), 3.1);
      final miles = displayDistanceToMiles('5', DistanceUnit.km);
      expect(miles, isNotNull);
      expect(milesToDisplayDistanceString(miles!, DistanceUnit.km), '5');
    });
  });

  group('timing defaults', () {
    test('average rest and lift default to 60 seconds', () {
      expect(averageRestSecondsFromSettings(null), defaultAverageRestSeconds);
      expect(averageLiftSecondsFromSettings(null), defaultAverageLiftSeconds);
      expect(
        resolveAverageRestSeconds(storedKeyValue: null, settingsJson: null),
        60,
      );
      expect(
        resolveAverageLiftSeconds(storedKeyValue: null, settingsJson: null),
        60,
      );
    });
  });

  group('body weight prediction', () {
    test('uses configured body weight instead of 180 lb default', () {
      final atDefault = loggedSetFill(
        exerciseName: 'Bench Press',
        libraryId: 'bench-press',
        bodyWeightLbs: defaultAssumedBodyWeightLbs,
        history: const [],
      );
      final at200 = loggedSetFill(
        exerciseName: 'Bench Press',
        libraryId: 'bench-press',
        bodyWeightLbs: 200,
        history: const [],
      );
      expect(atDefault, isNotNull);
      expect(at200, isNotNull);
      expect(
        double.parse(at200!.weight),
        greaterThan(double.parse(atDefault!.weight)),
      );
    });
  });
}
