// app/utils/defaultPlans.ts
import AsyncStorage from "@react-native-async-storage/async-storage";

export type TemplateSet = { targetReps: string; targetWeight: string };
export type TemplateExercise = { id: string; name: string; sets: TemplateSet[]; isCircuit?: boolean };
export type WorkoutTemplate = { id: string; name: string; exercises: TemplateExercise[]; isCircuit?: boolean };

function ex(name: string, sets: number, reps: string, weight: string, isCircuit = false): TemplateExercise {
  return {
    id: name.replace(/\s+/g, "-").toLowerCase() + "-" + Date.now() + Math.random(),
    name,
    isCircuit,
    sets: Array.from({ length: sets }, () => ({ targetReps: reps, targetWeight: weight })),
  };
}

export const DEFAULT_PLANS: WorkoutTemplate[] = [
  {
    id: "plan-back-legs",
    name: "Back / Legs",
    exercises: [
      ex("Pull Ups / Lat Pulldown", 4, "8-12", "120"),
      ex("Leg Extension", 3, "12-15", "140"),
      ex("Row Variation", 3, "8-12", "110"),
      ex("Hamstring Curl", 3, "10-15", "120"),
      ex("Face Pulls", 3, "12-15", "100"),
      ex("Cable Curl", 3, "10-12", "30"),
      ex("Tricep Pushdown", 3, "10-12", "70"),
      ex("Lateral Raises", 3, "15-20", "20"),
      ex("Cable Woodchops", 3, "10-12", "25"),
    ],
  },
  {
    id: "plan-chest-1",
    name: "Chest 1",
    exercises: [
      ex("Incline DB Press", 4, "6-10", "65"),
      ex("DB Lateral Raise", 4, "12-20", "20"),
      ex("Incline Machine Press", 3, "8-12", "95"),
      ex("Rear Delt Fly", 3, "12-15", "20"),
      ex("Machine Flyes", 3, "12-15", "80"),
      ex("Cable Lateral Raise", 3, "12-15", "15"),
      ex("Ab Machine / Leg Raises", 3, "10-15", "100"),
    ],
  },
  {
    id: "plan-back",
    name: "Back",
    exercises: [
      ex("Pull Ups", 4, "AMRAP", "160"),
      ex("Single Arm Lat Pulldown", 3, "10-12", "60"),
      ex("Lat Pulldown", 3, "8-12", "100"),
      ex("Seated / Bentover Row", 3, "8-12", "100"),
      ex("Chest Supported Row", 3, "8-12", "100"),
      ex("Face Pulls", 3, "12-15", "100"),
      ex("Cable Crunches", 3, "12-15", "100"),
    ],
  },
  {
    id: "plan-circuit",
    name: "Circuit Day",
    isCircuit: true,
    exercises: [
      ex("DB Goblet Squat", 3, "12-15", "20", true),
      ex("DB RDL's", 3, "10-12", "20", true),
      ex("Push-ups", 3, "AMRAP", "20", true),
      ex("DB Rows", 3, "10-15", "20", true),
      ex("Lateral Raises", 3, "15-20", "20", true),
      ex("DB Hammer Curls", 3, "10-12", "20", true),
      ex("DB Overhead Tricep Extension", 3, "10-12", "20", true),
    ],
  },
  {
    id: "plan-chest-2",
    name: "Chest 2",
    exercises: [
      ex("Incline DB Press", 4, "8-12", "55"),
      ex("Rear Delt Fly", 3, "12-15", "20"),
      ex("Flat DB Press", 3, "8-12", "45"),
      ex("Lateral Raise Dropset", 3, "AMRAP", "20"),
      ex("Cable Flyes", 3, "10-15", "20"),
      ex("Cable Lateral Raise", 4, "12-15", "15"),
      ex("Overhead Tricep Extension", 3, "10-12", "70"),
      ex("Incline Cable Curl", 3, "10-12", "20"),
      ex("Weighted Reverse Crunches", 3, "10-12", "25"),
    ],
  },
  {
    id: "plan-legs",
    name: "Legs",
    exercises: [
      ex("Leg Press / Squat", 4, "6-10", "275"),
      ex("RDL", 4, "8-12", "135"),
      ex("Seated Hamstring Curl", 3, "10-15", "140"),
      ex("Leg Extension", 3, "12-15", "140"),
      ex("Calf Raises", 4, "12-20", "225"),
      ex("Walking Lunges", 2, "10-12", "40"),
    ],
  },
];

export async function seedDefaultPlans() {
  const existing = await AsyncStorage.getItem("liftbig_templates");
  if (existing) return; // Don't overwrite if user has already saved plans
  await AsyncStorage.setItem("liftbig_templates", JSON.stringify(DEFAULT_PLANS));
}