import type { TemplateExercise, WorkoutTemplate } from '@/types/workout'

function row(n: number, reps: string, weight: string) {
  return Array.from({ length: n }, () => ({ targetReps: reps, targetWeight: weight }))
}

function te(
  planId: string,
  slug: string,
  name: string,
  sets: number,
  reps: string,
  weight: string,
  isCircuit = false,
  libraryId?: string,
): TemplateExercise {
  return {
    id: `${planId}__${slug}`,
    name,
    libraryId,
    isCircuit,
    sets: row(sets, reps, weight),
  }
}

export const DEFAULT_PLANS: WorkoutTemplate[] = [
  {
    id: 'plan-back-legs',
    name: 'Back / Legs',
    exercises: [
      te('plan-back-legs', 'pull-ups-lat', 'Pull Ups / Lat Pulldown', 4, '8-12', '120', false, 'pull-up'),
      te('plan-back-legs', 'leg-extension', 'Leg Extension', 3, '12-15', '140', false, 'leg-extension'),
      te('plan-back-legs', 'row-variation', 'Row Variation', 3, '8-12', '110', false, 'barbell-row'),
      te('plan-back-legs', 'hamstring-curl', 'Hamstring Curl', 3, '10-15', '120', false, 'hamstring-curl'),
      te('plan-back-legs', 'face-pulls', 'Face Pulls', 3, '12-15', '100', false, 'face-pull'),
      te('plan-back-legs', 'cable-curl', 'Cable Curl', 3, '10-12', '30', false, 'cable-curl'),
      te('plan-back-legs', 'tricep-pushdown', 'Tricep Pushdown', 3, '10-12', '70', false, 'tricep-pushdown'),
      te('plan-back-legs', 'lateral-raises', 'Lateral Raises', 3, '15-20', '20', false, 'lateral-raise'),
      te('plan-back-legs', 'cable-woodchops', 'Cable Woodchops', 3, '10-12', '25', false, 'cable-woodchop'),
    ],
  },
  {
    id: 'plan-chest-1',
    name: 'Chest 1',
    exercises: [
      te('plan-chest-1', 'incline-db-press', 'Incline DB Press', 4, '6-10', '65', false, 'incline-dumbbell-press'),
      te('plan-chest-1', 'db-lateral-raise', 'DB Lateral Raise', 4, '12-20', '20', false, 'lateral-raise'),
      te('plan-chest-1', 'incline-machine-press', 'Incline Machine Press', 3, '8-12', '95', false, 'incline-machine-press'),
      te('plan-chest-1', 'rear-delt-fly', 'Rear Delt Fly', 3, '12-15', '20', false, 'rear-delt-fly'),
      te('plan-chest-1', 'machine-flyes', 'Machine Flyes', 3, '12-15', '80', false, 'machine-fly'),
      te('plan-chest-1', 'cable-lateral-raise', 'Cable Lateral Raise', 3, '12-15', '15', false, 'lateral-raise'),
      te('plan-chest-1', 'ab-machine', 'Ab Machine / Leg Raises', 3, '10-15', '100', false, 'ab-machine-crunch'),
    ],
  },
  {
    id: 'plan-back',
    name: 'Back',
    exercises: [
      te('plan-back', 'pull-ups', 'Pull Ups', 4, 'AMRAP', '160', false, 'pull-up'),
      te('plan-back', 'single-arm-lat', 'Single Arm Lat Pulldown', 3, '10-12', '60', false, 'lat-pulldown'),
      te('plan-back', 'lat-pulldown', 'Lat Pulldown', 3, '8-12', '100', false, 'lat-pulldown'),
      te('plan-back', 'seated-bentover-row', 'Seated / Bentover Row', 3, '8-12', '100', false, 'seated-cable-row'),
      te('plan-back', 'chest-supported-row', 'Chest Supported Row', 3, '8-12', '100', false, 'chest-supported-row'),
      te('plan-back', 'face-pulls', 'Face Pulls', 3, '12-15', '100', false, 'face-pull'),
      te('plan-back', 'cable-crunches', 'Cable Crunches', 3, '12-15', '100', false, 'cable-crunch'),
    ],
  },
  {
    id: 'plan-circuit',
    name: 'Circuit Day',
    isCircuit: true,
    exercises: [
      te('plan-circuit', 'goblet-squat', 'DB Goblet Squat', 3, '12-15', '20', true, 'goblet-squat'),
      te('plan-circuit', 'db-rdl', "DB RDL's", 3, '10-12', '20', true, 'dumbbell-romanian-deadlift'),
      te('plan-circuit', 'push-ups', 'Push-ups', 3, 'AMRAP', '20', true, 'push-up'),
      te('plan-circuit', 'db-rows', 'DB Rows', 3, '10-15', '20', true, 'dumbbell-row'),
      te('plan-circuit', 'lateral-raises', 'Lateral Raises', 3, '15-20', '20', true, 'lateral-raise'),
      te('plan-circuit', 'hammer-curls', 'DB Hammer Curls', 3, '10-12', '20', true, 'hammer-curl'),
      te('plan-circuit', 'oh-tricep', 'DB Overhead Tricep Extension', 3, '10-12', '20', true, 'overhead-tricep-extension'),
    ],
  },
  {
    id: 'plan-chest-2',
    name: 'Chest 2',
    exercises: [
      te('plan-chest-2', 'incline-db-press', 'Incline DB Press', 4, '8-12', '55', false, 'incline-dumbbell-press'),
      te('plan-chest-2', 'rear-delt-fly', 'Rear Delt Fly', 3, '12-15', '20', false, 'rear-delt-fly'),
      te('plan-chest-2', 'flat-db-press', 'Flat DB Press', 3, '8-12', '45', false, 'flat-dumbbell-press'),
      te('plan-chest-2', 'lat-raise-dropset', 'Lateral Raise Dropset', 3, 'AMRAP', '20', false, 'lateral-raise'),
      te('plan-chest-2', 'cable-flyes', 'Cable Flyes', 3, '10-15', '20', false, 'cable-fly'),
      te('plan-chest-2', 'cable-lat-raise', 'Cable Lateral Raise', 4, '12-15', '15', false, 'lateral-raise'),
      te('plan-chest-2', 'oh-tricep', 'Overhead Tricep Extension', 3, '10-12', '70', false, 'overhead-tricep-extension'),
      te('plan-chest-2', 'incline-cable-curl', 'Incline Cable Curl', 3, '10-12', '20', false, 'incline-cable-curl'),
      te('plan-chest-2', 'rev-crunches', 'Weighted Reverse Crunches', 3, '10-12', '25', false, 'reverse-crunch'),
    ],
  },
  {
    id: 'plan-legs',
    name: 'Legs',
    exercises: [
      te('plan-legs', 'leg-press-squat', 'Leg Press / Squat', 4, '6-10', '275', false, 'leg-press'),
      te('plan-legs', 'rdl', 'RDL', 4, '8-12', '135', false, 'romanian-deadlift'),
      te('plan-legs', 'seated-ham-curl', 'Seated Hamstring Curl', 3, '10-15', '140', false, 'hamstring-curl'),
      te('plan-legs', 'leg-extension', 'Leg Extension', 3, '12-15', '140', false, 'leg-extension'),
      te('plan-legs', 'calf-raises', 'Calf Raises', 4, '12-20', '225', false, 'calf-raise'),
      te('plan-legs', 'walking-lunges', 'Walking Lunges', 2, '10-12', '40', false, 'walking-lunge'),
    ],
  },
]
