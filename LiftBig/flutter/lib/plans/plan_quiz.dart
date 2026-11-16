import '../catalog/liftbig_catalog.dart';

class QuizAnswers {
  const QuizAnswers({
    this.experience,
    this.goal,
    this.daysPerWeek,
    this.duration,
    this.equipment,
    this.style,
  });

  final String? experience;
  final String? goal;
  final int? daysPerWeek;
  final String? duration;
  final String? equipment;
  final String? style;

  QuizAnswers copyWith({
    String? experience,
    String? goal,
    int? daysPerWeek,
    String? duration,
    String? equipment,
    String? style,
  }) {
    return QuizAnswers(
      experience: experience ?? this.experience,
      goal: goal ?? this.goal,
      daysPerWeek: daysPerWeek ?? this.daysPerWeek,
      duration: duration ?? this.duration,
      equipment: equipment ?? this.equipment,
      style: style ?? this.style,
    );
  }
}

class PlanMatch {
  const PlanMatch({
    required this.entry,
    required this.score,
    required this.badge,
    required this.reasons,
  });

  final QuizEntry entry;
  final int score;
  final String badge;
  final List<String> reasons;
}

const quizGoalLabels = <String, String>{
  'strength': 'Build Strength',
  'size': 'Build Size',
  'weightLoss': 'Lose Weight',
  'liftBig': 'Lift Big',
};

const quizDurationLabels = <String, String>{
  'quick': 'Quick duration',
  'standard': 'Standard duration',
  'long': 'Long sessions',
};

const quizExperienceLabels = <String, String>{
  'beginner': 'Beginner',
  'intermediate': 'Intermediate',
  'experienced': 'Experienced',
  'liftaholic': 'Liftaholic',
};

const _durationOrder = ['quick', 'standard', 'long'];

int scoreQuizEntry(QuizEntry entry, QuizAnswers answers) {
  var score = 0;
  if (answers.experience != null &&
      entry.experienceLevels.contains(answers.experience)) {
    score += 50;
  }
  if (answers.goal != null && entry.goals.contains(answers.goal)) {
    score += 40;
  }
  score += _daysScore(answers.daysPerWeek, entry.days);
  score += _durationScore(answers.duration, entry.duration);
  if (answers.equipment != null &&
      _equipmentMatches(answers.equipment!, entry.equipment)) {
    score += 30;
  }
  if (answers.style != null && entry.styles.contains(answers.style)) {
    score += 20;
  }
  return score;
}

List<String> matchReasons(QuizEntry entry, QuizAnswers answers) {
  final reasons = <String>[];
  final goal = answers.goal;
  if (goal != null && entry.goals.contains(goal)) {
    reasons.add(quizGoalLabels[goal] ?? goal);
  }
  final days = answers.daysPerWeek;
  if (days != null && entry.days.any((target) => (target - days).abs() <= 1)) {
    reasons.add('$days days/week');
  }
  final duration = answers.duration;
  if (duration != null && entry.duration.contains(duration)) {
    reasons.add(quizDurationLabels[duration] ?? duration);
  }
  if (answers.equipment != null &&
      _equipmentMatches(answers.equipment!, entry.equipment)) {
    reasons.add('Equipment match');
  }
  if (answers.style != null && entry.styles.contains(answers.style)) {
    reasons.add('Style match');
  }
  final experience = answers.experience;
  if (experience != null && entry.experienceLevels.contains(experience)) {
    reasons.add(quizExperienceLabels[experience] ?? experience);
  }
  return reasons;
}

String quizHeadline(QuizAnswers answers) {
  final parts = <String>[];
  final goal = answers.goal;
  if (goal != null) {
    final phrase = switch (goal) {
      'strength' => 'build strength',
      'size' => 'build muscle',
      'weightLoss' => 'lose weight while keeping muscle',
      'liftBig' => 'lift big with high-volume training',
      _ => goal,
    };
    parts.add('aiming to $phrase');
  }
  final days = answers.daysPerWeek;
  if (days != null) {
    parts.add('can train $days ${days == 1 ? 'day' : 'days'}/week');
  }
  if (parts.isEmpty) {
    return "Here's what we'd start with based on your answers.";
  }
  return "Looks like you're ${parts.join(' and ')}. Here's what we'd start with.";
}

/// Top three premade plans, preferring different styles the way the Vue quiz does.
List<PlanMatch> recommendPlans(List<QuizEntry> catalog, QuizAnswers answers) {
  final scored = [
    for (final entry in catalog)
      if (_planAllowed(entry, answers))
        (entry: entry, score: scoreQuizEntry(entry, answers)),
  ]..sort((a, b) => b.score.compareTo(a.score));

  final picked = <({QuizEntry entry, int score})>[];
  final used = <String>{};
  for (final item in scored) {
    if (picked.length >= 3) break;
    final key = _archetype(item.entry);
    if (picked.isNotEmpty && used.contains(key)) continue;
    picked.add(item);
    used.add(key);
  }
  for (final item in scored) {
    if (picked.length >= 3) break;
    if (picked.every((chosen) => chosen.entry.id != item.entry.id)) {
      picked.add(item);
    }
  }

  const badges = ['Best Match', 'Great Alternative', 'Something Different'];
  return [
    for (var i = 0; i < picked.length; i++)
      PlanMatch(
        entry: picked[i].entry,
        score: picked[i].score,
        badge: badges[i],
        reasons: matchReasons(picked[i].entry, answers),
      ),
  ];
}

String _archetype(QuizEntry entry) {
  final style = entry.styles.isEmpty ? '' : entry.styles.first;
  return '$style|${entry.category}|${entry.goalTag}';
}

int _daysScore(int? answer, List<int> targets) {
  if (answer == null || targets.isEmpty) return 0;
  var best = 0;
  for (final target in targets) {
    final diff = (answer - target).abs();
    final score = switch (diff) {
      0 => 30,
      1 => 20,
      2 => 10,
      _ => 0,
    };
    if (score > best) best = score;
  }
  return best;
}

int _durationScore(String? answer, List<String> targets) {
  if (answer == null) return 0;
  if (targets.contains(answer)) return 25;
  final answerIndex = _durationOrder.indexOf(answer);
  if (answerIndex < 0) return 0;
  for (final target in targets) {
    final index = _durationOrder.indexOf(target);
    if (index >= 0 && (answerIndex - index).abs() == 1) return 15;
  }
  return 0;
}

bool _equipmentMatches(String answer, List<String> equipment) {
  return equipment.contains(answer);
}

bool _planAllowed(QuizEntry entry, QuizAnswers answers) {
  return _experienceAllowed(answers.experience, entry) &&
      _equipmentAllowed(answers.equipment, entry.equipment);
}

/// Apartment answers only receive apartment plans. A commercial answer is not
/// filled with an apartment-only plan.
bool _equipmentAllowed(String? answer, List<String> equipment) {
  if (answer == null) return true;
  if (answer == 'apartmentGym') return equipment.contains('apartmentGym');
  if (!equipment.contains(answer)) return false;
  if (answer == 'commercialGym' &&
      equipment.contains('apartmentGym') &&
      !equipment.contains('commercialGym')) {
    return false;
  }
  return true;
}

/// A beginner cannot be given an experienced or liftaholic plan.
bool _experienceAllowed(String? answer, QuizEntry entry) {
  if (answer == null) return true;
  final levels = entry.experienceLevels;
  if (levels.contains(answer)) {
    if (answer == 'beginner' &&
        (entry.category == 'experienced' || entry.category == 'liftaholic')) {
      return false;
    }
    return true;
  }
  if (answer == 'beginner') {
    if (entry.category == 'experienced' || entry.category == 'liftaholic') {
      return false;
    }
    if (levels.contains('experienced') || levels.contains('liftaholic')) {
      return false;
    }
    return levels.contains('intermediate');
  }
  return false;
}

String quizFitSentence(QuizEntry entry, QuizAnswers answers) {
  final who = quizAudienceBullet(entry).replaceFirst('For ', '');
  final days = answers.daysPerWeek;
  final goal = switch (answers.goal) {
    'strength' => 'to get stronger',
    'size' => 'to build muscle',
    'weightLoss' => 'to lose weight while keeping muscle',
    'liftBig' => 'to train hard and often',
    _ => null,
  };
  if (days != null && goal != null) {
    final dayWord = days == 1 ? 'day' : 'days';
    return 'Chosen for ${who.toLowerCase()} who can train $days $dayWord a week and want $goal.';
  }
  return 'Chosen for ${who.toLowerCase()} from the answers you gave.';
}

String quizDaysBullet(List<int> days) {
  if (days.isEmpty) return 'Flexible weekly schedule';
  final sorted = [...days]..sort();
  if (sorted.length == 1) return '${sorted.first} days a week';
  return '${sorted.first}–${sorted.last} days a week';
}

String quizSessionBullet(int minutes) {
  if (minutes <= 0) return 'Session length varies';
  return 'About $minutes minutes';
}

String quizEquipmentBullet(List<String> equipment) {
  const labels = {
    'commercialGym': 'Large gym',
    'apartmentGym': 'Apartment gym',
    'homeGym': 'Home gym',
    'dumbbellsOnly': 'Dumbbells',
    'minimalEquipment': 'Minimal equipment',
  };
  if (equipment.isEmpty) return 'Any setup';
  return equipment.map((item) => labels[item] ?? item).join(', ');
}

String quizAudienceBullet(QuizEntry entry) {
  const labels = {
    'beginner': 'Beginners',
    'intermediate': 'People who train regularly',
    'experienced': 'Experienced lifters',
    'liftaholic': 'People who train most days',
  };
  if (entry.experienceLevels.isEmpty) {
    return entry.difficulty.isEmpty ? 'For most lifters' : 'For ${entry.difficulty}';
  }
  final who = entry.experienceLevels.map((level) => labels[level] ?? level).join(' and ');
  return 'For $who';
}
