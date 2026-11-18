import '../catalog/liftbig_catalog.dart';
import '../date_key.dart';
import '../journal/lift_name_convergence.dart';
import '../model/journal_day.dart';

/// Warmup sets are stored and shown. They do not move progress or achievements.
bool setCountsTowardProgress(JournalSet set) => !set.isWarmup;

class LiftSessionPoint {
  const LiftSessionPoint({
    required this.dateKey,
    required this.maxWeightLbs,
    required this.volumeLbs,
    required this.setCount,
    required this.maxReps,
  });

  final String dateKey;

  /// Heaviest working-set load that day, in pounds.
  final double maxWeightLbs;
  final double volumeLbs;
  final int setCount;

  /// Reps on the set that lifted [maxWeightLbs]. Tied loads keep the higher reps.
  final int maxReps;
}

class LiftSeries {
  const LiftSeries({
    required this.name,
    required this.sessions,
    this.latestCompleted = false,
  });

  final String name;
  final List<LiftSessionPoint> sessions;

  /// Every working set on the newest logged day for this lift is checked off.
  final bool latestCompleted;
}

/// Working-set history for one lift name. Warmups and empty loads are skipped.
List<LiftSessionPoint> collectLiftHistory(
  List<JournalDay> days,
  String liftName,
) {
  final target = liftName.trim().toLowerCase();
  final points = <LiftSessionPoint>[];
  for (final day in days) {
    for (final exercise in day.exercises) {
      if (exercise.name.trim().toLowerCase() != target) continue;
      if (exercise.isCardio && !exercise.isCircuit) continue;
      final point = sessionPoint(day.dateKey, exercise);
      if (point != null) points.add(point);
    }
  }
  points.sort((a, b) => a.dateKey.compareTo(b.dateKey));
  return points;
}

/// Same movement as the exercise opened on the info sheet.
///
/// A library id matches only that id. Without one, names match after
/// [normalizeForExerciseMatch] so spelling differences stay one lift.
bool matchesLoggedLift(
  JournalExercise exercise, {
  required String name,
  String? libraryId,
}) {
  final id = libraryId?.trim();
  final otherId = exercise.libraryId?.trim() ?? '';
  if (id != null && id.isNotEmpty && otherId.isNotEmpty) {
    return otherId == id;
  }
  return exerciseFoldKey(exercise.name) == exerciseFoldKey(name);
}

/// [collectLiftHistory] for one logged exercise, matched by library id or name.
///
/// Working sets still come from [sessionPoint]. Cardio that is not a circuit
/// stays off the chart, same as [collectLiftHistory].
List<LiftSessionPoint> collectSameLiftHistory(
  List<JournalDay> days, {
  required String name,
  String? libraryId,
}) {
  final points = <LiftSessionPoint>[];
  for (final day in days) {
    for (final exercise in day.exercises) {
      if (exercise.isCardio && !exercise.isCircuit) continue;
      if (!matchesLoggedLift(exercise, name: name, libraryId: libraryId)) {
        continue;
      }
      final point = sessionPoint(day.dateKey, exercise);
      if (point != null) points.add(point);
    }
  }
  points.sort((a, b) => a.dateKey.compareTo(b.dateKey));
  return points;
}

/// One point per lift that has at least one working set with a load.
///
/// Exercises that share a library id, or a name that folds to one library
/// lift, are a single series.
List<LiftSeries> strengthSeries(
  List<JournalDay> days, {
  List<LibraryLift> lifts = const [],
}) {
  final index = LibraryNameIndex(lifts);
  final names = <String, List<String>>{};
  final exercises = <String, List<JournalExercise>>{};
  for (final day in days) {
    for (final exercise in day.exercises) {
      final name = exercise.name.trim();
      if (name.isEmpty) continue;
      if (exercise.isCardio && !exercise.isCircuit) continue;
      if (sessionPoint(day.dateKey, exercise) == null) continue;
      final key = _seriesKey(exercise, index);
      (names[key] ??= []).add(name);
      (exercises[key] ??= []).add(exercise);
    }
  }
  final keys = names.keys.toList()
    ..sort((a, b) => _seriesDisplay(a, names[a]!, index).compareTo(
      _seriesDisplay(b, names[b]!, index),
    ));
  return [
    for (final key in keys)
      LiftSeries(
        name: _seriesDisplay(key, names[key]!, index),
        sessions: _sessionsForKey(days, key, index),
        latestCompleted: _latestKeyCompleted(days, key, index),
      ),
  ];
}

String _seriesKey(JournalExercise exercise, LibraryNameIndex index) {
  final id = exercise.libraryId?.trim();
  if (id != null && id.isNotEmpty) return 'id:$id';
  final match = index.matchName(exercise.name);
  if (match != null) return 'id:${match.id}';
  return 'name:${normalizeForExerciseMatch(exercise.name)}';
}

String _seriesDisplay(String key, List<String> logged, LibraryNameIndex index) {
  if (key.startsWith('id:')) {
    final lift = index.byId[key.substring(3)];
    if (lift != null) return lift.name;
  }
  final unique = logged.toSet().toList()
    ..sort((a, b) => a.length.compareTo(b.length));
  return unique.first;
}

bool _exerciseInSeries(
  JournalExercise exercise,
  String key,
  LibraryNameIndex index,
) {
  return _seriesKey(exercise, index) == key;
}

List<LiftSessionPoint> _sessionsForKey(
  List<JournalDay> days,
  String key,
  LibraryNameIndex index,
) {
  final points = <LiftSessionPoint>[];
  for (final day in days) {
    for (final exercise in day.exercises) {
      if (exercise.isCardio && !exercise.isCircuit) continue;
      if (!_exerciseInSeries(exercise, key, index)) continue;
      final point = sessionPoint(day.dateKey, exercise);
      if (point != null) points.add(point);
    }
  }
  points.sort((a, b) => a.dateKey.compareTo(b.dateKey));
  return points;
}

bool _latestKeyCompleted(
  List<JournalDay> days,
  String key,
  LibraryNameIndex index,
) {
  JournalExercise? latest;
  var latestKey = '';
  for (final day in days) {
    for (final exercise in day.exercises) {
      if (!_exerciseInSeries(exercise, key, index)) continue;
      if (sessionPoint(day.dateKey, exercise) == null) continue;
      if (latest == null || day.dateKey.compareTo(latestKey) >= 0) {
        latest = exercise;
        latestKey = day.dateKey;
      }
    }
  }
  final working = latest?.sets.where((set) => !set.isWarmup).toList() ?? const <JournalSet>[];
  if (working.isEmpty) return false;
  return working.every((set) => set.checked);
}

LiftSessionPoint? sessionPoint(String dateKey, JournalExercise exercise) {
  var maxWeight = 0.0;
  var volume = 0.0;
  var maxReps = 0;
  var counted = 0;
  for (final set in exercise.sets) {
    if (!setCountsTowardProgress(set)) continue;
    if (set.reps.trim().isEmpty || set.weight.trim().isEmpty) continue;
    final weight = double.tryParse(set.weight.trim());
    if (weight == null || weight <= 0) continue;
    counted++;
    final reps = int.tryParse(set.reps.trim());
    final repCount = reps == null || reps < 0 ? 0 : reps;
    if (weight > maxWeight || (weight == maxWeight && repCount > maxReps)) {
      maxWeight = weight;
      maxReps = repCount;
    }
    volume += weight * repCount;
  }
  if (maxWeight <= 0 || counted == 0) return null;
  return LiftSessionPoint(
    dateKey: dateKey,
    maxWeightLbs: maxWeight,
    volumeLbs: volume,
    setCount: counted,
    maxReps: maxReps,
  );
}

class Achievement {
  const Achievement({
    required this.id,
    required this.title,
    required this.description,
  });

  final String id;
  final String title;
  final String description;
}

const achievements = <Achievement>[
  Achievement(
    id: 'first-workout',
    title: 'First rep logged',
    description: 'Complete your first training day.',
  ),
  Achievement(
    id: 'tonnage-10k',
    title: '10K club',
    description: 'Move 10,000+ lbs of total tonnage across all logged sets.',
  ),
  Achievement(
    id: 'streak-3',
    title: 'Fire starter',
    description: 'Train on 3 consecutive calendar days.',
  ),
  Achievement(
    id: 'streak-7',
    title: 'Week warrior',
    description: 'Train on 7 consecutive calendar days.',
  ),
  Achievement(
    id: 'streak-14',
    title: 'Fortnight fighter',
    description: 'Train on 14 consecutive calendar days.',
  ),
  Achievement(
    id: 'streak-30',
    title: 'Monthly machine',
    description: 'Train on 30 consecutive calendar days.',
  ),
  Achievement(
    id: 'cardio-debut',
    title: 'Cardio convert',
    description: 'Log your first cardio session.',
  ),
  Achievement(
    id: 'pull-up-debut',
    title: 'First chin',
    description: 'Log your first pull-up set.',
  ),
  Achievement(
    id: 'sessions-50',
    title: 'Half century',
    description: 'Log 50 training sessions.',
  ),
  Achievement(
    id: 'unique-25',
    title: 'Movement explorer',
    description: 'Log 25 different exercises.',
  ),
  Achievement(
    id: 'sets-1k',
    title: 'Set collector',
    description: 'Log 1,000 working sets.',
  ),
  Achievement(
    id: 'reps-10k',
    title: 'Rep rally',
    description: 'Log 10,000 total reps.',
  ),
  Achievement(
    id: 'tonnage-100k',
    title: '100K tonnage',
    description: 'Accumulate 100,000+ lbs of total volume.',
  ),
  Achievement(
    id: 'core-1000',
    title: 'Plank pro',
    description: 'Accumulate 1,000 seconds of logged core hold time.',
  ),
  Achievement(
    id: 'cardio-10-hours',
    title: 'Endurance engine',
    description: 'Log 600+ minutes of cardio.',
  ),
  Achievement(
    id: 'rest-days-10',
    title: 'Recovery respect',
    description: 'Log 10 intentional rest days.',
  ),
  Achievement(
    id: 'variety-week',
    title: 'Mix master',
    description: 'Hit 8+ different exercises in a single calendar week.',
  ),
  Achievement(
    id: 'superset-25',
    title: 'Superset savvy',
    description: 'Log 25 exercises performed as supersets.',
  ),
  Achievement(
    id: 'streak-12-weeks',
    title: '12-week streak',
    description: 'Train every day for 12 consecutive weeks (84 days).',
  ),
  Achievement(
    id: 'sessions-100',
    title: 'Century sessions',
    description: 'Log 100 training sessions.',
  ),
  Achievement(
    id: 'unique-50',
    title: 'Exercise encyclopedia',
    description: 'Log 50 different exercises.',
  ),
  Achievement(
    id: 'pull-up-10',
    title: 'Double digits',
    description: 'Log a set of 10+ pull-ups.',
  ),
  Achievement(
    id: 'month-20',
    title: 'Twenty in thirty',
    description: 'Train on 20+ days in a single calendar month.',
  ),
  Achievement(
    id: 'sessions-200',
    title: 'Double ton',
    description: 'Log 200 training sessions.',
  ),
  Achievement(
    id: 'sets-5k',
    title: 'Set factory',
    description: 'Log 5,000 working sets.',
  ),
  Achievement(
    id: 'reps-100k',
    title: 'Centurion reps',
    description: 'Log 100,000 total reps.',
  ),
  Achievement(
    id: 'tonnage-500k',
    title: 'Half-million mover',
    description: 'Move 500,000+ lbs of total tonnage.',
  ),
  Achievement(
    id: 'cardio-50',
    title: 'Steady state',
    description: 'Log 50 cardio sessions.',
  ),
  Achievement(
    id: 'unique-100',
    title: 'Library legend',
    description: 'Log 100 different exercises.',
  ),
  Achievement(
    id: 'core-10000',
    title: 'Core of steel',
    description: 'Accumulate 10,000 seconds of logged core hold time.',
  ),
  Achievement(
    id: 'ohp-plate',
    title: 'Strict press club',
    description: 'Log a working set of 135+ lbs on overhead press.',
  ),
  Achievement(
    id: 'bench-2-plates',
    title: 'Bench two plates',
    description: 'Log a working set of 225+ lbs on barbell bench press.',
  ),
  Achievement(
    id: 'squat-2-plates',
    title: 'Squat two plates',
    description: 'Log a working set of 225+ lbs on barbell back squat.',
  ),
  Achievement(
    id: 'deadlift-2-plates',
    title: 'Deadlift two plates',
    description: 'Log a working set of 225+ lbs on barbell deadlift.',
  ),
  Achievement(
    id: 'row-2-plates',
    title: 'Row two plates',
    description: 'Log a working set of 225+ lbs on barbell row.',
  ),
  Achievement(
    id: 'hip-thrust-2-plates',
    title: 'Glute goals',
    description: 'Log a working set of 225+ lbs on hip thrust.',
  ),
  Achievement(
    id: 'ohp-2-plates',
    title: 'Press two plates',
    description: 'Log a working set of 225+ lbs on overhead press.',
  ),
  Achievement(
    id: 'bench-3-plates',
    title: 'Bench three plates',
    description: 'Log a working set of 315+ lbs on barbell bench press.',
  ),
  Achievement(
    id: 'squat-3-plates',
    title: 'Squat three plates',
    description: 'Log a working set of 315+ lbs on barbell back squat.',
  ),
  Achievement(
    id: 'deadlift-3-plates',
    title: 'Deadlift three plates',
    description: 'Log a working set of 315+ lbs on barbell deadlift.',
  ),
  Achievement(
    id: 'hip-thrust-3-plates',
    title: 'Heavy thrust',
    description: 'Log a working set of 315+ lbs on hip thrust.',
  ),
  Achievement(
    id: 'sets-10k',
    title: 'Volume king',
    description: 'Log 10,000 working sets.',
  ),
  Achievement(
    id: 'sessions-500',
    title: 'Iron veteran',
    description: 'Log 500 training sessions.',
  ),
  Achievement(
    id: 'tonnage-1m',
    title: 'Million pound club',
    description: 'Move 1,000,000+ lbs of total tonnage.',
  ),
  Achievement(
    id: 'bench-4-plates',
    title: 'Bench four plates',
    description: 'Log a working set of 405+ lbs on barbell bench press.',
  ),
  Achievement(
    id: 'squat-4-plates',
    title: 'Squat four plates',
    description: 'Log a working set of 405+ lbs on barbell back squat.',
  ),
  Achievement(
    id: 'deadlift-4-plates',
    title: 'Deadlift four plates',
    description: 'Log a working set of 405+ lbs on barbell deadlift.',
  ),
];

/// Names the journal already uses for the plate lifts, plus the library name.
const plateLiftAliases = <String, Set<String>>{
  'bench-press': {'barbell bench press', 'bench press', 'flat bench', 'bench'},
  'squat': {'barbell back squat', 'back squat', 'squat', 'squats'},
  'deadlift': {'conventional deadlift', 'deadlift', 'barbell deadlift'},
  'overhead-press': {'overhead press', 'ohp', 'military press', 'strict press'},
  'barbell-row': {'barbell row', 'bent over row', 'bent-over row'},
  'hip-thrust': {'hip thrust', 'hip thrusts'},
};

bool matchesPlateLift(JournalExercise exercise, String libraryId) {
  if (exercise.libraryId == libraryId) return true;
  final name = exercise.name.trim().toLowerCase();
  return plateLiftAliases[libraryId]?.contains(name) ?? false;
}

Set<String> unlockedAchievements(List<JournalDay> days) {
  final unlocked = <String>{};
  final sessions = _trainedDateKeys(days);
  final sessionCount = sessions.length;
  final tonnage = _totalTonnage(days);
  final streak = _longestStreak(sessions);
  final sets = _totalSets(days);
  final reps = _totalReps(days);

  if (sessionCount >= 1) unlocked.add('first-workout');
  if (tonnage >= 10000) unlocked.add('tonnage-10k');
  if (tonnage >= 100000) unlocked.add('tonnage-100k');
  if (tonnage >= 500000) unlocked.add('tonnage-500k');
  if (tonnage >= 1000000) unlocked.add('tonnage-1m');
  if (sessionCount >= 50) unlocked.add('sessions-50');
  if (sessionCount >= 100) unlocked.add('sessions-100');
  if (sessionCount >= 200) unlocked.add('sessions-200');
  if (sessionCount >= 500) unlocked.add('sessions-500');
  if (streak >= 3) unlocked.add('streak-3');
  if (streak >= 7) unlocked.add('streak-7');
  if (streak >= 14) unlocked.add('streak-14');
  if (streak >= 30) unlocked.add('streak-30');
  if (streak >= 84) unlocked.add('streak-12-weeks');
  if (sets >= 1000) unlocked.add('sets-1k');
  if (sets >= 5000) unlocked.add('sets-5k');
  if (sets >= 10000) unlocked.add('sets-10k');
  if (reps >= 10000) unlocked.add('reps-10k');
  if (reps >= 100000) unlocked.add('reps-100k');

  final cardioSessions = _cardioSessions(days);
  if (cardioSessions > 0) unlocked.add('cardio-debut');
  if (_cardioMinutes(days) >= 600) unlocked.add('cardio-10-hours');
  if (cardioSessions >= 50) unlocked.add('cardio-50');

  final unique = _uniqueLiftNames(days);
  if (unique >= 25) unlocked.add('unique-25');
  if (unique >= 50) unlocked.add('unique-50');
  if (unique >= 100) unlocked.add('unique-100');
  if (_hasVarietyWeek(days)) unlocked.add('variety-week');

  if (_restDays(days) >= 10) unlocked.add('rest-days-10');
  if (_maxDaysInMonth(sessions) >= 20) unlocked.add('month-20');
  if (_supersetLifts(days) >= 25) unlocked.add('superset-25');

  final coreSeconds = _coreSeconds(days);
  if (coreSeconds >= 1000) unlocked.add('core-1000');
  if (coreSeconds >= 10000) unlocked.add('core-10000');

  if (_hasPullUps(days)) unlocked.add('pull-up-debut');
  if (_maxPullUpReps(days) >= 10) unlocked.add('pull-up-10');

  final bench = _maxPlateLbs(days, 'bench-press');
  if (bench >= 225) unlocked.add('bench-2-plates');
  if (bench >= 315) unlocked.add('bench-3-plates');
  if (bench >= 405) unlocked.add('bench-4-plates');

  final squat = _maxPlateLbs(days, 'squat');
  if (squat >= 225) unlocked.add('squat-2-plates');
  if (squat >= 315) unlocked.add('squat-3-plates');
  if (squat >= 405) unlocked.add('squat-4-plates');

  final deadlift = _maxPlateLbs(days, 'deadlift');
  if (deadlift >= 225) unlocked.add('deadlift-2-plates');
  if (deadlift >= 315) unlocked.add('deadlift-3-plates');
  if (deadlift >= 405) unlocked.add('deadlift-4-plates');

  final press = _maxPlateLbs(days, 'overhead-press');
  if (press >= 135) unlocked.add('ohp-plate');
  if (press >= 225) unlocked.add('ohp-2-plates');

  if (_maxPlateLbs(days, 'barbell-row') >= 225) unlocked.add('row-2-plates');

  final hip = _maxPlateLbs(days, 'hip-thrust');
  if (hip >= 225) unlocked.add('hip-thrust-2-plates');
  if (hip >= 315) unlocked.add('hip-thrust-3-plates');

  return unlocked;
}

bool _isPullUp(JournalExercise exercise) {
  if (exercise.libraryId == 'pull-up') return true;
  final name = exercise.name.trim().toLowerCase();
  return name.contains('pull-up') || name.contains('pull up');
}

bool _setHasReps(JournalSet set) {
  final text = set.reps.trim();
  if (text.isEmpty) return false;
  final reps = int.tryParse(text);
  if (reps != null && reps >= 1) return true;
  return text.toLowerCase().contains('amrap');
}

double _maxPlateLbs(List<JournalDay> days, String libraryId) {
  var best = 0.0;
  for (final day in days) {
    for (final exercise in day.exercises) {
      if (!matchesPlateLift(exercise, libraryId)) continue;
      for (final set in exercise.sets) {
        if (!setCountsTowardProgress(set)) continue;
        if (!_setHasReps(set)) continue;
        final weight = double.tryParse(set.weight.trim());
        if (weight == null || weight <= 0) continue;
        if (weight > best) best = weight;
      }
    }
  }
  return best;
}

List<String> _trainedDateKeys(List<JournalDay> days) {
  final keys = <String>[];
  for (final day in days) {
    if (_dayHasWork(day)) keys.add(day.dateKey);
  }
  keys.sort();
  return keys;
}

bool dayHasLoggedWork(JournalDay day) => _dayHasWork(day);

bool _dayHasWork(JournalDay day) {
  for (final exercise in day.exercises) {
    if (exercise.isCardio && !exercise.isCircuit) {
      final minutes = int.tryParse(_cardioMinutesText(exercise));
      if (minutes != null && minutes > 0) return true;
      continue;
    }
    for (final set in exercise.sets) {
      if (!setCountsTowardProgress(set)) continue;
      if (set.reps.trim().isNotEmpty && set.weight.trim().isNotEmpty) {
        return true;
      }
    }
  }
  return false;
}

String _cardioMinutesText(JournalExercise exercise) {
  if (exercise.sets.isEmpty) return '';
  return exercise.sets.first.reps.trim();
}

double _totalTonnage(List<JournalDay> days) {
  var total = 0.0;
  for (final day in days) {
    for (final exercise in day.exercises) {
      if (exercise.isCardio && !exercise.isCircuit) continue;
      for (final set in exercise.sets) {
        if (!setCountsTowardProgress(set)) continue;
        final weight = double.tryParse(set.weight.trim());
        final reps = int.tryParse(set.reps.trim());
        if (weight == null || weight <= 0 || reps == null || reps <= 0) {
          continue;
        }
        total += weight * reps;
      }
    }
  }
  return total;
}

int _totalSets(List<JournalDay> days) {
  var total = 0;
  for (final day in days) {
    for (final exercise in day.exercises) {
      if (exercise.isCardio && !exercise.isCircuit) continue;
      for (final set in exercise.sets) {
        if (!setCountsTowardProgress(set)) continue;
        if (exercise.isCircuit) {
          if (set.checked) total++;
          continue;
        }
        if (exercise.isCore) {
          final reps = int.tryParse(set.reps.trim());
          final seconds = int.tryParse((set.durationSeconds ?? '').trim());
          if ((reps != null && reps > 0) || (seconds != null && seconds > 0)) {
            total++;
          }
          continue;
        }
        if (set.reps.trim().isNotEmpty && set.weight.trim().isNotEmpty) total++;
      }
    }
  }
  return total;
}

int _totalReps(List<JournalDay> days) {
  var total = 0;
  for (final day in days) {
    for (final exercise in day.exercises) {
      if ((exercise.isCardio && !exercise.isCircuit) || exercise.isCircuit) {
        continue;
      }
      for (final set in exercise.sets) {
        if (!setCountsTowardProgress(set)) continue;
        final reps = int.tryParse(set.reps.trim());
        if (reps != null && reps > 0) total += reps;
      }
    }
  }
  return total;
}

int _longestStreak(List<String> dates) {
  if (dates.isEmpty) return 0;
  var best = 1;
  var run = 1;
  for (var i = 1; i < dates.length; i++) {
    final gap = parseDateKey(dates[i])
        .difference(parseDateKey(dates[i - 1]))
        .inDays;
    if (gap == 1) {
      run++;
      if (run > best) best = run;
    } else if (gap > 1) {
      run = 1;
    }
  }
  return best;
}

int _cardioSessions(List<JournalDay> days) {
  var count = 0;
  for (final day in days) {
    for (final exercise in day.exercises) {
      if (!exercise.isCardio || exercise.isCircuit) continue;
      final minutes = int.tryParse(_cardioMinutesText(exercise));
      if (minutes != null && minutes > 0) count++;
    }
  }
  return count;
}

int _cardioMinutes(List<JournalDay> days) {
  var total = 0;
  for (final day in days) {
    for (final exercise in day.exercises) {
      if (!exercise.isCardio || exercise.isCircuit) continue;
      final minutes = int.tryParse(_cardioMinutesText(exercise));
      if (minutes != null && minutes > 0) total += minutes;
    }
  }
  return total;
}

int _uniqueLiftNames(List<JournalDay> days) {
  final names = <String>{};
  for (final day in days) {
    for (final exercise in day.exercises) {
      final name = exercise.name.trim().toLowerCase();
      if (name.isNotEmpty) names.add(name);
    }
  }
  return names.length;
}

int _restDays(List<JournalDay> days) {
  var count = 0;
  for (final day in days) {
    if (day.isRestDay) count++;
  }
  return count;
}

int _coreSeconds(List<JournalDay> days) {
  var total = 0;
  for (final day in days) {
    for (final exercise in day.exercises) {
      if (!exercise.isCore) continue;
      for (final set in exercise.sets) {
        if (!setCountsTowardProgress(set)) continue;
        final seconds = int.tryParse((set.durationSeconds ?? '').trim());
        if (seconds != null && seconds > 0) total += seconds;
      }
    }
  }
  return total;
}

int _supersetLifts(List<JournalDay> days) {
  var count = 0;
  for (final day in days) {
    for (final exercise in day.exercises) {
      if (exercise.supersetGroupId?.trim().isNotEmpty ?? false) count++;
    }
  }
  return count;
}

int _maxDaysInMonth(List<String> dates) {
  final byMonth = <String, int>{};
  for (final date in dates) {
    final month = date.substring(0, 7);
    byMonth[month] = (byMonth[month] ?? 0) + 1;
  }
  var best = 0;
  for (final count in byMonth.values) {
    if (count > best) best = count;
  }
  return best;
}

bool _hasPullUps(List<JournalDay> days) {
  for (final day in days) {
    for (final exercise in day.exercises) {
      if (!_isPullUp(exercise)) continue;
      for (final set in exercise.sets) {
        if (!setCountsTowardProgress(set)) continue;
        final reps = int.tryParse(set.reps.trim());
        if (reps != null && reps > 0) return true;
      }
    }
  }
  return false;
}

int _maxPullUpReps(List<JournalDay> days) {
  var best = 0;
  for (final day in days) {
    for (final exercise in day.exercises) {
      if (!_isPullUp(exercise)) continue;
      for (final set in exercise.sets) {
        if (!setCountsTowardProgress(set)) continue;
        final reps = int.tryParse(set.reps.trim());
        if (reps != null && reps > best) best = reps;
      }
    }
  }
  return best;
}

bool _hasVarietyWeek(List<JournalDay> days) {
  final trained = _trainedDateKeys(days);
  if (trained.isEmpty) return false;
  final starts = <String>{};
  for (final date in trained) {
    starts.add(_weekStart(date));
  }
  for (final start in starts) {
    final end = toDateKey(parseDateKey(start).add(const Duration(days: 6)));
    final names = <String>{};
    for (final day in days) {
      if (day.dateKey.compareTo(start) < 0 || day.dateKey.compareTo(end) > 0) {
        continue;
      }
      for (final exercise in day.exercises) {
        final name = exercise.name.trim().toLowerCase();
        if (name.isNotEmpty) names.add(name);
      }
    }
    if (names.length >= 8) return true;
  }
  return false;
}

/// The run of trained days ending today or yesterday. A missed day ends it.
int currentTrainingStreak(List<String> dates, {DateTime? today}) {
  if (dates.isEmpty) return 0;
  final unique = dates.toSet().toList()..sort();
  final now = today ?? DateTime.now();
  final todayKeyValue = toDateKey(DateTime(now.year, now.month, now.day));
  final yesterday = toDateKey(
    DateTime(now.year, now.month, now.day).subtract(const Duration(days: 1)),
  );
  final last = unique.last;
  if (last != todayKeyValue && last != yesterday) return 0;
  var run = 1;
  for (var i = unique.length - 1; i > 0; i--) {
    final gap = parseDateKey(unique[i])
        .difference(parseDateKey(unique[i - 1]))
        .inDays;
    if (gap == 1) {
      run++;
    } else if (gap > 1) {
      break;
    }
  }
  return run;
}

class HeaviestSet {
  const HeaviestSet({required this.name, required this.weightLb});

  final String name;
  final double weightLb;
}

class GoalProgress {
  const GoalProgress({
    required this.achievement,
    required this.current,
    required this.target,
  });

  final Achievement achievement;
  final double current;
  final double target;

  double get ratio {
    if (target <= 0) return 0;
    return (current / target).clamp(0.0, 1.0).toDouble();
  }
}

class TrainingSnapshot {
  const TrainingSnapshot({
    required this.currentStreak,
    required this.longestStreak,
    required this.nextStreakGoal,
    required this.weekTrained,
    required this.weekSessions,
    required this.weekSets,
    required this.weekVolumeLb,
    required this.previousWeekVolumeLb,
    required this.trainedDays,
    required this.totalVolumeLb,
    required this.heaviest,
    required this.benchLb,
    required this.squatLb,
    required this.deadliftLb,
    required this.nextGoal,
  });

  final int currentStreak;
  final int longestStreak;
  final int? nextStreakGoal;
  final List<bool> weekTrained;
  final int weekSessions;
  final int weekSets;
  final double weekVolumeLb;
  final double? previousWeekVolumeLb;
  final int trainedDays;
  final double totalVolumeLb;
  final HeaviestSet? heaviest;
  final double benchLb;
  final double squatLb;
  final double deadliftLb;
  final GoalProgress? nextGoal;
}

const _streakMarks = [3, 7, 14, 30, 84];

TrainingSnapshot trainingSnapshot(List<JournalDay> days, {DateTime? today}) {
  final now = today ?? DateTime.now();
  final trained = _trainedDateKeys(days);
  final current = currentTrainingStreak(trained, today: now);
  final longest = trained.isEmpty ? 0 : _longestStreak(trained);
  int? nextMark;
  for (final mark in _streakMarks) {
    if (current < mark) {
      nextMark = mark;
      break;
    }
  }
  final monday = DateTime(now.year, now.month, now.day)
      .subtract(Duration(days: now.weekday - DateTime.monday));
  final weekTrained = <bool>[];
  var weekSessions = 0;
  for (var i = 0; i < 7; i++) {
    final key = toDateKey(monday.add(Duration(days: i)));
    final trainedDay = trained.contains(key);
    weekTrained.add(trainedDay);
    if (trainedDay) weekSessions++;
  }
  final weekStart = toDateKey(monday);
  final weekEnd = toDateKey(monday.add(const Duration(days: 6)));
  final previousStart = toDateKey(monday.subtract(const Duration(days: 7)));
  final previousEnd = toDateKey(monday.subtract(const Duration(days: 1)));
  final previousHadWork = trained.any(
    (key) => key.compareTo(previousStart) >= 0 && key.compareTo(previousEnd) <= 0,
  );
  final earned = unlockedAchievements(days);
  return TrainingSnapshot(
    currentStreak: current,
    longestStreak: longest,
    nextStreakGoal: nextMark,
    weekTrained: weekTrained,
    weekSessions: weekSessions,
    weekSets: _setsBetween(days, weekStart, weekEnd),
    weekVolumeLb: _tonnageBetween(days, weekStart, weekEnd),
    previousWeekVolumeLb: previousHadWork
        ? _tonnageBetween(days, previousStart, previousEnd)
        : null,
    trainedDays: trained.length,
    totalVolumeLb: _totalTonnage(days),
    heaviest: _heaviestSet(days),
    benchLb: _maxPlateLbs(days, 'bench-press'),
    squatLb: _maxPlateLbs(days, 'squat'),
    deadliftLb: _maxPlateLbs(days, 'deadlift'),
    nextGoal: _nextGoal(days, earned, current),
  );
}

int _setsBetween(List<JournalDay> days, String start, String end) {
  return _totalSets([
    for (final day in days)
      if (day.dateKey.compareTo(start) >= 0 && day.dateKey.compareTo(end) <= 0) day,
  ]);
}

double _tonnageBetween(List<JournalDay> days, String start, String end) {
  return _totalTonnage([
    for (final day in days)
      if (day.dateKey.compareTo(start) >= 0 && day.dateKey.compareTo(end) <= 0) day,
  ]);
}

HeaviestSet? _heaviestSet(List<JournalDay> days) {
  String? name;
  var best = 0.0;
  for (final day in days) {
    for (final exercise in day.exercises) {
      if (exercise.isCardio && !exercise.isCircuit) continue;
      for (final set in exercise.sets) {
        if (!setCountsTowardProgress(set)) continue;
        final weight = double.tryParse(set.weight.trim());
        if (weight == null || weight <= best) continue;
        if (set.reps.trim().isEmpty) continue;
        best = weight;
        name = exercise.name.trim();
      }
    }
  }
  if (name == null || name.isEmpty || best <= 0) return null;
  return HeaviestSet(name: name, weightLb: best);
}

GoalProgress? _nextGoal(List<JournalDay> days, Set<String> earned, int currentStreak) {
  final byId = {for (final item in achievements) item.id: item};
  final candidates = <GoalProgress>[];
  void add(String id, double current, double target) {
    if (earned.contains(id) || target <= 0) return;
    final item = byId[id];
    if (item == null) return;
    candidates.add(GoalProgress(achievement: item, current: current, target: target));
  }

  final sessions = _trainedDateKeys(days).length.toDouble();
  final tonnage = _totalTonnage(days);
  final sets = _totalSets(days).toDouble();
  final reps = _totalReps(days).toDouble();
  add('first-workout', sessions, 1);
  add('streak-3', currentStreak.toDouble(), 3);
  add('streak-7', currentStreak.toDouble(), 7);
  add('streak-14', currentStreak.toDouble(), 14);
  add('streak-30', currentStreak.toDouble(), 30);
  add('streak-12-weeks', currentStreak.toDouble(), 84);
  add('tonnage-10k', tonnage, 10000);
  add('tonnage-100k', tonnage, 100000);
  add('tonnage-500k', tonnage, 500000);
  add('tonnage-1m', tonnage, 1000000);
  add('sessions-50', sessions, 50);
  add('sessions-100', sessions, 100);
  add('sessions-200', sessions, 200);
  add('sessions-500', sessions, 500);
  add('sets-1k', sets, 1000);
  add('sets-5k', sets, 5000);
  add('sets-10k', sets, 10000);
  add('reps-10k', reps, 10000);
  add('reps-100k', reps, 100000);
  add('bench-2-plates', _maxPlateLbs(days, 'bench-press'), 225);
  add('bench-3-plates', _maxPlateLbs(days, 'bench-press'), 315);
  add('bench-4-plates', _maxPlateLbs(days, 'bench-press'), 405);
  add('squat-2-plates', _maxPlateLbs(days, 'squat'), 225);
  add('squat-3-plates', _maxPlateLbs(days, 'squat'), 315);
  add('squat-4-plates', _maxPlateLbs(days, 'squat'), 405);
  add('deadlift-2-plates', _maxPlateLbs(days, 'deadlift'), 225);
  add('deadlift-3-plates', _maxPlateLbs(days, 'deadlift'), 315);
  add('deadlift-4-plates', _maxPlateLbs(days, 'deadlift'), 405);
  add('ohp-plate', _maxPlateLbs(days, 'overhead-press'), 135);
  add('ohp-2-plates', _maxPlateLbs(days, 'overhead-press'), 225);
  add('row-2-plates', _maxPlateLbs(days, 'barbell-row'), 225);
  add('hip-thrust-2-plates', _maxPlateLbs(days, 'hip-thrust'), 225);
  add('hip-thrust-3-plates', _maxPlateLbs(days, 'hip-thrust'), 315);
  if (candidates.isEmpty) return null;
  candidates.sort((a, b) {
    final ratio = b.ratio.compareTo(a.ratio);
    if (ratio != 0) return ratio;
    return (a.target - a.current).compareTo(b.target - b.current);
  });
  return candidates.first;
}

/// Sunday that starts the calendar week containing [dateKey].
String _weekStart(String dateKey) {
  final date = parseDateKey(dateKey);
  final sunday = date.subtract(Duration(days: date.weekday % 7));
  return toDateKey(sunday);
}
