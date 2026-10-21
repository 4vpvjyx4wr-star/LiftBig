import 'dart:math';

import '../catalog/liftbig_catalog.dart';

const shuffleFocusPatterns = ['push', 'pull', 'legs'];

/// Gear that lives under the cardio submenu. Bodyweight is also listed with
/// strength equipment so it covers both bodyweight lifts and running.
const cardioGear = [
  'Bike',
  'Elliptical',
  'Bodyweight',
  'Jump rope',
  'Rower',
  'Stair climber',
  'Stationary bike',
  'Treadmill',
];

/// Gear that lives under the sports submenu.
const sportsGear = [
  'Climbing gym',
  'Clubs',
  'Gi / gear',
  'Gloves / bag',
  'Kayak',
  'Paddle',
  'Pool',
  'Racquet',
  'SUP',
  'Skates',
  'Skis',
  'Snowboard',
];

/// Strength equipment, plus Bodyweight. Cardio machines and sports gear are omitted.
List<String> strengthGearChoices(List<String> catalogTypes) {
  final hidden = {...cardioGear, ...sportsGear}..remove('Bodyweight');
  return [
    for (final type in catalogTypes)
      if (!hidden.contains(type)) type,
  ];
}

/// Names from [ordered] that exist in the catalog, keeping [ordered].
List<String> gearPresentInCatalog(List<String> ordered, List<String> catalogTypes) {
  final have = catalogTypes.toSet();
  return [for (final name in ordered) if (have.contains(name)) name];
}

const _legMuscles = {'quads', 'hamstrings', 'glutes', 'calves'};

const _finisherTags = {
  'mobility',
  'warm-up',
  'recovery',
  'stretch',
  'cooldown',
  'foam roll',
};

class ShuffleRequest {
  const ShuffleRequest({
    required this.equipment,
    required this.focus,
    required this.includeCardio,
    required this.targetMinutes,
    required this.secondsPerLift,
    required this.secondsPerRest,
  });

  final List<String> equipment;
  final List<String> focus;
  final bool includeCardio;
  final int targetMinutes;
  final int secondsPerLift;
  final int secondsPerRest;
}

class ShuffledWorkout {
  const ShuffledWorkout({required this.lifts, required this.minutes});

  final List<LibraryLift> lifts;
  final int minutes;
}

int clampPaceSeconds(int value) {
  if (value < 5) return 5;
  if (value > 600) return 600;
  return value;
}

/// Builds one session from the catalog using equipment, focus, and time.
ShuffledWorkout buildShuffledWorkout(
  List<LibraryLift> library,
  ShuffleRequest request, {
  double Function()? random,
}) {
  final roll = random ?? _defaultRandom;
  final pool = [
    for (final lift in library)
      if (_matches(lift, request)) lift,
  ];
  if (pool.isEmpty) {
    return const ShuffledWorkout(lifts: [], minutes: 0);
  }
  final shuffled = [...pool];
  _shuffle(shuffled, roll);
  final paceLift = clampPaceSeconds(request.secondsPerLift);
  final paceRest = clampPaceSeconds(request.secondsPerRest);
  final target = request.targetMinutes < 5 ? 5 : request.targetMinutes;
  final picked = <LibraryLift>[];
  for (final lift in shuffled) {
    picked.add(lift);
    if (_minutes(picked, paceLift, paceRest) >= target) break;
  }
  final ordered = _order(picked, roll);
  return ShuffledWorkout(
    lifts: ordered,
    minutes: _minutes(ordered, paceLift, paceRest),
  );
}

int _minutes(List<LibraryLift> lifts, int secondsPerLift, int secondsPerRest) {
  var cardio = 0;
  var strengthSets = 0;
  for (final lift in lifts) {
    if (lift.isCardio) {
      cardio += 30;
      continue;
    }
    strengthSets += 3;
  }
  if (strengthSets <= 0) return cardio;
  final work = strengthSets * secondsPerLift / 60;
  final rest = (strengthSets - 1) * secondsPerRest / 60;
  return (cardio + work + rest).round();
}

bool _matches(LibraryLift lift, ShuffleRequest request) {
  if (request.equipment.isEmpty) return false;
  if (!request.equipment.contains(lift.equipment)) return false;
  if (lift.isCardio &&
      !request.includeCardio &&
      !_selectedCardioOrSportGear(lift.equipment)) {
    return false;
  }
  if (request.focus.isEmpty) return true;
  final patterns = _patterns(lift);
  for (final focus in request.focus) {
    if (focus == 'push' || focus == 'pull' || focus == 'legs') {
      if (patterns.contains(focus)) return true;
    } else if (lift.muscleGroups.contains(focus)) {
      return true;
    }
  }
  return false;
}

bool _selectedCardioOrSportGear(String equipment) {
  return cardioGear.contains(equipment) || sportsGear.contains(equipment);
}

List<String> _patterns(LibraryLift lift) {
  final muscles = lift.muscleGroups.toSet();
  final tags = lift.tags.map((tag) => tag.toLowerCase()).toSet();
  final patterns = <String>{};
  if (muscles.any(_legMuscles.contains)) patterns.add('legs');
  if (muscles.contains('back') || muscles.contains('biceps') || tags.contains('pull')) {
    patterns.add('pull');
  }
  if (muscles.contains('chest') || muscles.contains('triceps') || tags.contains('push')) {
    patterns.add('push');
  }
  if (muscles.contains('shoulders') &&
      !muscles.contains('back') &&
      !muscles.contains('core') &&
      !muscles.any(_legMuscles.contains)) {
    patterns.add('push');
  }
  return patterns.toList();
}

bool _finisher(LibraryLift lift) {
  if (lift.isCardio) return true;
  return lift.tags.any((tag) => _finisherTags.contains(tag.toLowerCase()));
}

bool _compound(LibraryLift lift) {
  if (lift.isCardio || _finisher(lift)) return false;
  final tags = lift.tags.map((tag) => tag.toLowerCase()).toSet();
  if (tags.contains('compound')) return true;
  if (tags.contains('isolation')) return false;
  final primary = lift.muscleGroups.where((group) => group != 'core').toList();
  if (primary.length >= 2) return true;
  final name = lift.name.toLowerCase();
  if (RegExp(
    r'\b(squat|deadlift|bench|press|row|pull-up|pullup|chin-up|lunge|rdl|thrust|clean|snatch|step-up)\b',
  ).hasMatch(name)) {
    return true;
  }
  if (RegExp(
    r'\b(curl|extension|fly|flye|raise|crunch|pushdown|kickback|pullover|plank)\b',
  ).hasMatch(name)) {
    return false;
  }
  return false;
}

List<LibraryLift> _order(List<LibraryLift> lifts, double Function() random) {
  if (lifts.length <= 1) return [...lifts];
  final remaining = [...lifts];
  final ordered = <LibraryLift>[];
  while (remaining.isNotEmpty) {
    var bestIndex = 0;
    var bestScore = -1e9;
    for (var i = 0; i < remaining.length; i++) {
      final score = _orderScore(remaining[i], ordered, remaining, random);
      if (score > bestScore) {
        bestScore = score;
        bestIndex = i;
      }
    }
    ordered.add(remaining.removeAt(bestIndex));
  }
  return ordered;
}

double _orderScore(
  LibraryLift lift,
  List<LibraryLift> ordered,
  List<LibraryLift> remaining,
  double Function() random,
) {
  var score = random() * 2;
  final finisher = _finisher(lift);
  final mainLeft = remaining.any((other) => other != lift && !_finisher(other));
  if (finisher) {
    score += mainLeft ? -80 : ordered.length * 3;
    if (lift.isCardio) score += ordered.length * 2;
  } else if (_compound(lift)) {
    final compoundsLeft = remaining
        .where((other) => !_finisher(other) && _compound(other))
        .length;
    if (compoundsLeft > 0) score += 25;
    score += (18 - ordered.where((other) => !_finisher(other)).length).clamp(0, 18);
  } else {
    final compoundsLeft = remaining
        .where((other) => !_finisher(other) && _compound(other))
        .length;
    score += compoundsLeft > 0 ? -22 : 10;
  }
  if (ordered.isNotEmpty) {
    final overlap = _overlap(lift, ordered.last);
    score -= overlap * 14;
    if (overlap > 0 && _compound(lift) && _compound(ordered.last)) score -= 10;
  }
  return score;
}

int _overlap(LibraryLift a, LibraryLift b) {
  final primary = a.muscleGroups.where((group) => group != 'core').toSet();
  final other = b.muscleGroups.where((group) => group != 'core');
  final left = primary.isEmpty ? a.muscleGroups.toSet() : primary;
  final right = other.isEmpty ? b.muscleGroups : other.toList();
  var count = 0;
  for (final muscle in right) {
    if (left.contains(muscle)) count++;
  }
  return count;
}

void _shuffle(List<LibraryLift> items, double Function() random) {
  for (var i = items.length - 1; i > 0; i--) {
    final j = (random() * (i + 1)).floor();
    final swap = items[i];
    items[i] = items[j];
    items[j] = swap;
  }
}

final _random = Random();

double _defaultRandom() => _random.nextDouble();
