// app/utils/progressiveOverload.ts
import AsyncStorage from "@react-native-async-storage/async-storage";

export type SetLog = { reps: string; weight: string };
export type ExerciseLog = { id: string; name: string; sets: SetLog[] };
export type WorkoutLog = { [dateKey: string]: ExerciseLog[] };

// How much to increase weight per exercise category (lbs)
const INCREMENT_MAP: { [key: string]: number } = {
  // Big compound / machine lower body
  "leg press": 10,
  "squat": 5,
  "rdl": 5,
  "leg extension": 5,
  "hamstring curl": 5,
  "seated hamstring curl": 5,
  "calf raises": 10,
  "walking lunges": 5,
  // Upper body compound
  "incline db press": 5,
  "flat db press": 5,
  "incline machine press": 5,
  "pull ups": 5,
  "lat pulldown": 5,
  "single arm lat pulldown": 2.5,
  "row variation": 5,
  "seated/bentover row": 5,
  "bentover row": 5,
  "chest supported row": 5,
  // Isolation / cables / light
  "cable curl": 2.5,
  "incline cable curl": 2.5,
  "tricep pushdown": 2.5,
  "overhead tricep extension": 2.5,
  "face pulls": 2.5,
  "cable lateral raise": 2.5,
  "lateral raises": 2.5,
  "lateral raise dropset": 2.5,
  "rear delt fly": 2.5,
  "machine flyes": 2.5,
  "cable flyes": 2.5,
  "cable woodchops": 2.5,
  "cable crunches": 2.5,
  "ab machine": 5,
  "weighted reverse crunches": 2.5,
};

function getIncrement(exerciseName: string): number {
  const lower = exerciseName.toLowerCase();
  for (const key of Object.keys(INCREMENT_MAP)) {
    if (lower.includes(key)) return INCREMENT_MAP[key];
  }
  return 2.5; // default for anything unmatched
}

function isAMRAP(repGoal: string): boolean {
  return repGoal.toLowerCase().includes("amrap");
}

function parseRepRange(repGoal: string): { min: number; max: number } {
  if (isAMRAP(repGoal)) return { min: 1, max: 9999 };
  const match = repGoal.match(/(\d+)\s*[-–]\s*(\d+)/);
  if (match) return { min: parseInt(match[1]), max: parseInt(match[2]) };
  const single = parseInt(repGoal);
  if (!isNaN(single)) return { min: single, max: single };
  return { min: 0, max: 9999 };
}

// Returns the suggested weight for an exercise given its history
export async function getSuggestedWeight(
  exerciseName: string,
  targetRepGoal: string,
  currentGoalWeight: number
): Promise<{ suggestedWeight: number; reason: string }> {
  try {
    const raw = await AsyncStorage.getItem("liftbig_workouts");
    if (!raw) return { suggestedWeight: currentGoalWeight, reason: "No history yet" };

    const allWorkouts: WorkoutLog = JSON.parse(raw);
    const { max: repMax } = parseRepRange(targetRepGoal);

    // Collect all logged sets for this exercise, sorted by date descending
    const history: { date: string; sets: SetLog[] }[] = [];
    for (const [date, exercises] of Object.entries(allWorkouts)) {
      const match = exercises.find(
        (ex) => ex.name.toLowerCase() === exerciseName.toLowerCase()
      );
      if (match) history.push({ date, sets: match.sets });
    }
    history.sort((a, b) => b.date.localeCompare(a.date));

    if (history.length === 0) {
      return { suggestedWeight: currentGoalWeight, reason: "No history yet" };
    }

    // Look at the most recent session
    const lastSession = history[0];
    const completedSets = lastSession.sets.filter(
      (s) => s.reps !== "" && s.weight !== ""
    );
    if (completedSets.length === 0) {
      return { suggestedWeight: currentGoalWeight, reason: "No completed sets found" };
    }

    // Check if all sets hit the top of the rep range
    const allHitMax = completedSets.every((s) => {
      if (isAMRAP(targetRepGoal)) return true;
      return parseInt(s.reps) >= repMax;
    });

    const lastWeight = parseFloat(completedSets[completedSets.length - 1].weight) || currentGoalWeight;
    const increment = getIncrement(exerciseName);

    if (allHitMax) {
      return {
        suggestedWeight: lastWeight + increment,
        reason: `Hit top of range last session — increase by ${increment} lbs`,
      };
    }

    // Check if any set failed (below the min rep range)
    const { min: repMin } = parseRepRange(targetRepGoal);
    const anyFailed = completedSets.some((s) => parseInt(s.reps) < repMin);
    if (anyFailed) {
      return {
        suggestedWeight: lastWeight,
        reason: "Stay at current weight — keep working toward the top of the range",
      };
    }

    return {
      suggestedWeight: lastWeight,
      reason: "Good progress — maintain weight and push for more reps",
    };
  } catch {
    return { suggestedWeight: currentGoalWeight, reason: "Could not load history" };
  }
}