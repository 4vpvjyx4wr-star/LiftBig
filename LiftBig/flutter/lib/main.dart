import 'package:flutter/material.dart';

import 'data/app_database.dart';
import 'journal/journal_repository.dart';
import 'reminder/daily_lift_notifications.dart';
import 'rest/rest_notifications.dart';
import 'rest/rest_timer_controller.dart';
import 'sync/firebase_bootstrap.dart';
import 'sync/sync_controller.dart';
import 'theme.dart';
import 'ui/app_shell.dart';
import 'ui/rest_timer_scope.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final firebaseReady = await initializeFirebaseIfReady();
  final journal = JournalRepository(AppDatabase.defaults());
  final sync = SyncController(journal: journal, firebaseReady: firebaseReady);
  await sync.load();
  final notifications = FlutterRestNotificationScheduler();
  await notifications.initialize();
  final dailyReminder = FlutterDailyLiftReminderScheduler(
    restScheduler: notifications,
  );
  final reminderSettings = await journal.loadDailyLiftReminderSettings();
  await dailyReminder.applySettings(reminderSettings);
  final restTimer = RestTimerController(
    journal: journal,
    notifications: notifications,
  );
  await restTimer.load();
  runApp(
    LiftBigApp(
      journal: journal,
      sync: sync,
      restTimer: restTimer,
      dailyReminder: dailyReminder,
    ),
  );
}

class LiftBigApp extends StatefulWidget {
  const LiftBigApp({
    super.key,
    required this.journal,
    required this.sync,
    required this.restTimer,
    required this.dailyReminder,
  });

  final JournalRepository journal;
  final SyncController sync;
  final RestTimerController restTimer;
  final DailyLiftReminderScheduler dailyReminder;

  @override
  State<LiftBigApp> createState() => _LiftBigAppState();
}

class _LiftBigAppState extends State<LiftBigApp> {
  @override
  void dispose() {
    widget.restTimer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RestTimerScope(
      controller: widget.restTimer,
      child: MaterialApp(
        title: 'LiftBig',
        debugShowCheckedModeBanner: false,
        theme: buildLiftBigTheme(),
        scrollBehavior: const LiftBigScrollBehavior(),
        home: AppShell(
          journal: widget.journal,
          sync: widget.sync,
          dailyReminder: widget.dailyReminder,
        ),
      ),
    );
  }
}

/// Clamps scroll at content edges and disables overscroll glow/stretch app-wide.
final class LiftBigScrollBehavior extends MaterialScrollBehavior {
  const LiftBigScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const ClampingScrollPhysics();
  }

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }
}
