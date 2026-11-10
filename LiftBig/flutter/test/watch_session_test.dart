import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liftbig/companion/companion_bridge.dart';
import 'package:liftbig/companion/watch_session.dart';
import 'package:liftbig/model/journal_day.dart';
import 'package:liftbig/utils/weight_units.dart';

JournalExercise _exercise({
  required String id,
  required String name,
  bool isCardio = false,
  List<JournalSet> sets = const [],
}) {
  return JournalExercise(
    id: id,
    sortOrder: 0,
    name: name,
    isCardio: isCardio,
    sets: sets,
  );
}

JournalSet _set({
  required String id,
  required int order,
  required String reps,
  required String weight,
  bool checked = false,
}) {
  return JournalSet(
    id: id,
    sortOrder: order,
    reps: reps,
    weight: weight,
    checked: checked,
  );
}

void main() {
  test('watch session points at the in-progress lift', () {
    final session = buildWatchSession(
      dateKey: '2026-11-06',
      exercises: [
        _exercise(
          id: 'bench',
          name: 'Bench Press',
          sets: [
            _set(id: 'b1', order: 0, reps: '8', weight: '135', checked: true),
            _set(id: 'b2', order: 1, reps: '8', weight: '135', checked: true),
          ],
        ),
        _exercise(
          id: 'row',
          name: 'Barbell Row',
          sets: [
            _set(id: 'r1', order: 0, reps: '8', weight: '115', checked: true),
            _set(id: 'r2', order: 1, reps: '8', weight: '125'),
          ],
        ),
      ],
      restSeconds: 90,
      weightUnit: WeightUnit.lb,
      pro: true,
    );

    expect(session.exerciseId, 'row');
    expect(session.exerciseName, 'Barbell Row');
    expect(session.currentSetIndex, 1);
    final json = session.toJson();
    expect(json.containsKey('slots'), isFalse);
    expect(json['restCancelled'], isFalse);
    expect(phonePayloadClearsWatchRest(json), isFalse);

    final lineup = json['lineup']! as List<Object?>;
    expect(lineup, hasLength(4));
    final first = lineup.first! as Map<String, Object?>;
    final open = lineup[3]! as Map<String, Object?>;
    expect(first.containsKey('weight'), isFalse);
    expect(first['weightDisplay'], '135');
    expect(first['checked'], isTrue);
    expect(open['exerciseId'], 'row');
    expect(open['setIndex'], 1);
    expect(open['weightDisplay'], '125');
    expect(open['checked'], isFalse);
  });

  test('a lineup republish keeps the current set and a running rest', () {
    final lineup = <Map<String, Object?>>[
      {'exerciseId': 'bench', 'setIndex': 0, 'checked': true, 'weightDisplay': '135'},
      {'exerciseId': 'bench', 'setIndex': 1, 'checked': false, 'weightDisplay': '135'},
      {'exerciseId': 'row', 'setIndex': 0, 'checked': false, 'weightDisplay': '115'},
    ];
    final republish = <String, Object?>{
      'version': 1,
      'locked': false,
      'restSeconds': 90,
      'lineup': lineup,
    };

    expect(phonePayloadClearsWatchRest(republish), isFalse);
    expect(
      keptWatchSlotIndex(
        lineup: lineup,
        currentExerciseId: 'row',
        currentSetIndex: 0,
      ),
      2,
    );
    expect(
      keptWatchSlotIndex(
        lineup: lineup,
        currentExerciseId: 'bench',
        currentSetIndex: 1,
      ),
      1,
    );
    expect(
      keptWatchSlotIndex(
        lineup: lineup,
        currentExerciseId: 'gone',
        currentSetIndex: 4,
      ),
      1,
    );
    expect(
      phonePayloadClearsWatchRest({...republish, 'restCancelled': true}),
      isTrue,
    );
    expect(phonePayloadClearsWatchRest({'locked': true, 'reason': 'idle'}), isTrue);
  });

  test('a rep range becomes the top count for companions', () {
    expect(companionReps('8-12'), '12');
    expect(companionReps('12-8'), '12');
    expect(companionReps('12'), '12');
    expect(companionReps('8'), '8');

    final session = buildWatchSession(
      dateKey: '2026-11-10',
      exercises: [
        JournalExercise(
          id: 'squat',
          sortOrder: 0,
          name: 'Back Squat',
          targetReps: '8-12',
          sets: [
            const JournalSet(id: 's1', sortOrder: 0, reps: '', weight: '185'),
            const JournalSet(id: 's2', sortOrder: 1, reps: '8-12', weight: '185'),
          ],
        ),
      ],
      restSeconds: 90,
      weightUnit: WeightUnit.lb,
      pro: true,
    );
    final json = session.toJson();
    expect(json['targetReps'], '12');
    final lineup = json['lineup']! as List<Object?>;
    expect((lineup[0]! as Map)['reps'], '12');
    expect((lineup[1]! as Map)['reps'], '12');

    final running = withWatchRest(
      json,
      const WatchRestPublish(
        soundEnabled: false,
        restEndsAtEpochSeconds: 1700000000,
      ),
    );
    expect(running['soundEnabled'], isFalse);
    expect(running['restEndsAt'], 1700000000);
    expect(running['restCancelled'], isFalse);
    expect(running.containsKey('restPaused'), isTrue);
    expect(phonePayloadClearsWatchRest(running), isFalse);

    final paused = withWatchRest(
      json,
      const WatchRestPublish(
        soundEnabled: true,
        restPaused: true,
        restRemaining: 40,
      ),
    );
    expect(paused.containsKey('restEndsAt'), isFalse);
    expect(paused['restPaused'], isTrue);
    expect(paused['restRemaining'], 40);

    final bridge = CompanionBridge(
      channel: const MethodChannel('liftbig/watch_rest_test'),
    );
    bridge.notePhoneRest(
      const WatchRestPublish(soundEnabled: true, restCancelled: true),
    );
    final raw = '{"version":1,"locked":false,"restSeconds":90}';
    final first = jsonDecode(bridge.annotateSession(raw)) as Map<String, Object?>;
    final second = jsonDecode(bridge.annotateSession(raw)) as Map<String, Object?>;
    expect(first['restCancelled'], isTrue);
    expect(first.containsKey('restEndsAt'), isFalse);
    expect(second['restCancelled'], isFalse);
    expect(phonePayloadClearsWatchRest({
      'locked': false,
      'restCancelled': true,
    }), isTrue);
  });

  test('cardio does not hide the strength lift still in progress', () {
    final exercise = watchExercise([
      _exercise(id: 'run', name: 'Run', isCardio: true),
      _exercise(
        id: 'squat',
        name: 'Back Squat',
        sets: [_set(id: 's1', order: 0, reps: '5', weight: '185')],
      ),
    ]);
    expect(exercise?.id, 'squat');
  });
}
