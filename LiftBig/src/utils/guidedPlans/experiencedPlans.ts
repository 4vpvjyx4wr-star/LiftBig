import type { WorkoutTemplate } from '@/types/workout'
import { catalogFolderId } from './catalogFolders'
import { GUIDED_EXPERIENCED_FOLDER } from './guidedPlanFolders'
import { dayTemplate, repeatTemplate, te } from './planHelpers'

const F = GUIDED_EXPERIENCED_FOLDER.id
const F_VTAPER = catalogFolderId('aesthetic-v-taper')
const F_HVPPL = catalogFolderId('high-volume-ppl')
const F_ULA = catalogFolderId('upper-lower-arms')
const F_PB_ADV = catalogFolderId('powerbuilding-advanced')

export const AESTHETIC_VTAPER_FOLDER_ID = catalogFolderId('aesthetic-v-taper')
export const HIGH_VOLUME_PPL_FOLDER_ID = catalogFolderId('high-volume-ppl')
export const UPPER_LOWER_ARMS_FOLDER_ID = catalogFolderId('upper-lower-arms')
export const POWERBUILDING_ADVANCED_FOLDER_ID = catalogFolderId('powerbuilding-advanced')
export const SUMMER_CUT_ID = 'guided-summer-cut'
export const STRENGTH_HYBRID_ID = 'guided-strength-hybrid'

export const EXPERIENCED_GUIDED_PLANS: WorkoutTemplate[] = [
  dayTemplate(
    'guided-exp-vtaper-push',
    'V-Taper Push',
    F_VTAPER,
    [
      te('guided-exp-vtaper-push', 'oh-press', 'Overhead Press', 4, '6-8', '115', false, 'overhead-press'),
      te('guided-exp-vtaper-push', 'incline-db', 'Incline Dumbbell Press', 4, '8-10', '55', false, 'incline-dumbbell-press'),
      te('guided-exp-vtaper-push', 'lateral', 'Lateral Raise', 5, '12-20', '25', false, 'lateral-raise'),
      te('guided-exp-vtaper-push', 'rear-delt', 'Rear Delt Fly', 4, '15-20', '25', false, 'rear-delt-fly'),
      te('guided-exp-vtaper-push', 'tri', 'Overhead Tricep Extension', 3, '10-12', '50', false, 'overhead-tricep-extension'),
    ],
  ),
  dayTemplate(
    'guided-exp-vtaper-pull',
    'V-Taper Pull',
    F_VTAPER,
    [
      te('guided-exp-vtaper-pull', 'pull-up', 'Weighted Pull-Ups', 5, '6-10', '35', false, 'pull-up'),
      te('guided-exp-vtaper-pull', 'row', 'Barbell Row', 4, '8-10', '155', false, 'barbell-row'),
      te('guided-exp-vtaper-pull', 'lat-pulldown', 'Lat Pulldown', 3, '10-12', '120', false, 'lat-pulldown'),
      te('guided-exp-vtaper-pull', 'face-pull', 'Face Pull', 4, '15-20', '50', false, 'face-pull'),
      te('guided-exp-vtaper-pull', 'curl', 'Incline Dumbbell Curl', 3, '10-12', '30', false, 'incline-dumbbell-curl'),
    ],
  ),
  dayTemplate(
    'guided-exp-vtaper-legs',
    'V-Taper Legs',
    F_VTAPER,
    [
      te('guided-exp-vtaper-legs', 'squat', 'Barbell Back Squat', 4, '6-8', '245', false, 'squat'),
      te('guided-exp-vtaper-legs', 'rdl', 'Romanian Deadlift', 3, '8-10', '185', false, 'romanian-deadlift'),
      te('guided-exp-vtaper-legs', 'leg-press', 'Leg Press', 3, '12-15', '450', false, 'leg-press'),
      te('guided-exp-vtaper-legs', 'leg-curl', 'Leg Curl', 3, '12-15', '110', false, 'hamstring-curl'),
      te('guided-exp-vtaper-legs', 'calf', 'Standing Calf Raise', 4, '15-20', '160', false, 'standing-calf-raise'),
    ],
  ),
  dayTemplate(
    'guided-exp-hv-push',
    'High Volume Push',
    F_HVPPL,
    [
      te('guided-exp-hv-push', 'bench', 'Barbell Bench Press', 5, '8-10', '185', false, 'bench-press'),
      te('guided-exp-hv-push', 'oh-press', 'Overhead Press', 4, '8-10', '105', false, 'overhead-press'),
      te('guided-exp-hv-push', 'incline-db', 'Incline Dumbbell Press', 4, '10-12', '55', false, 'incline-dumbbell-press'),
      te('guided-exp-hv-push', 'lateral', 'Lateral Raise', 5, '15-20', '25', false, 'lateral-raise'),
      te('guided-exp-hv-push', 'fly', 'Cable Fly', 3, '12-15', '35', false, 'cable-fly'),
      te('guided-exp-hv-push', 'tri', 'Rope Pushdown', 4, '10-12', '70', false, 'tricep-pushdown'),
    ],
  ),
  dayTemplate(
    'guided-exp-hv-pull',
    'High Volume Pull',
    F_HVPPL,
    [
      te('guided-exp-hv-pull', 'deadlift', 'Conventional Deadlift', 4, '5-6', '335', false, 'deadlift'),
      te('guided-exp-hv-pull', 'pull-up', 'Pull-Ups', 5, '8-12', '0', false, 'pull-up'),
      te('guided-exp-hv-pull', 'row', 'Chest Supported Row', 4, '10-12', '120', false, 'chest-supported-row'),
      te('guided-exp-hv-pull', 'pulldown', 'Lat Pulldown', 3, '12-15', '110', false, 'lat-pulldown'),
      te('guided-exp-hv-pull', 'face-pull', 'Face Pull', 4, '15-20', '50', false, 'face-pull'),
      te('guided-exp-hv-pull', 'curl', 'Cable Curl', 4, '10-12', '40', false, 'cable-curl'),
    ],
  ),
  dayTemplate(
    'guided-exp-hv-legs',
    'High Volume Legs',
    F_HVPPL,
    [
      te('guided-exp-hv-legs', 'squat', 'Barbell Back Squat', 5, '6-8', '265', false, 'squat'),
      te('guided-exp-hv-legs', 'rdl', 'Romanian Deadlift', 4, '8-10', '205', false, 'romanian-deadlift'),
      te('guided-exp-hv-legs', 'leg-press', 'Leg Press', 4, '12-15', '540', false, 'leg-press'),
      te('guided-exp-hv-legs', 'leg-ext', 'Leg Extension', 4, '12-15', '120', false, 'leg-extension'),
      te('guided-exp-hv-legs', 'leg-curl', 'Leg Curl', 4, '12-15', '120', false, 'hamstring-curl'),
      te('guided-exp-hv-legs', 'calf', 'Standing Calf Raise', 5, '15-20', '180', false, 'standing-calf-raise'),
    ],
  ),
  dayTemplate(
    'guided-exp-ula-upper',
    'Upper + Arms',
    F_ULA,
    [
      te('guided-exp-ula-upper', 'bench', 'Barbell Bench Press', 4, '6-8', '195', false, 'bench-press'),
      te('guided-exp-ula-upper', 'row', 'Barbell Row', 4, '8-10', '155', false, 'barbell-row'),
      te('guided-exp-ula-upper', 'oh-press', 'Overhead Press', 3, '8-10', '105', false, 'overhead-press'),
      te('guided-exp-ula-upper', 'curl', 'Barbell Curl', 4, '10-12', '75', false, 'barbell-curl'),
      te('guided-exp-ula-upper', 'tri', 'Skull Crushers', 4, '10-12', '65', false, 'skull-crusher'),
      te('guided-exp-ula-upper', 'lateral', 'Lateral Raise', 4, '12-15', '25', false, 'lateral-raise'),
    ],
  ),
  dayTemplate(
    'guided-exp-ula-lower',
    'Lower',
    F_ULA,
    [
      te('guided-exp-ula-lower', 'squat', 'Barbell Back Squat', 5, '5-8', '255', false, 'squat'),
      te('guided-exp-ula-lower', 'rdl', 'Romanian Deadlift', 4, '8-10', '205', false, 'romanian-deadlift'),
      te('guided-exp-ula-lower', 'split-squat', 'Bulgarian Split Squat', 3, '10-12', '40', false, 'bulgarian-split-squat'),
      te('guided-exp-ula-lower', 'leg-curl', 'Leg Curl', 4, '12-15', '120', false, 'hamstring-curl'),
      te('guided-exp-ula-lower', 'calf', 'Standing Calf Raise', 4, '15-20', '180', false, 'standing-calf-raise'),
    ],
  ),
  dayTemplate(
    'guided-exp-ula-arms',
    'Arms Day',
    F_ULA,
    [
      te('guided-exp-ula-arms', 'curl', 'Incline Dumbbell Curl', 4, '10-12', '30', false, 'incline-dumbbell-curl'),
      te('guided-exp-ula-arms', 'hammer', 'Hammer Curl', 4, '10-12', '30', false, 'hammer-curl'),
      te('guided-exp-ula-arms', 'preacher', 'Preacher Curl', 3, '10-12', '55', false, 'preacher-curl'),
      te('guided-exp-ula-arms', 'tri', 'Overhead Tricep Extension', 4, '10-12', '50', false, 'overhead-tricep-extension'),
      te('guided-exp-ula-arms', 'pushdown', 'Rope Pushdown', 4, '12-15', '70', false, 'tricep-pushdown'),
      te('guided-exp-ula-arms', 'dip', 'Weighted Dips', 3, '8-12', '25', false, 'dip'),
    ],
  ),
  dayTemplate(
    'guided-exp-pb-squat',
    'Squat Focus',
    F_PB_ADV,
    [
      te('guided-exp-pb-squat', 'squat', 'Barbell Back Squat', 6, '3-5', '285', false, 'squat'),
      te('guided-exp-pb-squat', 'front-squat', 'Front Squat', 4, '6-8', '185', false, 'front-squat'),
      te('guided-exp-pb-squat', 'leg-press', 'Leg Press', 3, '12-15', '450', false, 'leg-press'),
      te('guided-exp-pb-squat', 'leg-curl', 'Leg Curl', 3, '12-15', '110', false, 'hamstring-curl'),
    ],
  ),
  dayTemplate(
    'guided-exp-pb-bench',
    'Bench Focus',
    F_PB_ADV,
    [
      te('guided-exp-pb-bench', 'bench', 'Barbell Bench Press', 6, '3-5', '225', false, 'bench-press'),
      te('guided-exp-pb-bench', 'incline-bench', 'Incline Barbell Bench', 4, '6-8', '165', false, 'incline-bench-press'),
      te('guided-exp-pb-bench', 'oh-press', 'Overhead Press', 3, '8-10', '115', false, 'overhead-press'),
      te('guided-exp-pb-bench', 'tri', 'Close-Grip Bench Press', 3, '8-10', '155', false, 'close-grip-bench-press'),
    ],
  ),
  dayTemplate(
    'guided-exp-pb-deadlift',
    'Deadlift Focus',
    F_PB_ADV,
    [
      te('guided-exp-pb-deadlift', 'deadlift', 'Conventional Deadlift', 6, '2-4', '365', false, 'deadlift'),
      te('guided-exp-pb-deadlift', 'rdl', 'Romanian Deadlift', 4, '8', '225', false, 'romanian-deadlift'),
      te('guided-exp-pb-deadlift', 'row', 'Barbell Row', 4, '8-10', '165', false, 'barbell-row'),
      te('guided-exp-pb-deadlift', 'pull-up', 'Pull-Ups', 3, '8-12', '0', false, 'pull-up'),
    ],
  ),
  dayTemplate(
    'guided-exp-pb-accessory',
    'Accessory Day',
    F_PB_ADV,
    [
      te('guided-exp-pb-accessory', 'incline-db', 'Incline Dumbbell Press', 4, '10-12', '55', false, 'incline-dumbbell-press'),
      te('guided-exp-pb-accessory', 'lat-pulldown', 'Lat Pulldown', 4, '10-12', '120', false, 'lat-pulldown'),
      te('guided-exp-pb-accessory', 'lateral', 'Lateral Raise', 4, '15-20', '25', false, 'lateral-raise'),
      te('guided-exp-pb-accessory', 'curl', 'Cable Curl', 3, '12-15', '40', false, 'cable-curl'),
      te('guided-exp-pb-accessory', 'core', 'Cable Crunch', 3, '12-15', '70', false, 'cable-crunch'),
    ],
  ),
  repeatTemplate(
    SUMMER_CUT_ID,
    'Summer Cut',
    F,
    [
      te(SUMMER_CUT_ID, 'circuit-squat', 'Goblet Squat', 3, '15', '45', true, 'goblet-squat'),
      te(SUMMER_CUT_ID, 'circuit-push', 'Incline Push-Ups', 3, '12-15', '0', true, 'push-up'),
      te(SUMMER_CUT_ID, 'circuit-row', 'Cable Row', 3, '12-15', '80', true, 'seated-cable-row'),
      te(SUMMER_CUT_ID, 'circuit-lunge', 'Walking Lunges', 3, '12/leg', '25', true, 'walking-lunge'),
      te(SUMMER_CUT_ID, 'cardio', 'Stair Climber', 1, '20 min', '0', false, 'stair-climber'),
      te(SUMMER_CUT_ID, 'core', 'Hanging Leg Raise', 3, '12-15', '0', false, 'hanging-leg-raise'),
    ],
    'Superset-friendly cut phase. Keep rest short and protein high.',
  ),
  repeatTemplate(
    STRENGTH_HYBRID_ID,
    'Strength Hybrid',
    F,
    [
      te(STRENGTH_HYBRID_ID, 'squat', 'Barbell Back Squat', 5, '5', '225', false, 'squat'),
      te(STRENGTH_HYBRID_ID, 'bench', 'Barbell Bench Press', 5, '5', '185', false, 'bench-press'),
      te(STRENGTH_HYBRID_ID, 'row', 'Barbell Row', 4, '8', '135', false, 'barbell-row'),
      te(STRENGTH_HYBRID_ID, 'rdl', 'Romanian Deadlift', 3, '8-10', '185', false, 'romanian-deadlift'),
      te(STRENGTH_HYBRID_ID, 'oh-press', 'Overhead Press', 3, '8-10', '95', false, 'overhead-press'),
      te(STRENGTH_HYBRID_ID, 'core', 'Pallof Press', 3, '12', '40', false, 'pallof-press'),
    ],
    'Strength-first full body with compound focus. Repeat 3–4× per week.',
  ),
]
