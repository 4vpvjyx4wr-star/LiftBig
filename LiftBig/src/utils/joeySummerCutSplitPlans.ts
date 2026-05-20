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

/** Legacy Joey folder plans — kept in All (no folder) after migration. */
export const JOEY_SUMMER_LEGACY_PLAN_IDS: readonly string[] = [
  'plan-push',
  'plan-pull',
  'plan-legs',
  'plan-core-conditioning',
  'plan-arms-core',
  'plan-circuit',
  'plan-heavy-push-delts-abs',
  'plan-quick-legs-delts',
  'plan-upper-chest-arms-abs',
  'plan-quick-pump-day',
]

export const LEGACY_JOEY_SUMMER_FOLDER_ID = 'folder-joey-summer-ppl'
export const LEGACY_JOEY_SUMMER_FOLDER_NAME = "Joey's Summer PPL/Core/Circuit"

export const JOEY_CUT_SPLIT_FOLDER: TemplateFolder = {
  id: 'folder-joey-summer-cut-split',
  name: "Joey's Summer PPL/Core/Cut Split",
  purpose:
    'Three-week summer cut split: push/pull/legs, quick pumps, chill circuits, and progressive overload with week-3 finishers.',
}

const WEEK_FOCUS: Record<1 | 2 | 3, string> = {
  1: 'Week 1 — Baseline: Hit the listed rep ranges with clean form. Superset pairings mean back-to-back exercises with minimal rest between the two moves, then rest before the next round.',
  2: 'Week 2 — Progressive overload: Add +5 lb on main compounds when you hit the top of the rep range. On isolation work, beat reps from Week 1 OR slow the eccentric (2–3 sec lowering). Last set of lateral raises, curls, and abs → go near failure.',
  3: 'Week 3 — Peak intensity: Compounds at 0–1 RIR; occasional failure on isolations is OK. Same weekly structure with added finishers on Monday, Friday, and Saturday (see day notes).',
}

function planNotes(week: 1 | 2 | 3, activity: string, extra?: string): string {
  const parts = [WEEK_FOCUS[week], `Activity: ${activity}`]
  if (extra?.trim()) parts.push(extra.trim())
  return parts.join('\n\n')
}

function cutPlanId(week: number, day: number): string {
  return `plan-joey-cut-w${week}-d${day}`
}

type Loads = {
  inclineDb: string
  inclineMachine: string
  flatDb: string
  legPress: string
  rdl: string
  chestRow: string
  legExt: string
  cableLat: string
  cableCrunch: string
  wtdCableCrunch: string
  facePull: string
  ohCableTri: string
}

const LOADS: Record<1 | 2 | 3, Loads> = {
  1: {
    inclineDb: '55',
    inclineMachine: '95',
    flatDb: '45',
    legPress: '275',
    rdl: '135',
    chestRow: '100',
    legExt: '140',
    cableLat: '15',
    cableCrunch: '85',
    wtdCableCrunch: '90',
    facePull: '100',
    ohCableTri: '55',
  },
  2: {
    inclineDb: '60',
    inclineMachine: '100',
    flatDb: '50',
    legPress: '280',
    rdl: '140',
    chestRow: '105',
    legExt: '145',
    cableLat: '17.5',
    cableCrunch: '90',
    wtdCableCrunch: '95',
    facePull: '105',
    ohCableTri: '60',
  },
  3: {
    inclineDb: '65',
    inclineMachine: '105',
    flatDb: '55',
    legPress: '285',
    rdl: '145',
    chestRow: '110',
    legExt: '150',
    cableLat: '20',
    cableCrunch: '95',
    wtdCableCrunch: '100',
    facePull: '110',
    ohCableTri: '65',
  },
}

type DaySpec = {
  day: number
  title: string
  activity: string
  extraNotes?: string
  isCircuit?: boolean
  exercises: (id: string, w: Loads) => TemplateExercise[]
}

function buildCutWeekPlans(week: 1 | 2 | 3): WorkoutTemplate[] {
  const L = LOADS[week]
  const nearFail =
    week >= 2 ? ' Last set of lateral raises, curls, and abs: near failure.' : ''
  const intensity =
    week === 3 ? ' Compounds: 0–1 RIR. Isolations: occasional failure OK.' : ''

  const days: DaySpec[] = [
    {
      day: 1,
      title: 'Push / Delts / Abs',
      activity: 'Heavy push & delts + abs (~60 min)',
      extraNotes:
        `Superset A → B → C, then abs.${nearFail}${intensity}` +
        (week === 3
          ? '\n\nFinisher: Lateral raise partials — 1 burnout set after main lateral work.'
          : ''),
      exercises: (id, w) => {
        const list = [
          te(id, 'incline-db', 'Incline DB Press', 4, '6–10', w.inclineDb, false, 'incline-dumbbell-press'),
          te(id, 'cable-lat-a', 'Cable Lateral Raise', 4, '12–15', w.cableLat, false, 'lateral-raise'),
          te(id, 'incline-machine', 'Incline Machine Press', 3, '8–12', w.inclineMachine, false, 'incline-machine-press'),
          te(id, 'rear-delt-fly', 'Rear Delt Fly', 3, '12–15', '20', false, 'rear-delt-fly'),
          te(id, 'low-high-fly', 'Low-to-High Cable Fly', 3, '12–15', '25', false, 'low-to-high-cable-fly'),
          te(id, 'leaning-lat', 'Leaning DB Lateral Raise', 3, '15–20', '15', false, 'leaning-dumbbell-lateral-raise'),
          te(id, 'wtd-cable-crunch', 'Weighted Cable Crunch', 3, '10–12', w.wtdCableCrunch, false, 'cable-crunch'),
          te(id, 'hanging-leg-raise', 'Hanging Leg Raise', 3, '10–15', '0', false, 'leg-raise'),
        ]
        if (week === 3) {
          list.push(
            te(id, 'lat-partial-finisher', 'Lateral Raise Partials (Burnout)', 1, 'AMRAP', '12', false, 'lateral-raise-partial'),
          )
        }
        return list
      },
    },
    {
      day: 2,
      title: 'QUICK Pump',
      activity: 'Pump circuit + cardio finish (~35–40 min)',
      extraNotes:
        '3 rounds — minimal rest between stations, rest 60–90 sec between rounds. Finish: incline treadmill walk 10 min.' +
        nearFail,
      isCircuit: true,
      exercises: (id) => [
        te(id, 'push-up', 'Push-Ups', 3, 'AMRAP', '0', true, 'push-up'),
        te(id, 'db-lat', 'DB Lateral Raise', 3, '15–20', '20', true, 'lateral-raise'),
        te(id, 'cable-curl', 'Cable Curl', 3, '10–12', week === 1 ? '30' : week === 2 ? '32.5' : '35', true, 'cable-curl'),
        te(id, 'rope-push', 'Rope Pushdown', 3, '10–12', week === 1 ? '65' : week === 2 ? '70' : '75', true, 'tricep-pushdown'),
        te(id, 'plank', 'Plank', 3, '60 sec', '0', true, 'plank'),
        te(id, 'incline-walk', 'Incline Treadmill Walk (Finish)', 1, '10 min', '0', false, 'incline-treadmill-walk'),
      ],
    },
    {
      day: 3,
      title: 'Legs / Delts',
      activity: 'Legs & delts (~50 min)',
      extraNotes: `Superset A → B → C.${nearFail}${intensity}`,
      exercises: (id, w) => [
        te(id, 'leg-press', 'Leg Press', 4, '8–10', w.legPress, false, 'leg-press'),
        te(id, 'calf-raise', 'Standing Calf Raise', 4, '12–20', week === 1 ? '225' : week === 2 ? '235' : '245', false, 'calf-raise'),
        te(id, 'rdl', 'Romanian Deadlift', 3, '8–12', w.rdl, false, 'romanian-deadlift'),
        te(id, 'cable-crunch-b', 'Cable Crunch', 3, '12–15', w.cableCrunch, false, 'cable-crunch'),
        te(id, 'leg-ext', 'Leg Extension', 3, '12–15', w.legExt, false, 'leg-extension'),
        te(id, 'cable-lat-c', 'Cable Lateral Raise', 3, '15–20', w.cableLat, false, 'lateral-raise'),
      ],
    },
    {
      day: 4,
      title: 'Chill Circuit',
      activity: 'Low-stress conditioning circuit (~35–40 min)',
      extraNotes:
        'Keep heart rate elevated; don’t annihilate yourself. 4 rounds — flow station to station, rest 45–60 sec between rounds.',
      isCircuit: true,
      exercises: (id) => [
        te(id, 'goblet', 'Goblet Squat', 4, '15', week === 1 ? '40' : week === 2 ? '45' : '50', true, 'goblet-squat'),
        te(id, 'db-ohp', 'DB Shoulder Press', 4, '12', week === 1 ? '35' : week === 2 ? '40' : '45', true, 'standing-dumbbell-shoulder-press'),
        te(id, 'push-up-c', 'Push-Ups', 4, '15–20', '0', true, 'push-up'),
        te(id, 'db-curl', 'DB Curl', 4, '12', week === 1 ? '25' : week === 2 ? '27.5' : '30', true, 'dumbbell-curl'),
        te(id, 'oh-db-tri', 'Overhead DB Tricep Extension', 4, '12', week === 1 ? '30' : week === 2 ? '32.5' : '35', true, 'overhead-dumbbell-tricep-extension'),
        te(id, 'wtd-crunch', 'Weighted Crunch', 4, '15', week === 1 ? '25' : week === 2 ? '30' : '35', true, 'weighted-crunch'),
        te(id, 'side-plank', 'Side Plank', 4, '30 sec/side', '0', true, 'side-plank'),
      ],
    },
    {
      day: 5,
      title: 'Upper Chest / Arms',
      activity: 'Upper chest, arms & abs (~50 min)',
      extraNotes:
        `Superset A → B → C, then abs.${nearFail}${intensity}` +
        (week === 3
          ? '\n\nFinisher: Push-Up mechanical drop set — normal reps → knees → partials until burnout.'
          : ''),
      exercises: (id, w) => {
        const list = [
          te(id, 'incline-db-b', 'Incline DB Press', 4, '8–12', w.inclineDb, false, 'incline-dumbbell-press'),
          te(id, 'db-lat-b', 'DB Lateral Raise', 4, '15–20', '20', false, 'lateral-raise'),
          te(id, 'flat-db', 'Flat DB Press', 3, '8–12', w.flatDb, false, 'flat-dumbbell-press'),
          te(id, 'incline-db-curl', 'Incline DB Curl', 3, '10–12', week === 1 ? '25' : week === 2 ? '27.5' : '30', false, 'incline-dumbbell-curl'),
          te(id, 'oh-cable-tri', 'Overhead Cable Tricep Extension', 3, '10–12', w.ohCableTri, false, 'overhead-cable-tricep-extension'),
          te(id, 'rear-delt-b', 'Rear Delt Fly', 3, '12–15', '20', false, 'rear-delt-fly'),
          te(id, 'decline-rev', 'Decline Reverse Crunch', 3, '12–15', '0', false, 'decline-reverse-crunch'),
          te(id, 'woodchop', 'Cable Woodchop', 3, '10–15/side', week === 1 ? '35' : week === 2 ? '40' : '45', false, 'cable-woodchop'),
        ]
        if (week === 3) {
          list.push(
            te(id, 'pushup-drop', 'Push-Up Mechanical Drop Set', 1, 'burnout', '0', false, 'push-up'),
          )
        }
        return list
      },
    },
    {
      day: 6,
      title: 'Pull / Rear Delts / Core',
      activity: 'Pull & rear delts + core (~55–60 min)',
      extraNotes:
        `Superset A → B → C, then abs.${nearFail}${intensity}` +
        (week === 3 ? '\n\nFinisher: Face pull burnout — 25 reps with controlled squeeze.' : ''),
      exercises: (id, w) => {
        const list = [
          te(id, 'pull-up', 'Pull-Ups or Assisted Pull-Ups', 4, 'AMRAP', '0', false, 'assisted-pull-up'),
          te(id, 'face-pull', 'Face Pull', 4, '12–15', w.facePull, false, 'face-pull'),
          te(id, 'chest-row', 'Chest Supported Row', 3, '8–12', w.chestRow, false, 'chest-supported-row'),
          te(id, 'rear-cable-fly', 'Rear Delt Cable Fly', 3, '12–15', '20', false, 'rear-delt-cable-fly'),
          te(id, 'single-lat', 'Single Arm Lat Pulldown', 3, '10–12', week === 1 ? '60' : week === 2 ? '65' : '70', false, 'single-arm-lat-pulldown'),
          te(id, 'hammer', 'Hammer Curl', 3, '10–12', week === 1 ? '25' : week === 2 ? '27.5' : '30', false, 'hammer-curl'),
          te(id, 'hanging-knee', 'Hanging Knee Raise', 3, '12–15', '0', false, 'hanging-knee-raise'),
          te(id, 'cable-crunch-c', 'Cable Crunch', 3, '10–12', w.cableCrunch, false, 'cable-crunch'),
        ]
        if (week === 3) {
          list.push(te(id, 'face-pull-burnout', 'Face Pull Burnout', 1, '25', w.facePull, false, 'face-pull'))
        }
        return list
      },
    },
    {
      day: 7,
      title: 'Recovery / Athletic Day',
      activity: 'Very low stress — recovery & core (~30–40 min)',
      extraNotes:
        'Choose one: incline walk, basketball, long walk, bike, or mobility work (20–30 min). Then complete the ab circuit (3 rounds).',
      exercises: (id) => [
        te(id, 'recovery', 'Recovery Activity (your choice)', 1, '20–30 min', '0', false, 'incline-treadmill-walk'),
        te(id, 'rev-crunch', 'Reverse Crunch', 3, '15', '0', true, 'reverse-crunch'),
        te(id, 'plank-r', 'Plank', 3, '60 sec', '0', true, 'plank'),
        te(id, 'bicycle', 'Bicycle Crunch', 3, '20', '0', true, 'bicycle-crunch'),
        te(id, 'side-plank-r', 'Side Plank', 3, '30 sec/side', '0', true, 'side-plank'),
      ],
    },
  ]

  return days.map((spec) => {
    const id = cutPlanId(week, spec.day)
    const globalDay = (week - 1) * 7 + spec.day
    return {
      id,
      name: `Week ${week} - Day ${globalDay}: ${spec.title}`,
      folderId: JOEY_CUT_SPLIT_FOLDER.id,
      isCircuit: spec.isCircuit,
      notes: planNotes(week, spec.activity, spec.extraNotes),
      exercises: spec.exercises(id, L),
    }
  })
}

export const JOEY_CUT_SPLIT_PLANS: WorkoutTemplate[] = [
  ...buildCutWeekPlans(1),
  ...buildCutWeekPlans(2),
  ...buildCutWeekPlans(3),
]
