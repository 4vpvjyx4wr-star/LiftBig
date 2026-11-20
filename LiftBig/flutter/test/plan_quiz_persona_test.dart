import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liftbig/catalog/liftbig_catalog.dart';
import 'package:liftbig/plans/custom_plans.dart';
import 'package:liftbig/plans/plan_quiz.dart';

LibraryLift _lift(String id, String name) {
  return LibraryLift(
    id: id,
    name: name,
    muscleGroups: const ['legs'],
    tags: const [],
    equipment: 'Dumbbell',
    summary: '',
    instructions: const [],
    tips: const [],
    cues: const [],
    tutorialUrl: '',
    isCardio: false,
    repBasedCore: false,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('catalog drops the removed gym brand name', () async {
    final raw = await rootBundle.loadString('assets/liftbig_catalog.json');
    final banned = 'Planet ' 'Fitness';
    expect(raw.contains(banned), isFalse);
    expect(raw.contains('apartmentGym'), isTrue);
    expect(raw.contains('Commercial Gym Starter'), isTrue);
    expect(raw.contains('plan-guided-beg-planet-fitness'), isTrue);
    expect(raw.contains('PF Full Body A'), isTrue);
  });

  test('quiz personas match equipment and experience', () async {
    final catalog = await LiftBigCatalog.load();
    final quiz = catalog.quiz;

    final apartment = recommendPlans(
      quiz,
      const QuizAnswers(
        experience: 'beginner',
        goal: 'size',
        daysPerWeek: 3,
        duration: 'standard',
        equipment: 'apartmentGym',
        style: 'balanced',
      ),
    );
    expect(apartment, isNotEmpty);
    expect(apartment.first.entry.equipment, contains('apartmentGym'));
    expect(apartment.first.entry.experienceLevels, contains('beginner'));
    expect(apartment.map((match) => match.entry.id).toSet().length, apartment.length);

    final commercial = recommendPlans(
      quiz,
      const QuizAnswers(
        experience: 'beginner',
        goal: 'strength',
        daysPerWeek: 3,
        duration: 'standard',
        equipment: 'commercialGym',
        style: 'balanced',
      ),
    );
    expect(commercial.first.entry.category, 'beginner');
    expect(commercial.first.entry.equipment, contains('commercialGym'));
    expect(commercial.first.entry.equipment, isNot(contains('apartmentGym')));

    final dumbbell = recommendPlans(
      quiz,
      const QuizAnswers(
        experience: 'beginner',
        goal: 'strength',
        daysPerWeek: 2,
        duration: 'quick',
        equipment: 'dumbbellsOnly',
        style: 'minimalist',
      ),
    );
    expect(dumbbell, isNotEmpty);
    for (final match in dumbbell) {
      expect(match.entry.equipment, contains('dumbbellsOnly'));
      expect(match.entry.days.any((day) => day >= 6), isFalse);
    }

    final experienced = recommendPlans(
      quiz,
      const QuizAnswers(
        experience: 'experienced',
        goal: 'strength',
        daysPerWeek: 4,
        duration: 'standard',
        equipment: 'commercialGym',
        style: 'compound',
      ),
    );
    expect(experienced.first.entry.experienceLevels, contains('experienced'));
    expect(
      experienced.map((match) => match.entry.id),
      isNot(contains('catalog-planet-fitness-starter')),
    );
  });

  test('a built plan is saved into templates json and reads back', () {
    const catalog = LiftBigCatalog(
      lifts: [],
      plans: [],
      starterWorkouts: [],
      quiz: [],
    );
    var next = 0;
    final raw = appendBuiltPlanToTemplatesJson(
      existing: '[{"id":"old","name":"Old Workout"}]',
      planName: 'Hotel Week',
      workouts: [
        BuiltPlanWorkout(name: 'Day A', lifts: [_lift('goblet-squat', 'Goblet Squat')]),
      ],
      createId: () => 'id-${next++}',
    );
    expect(raw, isNotNull);
    final plans = parseCustomPlansFromTemplatesJson(raw, catalog);
    final saved = plans.singleWhere((plan) => plan.name == 'Hotel Week');
    expect(saved.purpose, 'Built by you');
    expect(saved.workouts.single.name, 'Day A');
    expect(saved.workouts.single.lifts.single.name, 'Goblet Squat');
    expect(saved.workouts.single.lifts.single.sets, hasLength(3));
    expect(saved.workouts.single.lifts.single.sets.first.reps, '8-12');
    expect(plans.any((plan) => plan.name == 'Old Workout'), isTrue);
  });

  test('a built plan keeps a custom set count and target reps', () {
    const catalog = LiftBigCatalog(
      lifts: [],
      plans: [],
      starterWorkouts: [],
      quiz: [],
    );
    var next = 0;
    final raw = appendBuiltPlanToTemplatesJson(
      existing: null,
      planName: 'Rep Week',
      workouts: [
        BuiltPlanWorkout(
          name: 'Day A',
          exercises: [
            BuiltPlanExercise(
              lift: _lift('bench-press', 'Bench Press'),
              setCount: 5,
              targetReps: '5-8',
            ),
          ],
        ),
      ],
      createId: () => 'id-${next++}',
    );
    expect(raw, isNotNull);
    final plans = parseCustomPlansFromTemplatesJson(raw, catalog);
    final lift = plans.single.workouts.single.lifts.single;
    expect(lift.name, 'Bench Press');
    expect(lift.sets, hasLength(5));
    expect(lift.sets.map((set) => set.reps), everyElement('5-8'));
  });

  test('editing a built plan replaces that plan and keeps the others', () {
    const catalog = LiftBigCatalog(
      lifts: [],
      plans: [],
      starterWorkouts: [],
      quiz: [],
    );
    var next = 0;
    final first = appendBuiltPlanToTemplatesJson(
      existing: null,
      planName: 'Hotel Week',
      workouts: [
        BuiltPlanWorkout(
          name: 'Day A',
          exercises: [
            BuiltPlanExercise(
              lift: _lift('goblet-squat', 'Goblet Squat'),
              setCount: 3,
              targetReps: '8-12',
            ),
          ],
        ),
      ],
      createId: () => 'id-${next++}',
    );
    final second = appendBuiltPlanToTemplatesJson(
      existing: first,
      planName: 'Beach Week',
      workouts: [
        BuiltPlanWorkout(
          name: 'Push',
          exercises: [
            BuiltPlanExercise(lift: _lift('bench-press', 'Bench Press')),
          ],
        ),
      ],
      createId: () => 'id-${next++}',
    );
    final original = parseCustomPlansFromTemplatesJson(second, catalog)
        .singleWhere((plan) => plan.name == 'Hotel Week');
    final edited = appendBuiltPlanToTemplatesJson(
      existing: second,
      planName: 'Hotel Week Updated',
      replacePlanId: original.id,
      workouts: [
        BuiltPlanWorkout(
          name: 'Day A',
          exercises: [
            BuiltPlanExercise(
              lift: _lift('goblet-squat', 'Goblet Squat'),
              setCount: 4,
              targetReps: '6',
              targetWeight: '40',
            ),
          ],
        ),
        BuiltPlanWorkout(
          name: 'Day B',
          exercises: [
            BuiltPlanExercise(lift: _lift('romanian-deadlift', 'Romanian Deadlift')),
          ],
        ),
      ],
      createId: () => 'id-${next++}',
    );
    final plans = parseCustomPlansFromTemplatesJson(edited, catalog);
    expect(plans.map((plan) => plan.name), containsAll(['Hotel Week Updated', 'Beach Week']));
    expect(plans.where((plan) => plan.name == 'Hotel Week'), isEmpty);
    final saved = plans.singleWhere((plan) => plan.id == original.id);
    expect(saved.workouts, hasLength(2));
    expect(saved.workouts.first.lifts.single.sets, hasLength(4));
    expect(saved.workouts.first.lifts.single.sets.first.reps, '6');
    expect(saved.workouts.first.lifts.single.sets.first.weight, '40');
    expect(saved.workouts.last.name, 'Day B');
  });

  test('a built superset is saved and opens again for editing', () {
    const catalog = LiftBigCatalog(
      lifts: [],
      plans: [],
      starterWorkouts: [],
      quiz: [],
    );
    var next = 0;
    final raw = appendBuiltPlanToTemplatesJson(
      existing: null,
      planName: 'Pairs',
      workouts: [
        BuiltPlanWorkout(
          name: 'Upper',
          exercises: [
            BuiltPlanExercise(
              lift: _lift('bench-press', 'Bench Press'),
              supersetGroupId: 'pair-a',
              supersetLabel: 'A',
              supersetOrder: 0,
            ),
            BuiltPlanExercise(
              lift: _lift('barbell-row', 'Barbell Row'),
              supersetGroupId: 'pair-a',
              supersetLabel: 'A',
              supersetOrder: 1,
            ),
          ],
        ),
      ],
      createId: () => 'id-${next++}',
    );
    final plans = parseCustomPlansFromTemplatesJson(raw, catalog);
    final lifts = plans.single.workouts.single.lifts;
    expect(lifts.map((lift) => lift.supersetGroupId), ['pair-a', 'pair-a']);
    expect(lifts.map((lift) => lift.supersetOrder), [0, 1]);
    expect(lifts.first.supersetLabel, 'A');
  });
}
