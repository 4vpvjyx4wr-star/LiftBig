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

export const DEFAULT_PLANS: WorkoutTemplate[] = [
  {
    id: 'plan-back-legs',
    name: 'Back / Legs',
    exercises: [
      te('plan-back-legs', 'pull-ups-lat', 'Pull Ups / Lat Pulldown', 4, '8-12', '120', false, 'pull-up'),
      te('plan-back-legs', 'leg-extension', 'Leg Extension', 3, '12-15', '140', false, 'leg-extension'),
      te('plan-back-legs', 'row-variation', 'Row Variation', 3, '8-12', '110', false, 'barbell-row'),
      te('plan-back-legs', 'hamstring-curl', 'Hamstring Curl', 3, '10-15', '120', false, 'hamstring-curl'),
      te('plan-back-legs', 'face-pulls', 'Face Pulls', 3, '12-15', '100', false, 'face-pull'),
      te('plan-back-legs', 'cable-curl', 'Cable Curl', 3, '10-12', '30', false, 'cable-curl'),
      te('plan-back-legs', 'tricep-pushdown', 'Tricep Pushdown', 3, '10-12', '70', false, 'tricep-pushdown'),
      te('plan-back-legs', 'lateral-raises', 'Lateral Raises', 3, '15-20', '20', false, 'lateral-raise'),
      te('plan-back-legs', 'cable-woodchops', 'Cable Woodchops', 3, '10-12', '25', false, 'cable-woodchop'),
    ],
  },
  {
    id: 'plan-chest-1',
    name: 'Chest 1',
    exercises: [
      te('plan-chest-1', 'incline-db-press', 'Incline DB Press', 4, '6-10', '65', false, 'incline-dumbbell-press'),
      te('plan-chest-1', 'db-lateral-raise', 'DB Lateral Raise', 4, '12-20', '20', false, 'lateral-raise'),
      te('plan-chest-1', 'incline-machine-press', 'Incline Machine Press', 3, '8-12', '95', false, 'incline-machine-press'),
      te('plan-chest-1', 'rear-delt-fly', 'Rear Delt Fly', 3, '12-15', '20', false, 'rear-delt-fly'),
      te('plan-chest-1', 'machine-flyes', 'Machine Flyes', 3, '12-15', '80', false, 'machine-fly'),
      te('plan-chest-1', 'cable-lateral-raise', 'Cable Lateral Raise', 3, '12-15', '15', false, 'lateral-raise'),
      te('plan-chest-1', 'ab-machine', 'Ab Machine / Leg Raises', 3, '10-15', '100', false, 'ab-machine-crunch'),
    ],
  },
  {
    id: 'plan-back',
    name: 'Back',
    exercises: [
      te('plan-back', 'pull-ups', 'Pull Ups', 4, 'AMRAP', '160', false, 'pull-up'),
      te('plan-back', 'single-arm-lat', 'Single Arm Lat Pulldown', 3, '10-12', '60', false, 'lat-pulldown'),
      te('plan-back', 'lat-pulldown', 'Lat Pulldown', 3, '8-12', '100', false, 'lat-pulldown'),
      te('plan-back', 'seated-bentover-row', 'Seated / Bentover Row', 3, '8-12', '100', false, 'seated-cable-row'),
      te('plan-back', 'chest-supported-row', 'Chest Supported Row', 3, '8-12', '100', false, 'chest-supported-row'),
      te('plan-back', 'face-pulls', 'Face Pulls', 3, '12-15', '100', false, 'face-pull'),
      te('plan-back', 'cable-crunches', 'Cable Crunches', 3, '12-15', '100', false, 'cable-crunch'),
    ],
  },
  {
    id: 'plan-circuit',
    name: 'Circuit Day',
    isCircuit: true,
    exercises: [
      te('plan-circuit', 'goblet-squat', 'DB Goblet Squat', 3, '12-15', '20', true, 'goblet-squat'),
      te('plan-circuit', 'db-rdl', "DB RDL's", 3, '10-12', '20', true, 'dumbbell-romanian-deadlift'),
      te('plan-circuit', 'push-ups', 'Push-ups', 3, 'AMRAP', '20', true, 'push-up'),
      te('plan-circuit', 'db-rows', 'DB Rows', 3, '10-15', '20', true, 'dumbbell-row'),
      te('plan-circuit', 'lateral-raises', 'Lateral Raises', 3, '15-20', '20', true, 'lateral-raise'),
      te('plan-circuit', 'hammer-curls', 'DB Hammer Curls', 3, '10-12', '20', true, 'hammer-curl'),
      te('plan-circuit', 'oh-tricep', 'DB Overhead Tricep Extension', 3, '10-12', '20', true, 'overhead-tricep-extension'),
    ],
  },
  {
    id: 'plan-chest-2',
    name: 'Chest 2',
    exercises: [
      te('plan-chest-2', 'incline-db-press', 'Incline DB Press', 4, '8-12', '55', false, 'incline-dumbbell-press'),
      te('plan-chest-2', 'rear-delt-fly', 'Rear Delt Fly', 3, '12-15', '20', false, 'rear-delt-fly'),
      te('plan-chest-2', 'flat-db-press', 'Flat DB Press', 3, '8-12', '45', false, 'flat-dumbbell-press'),
      te('plan-chest-2', 'lat-raise-dropset', 'Lateral Raise Dropset', 3, 'AMRAP', '20', false, 'lateral-raise'),
      te('plan-chest-2', 'cable-flyes', 'Cable Flyes', 3, '10-15', '20', false, 'cable-fly'),
      te('plan-chest-2', 'cable-lat-raise', 'Cable Lateral Raise', 4, '12-15', '15', false, 'lateral-raise'),
      te('plan-chest-2', 'oh-tricep', 'Overhead Tricep Extension', 3, '10-12', '70', false, 'overhead-tricep-extension'),
      te('plan-chest-2', 'incline-cable-curl', 'Incline Cable Curl', 3, '10-12', '20', false, 'incline-cable-curl'),
      te('plan-chest-2', 'rev-crunches', 'Weighted Reverse Crunches', 3, '10-12', '25', false, 'reverse-crunch'),
    ],
  },
  {
    id: 'plan-legs',
    name: 'Legs',
    exercises: [
      te('plan-legs', 'leg-press-squat', 'Leg Press / Squat', 4, '6-10', '275', false, 'leg-press'),
      te('plan-legs', 'rdl', 'RDL', 4, '8-12', '135', false, 'romanian-deadlift'),
      te('plan-legs', 'seated-ham-curl', 'Seated Hamstring Curl', 3, '10-15', '140', false, 'hamstring-curl'),
      te('plan-legs', 'leg-extension', 'Leg Extension', 3, '12-15', '140', false, 'leg-extension'),
      te('plan-legs', 'calf-raises', 'Calf Raises', 4, '12-20', '225', false, 'calf-raise'),
      te('plan-legs', 'walking-lunges', 'Walking Lunges', 2, '10-12', '40', false, 'walking-lunge'),
    ],
  },
  {
    id: 'plan-push',
    name: 'Push',
    exercises: [
      te('plan-push', 'bench', 'Barbell Bench Press', 4, '6-10', '135', false, 'bench-press'),
      te('plan-push', 'incline-db', 'Incline DB Press', 3, '8-12', '55', false, 'incline-dumbbell-press'),
      te('plan-push', 'ohp', 'Overhead Press', 3, '8-12', '95', false, 'overhead-press'),
      te('plan-push', 'lat-raise', 'Lateral Raise', 3, '12-15', '20', false, 'lateral-raise'),
      te('plan-push', 'pushdown', 'Tricep Pushdown', 3, '10-12', '70', false, 'tricep-pushdown'),
      te('plan-push', 'cable-crunch', 'Cable Crunch', 3, '12-15', '90', false, 'cable-crunch'),
    ],
  },
  {
    id: 'plan-pull',
    name: 'Pull',
    exercises: [
      te('plan-pull', 'pull-up', 'Pull-Up', 4, 'AMRAP', '0', false, 'pull-up'),
      te('plan-pull', 'chest-row', 'Chest Supported Row', 3, '8-12', '35', false, 'chest-supported-row'),
      te('plan-pull', 'lat-pd', 'Lat Pulldown', 3, '10-12', '100', false, 'lat-pulldown'),
      te('plan-pull', 'face-pull', 'Face Pull', 3, '15-20', '90', false, 'face-pull'),
      te('plan-pull', 'hammer', 'Hammer Curl', 3, '10-12', '25', false, 'hammer-curl'),
      te('plan-pull', 'bb-curl', 'Barbell Curl', 3, '10-12', '65', false, 'barbell-curl'),
    ],
  },
  {
    id: 'plan-full-body-a',
    name: 'Full Body A',
    exercises: [
      te('plan-full-body-a', 'squat', 'Barbell Back Squat', 4, '5-8', '185', false, 'squat'),
      te('plan-full-body-a', 'bench', 'Barbell Bench Press', 3, '8-10', '135', false, 'bench-press'),
      te('plan-full-body-a', 'row', 'Barbell Row', 3, '8-10', '115', false, 'barbell-row'),
      te('plan-full-body-a', 'rdl', 'Romanian Deadlift', 3, '8-12', '135', false, 'romanian-deadlift'),
    ],
  },
  {
    id: 'plan-full-body-b',
    name: 'Full Body B',
    exercises: [
      te('plan-full-body-b', 'deadlift', 'Conventional Deadlift', 3, '5-8', '225', false, 'deadlift'),
      te('plan-full-body-b', 'ohp', 'Overhead Press', 3, '8-12', '85', false, 'overhead-press'),
      te('plan-full-body-b', 'leg-press', 'Leg Press', 3, '10-15', '270', false, 'leg-press'),
      te('plan-full-body-b', 'pull-up', 'Pull-Up', 3, 'AMRAP', '0', false, 'pull-up'),
      te('plan-full-body-b', 'hip-thrust', 'Hip Thrust', 3, '10-12', '135', false, 'hip-thrust'),
    ],
  },
  {
    id: 'plan-glutes-posterior',
    name: 'Glutes & Posterior',
    exercises: [
      te('plan-glutes-posterior', 'hip-thrust', 'Hip Thrust', 4, '8-12', '155', false, 'hip-thrust'),
      te('plan-glutes-posterior', 'rdl', 'Romanian Deadlift', 3, '10-12', '125', false, 'romanian-deadlift'),
      te('plan-glutes-posterior', 'ham-curl', 'Hamstring Curl', 3, '12-15', '130', false, 'hamstring-curl'),
      te('plan-glutes-posterior', 'lunge', 'Walking Lunge', 3, '10-12', '35', false, 'walking-lunge'),
      te('plan-glutes-posterior', 'goblet', 'Goblet Squat', 2, '12-15', '40', false, 'goblet-squat'),
    ],
  },
  {
    id: 'plan-arms-core',
    name: 'Arms & Core',
    exercises: [
      te('plan-arms-core', 'bb-curl', 'Barbell Curl', 3, '10-12', '65', false, 'barbell-curl'),
      te('plan-arms-core', 'hammer', 'Hammer Curl', 3, '10-12', '25', false, 'hammer-curl'),
      te('plan-arms-core', 'cable-curl', 'Cable Curl', 3, '12-15', '35', false, 'cable-curl'),
      te('plan-arms-core', 'pushdown', 'Tricep Pushdown', 3, '10-12', '65', false, 'tricep-pushdown'),
      te('plan-arms-core', 'oh-tri', 'Overhead Tricep Extension', 3, '10-12', '55', false, 'overhead-tricep-extension'),
      te('plan-arms-core', 'cable-crunch', 'Cable Crunch', 3, '12-15', '85', false, 'cable-crunch'),
      te('plan-arms-core', 'plank', 'Plank', 3, '45 sec', '0', false, 'plank'),
    ],
  },
  {
    id: 'plan-core-conditioning',
    name: 'Core & Conditioning',
    exercises: [
      te('plan-core-conditioning', 'cable-crunch', 'Cable Crunch', 3, '15-20', '90', false, 'cable-crunch'),
      te('plan-core-conditioning', 'leg-raise', 'Hanging Leg Raise', 3, '10-15', '0', false, 'leg-raise'),
      te('plan-core-conditioning', 'rev-crunch', 'Reverse Crunch', 3, '12-15', '0', false, 'reverse-crunch'),
      te('plan-core-conditioning', 'woodchop', 'Cable Woodchop', 3, '10-12', '35', false, 'cable-woodchop'),
      te('plan-core-conditioning', 'push-up', 'Push-Up', 3, 'AMRAP', '0', false, 'push-up'),
    ],
  },
]

export const SBD_STRENGTH_FOLDER: TemplateFolder = {
  id: 'folder-sbd-strength',
  name: 'SBD Strength',
  purpose:
    'Three-week strength block centered on squat, bench, and deadlift. Goal: build max force via progressive overload, technical practice, and targeted accessories.',
}

function sbdPlanId(week: number, day: number): string {
  return `plan-sbd-w${week}-d${day}`
}

function buildSbdWeekPlans(week: number, loadBump: number): WorkoutTemplate[] {
  const squat = `${225 + loadBump}`
  const bench = `${165 + loadBump}`
  const deadlift = `${275 + loadBump * 2}`

  return [
    {
      id: sbdPlanId(week, 1),
      name: `Week ${week} - Day 1: Squat Volume + Bench Technique`,
      folderId: SBD_STRENGTH_FOLDER.id,
      exercises: [
        te(sbdPlanId(week, 1), 'back-squat', 'Barbell Back Squat', 5, '5', squat, false, 'squat'),
        te(sbdPlanId(week, 1), 'paused-bench', 'Paused Barbell Bench Press', 6, '3', bench, false, 'bench-press'),
        te(sbdPlanId(week, 1), 'front-squat', 'Front Squat', 3, '5', `${165 + loadBump}`, false, 'front-squat'),
        te(sbdPlanId(week, 1), 'row', 'Barbell Row', 4, '8', `${135 + loadBump}`, false, 'barbell-row'),
        te(sbdPlanId(week, 1), 'core', 'Pallof Press', 3, '12', '40', false, 'pallof-press'),
      ],
    },
    {
      id: sbdPlanId(week, 2),
      name: `Week ${week} - Day 2: Deadlift Volume + Bench Hypertrophy`,
      folderId: SBD_STRENGTH_FOLDER.id,
      exercises: [
        te(sbdPlanId(week, 2), 'deadlift', 'Conventional Deadlift', 5, '4', deadlift, false, 'deadlift'),
        te(sbdPlanId(week, 2), 'bench', 'Barbell Bench Press', 4, '6', `${175 + loadBump}`, false, 'bench-press'),
        te(sbdPlanId(week, 2), 'rdl', 'Romanian Deadlift (RDL)', 3, '6', `${185 + loadBump}`, false, 'romanian-deadlift'),
        te(sbdPlanId(week, 2), 'row', 'Pendlay Row', 4, '6', `${145 + loadBump}`, false, 'pendlay-row'),
        te(sbdPlanId(week, 2), 'hamstrings', 'Nordic Hamstring Curl', 3, '6', '0', false, 'nordic-hamstring-curl'),
      ],
    },
    {
      id: sbdPlanId(week, 3),
      name: `Week ${week} - Day 3: Bench Intensity + Squat Technique`,
      folderId: SBD_STRENGTH_FOLDER.id,
      exercises: [
        te(sbdPlanId(week, 3), 'bench-heavy', 'Barbell Bench Press', 6, '3', `${195 + loadBump}`, false, 'bench-press'),
        te(sbdPlanId(week, 3), 'back-squat-pause', 'Paused Barbell Back Squat', 4, '3', `${205 + loadBump}`, false, 'squat'),
        te(sbdPlanId(week, 3), 'close-grip', 'Close-Grip Bench Press', 3, '6', `${165 + loadBump}`, false, 'bench-press'),
        te(sbdPlanId(week, 3), 'shoulders', 'Overhead Press', 3, '6', `${95 + Math.floor(loadBump / 2)}`, false, 'overhead-press'),
        te(sbdPlanId(week, 3), 'triceps', 'Skull Crusher (Lying Triceps Extension)', 3, '10', '60', false, 'skull-crusher'),
      ],
    },
    {
      id: sbdPlanId(week, 4),
      name: `Week ${week} - Day 4: Squat Intensity + Deadlift Technique`,
      folderId: SBD_STRENGTH_FOLDER.id,
      exercises: [
        te(sbdPlanId(week, 4), 'back-squat-heavy', 'Barbell Back Squat', 6, '2', `${255 + loadBump}`, false, 'squat'),
        te(sbdPlanId(week, 4), 'tempo-deadlift', 'Tempo Conventional Deadlift', 4, '3', `${245 + loadBump}`, false, 'deadlift'),
        te(sbdPlanId(week, 4), 'split-squat', 'Bulgarian Split Squat', 3, '8', `${40 + Math.floor(loadBump / 5)}`, false, 'bulgarian-split-squat'),
        te(sbdPlanId(week, 4), 'pull-through', 'Cable Pull-Through', 3, '12', `${80 + loadBump}`, false, 'cable-pull-through'),
        te(sbdPlanId(week, 4), 'abs', 'Cable Crunch', 3, '12', '100', false, 'cable-crunch'),
      ],
    },
    {
      id: sbdPlanId(week, 5),
      name: `Week ${week} - Day 5: Deadlift Intensity + Bench Speed`,
      folderId: SBD_STRENGTH_FOLDER.id,
      exercises: [
        te(sbdPlanId(week, 5), 'deadlift-heavy', 'Conventional Deadlift', 6, '2', `${315 + loadBump * 2}`, false, 'deadlift'),
        te(sbdPlanId(week, 5), 'bench-speed', 'Speed Barbell Bench Press', 8, '3', `${145 + loadBump}`, false, 'bench-press'),
        te(sbdPlanId(week, 5), 'sumo-variation', 'Sumo Deadlift', 3, '5', `${275 + loadBump * 2}`, false, 'sumo-deadlift'),
        te(sbdPlanId(week, 5), 'upper-back', 'T-Bar Row', 4, '8', `${135 + loadBump}`, false, 't-bar-row'),
        te(sbdPlanId(week, 5), 'grip', "Farmer's Carry", 4, '30m', `${70 + Math.floor(loadBump / 2)}`, false, 'farmers-walk'),
      ],
    },
    {
      id: sbdPlanId(week, 6),
      name: `Week ${week} - Day 6: Bench Volume + Upper Back`,
      folderId: SBD_STRENGTH_FOLDER.id,
      exercises: [
        te(sbdPlanId(week, 6), 'bench-volume', 'Barbell Bench Press', 5, '5', `${180 + loadBump}`, false, 'bench-press'),
        te(sbdPlanId(week, 6), 'incline', 'Incline Dumbbell Press', 4, '8', `${60 + Math.floor(loadBump / 2)}`, false, 'incline-dumbbell-press'),
        te(sbdPlanId(week, 6), 'row', 'Chest Supported Row', 4, '10', `${50 + Math.floor(loadBump / 2)}`, false, 'chest-supported-row'),
        te(sbdPlanId(week, 6), 'lat-work', 'Lat Pulldown', 3, '10', `${120 + loadBump}`, false, 'lat-pulldown'),
        te(sbdPlanId(week, 6), 'rear-delts', 'Face Pull', 3, '15', '80', false, 'face-pull'),
      ],
    },
    {
      id: sbdPlanId(week, 7),
      name: `Week ${week} - Day 7: Recovery / GPP + Technique`,
      folderId: SBD_STRENGTH_FOLDER.id,
      exercises: [
        te(sbdPlanId(week, 7), 'tech-squat', 'Technique Barbell Back Squat', 3, '5', `${155 + loadBump}`, false, 'squat'),
        te(sbdPlanId(week, 7), 'tech-bench', 'Technique Barbell Bench Press', 3, '5', `${115 + loadBump}`, false, 'bench-press'),
        te(sbdPlanId(week, 7), 'tech-deadlift', 'Technique Conventional Deadlift', 3, '3', `${185 + loadBump}`, false, 'deadlift'),
        te(sbdPlanId(week, 7), 'swings', 'Kettlebell Swing', 4, '15', '24', false, 'kettlebell-swing'),
        te(sbdPlanId(week, 7), 'core', 'Plank', 3, '60 sec', '0', false, 'plank'),
      ],
    },
  ]
}

export const SBD_STRENGTH_PLANS: WorkoutTemplate[] = [
  ...buildSbdWeekPlans(1, 0),
  ...buildSbdWeekPlans(2, 10),
  ...buildSbdWeekPlans(3, 20),
]

export const CALISTHENICS_FULL_BODY_FOLDER: TemplateFolder = {
  id: 'folder-calisthenics-full-body',
  name: 'Calisthenics Full Body Week',
  purpose:
    'One-week full-body bodyweight block to build strength, control, and work capacity using push, pull, squat, hinge, and core patterns with minimal equipment.',
}

export const CALISTHENICS_FULL_BODY_PLANS: WorkoutTemplate[] = [
  {
    id: 'plan-cali-w1-d1',
    name: 'Week 1 - Day 1: Push + Squat Foundation',
    folderId: CALISTHENICS_FULL_BODY_FOLDER.id,
    exercises: [
      te('plan-cali-w1-d1', 'pushup', 'Push-Up', 4, '8-15', '0', false, 'push-up'),
      te('plan-cali-w1-d1', 'pike', 'Pike Push-Up', 4, '6-10', '0', false, 'pike-push-up'),
      te('plan-cali-w1-d1', 'squat', 'Bodyweight Squat', 4, '15-20', '0', false, 'bodyweight-squat'),
      te('plan-cali-w1-d1', 'lunge', 'Walking Lunge', 3, '10/side', '0', false, 'walking-lunge'),
      te('plan-cali-w1-d1', 'plank', 'Plank', 3, '45-60 sec', '0', false, 'plank'),
    ],
  },
  {
    id: 'plan-cali-w1-d2',
    name: 'Week 1 - Day 2: Pull + Posterior Chain',
    folderId: CALISTHENICS_FULL_BODY_FOLDER.id,
    exercises: [
      te('plan-cali-w1-d2', 'pullup', 'Pull-Up', 5, 'AMRAP', '0', false, 'pull-up'),
      te('plan-cali-w1-d2', 'inv-row', 'Inverted Row', 4, '8-12', '0', false, 'inverted-row'),
      te('plan-cali-w1-d2', 'bridge', 'Glute Bridge', 4, '12-20', '0', false, 'glute-bridge'),
      te('plan-cali-w1-d2', 'reverse-crunch', 'Reverse Crunch', 3, '12-15', '0', false, 'reverse-crunch'),
      te('plan-cali-w1-d2', 'hollow', 'Hollow Body Hold', 3, '20-40 sec', '0', false, 'hollow-body-hold'),
    ],
  },
  {
    id: 'plan-cali-w1-d3',
    name: 'Week 1 - Day 3: Conditioning Circuit',
    folderId: CALISTHENICS_FULL_BODY_FOLDER.id,
    exercises: [
      te('plan-cali-w1-d3', 'burpee', 'Burpee', 5, '10', '0', true, 'burpee'),
      te('plan-cali-w1-d3', 'pushup', 'Push-Up', 5, '10-15', '0', true, 'push-up'),
      te('plan-cali-w1-d3', 'squat', 'Bodyweight Squat', 5, '20', '0', true, 'bodyweight-squat'),
      te('plan-cali-w1-d3', 'row', 'Inverted Row', 5, '8-10', '0', true, 'inverted-row'),
      te('plan-cali-w1-d3', 'mountain', 'Mountain Climber', 5, '30 sec', '0', true, 'mountain-climber'),
    ],
  },
  {
    id: 'plan-cali-w1-d4',
    name: 'Week 1 - Day 4: Recovery Mobility + Core',
    folderId: CALISTHENICS_FULL_BODY_FOLDER.id,
    exercises: [
      te('plan-cali-w1-d4', 'squat-tech', 'Bodyweight Squat', 3, '12', '0', false, 'bodyweight-squat'),
      te('plan-cali-w1-d4', 'bridge', 'Glute Bridge', 3, '15', '0', false, 'glute-bridge'),
      te('plan-cali-w1-d4', 'leg-raise', 'Hanging Leg Raise', 3, '8-12', '0', false, 'leg-raise'),
      te('plan-cali-w1-d4', 'plank', 'Plank', 3, '45 sec', '0', false, 'plank'),
      te('plan-cali-w1-d4', 'hollow', 'Hollow Body Hold', 3, '20-30 sec', '0', false, 'hollow-body-hold'),
    ],
  },
  {
    id: 'plan-cali-w1-d5',
    name: 'Week 1 - Day 5: Upper Body Strength',
    folderId: CALISTHENICS_FULL_BODY_FOLDER.id,
    exercises: [
      te('plan-cali-w1-d5', 'dip', 'Chest Dip', 4, '6-10', '0', false, 'chest-dip'),
      te('plan-cali-w1-d5', 'pullup', 'Pull-Up', 4, 'AMRAP', '0', false, 'pull-up'),
      te('plan-cali-w1-d5', 'pike', 'Pike Push-Up', 4, '6-10', '0', false, 'pike-push-up'),
      te('plan-cali-w1-d5', 'row', 'Inverted Row', 3, '10-12', '0', false, 'inverted-row'),
      te('plan-cali-w1-d5', 'core', 'Pallof Press', 3, '12', '0', false, 'pallof-press'),
    ],
  },
  {
    id: 'plan-cali-w1-d6',
    name: 'Week 1 - Day 6: Lower Body + Work Capacity',
    folderId: CALISTHENICS_FULL_BODY_FOLDER.id,
    exercises: [
      te('plan-cali-w1-d6', 'squat', 'Bodyweight Squat', 5, '20', '0', false, 'bodyweight-squat'),
      te('plan-cali-w1-d6', 'lunge', 'Walking Lunge', 4, '12/side', '0', false, 'walking-lunge'),
      te('plan-cali-w1-d6', 'bridge', 'Glute Bridge', 4, '20', '0', false, 'glute-bridge'),
      te('plan-cali-w1-d6', 'burpee', 'Burpee', 4, '8', '0', false, 'burpee'),
      te('plan-cali-w1-d6', 'mountain', 'Mountain Climber', 4, '30 sec', '0', false, 'mountain-climber'),
    ],
  },
  {
    id: 'plan-cali-w1-d7',
    name: 'Week 1 - Day 7: Full Body Test Day',
    folderId: CALISTHENICS_FULL_BODY_FOLDER.id,
    exercises: [
      te('plan-cali-w1-d7', 'pushup', 'Push-Up', 3, 'AMRAP', '0', false, 'push-up'),
      te('plan-cali-w1-d7', 'pullup', 'Pull-Up', 3, 'AMRAP', '0', false, 'pull-up'),
      te('plan-cali-w1-d7', 'squat', 'Bodyweight Squat', 3, 'AMRAP (60 sec)', '0', false, 'bodyweight-squat'),
      te('plan-cali-w1-d7', 'leg-raise', 'Hanging Leg Raise', 3, 'AMRAP', '0', false, 'leg-raise'),
      te('plan-cali-w1-d7', 'plank', 'Plank', 3, 'max hold', '0', false, 'plank'),
    ],
  },
]
