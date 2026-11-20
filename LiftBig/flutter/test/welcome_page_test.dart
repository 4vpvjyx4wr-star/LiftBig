import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liftbig/data/app_database.dart';
import 'package:liftbig/journal/journal_repository.dart';
import 'package:liftbig/model/journal_day.dart';
import 'package:liftbig/progress/lift_progress.dart';
import 'package:liftbig/theme.dart';
import 'package:liftbig/ui/welcome_page.dart';

void main() {
  testWidgets('startup screen offers the quiz, shuffle, paste, and continue', (
    tester,
  ) async {
    var continued = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildLiftBigTheme(),
        home: WelcomePage(
          onQuiz: () {},
          onShuffle: () {},
          onPaste: () {},
          onContinue: () => continued++,
        ),
      ),
    );

    expect(find.text('Start with a Plan'), findsOneWidget);
    expect(find.text('Take the Quiz'), findsOneWidget);
    expect(find.text('Shuffle a Workout'), findsOneWidget);
    expect(find.text('Paste a Plan'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    expect(continued, 1);
  });

  test('welcome stays until it is dismissed or a working set exists', () async {
    final journal = JournalRepository(AppDatabase(NativeDatabase.memory()));
    addTearDown(journal.db.close);
    expect(await journal.isWelcomeDismissed(), isFalse);
    expect((await journal.allDays()).any(dayHasLoggedWork), isFalse);

    await journal.replaceDay(
      JournalDay(
        dateKey: '2026-03-01',
        updatedAt: '2026-03-01T00:00:00.000Z',
        exercises: [
          JournalExercise(
            id: 'bench',
            sortOrder: 0,
            name: 'Bench Press',
            sets: [
              JournalSet(
                id: 'work',
                sortOrder: 0,
                reps: '5',
                weight: '135',
              ),
            ],
          ),
        ],
      ),
    );
    expect((await journal.allDays()).any(dayHasLoggedWork), isTrue);

    await journal.setWelcomeDismissed();
    expect(await journal.isWelcomeDismissed(), isTrue);
    expect(cloudSyncedPreferenceKeys.contains('welcome_dismissed'), isFalse);
  });
}
