import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liftbig/companion/companion_bridge.dart';
import 'package:liftbig/data/app_database.dart';
import 'package:liftbig/journal/app_settings.dart';
import 'package:liftbig/journal/journal_repository.dart';
import 'package:liftbig/rest/rest_notifications.dart';
import 'package:liftbig/rest/rest_timer_controller.dart';

class _RecordingRestNotifications implements RestNotificationScheduler {
  final List<DateTime> scheduled = [];
  final List<RestFinishedNotificationOptions> options = [];
  var cancels = 0;

  @override
  Future<void> cancelRestFinished() async {
    cancels += 1;
  }

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> requestPermissionIfNeeded() async => true;

  @override
  Future<void> scheduleRestFinished(
    DateTime endTime, {
    RestFinishedNotificationOptions options = RestFinishedNotificationOptions.defaults,
  }) async {
    scheduled.add(endTime);
    this.options.add(options);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('setRemaining moves the end and does not restart the full duration', () async {
    final journal = JournalRepository(AppDatabase(NativeDatabase.memory()));
    final notifications = _RecordingRestNotifications();
    final controller = RestTimerController(
      journal: journal,
      notifications: notifications,
      companion: CompanionBridge(
        channel: const MethodChannel('liftbig/rest_timer_controller_test'),
      ),
    );
    addTearDown(() async {
      controller.dispose();
      await journal.db.close();
    });

    await controller.load();
    await controller.start(
      exerciseId: 'squat',
      exerciseName: 'Back Squat',
      fullSeconds: 90,
    );
    final started = controller.snapshot.endAtEpochMs!;
    await controller.setRemaining(40);

    expect(controller.snapshot.fullSeconds, 90);
    expect(controller.snapshot.paused, isFalse);
    expect(controller.remaining, inInclusiveRange(38, 40));
    expect(controller.snapshot.endAtEpochMs, lessThan(started));
    final moved = DateTime.fromMillisecondsSinceEpoch(
      controller.snapshot.endAtEpochMs!,
    );
    final left = moved.difference(DateTime.now()).inSeconds;
    expect(left, inInclusiveRange(38, 40));
    expect(notifications.scheduled, hasLength(2));
    expect(notifications.cancels, 0);

    await controller.pause();
    await controller.setRemaining(25);
    expect(controller.snapshot.paused, isTrue);
    expect(controller.snapshot.pausedRemainingSeconds, 25);
    expect(controller.snapshot.fullSeconds, 90);
    expect(controller.snapshot.endAtEpochMs, isNull);
    expect(notifications.scheduled, hasLength(2));
    expect(notifications.cancels, 1);
  });

  test('changing the sound setting reschedules the pending notification', () async {
    final journal = JournalRepository(AppDatabase(NativeDatabase.memory()));
    final notifications = _RecordingRestNotifications();
    final controller = RestTimerController(
      journal: journal,
      notifications: notifications,
      companion: CompanionBridge(
        channel: const MethodChannel('liftbig/rest_timer_sound_test'),
      ),
    );
    addTearDown(() async {
      controller.dispose();
      await journal.db.close();
    });

    await controller.load();
    await controller.start(
      exerciseId: 'row',
      exerciseName: 'Barbell Row',
      fullSeconds: 60,
    );
    await journal.saveRestTimerAlertSettings(
      const RestTimerAlertSettings(
        soundEnabled: false,
        vibrationEnabled: true,
        notificationEnabled: true,
      ),
    );
    await controller.reloadAlertSettings();

    expect(notifications.scheduled, hasLength(2));
    expect(notifications.options.last.sound, isFalse);
    expect(notifications.options.last.vibration, isTrue);
    expect(controller.soundEnabled, isFalse);
    expect(controller.snapshot.fullSeconds, 60);
  });
}
