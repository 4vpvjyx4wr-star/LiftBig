import 'package:flutter_test/flutter_test.dart';
import 'package:liftbig/catalog/liftbig_catalog.dart';
import 'package:liftbig/plans/plan_quiz.dart';
import 'package:liftbig/plans/workout_shuffle.dart';
import 'package:liftbig/ui/shell_tabs.dart';

LibraryLift sampleLift({
  required String id,
  required String name,
  required List<String> muscles,
  required String equipment,
  bool cardio = false,
  List<String> tags = const [],
}) {
  return LibraryLift(
    id: id,
    name: name,
    muscleGroups: muscles,
    tags: tags,
    equipment: equipment,
    summary: '',
    instructions: const [],
    tips: const [],
    cues: const [],
    tutorialUrl: '',
    isCardio: cardio,
    repBasedCore: false,
  );
}

void main() {
  test('bottom bar order matches the Vue shell', () {
    expect(ShellTab.values.map((tab) => tab.label), [
      'Home',
      'Progress',
      'LIFT',
      'Plans',
      'Library',
    ]);
    expect(ShellTab.lift.opens, 'Today');
    expect(ShellTab.home.opens, 'Calendar');
    expect(ShellTab.library.opens, 'Lift library');
  });

  test('quiz prefers the plan that matches experience, days, and goal', () {
    const beginner = QuizEntry(
      id: 'beginner',
      title: 'Beginner Full Body',
      description: 'Three days',
      experienceLevels: ['beginner'],
      goals: ['strength'],
      days: [3],
      duration: ['standard'],
      equipment: ['commercialGym'],
      styles: ['balanced'],
      difficulty: 'Beginner',
      estimatedMinutes: 55,
      primaryMuscles: ['Full body'],
      progressionStyle: 'Double progression',
      goalTag: 'Foundation',
      category: 'beginner',
      workoutIds: ['full-body'],
    );
    const elite = QuizEntry(
      id: 'elite',
      title: 'Elite Split',
      description: 'Six days',
      experienceLevels: ['liftaholic'],
      goals: ['size'],
      days: [6],
      duration: ['long'],
      equipment: ['commercialGym'],
      styles: ['bodybuilding'],
      difficulty: 'Elite',
      estimatedMinutes: 90,
      primaryMuscles: ['Full body'],
      progressionStyle: 'Volume',
      goalTag: 'Size',
      category: 'liftaholic',
      workoutIds: [],
    );

    final matches = recommendPlans(
      [elite, beginner],
      const QuizAnswers(
        experience: 'beginner',
        goal: 'strength',
        daysPerWeek: 3,
        duration: 'standard',
        equipment: 'commercialGym',
        style: 'balanced',
      ),
    );

    expect(matches.first.entry.id, 'beginner');
    expect(matches.first.badge, 'Best Match');
    expect(matches.first.score, greaterThan(matches.last.score));
  });

  test('shuffle uses equipment, focus, and the time budget', () {
    final library = [
      sampleLift(
        id: 'bench',
        name: 'Barbell Bench Press',
        muscles: ['chest', 'triceps'],
        equipment: 'Barbell',
        tags: ['compound', 'push'],
      ),
      sampleLift(
        id: 'row',
        name: 'Barbell Row',
        muscles: ['back'],
        equipment: 'Barbell',
        tags: ['compound', 'pull'],
      ),
      sampleLift(
        id: 'curl',
        name: 'Dumbbell Curl',
        muscles: ['biceps'],
        equipment: 'Dumbbell',
        tags: ['isolation'],
      ),
      sampleLift(
        id: 'bike',
        name: 'Bike',
        muscles: const [],
        equipment: 'Machine',
        cardio: true,
      ),
    ];
    var roll = 0.0;
    final workout = buildShuffledWorkout(
      library,
      const ShuffleRequest(
        equipment: ['Barbell'],
        focus: ['push'],
        includeCardio: false,
        targetMinutes: 30,
        secondsPerLift: 60,
        secondsPerRest: 60,
      ),
      random: () => roll += 0.1,
    );

    expect(workout.lifts.map((lift) => lift.id), ['bench']);
    expect(workout.minutes, greaterThan(0));
  });

  test('cardio and sports gear are not mixed into the strength list', () {
    final types = [
      'Barbell',
      'Bodyweight',
      'Treadmill',
      'Pool',
      'Stationary bike',
    ];
    expect(strengthGearChoices(types), ['Barbell', 'Bodyweight']);
    expect(gearPresentInCatalog(cardioGear, types), [
      'Bodyweight',
      'Stationary bike',
      'Treadmill',
    ]);
    expect(gearPresentInCatalog(sportsGear, types), ['Pool']);
  });

  test('choosing treadmill includes that cardio without the include switch', () {
    final workout = buildShuffledWorkout(
      [
        sampleLift(
          id: 'run',
          name: 'Treadmill run',
          muscles: const [],
          equipment: 'Treadmill',
          cardio: true,
        ),
        sampleLift(
          id: 'squat',
          name: 'Squat',
          muscles: const ['quads'],
          equipment: 'Barbell',
        ),
      ],
      const ShuffleRequest(
        equipment: ['Treadmill'],
        focus: [],
        includeCardio: false,
        targetMinutes: 30,
        secondsPerLift: 60,
        secondsPerRest: 60,
      ),
      random: () => 0,
    );
    expect(workout.lifts.map((lift) => lift.id), ['run']);
  });

  test('catalog keeps bench press cues and the YouTube tutorial', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final catalog = await LiftBigCatalog.load();
    final bench = catalog.liftById('bench-press');
    expect(bench, isNotNull);
    expect(bench!.tutorialUrl, 'https://www.youtube.com/shorts/hWbUlkb5Ms4');
    expect(bench.instructions, isNotEmpty);
    expect(bench.cues, isNotEmpty);
    expect(catalog.liftById('machine-shoulder-press')!.tutorialUrl, 'https://www.youtube.com/watch?v=oAadscMCGLU');
    expect(catalog.liftById('back-extension')!.tutorialUrl, 'https://www.youtube.com/watch?v=WnsnESPx4JE');
    expect(catalog.liftById('assisted-dip')!.tutorialUrl, 'https://www.youtube.com/watch?v=8zFcJWD9Y_E');
    expect(catalog.liftById('machine-bicep-curl')!.tutorialUrl, 'https://www.youtube.com/watch?v=M_uPvGrMx_o');
    expect(catalog.liftById('machine-triceps-extension')!.tutorialUrl, 'https://www.youtube.com/watch?v=S_evjJzI4hA');
    expect(catalog.liftById('hip-abductor-machine')!.tutorialUrl, 'https://www.youtube.com/watch?v=2b97cvyH9sE');
    expect(catalog.liftById('sit-up')!.tutorialUrl, 'https://www.youtube.com/watch?v=jDwoBqPH0jk');
    expect(catalog.liftById('sit-up')!.tips, isNotEmpty);
    expect(catalog.lifts.length, 179);
    expect(catalog.plans.length, 51);
    expect(catalog.quiz.length, 53);
    expect(catalog.plans, isNotEmpty);
    expect(catalog.quiz, isNotEmpty);
    expect(
      catalog.lifts.where((lift) => lift.tutorialUrl.contains('youtube.com')),
      isNotEmpty,
    );
  });
}
