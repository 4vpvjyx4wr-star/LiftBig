import type { TemplateExercise, WorkoutTemplate } from '@/types/workout'
import { CATALOG_WEEKLY_FOLDERS, catalogFolderId } from './catalogFolders'
import { EXPANSION_CATALOG_PLANS, EXPANSION_CATALOG_SCHEDULE_IDS } from './catalogExpansion'
import { dayTemplate, te } from './planHelpers'

const FB = catalogFolderId('beginner-full-body-3d')
const BUSY = catalogFolderId('busy-beginner')
const WL = catalogFolderId('beginner-weight-loss')
const PF = catalogFolderId('planet-fitness-starter')
const DB = catalogFolderId('dumbbell-starter')
const LEAN = catalogFolderId('lean-muscle-builder')
const PRO = catalogFolderId('busy-professional')
const MACHINE = catalogFolderId('machine-hypertrophy')
const CUT = catalogFolderId('summer-cut')
const HYBRID = catalogFolderId('strength-hybrid')
const HFFB = catalogFolderId('high-freq-full-body')

function day(
  id: string,
  name: string,
  folderId: string,
  exercises: TemplateExercise[],
  notes?: string,
): WorkoutTemplate {
  return dayTemplate(id, name, folderId, exercises, notes)
}

const REPEAT_VARIANT_PLANS: WorkoutTemplate[] = [
  day('plan-catalog-beg-fb-a', 'Full Body A', FB, [
    te('plan-catalog-beg-fb-a', 'squat', 'Goblet Squat', 3, '10-12', '35', false, 'goblet-squat'),
    te('plan-catalog-beg-fb-a', 'bench', 'Barbell Bench Press', 3, '8-10', '95', false, 'bench-press'),
    te('plan-catalog-beg-fb-a', 'row', 'Seated Cable Row', 3, '10-12', '80', false, 'seated-cable-row'),
    te('plan-catalog-beg-fb-a', 'rdl', 'Romanian Deadlift', 3, '10-12', '95', false, 'romanian-deadlift'),
    te('plan-catalog-beg-fb-a', 'ohp', 'Dumbbell Shoulder Press', 3, '10-12', '25', false, 'dumbbell-shoulder-press'),
    te('plan-catalog-beg-fb-a', 'plank', 'Plank', 3, '30-45 sec', '0', false, 'plank'),
  ]),
  day('plan-catalog-beg-fb-b', 'Full Body B', FB, [
    te('plan-catalog-beg-fb-b', 'squat', 'Barbell Back Squat', 3, '8-10', '95', false, 'squat'),
    te('plan-catalog-beg-fb-b', 'incline', 'Incline Dumbbell Press', 3, '10-12', '35', false, 'incline-dumbbell-press'),
    te('plan-catalog-beg-fb-b', 'pulldown', 'Lat Pulldown', 3, '10-12', '90', false, 'lat-pulldown'),
    te('plan-catalog-beg-fb-b', 'lunge', 'Walking Lunge', 3, '10/side', '25', false, 'walking-lunge'),
    te('plan-catalog-beg-fb-b', 'raise', 'Lateral Raise', 3, '12-15', '15', false, 'lateral-raise'),
    te('plan-catalog-beg-fb-b', 'curl', 'Dumbbell Curl', 2, '10-12', '20', false, 'dumbbell-curl'),
  ]),
  day('plan-catalog-beg-fb-c', 'Full Body C', FB, [
    te('plan-catalog-beg-fb-c', 'deadlift', 'Trap Bar Deadlift', 3, '6-8', '135', false, 'trap-bar-deadlift'),
    te('plan-catalog-beg-fb-c', 'press', 'Machine Chest Press', 3, '10-12', '90', false, 'machine-chest-press'),
    te('plan-catalog-beg-fb-c', 'row', 'Chest Supported Row', 3, '10-12', '35', false, 'chest-supported-row'),
    te('plan-catalog-beg-fb-c', 'leg-press', 'Leg Press', 3, '12-15', '180', false, 'leg-press'),
    te('plan-catalog-beg-fb-c', 'tri', 'Tricep Pushdown', 2, '10-12', '50', false, 'tricep-pushdown'),
    te('plan-catalog-beg-fb-c', 'core', 'Cable Crunch', 3, '12-15', '60', false, 'cable-crunch'),
  ]),
  day('plan-catalog-busy-a', 'Quick Circuit A', BUSY, [
    te('plan-catalog-busy-a', 'goblet', 'Goblet Squat', 2, '12', '30', false, 'goblet-squat'),
    te('plan-catalog-busy-a', 'push', 'Push-Up', 2, 'AMRAP', '0', false, 'push-up'),
    te('plan-catalog-busy-a', 'row', 'Dumbbell Row', 2, '10/side', '25', false, 'dumbbell-row'),
    te('plan-catalog-busy-a', 'rdl', 'Dumbbell RDL', 2, '10', '25', false, 'dumbbell-romanian-deadlift'),
    te('plan-catalog-busy-a', 'raise', 'Lateral Raise', 2, '15', '15', false, 'lateral-raise'),
    te('plan-catalog-busy-a', 'plank', 'Plank', 2, '30 sec', '0', false, 'plank'),
  ]),
  day('plan-catalog-busy-b', 'Quick Circuit B', BUSY, [
    te('plan-catalog-busy-b', 'squat', 'Bodyweight Squat', 3, '15', '0', true, 'bodyweight-squat'),
    te('plan-catalog-busy-b', 'press', 'Dumbbell Shoulder Press', 2, '10', '25', false, 'dumbbell-shoulder-press'),
    te('plan-catalog-busy-b', 'pulldown', 'Lat Pulldown', 2, '12', '70', false, 'lat-pulldown'),
    te('plan-catalog-busy-b', 'lunge', 'Walking Lunge', 2, '10/side', '0', true, 'walking-lunge'),
    te('plan-catalog-busy-b', 'curl', 'Hammer Curl', 2, '12', '20', false, 'hammer-curl'),
    te('plan-catalog-busy-b', 'bike', 'Stationary Bike', 1, '8 min', '0', false, 'stationary-bike'),
  ]),
  day('plan-catalog-busy-c', 'Quick Circuit C', BUSY, [
    te('plan-catalog-busy-c', 'leg-press', 'Leg Press', 2, '15', '180', false, 'leg-press'),
    te('plan-catalog-busy-c', 'bench', 'Machine Chest Press', 2, '12', '80', false, 'machine-chest-press'),
    te('plan-catalog-busy-c', 'row', 'Seated Cable Row', 2, '12', '70', false, 'seated-cable-row'),
    te('plan-catalog-busy-c', 'bridge', 'Glute Bridge', 2, '15', '0', false, 'glute-bridge'),
    te('plan-catalog-busy-c', 'tri', 'Tricep Pushdown', 2, '12', '40', false, 'tricep-pushdown'),
    te('plan-catalog-busy-c', 'plank', 'Side Plank', 2, '30 sec/side', '0', false, 'side-plank'),
  ]),
  {
    id: 'plan-catalog-wl-a',
    name: 'Fat Burn Circuit A',
    folderId: WL,
    isCircuit: true,
    exercises: [
      te('plan-catalog-wl-a', 'squat', 'Bodyweight Squat', 3, '15', '0', true, 'bodyweight-squat'),
      te('plan-catalog-wl-a', 'push', 'Push-Up', 3, '10-15', '0', true, 'push-up'),
      te('plan-catalog-wl-a', 'row', 'Inverted Row', 3, '8-12', '0', true, 'inverted-row'),
      te('plan-catalog-wl-a', 'lunge', 'Walking Lunge', 3, '10/side', '0', true, 'walking-lunge'),
      te('plan-catalog-wl-a', 'burpee', 'Burpee', 3, '8', '0', true, 'burpee'),
      te('plan-catalog-wl-a', 'bike', 'Stationary Bike', 1, '10 min', '0', false, 'stationary-bike'),
    ],
  },
  {
    id: 'plan-catalog-wl-b',
    name: 'Fat Burn Circuit B',
    folderId: WL,
    isCircuit: true,
    exercises: [
      te('plan-catalog-wl-b', 'goblet', 'Goblet Squat', 3, '15', '35', true, 'goblet-squat'),
      te('plan-catalog-wl-b', 'press', 'Dumbbell Shoulder Press', 3, '12', '25', true, 'dumbbell-shoulder-press'),
      te('plan-catalog-wl-b', 'row', 'Dumbbell Row', 3, '10/side', '25', true, 'dumbbell-row'),
      te('plan-catalog-wl-b', 'rdl', 'Dumbbell RDL', 3, '12', '25', true, 'dumbbell-romanian-deadlift'),
      te('plan-catalog-wl-b', 'mountain', 'Mountain Climber', 3, '30 sec', '0', true, 'mountain-climber'),
      te('plan-catalog-wl-b', 'walk', 'Incline Treadmill Walk', 1, '12 min', '0', false, 'incline-treadmill-walk'),
    ],
  },
  {
    id: 'plan-catalog-wl-c',
    name: 'Fat Burn Circuit C',
    folderId: WL,
    isCircuit: true,
    exercises: [
      te('plan-catalog-wl-c', 'kb-swing', 'Kettlebell Swing', 3, '15', '24', true, 'kettlebell-swing'),
      te('plan-catalog-wl-c', 'step-up', 'Step-Up', 3, '10/side', '0', true, 'step-up'),
      te('plan-catalog-wl-c', 'pulldown', 'Lat Pulldown', 3, '12', '70', true, 'lat-pulldown'),
      te('plan-catalog-wl-c', 'push', 'Incline Push-Up', 3, '12-15', '0', true, 'push-up'),
      te('plan-catalog-wl-c', 'plank', 'Plank', 3, '45 sec', '0', true, 'plank'),
      te('plan-catalog-wl-c', 'stair', 'Stair Climber', 1, '10 min', '0', false, 'stair-climber'),
    ],
  },
  day('plan-catalog-pf-a', 'PF Full Body A', PF, [
    te('plan-catalog-pf-a', 'squat', 'Barbell Back Squat', 3, '8-10', '95', false, 'squat'),
    te('plan-catalog-pf-a', 'bench', 'Barbell Bench Press', 3, '8-10', '95', false, 'bench-press'),
    te('plan-catalog-pf-a', 'row', 'Seated Cable Row', 3, '10-12', '80', false, 'seated-cable-row'),
    te('plan-catalog-pf-a', 'rdl', 'Romanian Deadlift', 3, '10-12', '95', false, 'romanian-deadlift'),
    te('plan-catalog-pf-a', 'ohp', 'Dumbbell Shoulder Press', 3, '10-12', '25', false, 'dumbbell-shoulder-press'),
    te('plan-catalog-pf-a', 'lat', 'Lat Pulldown', 2, '10-12', '90', false, 'lat-pulldown'),
  ], 'Full-body session using barbells, dumbbells, and cables at Planet Fitness.'),
  day('plan-catalog-pf-b', 'PF Full Body B', PF, [
    te('plan-catalog-pf-b', 'leg-press', 'Leg Press', 3, '12-15', '270', false, 'leg-press'),
    te('plan-catalog-pf-b', 'incline', 'Incline Dumbbell Press', 3, '10-12', '40', false, 'incline-dumbbell-press'),
    te('plan-catalog-pf-b', 'pulldown', 'Lat Pulldown', 3, '10-12', '90', false, 'lat-pulldown'),
    te('plan-catalog-pf-b', 'curl', 'Leg Curl', 3, '12-15', '70', false, 'hamstring-curl'),
    te('plan-catalog-pf-b', 'lateral', 'Cable Lateral Raise', 3, '12-15', '15', false, 'lateral-raise'),
    te('plan-catalog-pf-b', 'tri', 'Tricep Pushdown', 2, '10-12', '50', false, 'tricep-pushdown'),
  ]),
  day('plan-catalog-pf-c', 'PF Full Body C', PF, [
    te('plan-catalog-pf-c', 'deadlift', 'Trap Bar Deadlift', 3, '6-8', '135', false, 'trap-bar-deadlift'),
    te('plan-catalog-pf-c', 'machine-press', 'Machine Chest Press', 3, '10-12', '100', false, 'machine-chest-press'),
    te('plan-catalog-pf-c', 'face', 'Face Pull', 3, '15-20', '50', false, 'face-pull'),
    te('plan-catalog-pf-c', 'lunge', 'Walking Lunge', 3, '10/side', '25', false, 'walking-lunge'),
    te('plan-catalog-pf-c', 'curl', 'Dumbbell Curl', 2, '10-12', '20', false, 'dumbbell-curl'),
    te('plan-catalog-pf-c', 'calf', 'Calf Raise', 3, '15-20', '135', false, 'calf-raise'),
  ]),
  day('plan-catalog-db-a', 'DB Full Body A', DB, [
    te('plan-catalog-db-a', 'goblet', 'Goblet Squat', 3, '12', '35', false, 'goblet-squat'),
    te('plan-catalog-db-a', 'press', 'Flat DB Press', 3, '10-12', '40', false, 'flat-dumbbell-press'),
    te('plan-catalog-db-a', 'row', 'Dumbbell Row', 3, '10/side', '30', false, 'dumbbell-row'),
    te('plan-catalog-db-a', 'rdl', 'Dumbbell RDL', 3, '10-12', '30', false, 'dumbbell-romanian-deadlift'),
    te('plan-catalog-db-a', 'raise', 'Lateral Raise', 3, '15', '15', false, 'lateral-raise'),
    te('plan-catalog-db-a', 'curl', 'Hammer Curl', 2, '10-12', '20', false, 'hammer-curl'),
  ]),
  day('plan-catalog-db-b', 'DB Full Body B', DB, [
    te('plan-catalog-db-b', 'split', 'Bulgarian Split Squat', 3, '10/side', '25', false, 'bulgarian-split-squat'),
    te('plan-catalog-db-b', 'incline', 'Incline Dumbbell Press', 3, '10-12', '35', false, 'incline-dumbbell-press'),
    te('plan-catalog-db-b', 'pullover', 'Dumbbell Pullover', 3, '12', '30', false, 'dumbbell-pullover'),
    te('plan-catalog-db-b', 'hip', 'Dumbbell Hip Thrust', 3, '12', '50', false, 'hip-thrust'),
    te('plan-catalog-db-b', 'ohp', 'Dumbbell Shoulder Press', 3, '10-12', '25', false, 'dumbbell-shoulder-press'),
    te('plan-catalog-db-b', 'tri', 'Overhead DB Tricep Extension', 2, '10-12', '25', false, 'overhead-dumbbell-tricep-extension'),
  ]),
  day('plan-catalog-db-c', 'DB Full Body C', DB, [
    te('plan-catalog-db-c', 'lunge', 'Walking Lunge', 3, '10/side', '25', false, 'walking-lunge'),
    te('plan-catalog-db-c', 'floor-press', 'Dumbbell Floor Press', 3, '10-12', '40', false, 'flat-dumbbell-press'),
    te('plan-catalog-db-c', 'row', 'Chest Supported Row', 3, '10-12', '30', false, 'chest-supported-row'),
    te('plan-catalog-db-c', 'bridge', 'Glute Bridge', 3, '15', '0', false, 'glute-bridge'),
    te('plan-catalog-db-c', 'rear', 'Rear Delt Fly', 3, '15', '15', false, 'rear-delt-fly'),
    te('plan-catalog-db-c', 'core', 'Plank', 3, '45 sec', '0', false, 'plank'),
  ]),
  day('plan-catalog-lean-a', 'Recomp Full Body A', LEAN, [
    te('plan-catalog-lean-a', 'squat', 'Goblet Squat', 3, '12-15', '45', false, 'goblet-squat'),
    te('plan-catalog-lean-a', 'bench', 'Dumbbell Bench Press', 3, '10-12', '45', false, 'flat-dumbbell-press'),
    te('plan-catalog-lean-a', 'row', 'Cable Row', 3, '10-12', '90', false, 'seated-cable-row'),
    te('plan-catalog-lean-a', 'rdl', 'Romanian Deadlift', 3, '10-12', '135', false, 'romanian-deadlift'),
    te('plan-catalog-lean-a', 'cardio', 'Incline Walk', 1, '15 min', '0', false, 'treadmill-walk'),
    te('plan-catalog-lean-a', 'core', 'Plank', 2, '45 sec', '0', false, 'plank'),
  ], 'Recomposition-focused full body with moderate volume and cardio finishers.'),
  day('plan-catalog-lean-b', 'Recomp Full Body B', LEAN, [
    te('plan-catalog-lean-b', 'leg-press', 'Leg Press', 3, '12-15', '270', false, 'leg-press'),
    te('plan-catalog-lean-b', 'incline', 'Incline Dumbbell Press', 3, '10-12', '45', false, 'incline-dumbbell-press'),
    te('plan-catalog-lean-b', 'pulldown', 'Lat Pulldown', 3, '10-12', '90', false, 'lat-pulldown'),
    te('plan-catalog-lean-b', 'lunge', 'Walking Lunge', 3, '10/side', '30', false, 'walking-lunge'),
    te('plan-catalog-lean-b', 'raise', 'Lateral Raise', 3, '15', '20', false, 'lateral-raise'),
    te('plan-catalog-lean-b', 'bike', 'Stationary Bike', 1, '12 min', '0', false, 'stationary-bike'),
  ]),
  day('plan-catalog-lean-c', 'Recomp Full Body C', LEAN, [
    te('plan-catalog-lean-c', 'deadlift', 'Trap Bar Deadlift', 3, '8-10', '185', false, 'trap-bar-deadlift'),
    te('plan-catalog-lean-c', 'ohp', 'Dumbbell Shoulder Press', 3, '10-12', '30', false, 'dumbbell-shoulder-press'),
    te('plan-catalog-lean-c', 'row', 'Chest Supported Row', 3, '10-12', '40', false, 'chest-supported-row'),
    te('plan-catalog-lean-c', 'curl', 'Leg Curl', 3, '12-15', '80', false, 'hamstring-curl'),
    te('plan-catalog-lean-c', 'tri', 'Tricep Pushdown', 2, '12-15', '50', false, 'tricep-pushdown'),
    te('plan-catalog-lean-c', 'core', 'Cable Crunch', 3, '12-15', '60', false, 'cable-crunch'),
  ]),
  day('plan-catalog-pro-a', 'Efficient Session A', PRO, [
    te('plan-catalog-pro-a', 'squat', 'Leg Press', 3, '12', '270', false, 'leg-press'),
    te('plan-catalog-pro-a', 'press', 'Machine Chest Press', 3, '10-12', '100', false, 'machine-chest-press'),
    te('plan-catalog-pro-a', 'pulldown', 'Lat Pulldown', 3, '10-12', '90', false, 'lat-pulldown'),
    te('plan-catalog-pro-a', 'shoulder', 'Dumbbell Shoulder Press', 2, '10-12', '30', false, 'dumbbell-shoulder-press'),
    te('plan-catalog-pro-a', 'curl', 'Cable Curl', 2, '12', '30', false, 'cable-curl'),
  ], 'Efficient ~40-minute sessions for busy schedules.'),
  day('plan-catalog-pro-b', 'Efficient Session B', PRO, [
    te('plan-catalog-pro-b', 'hack', 'Hack Squat', 3, '10-12', '180', false, 'hack-squat'),
    te('plan-catalog-pro-b', 'row', 'Chest Supported Row', 3, '10-12', '90', false, 'chest-supported-row'),
    te('plan-catalog-pro-b', 'incline', 'Incline Machine Press', 3, '10-12', '90', false, 'incline-machine-press'),
    te('plan-catalog-pro-b', 'curl', 'Leg Curl', 2, '12-15', '80', false, 'hamstring-curl'),
    te('plan-catalog-pro-b', 'tri', 'Tricep Pushdown', 2, '12', '50', false, 'tricep-pushdown'),
  ]),
  day('plan-catalog-pro-c', 'Efficient Session C', PRO, [
    te('plan-catalog-pro-c', 'rdl', 'Romanian Deadlift', 3, '10-12', '135', false, 'romanian-deadlift'),
    te('plan-catalog-pro-c', 'fly', 'Cable Fly', 3, '12-15', '30', false, 'cable-fly'),
    te('plan-catalog-pro-c', 'pulldown', 'Single Arm Lat Pulldown', 3, '10/side', '60', false, 'single-arm-lat-pulldown'),
    te('plan-catalog-pro-c', 'lateral', 'Lateral Raise', 2, '15', '20', false, 'lateral-raise'),
    te('plan-catalog-pro-c', 'calf', 'Calf Raise', 3, '15', '135', false, 'calf-raise'),
  ]),
  day('plan-catalog-machine-a', 'Machine Upper A', MACHINE, [
    te('plan-catalog-machine-a', 'chest', 'Machine Chest Press', 4, '10-12', '110', false, 'machine-chest-press'),
    te('plan-catalog-machine-a', 'row', 'Chest Supported Row', 4, '10-12', '100', false, 'chest-supported-row'),
    te('plan-catalog-machine-a', 'shoulder', 'Machine Shoulder Press', 3, '10-12', '70', false, 'machine-shoulder-press'),
    te('plan-catalog-machine-a', 'lateral', 'Lateral Raise', 3, '15-20', '20', false, 'lateral-raise'),
    te('plan-catalog-machine-a', 'curl', 'Cable Curl', 3, '10-12', '35', false, 'cable-curl'),
    te('plan-catalog-machine-a', 'tri', 'Tricep Pushdown', 3, '10-12', '60', false, 'tricep-pushdown'),
  ], 'Machine-heavy hypertrophy for joint-friendly volume.'),
  day('plan-catalog-machine-b', 'Machine Lower A', MACHINE, [
    te('plan-catalog-machine-b', 'leg-press', 'Leg Press', 4, '12-15', '360', false, 'leg-press'),
    te('plan-catalog-machine-b', 'leg-curl', 'Leg Curl', 4, '12-15', '100', false, 'hamstring-curl'),
    te('plan-catalog-machine-b', 'leg-ext', 'Leg Extension', 3, '12-15', '90', false, 'leg-extension'),
    te('plan-catalog-machine-b', 'hip', 'Hip Abduction', 3, '15-20', '90', false, 'hip-abduction'),
    te('plan-catalog-machine-b', 'calf', 'Standing Calf Raise', 4, '15-20', '140', false, 'standing-calf-raise'),
  ]),
  day('plan-catalog-machine-c', 'Machine Upper B', MACHINE, [
    te('plan-catalog-machine-c', 'incline', 'Incline Machine Press', 4, '10-12', '90', false, 'incline-machine-press'),
    te('plan-catalog-machine-c', 'pulldown', 'Lat Pulldown', 4, '10-12', '100', false, 'lat-pulldown'),
    te('plan-catalog-machine-c', 'rear', 'Rear Delt Fly', 3, '15-20', '25', false, 'rear-delt-fly'),
    te('plan-catalog-machine-c', 'hammer', 'Hammer Curl', 3, '10-12', '25', false, 'hammer-curl'),
    te('plan-catalog-machine-c', 'oh-tri', 'Overhead Cable Tricep Extension', 3, '10-12', '50', false, 'overhead-cable-tricep-extension'),
  ]),
  day('plan-catalog-machine-d', 'Machine Lower B', MACHINE, [
    te('plan-catalog-machine-d', 'hack', 'Hack Squat', 4, '10-12', '180', false, 'hack-squat'),
    te('plan-catalog-machine-d', 'rdl', 'Romanian Deadlift', 3, '10-12', '135', false, 'romanian-deadlift'),
    te('plan-catalog-machine-d', 'split', 'Bulgarian Split Squat', 3, '10/side', '30', false, 'bulgarian-split-squat'),
    te('plan-catalog-machine-d', 'curl', 'Leg Curl', 3, '12-15', '90', false, 'hamstring-curl'),
    te('plan-catalog-machine-d', 'core', 'Cable Crunch', 3, '12-15', '70', false, 'cable-crunch'),
  ]),
  {
    id: 'plan-catalog-cut-a',
    name: 'Cut Circuit A',
    folderId: CUT,
    isCircuit: true,
    exercises: [
      te('plan-catalog-cut-a', 'circuit-squat', 'Goblet Squat', 3, '15', '45', true, 'goblet-squat'),
      te('plan-catalog-cut-a', 'circuit-push', 'Incline Push-Ups', 3, '12-15', '0', true, 'push-up'),
      te('plan-catalog-cut-a', 'circuit-row', 'Cable Row', 3, '12-15', '80', true, 'seated-cable-row'),
      te('plan-catalog-cut-a', 'circuit-lunge', 'Walking Lunges', 3, '12/leg', '25', true, 'walking-lunge'),
      te('plan-catalog-cut-a', 'cardio', 'Stair Climber', 1, '20 min', '0', false, 'stair-climber'),
      te('plan-catalog-cut-a', 'core', 'Hanging Leg Raise', 3, '12-15', '0', false, 'hanging-leg-raise'),
    ],
    notes: 'Superset-friendly cut phase. Keep rest short and protein high.',
  },
  {
    id: 'plan-catalog-cut-b',
    name: 'Cut Circuit B',
    folderId: CUT,
    isCircuit: true,
    exercises: [
      te('plan-catalog-cut-b', 'kb', 'Kettlebell Swing', 3, '15', '24', true, 'kettlebell-swing'),
      te('plan-catalog-cut-b', 'press', 'Dumbbell Shoulder Press', 3, '12', '30', true, 'dumbbell-shoulder-press'),
      te('plan-catalog-cut-b', 'row', 'Dumbbell Row', 3, '10/side', '30', true, 'dumbbell-row'),
      te('plan-catalog-cut-b', 'burpee', 'Burpee', 3, '10', '0', true, 'burpee'),
      te('plan-catalog-cut-b', 'bike', 'Stationary Bike', 1, '15 min', '0', false, 'stationary-bike'),
      te('plan-catalog-cut-b', 'plank', 'Plank', 3, '45 sec', '0', false, 'plank'),
    ],
  },
  {
    id: 'plan-catalog-cut-c',
    name: 'Cut Circuit C',
    folderId: CUT,
    isCircuit: true,
    exercises: [
      te('plan-catalog-cut-c', 'leg-press', 'Leg Press', 3, '15', '270', true, 'leg-press'),
      te('plan-catalog-cut-c', 'fly', 'Cable Fly', 3, '12-15', '30', true, 'cable-fly'),
      te('plan-catalog-cut-c', 'pulldown', 'Lat Pulldown', 3, '12', '80', true, 'lat-pulldown'),
      te('plan-catalog-cut-c', 'curl', 'Hammer Curl', 3, '12', '25', true, 'hammer-curl'),
      te('plan-catalog-cut-c', 'walk', 'Incline Treadmill Walk', 1, '18 min', '0', false, 'incline-treadmill-walk'),
      te('plan-catalog-cut-c', 'core', 'Cable Woodchop', 3, '12/side', '35', false, 'cable-woodchop'),
    ],
  },
  day('plan-catalog-hybrid-a', 'Strength Full Body A', HYBRID, [
    te('plan-catalog-hybrid-a', 'squat', 'Barbell Back Squat', 5, '5', '225', false, 'squat'),
    te('plan-catalog-hybrid-a', 'bench', 'Barbell Bench Press', 5, '5', '185', false, 'bench-press'),
    te('plan-catalog-hybrid-a', 'row', 'Barbell Row', 4, '8', '135', false, 'barbell-row'),
    te('plan-catalog-hybrid-a', 'rdl', 'Romanian Deadlift', 3, '8-10', '185', false, 'romanian-deadlift'),
    te('plan-catalog-hybrid-a', 'ohp', 'Overhead Press', 3, '8-10', '95', false, 'overhead-press'),
    te('plan-catalog-hybrid-a', 'core', 'Pallof Press', 3, '12', '40', false, 'pallof-press'),
  ], 'Strength-first full body with compound focus.'),
  day('plan-catalog-hybrid-b', 'Strength Full Body B', HYBRID, [
    te('plan-catalog-hybrid-b', 'deadlift', 'Conventional Deadlift', 5, '3-5', '315', false, 'deadlift'),
    te('plan-catalog-hybrid-b', 'incline', 'Incline Barbell Bench', 4, '6-8', '155', false, 'incline-bench-press'),
    te('plan-catalog-hybrid-b', 'pull-up', 'Pull-Ups', 4, '6-10', '0', false, 'pull-up'),
    te('plan-catalog-hybrid-b', 'front-squat', 'Front Squat', 3, '6-8', '155', false, 'front-squat'),
    te('plan-catalog-hybrid-b', 'face', 'Face Pull', 3, '15-20', '50', false, 'face-pull'),
    te('plan-catalog-hybrid-b', 'core', 'Hanging Leg Raise', 3, '10-12', '0', false, 'hanging-leg-raise'),
  ]),
  day('plan-catalog-hybrid-c', 'Strength Full Body C', HYBRID, [
    te('plan-catalog-hybrid-c', 'squat', 'Pause Back Squat', 5, '4', '205', false, 'squat'),
    te('plan-catalog-hybrid-c', 'close-grip', 'Close-Grip Bench Press', 4, '6-8', '155', false, 'close-grip-bench-press'),
    te('plan-catalog-hybrid-c', 'pendlay', 'Pendlay Row', 4, '6-8', '135', false, 'pendlay-row'),
    te('plan-catalog-hybrid-c', 'rdl', 'Romanian Deadlift', 3, '8', '205', false, 'romanian-deadlift'),
    te('plan-catalog-hybrid-c', 'ohp', 'Push Press', 3, '5', '115', false, 'overhead-press'),
    te('plan-catalog-hybrid-c', 'core', 'Ab Wheel Rollout', 3, '8-10', '0', false, 'ab-wheel-rollout'),
  ]),
  day('plan-catalog-hybrid-d', 'Strength Full Body D', HYBRID, [
    te('plan-catalog-hybrid-d', 'trap', 'Trap Bar Deadlift', 5, '5', '275', false, 'trap-bar-deadlift'),
    te('plan-catalog-hybrid-d', 'bench', 'Paused Bench Press', 5, '4', '175', false, 'bench-press'),
    te('plan-catalog-hybrid-d', 'row', 'Chest Supported Row', 4, '8-10', '100', false, 'chest-supported-row'),
    te('plan-catalog-hybrid-d', 'lunge', 'Walking Lunge', 3, '8/side', '50', false, 'walking-lunge'),
    te('plan-catalog-hybrid-d', 'curl', 'Barbell Curl', 3, '8-10', '65', false, 'barbell-curl'),
    te('plan-catalog-hybrid-d', 'core', 'Plank', 3, '60 sec', '0', false, 'plank'),
  ]),
  day('plan-catalog-hffb-a', 'HFFB Day A', HFFB, [
    te('plan-catalog-hffb-a', 'squat', 'Barbell Back Squat', 4, '5', '245', false, 'squat'),
    te('plan-catalog-hffb-a', 'bench', 'Barbell Bench Press', 4, '5', '195', false, 'bench-press'),
    te('plan-catalog-hffb-a', 'row', 'Barbell Row', 3, '8', '155', false, 'barbell-row'),
    te('plan-catalog-hffb-a', 'rdl', 'Romanian Deadlift', 3, '8', '205', false, 'romanian-deadlift'),
    te('plan-catalog-hffb-a', 'ohp', 'Overhead Press', 3, '8', '115', false, 'overhead-press'),
    te('plan-catalog-hffb-a', 'curl', 'Barbell Curl', 3, '10-12', '75', false, 'barbell-curl'),
  ], 'Full body repeated 5–6× per week with submaximal loads.'),
  day('plan-catalog-hffb-b', 'HFFB Day B', HFFB, [
    te('plan-catalog-hffb-b', 'front-squat', 'Front Squat', 4, '5', '185', false, 'front-squat'),
    te('plan-catalog-hffb-b', 'incline', 'Incline Barbell Bench', 4, '6', '155', false, 'incline-bench-press'),
    te('plan-catalog-hffb-b', 'pull-up', 'Pull-Ups', 3, '8-10', '0', false, 'pull-up'),
    te('plan-catalog-hffb-b', 'hip', 'Hip Thrust', 3, '8', '185', false, 'hip-thrust'),
    te('plan-catalog-hffb-b', 'lateral', 'Lateral Raise', 3, '15', '25', false, 'lateral-raise'),
    te('plan-catalog-hffb-b', 'tri', 'Tricep Pushdown', 3, '12', '60', false, 'tricep-pushdown'),
  ]),
  day('plan-catalog-hffb-c', 'HFFB Day C', HFFB, [
    te('plan-catalog-hffb-c', 'squat', 'Pause Back Squat', 4, '4', '225', false, 'squat'),
    te('plan-catalog-hffb-c', 'bench', 'Close-Grip Bench Press', 4, '5', '175', false, 'close-grip-bench-press'),
    te('plan-catalog-hffb-c', 'pendlay', 'Pendlay Row', 3, '6', '145', false, 'pendlay-row'),
    te('plan-catalog-hffb-c', 'rdl', 'Romanian Deadlift', 3, '8', '195', false, 'romanian-deadlift'),
    te('plan-catalog-hffb-c', 'face', 'Face Pull', 3, '15', '50', false, 'face-pull'),
    te('plan-catalog-hffb-c', 'hammer', 'Hammer Curl', 3, '10', '30', false, 'hammer-curl'),
  ]),
  day('plan-catalog-hffb-d', 'HFFB Day D', HFFB, [
    te('plan-catalog-hffb-d', 'deadlift', 'Conventional Deadlift', 4, '3', '365', false, 'deadlift'),
    te('plan-catalog-hffb-d', 'ohp', 'Overhead Press', 4, '5', '125', false, 'overhead-press'),
    te('plan-catalog-hffb-d', 'row', 'Chest Supported Row', 3, '10', '100', false, 'chest-supported-row'),
    te('plan-catalog-hffb-d', 'lunge', 'Walking Lunge', 3, '8/side', '50', false, 'walking-lunge'),
    te('plan-catalog-hffb-d', 'curl', 'Incline Dumbbell Curl', 3, '10', '30', false, 'incline-dumbbell-curl'),
    te('plan-catalog-hffb-d', 'core', 'Cable Crunch', 3, '12', '70', false, 'cable-crunch'),
  ]),
  day('plan-catalog-hffb-e', 'HFFB Day E', HFFB, [
    te('plan-catalog-hffb-e', 'leg-press', 'Leg Press', 4, '10', '450', false, 'leg-press'),
    te('plan-catalog-hffb-e', 'incline-db', 'Incline Dumbbell Press', 4, '8', '55', false, 'incline-dumbbell-press'),
    te('plan-catalog-hffb-e', 'pulldown', 'Lat Pulldown', 3, '10', '110', false, 'lat-pulldown'),
    te('plan-catalog-hffb-e', 'rdl', 'Dumbbell RDL', 3, '10', '50', false, 'dumbbell-romanian-deadlift'),
    te('plan-catalog-hffb-e', 'raise', 'Lateral Raise', 3, '15', '25', false, 'lateral-raise'),
    te('plan-catalog-hffb-e', 'pushdown', 'Rope Pushdown', 3, '12', '70', false, 'tricep-pushdown'),
  ]),
]

export const ALL_WEEKLY_FOLDERS = CATALOG_WEEKLY_FOLDERS

export const ALL_WEEKLY_PLANS: WorkoutTemplate[] = [
  ...REPEAT_VARIANT_PLANS,
  ...EXPANSION_CATALOG_PLANS,
]

export const CATALOG_WEEKLY_PLAN_IDS = new Set(ALL_WEEKLY_PLANS.map((p) => p.id))

export const CATALOG_SCHEDULE_IDS: Record<string, string[]> = {
  'catalog-beginner-full-body-3d': ['plan-catalog-beg-fb-a', 'plan-catalog-beg-fb-b', 'plan-catalog-beg-fb-c'],
  'catalog-beginner-upper-lower-4d': [
    'plan-guided-beg-upper-a',
    'plan-guided-beg-lower-a',
    'plan-guided-beg-upper-b',
    'plan-guided-beg-lower-b',
  ],
  'catalog-busy-beginner': ['plan-catalog-busy-a', 'plan-catalog-busy-b', 'plan-catalog-busy-c'],
  'catalog-beginner-weight-loss': ['plan-catalog-wl-a', 'plan-catalog-wl-b', 'plan-catalog-wl-c'],
  'catalog-planet-fitness-starter': ['plan-catalog-pf-a', 'plan-catalog-pf-b', 'plan-catalog-pf-c'],
  'catalog-dumbbell-starter': ['plan-catalog-db-a', 'plan-catalog-db-b', 'plan-catalog-db-c'],
  'catalog-intermediate-ul-hypertrophy': [
    'guided-int-ul-upper-a',
    'guided-int-ul-lower-a',
    'guided-int-ul-upper-b',
    'guided-int-ul-lower-b',
  ],
  'catalog-intermediate-ppl': [
    'guided-int-push',
    'guided-int-pull',
    'guided-int-legs',
    'guided-int-push',
    'guided-int-pull',
    'guided-int-legs',
  ],
  'catalog-powerbuilding-4d': [
    'guided-int-pb-upper',
    'guided-int-pb-lower',
    'guided-int-pb-push',
    'guided-int-pb-pull',
  ],
  'catalog-lean-muscle-builder': ['plan-catalog-lean-a', 'plan-catalog-lean-b', 'plan-catalog-lean-c'],
  'catalog-busy-professional': ['plan-catalog-pro-a', 'plan-catalog-pro-b', 'plan-catalog-pro-c'],
  'catalog-machine-hypertrophy': [
    'plan-catalog-machine-a',
    'plan-catalog-machine-b',
    'plan-catalog-machine-c',
    'plan-catalog-machine-d',
  ],
  'catalog-aesthetic-v-taper': ['guided-exp-vtaper-push', 'guided-exp-vtaper-pull', 'guided-exp-vtaper-legs'],
  'catalog-high-volume-ppl': [
    'guided-exp-hv-push',
    'guided-exp-hv-pull',
    'guided-exp-hv-legs',
    'guided-exp-hv-push',
    'guided-exp-hv-pull',
    'guided-exp-hv-legs',
  ],
  'catalog-upper-lower-arms': ['guided-exp-ula-upper', 'guided-exp-ula-lower', 'guided-exp-ula-arms'],
  'catalog-powerbuilding-advanced': [
    'guided-exp-pb-squat',
    'guided-exp-pb-bench',
    'guided-exp-pb-deadlift',
    'guided-exp-pb-accessory',
  ],
  'catalog-summer-cut': ['plan-catalog-cut-a', 'plan-catalog-cut-b', 'plan-catalog-cut-c'],
  'catalog-strength-hybrid': [
    'plan-catalog-hybrid-a',
    'plan-catalog-hybrid-b',
    'plan-catalog-hybrid-c',
    'plan-catalog-hybrid-d',
  ],
  'catalog-liftbig-extreme': [
    'guided-la-extreme-push',
    'guided-la-extreme-pull',
    'guided-la-extreme-legs',
    'guided-la-extreme-push',
    'guided-la-extreme-pull',
    'guided-la-extreme-legs',
  ],
  'catalog-arnold-ppl': [
    'guided-la-arnold-chest-back',
    'guided-la-arnold-shoulders-arms',
    'guided-la-arnold-legs',
  ],
  'catalog-double-split': [
    'guided-la-ds-am-upper',
    'guided-la-ds-pm-upper',
    'guided-la-ds-am-lower',
    'guided-la-ds-pm-lower',
  ],
  'catalog-mass-monster': [
    'guided-la-mass-chest',
    'guided-la-mass-back',
    'guided-la-mass-legs',
    'guided-la-mass-shoulders',
  ],
  'catalog-high-freq-full-body': [
    'plan-catalog-hffb-a',
    'plan-catalog-hffb-b',
    'plan-catalog-hffb-c',
    'plan-catalog-hffb-d',
    'plan-catalog-hffb-e',
  ],
  'catalog-advanced-aesthetics': [
    'guided-la-aesthetics-upper-a',
    'guided-la-aesthetics-lower',
    'guided-la-aesthetics-upper-b',
  ],
  'catalog-sbd-strength': [
    'plan-sbd-w1-d1',
    'plan-sbd-w1-d2',
    'plan-sbd-w1-d3',
    'plan-sbd-w1-d4',
    'plan-sbd-w1-d5',
    'plan-sbd-w1-d6',
    'plan-sbd-w1-d7',
  ],
  'catalog-calisthenics-full-body': [
    'plan-cali-w1-d1',
    'plan-cali-w1-d2',
    'plan-cali-w1-d3',
    'plan-cali-w1-d4',
    'plan-cali-w1-d5',
    'plan-cali-w1-d6',
    'plan-cali-w1-d7',
  ],
  'catalog-joey-summer-ppl': [
    'plan-joey-cut-w1-d1',
    'plan-joey-cut-w1-d2',
    'plan-joey-cut-w1-d3',
    'plan-joey-cut-w1-d4',
    'plan-joey-cut-w1-d5',
    'plan-joey-cut-w1-d6',
    'plan-joey-cut-w1-d7',
  ],
  'catalog-fallback-beginner': ['plan-catalog-beg-fb-a', 'plan-catalog-beg-fb-b', 'plan-catalog-beg-fb-c'],
  'catalog-fallback-intermediate': ['plan-catalog-lean-a', 'plan-catalog-lean-b', 'plan-catalog-lean-c'],
  'catalog-fallback-experienced': [
    'plan-catalog-hybrid-a',
    'plan-catalog-hybrid-b',
    'plan-catalog-hybrid-c',
    'plan-catalog-hybrid-d',
  ],
  'catalog-fallback-liftaholic': [
    'plan-catalog-hffb-a',
    'plan-catalog-hffb-b',
    'plan-catalog-hffb-c',
    'plan-catalog-hffb-d',
    'plan-catalog-hffb-e',
  ],
  ...EXPANSION_CATALOG_SCHEDULE_IDS,
}

export function catalogFolderForEntry(catalogId: string): string {
  const slug = catalogId.replace(/^catalog-/, '')
  if (slug === 'sbd-strength') return 'folder-sbd-strength'
  if (slug === 'calisthenics-full-body') return 'folder-calisthenics-full-body'
  if (slug === 'joey-summer-ppl') return 'folder-joey-summer-cut-split'
  if (slug.startsWith('fallback-')) {
    const map: Record<string, string> = {
      'fallback-beginner': catalogFolderId('beginner-full-body-3d'),
      'fallback-intermediate': catalogFolderId('lean-muscle-builder'),
      'fallback-experienced': catalogFolderId('strength-hybrid'),
      'fallback-liftaholic': catalogFolderId('high-freq-full-body'),
    }
    return map[slug] ?? catalogFolderId(slug)
  }
  return catalogFolderId(slug)
}
