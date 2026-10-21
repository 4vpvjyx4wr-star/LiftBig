/// Journal distances are stored in miles; display may use km.
enum DistanceUnit { mi, km }

DistanceUnit distanceUnitFromStored(String? raw) {
  return raw == 'km' ? DistanceUnit.km : DistanceUnit.mi;
}

const double _milesPerKm = 0.6213711922;

double milesToKm(double miles) => miles / _milesPerKm;

double kmToMiles(double km) => km * _milesPerKm;

String formatDistanceFromMiles(double miles, DistanceUnit unit, {int maxDecimals = 2}) {
  if (unit == DistanceUnit.mi) {
    return _trimDecimals(miles, maxDecimals);
  }
  return _trimDecimals(milesToKm(miles), maxDecimals);
}

String distanceUnitLabel(DistanceUnit unit) => unit == DistanceUnit.mi ? 'mi' : 'km';

String formatDistanceWithUnit(double miles, DistanceUnit unit, {int maxDecimals = 2}) {
  final n = formatDistanceFromMiles(miles, unit, maxDecimals: maxDecimals);
  return '$n ${distanceUnitLabel(unit)}';
}

/// Parses user input in display [unit] to miles for storage.
double? displayDistanceToMiles(String raw, DistanceUnit unit) {
  final normalized = raw.trim().replaceAll(',', '.');
  if (normalized.isEmpty) return null;
  final stripped = normalized.replaceAll(
    RegExp(r'\s*(mi|km|miles|kilometers?)\s*$', caseSensitive: false),
    '',
  ).trim();
  final value = double.tryParse(stripped);
  if (value == null || value < 0) return null;
  return unit == DistanceUnit.mi ? value : kmToMiles(value);
}

String milesToDisplayDistanceString(double miles, DistanceUnit unit, {int maxDecimals = 2}) {
  return formatDistanceFromMiles(miles, unit, maxDecimals: maxDecimals);
}

String _trimDecimals(double value, int maxDecimals) {
  final factor = _pow10(maxDecimals);
  final rounded = (value * factor).round() / factor;
  var text = rounded.toString();
  if (text.contains('.')) {
    text = text.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
  }
  return text;
}

double _pow10(int n) {
  var out = 1.0;
  for (var i = 0; i < n; i++) {
    out *= 10;
  }
  return out;
}
