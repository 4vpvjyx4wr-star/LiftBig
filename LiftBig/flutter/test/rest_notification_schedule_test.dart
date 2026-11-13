import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liftbig/rest/rest_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

void main() {
  test('rest end uses the device zone instead of a UTC wall clock', () {
    tz_data.initializeTimeZones();
    final eastern = tz.getLocation('America/New_York');
    final end = DateTime.utc(2026, 11, 6, 15, 37);
    final zoned = zonedRestEnd(end, eastern);
    final utcWall = tz.TZDateTime.utc(2026, 11, 6, 10, 37);

    expect(zoned.location.name, 'America/New_York');
    expect(zoned.millisecondsSinceEpoch, end.millisecondsSinceEpoch);
    expect(zoned.hour, 10);
    expect(zoned.minute, 37);
    expect(zoned.isAfter(utcWall), isTrue);
  });

  test('rest notification uses the bundled tone and an exact alarm when allowed', () {
    final loud = restFinishedNotificationDetails(
      const RestFinishedNotificationOptions(sound: true, vibration: true),
    );
    expect(loud.iOS?.sound, restAlarmSoundFile);
    expect(loud.iOS?.presentSound, isTrue);
    expect(loud.iOS?.interruptionLevel, InterruptionLevel.timeSensitive);
    expect(loud.android?.playSound, isTrue);
    expect(loud.android?.sound, isA<RawResourceAndroidNotificationSound>());
    expect(loud.android?.audioAttributesUsage, AudioAttributesUsage.alarm);
    expect(loud.android?.channelId, 'liftbig_rest_tone_vibe');
    expect(loud.android?.actions?.single.id, restAlarmStopActionId);
    expect(loud.android?.actions?.single.title, 'Stop');
    expect(loud.iOS?.categoryIdentifier, restAlarmDarwinCategoryId);

    final bell = restFinishedNotificationDetails(
      const RestFinishedNotificationOptions(
        sound: true,
        vibration: false,
        soundId: 'bell',
      ),
    );
    expect(bell.iOS?.sound, 'bell.wav');
    expect(bell.android?.sound?.sound, 'bell');
    expect(bell.android?.channelId, 'liftbig_rest_tone_bell');
    expect(bell.android?.actions?.single.id, restAlarmStopActionId);

    final unknown = restFinishedNotificationDetails(
      const RestFinishedNotificationOptions(soundId: 'ringtone'),
    );
    expect(unknown.iOS?.sound, restAlarmSoundFile);

    final quiet = restFinishedNotificationDetails(
      const RestFinishedNotificationOptions(sound: false, vibration: true),
    );
    expect(quiet.iOS?.sound, isNull);
    expect(quiet.iOS?.presentSound, isFalse);
    expect(quiet.android?.playSound, isFalse);
    expect(quiet.android?.sound, isNull);
    expect(quiet.android?.enableVibration, isTrue);
    expect(quiet.android?.channelId, 'liftbig_rest_vibe');

    expect(
      restAlarmAndroidScheduleMode(canScheduleExact: true),
      AndroidScheduleMode.exactAllowWhileIdle,
    );
    expect(
      restAlarmAndroidScheduleMode(canScheduleExact: false),
      AndroidScheduleMode.inexactAllowWhileIdle,
    );
  });
}
