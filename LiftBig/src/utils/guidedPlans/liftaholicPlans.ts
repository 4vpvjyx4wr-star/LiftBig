import type { WorkoutTemplate } from '@/types/workout'
import { GUIDED_LIFTAHOLIC_FOLDER } from './guidedPlanFolders'
import { dayTemplate, repeatTemplate, te } from './planHelpers'

const F = GUIDED_LIFTAHOLIC_FOLDER.id

export const LIFTBIG_EXTREME_FOLDER_ID = 'guided-liftbig-extreme'
export const ARNOLD_PPL_FOLDER_ID = 'guided-arnold-ppl'
export const DOUBLE_SPLIT_FOLDER_ID = 'guided-double-split'
export const MASS_MONSTER_FOLDER_ID = 'guided-mass-monster'
export const HIGH_FREQ_FB_ID = 'guided-high-freq-full-body'
export const ADVANCED_AESTHETICS_FOLDER_ID = 'guided-advanced-aesthetics'

export const LIFTAHOLIC_GUIDED_PLANS: WorkoutTemplate[] = [
  dayTemplate(
    'guided-la-extreme-push',
    'Extreme Push',
    F,
    [
      te('guided-la-extreme-push', 'bench', 'Barbell Bench Press', 6, '6-8', '225', false, 'bench-press'),
      te('guided-la-extreme-push', 'oh-press', 'Overhead Press', 5, '6-8', '135', false, 'overhead-press'),
      te('guided-la-extreme-push', 'incline-db', 'Incline Dumbbell Press', 5, '10-12', '60', false, 'incline-dumbbell-press'),
      te('guided-la-extreme-push', 'lateral', 'Lateral Raise', 6, '15-20', '30', false, 'lateral-raise'),
      te('guided-la-extreme-push', 'fly', 'Cable Fly', 4, '12-15', '40', false, 'cable-fly'),
      te('guided-la-extreme-push', 'tri', 'Overhead Tricep Extension', 5, '10-12', '55', false, 'overhead-tricep-extension'),
      te('guided-la-extreme-push', 'pushdown', 'Rope Pushdown', 4, '12-15', '80', false, 'tricep-pushdown'),
    ],
  ),
  dayTemplate(
    'guided-la-extreme-pull',
    'Extreme Pull',
    F,
    [
      te('guided-la-extreme-pull', 'deadlift', 'Conventional Deadlift', 5, '3-5', '405', false, 'deadlift'),
      te('guided-la-extreme-pull', 'pull-up', 'Weighted Pull-Ups', 6, '6-10', '45', false, 'pull-up'),
      te('guided-la-extreme-pull', 'row', 'Barbell Row', 5, '8-10', '185', false, 'barbell-row'),
      te('guided-la-extreme-pull', 'pulldown', 'Lat Pulldown', 4, '10-12', '130', false, 'lat-pulldown'),
      te('guided-la-extreme-pull', 'face-pull', 'Face Pull', 5, '15-20', '60', false, 'face-pull'),
      te('guided-la-extreme-pull', 'curl', 'Barbell Curl', 5, '10-12', '85', false, 'barbell-curl'),
      te('guided-la-extreme-pull', 'hammer', 'Hammer Curl', 4, '10-12', '35', false, 'hammer-curl'),
    ],
  ),
  dayTemplate(
    'guided-la-extreme-legs',
    'Extreme Legs',
    F,
    [
      te('guided-la-extreme-legs', 'squat', 'Barbell Back Squat', 6, '5-8', '315', false, 'squat'),
      te('guided-la-extreme-legs', 'rdl', 'Romanian Deadlift', 5, '8-10', '275', false, 'romanian-deadlift'),
      te('guided-la-extreme-legs', 'leg-press', 'Leg Press', 5, '12-15', '630', false, 'leg-press'),
      te('guided-la-extreme-legs', 'leg-ext', 'Leg Extension', 5, '12-15', '140', false, 'leg-extension'),
      te('guided-la-extreme-legs', 'leg-curl', 'Leg Curl', 5, '12-15', '140', false, 'hamstring-curl'),
      te('guided-la-extreme-legs', 'calf', 'Standing Calf Raise', 6, '15-20', '220', false, 'standing-calf-raise'),
    ],
  ),
  dayTemplate(
    'guided-la-arnold-chest-back',
    'Chest & Back',
    F,
    [
      te('guided-la-arnold-chest-back', 'bench', 'Barbell Bench Press', 5, '8-10', '225', false, 'bench-press'),
      te('guided-la-arnold-chest-back', 'incline-db', 'Incline Dumbbell Press', 4, '10-12', '60', false, 'incline-dumbbell-press'),
      te('guided-la-arnold-chest-back', 'pull-up', 'Pull-Ups', 5, '8-12', '0', false, 'pull-up'),
      te('guided-la-arnold-chest-back', 'row', 'Barbell Row', 4, '8-10', '185', false, 'barbell-row'),
      te('guided-la-arnold-chest-back', 'fly', 'Cable Fly', 4, '12-15', '40', false, 'cable-fly'),
      te('guided-la-arnold-chest-back', 'pulldown', 'Lat Pulldown', 4, '10-12', '130', false, 'lat-pulldown'),
    ],
  ),
  dayTemplate(
    'guided-la-arnold-shoulders-arms',
    'Shoulders & Arms',
    F,
    [
      te('guided-la-arnold-shoulders-arms', 'oh-press', 'Overhead Press', 5, '8-10', '135', false, 'overhead-press'),
      te('guided-la-arnold-shoulders-arms', 'lateral', 'Lateral Raise', 6, '15-20', '30', false, 'lateral-raise'),
      te('guided-la-arnold-shoulders-arms', 'rear-delt', 'Rear Delt Fly', 5, '15-20', '30', false, 'rear-delt-fly'),
      te('guided-la-arnold-shoulders-arms', 'curl', 'Barbell Curl', 5, '10-12', '85', false, 'barbell-curl'),
      te('guided-la-arnold-shoulders-arms', 'tri', 'Skull Crushers', 5, '10-12', '75', false, 'skull-crusher'),
      te('guided-la-arnold-shoulders-arms', 'pushdown', 'Rope Pushdown', 4, '12-15', '80', false, 'tricep-pushdown'),
    ],
  ),
  dayTemplate(
    'guided-la-arnold-legs',
    'Legs',
    F,
    [
      te('guided-la-arnold-legs', 'squat', 'Barbell Back Squat', 6, '6-8', '315', false, 'squat'),
      te('guided-la-arnold-legs', 'rdl', 'Romanian Deadlift', 4, '8-10', '275', false, 'romanian-deadlift'),
      te('guided-la-arnold-legs', 'leg-press', 'Leg Press', 5, '12-15', '630', false, 'leg-press'),
      te('guided-la-arnold-legs', 'leg-curl', 'Leg Curl', 5, '12-15', '140', false, 'hamstring-curl'),
      te('guided-la-arnold-legs', 'calf', 'Standing Calf Raise', 6, '15-20', '220', false, 'standing-calf-raise'),
    ],
  ),
  dayTemplate(
    'guided-la-ds-am-upper',
    'AM Upper',
    F,
    [
      te('guided-la-ds-am-upper', 'bench', 'Barbell Bench Press', 4, '6-8', '225', false, 'bench-press'),
      te('guided-la-ds-am-upper', 'row', 'Barbell Row', 4, '8-10', '185', false, 'barbell-row'),
      te('guided-la-ds-am-upper', 'oh-press', 'Overhead Press', 3, '8-10', '135', false, 'overhead-press'),
      te('guided-la-ds-am-upper', 'lateral', 'Lateral Raise', 4, '12-15', '30', false, 'lateral-raise'),
    ],
  ),
  dayTemplate(
    'guided-la-ds-pm-upper',
    'PM Upper',
    F,
    [
      te('guided-la-ds-pm-upper', 'incline-db', 'Incline Dumbbell Press', 4, '10-12', '60', false, 'incline-dumbbell-press'),
      te('guided-la-ds-pm-upper', 'pulldown', 'Lat Pulldown', 4, '10-12', '130', false, 'lat-pulldown'),
      te('guided-la-ds-pm-upper', 'curl', 'Cable Curl', 4, '10-12', '45', false, 'cable-curl'),
      te('guided-la-ds-pm-upper', 'tri', 'Overhead Tricep Extension', 4, '10-12', '55', false, 'overhead-tricep-extension'),
    ],
  ),
  dayTemplate(
    'guided-la-ds-am-lower',
    'AM Lower',
    F,
    [
      te('guided-la-ds-am-lower', 'squat', 'Barbell Back Squat', 5, '5-8', '315', false, 'squat'),
      te('guided-la-ds-am-lower', 'rdl', 'Romanian Deadlift', 4, '8-10', '275', false, 'romanian-deadlift'),
      te('guided-la-ds-am-lower', 'leg-curl', 'Leg Curl', 4, '12-15', '140', false, 'hamstring-curl'),
    ],
  ),
  dayTemplate(
    'guided-la-ds-pm-lower',
    'PM Lower',
    F,
    [
      te('guided-la-ds-pm-lower', 'leg-press', 'Leg Press', 5, '12-15', '630', false, 'leg-press'),
      te('guided-la-ds-pm-lower', 'split-squat', 'Bulgarian Split Squat', 4, '10-12', '50', false, 'bulgarian-split-squat'),
      te('guided-la-ds-pm-lower', 'calf', 'Standing Calf Raise', 5, '15-20', '220', false, 'standing-calf-raise'),
      te('guided-la-ds-pm-lower', 'core', 'Cable Crunch', 4, '12-15', '80', false, 'cable-crunch'),
    ],
  ),
  dayTemplate(
    'guided-la-mass-chest',
    'Mass Chest',
    F,
    [
      te('guided-la-mass-chest', 'bench', 'Barbell Bench Press', 6, '8-10', '225', false, 'bench-press'),
      te('guided-la-mass-chest', 'incline-db', 'Incline Dumbbell Press', 5, '10-12', '60', false, 'incline-dumbbell-press'),
      te('guided-la-mass-chest', 'fly', 'Cable Fly', 5, '12-15', '45', false, 'cable-fly'),
      te('guided-la-mass-chest', 'dip', 'Weighted Dips', 4, '8-12', '35', false, 'dip'),
      te('guided-la-mass-chest', 'tri', 'Close-Grip Bench Press', 4, '8-10', '175', false, 'close-grip-bench-press'),
    ],
  ),
  dayTemplate(
    'guided-la-mass-back',
    'Mass Back',
    F,
    [
      te('guided-la-mass-back', 'deadlift', 'Conventional Deadlift', 5, '4-6', '405', false, 'deadlift'),
      te('guided-la-mass-back', 'pull-up', 'Weighted Pull-Ups', 6, '6-10', '45', false, 'pull-up'),
      te('guided-la-mass-back', 'row', 'Barbell Row', 5, '8-10', '185', false, 'barbell-row'),
      te('guided-la-mass-back', 'pulldown', 'Lat Pulldown', 4, '10-12', '130', false, 'lat-pulldown'),
      te('guided-la-mass-back', 'face-pull', 'Face Pull', 4, '15-20', '60', false, 'face-pull'),
    ],
  ),
  dayTemplate(
    'guided-la-mass-legs',
    'Mass Legs',
    F,
    [
      te('guided-la-mass-legs', 'squat', 'Barbell Back Squat', 6, '6-8', '315', false, 'squat'),
      te('guided-la-mass-legs', 'rdl', 'Romanian Deadlift', 5, '8-10', '275', false, 'romanian-deadlift'),
      te('guided-la-mass-legs', 'leg-press', 'Leg Press', 5, '12-15', '630', false, 'leg-press'),
      te('guided-la-mass-legs', 'leg-ext', 'Leg Extension', 5, '12-15', '140', false, 'leg-extension'),
      te('guided-la-mass-legs', 'leg-curl', 'Leg Curl', 5, '12-15', '140', false, 'hamstring-curl'),
      te('guided-la-mass-legs', 'calf', 'Standing Calf Raise', 6, '15-20', '220', false, 'standing-calf-raise'),
    ],
  ),
  dayTemplate(
    'guided-la-mass-shoulders',
    'Mass Shoulders',
    F,
    [
      te('guided-la-mass-shoulders', 'oh-press', 'Overhead Press', 6, '6-8', '135', false, 'overhead-press'),
      te('guided-la-mass-shoulders', 'lateral', 'Lateral Raise', 6, '15-20', '30', false, 'lateral-raise'),
      te('guided-la-mass-shoulders', 'rear-delt', 'Rear Delt Fly', 5, '15-20', '30', false, 'rear-delt-fly'),
      te('guided-la-mass-shoulders', 'upright-row', 'Cable Upright Row', 4, '12-15', '50', false, 'cable-upright-row'),
      te('guided-la-mass-shoulders', 'shrug', 'Barbell Shrug', 4, '12-15', '225', false, 'barbell-shrug'),
    ],
  ),
  repeatTemplate(
    HIGH_FREQ_FB_ID,
    'High Frequency Full Body',
    F,
    [
      te(HIGH_FREQ_FB_ID, 'squat', 'Barbell Back Squat', 4, '5', '245', false, 'squat'),
      te(HIGH_FREQ_FB_ID, 'bench', 'Barbell Bench Press', 4, '5', '195', false, 'bench-press'),
      te(HIGH_FREQ_FB_ID, 'row', 'Barbell Row', 3, '8', '155', false, 'barbell-row'),
      te(HIGH_FREQ_FB_ID, 'rdl', 'Romanian Deadlift', 3, '8', '205', false, 'romanian-deadlift'),
      te(HIGH_FREQ_FB_ID, 'oh-press', 'Overhead Press', 3, '8', '115', false, 'overhead-press'),
      te(HIGH_FREQ_FB_ID, 'curl', 'Barbell Curl', 3, '10-12', '75', false, 'barbell-curl'),
    ],
    'Full body repeated 5–6× per week with submaximal loads. Auto-regulate intensity.',
  ),
  dayTemplate(
    'guided-la-aesthetics-upper-a',
    'Aesthetics Upper A',
    F,
    [
      te('guided-la-aesthetics-upper-a', 'incline-db', 'Incline Dumbbell Press', 5, '8-10', '60', false, 'incline-dumbbell-press'),
      te('guided-la-aesthetics-upper-a', 'pull-up', 'Pull-Ups', 5, '8-12', '0', false, 'pull-up'),
      te('guided-la-aesthetics-upper-a', 'lateral', 'Lateral Raise', 6, '15-20', '30', false, 'lateral-raise'),
      te('guided-la-aesthetics-upper-a', 'rear-delt', 'Rear Delt Fly', 5, '15-20', '30', false, 'rear-delt-fly'),
      te('guided-la-aesthetics-upper-a', 'curl', 'Incline Dumbbell Curl', 4, '10-12', '30', false, 'incline-dumbbell-curl'),
    ],
  ),
  dayTemplate(
    'guided-la-aesthetics-lower',
    'Aesthetics Lower',
    F,
    [
      te('guided-la-aesthetics-lower', 'squat', 'Barbell Back Squat', 5, '6-8', '275', false, 'squat'),
      te('guided-la-aesthetics-lower', 'rdl', 'Romanian Deadlift', 4, '8-10', '225', false, 'romanian-deadlift'),
      te('guided-la-aesthetics-lower', 'hip-thrust', 'Hip Thrust', 4, '10-12', '185', false, 'hip-thrust'),
      te('guided-la-aesthetics-lower', 'leg-curl', 'Leg Curl', 4, '12-15', '120', false, 'hamstring-curl'),
      te('guided-la-aesthetics-lower', 'calf', 'Standing Calf Raise', 5, '15-20', '180', false, 'standing-calf-raise'),
    ],
  ),
  dayTemplate(
    'guided-la-aesthetics-upper-b',
    'Aesthetics Upper B',
    F,
    [
      te('guided-la-aesthetics-upper-b', 'oh-press', 'Overhead Press', 5, '6-8', '135', false, 'overhead-press'),
      te('guided-la-aesthetics-upper-b', 'row', 'Chest Supported Row', 5, '8-10', '120', false, 'chest-supported-row'),
      te('guided-la-aesthetics-upper-b', 'fly', 'Cable Fly', 4, '12-15', '45', false, 'cable-fly'),
      te('guided-la-aesthetics-upper-b', 'tri', 'Overhead Tricep Extension', 5, '10-12', '55', false, 'overhead-tricep-extension'),
      te('guided-la-aesthetics-upper-b', 'pushdown', 'Rope Pushdown', 4, '12-15', '80', false, 'tricep-pushdown'),
    ],
  ),
]
