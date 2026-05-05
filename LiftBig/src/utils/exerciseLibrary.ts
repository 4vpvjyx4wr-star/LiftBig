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
  /** Free-form labels for search and browsing (e.g. “unilateral”, “compound”). */
  tags?: string[]
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
    tags: ['compound', 'push', 'powerlifting'],
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
    tags: ['bodyweight', 'hanging', 'ab training'],
    equipment: 'Bodyweight',
    summary: 'Hang from bar and lift knees or legs.',
    instructions: [
      'Hang with active shoulders; slight posterior pelvic tilt.',
      'Raise knees toward chest or legs to parallel.',
      'Lower without swinging.',
    ],
    tips: ['Reduce range if you swing excessively.'],
  }),
  reg({
    id: 'arnold-press',
    name: 'Arnold Press',
    muscleGroups: ['shoulders', 'triceps'],
    tags: ['dumbbell', 'overhead', 'rotation'],
    equipment: 'Dumbbell',
    summary:
      'Seated or standing dumbbell press with palms rotating from inward at the bottom to forward at the top for fuller shoulder development.',
    instructions: [
      'Start with dumbbells at shoulder height, palms facing you like the bottom of a curl.',
      'Brace core; press up while rotating palms to face forward.',
      'Finish with arms overhead, biceps beside ears without shrugging.',
      'Reverse the rotation on the way down under control.',
    ],
    tips: [
      'Use a moderate weight—rotation adds instability.',
      'Keep ribs down to avoid excessive lower-back arch.',
    ],
  }),
  reg({
    id: 'bulgarian-split-squat',
    name: 'Bulgarian Split Squat',
    muscleGroups: ['quads', 'glutes'],
    tags: ['unilateral', 'single-leg', 'RFE squat'],
    equipment: 'Dumbbell',
    summary:
      'Rear-foot-elevated split squat that builds single-leg strength and balance while emphasizing quads and glutes.',
    instructions: [
      'Place rear foot on bench behind you; front foot far enough forward that knee tracks over ankle.',
      'Hold dumbbells at sides or one goblet-style.',
      'Lower until front thigh is near parallel or hip allows.',
      'Drive through the front mid-foot to stand; switch legs each set or alternate.',
    ],
    tips: [
      'If you feel knee irritation, shorten stride slightly.',
      'Lean torso slightly forward if you want more glute bias.',
    ],
  }),
  reg({
    id: 't-bar-row',
    name: 'T-Bar Row',
    muscleGroups: ['back', 'biceps', 'forearms'],
    tags: ['compound', 'pull', 'thick grip'],
    equipment: 'Barbell',
    summary:
      'Neutral-grip row using a landmine or T-bar setup—great for mid-back thickness with a stable torso.',
    instructions: [
      'Straddle the bar or use a chest-supported station if available.',
      'Hinge slightly; grip the handles with neutral wrists.',
      'Pull elbows back toward hips; squeeze shoulder blades.',
      'Lower until arms extend without rounding heavily.',
    ],
    tips: ['Keep chest tall; avoid jerking with hip extension unless doing a deliberate cheat variation.'],
  }),
  reg({
    id: 'pendlay-row',
    name: 'Pendlay Row',
    muscleGroups: ['back', 'biceps'],
    tags: ['explosive', 'dead-stop', 'powerlifting'],
    equipment: 'Barbell',
    summary:
      'Strict bent-over row where the bar rests on the floor each rep—explosive pull with a flat back.',
    instructions: [
      'Barbell on floor each rep; hinge until torso is roughly parallel to floor.',
      'Grip slightly wider than bench; brace lats and core.',
      'Pull bar to lower ribs explosively; pause briefly at the torso.',
      'Lower fully to the floor before the next rep.',
    ],
    tips: ['Reset brace each rep; do not touch-and-go if you want strict Pendlay style.'],
  }),
  reg({
    id: 'skull-crusher',
    name: 'Skull Crusher (Lying Triceps Extension)',
    muscleGroups: ['triceps'],
    tags: ['isolation', 'lying', 'elbow extension'],
    equipment: 'Barbell',
    summary:
      'Lying triceps extension lowering an EZ bar or bar toward the forehead or behind the head for long-head emphasis.',
    instructions: [
      'Lie on bench; bar over shoulders with narrow-to-medium grip.',
      'Keep upper arms angled slightly back toward the rack.',
      'Bend elbows to lower bar toward forehead or hairline.',
      'Extend to lockout without letting elbows flare wide.',
    ],
    tips: [
      'Use an EZ bar if wrists bother you on a straight bar.',
      'Stop short of pain at the elbow joint—switch to cables if needed.',
    ],
  }),
  reg({
    id: 'preacher-curl',
    name: 'Preacher Curl',
    muscleGroups: ['biceps', 'forearms'],
    tags: ['isolation', 'arms', 'strict curl'],
    equipment: 'Barbell',
    summary:
      'Arms braced on a preacher pad to isolate biceps and reduce cheating from the hips or shoulders.',
    instructions: [
      'Adjust seat so armpits sit near the top of the pad.',
      'Grip bar or dumbbells with arms extended along the pad.',
      'Curl toward shoulders without lifting elbows off the pad.',
      'Lower slowly to full extension without hyperextending elbows harshly.',
    ],
    tips: ['Partial reps at the bottom are OK for pump; full ROM builds strength through length.'],
  }),
  reg({
    id: 'good-morning',
    name: 'Good Morning',
    muscleGroups: ['hamstrings', 'glutes', 'back'],
    tags: ['hinge', 'accessory', 'posterior chain'],
    equipment: 'Barbell',
    summary:
      'Bar-on-back hip hinge that strengthens the posterior chain; treat like a skill lift with light-to-moderate loads.',
    instructions: [
      'Bar on upper back as in a squat; feet hip-width.',
      'Unlock knees slightly; push hips back while keeping spine neutral.',
      'Hinge until torso is roughly parallel to the floor or hamstrings limit you.',
      'Drive hips forward to stand tall.',
    ],
    tips: [
      'Master the pattern with a PVC pipe or empty bar before loading heavy.',
      'If you feel sharp low-back discomfort, reduce load and improve hinge mechanics.',
    ],
  }),
  reg({
    id: 'nordic-hamstring-curl',
    name: 'Nordic Hamstring Curl',
    muscleGroups: ['hamstrings'],
    tags: ['bodyweight', 'eccentric', 'injury prevention'],
    equipment: 'Bodyweight',
    summary:
      'Kneeling hamstring exercise leaning forward from knees—excellent for eccentric hamstring strength.',
    instructions: [
      'Kneel on pad; ankles secured under support or partner holds feet.',
      'Keep hips extended; lower torso toward floor as slowly as possible.',
      'Catch with hands if needed; push back up to reset.',
      'Progress by controlling more of the lowering phase.',
    ],
    tips: [
      'Use a band assist or shorten range early on.',
      'Quality eccentrics matter more than hitting the floor.',
    ],
  }),
  reg({
    id: 'chest-dip',
    name: 'Chest Dip',
    muscleGroups: ['chest', 'triceps', 'shoulders'],
    tags: ['bodyweight', 'compound', 'parallel bars'],
    equipment: 'Bodyweight',
    summary:
      'Forward-leaning dip on parallel bars to emphasize chest while still loading triceps and shoulders.',
    instructions: [
      'Support on bars with arms straight; shoulders depressed.',
      'Tilt torso slightly forward; elbows track out to ~45°.',
      'Lower until stretch across chest without sinking shoulders.',
      'Press up while maintaining forward lean.',
    ],
    tips: [
      'Stop depth if anterior shoulder feels pinchy.',
      'Add load with a belt once bodyweight feels easy.',
    ],
  }),
  reg({
    id: 'farmers-walk',
    name: "Farmer's Carry",
    muscleGroups: ['forearms', 'shoulders', 'core'],
    tags: ['carry', 'conditioning', 'grip'],
    equipment: 'Dumbbell',
    summary:
      'Walk while holding heavy weights at sides—builds grip, traps, and core bracing in a simple package.',
    instructions: [
      'Lift dumbbells or handles from the floor with neutral spine.',
      'Stand tall; ribs down; walk heel-to-toe for set distance or time.',
      'Avoid shrugging ears to shoulders unless targeting traps intentionally.',
      'Set weights down with control.',
    ],
    tips: [
      'Progress distance before maxing weight to protect hands and posture.',
      'Chalk or straps can help if grip is the only limiter.',
    ],
  }),
  reg({
    id: 'barbell-shrug',
    name: 'Barbell Shrug',
    muscleGroups: ['shoulders', 'forearms'],
    tags: ['traps', 'upper back', 'isolation'],
    equipment: 'Barbell',
    summary:
      'Vertical shrug motion to load upper trapezius; short range but heavy loads when appropriate.',
    instructions: [
      'Hold bar at arms length in front or behind body (behind hits traps slightly differently).',
      'Elevate shoulders straight up toward ears.',
      'Pause at top; lower with control—avoid rolling shoulders in circles.',
    ],
    tips: [
      'Rolling the shoulders is unnecessary for most goals and can irritate joints.',
      'Use straps if forearms fail before traps.',
    ],
  }),
  reg({
    id: 'pallof-press',
    name: 'Pallof Press',
    muscleGroups: ['core', 'shoulders'],
    tags: ['anti-rotation', 'cable', 'abs'],
    equipment: 'Cable',
    summary:
      'Anti-rotation press from a side-facing cable—trains obliques and deep core to resist twisting.',
    instructions: [
      'Stand perpendicular to cable stack; grab handle at chest.',
      'Step away until you feel tension trying to rotate you.',
      'Brace; extend arms forward without letting torso twist.',
      'Return hands to chest; repeat; switch sides.',
    ],
    tips: [
      'Exhale as you extend; imagine ribs and pelvis stacked.',
      'Half-kneeling makes it easier to feel glute and core brace.',
    ],
  }),
  reg({
    id: 'cable-pull-through',
    name: 'Cable Pull-Through',
    muscleGroups: ['glutes', 'hamstrings'],
    tags: ['hinge', 'glutes', 'beginner friendly'],
    equipment: 'Cable',
    summary:
      'Face away from a low pulley and hinge hips back—great hip hinge pattern with constant tension.',
    instructions: [
      'Straddle rope or handle between legs; walk forward for tension.',
      'Soft knees; push hips back while arms stay relaxed as cables.',
      'Stand tall by squeezing glutes at lockout.',
      'Control the forward hinge each rep.',
    ],
    tips: [
      'Keep eyes forward enough to protect neck; movement is from hips.',
      'Light weight teaches pattern before loading.',
    ],
  }),
  reg({
    id: 'sumo-deadlift',
    name: 'Sumo Deadlift',
    muscleGroups: ['glutes', 'hamstrings', 'back'],
    tags: ['compound', 'deadlift variant', 'wide stance'],
    equipment: 'Barbell',
    summary:
      'Wide-stance deadlift with vertical torso bias—often suits longer limbs or those who prefer quad and adductor involvement.',
    instructions: [
      'Feet wide; toes turned out; grip narrow inside knees.',
      'Hips closer to bar than conventional; brace before pulling.',
      'Drive knees out; drag bar up legs to lockout.',
      'Lower by pushing hips back first.',
    ],
    tips: [
      'Experiment stance width—too wide can limit depth.',
      'Mix with conventional over training cycles for balanced development.',
    ],
  }),
  reg({
    id: 'kettlebell-swing',
    name: 'Kettlebell Swing',
    muscleGroups: ['glutes', 'hamstrings', 'shoulders'],
    tags: ['hinge', 'power', 'conditioning'],
    equipment: 'Kettlebell',
    summary:
      'Explosive hip hinge projecting the kettlebell to chest height—posterior chain power with minimal knee bend.',
    instructions: [
      'Feet shoulder-width; bell slightly in front.',
      'Hike bell back between legs with flat wrists.',
      'Snap hips forward; arms float to about shoulder height (Russian style).',
      'Let bell fall; absorb with hinge—repeat rhythmically.',
    ],
    tips: [
      'Do not squat the swing; knees stay soft but hips drive.',
      'Stop set if lower back feels it instead of glutes/hams.',
    ],
  }),
  reg({
    id: 'inverted-row',
    name: 'Inverted Row',
    muscleGroups: ['back', 'biceps'],
    tags: ['bodyweight', 'horizontal pull', 'scalable'],
    equipment: 'Bodyweight',
    summary:
      'Ring or bar bodyweight row—adjust difficulty by moving feet or torso angle.',
    instructions: [
      'Hang under a fixed bar or rings; body straight like a plank.',
      'Pull chest to bar with elbows tracking toward ribs.',
      'Lower until arms straight without losing shoulder integrity.',
    ],
    tips: [
      'Elevate feet or wear a vest to progress.',
      'Pull ribs toward hips to avoid excessive arch.',
    ],
  }),
  reg({
    id: 'front-squat',
    name: 'Front Squat',
    muscleGroups: ['quads', 'core', 'glutes'],
    tags: ['compound', 'squat', 'oly lifting'],
    equipment: 'Barbell',
    summary:
      'Bar rests on front delts—upright torso squat pattern that demands ankle, thoracic, and core mobility.',
    instructions: [
      'Use clean grip or cross-arm shelf depending on wrist comfort.',
      'Elbows high; brace; squat between hips.',
      'Drive up keeping torso as vertical as mobility allows.',
    ],
    tips: [
      'Straps around bar can help if wrists limit rack position.',
      'If elbows drop, the bar may roll—reduce weight until position holds.',
    ],
  }),
  reg({
    id: 'decline-bench-press',
    name: 'Decline Barbell Bench Press',
    muscleGroups: ['chest', 'triceps', 'shoulders'],
    tags: ['press', 'lower chest', 'spotter'],
    equipment: 'Barbell',
    summary:
      'Decline angle shifts emphasis toward lower pec fibers while reducing some shoulder impingement risk for certain lifters.',
    instructions: [
      'Secure legs on decline bench pads; eyes under bar.',
      'Unrack with stacked wrists; lower to lower chest line.',
      'Press along same path; lock out without losing leg brace.',
    ],
    tips: [
      'Use safeties or a spotter—bar path can feel awkward first.',
      'Avoid excessive bounce off the chest.',
    ],
  }),
  reg({
    id: 'smith-machine-squat',
    name: 'Smith Machine Squat',
    muscleGroups: ['quads', 'glutes'],
    tags: ['machine', 'guided', 'squat pattern'],
    equipment: 'Machine',
    summary:
      'Squat on a fixed vertical or slight-angle track—stable for quad emphasis when learning patterns or training to failure safely.',
    instructions: [
      'Set safeties at appropriate depth; feet slightly in front of bar path common.',
      'Unrack; squat keeping knees tracking toes.',
      'Stand without locking knees aggressively.',
    ],
    tips: [
      'Foot placement changes quad vs glute bias.',
      'Still brace core—machine guidance does not replace bracing.',
    ],
  }),
  reg({
    id: 'zercher-squat',
    name: 'Zercher Squat',
    muscleGroups: ['quads', 'glutes', 'core'],
    tags: ['front-loaded', 'squat', 'strongman'],
    equipment: 'Barbell',
    summary:
      'Barbell held in elbow crook—upright torso challenge that smokes upper back and core while squatting.',
    instructions: [
      'Bar rests in elbows with hands clasped or overlapped.',
      'Brace hard; squat keeping elbows level.',
      'Stand tall without dumping forward.',
    ],
    tips: [
      'Pad the bar or wear long sleeves—pressure on arms is real.',
      'Start light to own the rack position.',
    ],
  }),
  reg({
    id: 'seated-dumbbell-shoulder-press',
    name: 'Seated Dumbbell Shoulder Press',
    muscleGroups: ['shoulders', 'triceps'],
    tags: ['overhead', 'seated', 'strict press'],
    equipment: 'Dumbbell',
    summary:
      'Strict vertical press with back support—limits leg drive and isolates shoulder and triceps work.',
    instructions: [
      'Back flat on bench with vertical seat or slight incline.',
      'Dumbbells at shoulder height; palms forward or neutral.',
      'Press overhead without locking aggressively backward.',
      'Lower under control to ear level or shoulders.',
    ],
    tips: [
      'Don’t bounce off the bench—keep glutes and upper back planted.',
      'Neutral grip may feel friendlier on shoulders.',
    ],
  }),
  reg({
    id: 'reverse-fly-machine',
    name: 'Reverse Pec Deck / Reverse Fly Machine',
    muscleGroups: ['shoulders', 'back'],
    tags: ['rear delts', 'machine', 'isolation'],
    equipment: 'Machine',
    summary:
      'Seated reverse fly on machine—steady resistance for rear delts and external rotation endurance.',
    instructions: [
      'Sit facing machine; handles at shoulder height or per settings.',
      'Arms slightly bent; open arms wide squeezing shoulder blades.',
      'Pause; return slowly without letting stack slam.',
    ],
    tips: [
      'Keep chin neutral—don’t crane neck forward.',
      'Light weight and tempo beat ego lifting here.',
    ],
  }),
  reg({
    id: 'lat-prayer-stretch-cable',
    name: 'Straight-Arm Pulldown',
    muscleGroups: ['back'],
    tags: ['lat isolation', 'cable', 'mind-muscle'],
    equipment: 'Cable',
    summary:
      'Straight-arm pull from high cable isolates lats with minimal biceps—great finisher or technique primer.',
    instructions: [
      'Face stack; slight hinge; arms nearly straight with soft elbows.',
      'Pull handle down and slightly back toward thighs.',
      'Squeeze lats; return until shoulders feel stretch.',
    ],
    tips: [
      'Think elbows pulling to back pockets.',
      'Reduce weight if triceps take over.',
    ],
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
      if (ex.tags?.some((t) => t.toLowerCase().includes(needle))) return true
      return ex.muscleGroups.some((g) => MUSCLE_GROUP_LABELS[g].toLowerCase().includes(needle))
    })
    .sort((a, b) => a.name.localeCompare(b.name))
}