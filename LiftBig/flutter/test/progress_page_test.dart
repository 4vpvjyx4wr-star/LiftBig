import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liftbig/data/app_database.dart';
import 'package:liftbig/journal/journal_repository.dart';
import 'package:liftbig/model/journal_day.dart';
import 'package:liftbig/theme.dart';
import 'package:liftbig/ui/progress_page.dart';
import 'package:liftbig/utils/weight_units.dart';

void main() {
  testWidgets('progress shows stored pounds in the selected unit', (tester) async {
    final journal = JournalRepository(AppDatabase(NativeDatabase.memory()));
    addTearDown(journal.db.close);
    await journal.setWeightUnit(WeightUnit.kg);
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
              JournalSet(id: 'work', sortOrder: 0, reps: '5', weight: '225'),
            ],
          ),
        ],
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: buildLiftBigTheme(),
        home: Scaffold(body: ProgressPage(journal: journal)),
      ),
    );
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 300));
    });
    await tester.pump();

    expect(find.textContaining('102 kg'), findsWidgets);
    expect(find.text('1 trained day · 510 kg moved'), findsOneWidget);
    expect(find.textContaining('225 lb'), findsNothing);
    expect(find.text('day streak'), findsNothing);
  });
}
