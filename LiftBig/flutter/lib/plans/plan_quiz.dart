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
  if (equipment.contains(answer)) return true;
  return answer == 'planetFitness' && equipment.contains('commercialGym');
}
