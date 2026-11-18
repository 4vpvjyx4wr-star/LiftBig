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
  testWidgets('an empty day offers Rest Day and Clear Rest', (tester) async {
    final journal = JournalRepository(AppDatabase(NativeDatabase.memory()));
    final restTimer = RestTimerController(journal: journal);
    addTearDown(() async {
      restTimer.dispose();
      await journal.db.close();
    });

    await tester.pumpWidget(
      RestTimerScope(
        controller: restTimer,
        child: MaterialApp(
          theme: buildLiftBigTheme(),
          home: DayPage(journal: journal, dateKey: '2026-03-01'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Rest Day'), findsOneWidget);
    expect(find.text('zzz'), findsNothing);

    await tester.tap(find.text('Rest Day'));
    await tester.pumpAndSettle();
    expect(find.text('Clear Rest'), findsOneWidget);
  });
}
