import '../journal/progressive_overload.dart';
import '../model/journal_day.dart';
import 'lift_progress.dart';

/// One future session drawn on the exercise chart. Display only.
class PredictedLiftSession {
  const PredictedLiftSession({required this.weightLbs, required this.reps});

  final double weightLbs;
  final int reps;
}

/// How many future sessions the exercise chart projects.
const int maxPredictedLiftSessions = 5;

/// Working and warmup sets for the same lift the chart is showing.
///
/// [predictWorkoutGoals] drops warmups. The chart does not pre-filter them,
/// so the overload rule stays in that function.
List<HistorySet> historySetsForLoggedLift(
  List<JournalDay> days, {
  required String exerciseName,
  String? libraryId,
}) {
  final out = <HistorySet>[];
  for (final day in days) {
    for (final exercise in day.exercises) {
      if (exercise.isCardio && !exercise.isCircuit) continue;
      if (!matchesLoggedLift(
        exercise,
        name: exerciseName,
        libraryId: libraryId,
      )) {
        continue;
      }
      for (final set in exercise.sets) {
        out.add(
          HistorySet(
            dateKey: day.dateKey,
            exerciseName: exerciseName,
            reps: set.reps,
            weight: set.weight,
            isWarmup: set.isWarmup,
            targetReps: exercise.targetReps,
            difficulty: set.difficulty,
          ),
        );
      }
    }
  }
  return out;
}

/// Up to [steps] future sessions from [predictWorkoutGoals].
///
/// Each step is appended only in memory so the next call sees it as the latest
/// completed session. Nothing is written to the journal. No history means an
/// empty list — this does not invent a body-weight starting load.
List<PredictedLiftSession> predictFutureLiftSessions({
  required String exerciseName,
  required List<HistorySet> history,
  int steps = maxPredictedLiftSessions,
}) {
  if (steps <= 0) return const [];
  if (!predictWorkoutGoals(exerciseName, history).hasHistory) {
    return const [];
  }

  final projected = List<HistorySet>.of(history);
  final out = <PredictedLiftSession>[];
  for (var step = 0; step < steps; step++) {
    final predicted = predictWorkoutGoals(exerciseName, projected);
    if (!predicted.hasHistory || predicted.suggestedWeightLbs <= 0) break;
    final logReps = predicted.suggestedLogReps.trim();
    final reps = int.tryParse(
      logReps.isNotEmpty
          ? logReps
          : defaultLogRepsForTarget(predicted.suggestedReps),
    );
    if (reps == null || reps <= 0) break;
    final weightLbs = predicted.suggestedWeightLbs;
    out.add(PredictedLiftSession(weightLbs: weightLbs, reps: reps));
    projected.add(
      HistorySet(
        dateKey: '9999-01-${(step + 1).toString().padLeft(2, '0')}',
        exerciseName: exerciseName,
        reps: '$reps',
        weight: formatPredictedWeight(weightLbs),
        targetReps: predicted.suggestedReps,
      ),
    );
  }
  return out;
}
