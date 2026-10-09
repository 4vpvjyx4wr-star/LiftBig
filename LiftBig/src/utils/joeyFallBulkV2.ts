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
  targetTimeSeconds?: string
  preferredSwapLibraryIds?: string[]
  targetRestSeconds?: number
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
    targetTimeSeconds: opts.targetTimeSeconds,
    preferredSwapLibraryIds: opts.preferredSwapLibraryIds,
    targetRestSeconds: opts.targetRestSeconds,
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
  restSeconds?: number,
): TemplateExercise[] {
  const groupId = `${planId}__ss-${label.toLowerCase()}`
  const restOpts = restSeconds != null ? { targetRestSeconds: restSeconds } : {}
  return [
    {
      ...te(planId, a.slug, a.name, a.sets, a.reps, a.weight, { ...a.opts, ...restOpts }),
      supersetGroupId: groupId,
      supersetLabel: label,
      supersetOrder: 1,
    },
    {
      ...te(planId, b.slug, b.name, b.sets, b.reps, b.weight, { ...b.opts, ...restOpts }),
      supersetGroupId: groupId,
      supersetLabel: label,
      supersetOrder: 2,
    },
  ]
}

export const JOEY_FALL_BULK_V2_FOLDER: TemplateFolder = {
  id: 'folder-joey-fall-bulk-v2',
  name: 'Joey Fall Bulk v3',
  purpose:
    'Fall hypertrophy bulk v3: Monday upper chest / lat width / delts, Tuesday lower body / traps, Wednesday push (chest / shoulders / triceps / core), Thursday rest, Friday back / rear delts / biceps / traps, Saturday shoulders / arms / advanced core, Sunday recovery, plus an optional busy bonus day. Superset pairings, “or” swap alternatives, and prescribed rest timers are linked in the log.',
}

const SUPERSET_HINT =
  'Superset blocks are linked in your log—alternate the two moves with minimal rest, then rest before the next round. When a rest time is listed, a timer is waiting under that lift or superset (set to the lower end of the range).'

const SWAP_HINT =
  'Moves labeled with an “or” alternative: press Swap and pick the top similar movement to hot-swap.'

/** Lower bound of plan rest prescriptions (seconds). */
const REST_90 = 90
const REST_60 = 60

function planId(day: string): string {
  return `plan-joey-fall-bulk-v2-${day}`
}

export const JOEY_FALL_BULK_V2_PLANS: WorkoutTemplate[] = [
  {
    id: planId('mon'),
    name: 'Monday: Upper Chest, Lat Width & Delts',
    folderId: JOEY_FALL_BULK_V2_FOLDER.id,
    notes: `${SUPERSET_HINT}\n${SWAP_HINT}\n\nZone 1: Incline Dumbbell Bench Press — heavy, controlled, full ROM. ~1–2 RIR on most sets; last set can approach 0–1 RIR. Rest 90–120 sec.\nSuperset A: rest 60–90 sec after A2.\nSuperset B: rest 60–90 sec after B2.\nSuperset C: rest 60–90 sec after C2.\n\nOptional finish: 5–10 min incline treadmill walk or stair climber.\n\nGoal: Upper chest, lat width, side delts, and core.`,
    exercises: [
      te(planId('mon'), 'incline-db', 'Incline Dumbbell Bench Press', 3, '6–8', '55', {
        libraryId: 'incline-dumbbell-press',
        targetRestSeconds: REST_90,
      }),
      ...supersetPair(
        planId('mon'),
        'A',
        {
          slug: 'neutral-lat',
          name: 'Neutral-Grip Lat Pulldown',
          sets: 3,
          reps: '8–10',
          weight: '100',
          opts: {
            libraryId: 'neutral-grip-lat-pulldown',
            preferredSwapLibraryIds: ['single-arm-lat-pulldown'],
          },
        },
        {
          slug: 'db-lat',
          name: 'Dumbbell Lateral Raise',
          sets: 3,
          reps: '10–15',
          weight: '20',
          opts: {
            libraryId: 'lateral-raise',
            preferredSwapLibraryIds: ['cable-lateral-raise'],
          },
        },
        REST_60,
      ),
      ...supersetPair(
        planId('mon'),
        'B',
        {
          slug: 'low-high-fly',
          name: 'Low-to-High Cable Fly',
          sets: 3,
          reps: '10–15',
          weight: '25',
          opts: { libraryId: 'low-to-high-cable-fly' },
        },
        {
          slug: 'captains-lr',
          name: "Captain's Chair Leg Raise",
          sets: 3,
          reps: '10–15',
          weight: '0',
          opts: {
            libraryId: 'captains-chair-leg-raise',
            isCore: true,
            preferredSwapLibraryIds: ['leg-raise', 'weighted-decline-situp'],
          },
        },
        REST_60,
      ),
      ...supersetPair(
        planId('mon'),
        'C',
        {
          slug: 'face-pull',
          name: 'Cable Face Pull',
          sets: 3,
          reps: '10–15',
          weight: '40',
          opts: { libraryId: 'face-pull' },
        },
        {
          slug: 'cable-crunch',
          name: 'Kneeling Cable Crunch',
          sets: 3,
          reps: '10–15',
          weight: '85',
          opts: {
            libraryId: 'cable-crunch',
            isCore: true,
            preferredSwapLibraryIds: ['ab-wheel-rollout'],
          },
        },
        REST_60,
      ),
      te(planId('mon'), 'incline-walk-fin', 'Incline Walk', 1, '5–10 min', '0', {
        libraryId: 'incline-treadmill-walk',
        isCardio: true,
        targetDuration: '5',
        preferredSwapLibraryIds: ['stairmaster'],
      }),
    ],
  },
  {
    id: planId('tue'),
    name: 'Tuesday: Lower Body, Quads/Calves & Traps',
    folderId: JOEY_FALL_BULK_V2_FOLDER.id,
    notes: `${SUPERSET_HINT}\n${SWAP_HINT}\n\nSuperset A: rest 90–120 sec after A2.\nSuperset B: rest 90–120 sec after B2.\nSuperset C: rest 60–90 sec after C2.\n\nOptional finish: 5–10 min StairMaster or incline treadmill.\n\nGoal: Quads, posterior chain, calves, and traps.`,
    exercises: [
      ...supersetPair(
        planId('tue'),
        'A',
        {
          slug: 'hack-squat',
          name: 'Hack Squat',
          sets: 3,
          reps: '6–8',
          weight: '180',
          opts: {
            libraryId: 'hack-squat',
            preferredSwapLibraryIds: ['leg-press'],
          },
        },
        {
          slug: 'calf-raise',
          name: 'Standing Calf Raise',
          sets: 3,
          reps: '10–15',
          weight: '180',
          opts: {
            libraryId: 'standing-calf-raise',
            preferredSwapLibraryIds: ['calf-raise'],
          },
        },
        REST_90,
      ),
      ...supersetPair(
        planId('tue'),
        'B',
        {
          slug: 'db-rdl',
          name: 'Dumbbell Romanian Deadlift',
          sets: 3,
          reps: '8–10',
          weight: '50',
          opts: {
            libraryId: 'dumbbell-romanian-deadlift',
            preferredSwapLibraryIds: ['romanian-deadlift'],
          },
        },
        {
          slug: 'db-shrug',
          name: 'Dumbbell Shrug',
          sets: 3,
          reps: '10–15',
          weight: '40',
          opts: {
            libraryId: 'dumbbell-shrug',
            preferredSwapLibraryIds: ['barbell-shrug'],
          },
        },
        REST_90,
      ),
      ...supersetPair(
        planId('tue'),
        'C',
        {
          slug: 'walk-lunge',
          name: 'Dumbbell Walking Lunge',
          sets: 3,
          reps: '10–12/leg',
          weight: '40',
          opts: { libraryId: 'walking-lunge' },
        },
        {
          slug: 'seated-curl',
          name: 'Seated Leg Curl',
          sets: 3,
          reps: '10–15',
          weight: '100',
          opts: {
            libraryId: 'seated-leg-curl',
            preferredSwapLibraryIds: ['hamstring-curl'],
          },
        },
        REST_60,
      ),
      te(planId('tue'), 'stair-fin', 'StairMaster', 1, '5–10 min', '0', {
        libraryId: 'stairmaster',
        isCardio: true,
        targetDuration: '5',
        preferredSwapLibraryIds: ['incline-treadmill-walk'],
      }),
    ],
  },
  {
    id: planId('wed'),
    name: 'Wednesday: Push — Chest, Shoulders, Triceps & Core',
    folderId: JOEY_FALL_BULK_V2_FOLDER.id,
    notes: `${SUPERSET_HINT}\n${SWAP_HINT}\n\nZone 1: Incline Smith Machine Press — rest 90–120 sec.\nSuperset A: rest 60–90 sec after A2.\nSuperset B: rest 60–90 sec after B2.\nSuperset C: core + triceps.\n\nGoal: Chest, delts, triceps, and core.`,
    exercises: [
      te(planId('wed'), 'smith-incline', 'Incline Smith Machine Press', 3, '8–10', '95', {
        libraryId: 'smith-machine-incline-bench',
        targetRestSeconds: REST_90,
      }),
      ...supersetPair(
        planId('wed'),
        'A',
        {
          slug: 'flat-db',
          name: 'Flat Dumbbell Bench Press',
          sets: 3,
          reps: '8–10',
          weight: '45',
          opts: { libraryId: 'flat-dumbbell-press' },
        },
        {
          slug: 'incline-fly',
          name: 'Incline Dumbbell Chest Fly',
          sets: 3,
          reps: '10–15',
          weight: '20',
          opts: { libraryId: 'incline-dumbbell-fly' },
        },
        REST_60,
      ),
      ...supersetPair(
        planId('wed'),
        'B',
        {
          slug: 'seated-ohp',
          name: 'Seated DB Shoulder Press',
          sets: 3,
          reps: '8–10',
          weight: '40',
          opts: { libraryId: 'seated-dumbbell-shoulder-press' },
        },
        {
          slug: 'cable-lat',
          name: 'Cable Lateral Raise',
          sets: 3,
          reps: '12–20',
          weight: '15',
          opts: {
            libraryId: 'cable-lateral-raise',
            preferredSwapLibraryIds: ['lateral-raise'],
          },
        },
        REST_60,
      ),
      ...supersetPair(
        planId('wed'),
        'C',
        {
          slug: 'oh-rope',
          name: 'Overhead Rope Triceps Extension',
          sets: 3,
          reps: '10–15',
          weight: '40',
          opts: { libraryId: 'overhead-cable-tricep-extension' },
        },
        {
          slug: 'cable-crunch',
          name: 'Cable Ab Crunches',
          sets: 3,
          reps: '8–15',
          weight: '85',
          opts: {
            libraryId: 'cable-crunch',
            isCore: true,
            preferredSwapLibraryIds: ['ab-wheel-rollout'],
          },
        },
      ),
    ],
  },
  {
    id: planId('thu'),
    name: 'Thursday: Complete Rest',
    folderId: JOEY_FALL_BULK_V2_FOLDER.id,
    notes: 'Complete rest. No lifting. Sleep, eat, and recover for Friday’s back session.',
    exercises: [],
  },
  {
    id: planId('fri'),
    name: 'Friday: Back Width/Thickness, Rear Delts, Biceps & Traps',
    folderId: JOEY_FALL_BULK_V2_FOLDER.id,
    notes: `${SUPERSET_HINT}\n${SWAP_HINT}\n\nAfter chest-supported rows, the scapular retractors are primed. Treat Kelso shrugs as a mechanical drop set: row to near failure, then 12–20 controlled scapular retractions without bending the elbows.\n\nSuperset A: rest 90 sec after the Kelso shrug.\nSuperset B: rest 60–90 sec.\nSuperset C: rest 60–90 sec.\nSuperset D: rest 60–90 sec.\n\nGoal: Lat width, mid-back thickness, rear delts, biceps, and traps.`,
    exercises: [
      ...supersetPair(
        planId('fri'),
        'A',
        {
          slug: 'chest-row',
          name: 'Chest-Supported Machine Row',
          sets: 3,
          reps: '8–10',
          weight: '100',
          opts: {
            libraryId: 'chest-supported-lat-row',
            preferredSwapLibraryIds: ['chest-supported-row'],
          },
        },
        {
          slug: 'kelso',
          name: 'Kelso Shrug',
          sets: 3,
          reps: '12–20',
          weight: '100',
          opts: { libraryId: 'kelso-shrug' },
        },
        REST_90,
      ),
      ...supersetPair(
        planId('fri'),
        'B',
        {
          slug: 'neutral-lat',
          name: 'Neutral-Grip Lat Pulldown',
          sets: 3,
          reps: '8–10',
          weight: '100',
          opts: { libraryId: 'neutral-grip-lat-pulldown' },
        },
        {
          slug: 'rear-delt',
          name: 'Seated Dumbbell Rear-Delt Fly',
          sets: 3,
          reps: '12–15',
          weight: '20',
          opts: { libraryId: 'rear-delt-fly' },
        },
        REST_60,
      ),
      ...supersetPair(
        planId('fri'),
        'C',
        {
          slug: 'sa-row',
          name: 'Single-Arm Dumbbell Row',
          sets: 3,
          reps: '8–12/arm',
          weight: '50',
          opts: { libraryId: 'dumbbell-row' },
        },
        {
          slug: 'incline-curl',
          name: 'Incline Dumbbell Curl',
          sets: 3,
          reps: '10–12',
          weight: '25',
          opts: { libraryId: 'incline-dumbbell-curl' },
        },
        REST_60,
      ),
      ...supersetPair(
        planId('fri'),
        'D',
        {
          slug: 'straight-arm',
          name: 'Straight-Arm Cable Pulldown',
          sets: 3,
          reps: '10–15',
          weight: '40',
          opts: { libraryId: 'lat-prayer-stretch-cable' },
        },
        {
          slug: 'face-pull',
          name: 'Cable Face Pull',
          sets: 3,
          reps: '10–15',
          weight: '40',
          opts: { libraryId: 'face-pull' },
        },
        REST_60,
      ),
    ],
  },
  {
    id: planId('sat'),
    name: 'Saturday: Shoulders, Arms & Advanced Core',
    folderId: JOEY_FALL_BULK_V2_FOLDER.id,
    notes: `${SUPERSET_HINT}\n${SWAP_HINT}\n\nSuperset A: rest 60–90 sec.\nSuperset B: rest 60–90 sec.\n\nAdvanced core circuit: 2–3 rounds — Dragon Flags 5–8, Weighted Russian Twists 15–20 total, RKC Plank 30–45 sec, Hanging or Captain's Chair Leg Raise 10–15. Minimal rest between movements; rest ~60–90 sec between rounds.\n\nOptional finish: 5–10 min StairMaster or incline treadmill.`,
    exercises: [
      ...supersetPair(
        planId('sat'),
        'A',
        {
          slug: 'seated-ohp',
          name: 'Seated Dumbbell Shoulder Press',
          sets: 3,
          reps: '8–10',
          weight: '40',
          opts: { libraryId: 'seated-dumbbell-shoulder-press' },
        },
        {
          slug: 'incline-curl',
          name: 'Incline Dumbbell Biceps Curl',
          sets: 3,
          reps: '10–12',
          weight: '25',
          opts: { libraryId: 'incline-dumbbell-curl' },
        },
        REST_60,
      ),
      ...supersetPair(
        planId('sat'),
        'B',
        {
          slug: 'cable-hammer',
          name: 'Cable Hammer Curl — Rope',
          sets: 3,
          reps: '10–15',
          weight: '30',
          opts: { libraryId: 'cable-hammer-curl' },
        },
        {
          slug: 'lean-away',
          name: 'Lean-Away Cable Lateral Raise',
          sets: 3,
          reps: '12–15',
          weight: '15',
          opts: { libraryId: 'lean-away-cable-lateral-raise' },
        },
        REST_60,
      ),
      te(planId('sat'), 'dragon-flag', 'Dragon Flags', 3, '5–8', '0', {
        isCircuit: true,
        libraryId: 'dragon-flag',
        isCore: true,
        targetRestSeconds: REST_60,
      }),
      te(planId('sat'), 'w-russian', 'Weighted Russian Twists', 3, '15–20', '20', {
        isCircuit: true,
        libraryId: 'weighted-russian-twist',
        isCore: true,
        targetRestSeconds: REST_60,
      }),
      te(planId('sat'), 'rkc', 'RKC Plank', 3, '30–45 sec', '0', {
        isCircuit: true,
        libraryId: 'rkc-plank',
        isCore: true,
        targetTimeSeconds: '30',
        targetRestSeconds: REST_60,
      }),
      te(planId('sat'), 'hanging-lr', 'Hanging Leg Raise', 3, '10–15', '0', {
        isCircuit: true,
        libraryId: 'leg-raise',
        isCore: true,
        preferredSwapLibraryIds: ['captains-chair-leg-raise'],
        targetRestSeconds: REST_60,
      }),
      te(planId('sat'), 'stair-fin', 'StairMaster', 1, '5–10 min', '0', {
        libraryId: 'stairmaster',
        isCardio: true,
        targetDuration: '5',
        preferredSwapLibraryIds: ['incline-treadmill-walk'],
      }),
    ],
  },
  {
    id: planId('sun'),
    name: 'Sunday: Rest / Active Recovery',
    folderId: JOEY_FALL_BULK_V2_FOLDER.id,
    notes:
      'Easy walking, mobility, and stretching if desired. Keep intensity low—no required lifting. Recover for Monday.',
    exercises: [
      te(planId('sun'), 'walk', 'Easy Walk', 1, '30–45 min', '0', {
        libraryId: 'walking',
        isCardio: true,
        targetDuration: '30',
      }),
      te(planId('sun'), 'mobility', 'Mobility / Stretching', 1, '15–20 min', '0', {
        libraryId: 'yoga-flow',
        isCardio: true,
        targetDuration: '15',
      }),
    ],
  },
  {
    id: planId('bonus'),
    name: 'Optional Busy Bonus Day',
    folderId: JOEY_FALL_BULK_V2_FOLDER.id,
    notes: `${SUPERSET_HINT}\n${SWAP_HINT}\n\n20–25 min — use this when medical school destroys the schedule. This replaces a normal session; do not stack it on top of five training days.\n\nSuperset A: 3–4 rounds — DB Incline/Flat Bench Press 12–15 @ 20 lb, Single-Arm DB Row 12–15/side @ 20 lb.\nSuperset B: 3 rounds — Bulgarian Split Squat 10–15/leg (20 lb or bodyweight), IYT Raises 12–20 @ 8 lb.\nSuperset C: 3 rounds — DB Hammer Curl 10–15 @ 20 lb, Overhead DB Triceps Extension 12–15 @ 20 lb.\n\nCore finisher: RKC plank near failure, then standard plank near failure.`,
    exercises: [
      ...supersetPair(
        planId('bonus'),
        'A',
        {
          slug: 'db-press',
          name: 'DB Incline Bench Press',
          sets: 4,
          reps: '12–15',
          weight: '20',
          opts: {
            libraryId: 'incline-dumbbell-press',
            preferredSwapLibraryIds: ['flat-dumbbell-press'],
          },
        },
        {
          slug: 'sa-row',
          name: 'Single-Arm DB Row',
          sets: 4,
          reps: '12–15/side',
          weight: '20',
          opts: { libraryId: 'dumbbell-row' },
        },
      ),
      ...supersetPair(
        planId('bonus'),
        'B',
        {
          slug: 'bss',
          name: 'Bulgarian Split Squat',
          sets: 3,
          reps: '10–15/leg',
          weight: '20',
          opts: { libraryId: 'bulgarian-split-squat' },
        },
        {
          slug: 'iyt',
          name: 'IYT Raises',
          sets: 3,
          reps: '12–20',
          weight: '8',
          opts: { libraryId: 'iyt-raises' },
        },
      ),
      ...supersetPair(
        planId('bonus'),
        'C',
        {
          slug: 'hammer',
          name: 'DB Hammer Curl',
          sets: 3,
          reps: '10–15',
          weight: '20',
          opts: { libraryId: 'hammer-curl' },
        },
        {
          slug: 'oh-db-tri',
          name: 'Overhead DB Triceps Extension',
          sets: 3,
          reps: '12–15',
          weight: '20',
          opts: { libraryId: 'overhead-dumbbell-tricep-extension' },
        },
      ),
      te(planId('bonus'), 'rkc', 'RKC Plank', 1, 'near failure', '0', {
        isCircuit: true,
        libraryId: 'rkc-plank',
        isCore: true,
        targetTimeSeconds: '30',
      }),
      te(planId('bonus'), 'plank', 'Standard Plank', 1, 'near failure', '0', {
        isCircuit: true,
        libraryId: 'plank',
        isCore: true,
        targetTimeSeconds: '45',
      }),
    ],
  },
]
