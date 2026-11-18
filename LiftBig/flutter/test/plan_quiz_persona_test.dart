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
}
