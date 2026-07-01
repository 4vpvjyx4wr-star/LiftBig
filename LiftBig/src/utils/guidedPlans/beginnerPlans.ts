import type { TemplateFolder, WorkoutTemplate } from '@/types/workout'
import { catalogFolderId } from './catalogFolders'
import { GUIDED_BEGINNER_FOLDER } from './guidedPlanFolders'
import { te } from './guidedPlanHelpers'

const F = GUIDED_BEGINNER_FOLDER.id

export const BEGINNER_FULL_BODY_ID = 'plan-guided-beg-fullbody'
export const BEGINNER_UPPER_LOWER_FOLDER_ID = catalogFolderId('beginner-upper-lower-4d')
export const BUSY_BEGINNER_ID = 'plan-guided-beg-busy'
export const BEGINNER_WEIGHT_LOSS_ID = 'plan-guided-beg-weight-loss'
export const PLANET_FITNESS_STARTER_ID = 'plan-guided-beg-planet-fitness'
export const DUMBBELL_STARTER_ID = 'plan-guided-beg-dumbbell'

export const BEGINNER_PLANS: WorkoutTemplate[] = [
  {
    id: BEGINNER_FULL_BODY_ID,
    name: 'Beginner Full Body (3d)',
    folderId: F,
    exercises: [
      te(BEGINNER_FULL_BODY_ID, 'squat', 'Goblet Squat', 3, '10-12', '35', false, 'goblet-squat'),
      te(BEGINNER_FULL_BODY_ID, 'bench', 'Barbell Bench Press', 3, '8-10', '95', false, 'bench-press'),
      te(BEGINNER_FULL_BODY_ID, 'row', 'Seated Cable Row', 3, '10-12', '80', false, 'seated-cable-row'),
      te(BEGINNER_FULL_BODY_ID, 'rdl', 'Romanian Deadlift', 3, '10-12', '95', false, 'romanian-deadlift'),
      te(BEGINNER_FULL_BODY_ID, 'ohp', 'Dumbbell Shoulder Press', 3, '10-12', '25', false, 'dumbbell-shoulder-press'),
      te(BEGINNER_FULL_BODY_ID, 'plank', 'Plank', 3, '30-45 sec', '0', false, 'plank'),
    ],
  },
  {
    id: 'plan-guided-beg-upper-a',
    name: 'Upper A',
    folderId: BEGINNER_UPPER_LOWER_FOLDER_ID,
    exercises: [
      te('plan-guided-beg-upper-a', 'bench', 'Barbell Bench Press', 3, '8-10', '95', false, 'bench-press'),
      te('plan-guided-beg-upper-a', 'row', 'Lat Pulldown', 3, '10-12', '90', false, 'lat-pulldown'),
      te('plan-guided-beg-upper-a', 'ohp', 'Dumbbell Shoulder Press', 3, '10-12', '25', false, 'dumbbell-shoulder-press'),
      te('plan-guided-beg-upper-a', 'curl', 'Dumbbell Curl', 2, '10-12', '20', false, 'dumbbell-curl'),
      te('plan-guided-beg-upper-a', 'tri', 'Tricep Pushdown', 2, '10-12', '50', false, 'tricep-pushdown'),
    ],
  },
  {
    id: 'plan-guided-beg-lower-a',
    name: 'Lower A',
    folderId: BEGINNER_UPPER_LOWER_FOLDER_ID,
    exercises: [
      te('plan-guided-beg-lower-a', 'squat', 'Barbell Back Squat', 3, '8-10', '115', false, 'squat'),
      te('plan-guided-beg-lower-a', 'rdl', 'Romanian Deadlift', 3, '10-12', '95', false, 'romanian-deadlift'),
      te('plan-guided-beg-lower-a', 'leg-press', 'Leg Press', 3, '12-15', '180', false, 'leg-press'),
      te('plan-guided-beg-lower-a', 'curl', 'Leg Curl', 3, '12-15', '70', false, 'hamstring-curl'),
      te('plan-guided-beg-lower-a', 'calf', 'Calf Raise', 3, '15-20', '135', false, 'calf-raise'),
    ],
  },
  {
    id: 'plan-guided-beg-upper-b',
    name: 'Upper B',
    folderId: BEGINNER_UPPER_LOWER_FOLDER_ID,
    exercises: [
      te('plan-guided-beg-upper-b', 'incline', 'Incline DB Press', 3, '8-12', '35', false, 'incline-dumbbell-press'),
      te('plan-guided-beg-upper-b', 'pull', 'Chest Supported Row', 3, '10-12', '35', false, 'chest-supported-row'),
      te('plan-guided-beg-upper-b', 'lat', 'Cable Lateral Raise', 3, '12-15', '15', false, 'lateral-raise'),
      te('plan-guided-beg-upper-b', 'face', 'Face Pull', 3, '15-20', '60', false, 'face-pull'),
      te('plan-guided-beg-upper-b', 'hammer', 'Hammer Curl', 2, '10-12', '20', false, 'hammer-curl'),
    ],
  },
  {
    id: 'plan-guided-beg-lower-b',
    name: 'Lower B',
    folderId: BEGINNER_UPPER_LOWER_FOLDER_ID,
    exercises: [
      te('plan-guided-beg-lower-b', 'deadlift', 'Trap Bar Deadlift', 3, '6-8', '135', false, 'trap-bar-deadlift'),
      te('plan-guided-beg-lower-b', 'lunge', 'Walking Lunge', 3, '10/side', '25', false, 'walking-lunge'),
      te('plan-guided-beg-lower-b', 'ext', 'Leg Extension', 3, '12-15', '90', false, 'leg-extension'),
      te('plan-guided-beg-lower-b', 'hip', 'Hip Thrust', 3, '10-12', '95', false, 'hip-thrust'),
      te('plan-guided-beg-lower-b', 'core', 'Cable Crunch', 3, '12-15', '70', false, 'cable-crunch'),
    ],
  },
  {
    id: 'plan-guided-beg-busy',
    name: 'Busy Beginner (3×30)',
    folderId: F,
    exercises: [
      te('plan-guided-beg-busy', 'goblet', 'Goblet Squat', 2, '12', '30', false, 'goblet-squat'),
      te('plan-guided-beg-busy', 'push', 'Push-Up', 2, 'AMRAP', '0', false, 'push-up'),
      te('plan-guided-beg-busy', 'row', 'Dumbbell Row', 2, '10/side', '25', false, 'dumbbell-row'),
      te('plan-guided-beg-busy', 'rdl', 'Dumbbell RDL', 2, '10', '25', false, 'dumbbell-romanian-deadlift'),
      te('plan-guided-beg-busy', 'raise', 'Lateral Raise', 2, '15', '15', false, 'lateral-raise'),
      te('plan-guided-beg-busy', 'plank', 'Plank', 2, '30 sec', '0', false, 'plank'),
    ],
  },
  {
    id: 'plan-guided-beg-weight-loss',
    name: 'Beginner Weight Loss',
    folderId: F,
    isCircuit: true,
    exercises: [
      te('plan-guided-beg-weight-loss', 'squat', 'Bodyweight Squat', 3, '15', '0', true, 'bodyweight-squat'),
      te('plan-guided-beg-weight-loss', 'push', 'Push-Up', 3, '10-15', '0', true, 'push-up'),
      te('plan-guided-beg-weight-loss', 'row', 'Inverted Row', 3, '8-12', '0', true, 'inverted-row'),
      te('plan-guided-beg-weight-loss', 'lunge', 'Walking Lunge', 3, '10/side', '0', true, 'walking-lunge'),
      te('plan-guided-beg-weight-loss', 'burpee', 'Burpee', 3, '8', '0', true, 'burpee'),
      te('plan-guided-beg-weight-loss', 'bike', 'Stationary Bike', 1, '10 min', '0', false, 'stationary-bike'),
    ],
  },
  {
    id: 'plan-guided-beg-planet-fitness',
    name: 'Planet Fitness Starter',
    folderId: F,
    notes: 'Full-body session using barbells, dumbbells, and cables — a solid intro to compound lifting at Planet Fitness.',
    exercises: [
      te('plan-guided-beg-planet-fitness', 'squat', 'Barbell Back Squat', 3, '8-10', '95', false, 'squat'),
      te('plan-guided-beg-planet-fitness', 'bench', 'Barbell Bench Press', 3, '8-10', '95', false, 'bench-press'),
      te('plan-guided-beg-planet-fitness', 'row', 'Seated Cable Row', 3, '10-12', '80', false, 'seated-cable-row'),
      te('plan-guided-beg-planet-fitness', 'rdl', 'Romanian Deadlift', 3, '10-12', '95', false, 'romanian-deadlift'),
      te('plan-guided-beg-planet-fitness', 'ohp', 'Dumbbell Shoulder Press', 3, '10-12', '25', false, 'dumbbell-shoulder-press'),
      te('plan-guided-beg-planet-fitness', 'lat', 'Lat Pulldown', 2, '10-12', '90', false, 'lat-pulldown'),
    ],
  },
  {
    id: 'plan-guided-beg-dumbbell',
    name: 'Dumbbell Starter',
    folderId: F,
    exercises: [
      te('plan-guided-beg-dumbbell', 'goblet', 'Goblet Squat', 3, '12', '35', false, 'goblet-squat'),
      te('plan-guided-beg-dumbbell', 'press', 'Flat DB Press', 3, '10-12', '40', false, 'flat-dumbbell-press'),
      te('plan-guided-beg-dumbbell', 'row', 'Dumbbell Row', 3, '10/side', '30', false, 'dumbbell-row'),
      te('plan-guided-beg-dumbbell', 'rdl', 'Dumbbell RDL', 3, '10-12', '30', false, 'dumbbell-romanian-deadlift'),
      te('plan-guided-beg-dumbbell', 'raise', 'Lateral Raise', 3, '15', '15', false, 'lateral-raise'),
      te('plan-guided-beg-dumbbell', 'curl', 'Hammer Curl', 2, '10-12', '20', false, 'hammer-curl'),
    ],
  },
]

export const BEGINNER_UPPER_LOWER_FOLDER: TemplateFolder = {
  id: BEGINNER_UPPER_LOWER_FOLDER_ID,
  name: 'Beginner Upper Lower (4d)',
  purpose: 'Four-day upper/lower split for beginners building a strength base.',
}
