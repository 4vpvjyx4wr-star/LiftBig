import type { WorkoutTemplate } from '@/types/workout'
import { GUIDED_INTERMEDIATE_FOLDER } from './guidedPlanFolders'
import { dayTemplate, repeatTemplate, te } from './planHelpers'

const F = GUIDED_INTERMEDIATE_FOLDER.id

export const INTERMEDIATE_UL_HYPERTROPHY_FOLDER_ID = 'guided-intermediate-ul-hypertrophy'
export const INTERMEDIATE_PPL_FOLDER_ID = 'guided-intermediate-ppl'
export const INTERMEDIATE_POWERBUILDING_FOLDER_ID = 'guided-intermediate-powerbuilding-4d'
export const LEAN_MUSCLE_BUILDER_ID = 'guided-lean-muscle-builder'
export const BUSY_PROFESSIONAL_ID = 'guided-busy-professional'
export const MACHINE_HYPERTROPHY_ID = 'guided-machine-hypertrophy'

export const INTERMEDIATE_GUIDED_PLANS: WorkoutTemplate[] = [
  dayTemplate(
    'guided-int-ul-upper-a',
    'Upper Hypertrophy A',
    F,
    [
      te('guided-int-ul-upper-a', 'bench', 'Barbell Bench Press', 4, '8-10', '135', false, 'bench-press'),
      te('guided-int-ul-upper-a', 'row', 'Barbell Row', 4, '8-10', '115', false, 'barbell-row'),
      te('guided-int-ul-upper-a', 'incline-db', 'Incline Dumbbell Press', 3, '10-12', '45', false, 'incline-dumbbell-press'),
      te('guided-int-ul-upper-a', 'lat-pulldown', 'Lat Pulldown', 3, '10-12', '100', false, 'lat-pulldown'),
      te('guided-int-ul-upper-a', 'lateral', 'Lateral Raise', 3, '12-15', '20', false, 'lateral-raise'),
      te('guided-int-ul-upper-a', 'curl', 'Cable Curl', 3, '10-12', '35', false, 'cable-curl'),
    ],
  ),
  dayTemplate(
    'guided-int-ul-lower-a',
    'Lower Hypertrophy A',
    F,
    [
      te('guided-int-ul-lower-a', 'squat', 'Barbell Back Squat', 4, '8-10', '185', false, 'squat'),
      te('guided-int-ul-lower-a', 'rdl', 'Romanian Deadlift', 3, '10-12', '135', false, 'romanian-deadlift'),
      te('guided-int-ul-lower-a', 'leg-press', 'Leg Press', 3, '12-15', '270', false, 'leg-press'),
      te('guided-int-ul-lower-a', 'leg-curl', 'Leg Curl', 3, '12-15', '90', false, 'hamstring-curl'),
      te('guided-int-ul-lower-a', 'calf', 'Standing Calf Raise', 4, '12-15', '120', false, 'standing-calf-raise'),
    ],
  ),
  dayTemplate(
    'guided-int-ul-upper-b',
    'Upper Hypertrophy B',
    F,
    [
      te('guided-int-ul-upper-b', 'oh-press', 'Overhead Press', 4, '8-10', '85', false, 'overhead-press'),
      te('guided-int-ul-upper-b', 'pull-up', 'Pull-Ups', 4, '6-10', '0', false, 'pull-up'),
      te('guided-int-ul-upper-b', 'chest-fly', 'Cable Fly', 3, '12-15', '30', false, 'cable-fly'),
      te('guided-int-ul-upper-b', 'face-pull', 'Face Pull', 3, '15-20', '40', false, 'face-pull'),
      te('guided-int-ul-upper-b', 'tri', 'Rope Pushdown', 3, '10-12', '60', false, 'tricep-pushdown'),
      te('guided-int-ul-upper-b', 'hammer', 'Hammer Curl', 3, '10-12', '25', false, 'hammer-curl'),
    ],
  ),
  dayTemplate(
    'guided-int-ul-lower-b',
    'Lower Hypertrophy B',
    F,
    [
      te('guided-int-ul-lower-b', 'deadlift', 'Conventional Deadlift', 4, '5-8', '225', false, 'deadlift'),
      te('guided-int-ul-lower-b', 'split-squat', 'Bulgarian Split Squat', 3, '10-12', '30', false, 'bulgarian-split-squat'),
      te('guided-int-ul-lower-b', 'hip-thrust', 'Hip Thrust', 3, '10-12', '135', false, 'hip-thrust'),
      te('guided-int-ul-lower-b', 'leg-ext', 'Leg Extension', 3, '12-15', '90', false, 'leg-extension'),
      te('guided-int-ul-lower-b', 'core', 'Cable Crunch', 3, '12-15', '60', false, 'cable-crunch'),
    ],
  ),
  dayTemplate(
    'guided-int-push',
    'Push',
    F,
    [
      te('guided-int-push', 'bench', 'Barbell Bench Press', 4, '8-10', '155', false, 'bench-press'),
      te('guided-int-push', 'oh-press', 'Overhead Press', 3, '8-10', '85', false, 'overhead-press'),
      te('guided-int-push', 'incline-db', 'Incline Dumbbell Press', 3, '10-12', '50', false, 'incline-dumbbell-press'),
      te('guided-int-push', 'lateral', 'Lateral Raise', 4, '12-15', '20', false, 'lateral-raise'),
      te('guided-int-push', 'tri', 'Overhead Tricep Extension', 3, '10-12', '40', false, 'overhead-tricep-extension'),
    ],
  ),
  dayTemplate(
    'guided-int-pull',
    'Pull',
    F,
    [
      te('guided-int-pull', 'deadlift', 'Conventional Deadlift', 4, '5-6', '275', false, 'deadlift'),
      te('guided-int-pull', 'pull-up', 'Pull-Ups', 4, '6-10', '0', false, 'pull-up'),
      te('guided-int-pull', 'row', 'Barbell Row', 3, '8-10', '125', false, 'barbell-row'),
      te('guided-int-pull', 'face-pull', 'Face Pull', 3, '15-20', '40', false, 'face-pull'),
      te('guided-int-pull', 'curl', 'Incline Dumbbell Curl', 3, '10-12', '25', false, 'incline-dumbbell-curl'),
    ],
  ),
  dayTemplate(
    'guided-int-legs',
    'Legs',
    F,
    [
      te('guided-int-legs', 'squat', 'Barbell Back Squat', 4, '6-8', '205', false, 'squat'),
      te('guided-int-legs', 'rdl', 'Romanian Deadlift', 3, '8-10', '155', false, 'romanian-deadlift'),
      te('guided-int-legs', 'leg-press', 'Leg Press', 3, '12-15', '360', false, 'leg-press'),
      te('guided-int-legs', 'leg-curl', 'Leg Curl', 3, '12-15', '100', false, 'hamstring-curl'),
      te('guided-int-legs', 'calf', 'Standing Calf Raise', 4, '12-15', '140', false, 'standing-calf-raise'),
    ],
  ),
  dayTemplate(
    'guided-int-pb-upper',
    'Powerbuilding Upper',
    F,
    [
      te('guided-int-pb-upper', 'bench', 'Barbell Bench Press', 5, '5', '175', false, 'bench-press'),
      te('guided-int-pb-upper', 'row', 'Barbell Row', 4, '8', '135', false, 'barbell-row'),
      te('guided-int-pb-upper', 'incline-db', 'Incline Dumbbell Press', 3, '10-12', '50', false, 'incline-dumbbell-press'),
      te('guided-int-pb-upper', 'lat-pulldown', 'Lat Pulldown', 3, '10-12', '100', false, 'lat-pulldown'),
      te('guided-int-pb-upper', 'tri', 'Tricep Pushdown', 3, '12-15', '60', false, 'tricep-pushdown'),
    ],
  ),
  dayTemplate(
    'guided-int-pb-lower',
    'Powerbuilding Lower',
    F,
    [
      te('guided-int-pb-lower', 'squat', 'Barbell Back Squat', 5, '5', '225', false, 'squat'),
      te('guided-int-pb-lower', 'rdl', 'Romanian Deadlift', 4, '8', '185', false, 'romanian-deadlift'),
      te('guided-int-pb-lower', 'leg-press', 'Leg Press', 3, '12-15', '360', false, 'leg-press'),
      te('guided-int-pb-lower', 'leg-curl', 'Leg Curl', 3, '12-15', '100', false, 'hamstring-curl'),
      te('guided-int-pb-lower', 'calf', 'Standing Calf Raise', 3, '15-20', '140', false, 'standing-calf-raise'),
    ],
  ),
  dayTemplate(
    'guided-int-pb-push',
    'Powerbuilding Push',
    F,
    [
      te('guided-int-pb-push', 'oh-press', 'Overhead Press', 5, '5', '95', false, 'overhead-press'),
      te('guided-int-pb-push', 'incline-bench', 'Incline Barbell Bench', 4, '8', '135', false, 'incline-bench-press'),
      te('guided-int-pb-push', 'lateral', 'Lateral Raise', 4, '12-15', '20', false, 'lateral-raise'),
      te('guided-int-pb-push', 'tri', 'Overhead Tricep Extension', 3, '10-12', '45', false, 'overhead-tricep-extension'),
    ],
  ),
  dayTemplate(
    'guided-int-pb-pull',
    'Powerbuilding Pull',
    F,
    [
      te('guided-int-pb-pull', 'deadlift', 'Conventional Deadlift', 5, '3', '315', false, 'deadlift'),
      te('guided-int-pb-pull', 'pull-up', 'Weighted Pull-Ups', 4, '6-8', '25', false, 'pull-up'),
      te('guided-int-pb-pull', 'row', 'Chest Supported Row', 3, '10-12', '100', false, 'chest-supported-row'),
      te('guided-int-pb-pull', 'curl', 'Barbell Curl', 3, '10-12', '65', false, 'barbell-curl'),
    ],
  ),
  repeatTemplate(
    LEAN_MUSCLE_BUILDER_ID,
    'Lean Muscle Builder',
    F,
    [
      te(LEAN_MUSCLE_BUILDER_ID, 'squat', 'Goblet Squat', 3, '12-15', '45', false, 'goblet-squat'),
      te(LEAN_MUSCLE_BUILDER_ID, 'bench', 'Dumbbell Bench Press', 3, '10-12', '45', false, 'flat-dumbbell-press'),
      te(LEAN_MUSCLE_BUILDER_ID, 'row', 'Cable Row', 3, '10-12', '90', false, 'seated-cable-row'),
      te(LEAN_MUSCLE_BUILDER_ID, 'rdl', 'Romanian Deadlift', 3, '10-12', '135', false, 'romanian-deadlift'),
      te(LEAN_MUSCLE_BUILDER_ID, 'cardio', 'Incline Walk', 1, '15 min', '0', false, 'treadmill-walk'),
      te(LEAN_MUSCLE_BUILDER_ID, 'core', 'Plank', 2, '45 sec', '0', false, 'plank'),
    ],
    'Recomposition-focused full body with moderate volume and cardio finishers.',
  ),
  repeatTemplate(
    BUSY_PROFESSIONAL_ID,
    'Busy Professional',
    F,
    [
      te(BUSY_PROFESSIONAL_ID, 'squat', 'Leg Press', 3, '12', '270', false, 'leg-press'),
      te(BUSY_PROFESSIONAL_ID, 'press', 'Machine Chest Press', 3, '10-12', '100', false, 'machine-chest-press'),
      te(BUSY_PROFESSIONAL_ID, 'pulldown', 'Lat Pulldown', 3, '10-12', '90', false, 'lat-pulldown'),
      te(BUSY_PROFESSIONAL_ID, 'shoulder', 'Dumbbell Shoulder Press', 2, '10-12', '30', false, 'dumbbell-shoulder-press'),
      te(BUSY_PROFESSIONAL_ID, 'curl', 'Cable Curl', 2, '12', '30', false, 'cable-curl'),
    ],
    'Efficient ~45-minute sessions for busy schedules. Repeat 3–4× per week.',
  ),
  repeatTemplate(
    MACHINE_HYPERTROPHY_ID,
    'Machine Hypertrophy',
    F,
    [
      te(MACHINE_HYPERTROPHY_ID, 'chest', 'Machine Chest Press', 4, '10-12', '110', false, 'machine-chest-press'),
      te(MACHINE_HYPERTROPHY_ID, 'row', 'Chest Supported Row', 4, '10-12', '100', false, 'chest-supported-row'),
      te(MACHINE_HYPERTROPHY_ID, 'shoulder', 'Machine Shoulder Press', 3, '10-12', '70', false, 'machine-shoulder-press'),
      te(MACHINE_HYPERTROPHY_ID, 'leg-press', 'Leg Press', 4, '12-15', '360', false, 'leg-press'),
      te(MACHINE_HYPERTROPHY_ID, 'leg-curl', 'Leg Curl', 3, '12-15', '100', false, 'hamstring-curl'),
      te(MACHINE_HYPERTROPHY_ID, 'lateral', 'Lateral Raise', 3, '15-20', '20', false, 'lateral-raise'),
    ],
    'Machine-heavy hypertrophy for joint-friendly volume.',
  ),
]
