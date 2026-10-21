import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liftbig/data/app_database.dart';
import 'package:liftbig/date_key.dart';
import 'package:liftbig/journal/journal_repository.dart';
import 'package:liftbig/model/journal_day.dart';
import 'package:liftbig/sync/sync_controller.dart';
import 'package:liftbig/theme.dart';
import 'package:liftbig/rest/rest_timer_controller.dart';
import 'package:liftbig/reminder/daily_lift_notifications.dart';
import 'package:liftbig/ui/app_shell.dart';
import 'package:liftbig/ui/rest_timer_scope.dart';

void main() {
  testWidgets('calendar reads a logged set from SQLite', (tester) async {
    final journal = JournalRepository(AppDatabase(NativeDatabase.memory()));
    final sync = SyncController(journal: journal, firebaseReady: false);
    addTearDown(() async {
      sync.dispose();
      await journal.db.close();
    });
    await sync.load();
    final today = todayKey();
    await journal.replaceDay(
      JournalDay(
        dateKey: today,
        updatedAt: '2026-10-01T12:00:00.000Z',
        exercises: [
          JournalExercise(
            id: 'ex1',
            sortOrder: 0,
            name: 'Bench Press',
            sets: const [
              JournalSet(
                id: 's1',
                sortOrder: 0,
                reps: '5',
                weight: '135',
              ),
            ],
          ),
        ],
      ),
    );

    tester.view.physicalSize = const Size(400, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final restTimer = RestTimerController(journal: journal);
    addTearDown(restTimer.dispose);
    await restTimer.load();

    await tester.pumpWidget(
      RestTimerScope(
        controller: restTimer,
        child: MaterialApp(
          theme: buildLiftBigTheme(),
          home: AppShell(
            journal: journal,
            sync: sync,
            dailyReminder: NoOpDailyLiftReminderScheduler(),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final now = DateTime.now();
    expect(find.text('LIFTBIG'), findsOneWidget);
    expect(find.text('${monthNames[now.month - 1]} ${now.year}'), findsOneWidget);
    expect(find.text('Bench Press'), findsOneWidget);
    expect(find.textContaining('135 lb'), findsOneWidget);
    expect(find.text('Sync this journal'), findsNothing);
  });
}
