import '../catalog/liftbig_catalog.dart';
import '../journal/lift_name_convergence.dart';
import 'custom_plans.dart';

class ParsedPlan {
  const ParsedPlan({required this.name, required this.workouts});

  final String name;
  final List<BuiltPlanWorkout> workouts;
}

/// Reads a pasted note into workouts. Returns null when no exercise is found.
ParsedPlan? parsePastedPlan(String raw, List<LibraryLift> lifts) {
  final index = LibraryNameIndex(lifts);
  final workouts = <_Draft>[];
  _Draft? current;

  for (final rawLine in raw.split(RegExp(r'\r?\n'))) {
    final line = rawLine.trim();
    if (line.isEmpty) continue;
    if (_isSkipped(line)) continue;
    if (_isDayTitle(line)) {
      current = _Draft(_titleText(line));
      workouts.add(current);
      continue;
    }
    current ??= _Draft('Workout');
    if (workouts.isEmpty) workouts.add(current);
    final exercise = _parseExercise(line, index);
    if (exercise == null) continue;
    current.exercises.add(exercise);
  }

  final sessions = [
    for (final workout in workouts)
      if (workout.exercises.isNotEmpty)
        BuiltPlanWorkout(name: workout.name, exercises: workout.exercises),
  ];
  if (sessions.isEmpty) return null;
  final name = sessions.length == 1 ? sessions.first.name : 'My Plan';
  return ParsedPlan(name: name, workouts: sessions);
}

class _Draft {
  _Draft(this.name);
  final String name;
  final exercises = <BuiltPlanExercise>[];
}

bool _isSkipped(String line) {
  final lower = line.toLowerCase();
  return lower.startsWith('warmup') ||
      lower.startsWith('warm-up') ||
      lower.startsWith('warm up') ||
      lower.startsWith('rest ') ||
      lower == 'rest' ||
      lower.startsWith('note:') ||
      lower.startsWith('notes:') ||
      lower.startsWith('notes ');
}

bool _isDayTitle(String line) {
  final lower = line.toLowerCase().replaceFirst(RegExp(r':$'), '').trim();
  const named = {
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
    'saturday',
    'sunday',
    'push',
    'pull',
    'legs',
    'upper',
    'lower',
    'full body',
  };
  if (named.contains(lower)) return true;
  if (RegExp(r'^day\s*\d+$').hasMatch(lower)) return true;
  if (RegExp(r'^workout\s*[a-z0-9]+$').hasMatch(lower)) return true;
  if (line.endsWith(':') &&
      line.length <= 40 &&
      !_looksPrescribed(line.substring(0, line.length - 1).trim())) {
    return true;
  }
  return false;
}

String _titleText(String line) {
  final trimmed = line.trim();
  if (trimmed.endsWith(':')) {
    return trimmed.substring(0, trimmed.length - 1).trim();
  }
  return trimmed;
}

bool _looksPrescribed(String line) {
  return RegExp(r'\d+\s*[x×]\s*\d+', caseSensitive: false).hasMatch(line) ||
      RegExp(r'\d+\s+sets?\s+of\s+\d+', caseSensitive: false).hasMatch(line);
}

BuiltPlanExercise? _parseExercise(String line, LibraryNameIndex index) {
  var rest = line.trim();
  var weight = '';
  final at = RegExp(
    r'\s*@\s*(\d+(?:\.\d+)?)\s*(?:lb|lbs|kg)?\s*$',
    caseSensitive: false,
  ).firstMatch(rest);
  if (at != null) {
    weight = at.group(1)!;
    rest = rest.substring(0, at.start).trim();
  } else {
    final withUnit = RegExp(
      r'\s+(\d+(?:\.\d+)?)\s*(lb|lbs|kg)\s*$',
      caseSensitive: false,
    ).firstMatch(rest);
    if (withUnit != null) {
      weight = withUnit.group(1)!;
      rest = rest.substring(0, withUnit.start).trim();
    }
  }

  final prescribed = RegExp(
    r'^(.*?)\s+(\d+)\s*[x×]\s*(\d+(?:\s*[-–]\s*\d+)?)(?:\s+(\d+(?:\.\d+)?))?\s*$',
    caseSensitive: false,
  ).firstMatch(rest);
  final setsOf = prescribed == null
      ? RegExp(
          r'^(.*?)\s+(\d+)\s+sets?\s+of\s+(\d+(?:\s*[-–]\s*\d+)?)\s*$',
          caseSensitive: false,
        ).firstMatch(rest)
      : null;
  final match = prescribed ?? setsOf;
  if (match == null) {
    if (_isDayTitle(rest) || rest.length < 2) return null;
    return _exercise(rest, defaultBuiltSetCount, defaultBuiltReps, weight, index);
  }
  final name = match.group(1)!.replaceFirst(RegExp(r'\s*[-–]\s*$'), '').trim();
  if (name.isEmpty) return null;
  final sets = int.tryParse(match.group(2)!) ?? defaultBuiltSetCount;
  final reps = match.group(3)!.replaceAll(' ', '');
  final bare = match.groupCount >= 4 ? match.group(4) : null;
  if (weight.isEmpty && bare != null) weight = bare;
  return _exercise(name, sets, reps, weight, index);
}

BuiltPlanExercise _exercise(
  String name,
  int sets,
  String reps,
  String weight,
  LibraryNameIndex index,
) {
  final match = index.matchName(name);
  return BuiltPlanExercise(
    lift: match,
    customName: match == null ? name : null,
    setCount: sets,
    targetReps: reps,
    targetWeight: weight,
  );
}
