import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liftbig/companion/companion_bridge.dart';
import 'package:liftbig/data/app_database.dart';
import 'package:liftbig/journal/app_settings.dart';
import 'package:liftbig/journal/journal_repository.dart';
import 'package:liftbig/rest/rest_alarm.dart';
import 'package:liftbig/rest/rest_notifications.dart';
import 'package:liftbig/rest/rest_timer_alerts.dart';
import 'package:liftbig/rest/rest_timer_controller.dart';
import 'package:liftbig/rest/rest_timer_state.dart';

class _RecordingRestNotifications implements RestNotificationScheduler {
  final List<DateTime> scheduled = [];
  final List<RestFinishedNotificationOptions> options = [];
  var cancels = 0;
  var delivered = false;

  @override
  Future<void> cancelRestFinished() async {
    cancels += 1;
    delivered = false;
  }

  @override
  Future<void> keepLockScreenRest(RestFinishedNotificationOptions options) async {
    if (options.enabled) delivered = true;
  }

  @override
  Future<bool> restFinishedIsDelivered() async => delivered;

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

  test('reset restarts the running rest and anchored chrome is remembered', () async {
    final journal = JournalRepository(AppDatabase(NativeDatabase.memory()));
    final notifications = _RecordingRestNotifications();
    final controller = RestTimerController(
      journal: journal,
      notifications: notifications,
      companion: CompanionBridge(
        channel: const MethodChannel('liftbig/rest_timer_reset_test'),
      ),
    );
    addTearDown(() async {
      controller.dispose();
      await journal.db.close();
    });

    await controller.load();
    expect(controller.chrome, RestTimerChrome.floating);
    expect(controller.showsAnchored, isFalse);
    await controller.start(
      exerciseId: 'bench',
      exerciseName: 'Bench Press',
      fullSeconds: 30,
    );
    await controller.pause();
    expect(controller.snapshot.paused, isTrue);
    await controller.reset();
    expect(controller.snapshot.paused, isFalse);
    expect(controller.snapshot.fullSeconds, 30);
    expect(controller.isRunning, isTrue);
    expect(controller.remaining, inInclusiveRange(28, 30));

    await controller.setChrome(RestTimerChrome.anchored);
    expect(controller.showsFloatingCard, isFalse);
    expect(controller.showsAnchored, isTrue);
    final again = RestTimerController(
      journal: journal,
      notifications: notifications,
      companion: CompanionBridge(
        channel: const MethodChannel('liftbig/rest_timer_reset_test_2'),
      ),
    );
    addTearDown(again.dispose);
    await again.load();
    expect(again.chrome, RestTimerChrome.anchored);
  });

  test('opening the menu does not pause the countdown', () async {
    final journal = JournalRepository(AppDatabase(NativeDatabase.memory()));
    final controller = RestTimerController(
      journal: journal,
      notifications: _RecordingRestNotifications(),
      companion: CompanionBridge(
        channel: const MethodChannel('liftbig/rest_timer_menu_test'),
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
    controller.setMenuOpen(true);
    expect(controller.snapshot.paused, isFalse);
    expect(controller.isRunning, isTrue);
    expect(controller.menuOpen, isTrue);
  });

  test('expired stored rest loads inactive and a running rest keeps its time', () async {
    final calls = <MethodCall>[];
    const channel = MethodChannel(RestAlarm.channelName);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return true;
        });
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    final journal = JournalRepository(AppDatabase(NativeDatabase.memory()));
    final notifications = _RecordingRestNotifications();
    final controller = RestTimerController(
      journal: journal,
      notifications: notifications,
      companion: CompanionBridge(
        channel: const MethodChannel('liftbig/rest_timer_expired_load'),
      ),
    );
    addTearDown(() async {
      controller.dispose();
      await journal.db.close();
    });
    await journal.saveRestTimerAlertSettings(
      const RestTimerAlertSettings(
        soundEnabled: true,
        vibrationEnabled: false,
        notificationEnabled: true,
        ringUntilStopped: true,
      ),
    );
    await journal.saveRestTimerState(
      RestTimerSnapshot(
        active: true,
        exerciseId: 'row',
        exerciseName: 'Barbell Row',
        fullSeconds: 30,
        paused: false,
        endAtEpochMs: DateTime.now().millisecondsSinceEpoch - 5000,
      ),
    );

    await controller.load();
    await pumpEventQueue();

    expect(controller.isActive, isFalse);
    expect(controller.alarmRinging, isFalse);
    expect(controller.showsFloatingCard, isFalse);
    expect(controller.showsAnchored, isFalse);
    expect(await journal.loadRestTimerState(), isNull);
    expect(calls.where((call) => call.method == 'play'), isEmpty);
    expect(notifications.scheduled, isEmpty);

    final endMs = DateTime.now()
        .add(const Duration(seconds: 75))
        .millisecondsSinceEpoch;
    await journal.saveRestTimerState(
      RestTimerSnapshot(
        active: true,
        exerciseId: 'squat',
        exerciseName: 'Back Squat',
        fullSeconds: 90,
        paused: false,
        endAtEpochMs: endMs,
      ),
    );
    final again = RestTimerController(
      journal: journal,
      notifications: notifications,
      companion: CompanionBridge(
        channel: const MethodChannel('liftbig/rest_timer_running_load'),
      ),
    );
    addTearDown(again.dispose);
    await again.load();

    expect(again.isActive, isTrue);
    expect(again.alarmRinging, isFalse);
    expect(again.isRunning, isTrue);
    expect(again.snapshot.endAtEpochMs, endMs);
    expect(again.snapshot.exerciseName, 'Back Squat');
    expect(again.remaining, inInclusiveRange(70, 75));
    expect(calls.where((call) => call.method == 'play'), isEmpty);
  });

  test('load of an expired or zero rest stays inactive and silent', () async {
    final calls = <MethodCall>[];
    const channel = MethodChannel(RestAlarm.channelName);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return true;
        });
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    Future<void> expectCleared(
      RestTimerSnapshot stored, {
      bool delivered = false,
    }) async {
      final journal = JournalRepository(AppDatabase(NativeDatabase.memory()));
      final notifications = _RecordingRestNotifications()..delivered = delivered;
      final now = DateTime.utc(2026, 11, 18, 12);
      final controller = RestTimerController(
        journal: journal,
        notifications: notifications,
        companion: CompanionBridge(
          channel: MethodChannel(
            'liftbig/rest_timer_zero_${stored.paused}_${stored.endAtEpochMs}',
          ),
        ),
        now: () => now,
      );
      await journal.saveRestTimerAlertSettings(
        const RestTimerAlertSettings(
          soundEnabled: true,
          vibrationEnabled: false,
          notificationEnabled: true,
          ringUntilStopped: true,
        ),
      );
      await journal.saveRestTimerState(stored);
      calls.clear();

      await controller.load();
      await pumpEventQueue();

      expect(controller.alarmRinging, isFalse);
      expect(controller.isActive, isFalse);
      expect(controller.showsFloatingCard, isFalse);
      expect(controller.showsAnchored, isFalse);
      expect(await journal.loadRestTimerState(), isNull);
      expect(notifications.scheduled, isEmpty);
      expect(notifications.cancels, greaterThan(0));
      expect(calls.where((call) => call.method == 'play'), isEmpty);
      controller.dispose();
      await journal.db.close();
    }

    final now = DateTime.utc(2026, 11, 18, 12);
    await expectCleared(
      RestTimerSnapshot(
        active: true,
        exerciseId: 'row',
        exerciseName: 'Barbell Row',
        fullSeconds: 30,
        paused: false,
        endAtEpochMs: now.millisecondsSinceEpoch - 5000,
      ),
    );
    await expectCleared(
      RestTimerSnapshot(
        active: true,
        exerciseId: 'row',
        exerciseName: 'Barbell Row',
        fullSeconds: 30,
        paused: false,
        endAtEpochMs: now.millisecondsSinceEpoch,
      ),
    );
    // Still before endAt, so isExpired is false, but the clock already shows 0.
    await expectCleared(
      RestTimerSnapshot(
        active: true,
        exerciseId: 'row',
        exerciseName: 'Barbell Row',
        fullSeconds: 30,
        paused: false,
        endAtEpochMs: now.millisecondsSinceEpoch + 400,
      ),
      delivered: true,
    );
    await expectCleared(
      RestTimerSnapshot(
        active: true,
        exerciseId: 'row',
        exerciseName: 'Barbell Row',
        fullSeconds: 30,
        paused: true,
        pausedRemainingSeconds: 0,
      ),
    );
  });

  testWidgets('ring until stopped loops the in-app tone until stop or cancel', (
    tester,
  ) async {
    final calls = <MethodCall>[];
    const channel = MethodChannel(RestAlarm.channelName);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return true;
        });
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    final looping = await playRestTimerFinishedAlerts(
      const RestTimerAlertSettings(
        soundEnabled: true,
        vibrationEnabled: false,
        notificationEnabled: true,
        ringUntilStopped: true,
        soundId: 'horn',
      ),
    );
    expect(looping, isTrue);
    expect(calls.single.method, 'play');
    expect(calls.single.arguments, {'loop': true, 'soundId': 'horn'});

    calls.clear();
    final once = await playRestTimerFinishedAlerts(
      const RestTimerAlertSettings(
        soundEnabled: true,
        vibrationEnabled: false,
        notificationEnabled: true,
      ),
    );
    expect(once, isFalse);
    expect(calls.single.arguments, {'loop': false, 'soundId': 'rest_alarm'});

    var now = DateTime.utc(2026, 11, 17, 12);
    final journal = JournalRepository(AppDatabase(NativeDatabase.memory()));
    final controller = RestTimerController(
      journal: journal,
      notifications: _RecordingRestNotifications(),
      companion: CompanionBridge(
        channel: const MethodChannel('liftbig/rest_timer_loop_test'),
      ),
      now: () => now,
    );
    addTearDown(() async {
      controller.dispose();
      await journal.db.close();
    });
    await journal.saveRestTimerAlertSettings(
      const RestTimerAlertSettings(
        soundEnabled: true,
        vibrationEnabled: false,
        notificationEnabled: true,
        ringUntilStopped: true,
      ),
    );
    await controller.load();
    await controller.start(
      exerciseId: 'row',
      exerciseName: 'Barbell Row',
      fullSeconds: 30,
    );
    calls.clear();
    now = now.add(const Duration(seconds: 31));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    expect(controller.alarmRinging, isTrue);
    expect(
      calls.where((call) => call.method == 'play').single.arguments,
      {'loop': true, 'soundId': 'rest_alarm'},
    );

    await journal.db.into(journal.db.localSettings).insertOnConflictUpdate(
      LocalSettingsCompanion.insert(
        key: restTimerTileOffsetKey,
        value: '40.0,180.0',
      ),
    );
    await controller.stopAlarm();
    expect(controller.alarmRinging, isFalse);
    expect(controller.isActive, isTrue);
    expect(controller.chrome, RestTimerChrome.anchored);
    expect(controller.showsAnchored, isTrue);
    final offset = await (journal.db.select(journal.db.localSettings)
          ..where((setting) => setting.key.equals(restTimerTileOffsetKey)))
        .getSingleOrNull();
    expect(offset, isNull);
    expect(calls.where((call) => call.method == 'stopKeepAlive'), isNotEmpty);

    calls.clear();
    await controller.dismiss();
    expect(controller.isActive, isFalse);
    expect(calls.where((call) => call.method == 'stopKeepAlive'), isNotEmpty);
  });
}
