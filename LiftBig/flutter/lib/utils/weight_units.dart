/// Journal weights are stored in pounds; display may use kg.
enum WeightUnit { lb, kg }

WeightUnit weightUnitFromStored(String? raw) {
  return raw == 'kg' ? WeightUnit.kg : WeightUnit.lb;
}

const double _lbsPerKg = 2.2046226218;

double lbsToKg(double lbs) => lbs / _lbsPerKg;

double kgToLbs(double kg) => kg * _lbsPerKg;

double roundTo(double value, int decimals) {
  final factor = _pow10(decimals);
  return (value * factor).round() / factor;
}

double _pow10(int n) {
  var out = 1.0;
  for (var i = 0; i < n; i++) {
    out *= 10;
  }
  return out;
}

String formatWeightFromLbs(double lbs, WeightUnit unit, {int maxDecimals = 1}) {
  if (unit == WeightUnit.lb) {
    return formatRoundedNumber(lbs, maxDecimals);
  }
  return formatRoundedNumber(lbsToKg(lbs), maxDecimals);
}

/// `roundTo(...).toString()` turns 35 into `35.0`. Whole numbers drop that suffix.
String formatRoundedNumber(double value, int decimals) {
  final rounded = roundTo(value, decimals);
  if (!rounded.isFinite) return '';
  if (rounded == rounded.roundToDouble()) return '${rounded.round()}';
  final text = rounded.toString();
  if (!text.contains('.')) return text;
  return text.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
}

String formatWeightWithUnit(double lbs, WeightUnit unit, {int maxDecimals = 1}) {
  final n = formatWeightFromLbs(lbs, unit, maxDecimals: maxDecimals);
  return unit == WeightUnit.lb ? '$n lb' : '$n kg';
}

/// Parses user input in display [unit] to pounds for internal math.
double? displayWeightToLbs(String raw, WeightUnit unit) {
  final normalized = raw.trim().replaceAll(',', '.');
  if (normalized.isEmpty) return null;
  final value = double.tryParse(normalized);
  if (value == null || value <= 0) return null;
  return unit == WeightUnit.lb ? value : kgToLbs(value);
}

/// Pounds to a display-unit number string for inputs/results.
String lbsToDisplayWeightString(double lbs, WeightUnit unit, {int maxDecimals = 1}) {
  return formatWeightFromLbs(lbs, unit, maxDecimals: maxDecimals);
}

const int weightPickerMaxLbs = 500;
const int weightPickerStepLbs = 5;
const double weightPickerStepKg = 2.5;

double weightPickerMaxForUnit(WeightUnit unit) {
  if (unit == WeightUnit.lb) return weightPickerMaxLbs.toDouble();
  return roundTo(lbsToKg(weightPickerMaxLbs.toDouble()), 0);
}

double weightPickerStepForUnit(WeightUnit unit) {
  return unit == WeightUnit.lb ? weightPickerStepLbs.toDouble() : weightPickerStepKg;
}

/// Stored pounds → display string for set fields and pickers.
String storedLbsToDisplay(String raw, WeightUnit unit) {
  final lbs = double.tryParse(raw.trim().replaceAll(',', '.'));
  if (lbs == null || raw.trim().isEmpty) return raw;
  return lbsToDisplayWeightString(lbs, unit);
}

/// Display string → pounds stored in SQLite.
String? displayToStoredLbsString(String raw, WeightUnit unit) {
  final lbs = displayWeightToLbs(raw, unit);
  if (lbs == null) return raw.trim().isEmpty ? '' : null;
  return formatPredictedWeightLbs(lbs);
}

String formatPredictedWeightLbs(double lbs) {
  if (lbs.isNaN || lbs.isInfinite) return '';
  final scaled = (lbs * 1000).round() / 1000;
  if (scaled == scaled.roundToDouble()) return '${scaled.round()}';
  final text = scaled.toString();
  if (!text.contains('.')) return text;
  return text
      .replaceFirst(RegExp(r'0+$'), '')
      .replaceFirst(RegExp(r'\.$'), '');
}

List<String> weightPickerOptionsFor(WeightUnit unit) {
  if (unit == WeightUnit.lb) {
    return [
      for (var lbs = weightPickerMaxLbs; lbs >= 0; lbs -= weightPickerStepLbs)
        '$lbs',
    ];
  }
  final maxKg = weightPickerMaxForUnit(unit);
  final step = weightPickerStepKg;
  final out = <String>[];
  for (var kg = maxKg; kg >= 0; kg -= step) {
    out.add(formatRoundedNumber(kg, 1));
  }
  return out;
}

String? snapWeightOptionFor(String raw, WeightUnit unit) {
  final lbs = displayWeightToLbs(raw, unit);
  if (lbs == null) {
    final parsed = double.tryParse(raw.trim().replaceAll(',', '.'));
    if (parsed == null || parsed.isNaN || parsed < 0) return null;
    if (unit == WeightUnit.lb) {
      final snapped = (parsed / weightPickerStepLbs).round() * weightPickerStepLbs;
      return '${snapped.clamp(0, weightPickerMaxLbs)}';
    }
    final snapped = (parsed / weightPickerStepKg).round() * weightPickerStepKg;
    return roundTo(snapped.clamp(0, weightPickerMaxForUnit(unit)), 1).toString();
  }
  if (unit == WeightUnit.lb) {
    final snapped = (lbs / weightPickerStepLbs).round() * weightPickerStepLbs;
    return '${snapped.clamp(0, weightPickerMaxLbs)}';
  }
  final kg = lbsToKg(lbs);
  final snapped = (kg / weightPickerStepKg).round() * weightPickerStepKg;
  return roundTo(snapped.clamp(0, weightPickerMaxForUnit(unit)), 1).toString();
}
