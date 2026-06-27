import type { TemplateExercise, TemplateFolder, WorkoutTemplate } from '@/types/workout'

function row(n: number, reps: string, weight: string) {
  return Array.from({ length: n }, () => ({ targetReps: reps, targetWeight: weight }))
}

type TeOpts = {
  isCircuit?: boolean
  libraryId?: string
  isCardio?: boolean
  isCore?: boolean
  targetDuration?: string
}

function te(
  planId: string,
  slug: string,
  name: string,
  sets: number,
  reps: string,
  weight: string,
  opts: TeOpts = {},
): TemplateExercise {
  return {
    id: `${planId}__${slug}`,
    name,
    libraryId: opts.libraryId,
    isCircuit: opts.isCircuit,
    isCardio: opts.isCardio,
    isCore: opts.isCore,
    targetDuration: opts.targetDuration,
    sets: row(sets, reps, weight),
  }
}

function supersetPair(
  planId: string,
  label: string,
  a: {
    slug: string
    name: string
    sets: number
    reps: string
    weight: string
    opts?: TeOpts
  },
  b: {
    slug: string
    name: string
    sets: number
    reps: string
    weight: string
    opts?: TeOpts
  },
): TemplateExercise[] {
  const groupId = `${planId}__ss-${label.toLowerCase()}`
  return [
    {
      ...te(planId, a.slug, a.name, a.sets, a.reps, a.weight, a.opts),
      supersetGroupId: groupId,
      supersetLabel: label,
      supersetOrder: 1,
    },
    {
      ...te(planId, b.slug, b.name, b.sets, b.reps, b.weight, b.opts),
      supersetGroupId: groupId,
      supersetLabel: label,
      supersetOrder: 2,
    },
  ]
}

export const JOEY_SUMMER_PLAN2_FOLDER: TemplateFolder = {
  id: 'folder-joey-summer-plan-2',
  name: 'Joey Summer Plan 2',
  purpose:
    'Seven-day summer split: upper chest and delts, lat width, recovery, legs, shoulder specialization, pull + arms, and active recovery. Superset pairings are linked in the log.',
}

const SUPERSET_HINT =
  'Superset blocks are linked in your log—alternate the two moves with minimal rest, then rest before the next round.'

function planId(day: string): string {
  return `plan-joey-summer2-${day}`
}

export const JOEY_SUMMER_PLAN2_PLANS: WorkoutTemplate[] = [
  {
    id: planId('mon'),
    name: 'Monday: Upper Chest + Delts + Abs',
    folderId: JOEY_SUMMER_PLAN2_FOLDER.id,
    notes: `${SUPERSET_HINT}\n\nSuperset A (Heavy): rest 90 sec between rounds.\nCable Crunch: slow eccentric.\n\nFinish: Incline walk 10 min @ 10–12% incline.\n\nGoal: Build clavicular chest + widen shoulders (~60–70 min).`,
    exercises: [
      ...supersetPair(
        planId('mon'),
        'A',
        {
          slug: 'incline-db',
          name: 'Incline DB Press',
          sets: 4,
          reps: '6–10',
          weight: '55',
          opts: { libraryId: 'incline-dumbbell-press' },
        },
        {
          slug: 'cable-lat-a',
          name: 'Cable Lateral Raise',
          sets: 4,
          reps: '15–20',
          weight: '15',
          opts: { libraryId: 'cable-lateral-raise' },
        },
      ),
      ...supersetPair(
        planId('mon'),
        'B',
        {
          slug: 'incline-machine',
          name: 'Incline Machine Press',
          sets: 3,
          reps: '8–12',
          weight: '95',
          opts: { libraryId: 'incline-machine-press' },
        },
        {
          slug: 'rear-delt-machine',
          name: 'Rear Delt Fly Machine',
          sets: 3,
          reps: '12–15',
          weight: '50',
          opts: { libraryId: 'reverse-fly-machine' },
        },
      ),
      ...supersetPair(
        planId('mon'),
        'C',
        {
          slug: 'low-high-fly',
          name: 'Low-to-High Cable Fly',
          sets: 3,
          reps: '12–15',
          weight: '25',
          opts: { libraryId: 'low-to-high-cable-fly' },
        },
        {
          slug: 'machine-pullover',
          name: 'Machine Pullover',
          sets: 3,
          reps: '12–15',
          weight: '70',
          opts: { libraryId: 'machine-pullover' },
        },
      ),
      ...supersetPair(
        planId('mon'),
        'D',
        {
          slug: 'cable-crunch',
          name: 'Cable Crunch',
          sets: 4,
          reps: '10–15',
          weight: '85',
          opts: { libraryId: 'cable-crunch', isCore: true },
        },
        {
          slug: 'hanging-leg-raise',
          name: 'Hanging Leg Raise',
          sets: 3,
          reps: '10–15',
          weight: '0',
          opts: { libraryId: 'leg-raise', isCore: true },
        },
      ),
      te(planId('mon'), 'incline-walk-fin', 'Incline Walk', 1, '10 min', '0', {
        libraryId: 'incline-treadmill-walk',
        isCardio: true,
        targetDuration: '10',
      }),
    ],
  },
  {
    id: planId('tue'),
    name: 'Tuesday: Lat Width + Biceps + Obliques',
    folderId: JOEY_SUMMER_PLAN2_FOLDER.id,
    notes: `${SUPERSET_HINT}\n\nOptional finish: 10–15 min incline walk.\n\nGoal: Maximum V taper (~55–65 min).`,
    exercises: [
      ...supersetPair(
        planId('tue'),
        'A',
        {
          slug: 'single-lat',
          name: 'Single Arm Lat Pulldown',
          sets: 4,
          reps: '10–12',
          weight: '60',
          opts: { libraryId: 'single-arm-lat-pulldown' },
        },
        {
          slug: 'incline-db-curl',
          name: 'Incline DB Curl',
          sets: 3,
          reps: '10–12',
          weight: '25',
          opts: { libraryId: 'incline-dumbbell-curl' },
        },
      ),
      ...supersetPair(
        planId('tue'),
        'B',
        {
          slug: 'neutral-lat',
          name: 'Neutral Grip Pulldown',
          sets: 4,
          reps: '8–12',
          weight: '100',
          opts: { libraryId: 'neutral-grip-lat-pulldown' },
        },
        {
          slug: 'hammer',
          name: 'Hammer Curl',
          sets: 3,
          reps: '10–12',
          weight: '25',
          opts: { libraryId: 'hammer-curl' },
        },
      ),
      ...supersetPair(
        planId('tue'),
        'C',
        {
          slug: 'lat-row',
          name: 'Chest Supported Lat Row',
          sets: 3,
          reps: '10–12',
          weight: '100',
          opts: { libraryId: 'chest-supported-lat-row' },
        },
        {
          slug: 'ab-wheel',
          name: 'Ab Wheel',
          sets: 4,
          reps: '8–15',
          weight: '0',
          opts: { libraryId: 'ab-wheel-rollout', isCore: true },
        },
      ),
      ...supersetPair(
        planId('tue'),
        'D',
        {
          slug: 'face-pull',
          name: 'Face Pull',
          sets: 4,
          reps: '15',
          weight: '100',
          opts: { libraryId: 'face-pull' },
        },
        {
          slug: 'cable-side-crunch',
          name: 'Cable Side Crunch',
          sets: 3,
          reps: '12–15/side',
          weight: '35',
          opts: { libraryId: 'cable-side-crunch', isCore: true },
        },
      ),
    ],
  },
  {
    id: planId('wed'),
    name: 'Wednesday: Recovery + Abs',
    folderId: JOEY_SUMMER_PLAN2_FOLDER.id,
    notes:
      'Incline walk 30 min at a comfortable pace. Then complete the ab circuit for 4 rounds—minimal rest between stations, brief rest between rounds. No failure.\n\nGoal: Look better tomorrow (~40 min).',
    exercises: [
      te(planId('wed'), 'incline-walk', 'Incline Walk', 1, '30 min', '0', {
        libraryId: 'incline-treadmill-walk',
        isCardio: true,
        targetDuration: '30',
      }),
      te(planId('wed'), 'ab-wheel-c', 'Ab Wheel', 4, '10', '0', {
        isCircuit: true,
        libraryId: 'ab-wheel-rollout',
        isCore: true,
      }),
      te(planId('wed'), 'cable-crunch-c', 'Cable Crunch', 4, '15', '85', {
        isCircuit: true,
        libraryId: 'cable-crunch',
        isCore: true,
      }),
      te(planId('wed'), 'side-plank', 'Side Plank', 4, '45 sec', '0', {
        isCircuit: true,
        libraryId: 'side-plank',
        isCore: true,
      }),
      te(planId('wed'), 'dead-bug', 'Dead Bug', 4, '15', '0', {
        isCircuit: true,
        libraryId: 'dead-bug',
        isCore: true,
      }),
    ],
  },
  {
    id: planId('thu'),
    name: 'Thursday: Legs + Delts',
    folderId: JOEY_SUMMER_PLAN2_FOLDER.id,
    notes: `${SUPERSET_HINT}\n\nSuperset A: start fresh on RDLs.\n\nFinish: Incline walk 10 min.\n\nGoal: Maintain legs, build aesthetic frame (~60–70 min).`,
    exercises: [
      ...supersetPair(
        planId('thu'),
        'A',
        {
          slug: 'rdl',
          name: 'Romanian Deadlift',
          sets: 4,
          reps: '8–10',
          weight: '135',
          opts: { libraryId: 'romanian-deadlift' },
        },
        {
          slug: 'cable-lat',
          name: 'Cable Lateral Raise',
          sets: 4,
          reps: '15–20',
          weight: '15',
          opts: { libraryId: 'cable-lateral-raise' },
        },
      ),
      ...supersetPair(
        planId('thu'),
        'B',
        {
          slug: 'leg-press',
          name: 'Leg Press',
          sets: 4,
          reps: '10–12',
          weight: '275',
          opts: { libraryId: 'leg-press' },
        },
        {
          slug: 'calf-raise',
          name: 'Standing Calf Raise',
          sets: 4,
          reps: '12–20',
          weight: '225',
          opts: { libraryId: 'calf-raise' },
        },
      ),
      ...supersetPair(
        planId('thu'),
        'C',
        {
          slug: 'leg-ext',
          name: 'Leg Extension',
          sets: 3,
          reps: '12–15',
          weight: '140',
          opts: { libraryId: 'leg-extension' },
        },
        {
          slug: 'db-lat',
          name: 'DB Lateral Raise',
          sets: 3,
          reps: '15–20',
          weight: '20',
          opts: { libraryId: 'lateral-raise' },
        },
      ),
      ...supersetPair(
        planId('thu'),
        'D',
        {
          slug: 'seated-leg-curl',
          name: 'Seated Leg Curl',
          sets: 3,
          reps: '12–15',
          weight: '100',
          opts: { libraryId: 'seated-leg-curl' },
        },
        {
          slug: 'rear-delt-fly',
          name: 'Rear Delt Fly',
          sets: 3,
          reps: '15',
          weight: '20',
          opts: { libraryId: 'rear-delt-fly' },
        },
      ),
      te(planId('thu'), 'incline-walk-fin', 'Incline Walk', 1, '10 min', '0', {
        libraryId: 'incline-treadmill-walk',
        isCardio: true,
        targetDuration: '10',
      }),
    ],
  },
  {
    id: planId('fri'),
    name: 'Friday: Shoulder Specialization',
    folderId: JOEY_SUMMER_PLAN2_FOLDER.id,
    notes: `${SUPERSET_HINT}\n\nThis is the money day—prioritize quality reps on pressing and lateral work.\n\nFinisher: Cable Crunch 3 × 12 after supersets.\n\nGoal: Look ridiculous in a T-shirt (~65–75 min).`,
    exercises: [
      ...supersetPair(
        planId('fri'),
        'A',
        {
          slug: 'seated-ohp',
          name: 'Seated DB Shoulder Press',
          sets: 4,
          reps: '6–10',
          weight: '40',
          opts: { libraryId: 'seated-dumbbell-shoulder-press' },
        },
        {
          slug: 'cable-lat-a',
          name: 'Cable Lateral Raise',
          sets: 4,
          reps: '15–20',
          weight: '15',
          opts: { libraryId: 'cable-lateral-raise' },
        },
      ),
      ...supersetPair(
        planId('fri'),
        'B',
        {
          slug: 'incline-db',
          name: 'Incline DB Press',
          sets: 3,
          reps: '8–12',
          weight: '55',
          opts: { libraryId: 'incline-dumbbell-press' },
        },
        {
          slug: 'rear-delt',
          name: 'Rear Delt Fly',
          sets: 3,
          reps: '12–15',
          weight: '20',
          opts: { libraryId: 'rear-delt-fly' },
        },
      ),
      ...supersetPair(
        planId('fri'),
        'C',
        {
          slug: 'machine-pullover',
          name: 'Machine Pullover',
          sets: 3,
          reps: '12–15',
          weight: '70',
          opts: { libraryId: 'machine-pullover' },
        },
        {
          slug: 'lean-away-lat',
          name: 'Lean Away Lateral Raise',
          sets: 3,
          reps: '12–15',
          weight: '15',
          opts: { libraryId: 'leaning-dumbbell-lateral-raise' },
        },
      ),
      ...supersetPair(
        planId('fri'),
        'D',
        {
          slug: 'oh-cable-tri',
          name: 'Overhead Cable Extension',
          sets: 3,
          reps: '10–12',
          weight: '55',
          opts: { libraryId: 'overhead-cable-tricep-extension' },
        },
        {
          slug: 'face-pull',
          name: 'Face Pull',
          sets: 3,
          reps: '15',
          weight: '100',
          opts: { libraryId: 'face-pull' },
        },
      ),
      te(planId('fri'), 'cable-crunch-fin', 'Cable Crunch', 3, '12', '85', {
        libraryId: 'cable-crunch',
        isCore: true,
      }),
    ],
  },
  {
    id: planId('sat'),
    name: 'Saturday: Pull + Arms + Abs',
    folderId: JOEY_SUMMER_PLAN2_FOLDER.id,
    notes: `${SUPERSET_HINT}\n\nFinish: 15 min incline walk.\n\nGoal: Upper back density + lat flare (~60–70 min).`,
    exercises: [
      ...supersetPair(
        planId('sat'),
        'A',
        {
          slug: 'chest-row',
          name: 'Chest Supported Row',
          sets: 4,
          reps: '8–12',
          weight: '100',
          opts: { libraryId: 'chest-supported-row' },
        },
        {
          slug: 'preacher',
          name: 'Preacher Curl',
          sets: 3,
          reps: '10–12',
          weight: '50',
          opts: { libraryId: 'preacher-curl' },
        },
      ),
      ...supersetPair(
        planId('sat'),
        'B',
        {
          slug: 'single-pulldown',
          name: 'Single Arm Pulldown',
          sets: 4,
          reps: '10–12',
          weight: '60',
          opts: { libraryId: 'single-arm-lat-pulldown' },
        },
        {
          slug: 'oh-cable-tri',
          name: 'Overhead Cable Extension',
          sets: 3,
          reps: '10–12',
          weight: '55',
          opts: { libraryId: 'overhead-cable-tricep-extension' },
        },
      ),
      ...supersetPair(
        planId('sat'),
        'C',
        {
          slug: 'machine-pullover',
          name: 'Machine Pullover',
          sets: 3,
          reps: '12–15',
          weight: '70',
          opts: { libraryId: 'machine-pullover' },
        },
        {
          slug: 'hammer',
          name: 'Hammer Curl',
          sets: 3,
          reps: '10–12',
          weight: '25',
          opts: { libraryId: 'hammer-curl' },
        },
      ),
      ...supersetPair(
        planId('sat'),
        'D',
        {
          slug: 'face-pull',
          name: 'Face Pull',
          sets: 3,
          reps: '15',
          weight: '100',
          opts: { libraryId: 'face-pull' },
        },
        {
          slug: 'weighted-decline-situp',
          name: 'Weighted Decline Sit-Up',
          sets: 3,
          reps: '12',
          weight: '25',
          opts: { libraryId: 'weighted-decline-situp', isCore: true },
        },
      ),
      te(planId('sat'), 'incline-walk-fin', 'Incline Walk', 1, '15 min', '0', {
        libraryId: 'incline-treadmill-walk',
        isCardio: true,
        targetDuration: '15',
      }),
    ],
  },
  {
    id: planId('sun'),
    name: 'Sunday: Active Recovery',
    folderId: JOEY_SUMMER_PLAN2_FOLDER.id,
    notes:
      '8–12k steps. Light stretching and mobility work—no hard training.\n\nGoal: Recover and move well.',
    exercises: [
      te(planId('sun'), 'steps', 'Daily Steps', 1, '8–12k', '0', {
        isCardio: true,
        targetDuration: '60',
      }),
    ],
  },
]
