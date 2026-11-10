import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liftbig/data/app_database.dart';
import 'package:liftbig/journal/journal_repository.dart';
import 'package:liftbig/model/journal_day.dart';
import 'package:liftbig/rest/rest_timer_controller.dart';
import 'package:liftbig/theme.dart';
import 'package:liftbig/ui/day_page.dart';
import 'package:liftbig/ui/rest_timer_scope.dart';

void main() {
  testWidgets('opening a day scrolls to the selected exercise', (tester) async {
    final journal = JournalRepository(AppDatabase(NativeDatabase.memory()));
    final restTimer = RestTimerController(journal: journal);
    addTearDown(() async {
      restTimer.dispose();
      await journal.db.close();
    });

    const dateKey = '2026-10-02';
    const targetId = 'ex-target';
    await journal.replaceDay(
      JournalDay(
        dateKey: dateKey,
        updatedAt: '2026-10-02T12:00:00.000Z',
        workoutName: 'Previous day',
        exercises: [
          for (var i = 0; i < 8; i++)
            JournalExercise(
              id: i == 7 ? targetId : 'ex-$i',
              sortOrder: i,
              name: i == 0
                  ? 'Opening Lift'
                  : i == 7
                  ? 'Target Later Lift'
                  : 'Middle Lift $i',
              sets: [
                for (var set = 0; set < 4; set++)
                  JournalSet(
                    id: 'set-$i-$set',
                    sortOrder: set,
                    reps: '8',
                    weight: '135',
                  ),
              ],
            ),
        ],
      ),
    );

    tester.view.physicalSize = const Size(400, 640);
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
            dateKey: dateKey,
            initialExerciseId: targetId,
          ),
        ),
      ),
    );

    Rect? target;
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 50));
      final finder = find.text('Target Later Lift');
      if (finder.evaluate().isEmpty) continue;
      target = tester.getRect(finder);
      if (target.top < 640 && target.bottom > 0) break;
    }

    expect(target, isNotNull);
    expect(target!.top, lessThan(640));
    expect(target.bottom, greaterThan(0));
    expect(tester.getRect(find.text('Opening Lift')).top, lessThan(0));
  });
}
