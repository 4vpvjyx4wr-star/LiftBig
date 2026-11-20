import 'distance_units.dart';
import 'weight_units.dart';

/// Feet and inches, or meters and centimeters, for the height fields.
class HeightEntry {
  const HeightEntry({required this.primary, required this.secondary});

  /// Feet when the distance unit is miles, meters when it is kilometers.
  final String primary;

  /// Inches when the distance unit is miles, centimeters when it is kilometers.
  final String secondary;

  static const empty = HeightEntry(primary: '', secondary: '');
}

/// Splits stored inches into the two fields for [unit].
///
/// Rounding is applied to the whole measurement first, so 11.96 in does not
/// display as 11.96 leftover inches and 99.96 cm does not display as 100 cm.
HeightEntry heightEntryFromInches(double? inches, DistanceUnit unit) {
  if (inches == null || !inches.isFinite || inches <= 0) return HeightEntry.empty;
  if (unit == DistanceUnit.km) {
    final totalCm = roundTo(inches * 2.54, 1);
    final meters = totalCm ~/ 100;
    final cm = roundTo(totalCm - meters * 100, 1);
    return HeightEntry(
      primary: '$meters',
      secondary: formatRoundedNumber(cm, 1),
    );
  }
  final totalInches = roundTo(inches, 1);
  final feet = totalInches ~/ 12;
  final inchPart = roundTo(totalInches - feet * 12, 1);
  return HeightEntry(
    primary: '$feet',
    secondary: formatRoundedNumber(inchPart, 1),
  );
}

/// Reads the two height fields back into inches. Empty or zero clears height.
double? inchesFromHeightFields({
  required DistanceUnit unit,
  required String primary,
  required String secondary,
}) {
  if (unit == DistanceUnit.km) {
    final meters = double.tryParse(primary.trim().replaceAll(',', '.')) ?? 0;
    final cm = double.tryParse(secondary.trim().replaceAll(',', '.')) ?? 0;
    final totalCm = meters * 100 + cm;
    if (totalCm <= 0) return null;
    return totalCm / 2.54;
  }
  final feet = double.tryParse(primary.trim().replaceAll(',', '.')) ?? 0;
  final inch = double.tryParse(secondary.trim().replaceAll(',', '.')) ?? 0;
  final total = feet * 12 + inch;
  if (total <= 0) return null;
  return total;
}
