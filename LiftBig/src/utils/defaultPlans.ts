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
): TemplateExercise {
  return {
    id: `${planId}__${slug}`,
    name,
    isCircuit,
    sets: row(sets, reps, weight),
  }
}

export const DEFAULT_PLANS: WorkoutTemplate[] = [
  {
    id: 'plan-back-legs',
    name: 'Back / Legs',
    exercises: [
      te('plan-back-legs', 'pull-ups-lat', 'Pull Ups / Lat Pulldown', 4, '8-12', '120'),
      te('plan-back-legs', 'leg-extension', 'Leg Extension', 3, '12-15', '140'),
      te('plan-back-legs', 'row-variation', 'Row Variation', 3, '8-12', '110'),
      te('plan-back-legs', 'hamstring-curl', 'Hamstring Curl', 3, '10-15', '120'),
      te('plan-back-legs', 'face-pulls', 'Face Pulls', 3, '12-15', '100'),
      te('plan-back-legs', 'cable-curl', 'Cable Curl', 3, '10-12', '30'),
      te('plan-back-legs', 'tricep-pushdown', 'Tricep Pushdown', 3, '10-12', '70'),
      te('plan-back-legs', 'lateral-raises', 'Lateral Raises', 3, '15-20', '20'),
      te('plan-back-legs', 'cable-woodchops', 'Cable Woodchops', 3, '10-12', '25'),
    ],
  },
  {
    id: 'plan-chest-1',
    name: 'Chest 1',
    exercises: [
      te('plan-chest-1', 'incline-db-press', 'Incline DB Press', 4, '6-10', '65'),
      te('plan-chest-1', 'db-lateral-raise', 'DB Lateral Raise', 4, '12-20', '20'),
      te('plan-chest-1', 'incline-machine-press', 'Incline Machine Press', 3, '8-12', '95'),
      te('plan-chest-1', 'rear-delt-fly', 'Rear Delt Fly', 3, '12-15', '20'),
      te('plan-chest-1', 'machine-flyes', 'Machine Flyes', 3, '12-15', '80'),
      te('plan-chest-1', 'cable-lateral-raise', 'Cable Lateral Raise', 3, '12-15', '15'),
      te('plan-chest-1', 'ab-machine', 'Ab Machine / Leg Raises', 3, '10-15', '100'),
    ],
  },
  {
    id: 'plan-back',
    name: 'Back',
    exercises: [
      te('plan-back', 'pull-ups', 'Pull Ups', 4, 'AMRAP', '160'),
      te('plan-back', 'single-arm-lat', 'Single Arm Lat Pulldown', 3, '10-12', '60'),
      te('plan-back', 'lat-pulldown', 'Lat Pulldown', 3, '8-12', '100'),
      te('plan-back', 'seated-bentover-row', 'Seated / Bentover Row', 3, '8-12', '100'),
      te('plan-back', 'chest-supported-row', 'Chest Supported Row', 3, '8-12', '100'),
      te('plan-back', 'face-pulls', 'Face Pulls', 3, '12-15', '100'),
      te('plan-back', 'cable-crunches', 'Cable Crunches', 3, '12-15', '100'),
    ],
  },
  {
    id: 'plan-circuit',
    name: 'Circuit Day',
    isCircuit: true,
    exercises: [
      te('plan-circuit', 'goblet-squat', 'DB Goblet Squat', 3, '12-15', '20', true),
      te('plan-circuit', 'db-rdl', "DB RDL's", 3, '10-12', '20', true),
      te('plan-circuit', 'push-ups', 'Push-ups', 3, 'AMRAP', '20', true),
      te('plan-circuit', 'db-rows', 'DB Rows', 3, '10-15', '20', true),
      te('plan-circuit', 'lateral-raises', 'Lateral Raises', 3, '15-20', '20', true),
      te('plan-circuit', 'hammer-curls', 'DB Hammer Curls', 3, '10-12', '20', true),
      te('plan-circuit', 'oh-tricep', 'DB Overhead Tricep Extension', 3, '10-12', '20', true),
    ],
  },
  {
    id: 'plan-chest-2',
    name: 'Chest 2',
    exercises: [
      te('plan-chest-2', 'incline-db-press', 'Incline DB Press', 4, '8-12', '55'),
      te('plan-chest-2', 'rear-delt-fly', 'Rear Delt Fly', 3, '12-15', '20'),
      te('plan-chest-2', 'flat-db-press', 'Flat DB Press', 3, '8-12', '45'),
      te('plan-chest-2', 'lat-raise-dropset', 'Lateral Raise Dropset', 3, 'AMRAP', '20'),
      te('plan-chest-2', 'cable-flyes', 'Cable Flyes', 3, '10-15', '20'),
      te('plan-chest-2', 'cable-lat-raise', 'Cable Lateral Raise', 4, '12-15', '15'),
      te('plan-chest-2', 'oh-tricep', 'Overhead Tricep Extension', 3, '10-12', '70'),
      te('plan-chest-2', 'incline-cable-curl', 'Incline Cable Curl', 3, '10-12', '20'),
      te('plan-chest-2', 'rev-crunches', 'Weighted Reverse Crunches', 3, '10-12', '25'),
    ],
  },
  {
    id: 'plan-legs',
    name: 'Legs',
    exercises: [
      te('plan-legs', 'leg-press-squat', 'Leg Press / Squat', 4, '6-10', '275'),
      te('plan-legs', 'rdl', 'RDL', 4, '8-12', '135'),
      te('plan-legs', 'seated-ham-curl', 'Seated Hamstring Curl', 3, '10-15', '140'),
      te('plan-legs', 'leg-extension', 'Leg Extension', 3, '12-15', '140'),
      te('plan-legs', 'calf-raises', 'Calf Raises', 4, '12-20', '225'),
      te('plan-legs', 'walking-lunges', 'Walking Lunges', 2, '10-12', '40'),
    ],
  },
]
