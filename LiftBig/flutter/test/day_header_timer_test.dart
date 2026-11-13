import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liftbig/data/app_database.dart';
import 'package:liftbig/journal/journal_repository.dart';
import 'package:liftbig/rest/rest_timer_controller.dart';
import 'package:liftbig/theme.dart';
import 'package:liftbig/ui/day_page.dart';
import 'package:liftbig/ui/rest_timer_scope.dart';

void main() {
  testWidgets('the date timer starts a rest, then opens the rest menu', (
    tester,
  ) async {
    final journal = JournalRepository(AppDatabase(NativeDatabase.memory()));
    final restTimer = RestTimerController(journal: journal);
    addTearDown(() async {
      restTimer.dispose();
      await journal.db.close();
    });

    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      RestTimerScope(
        controller: restTimer,
        child: MaterialApp(
          theme: buildLiftBigTheme(),
          home: DayPage(journal: journal, dateKey: '2026-11-10'),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(restTimer.isActive, isFalse);
    await tester.tap(find.byTooltip('Start Rest'));
    for (var i = 0; i < 20 && !restTimer.isActive; i++) {
      await tester.pump(const Duration(milliseconds: 20));
    }
    await tester.pump();
    await tester.pump();
    expect(restTimer.isActive, isTrue);
    expect(find.text('Pause'), findsNothing);

    await tester.tap(find.byIcon(Icons.timer_outlined));
    for (var i = 0; i < 15 && find.text('Pause').evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(find.text('Pause'), findsOneWidget);
    expect(find.text('Reset'), findsOneWidget);
    expect(find.text('Edit'), findsOneWidget);
    expect(find.text('Dismiss'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(restTimer.isRunning, isTrue);
  });

  testWidgets('lift tools stay under the date and out of the log', (
    tester,
  ) async {
    final journal = JournalRepository(AppDatabase(NativeDatabase.memory()));
    final restTimer = RestTimerController(journal: journal);
    addTearDown(() async {
      restTimer.dispose();
      await journal.db.close();
    });

    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      RestTimerScope(
        controller: restTimer,
        child: MaterialApp(
          theme: buildLiftBigTheme(),
          home: DayPage(
            journal: journal,
            dateKey: '2026-11-10',
            underShellHeader: true,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Start Workout'), findsNothing);
    expect(find.byTooltip('Assign a Plan'), findsOneWidget);
    expect(find.byTooltip('Add lift'), findsOneWidget);
    expect(find.byTooltip('Calculator'), findsOneWidget);
    expect(find.byTooltip('Plate Calculator'), findsOneWidget);
    expect(find.byTooltip('1RM Calculator'), findsOneWidget);
    expect(find.byTooltip('Notes'), findsOneWidget);
    expect(find.byTooltip('Clear Day'), findsNothing);
    expect(find.byTooltip('Start Workout'), findsNothing);

    final date = tester.getTopLeft(find.text('November 10, 2026'));
    final plan = tester.getTopLeft(find.byTooltip('Assign a Plan'));
    expect(plan.dy, greaterThan(date.dy));

    await tester.tap(find.byTooltip('Menu'));
    await tester.pumpAndSettle();
    expect(find.text('Add lift'), findsOneWidget);
    expect(find.text('Plan'), findsOneWidget);
    expect(find.text('Clear Day'), findsOneWidget);
    expect(find.text('Notes'), findsWidgets);
  });
}
