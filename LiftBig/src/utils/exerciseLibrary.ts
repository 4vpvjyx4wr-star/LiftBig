export const MUSCLE_GROUPS = [
  'chest',
  'back',
  'shoulders',
  'biceps',
  'triceps',
  'quads',
  'hamstrings',
  'glutes',
  'calves',
  'core',
  'forearms',
] as const

export type MuscleGroup = (typeof MUSCLE_GROUPS)[number]

export type LibraryExercise = {
  id: string
  name: string
  muscleGroups: MuscleGroup[]
  equipment?: string
  summary: string
  instructions: string[]
  tips?: string[]
}

export const MUSCLE_GROUP_LABELS: Record<MuscleGroup, string> = {
  chest: 'Chest',
  back: 'Back',
  shoulders: 'Shoulders',
  biceps: 'Biceps',
  triceps: 'Triceps',
  quads: 'Quads',
  hamstrings: 'Hamstrings',
  glutes: 'Glutes',
  calves: 'Calves',
  core: 'Core',
  forearms: 'Forearms',
}

const byId = new Map<string, LibraryExercise>()

function reg(ex: LibraryExercise): LibraryExercise {
  byId.set(ex.id, ex)
  return ex
}

export const EXERCISE_LIBRARY: LibraryExercise[] = [
  reg({
    id: 'bench-press',
    name: 'Barbell Bench Press',
    muscleGroups: ['chest', 'triceps', 'shoulders'],
    equipment: 'Barbell',
    summary: 'Horizontal press for chest with barbell on a flat bench.',
    instructions: [
      'Lie on the bench with eyes under the bar; feet flat on the floor.',
      'Grip slightly wider than shoulders, squeeze shoulder blades together on the bench.',
      'Unrack with straight wrists; bar over mid-chest.',
      'Lower with control to the lower chest; keep elbows ~45° from torso.',
      'Press up in a slight arc back over the shoulders; lock out without shrugging.',
    ],
    tips: [
      'Do not bounce the bar off the chest.',
      'Keep a slight arch in the upper back, not the lower back off the bench.',
    ],
  }),
  reg({
    id: 'incline-dumbbell-press',
    name: 'Incline Dumbbell Press',
    muscleGroups: ['chest', 'shoulders', 'triceps'],
    equipment: 'Dumbbell',
    summary: 'Upper-chest focused press on an inclined bench.',
    instructions: [
      'Set bench to ~30–45°; sit with dumbbells on thighs, lie back and press to start.',
      'Dumbbells over shoulders, palms facing forward or slightly in.',
      'Lower until elbows are at or just below shoulder level.',
      'Press up and slightly together without clanking the weights.',
    ],
    tips: ['Avoid excessive arch; keep ribs down and glutes on the pad.'],
  }),
  reg({
    id: 'flat-dumbbell-press',
    name: 'Flat Dumbbell Press',
    muscleGroups: ['chest', 'triceps', 'shoulders'],
    equipment: 'Dumbbell',
    summary: 'Chest press with dumbbells on a flat bench.',
    instructions: [
      'Lie flat, dumbbells at chest level, feet planted.',
      'Press up until arms are extended; dumbbells can touch lightly at the top.',
      'Lower with control, elbows ~45° from sides.',
    ],
    tips: ['Use a weight you can control for the full range without flaring elbows to 90°.'],
  }),
  reg({
    id: 'pull-up',
    name: 'Pull-Up',
    muscleGroups: ['back', 'biceps'],
    equipment: 'Bodyweight',
    summary: 'Vertical pull using body weight on a fixed bar.',
    instructions: [
      'Hang with full grip, arms extended, shoulders engaged (not fully relaxed).',
      'Pull chest toward the bar by driving elbows down and back.',
      'Clear the chin over the bar or get chest to bar depending on goal.',
      'Lower with control to full hang.',
    ],
    tips: ['Avoid excessive kipping unless training specifically for it.'],
  }),
  reg({
    id: 'lat-pulldown',
    name: 'Lat Pulldown',
    muscleGroups: ['back', 'biceps'],
    equipment: 'Cable',
    summary: 'Machine/cable vertical pull to train lats.',
    instructions: [
      'Grip bar wider than shoulders; sit with thighs secured under the pad.',
      'Lean slightly back, brace core, pull bar to upper chest.',
      'Drive elbows down and in toward ribs.',
      'Control the return until arms are nearly straight.',
    ],
    tips: ['Do not pull behind the neck; keep movement in front.'],
  }),
  reg({
    id: 'barbell-row',
    name: 'Barbell Row',
    muscleGroups: ['back', 'biceps', 'forearms'],
    equipment: 'Barbell',
    summary: 'Hinge and pull a barbell to the torso.',
    instructions: [
      'Hinge at hips with soft knees; torso ~45° or more horizontal.',
      'Grip bar shoulder-width; arms hang straight.',
      'Pull bar to lower ribs/upper abdomen, squeezing shoulder blades.',
      'Lower with control without rounding the lower back.',
    ],
    tips: ['Maintain neutral spine; use straps only if grip limits working sets.'],
  }),
  reg({
    id: 'dumbbell-row',
    name: 'Dumbbell Row',
    muscleGroups: ['back', 'biceps', 'forearms'],
    equipment: 'Dumbbell',
    summary: 'One-arm or two-arm row with dumbbells.',
    instructions: [
      'Hinge or support on bench; dumbbell hangs straight down.',
      'Pull elbow back toward hip/ribs without rotating torso excessively.',
      'Squeeze lat at top; lower with control.',
    ],
    tips: ['Keep neck neutral; avoid jerking the weight.'],
  }),
  reg({
    id: 'chest-supported-row',
    name: 'Chest Supported Row',
    muscleGroups: ['back', 'biceps'],
    equipment: 'Dumbbell',
    summary: 'Row lying face-down on an incline bench to isolate the back.',
    instructions: [
      'Set bench ~30–45°; lie chest-down with dumbbells hanging.',
      'Pull weights toward hips/lower ribs with elbows tracking back.',
      'Squeeze mid-back at the top; lower slowly.',
    ],
    tips: ['Great for reducing lower-back fatigue from bent-over rows.'],
  }),
  reg({
    id: 'seated-cable-row',
    name: 'Seated Cable Row',
    muscleGroups: ['back', 'biceps'],
    equipment: 'Cable',
    summary: 'Seated horizontal pull on a low cable.',
    instructions: [
      'Sit tall, slight knee bend, grab handle with arms extended.',
      'Pull to lower ribs/upper abdomen without excessive torso swing.',
      'Squeeze shoulder blades; return until arms extend with tension.',
    ],
    tips: ['Keep chest proud; avoid rounding forward at end range.'],
  }),
  reg({
    id: 'face-pull',
    name: 'Face Pull',
    muscleGroups: ['shoulders', 'back'],
    equipment: 'Cable',
    summary: 'Rope pull to face height for rear delts and external rotation.',
    instructions: [
      'Set cable at upper chest/face height; use rope attachment.',
      'Pull rope toward face, elbows high and wide.',
      'Finish with hands beside ears, externally rotating shoulders.',
      'Control the stack on the way forward.',
    ],
    tips: ['Light-to-moderate weight; quality of rotation matters more than load.'],
  }),
  reg({
    id: 'overhead-press',
    name: 'Overhead Press',
    muscleGroups: ['shoulders', 'triceps'],
    equipment: 'Barbell',
    summary: 'Standing or seated vertical press.',
    instructions: [
      'Bar at shoulders, grip just outside shoulders, wrists stacked.',
      'Brace core and glutes; press straight up, moving head slightly back then through.',
      'Lock out overhead with biceps by ears.',
      'Lower to shoulders with control.',
    ],
    tips: ['Avoid excessive lower-back arch; squeeze glutes and ribs down.'],
  }),
  reg({
    id: 'lateral-raise',
    name: 'Lateral Raise',
    muscleGroups: ['shoulders'],
    equipment: 'Dumbbell',
    summary: 'Raise arms to the sides for medial delts.',
    instructions: [
      'Stand with dumbbells at sides, slight bend in elbows.',
      'Raise to shoulder height with pinkies slightly high (pour water cue).',
      'Lower with control; stop short of full rest between reps if desired.',
    ],
    tips: ['Avoid swinging or using momentum from the legs.'],
  }),
  reg({
    id: 'rear-delt-fly',
    name: 'Rear Delt Fly',
    muscleGroups: ['shoulders', 'back'],
    equipment: 'Dumbbell',
    summary: 'Bent-over or chest-supported fly for rear delts.',
    instructions: [
      'Hinge forward or use incline support; arms hang under shoulders.',
      'Open arms wide with soft elbows, squeezing rear delts.',
      'Pause briefly; return without rounding the spine.',
    ],
    tips: ['Use lighter weight; focus on scapular retraction.'],
  }),
  reg({
    id: 'tricep-pushdown',
    name: 'Tricep Pushdown',
    muscleGroups: ['triceps'],
    equipment: 'Cable',
    summary: 'Cable extension with elbows fixed at the sides.',
    instructions: [
      'Stand facing high pulley; elbows pinned to ribs.',
      'Extend forearms down until arms straight.',
      'Squeeze triceps; return to ~90° elbow bend under control.',
    ],
    tips: ['Do not let elbows drift forward or shoulders roll forward.'],
  }),
  reg({
    id: 'overhead-tricep-extension',
    name: 'Overhead Tricep Extension',
    muscleGroups: ['triceps'],
    equipment: 'Dumbbell',
    summary: 'Triceps stretch position with arms overhead.',
    instructions: [
      'Hold one dumbbell with both hands or single-arm; arms overhead.',
      'Lower behind head by bending elbows while keeping upper arms vertical.',
      'Extend back to lockout without flaring ribs.',
    ],
    tips: ['Keep elbows pointing up, not drifting forward.'],
  }),
  reg({
    id: 'barbell-curl',
    name: 'Barbell Curl',
    muscleGroups: ['biceps', 'forearms'],
    equipment: 'Barbell',
    summary: 'Classic standing curl for biceps.',
    instructions: [
      'Stand with bar at thighs, supinated grip about shoulder width.',
      'Curl toward shoulders without swinging the hips.',
      'Lower slowly to full elbow extension.',
    ],
    tips: ['Avoid leaning back to move the weight.'],
  }),
  reg({
    id: 'hammer-curl',
    name: 'Hammer Curl',
    muscleGroups: ['biceps', 'forearms'],
    equipment: 'Dumbbell',
    summary: 'Neutral-grip curl for brachialis and forearms.',
    instructions: [
      'Hold dumbbells with palms facing each other.',
      'Curl up keeping wrists neutral.',
      'Lower with control.',
    ],
    tips: ['Alternate arms or both together depending on preference.'],
  }),
  reg({
    id: 'incline-cable-curl',
    name: 'Incline Cable Curl',
    muscleGroups: ['biceps'],
    equipment: 'Cable',
    summary: 'Curl on an incline bench with low cable for long-head bias.',
    instructions: [
      'Set bench ~45° facing away from low pulley; grab bar or handles.',
      'Arms hang straight down with elbows behind torso.',
      'Curl toward shoulders without letting elbows drift forward.',
      'Lower with full control.',
    ],
    tips: ['Lighter weight than standing curls; stretch at bottom is normal.'],
  }),
  reg({
    id: 'cable-curl',
    name: 'Cable Curl',
    muscleGroups: ['biceps'],
    equipment: 'Cable',
    summary: 'Constant tension curl from a low pulley.',
    instructions: [
      'Face the stack; elbows at sides.',
      'Curl handle toward shoulders.',
      'Control the eccentric; keep elbows fixed.',
    ],
    tips: ['Step back slightly for a better line of pull.'],
  }),
  reg({
    id: 'squat',
    name: 'Barbell Back Squat',
    muscleGroups: ['quads', 'glutes', 'core'],
    equipment: 'Barbell',
    summary: 'Primary lower-body compound with bar on upper back.',
    instructions: [
      'Bar on traps/rear delts; walk out with tight core.',
      'Break at hips and knees simultaneously.',
      'Descend until depth allows flat feet and neutral spine.',
      'Drive up through mid-foot, chest tall.',
    ],
    tips: ['Knees track over toes; avoid collapsing inward.'],
  }),
  reg({
    id: 'leg-press',
    name: 'Leg Press',
    muscleGroups: ['quads', 'glutes'],
    equipment: 'Machine',
    summary: 'Machine squat pattern with back supported.',
    instructions: [
      'Feet shoulder-width on platform; release safety.',
      'Lower until knees ~90° or comfortable depth without butt rounding off pad.',
      'Press platform up without locking knees aggressively.',
    ],
    tips: ['Foot placement shifts emphasis: higher = more glutes/hams; lower = more quads.'],
  }),
  reg({
    id: 'leg-extension',
    name: 'Leg Extension',
    muscleGroups: ['quads'],
    equipment: 'Machine',
    summary: 'Isolated knee extension for quads.',
    instructions: [
      'Sit with back on pad; ankles under roller.',
      'Extend knees to straight legs without snapping.',
      'Lower with control; avoid excessive torso swing.',
    ],
    tips: ['Moderate weight; control the negative to protect knees.'],
  }),
  reg({
    id: 'dumbbell-romanian-deadlift',
    name: 'Dumbbell Romanian Deadlift',
    muscleGroups: ['hamstrings', 'glutes', 'back'],
    equipment: 'Dumbbell',
    summary: 'Hip hinge holding dumbbells for hamstrings and glutes.',
    instructions: [
      'Stand holding dumbbells at sides, feet hip-width, soft knees.',
      'Push hips back, lowering dumbbells along legs.',
      'Stop before lower back rounds; feel hamstring stretch.',
      'Drive hips forward to stand.',
    ],
    tips: ['Keep dumbbells close to legs; neutral neck.'],
  }),
  reg({
    id: 'romanian-deadlift',
    name: 'Romanian Deadlift (RDL)',
    muscleGroups: ['hamstrings', 'glutes', 'back'],
    equipment: 'Barbell',
    summary: 'Hip hinge with soft knees for hamstrings and glutes.',
    instructions: [
      'Stand holding bar at hips, feet hip-width.',
      'Push hips back, bar slides down thighs; knees slightly bent.',
      'Feel stretch in hamstrings; stop before lower back rounds.',
      'Drive hips forward to stand tall.',
    ],
    tips: ['Bar stays close to legs; neck neutral.'],
  }),
  reg({
    id: 'deadlift',
    name: 'Conventional Deadlift',
    muscleGroups: ['glutes', 'hamstrings', 'back'],
    equipment: 'Barbell',
    summary: 'Lift bar from floor with hip hinge and leg drive.',
    instructions: [
      'Mid-foot under bar; grip outside knees, hips higher than squat.',
      'Brace lats, pull slack out, push floor away.',
      'Bar travels straight up; lock hips and knees together at top.',
      'Hinge down with control.',
    ],
    tips: ['Neutral spine throughout; do not jerk off the floor.'],
  }),
  reg({
    id: 'hamstring-curl',
    name: 'Hamstring Curl',
    muscleGroups: ['hamstrings'],
    equipment: 'Machine',
    summary: 'Knee flexion seated or lying for hamstrings.',
    instructions: [
      'Secure pad on lower legs; start with legs extended.',
      'Curl heels toward glutes.',
      'Squeeze; return slowly.',
    ],
    tips: ['Avoid lifting hips off the bench on lying curls.'],
  }),
  reg({
    id: 'calf-raise',
    name: 'Calf Raise',
    muscleGroups: ['calves'],
    equipment: 'Machine',
    summary: 'Plantarflexion for gastrocnemius and soleus.',
    instructions: [
      'Balls of feet on platform, heels hanging.',
      'Rise onto toes as high as comfortable.',
      'Pause; lower past parallel for a stretch if safe.',
    ],
    tips: ['Straight-leg bias gastroc; bent-knee can bias soleus.'],
  }),
  reg({
    id: 'walking-lunge',
    name: 'Walking Lunge',
    muscleGroups: ['quads', 'glutes'],
    equipment: 'Dumbbell',
    summary: 'Alternating forward lunge while walking.',
    instructions: [
      'Step forward long enough that front knee stays over mid-foot.',
      'Drop back knee toward floor; torso tall.',
      'Push through front foot to step into next lunge.',
    ],
    tips: ['Short steps over-stress knee; stride for hip comfort.'],
  }),
  reg({
    id: 'goblet-squat',
    name: 'Goblet Squat',
    muscleGroups: ['quads', 'glutes', 'core'],
    equipment: 'Dumbbell',
    summary: 'Front-loaded squat holding one dumbbell at chest.',
    instructions: [
      'Hold dumbbell vertically at chest, elbows under.',
      'Squat down between hips; elbows can track inside knees.',
      'Drive up keeping chest up.',
    ],
    tips: ['Great for learning squat depth and torso position.'],
  }),
  reg({
    id: 'push-up',
    name: 'Push-Up',
    muscleGroups: ['chest', 'triceps', 'shoulders'],
    equipment: 'Bodyweight',
    summary: 'Horizontal press from plank position.',
    instructions: [
      'Hands under shoulders, body straight from head to heels.',
      'Lower chest toward floor; elbows ~45°.',
      'Press back up maintaining plank.',
    ],
    tips: ['Scale on knees or incline if needed.'],
  }),
  reg({
    id: 'cable-crunch',
    name: 'Cable Crunch',
    muscleGroups: ['core'],
    equipment: 'Cable',
    summary: 'Kneeling crunch with high cable for abs.',
    instructions: [
      'Kneel facing stack, rope behind head or at shoulders.',
      'Crunch down by flexing spine, not pulling with arms.',
      'Pause; control the return.',
    ],
    tips: ['Hips stay mostly still; movement is thoracic flexion.'],
  }),
  reg({
    id: 'cable-woodchop',
    name: 'Cable Woodchop',
    muscleGroups: ['core', 'shoulders'],
    equipment: 'Cable',
    summary: 'Diagonal chop for obliques and anti-rotation.',
    instructions: [
      'Stand sideways to cable; grab handle with both hands.',
      'Rotate and pull across body from high to low or low to high.',
      'Control the stack; brace core.',
    ],
    tips: ['Pivot feet slightly as needed for a full range.'],
  }),
  reg({
    id: 'machine-fly',
    name: 'Machine Fly / Pec Deck',
    muscleGroups: ['chest'],
    equipment: 'Machine',
    summary: 'Isolated chest adduction on a machine.',
    instructions: [
      'Set seat so handles align with mid-chest.',
      'Slight bend in elbows; bring handles together in front.',
      'Squeeze chest; return with stretch under control.',
    ],
    tips: ['Do not overstretch at the back position if shoulder feels pinchy.'],
  }),
  reg({
    id: 'cable-fly',
    name: 'Cable Fly',
    muscleGroups: ['chest'],
    equipment: 'Cable',
    summary: 'Standing or lying fly with cables.',
    instructions: [
      'Cables slightly above or at shoulder height.',
      'Soft elbows; arc hands together in front of chest.',
      'Control the stretch back without shrugging.',
    ],
    tips: ['Think hugging a tree, not pressing.'],
  }),
  reg({
    id: 'incline-machine-press',
    name: 'Incline Machine Press',
    muscleGroups: ['chest', 'shoulders', 'triceps'],
    equipment: 'Machine',
    summary: 'Guided incline press on a plate or pin-loaded machine.',
    instructions: [
      'Adjust seat so handles align with upper chest.',
      'Grip handles, press along machine path.',
      'Full extension without locking aggressively; control return.',
    ],
    tips: ['Keep head and shoulders on pad.'],
  }),
  reg({
    id: 'hip-thrust',
    name: 'Hip Thrust',
    muscleGroups: ['glutes', 'hamstrings'],
    equipment: 'Barbell',
    summary: 'Loaded glute bridge with upper back on bench.',
    instructions: [
      'Upper back on bench, bar over hips (use pad).',
      'Feet under knees; drive hips up to full extension.',
      'Squeeze glutes at top; chin tucked slightly.',
      'Lower with control.',
    ],
    tips: ['Do not hyperextend the lower back at the top.'],
  }),
  reg({
    id: 'plank',
    name: 'Plank',
    muscleGroups: ['core', 'shoulders'],
    equipment: 'Bodyweight',
    summary: 'Isometric anti-extension hold.',
    instructions: [
      'Forearms or hands on floor; body straight.',
      'Brace abs; squeeze glutes; breathe.',
      'Hold without hips sagging or piking.',
    ],
    tips: ['Quality over duration.'],
  }),
  reg({
    id: 'ab-machine-crunch',
    name: 'Ab Machine / Crunch',
    muscleGroups: ['core'],
    equipment: 'Machine',
    summary: 'Seated or kneeling crunch machine for abs.',
    instructions: [
      'Adjust seat and pad per machine instructions.',
      'Flex spine forward against resistance.',
      'Control the return; avoid pulling with arms only.',
    ],
    tips: ['Exhale on the crunch portion.'],
  }),
  reg({
    id: 'reverse-crunch',
    name: 'Reverse Crunch',
    muscleGroups: ['core'],
    equipment: 'Bodyweight',
    summary: 'Lift hips off floor to target lower abs.',
    instructions: [
      'Lie on back, knees bent 90°, hands at sides for balance.',
      'Curl pelvis off floor bringing knees toward chest.',
      'Lower with control.',
    ],
    tips: ['Small range; focus on posterior pelvic tilt.'],
  }),
  reg({
    id: 'leg-raise',
    name: 'Hanging Leg Raise',
    muscleGroups: ['core', 'quads'],
    equipment: 'Bodyweight',
    summary: 'Hang from bar and lift knees or legs.',
    instructions: [
      'Hang with active shoulders; slight posterior pelvic tilt.',
      'Raise knees toward chest or legs to parallel.',
      'Lower without swinging.',
    ],
    tips: ['Reduce range if you swing excessively.'],
  }),
]

export function getLibraryExercise(id: string): LibraryExercise | undefined {
  return byId.get(id)
}

export function searchLibrary(
  q: string,
  group: MuscleGroup | 'all',
): LibraryExercise[] {
  const needle = q.trim().toLowerCase()
  let list = EXERCISE_LIBRARY
  if (group !== 'all') {
    list = list.filter((ex) => ex.muscleGroups.includes(group))
  }
  if (!needle) return [...list].sort((a, b) => a.name.localeCompare(b.name))
  return list
    .filter((ex) => {
      if (ex.name.toLowerCase().includes(needle)) return true
      if (ex.summary.toLowerCase().includes(needle)) return true
      if (ex.equipment?.toLowerCase().includes(needle)) return true
      return ex.muscleGroups.some((g) => MUSCLE_GROUP_LABELS[g].toLowerCase().includes(needle))
    })
    .sort((a, b) => a.name.localeCompare(b.name))
}