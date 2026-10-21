import 'package:flutter_test/flutter_test.dart';
import 'package:liftbig/reminder/daily_lift_reminder.dart';

void main() {
  test('message falls back to default when custom is blank', () {
    expect(dailyLiftReminderBody(customMessage: null), dailyLiftReminderDefaultBody);
    expect(dailyLiftReminderBody(customMessage: ''), dailyLiftReminderDefaultBody);
    expect(dailyLiftReminderBody(customMessage: '   '), dailyLiftReminderDefaultBody);
    expect(
      dailyLiftReminderBody(customMessage: 'Custom nudge'),
      'Custom nudge',
    );
  });

  test('schedule lists selected days, time, and resolved body', () {
    const settings = DailyLiftReminderSettings(
      enabled: true,
      timeHHmm: '08:30',
      weekdays: [DateTime.monday, DateTime.wednesday, DateTime.friday],
      customMessage: '',
    );
    final entries = buildDailyLiftReminderSchedule(settings);
    expect(entries, hasLength(3));
    expect(entries.map((e) => e.weekday).toList(), [
      DateTime.monday,
      DateTime.wednesday,
      DateTime.friday,
    ]);
    for (final entry in entries) {
      expect(entry.hour, 8);
      expect(entry.minute, 30);
      expect(entry.body, dailyLiftReminderDefaultBody);
      expect(entry.notificationId, dailyLiftReminderNotificationIdForWeekday(entry.weekday));
    }
    expect(
      dailyLiftReminderNotificationIdsForDays(settings.weekdays),
      [9101, 9103, 9105],
    );
  });

  test('disabled reminder produces no schedule entries', () {
    expect(
      buildDailyLiftReminderSchedule(DailyLiftReminderSettings.defaults()),
      isEmpty,
    );
  });
}
