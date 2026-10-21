import 'dart:convert';

const String dailyLiftReminderDefaultBody = "It's time to Lift Big";

const String dailyLiftReminderDefaultTime = '17:00';

/// Notification ids 9101–9107 (Mon–Sun). Rest timer uses 9001.
const int dailyLiftReminderNotificationBaseId = 9100;

int dailyLiftReminderNotificationIdForWeekday(int weekday) {
  if (weekday < DateTime.monday || weekday > DateTime.sunday) {
    throw ArgumentError('weekday must be 1–7');
  }
  return dailyLiftReminderNotificationBaseId + weekday;
}

List<int> dailyLiftReminderNotificationIdsForDays(Iterable<int> weekdays) {
  final ids = weekdays.map(dailyLiftReminderNotificationIdForWeekday).toList()
    ..sort();
  return ids;
}

/// Resolved notification body: empty custom text uses [dailyLiftReminderDefaultBody].
String dailyLiftReminderBody({String? customMessage}) {
  final trimmed = customMessage?.trim() ?? '';
  if (trimmed.isEmpty) return dailyLiftReminderDefaultBody;
  return trimmed;
}

class DailyLiftReminderSettings {
  const DailyLiftReminderSettings({
    required this.enabled,
    required this.timeHHmm,
    required this.weekdays,
    this.customMessage,
  });

  final bool enabled;
  final String timeHHmm;
  final List<int> weekdays;
  final String? customMessage;

  static const allWeekdays = [
    DateTime.monday,
    DateTime.tuesday,
    DateTime.wednesday,
    DateTime.thursday,
    DateTime.friday,
    DateTime.saturday,
    DateTime.sunday,
  ];

  factory DailyLiftReminderSettings.defaults() {
    return const DailyLiftReminderSettings(
      enabled: false,
      timeHHmm: dailyLiftReminderDefaultTime,
      weekdays: allWeekdays,
    );
  }

  String get resolvedBody => dailyLiftReminderBody(customMessage: customMessage);

  DailyLiftReminderSettings copyWith({
    bool? enabled,
    String? timeHHmm,
    List<int>? weekdays,
    String? customMessage,
    bool clearCustomMessage = false,
  }) {
    return DailyLiftReminderSettings(
      enabled: enabled ?? this.enabled,
      timeHHmm: timeHHmm ?? this.timeHHmm,
      weekdays: weekdays ?? this.weekdays,
      customMessage: clearCustomMessage ? null : (customMessage ?? this.customMessage),
    );
  }
}

/// One scheduled weekly nudge (testable without the notification plugin).
class DailyLiftReminderScheduleEntry {
  const DailyLiftReminderScheduleEntry({
    required this.notificationId,
    required this.weekday,
    required this.hour,
    required this.minute,
    required this.body,
  });

  final int notificationId;
  final int weekday;
  final int hour;
  final int minute;
  final String body;
}

/// Builds the entries that would be registered for [settings].
List<DailyLiftReminderScheduleEntry> buildDailyLiftReminderSchedule(
  DailyLiftReminderSettings settings,
) {
  if (!settings.enabled) return const [];
  final parsed = parseReminderTimeHHmm(settings.timeHHmm);
  final days = sanitizeReminderWeekdays(settings.weekdays);
  final body = settings.resolvedBody;
  return [
    for (final day in days)
      DailyLiftReminderScheduleEntry(
        notificationId: dailyLiftReminderNotificationIdForWeekday(day),
        weekday: day,
        hour: parsed.hour,
        minute: parsed.minute,
        body: body,
      ),
  ];
}

class ReminderTimeOfDay {
  const ReminderTimeOfDay({required this.hour, required this.minute});

  final int hour;
  final int minute;
}

ReminderTimeOfDay parseReminderTimeHHmm(String raw) {
  final match = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(raw.trim());
  if (match == null) {
    return const ReminderTimeOfDay(hour: 17, minute: 0);
  }
  final hour = int.tryParse(match.group(1)!);
  final minute = int.tryParse(match.group(2)!);
  if (hour == null ||
      minute == null ||
      hour < 0 ||
      hour > 23 ||
      minute < 0 ||
      minute > 59) {
    return const ReminderTimeOfDay(hour: 17, minute: 0);
  }
  return ReminderTimeOfDay(hour: hour, minute: minute);
}

String formatReminderTimeHHmm(int hour, int minute) {
  return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}

String sanitizeReminderTimeHHmm(String raw) {
  final parsed = parseReminderTimeHHmm(raw);
  return formatReminderTimeHHmm(parsed.hour, parsed.minute);
}

List<int> sanitizeReminderWeekdays(List<int> raw) {
  final out = <int>{};
  for (final day in raw) {
    if (day >= DateTime.monday && day <= DateTime.sunday) {
      out.add(day);
    }
  }
  final list = out.toList()..sort();
  return list;
}

List<int> decodeReminderWeekdays(String? raw) {
  if (raw == null || raw.trim().isEmpty) {
    return DailyLiftReminderSettings.allWeekdays;
  }
  try {
    final decoded = jsonDecode(raw);
    if (decoded is! List) return DailyLiftReminderSettings.allWeekdays;
    final days = decoded.map((e) => e is int ? e : int.tryParse('$e')).whereType<int>();
    final sanitized = sanitizeReminderWeekdays(days.toList());
    return sanitized.isEmpty ? DailyLiftReminderSettings.allWeekdays : sanitized;
  } catch (_) {
    return DailyLiftReminderSettings.allWeekdays;
  }
}

String encodeReminderWeekdays(List<int> weekdays) {
  final sanitized = sanitizeReminderWeekdays(weekdays);
  return jsonEncode(sanitized);
}
