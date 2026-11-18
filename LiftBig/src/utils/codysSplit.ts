import type { TemplateExercise, TemplateFolder, WorkoutTemplate } from '@/types/workout'

function row(n: number, reps: string, weight: string) {
  return Array.from({ length: n }, () => ({ targetReps: reps, targetWeight: weight }))
}

type TeOpts = {
  libraryId?: string
  isCardio?: boolean
  targetDuration?: string
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
    isCardio: opts.isCardio,
    targetDuration: opts.targetDuration,
    preferredSwapLibraryIds: opts.preferredSwapLibraryIds,
    targetRestSeconds: opts.targetRestSeconds,
    sets: row(sets, reps, weight),
  }
}

function supersetPair(
  planId: string,
  label: string,
  a: { slug: string; name: string; sets: number; reps: string; weight: string; opts?: TeOpts },
  b: { slug: string; name: string; sets: number; reps: string; weight: string; opts?: TeOpts },
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

export const CODYS_SPLIT_FOLDER: TemplateFolder = {
  id: 'folder-codys-split',
  name: "Cody's Split",
  purpose:
    'Four-day upper/lower split. Cycle Upper A, Lower A, Upper B, Lower B, and start with Lower A. A ski day counts as a Lower day: no Lower the day before or after. Deload the week before the home resort opens (2 easy sets of everything). In season: Upper A, Upper B, and one Lower a week, alternating A and B, 2 sets at the normal weights. Sore knees from skiing: skip jumps and wall sits. Legs beat after two ski days: skip Lower that week. Cardio by feel after Upper days or on off days — nothing hard the day before Lower or skiing. Sore knees: bike, not running. Knee pain sharper than a dull ache, or worse the next morning: back off.',
}

function planId(day: 'upper-a' | 'lower-a' | 'upper-b' | 'lower-b' | 'off-day' | 'travel'): string {
  return `plan-codys-split-${day}`
}

const UPPER_A = planId('upper-a')
const LOWER_A = planId('lower-a')
const UPPER_B = planId('upper-b')
const LOWER_B = planId('lower-b')
const OFF_DAY = planId('off-day')
const TRAVEL = planId('travel')

/** Lower end of the plan’s rest ranges. The full range stays in the day notes. */
const REST_LIFT = 120
const REST_LATER = 60

const RULES = [
  'Start with Lower A. The cycle is Upper A, then Lower A, then Upper B, then Lower B.',
  'Stop each set with 1-2 reps left. If every set hits the top of the range, use a heavier load next time.',
  'Two easy ramp-up sets before the first lift.',
  'Rest 2-3 min after the first three lifts (timer set to 2 min) and 60-90 s after the later work (timer set to 60 s).',
  'SS means do the pair back to back, then take that rest. Find means pick a weight that leaves about 2 reps in the tank mid-range.',
  'Dumbbell loads are per hand.',
].join('\n')

export const CODYS_SPLIT_PLANS: WorkoutTemplate[] = [
  {
    id: UPPER_A,
    name: 'Day 1: Upper A — Shoulders + Lats',
    folderId: CODYS_SPLIT_FOLDER.id,
    notes: [
      RULES,
      'Shoulders and lats. First three lifts: chin-up, machine shoulder press, lat pulldown.',
      'Machine shoulder press: top set 1 × 6-10 @ 60, then backoff 2 × 8-12 @ 50.',
      'Chest press machine, slow: top set 1 × 6-10 @ 90, then 1 × 8-12 @ 80.',
      'Chin-up: each set is 1-3 reps plus 1 slow negative, bodyweight.',
      'Bench full: cable curl 37.5 and cable overhead rope ext 15, both 3 × 10-15. These substitute for incline DB curl and DB overhead tricep extension. Swap lists those cable options first.',
    ].join('\n\n'),
    exercises: [
      te(UPPER_A, 'walk', 'Walk to Gym or Easy Cardio', 1, '5', '0', {
        libraryId: 'walking',
        isCardio: true,
        targetDuration: '5',
      }),
      te(UPPER_A, 'open-books', 'Open Books', 1, '10/side', '0', { libraryId: 'open-book' }),
      te(UPPER_A, 'chin-tucks', 'Chin Tucks', 1, '10 x 3 sec', '0', { libraryId: 'chin-tuck' }),
      te(UPPER_A, 'wall-slides', 'Wall Slides', 1, '10', '0', { libraryId: 'wall-slide' }),
      te(UPPER_A, 'dead-bugs', 'Dead Bugs', 2, '15', '0', { libraryId: 'dead-bug' }),
      te(UPPER_A, 'face-pull-light', 'Face Pull, Light', 1, '15', '32.5', { libraryId: 'face-pull' }),
      te(UPPER_A, 'chin-up', 'Chin-Up', 4, '1-3 + 1 slow negative', '0', {
        libraryId: 'pull-up',
        targetRestSeconds: REST_LIFT,
      }),
      te(UPPER_A, 'shoulder-press-top', 'Machine Shoulder Press (top set)', 1, '6-10', '60', {
        libraryId: 'machine-shoulder-press',
      }),
      te(UPPER_A, 'shoulder-press', 'Machine Shoulder Press', 2, '8-12', '50', {
        libraryId: 'machine-shoulder-press',
        targetRestSeconds: REST_LIFT,
      }),
      te(UPPER_A, 'lat-pulldown', 'Lat Pulldown', 3, '8-12', '95', {
        libraryId: 'lat-pulldown',
        targetRestSeconds: REST_LIFT,
      }),
      te(UPPER_A, 'chest-press-top', 'Chest Press Machine, Slow (top set)', 1, '6-10', '90', {
        libraryId: 'machine-chest-press',
      }),
      te(UPPER_A, 'chest-press', 'Chest Press Machine, Slow', 1, '8-12', '80', {
        libraryId: 'machine-chest-press',
        targetRestSeconds: REST_LATER,
      }),
      te(UPPER_A, 'db-lateral', 'DB Lateral Raise', 4, '12-20', '12', {
        libraryId: 'lateral-raise',
        targetRestSeconds: REST_LATER,
      }),
      te(UPPER_A, 'rear-delt', 'Rear Delt Fly', 3, '12-20', '50', {
        libraryId: 'rear-delt-fly',
        targetRestSeconds: REST_LATER,
      }),
      ...supersetPair(
        UPPER_A,
        'A',
        {
          slug: 'incline-db-curl',
          name: 'Incline DB Curl',
          sets: 3,
          reps: '6-12',
          weight: '20',
          opts: { libraryId: 'incline-dumbbell-curl', preferredSwapLibraryIds: ['cable-curl'] },
        },
        {
          slug: 'db-oh-tri',
          name: 'DB Overhead Tricep Extension',
          sets: 3,
          reps: '8-12',
          weight: '40',
          opts: {
            libraryId: 'overhead-dumbbell-tricep-extension',
            preferredSwapLibraryIds: ['overhead-cable-tricep-extension'],
            targetRestSeconds: REST_LATER,
          },
        },
      ),
      te(UPPER_A, 'pallof', 'Pallof Press', 3, '10/side', '27.5', {
        libraryId: 'pallof-press',
        targetRestSeconds: REST_LATER,
      }),
      te(UPPER_A, 'captains-chair', "Captain's Chair Leg Raise", 3, '10-15', '0', {
        libraryId: 'captains-chair-leg-raise',
        targetRestSeconds: REST_LATER,
      }),
      te(UPPER_A, 'couch', 'Couch Stretch', 1, '45 sec/side', '0', {
        libraryId: 'hip-flexor-stretch',
      }),
      te(UPPER_A, 'doorway-pec', 'Doorway Pec Stretch', 1, '30 sec/side', '0', {
        libraryId: 'doorway-pec-stretch',
      }),
      te(UPPER_A, 'childs-pose', "Child's Pose Side Reach", 1, '30 sec/side', '0', {
        libraryId: 'childs-pose-side-reach',
      }),
      te(UPPER_A, 'dead-hang', 'Dead Hang', 1, '30 sec', '0', { libraryId: 'dead-hang' }),
    ],
  },
  {
    id: LOWER_A,
    name: 'Day 2: Lower A — Squat + Hinge',
    folderId: CODYS_SPLIT_FOLDER.id,
    notes: [
      RULES,
      'Squat and hinge. First three lifts: back squat, barbell RDL, leg extension.',
      'Racks full: do leg extension, seated leg curl, calf raise, and hip abductor first, then check. Still full: leg press 3 × 8-12 @ 230 and back extension 3 × 10-15 @ 145 in place of the back squat and barbell RDL. Swap lists those options first.',
      'Skater bounds: 56 inches, stick 2 seconds. Distance is not a load. Progress by going longer.',
      'Box jump: 14 inch box, step down. Box height is not a load. Progress by going higher.',
      'Back squat and leg extension use a 3-second lowering (in the exercise name).',
      'Lateral step-down: 15 lb kettlebell, right side first.',
    ].join('\n\n'),
    exercises: [
      te(LOWER_A, 'bike', 'Easy Bike', 1, '5', '0', {
        libraryId: 'easy-stationary-bike',
        isCardio: true,
        targetDuration: '5',
      }),
      te(LOWER_A, 'open-books', 'Open Books', 1, '10/side', '0', { libraryId: 'open-book' }),
      te(LOWER_A, 'dead-bugs', 'Dead Bugs', 2, '15', '0', { libraryId: 'dead-bug' }),
      te(LOWER_A, 'glute-bridge', 'Glute Bridge', 2, '30 sec', '0', { libraryId: 'glute-bridge' }),
      te(LOWER_A, 'knee-to-wall', 'Knee-to-Wall', 1, '10/side', '0', { libraryId: 'knee-to-wall' }),
      te(LOWER_A, 'hip-switches', '90/90 Hip Switches', 1, '10/side', '0', {
        libraryId: 'hip-90-90-switch',
      }),
      te(LOWER_A, 'skater-bounds', 'Skater Bounds', 3, '8', '0', { libraryId: 'skater-bound' }),
      te(LOWER_A, 'box-jump', 'Box Jump, Step Down', 3, '5', '0', { libraryId: 'box-jump' }),
      te(LOWER_A, 'back-squat', 'Back Squat, 3s Down', 3, '6-10', '115', {
        libraryId: 'squat',
        preferredSwapLibraryIds: ['leg-press'],
        targetRestSeconds: REST_LIFT,
      }),
      te(LOWER_A, 'rdl', 'Barbell RDL', 3, '8-10', '115', {
        libraryId: 'romanian-deadlift',
        preferredSwapLibraryIds: ['back-extension'],
        targetRestSeconds: REST_LIFT,
      }),
      te(LOWER_A, 'leg-extension', 'Leg Extension, 3s Down', 3, '8-12', '115', {
        libraryId: 'leg-extension',
        targetRestSeconds: REST_LIFT,
      }),
      te(LOWER_A, 'leg-curl', 'Seated Leg Curl', 3, '8-12', '120', {
        libraryId: 'seated-leg-curl',
        targetRestSeconds: REST_LATER,
      }),
      te(LOWER_A, 'calf-raise', 'Calf Raise on Leg Press', 3, '10-15', '230', {
        libraryId: 'calf-raise',
        targetRestSeconds: REST_LATER,
      }),
      te(LOWER_A, 'hip-abductor', 'Hip Abductor', 2, '12-15/leg', '100', {
        libraryId: 'hip-abductor-machine',
        targetRestSeconds: REST_LATER,
      }),
      te(LOWER_A, 'db-lateral', 'DB Lateral Raise', 2, '12-20', '12', {
        libraryId: 'lateral-raise',
        targetRestSeconds: REST_LATER,
      }),
      te(LOWER_A, 'step-down', 'Lateral Step-Down', 2, '8/side', '15', {
        libraryId: 'lateral-step-down',
        targetRestSeconds: REST_LATER,
      }),
      te(LOWER_A, 'tibialis', 'Tibialis Raise', 2, '15-20', '0', {
        libraryId: 'tibialis-raise',
        targetRestSeconds: REST_LATER,
      }),
      te(LOWER_A, 'couch', 'Couch Stretch', 1, '45 sec/side', '0', {
        libraryId: 'hip-flexor-stretch',
      }),
      te(LOWER_A, 'calf-stretch', 'Calf Stretch on a Step', 1, '30 sec/side', '0', {
        libraryId: 'calf-stretch',
      }),
      te(LOWER_A, 'hamstring-stretch', 'Hamstring Stretch', 1, '45 sec/side', '0', {
        libraryId: 'hamstring-stretch-hold',
      }),
    ],
  },
  {
    id: UPPER_B,
    name: 'Day 3: Upper B — Upper Chest + Back + Arms',
    folderId: CODYS_SPLIT_FOLDER.id,
    notes: [
      RULES,
      'Upper chest, back, and arms. First three lifts: incline DB press, seated row, assisted wide pull-up.',
      'Bench full: chest press machine 3 × 8-12 @ 85 in place of incline DB press. Swap lists it first.',
      'Cables full: tricep machine 3 × 8-12 @ 70, side plank 2 × 30 s/side. Rope pushdown lists the tricep machine as the first swap.',
      'Assisted wide pull-up and assisted dips store assistance weight. A higher number is more help; progress by lowering it. Wide grip on the pull-up.',
      'Face pull is programmed twice: one light set early, then a heavier pair later. Same exercise.',
      'Suitcase carry: heavy kettlebell. Find a load that leaves about 2 reps in the tank (weight left unset). 3 × 30 m per side.',
    ].join('\n\n'),
    exercises: [
      te(UPPER_B, 'walk', 'Walk to Gym or Easy Cardio', 1, '5', '0', {
        libraryId: 'walking',
        isCardio: true,
        targetDuration: '5',
      }),
      te(UPPER_B, 'open-books', 'Open Books', 1, '10/side', '0', { libraryId: 'open-book' }),
      te(UPPER_B, 'chin-tucks', 'Chin Tucks', 1, '10 x 3 sec', '0', { libraryId: 'chin-tuck' }),
      te(UPPER_B, 'wall-slides', 'Wall Slides', 1, '10', '0', { libraryId: 'wall-slide' }),
      te(UPPER_B, 'dead-bugs', 'Dead Bugs', 2, '15', '0', { libraryId: 'dead-bug' }),
      te(UPPER_B, 'face-pull-light', 'Face Pull, Light', 1, '15', '32.5', { libraryId: 'face-pull' }),
      te(UPPER_B, 'incline-db', 'Incline DB Press', 3, '6-12', '35', {
        libraryId: 'incline-dumbbell-press',
        preferredSwapLibraryIds: ['machine-chest-press'],
        targetRestSeconds: REST_LIFT,
      }),
      te(UPPER_B, 'seated-row', 'Seated Row', 3, '8-12', '110', {
        libraryId: 'seated-cable-row',
        targetRestSeconds: REST_LIFT,
      }),
      te(UPPER_B, 'assisted-pull-up', 'Assisted Wide Pull-Up', 3, '6-10', '55', {
        libraryId: 'assisted-pull-up',
        targetRestSeconds: REST_LIFT,
      }),
      te(UPPER_B, 'assisted-dip', 'Assisted Dip', 3, '8-12', '35', {
        libraryId: 'assisted-dip',
        targetRestSeconds: REST_LATER,
      }),
      te(UPPER_B, 'lean-away', 'Lean-Away Lateral Raise', 3, '12-20/side', '10', {
        libraryId: 'lean-away-cable-lateral-raise',
        targetRestSeconds: REST_LATER,
      }),
      te(UPPER_B, 'face-pull-heavy', 'Face Pull, Heavy', 2, '12-15', '42.5', {
        libraryId: 'face-pull',
        targetRestSeconds: REST_LATER,
      }),
      ...supersetPair(
        UPPER_B,
        'A',
        {
          slug: 'curl-machine',
          name: 'Bicep Curl Machine',
          sets: 3,
          reps: '8-12',
          weight: '70',
          opts: { libraryId: 'machine-bicep-curl' },
        },
        {
          slug: 'rope-pushdown',
          name: 'Rope Pushdown',
          sets: 3,
          reps: '10-15',
          weight: '27.5',
          opts: {
            libraryId: 'tricep-pushdown',
            preferredSwapLibraryIds: ['machine-triceps-extension'],
            targetRestSeconds: REST_LATER,
          },
        },
      ),
      te(UPPER_B, 'hammer', 'Hammer Curl', 2, '8-15/side', '20', {
        libraryId: 'hammer-curl',
        targetRestSeconds: REST_LATER,
      }),
      te(UPPER_B, 'woodchop', 'Cable Woodchop', 2, '10/side', '25', {
        libraryId: 'cable-woodchop',
        targetRestSeconds: REST_LATER,
      }),
      te(UPPER_B, 'suitcase', 'Suitcase Carry', 3, '30 m/side', '', {
        libraryId: 'suitcase-carry',
        targetRestSeconds: REST_LATER,
      }),
      te(UPPER_B, 'couch', 'Couch Stretch', 1, '45 sec/side', '0', {
        libraryId: 'hip-flexor-stretch',
      }),
      te(UPPER_B, 'doorway-pec', 'Doorway Pec Stretch', 1, '30 sec/side', '0', {
        libraryId: 'doorway-pec-stretch',
      }),
      te(UPPER_B, 'childs-pose', "Child's Pose Side Reach", 1, '30 sec/side', '0', {
        libraryId: 'childs-pose-side-reach',
      }),
      te(UPPER_B, 'dead-hang', 'Dead Hang', 1, '30 sec', '0', { libraryId: 'dead-hang' }),
    ],
  },
  {
    id: LOWER_B,
    name: 'Day 4: Lower B — Single-Leg + Glutes',
    folderId: CODYS_SPLIT_FOLDER.id,
    notes: [
      RULES,
      'Single-leg and glutes. First three lifts: DB step-up, single-leg leg press, barbell hip thrust.',
      'Rack full: do the hip thrust last. Still full: cable pull-through 3 × 12-15 @ 30 in place of the hip thrust. Swap lists that option first.',
      'Right side first on the single-leg hop, DB step-up, single-leg leg press, and balance disc.',
      'Lateral line hops: no load. Progress by going faster.',
      'Single-leg hop: stick the landing about 2 seconds (in the name).',
      'DB step-up: 3-second lowering, 20 lb dumbbells per hand.',
      'Single-leg leg press and single-leg calf raise: Find a load around 100 lb.',
      'Lying leg curl: Find a load. Weight is left unset.',
      'Balance disc: hold as written with eyes open. Progression is eyes closed.',
      'Copenhagen plank is the knee version. Add about 5 seconds per side each week.',
    ].join('\n\n'),
    exercises: [
      te(LOWER_B, 'bike', 'Easy Bike', 1, '5', '0', {
        libraryId: 'easy-stationary-bike',
        isCardio: true,
        targetDuration: '5',
      }),
      te(LOWER_B, 'open-books', 'Open Books', 1, '10/side', '0', { libraryId: 'open-book' }),
      te(LOWER_B, 'dead-bugs', 'Dead Bugs', 2, '15', '0', { libraryId: 'dead-bug' }),
      te(LOWER_B, 'glute-bridge', 'Glute Bridge', 2, '30 sec', '0', { libraryId: 'glute-bridge' }),
      te(LOWER_B, 'knee-to-wall', 'Knee-to-Wall', 1, '10/side', '0', { libraryId: 'knee-to-wall' }),
      te(LOWER_B, 'hip-switches', '90/90 Hip Switches', 1, '10/side', '0', {
        libraryId: 'hip-90-90-switch',
      }),
      te(LOWER_B, 'line-hops', 'Lateral Line Hops', 3, '10', '0', { libraryId: 'lateral-line-hop' }),
      te(LOWER_B, 'sl-hop', 'Single-Leg Hop, Stick 2s', 2, '5/side', '0', {
        libraryId: 'single-leg-hop',
      }),
      te(LOWER_B, 'step-up', 'DB Step-Up, 3s Down', 3, '8-12/side', '20', {
        libraryId: 'step-up',
        targetRestSeconds: REST_LIFT,
      }),
      te(LOWER_B, 'sl-leg-press', 'Single-Leg Leg Press', 3, '10-12/side', '100', {
        libraryId: 'single-leg-leg-press',
        targetRestSeconds: REST_LIFT,
      }),
      te(LOWER_B, 'hip-thrust', 'Barbell Hip Thrust', 3, '8-12', '95', {
        libraryId: 'hip-thrust',
        preferredSwapLibraryIds: ['cable-pull-through'],
        targetRestSeconds: REST_LIFT,
      }),
      te(LOWER_B, 'lying-curl', 'Lying Leg Curl', 3, '10-12', '', {
        libraryId: 'hamstring-curl',
        targetRestSeconds: REST_LATER,
      }),
      te(LOWER_B, 'back-extension', 'Back Extension', 2, '12-15', '145', {
        libraryId: 'back-extension',
        targetRestSeconds: REST_LATER,
      }),
      te(LOWER_B, 'sl-calf', 'Single-Leg Calf Raise on Leg Press', 2, '10-15/side', '100', {
        libraryId: 'single-leg-calf-raise',
        targetRestSeconds: REST_LATER,
      }),
      te(LOWER_B, 'db-lateral', 'DB Lateral Raise', 2, '12-20', '12', {
        libraryId: 'lateral-raise',
        targetRestSeconds: REST_LATER,
      }),
      te(LOWER_B, 'balance', 'Balance Disc, One Leg', 3, '30 sec/side', '0', {
        libraryId: 'balance-disc',
        targetRestSeconds: REST_LATER,
      }),
      te(LOWER_B, 'copenhagen', 'Copenhagen Plank, Knee Version', 2, '20 sec/side', '0', {
        libraryId: 'copenhagen-plank',
        targetRestSeconds: REST_LATER,
      }),
      te(LOWER_B, 'couch', 'Couch Stretch', 1, '45 sec/side', '0', {
        libraryId: 'hip-flexor-stretch',
      }),
      te(LOWER_B, 'calf-stretch', 'Calf Stretch on a Step', 1, '30 sec/side', '0', {
        libraryId: 'calf-stretch',
      }),
      te(LOWER_B, 'hamstring-stretch', 'Hamstring Stretch', 1, '45 sec/side', '0', {
        libraryId: 'hamstring-stretch-hold',
      }),
    ],
  },
  {
    id: OFF_DAY,
    name: 'Off Day at Home',
    folderId: CODYS_SPLIT_FOLDER.id,
    notes: [
      'About 10 minutes at home.',
      'Wall sit is 4 × 45 s. The written next step is 5 × 45 s.',
      'Doorframe chin-ups are 4-6 singles spread through the day.',
      'Knee pain sharper than a dull ache, or worse the next morning: back off. Skip wall sits if the knees are sore from skiing.',
    ].join('\n\n'),
    exercises: [
      te(OFF_DAY, 'wall-sit', 'Wall Sit', 4, '45 sec', '0', { libraryId: 'wall-sit' }),
      te(OFF_DAY, 'doorframe-chin', 'Doorframe Chin-Up', 1, '4-6 singles through the day', '0', {
        libraryId: 'pull-up',
      }),
      te(OFF_DAY, 'chin-tucks', 'Chin Tucks', 1, '10 x 3 sec', '0', { libraryId: 'chin-tuck' }),
      te(OFF_DAY, 'wall-slides', 'Wall Slides', 1, '10', '0', { libraryId: 'wall-slide' }),
      te(OFF_DAY, 'open-books', 'Open Books', 1, '10/side', '0', { libraryId: 'open-book' }),
      te(OFF_DAY, 'glute-bridge', 'Glute Bridge', 2, '30 sec', '0', { libraryId: 'glute-bridge' }),
      te(OFF_DAY, 'couch', 'Couch Stretch', 1, '45 sec/side', '0', {
        libraryId: 'hip-flexor-stretch',
      }),
    ],
  },
  {
    id: TRAVEL,
    name: 'Travel (No Gym)',
    folderId: CODYS_SPLIT_FOLDER.id,
    notes:
      'No gym. Push-ups are 3 sets with no rep target in the plan. Skip jumps and the wall sit if the knees are sore.',
    exercises: [
      te(TRAVEL, 'push-up', 'Push-Up', 3, '—', '0', { libraryId: 'push-up' }),
      te(TRAVEL, 'pike', 'Pike Push-Up', 3, '8-12', '0', { libraryId: 'pike-push-up' }),
      te(TRAVEL, 'chair-step', 'Chair Step-Up', 3, '10/side', '0', { libraryId: 'step-up' }),
      te(TRAVEL, 'skater', 'Skater Bounds', 3, '8', '0', { libraryId: 'skater-bound' }),
      te(TRAVEL, 'wall-sit', 'Wall Sit', 4, '45 sec', '0', { libraryId: 'wall-sit' }),
      te(TRAVEL, 'copenhagen', 'Copenhagen Plank, Knee Version', 2, '20 sec/side', '0', {
        libraryId: 'copenhagen-plank',
      }),
      te(TRAVEL, 'side-plank', 'Side Plank', 2, '30 sec/side', '0', { libraryId: 'side-plank' }),
    ],
  },
]
