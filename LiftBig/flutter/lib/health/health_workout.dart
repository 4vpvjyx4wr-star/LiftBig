import '../model/journal_day.dart';

/// Activity names shared with the Vue health writer. Calories are filled later
/// from Apple or Health Connect active energy, never from a MET estimate.
enum HealthActivity {
  strength,
  walking,
  running,
  cycling,
  swimming,
  rowing,
  hiking,
  elliptical,
  stairs,
  mixedCardio,
}

class HealthWorkoutWrite {
  HealthWorkoutWrite({
    required this.id,
    required this.activity,
    required this.startMs,
    required this.endMs,
    this.energyKcal,
    this.distanceMeters,
  });

  final String id;
  final HealthActivity activity;
  final int startMs;
  final int endMs;

  /// Null until active-energy samples are summed. Never a LiftBig estimate.
  double? energyKcal;
  final double? distanceMeters;
}

const _activityByLibrary = <String, HealthActivity>{
  'walking': HealthActivity.walking,
  'treadmill-walking': HealthActivity.walking,
  'running': HealthActivity.running,
  'treadmill-running': HealthActivity.running,
  'indoor-cycling': HealthActivity.cycling,
  'outdoor-cycling': HealthActivity.cycling,
  'swimming': HealthActivity.swimming,
  'rowing-machine': HealthActivity.rowing,
  'hiking': HealthActivity.hiking,
  'elliptical': HealthActivity.elliptical,
  'stairmaster': HealthActivity.stairs,
};

HealthActivity healthActivityForLibrary(String? libraryId) {
  if (libraryId == null || libraryId.isEmpty) return HealthActivity.mixedCardio;
  return _activityByLibrary[libraryId] ?? HealthActivity.mixedCardio;
}

/// One strength workout plus one workout per cardio exercise that has a duration.
/// [energyKcal] stays null. Duration uses logged minutes, or lift/rest assumptions
/// when a strength day has no clock time.
List<HealthWorkoutWrite> healthWritesForDay({
  required JournalDay day,
  required int averageLiftSeconds,
  required int averageRestSeconds,
  DateTime? now,
}) {
  if (day.exercises.isEmpty) return const [];
  final clock = now ?? DateTime.now();
  final end = _endMsFor(day.dateKey, clock);
  final writes = <HealthWorkoutWrite>[];

  final strength = day.exercises.where((exercise) => !exercise.isCardio);
  final strengthMinutes = _strengthMinutes(
    strength,
    averageLiftSeconds: averageLiftSeconds,
    averageRestSeconds: averageRestSeconds,
  );
  if (strengthMinutes > 0) {
    final durationMs = (strengthMinutes * 60 * 1000).round();
    writes.add(
      HealthWorkoutWrite(
        id: 'liftbig-${day.dateKey}-strength',
        activity: HealthActivity.strength,
        startMs: end - durationMs,
        endMs: end,
      ),
    );
  }

  final cardio = day.exercises.where((exercise) => exercise.isCardio).toList();
  for (var index = 0; index < cardio.length; index++) {
    final exercise = cardio[index];
    final minutes = _cardioMinutes(exercise);
    if (minutes <= 0) continue;
    writes.add(
      HealthWorkoutWrite(
        id: 'liftbig-${day.dateKey}-cardio-$index',
        activity: healthActivityForLibrary(exercise.libraryId),
        startMs: end - minutes * 60 * 1000,
        endMs: end,
        distanceMeters: _metersOf(exercise),
      ),
    );
  }
  return writes;
}

double _strengthMinutes(
  Iterable<JournalExercise> exercises, {
  required int averageLiftSeconds,
  required int averageRestSeconds,
}) {
  final perSet = averageLiftSeconds <= 0 ? 0.0 : averageLiftSeconds / 60;
  final rest = averageRestSeconds <= 0 ? 0.0 : averageRestSeconds / 60;
  var total = 0.0;
  for (final exercise in exercises) {
    final logged = _loggedStrengthMinutes(exercise);
    if (logged != null && logged > 0) {
      total += logged;
      continue;
    }
    final setCount = exercise.sets.length;
    if (setCount <= 0 || perSet <= 0) continue;
    total += setCount * perSet + (setCount - 1) * rest;
  }
  return total;
}

/// Sum of per-set clocks when the lifter logged time. Null when none is logged.
double? _loggedStrengthMinutes(JournalExercise exercise) {
  var seconds = 0;
  var any = false;
  for (final set in exercise.sets) {
    final parsed = int.tryParse((set.durationSeconds ?? '').trim());
    if (parsed == null || parsed <= 0) continue;
    seconds += parsed;
    any = true;
  }
  if (!any) return null;
  return seconds / 60;
}

int _cardioMinutes(JournalExercise exercise) {
  final loggedRaw = exercise.sets.isEmpty ? '' : exercise.sets.first.reps.trim();
  final logged = int.tryParse(loggedRaw);
  if (logged != null && logged > 0) return logged;
  final target = int.tryParse((exercise.targetDuration ?? '').trim());
  if (target != null && target > 0) return target;
  return 0;
}

double? _metersOf(JournalExercise exercise) {
  final raw = exercise.sets.isEmpty ? '' : exercise.sets.first.weight.trim();
  final miles = double.tryParse(raw.replaceAll(',', '.'));
  if (miles == null || miles <= 0) return null;
  // Journal distances are stored in miles.
  return miles * 1609.344;
}

int _endMsFor(String dateKey, DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  final parts = dateKey.split('-');
  if (parts.length != 3) return now.millisecondsSinceEpoch;
  final year = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  final day = int.tryParse(parts[2]);
  if (year == null || month == null || day == null) return now.millisecondsSinceEpoch;
  final date = DateTime(year, month, day);
  if (date == today) return now.millisecondsSinceEpoch;
  return DateTime(year, month, day, 18).millisecondsSinceEpoch;
}

/// True when an existing Health workout is the same session we would write.
bool healthWorkoutDuplicates({
  required HealthActivity existingActivity,
  required int existingStartMs,
  required int existingEndMs,
  String? existingSyncId,
  required HealthWorkoutWrite next,
}) {
  if (existingSyncId != null && existingSyncId == next.id) return true;
  if (existingActivity != next.activity) return false;
  final existingMinutes = (existingEndMs - existingStartMs).abs() / 60000;
  final nextMinutes = (next.endMs - next.startMs).abs() / 60000;
  final existingDay = DateTime.fromMillisecondsSinceEpoch(existingStartMs);
  final nextDay = DateTime.fromMillisecondsSinceEpoch(next.startMs);
  final sameDay = existingDay.year == nextDay.year &&
      existingDay.month == nextDay.month &&
      existingDay.day == nextDay.day;
  return sameDay && (existingMinutes - nextMinutes).abs() <= 1;
}

/// Sum of active-energy samples. Null when Apple recorded none.
double? sumActiveEnergyKcal(Iterable<double> samples) {
  final values = samples.toList();
  if (values.isEmpty) return null;
  var total = 0.0;
  for (final sample in values) {
    if (!sample.isFinite || sample < 0) continue;
    total += sample;
  }
  return total;
}
