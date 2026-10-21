/// Calendar keys use the device's local date, matching the Vue app (`YYYY-MM-DD`).
String toDateKey(DateTime date) {
  final year = date.year.toString().padLeft(4, '0');
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}

String todayKey([DateTime? now]) => toDateKey(now ?? DateTime.now());

final RegExp _dateKeyPattern = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$');

bool isValidDateKey(String key) {
  final match = _dateKeyPattern.firstMatch(key);
  if (match == null) return false;
  final year = int.parse(match.group(1)!);
  final month = int.parse(match.group(2)!);
  final day = int.parse(match.group(3)!);
  final parsed = DateTime(year, month, day);
  return parsed.year == year && parsed.month == month && parsed.day == day;
}

const monthNames = <String>[
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

const weekdayLabels = <String>[
  'SUN',
  'MON',
  'TUE',
  'WED',
  'THU',
  'FRI',
  'SAT',
];

String formatDisplayDate(String dateKey) {
  final parts = dateKey.split('-');
  final year = int.parse(parts[0]);
  final month = int.parse(parts[1]);
  final day = int.parse(parts[2]);
  return '${monthNames[month - 1]} $day, $year';
}

/// Calendar card date: `10-06-2026` for October 6, 2026. Month and day are zero-padded.
String formatNumericDate(String dateKey) {
  final parts = dateKey.split('-');
  if (parts.length != 3) return dateKey;
  final year = parts[0].padLeft(4, '0');
  final month = parts[1].padLeft(2, '0');
  final day = parts[2].padLeft(2, '0');
  return '$month-$day-$year';
}

DateTime parseDateKey(String dateKey) {
  final parts = dateKey.split('-');
  return DateTime(
    int.parse(parts[0]),
    int.parse(parts[1]),
    int.parse(parts[2]),
  );
}

/// Adds [deltaDays] in local calendar days, matching the Vue `addDaysToDateKey`.
String addDaysToDateKey(String dateKey, int deltaDays) {
  final parts = parseDateKey(dateKey);
  return toDateKey(
    DateTime(parts.year, parts.month, parts.day + deltaDays),
  );
}
