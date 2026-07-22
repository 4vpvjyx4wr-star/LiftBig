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

export const JOEY_FALL_BULK_FOLDER: TemplateFolder = {
  id: 'folder-joey-fall-bulk',
  name: 'Joey Fall Bulk',
  purpose:
    'Fall hypertrophy bulk: upper chest/delts, back width/thickness, lower body, shoulders/arms, optional pull + advanced core, plus a busy-day dumbbell bonus. Superset pairings and “or” swap alternatives are linked in the log.',
}

const SUPERSET_HINT =
  'Superset blocks are linked in your log—alternate the two moves with minimal rest, then rest before the next round.'

const SWAP_HINT =
  'Moves labeled with an “or” alternative: press Swap and pick the top similar movement to hot-swap.'

function planId(day: string): string {
  return `plan-joey-fall-bulk-${day}`
}

export const JOEY_FALL_BULK_PLANS: WorkoutTemplate[] = [
  {
    id: planId('mon'),
    name: 'Monday: Upper Chest / Delts / Abs',
    folderId: JOEY_FALL_BULK_FOLDER.id,
    notes: `${SUPERSET_HINT}\n${SWAP_HINT}\n\nSuperset A: rest 90 sec between rounds.\nSuperset B: rest 75 sec between rounds.\nSuperset C: rest 60 sec between rounds.\n\nOptional finish: 10–15 min incline walk.\n\nGoal: Upper chest + side delts + abs (~45–50 min).`,
    exercises: [
      ...supersetPair(
        planId('mon'),
        'A',
        {
          slug: 'incline-db',
          name: 'Incline DB Press',
          sets: 4,
          reps: '6–8',
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
          reps: '8–10',
          weight: '95',
          opts: { libraryId: 'incline-machine-press' },
        },
        {
          slug: 'lean-away-lat',
          name: 'Lean-Away DB Lateral Raise',
          sets: 3,
          reps: '12–15',
          weight: '15',
          opts: { libraryId: 'leaning-dumbbell-lateral-raise' },
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
          opts: {
            libraryId: 'low-to-high-cable-fly',
            preferredSwapLibraryIds: ['machine-fly'],
          },
        },
        {
          slug: 'rear-delt-machine',
          name: 'Rear Delt Fly Machine',
          sets: 3,
          reps: '15',
          weight: '50',
          opts: {
            libraryId: 'reverse-fly-machine',
            preferredSwapLibraryIds: ['rear-delt-fly'],
          },
        },
      ),
      ...supersetPair(
        planId('mon'),
        'D',
        {
          slug: 'cable-crunch',
          name: 'Cable Crunch',
          sets: 4,
          reps: '12–15',
          weight: '85',
          opts: { libraryId: 'cable-crunch', isCore: true },
        },
        {
          slug: 'pallof',
          name: 'Pallof Press',
          sets: 3,
          reps: '12/side',
          weight: '30',
          opts: { libraryId: 'pallof-press', isCore: true },
        },
      ),
      te(planId('mon'), 'incline-walk-fin', 'Incline Walk', 1, '10–15 min', '0', {
        libraryId: 'incline-treadmill-walk',
        isCardio: true,
        targetDuration: '12',
      }),
    ],
  },
  {
    id: planId('tue'),
    name: 'Tuesday: Back Width / Thickness / Biceps',
    folderId: JOEY_FALL_BULK_FOLDER.id,
    notes: `${SUPERSET_HINT}\n\nNOTE: After chest-supported rows, the scapular retractors are primed. Think of Kelso shrugs as a mechanical drop set: row to near failure, then perform 15–20 controlled scapular retractions without bending the elbows (same weight).\n\nSuperset A: rest 90 sec between rounds.\nSuperset B: rest 75 sec between rounds.\nSuperset C (row → Kelso): rest 90 sec between rounds.\n\nOptional finish: 10–15 min incline treadmill.\n\nGoal: Lat width + mid-back thickness + biceps (~50 min).`,
    exercises: [
      ...supersetPair(
        planId('tue'),
        'A',
        {
          slug: 'single-lat',
          name: 'Single Arm Lat Pulldown',
          sets: 4,
          reps: '8–12',
          weight: '60',
          opts: { libraryId: 'single-arm-lat-pulldown' },
        },
        {
          slug: 'incline-db-curl',
          name: 'Incline DB Curl',
          sets: 4,
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
          sets: 3,
          reps: '8–10',
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
          slug: 'chest-row',
          name: 'Chest Supported Row',
          sets: 3,
          reps: '8–10',
          weight: '100',
          opts: { libraryId: 'chest-supported-row' },
        },
        {
          slug: 'kelso',
          name: 'Kelso Shrugs',
          sets: 3,
          reps: '15–20',
          weight: '100',
          opts: { libraryId: 'kelso-shrug' },
        },
      ),
      ...supersetPair(
        planId('tue'),
        'D',
        {
          slug: 'face-pull',
          name: 'Face Pull',
          sets: 3,
          reps: '15–20',
          weight: '40',
          opts: { libraryId: 'face-pull' },
        },
        {
          slug: 'ab-wheel',
          name: 'Ab Wheel',
          sets: 3,
          reps: '10–15',
          weight: '0',
          opts: { libraryId: 'ab-wheel-rollout', isCore: true },
        },
      ),
      te(planId('tue'), 'incline-walk-fin', 'Incline Treadmill', 1, '10–15 min', '0', {
        libraryId: 'incline-treadmill-walk',
        isCardio: true,
        targetDuration: '12',
      }),
    ],
  },
  {
    id: planId('wed'),
    name: 'Wednesday: Lower Body',
    folderId: JOEY_FALL_BULK_FOLDER.id,
    notes: `${SUPERSET_HINT}\n${SWAP_HINT}\n\nSuperset A: rest 90 sec between rounds.\nSuperset B: rest 90 sec between rounds.\nSuperset C: rest 75 sec between rounds.\n\nOptional finish: 10–20 min incline walk.\n\nGoal: Quads, posterior chain, calves (~45–50 min).`,
    exercises: [
      ...supersetPair(
        planId('wed'),
        'A',
        {
          slug: 'leg-press',
          name: 'Leg Press',
          sets: 4,
          reps: '8–10',
          weight: '275',
          opts: {
            libraryId: 'leg-press',
            preferredSwapLibraryIds: ['hack-squat'],
          },
        },
        {
          slug: 'calf-raise',
          name: 'Standing Calf Raise',
          sets: 4,
          reps: '15–20',
          weight: '180',
          opts: { libraryId: 'standing-calf-raise' },
        },
      ),
      ...supersetPair(
        planId('wed'),
        'B',
        {
          slug: 'rdl',
          name: 'Romanian Deadlift',
          sets: 4,
          reps: '8–10',
          weight: '135',
          opts: { libraryId: 'romanian-deadlift' },
        },
        {
          slug: 'bb-shrug',
          name: 'Barbell Shrugs',
          sets: 4,
          reps: '12–15',
          weight: '135',
          opts: { libraryId: 'barbell-shrug' },
        },
      ),
      ...supersetPair(
        planId('wed'),
        'C',
        {
          slug: 'walk-lunge',
          name: 'DB Walking Lunges',
          sets: 3,
          reps: '12/leg',
          weight: '40',
          opts: { libraryId: 'walking-lunge' },
        },
        {
          slug: 'leg-curl',
          name: 'Leg Curl',
          sets: 3,
          reps: '12–15',
          weight: '100',
          opts: { libraryId: 'hamstring-curl' },
        },
      ),
      te(planId('wed'), 'incline-walk-fin', 'Incline Walk', 1, '10–20 min', '0', {
        libraryId: 'incline-treadmill-walk',
        isCardio: true,
        targetDuration: '15',
      }),
    ],
  },
  {
    id: planId('thu'),
    name: 'Thursday: Rest',
    folderId: JOEY_FALL_BULK_FOLDER.id,
    notes: 'Full rest day. Sleep, eat, and recover for Friday’s shoulders / chest / arms session.',
    exercises: [],
  },
  {
    id: planId('fri'),
    name: 'Friday: Shoulders / Chest / Arms',
    folderId: JOEY_FALL_BULK_FOLDER.id,
    notes: `${SUPERSET_HINT}\n${SWAP_HINT}\n\nSuperset A: rest 90 sec between rounds.\nSuperset B: rest 75 sec between rounds.\nSuperset C: rest 75 sec between rounds.\nSuperset D: rest 60–75 sec between rounds.\n\nOptional finish: 15 min Zone 2 cardio.\n\nGoal: Delts, chest, arms (~45–50 min).`,
    exercises: [
      ...supersetPair(
        planId('fri'),
        'A',
        {
          slug: 'seated-ohp',
          name: 'Seated DB Shoulder Press',
          sets: 4,
          reps: '6–8',
          weight: '40',
          opts: { libraryId: 'seated-dumbbell-shoulder-press' },
        },
        {
          slug: 'cable-lat',
          name: 'Cable Lateral Raise',
          sets: 4,
          reps: '15–20',
          weight: '15',
          opts: {
            libraryId: 'cable-lateral-raise',
            preferredSwapLibraryIds: ['lateral-raise'],
          },
        },
      ),
      ...supersetPair(
        planId('fri'),
        'B',
        {
          slug: 'incline-db',
          name: 'Incline DB Press',
          sets: 3,
          reps: '8–10',
          weight: '55',
          opts: { libraryId: 'incline-dumbbell-press' },
        },
        {
          slug: 'rear-delt',
          name: 'DB Rear Delt Fly',
          sets: 3,
          reps: '15',
          weight: '20',
          opts: { libraryId: 'rear-delt-fly' },
        },
      ),
      ...supersetPair(
        planId('fri'),
        'C',
        {
          slug: 'machine-chest',
          name: 'Machine Chest Press',
          sets: 3,
          reps: '8–10',
          weight: '120',
          opts: {
            libraryId: 'machine-chest-press',
            preferredSwapLibraryIds: ['smith-machine-bench-press'],
          },
        },
        {
          slug: 'ez-curl',
          name: 'EZ Bar Curl',
          sets: 3,
          reps: '10–12',
          weight: '50',
          opts: { libraryId: 'ez-bar-curl' },
        },
      ),
      ...supersetPair(
        planId('fri'),
        'D',
        {
          slug: 'oh-rope',
          name: 'Overhead Rope Extension',
          sets: 3,
          reps: '10–12',
          weight: '40',
          opts: { libraryId: 'overhead-cable-tricep-extension' },
        },
        {
          slug: 'rope-pushdown',
          name: 'Rope Pushdown',
          sets: 3,
          reps: '12–15',
          weight: '40',
          opts: { libraryId: 'tricep-pushdown' },
        },
      ),
      te(planId('fri'), 'zone2', 'Zone 2 Cardio', 1, '15 min', '0', {
        libraryId: 'incline-treadmill-walk',
        isCardio: true,
        targetDuration: '15',
      }),
    ],
  },
  {
    id: planId('sat'),
    name: 'Saturday (Optional): Pull + Arms + Advanced Core',
    folderId: JOEY_FALL_BULK_FOLDER.id,
    notes: `${SUPERSET_HINT}\n${SWAP_HINT}\n\nOptional day (~50 min).\n\nSuperset A: rest 90 sec between rounds.\nSuperset B: rest 75 sec between rounds.\nSuperset C: rest 60 sec between rounds.\n\nAdvanced ab circuit: 3 rounds — Dragon Flags 5–8, Weighted Russian Twist 20 total, RKC Plank 30–45 sec, Hanging Leg Raise 12–15. Minimal rest between stations; brief rest between rounds.`,
    exercises: [
      ...supersetPair(
        planId('sat'),
        'A',
        {
          slug: 'single-lat',
          name: 'Single Arm Lat Pulldown',
          sets: 3,
          reps: '10–12',
          weight: '60',
          opts: { libraryId: 'single-arm-lat-pulldown' },
        },
        {
          slug: 'chest-row',
          name: 'Chest Supported Row',
          sets: 3,
          reps: '8–10',
          weight: '100',
          opts: { libraryId: 'chest-supported-row' },
        },
      ),
      ...supersetPair(
        planId('sat'),
        'B',
        {
          slug: 'rope-pushdown',
          name: 'Rope Pushdown',
          sets: 3,
          reps: '10–12',
          weight: '40',
          opts: { libraryId: 'tricep-pushdown' },
        },
        {
          slug: 'preacher',
          name: 'Preacher Curl',
          sets: 3,
          reps: '10–12',
          weight: '50',
          opts: {
            libraryId: 'preacher-curl',
            preferredSwapLibraryIds: ['cable-curl'],
          },
        },
      ),
      ...supersetPair(
        planId('sat'),
        'C',
        {
          slug: 'face-pull',
          name: 'Face Pull',
          sets: 3,
          reps: '15–20',
          weight: '40',
          opts: { libraryId: 'face-pull' },
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
      te(planId('sat'), 'dragon-flag', 'Dragon Flags', 3, '5–8', '0', {
        isCircuit: true,
        libraryId: 'dragon-flag',
        isCore: true,
      }),
      te(planId('sat'), 'w-russian', 'Weighted Russian Twist', 3, '20', '20', {
        isCircuit: true,
        libraryId: 'weighted-russian-twist',
        isCore: true,
      }),
      te(planId('sat'), 'rkc', 'RKC Plank', 3, '30–45 sec', '0', {
        isCircuit: true,
        libraryId: 'rkc-plank',
        isCore: true,
        targetTimeSeconds: '40',
      }),
      te(planId('sat'), 'hanging-lr', 'Hanging Leg Raise', 3, '12–15', '0', {
        isCircuit: true,
        libraryId: 'leg-raise',
        isCore: true,
      }),
    ],
  },
  {
    id: planId('sun'),
    name: 'Sunday: Rest or Walk / Mobility',
    folderId: JOEY_FALL_BULK_FOLDER.id,
    notes:
      'Rest day, or optional 30–45 min easy walk / mobility / stretching. Keep intensity low—recover for Monday.',
    exercises: [
      te(planId('sun'), 'walk', 'Easy Walk', 1, '30–45 min', '0', {
        libraryId: 'walking',
        isCardio: true,
        targetDuration: '40',
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
    name: 'Optional Busy Bonus Day (Home DB)',
    folderId: JOEY_FALL_BULK_FOLDER.id,
    notes:
      '20–30 min home workout — dumbbells only. Can sub for any day when you are short on time.\n\n3–5 rounds. Minimal rest between movements; rest 60–90 sec between rounds if needed.\n\nGoblet Squat (20 lb) ×20 · Push-ups ×15–20 · DB Romanian Deadlift ×15 · One-arm DB Row ×15/side · DB Arnold Press ×15 · IYT Raises (8 lb) ×12 each pattern · Bulgarian Split Squat ×12/leg · Renegade Row ×10/side · Plank ×60 sec.',
    exercises: [
      te(planId('bonus'), 'goblet', 'Goblet Squat', 4, '20', '20', {
        isCircuit: true,
        libraryId: 'goblet-squat',
      }),
      te(planId('bonus'), 'pushup', 'Push-Ups', 4, '15–20', '0', {
        isCircuit: true,
        libraryId: 'push-up',
      }),
      te(planId('bonus'), 'db-rdl', 'DB Romanian Deadlift', 4, '15', '40', {
        isCircuit: true,
        libraryId: 'dumbbell-romanian-deadlift',
      }),
      te(planId('bonus'), 'db-row', 'One-Arm DB Row', 4, '15/side', '40', {
        isCircuit: true,
        libraryId: 'dumbbell-row',
      }),
      te(planId('bonus'), 'arnold', 'DB Arnold Press', 4, '15', '25', {
        isCircuit: true,
        libraryId: 'arnold-press',
      }),
      te(planId('bonus'), 'iyt', 'IYT Raises', 4, '12 each', '8', {
        isCircuit: true,
        libraryId: 'iyt-raises',
      }),
      te(planId('bonus'), 'bss', 'Bulgarian Split Squat', 4, '12/leg', '25', {
        isCircuit: true,
        libraryId: 'bulgarian-split-squat',
      }),
      te(planId('bonus'), 'renegade', 'Renegade Row', 4, '10/side', '30', {
        isCircuit: true,
        libraryId: 'renegade-row',
      }),
      te(planId('bonus'), 'plank', 'Plank', 4, '60 sec', '0', {
        isCircuit: true,
        libraryId: 'plank',
        isCore: true,
        targetTimeSeconds: '60',
      }),
    ],
  },
]
