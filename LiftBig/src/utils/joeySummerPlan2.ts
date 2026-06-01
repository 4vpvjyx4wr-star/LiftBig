import type { TemplateExercise, TemplateFolder, WorkoutTemplate } from '@/types/workout'

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

export const JOEY_SUMMER_PLAN2_FOLDER: TemplateFolder = {
  id: 'folder-joey-summer-plan-2',
  name: 'Joey Summer Plan 2',
  purpose:
    'Six-day summer split: upper chest and delts, lat width, light conditioning, legs, shoulder specialization, and pull + arms. Superset pairings with optional finishers on Friday and Saturday.',
}

const SUPERSET_NOTE =
  'Superset A → B → C → D: pair exercises back-to-back with minimal rest between the two moves, then rest before the next round.'

function planId(day: string): string {
  return `plan-joey-summer2-${day}`
}

export const JOEY_SUMMER_PLAN2_PLANS: WorkoutTemplate[] = [
  {
    id: planId('mon'),
    name: 'Monday: Upper Chest + Delts + Abs',
    folderId: JOEY_SUMMER_PLAN2_FOLDER.id,
    notes: `${SUPERSET_NOTE}\n\nActivity: Upper chest, delts & abs (~55–60 min).`,
    exercises: [
      te(planId('mon'), 'incline-db', 'Incline DB Press', 4, '6–10', '55', false, 'incline-dumbbell-press'),
      te(planId('mon'), 'cable-lat-a', 'Cable Lateral Raise', 4, '15–20', '15', false, 'cable-lateral-raise'),
      te(planId('mon'), 'incline-machine', 'Incline Machine Press', 3, '8–12', '95', false, 'incline-machine-press'),
      te(planId('mon'), 'rear-delt-machine', 'Rear Delt Fly Machine', 3, '12–15', '50', false, 'reverse-fly-machine'),
      te(planId('mon'), 'low-high-fly', 'Low-to-High Cable Fly', 3, '12–15', '25', false, 'low-to-high-cable-fly'),
      te(planId('mon'), 'lean-away-cable-lat', 'Lean-Away Cable Lateral Raise', 3, '12–15', '12.5', false, 'lean-away-cable-lateral-raise'),
      te(planId('mon'), 'cable-crunch', 'Cable Crunch', 4, '10–15', '85', false, 'cable-crunch'),
      te(planId('mon'), 'hanging-leg-raise', 'Hanging Leg Raise', 4, '10–15', '0', false, 'leg-raise'),
    ],
  },
  {
    id: planId('tue'),
    name: 'Tuesday: Lat Width + Biceps + Abs',
    folderId: JOEY_SUMMER_PLAN2_FOLDER.id,
    notes: `${SUPERSET_NOTE}\n\nActivity: Lat width, biceps & abs (~55 min).`,
    exercises: [
      te(planId('tue'), 'single-lat', 'Single Arm Lat Pulldown', 4, '10–12', '60', false, 'single-arm-lat-pulldown'),
      te(planId('tue'), 'incline-db-curl', 'Incline DB Curl', 4, '10–12', '25', false, 'incline-dumbbell-curl'),
      te(planId('tue'), 'neutral-lat', 'Neutral Grip Lat Pulldown', 3, '8–12', '100', false, 'neutral-grip-lat-pulldown'),
      te(planId('tue'), 'hammer', 'Hammer Curl', 3, '10–12', '25', false, 'hammer-curl'),
      te(planId('tue'), 'lat-row', 'Chest Supported Lat-Focused Row', 3, '10–12', '100', false, 'chest-supported-lat-row'),
      te(planId('tue'), 'face-pull', 'Face Pull', 3, '12–15', '100', false, 'face-pull'),
      te(planId('tue'), 'ab-wheel', 'Ab Wheel', 3, '8–15', '0', false, 'ab-wheel-rollout'),
      te(planId('tue'), 'woodchop', 'Cable Woodchop', 3, '12/side', '35', false, 'cable-woodchop'),
    ],
  },
  {
    id: planId('wed'),
    name: 'Wednesday: Conditioning + Core',
    folderId: JOEY_SUMMER_PLAN2_FOLDER.id,
    notes:
      'Incline walk 20–30 min at a comfortable pace. Then complete the ab circuit for 4 rounds—minimal rest between stations, brief rest between rounds. This day should leave you feeling better, not exhausted.\n\nActivity: Conditioning + core (35–45 min).',
    exercises: [
      te(planId('wed'), 'incline-walk', 'Incline Walk', 1, '20–30 min', '0', false, 'incline-treadmill-walk'),
      te(planId('wed'), 'ab-wheel-c', 'Ab Wheel', 4, '10', '0', true, 'ab-wheel-rollout'),
      te(planId('wed'), 'cable-crunch-c', 'Cable Crunch', 4, '15', '85', true, 'cable-crunch'),
      te(planId('wed'), 'reverse-crunch', 'Reverse Crunch', 4, '15', '0', true, 'reverse-crunch'),
      te(planId('wed'), 'side-plank', 'Side Plank', 4, '30 sec/side', '0', true, 'side-plank'),
    ],
  },
  {
    id: planId('thu'),
    name: 'Thursday: Legs + Delts',
    folderId: JOEY_SUMMER_PLAN2_FOLDER.id,
    notes: `${SUPERSET_NOTE}\n\nLeg press and calf raise: same machine area in most gyms.\n\nActivity: Legs & delts (~60 min).`,
    exercises: [
      te(planId('thu'), 'leg-press', 'Leg Press', 4, '8–10', '275', false, 'leg-press'),
      te(planId('thu'), 'calf-raise', 'Standing Calf Raise', 4, '12–20', '225', false, 'calf-raise'),
      te(planId('thu'), 'rdl', 'Romanian Deadlift', 4, '8–10', '135', false, 'romanian-deadlift'),
      te(planId('thu'), 'cable-lat', 'Cable Lateral Raise', 4, '15–20', '15', false, 'cable-lateral-raise'),
      te(planId('thu'), 'leg-ext', 'Leg Extension', 3, '12–15', '140', false, 'leg-extension'),
      te(planId('thu'), 'seated-leg-curl', 'Seated Leg Curl', 3, '12–15', '100', false, 'seated-leg-curl'),
      te(planId('thu'), 'db-lat', 'DB Lateral Raise', 3, '15–20', '20', false, 'lateral-raise'),
      te(planId('thu'), 'rear-delt-fly', 'Rear Delt Fly', 3, '15', '20', false, 'rear-delt-fly'),
    ],
  },
  {
    id: planId('fri'),
    name: 'Friday: Shoulder Specialization',
    folderId: JOEY_SUMMER_PLAN2_FOLDER.id,
    notes: `${SUPERSET_NOTE}\n\nThis is the money day—prioritize quality reps on pressing and lateral work.\n\nFinisher: Cable Crunch 3 × 12 after supersets.\n\nActivity: Shoulder specialization (~60 min).`,
    exercises: [
      te(planId('fri'), 'seated-ohp', 'Seated DB Shoulder Press', 4, '6–10', '40', false, 'seated-dumbbell-shoulder-press'),
      te(planId('fri'), 'cable-lat-a', 'Cable Lateral Raise', 4, '15–20', '15', false, 'cable-lateral-raise'),
      te(planId('fri'), 'incline-db', 'Incline DB Press', 3, '8–12', '55', false, 'incline-dumbbell-press'),
      te(planId('fri'), 'rear-delt', 'Rear Delt Fly', 3, '12–15', '20', false, 'rear-delt-fly'),
      te(planId('fri'), 'machine-chest', 'Machine Chest Press', 3, '10–12', '120', false, 'machine-chest-press'),
      te(planId('fri'), 'lean-away-lat', 'Lean-Away Lateral Raise', 3, '12–15', '15', false, 'leaning-dumbbell-lateral-raise'),
      te(planId('fri'), 'oh-cable-tri', 'Overhead Cable Extension', 3, '10–12', '55', false, 'overhead-cable-tricep-extension'),
      te(planId('fri'), 'rope-push', 'Rope Pushdown', 3, '12–15', '65', false, 'tricep-pushdown'),
      te(planId('fri'), 'cable-crunch-fin', 'Cable Crunch (Finisher)', 3, '12', '85', false, 'cable-crunch'),
    ],
  },
  {
    id: planId('sat'),
    name: 'Saturday: Pull + Arms',
    folderId: JOEY_SUMMER_PLAN2_FOLDER.id,
    notes: `${SUPERSET_NOTE}\n\nFinisher: Hanging Leg Raise 3 × 15 after supersets.\n\nActivity: Pull & arms (~60 min).`,
    exercises: [
      te(planId('sat'), 'chest-row', 'Chest Supported Row', 4, '8–12', '100', false, 'chest-supported-row'),
      te(planId('sat'), 'preacher', 'Preacher Curl', 4, '10–12', '50', false, 'preacher-curl'),
      te(planId('sat'), 'single-pulldown', 'Single Arm Pulldown', 3, '10–12', '60', false, 'single-arm-lat-pulldown'),
      te(planId('sat'), 'oh-cable-tri', 'Overhead Cable Extension', 3, '10–12', '55', false, 'overhead-cable-tricep-extension'),
      te(planId('sat'), 'neutral-pulldown', 'Neutral Grip Pulldown', 3, '10–12', '100', false, 'neutral-grip-lat-pulldown'),
      te(planId('sat'), 'hammer', 'Hammer Curl', 3, '10–12', '25', false, 'hammer-curl'),
      te(planId('sat'), 'face-pull', 'Face Pull', 3, '15', '100', false, 'face-pull'),
      te(planId('sat'), 'rope-push', 'Rope Pushdown', 3, '12–15', '65', false, 'tricep-pushdown'),
      te(planId('sat'), 'hanging-leg-fin', 'Hanging Leg Raise (Finisher)', 3, '15', '0', false, 'leg-raise'),
    ],
  },
]
