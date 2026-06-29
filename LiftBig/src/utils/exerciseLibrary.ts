import { EXERCISE_TUTORIAL_URLS } from './exerciseTutorials'

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
  /** Short coaching checkpoints users can scan before each set (posture, rhythm, safety). */
  cues?: string[]
  /** Short-form YouTube tutorial focused on form and cues. */
  tutorialUrl?: string
  /** Cardio / sports — duration-only when logged or planned. */
  isCardio?: boolean
  /** Core exercise logged with reps and weight only (no per-set time column). */
  repBasedCore?: boolean
}

export type LibraryFilterGroup = MuscleGroup | 'all' | 'cardio'

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
  const tutorialUrl = ex.tutorialUrl ?? EXERCISE_TUTORIAL_URLS[ex.id]
  const entry = tutorialUrl ? { ...ex, tutorialUrl } : ex
  byId.set(entry.id, entry)
  return entry
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
    cues: [
      'Pinch shoulder blades together and keep them on the bench.',
      'Bar touches lower chest; elbows stay ~45° from your torso.',
      'Drive feet into the floor; wrists stacked over forearms.',
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
    cues: [
      'Shoulders stay “back and down” on the pad.',
      'Dumbbells track over elbows—no loose shoulders at the bottom.',
      'Press slightly inward at the top without clanking plates.',
    ],
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
    cues: [
      'Feet planted; ribs slightly down.',
      'Elbows ~45°; control the stretch at the bottom.',
      'Same path up and down—no bouncing off the chest.',
    ],
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
    cues: [
      'Set shoulders by pulling shoulder blades “into back pockets” first.',
      'Drive elbows down and slightly back—think sternum to bar.',
      'Lower until arms are long without relaxing into a dead hang.',
    ],
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
    cues: [
      'Thighs pinned under the pad; ribs tall.',
      'Pull the bar to upper chest, not behind the neck.',
      'Elbows trace down toward your sides each rep.',
    ],
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
    cues: [
      'Neck long; gaze a few feet ahead—no craned neck.',
      'Pull elbows toward hips; pause when the bar touches your torso.',
      'Hinge stays fixed—don’t stand up to cheat the rep.',
    ],
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
    cues: [
      'Support the torso; let the arm hang straight before each pull.',
      'Elbow tracks toward the hip—minimize torso rotation.',
      'Lower with control until the shoulder is fully lengthened.',
    ],
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
    cues: [
      'Chest stays lifted off the bench—no sinking between shoulder blades.',
      'Pull with elbows, not hands; squeeze mid-back at the top.',
      'Stop before shoulders dump forward at the bottom.',
    ],
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
    cues: [
      'Sit tall; slight bend in knees; feet flat.',
      'Hands lead the pull—finish with elbows behind the torso.',
      'Return until you feel a stretch, not a sloppy forward slump.',
    ],
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
    cues: [
      'Elbows higher than wrists through the pull.',
      'Separate the rope at the end—thumbs toward temples.',
      'Control the stack; no jerking the neck forward.',
    ],
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
    cues: [
      'Glutes and quads tight before you press.',
      'Bar travels close to the face, then head moves “through the window.”',
      'Finish with biceps beside ears—no aggressive rib flare.',
    ],
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
    cues: [
      'Soft elbows fixed—hands lead but elbows don’t bend more mid-rep.',
      'Raise to shoulder height; pinkies slightly high (“pour water”).',
      'Pause at the top; three-count lowers beat heavier sloppy reps.',
    ],
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
    cues: [
      'Neutral spine; gaze toward floor a few feet ahead.',
      'Initiate from rear delts—no shrugging toward ears.',
      'Stop if you feel pinching; reduce range or load.',
    ],
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
    cues: [
      'Elbows pinned to your sides or slightly in front of hips.',
      'Only the forearm moves—upper arm stays vertical.',
      'Full lockout without thrusting the hips forward.',
    ],
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
    cues: [
      'Ribs down; biceps beside ears at the start.',
      'Upper arms vertical—don’t let elbows flare wide.',
      'Reach full extension without dumping the chest forward.',
    ],
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
    cues: [
      'Stand tall; elbows stay at your sides.',
      'Supinate smoothly; no hip thrust at the sticking point.',
      'Lower until elbows straight without resting tension.',
    ],
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
    cues: [
      'Palms face each other throughout.',
      'Keep wrists neutral—don’t curl with the neck.',
      'Stop short of shoulder shrug at the top.',
    ],
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
    cues: [
      'Back flat on the pad; shoulders packed.',
      'Elbows stay behind the line of the ears—no drifting forward.',
      'Squeeze biceps; don’t yank the stack with the low back.',
    ],
  }),
  reg({
    id: 'incline-dumbbell-curl',
    name: 'Incline Dumbbell Curl',
    muscleGroups: ['biceps'],
    equipment: 'Dumbbell',
    summary: 'Curl on an incline bench with dumbbells for long-head stretch and strict elbows.',
    instructions: [
      'Set bench ~45°; sit with dumbbells at sides, arms hanging straight down.',
      'Curl with palms up (or neutral) without letting elbows drift forward of the shoulder line.',
      'Squeeze at the top; lower until arms are nearly straight with control.',
    ],
    tips: ['Use lighter loads than standing curls; long ROM makes cheating obvious.'],
    cues: [
      'Back and shoulders stay on the pad.',
      'Only forearms move; elbows stay “pinned” in space behind you.',
    ],
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
    cues: [
      'Stack shoulders over hips; elbows at your sides.',
      'Only forearms move; keep triceps “on” the whole set.',
      'End each rep with full extension, not partial ROM.',
    ],
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
    cues: [
      'Big breath, brace, then break at hips and knees together.',
      'Knees follow toes; heels stay down if mobility allows.',
      'Chest stays stacked over hips—no “good morning” out of the hole.',
    ],
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
    cues: [
      'Low back and hips stay glued to the pad.',
      'Press through mid-foot; don’t lock knees violently.',
      'Depth you can control—no butt bouncing off the seat.',
    ],
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
    cues: [
      'Set pad so the axis lines up with your knee joint.',
      'Squeeze quads to extend; don’t snap into lockout.',
      'Hands light on the handles—no white-knuckle pulling.',
    ],
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
    tips: [
      'Keep dumbbells close to legs; neutral neck.',
      'Push hips back as far as possible; stop around mid-shin if hamstrings limit depth.',
    ],
    cues: [
      'Soft knees; hips reach back like closing a car door.',
      'Weights skim the legs—don’t drift forward.',
      'Stop when hamstrings talk or back rounds—never chase depth.',
    ],
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
    cues: [
      'Soft knees stay parked; hips reach back like closing a car door.',
      'Bar skims thighs—lats keep the bar glued to your legs.',
      'Stand tall by extending hips; stop if your low back rounds.',
    ],
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
    cues: [
      'Mid-foot under bar; pull slack out; brace before you break the floor.',
      'Push the floor away; hips and chest rise together.',
      'Lock out tall with glutes; lower by hinging hips back first.',
    ],
  }),
  reg({
    id: 'seated-leg-curl',
    name: 'Seated Leg Curl',
    muscleGroups: ['hamstrings'],
    tags: ['machine', 'isolation'],
    equipment: 'Machine',
    summary: 'Seated knee flexion isolating hamstrings with hips flexed—great paired with leg extensions.',
    instructions: [
      'Adjust the back pad and leg pad so knees align with the machine axis.',
      'Curl heels under the seat toward glutes; hips stay planted.',
      'Squeeze hamstrings at peak; return slowly without letting the stack slam.',
    ],
    tips: [
      'Point toes slightly up (dorsiflex) to reduce calf takeover.',
      'Pair with leg extensions in supersets for efficient leg work.',
    ],
    cues: [
      'Hips glued to the seat—no rocking.',
      'Smooth curl; pause at peak contraction.',
      'Two-second negative on every rep.',
    ],
  }),
  reg({
    id: 'machine-chest-press',
    name: 'Machine Chest Press',
    muscleGroups: ['chest', 'shoulders', 'triceps'],
    tags: ['machine', 'press'],
    equipment: 'Machine',
    summary: 'Stable horizontal press on a chest machine—useful for volume after heavy shoulder work.',
    instructions: [
      'Set seat so handles align with mid-chest; feet flat and back on pad.',
      'Press forward without locking elbows aggressively backward.',
      'Lower under control to a comfortable stretch without shoulder pinch.',
    ],
    tips: [
      'Keep shoulders down and back on the pad throughout.',
      'Use after shoulder pressing when barbell/dumbbell stability is fatigued.',
    ],
    cues: [
      'Scapulae set before the first rep.',
      'Press in a slight arc—don’t shrug at lockout.',
      'Touch smooth, not bounce, at the bottom.',
    ],
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
    cues: [
      'Hips stay down on lying curls; ankles dorsiflex smoothly.',
      'Squeeze hamstrings at peak contraction.',
      'Two-second negatives beat rushing the stack.',
    ],
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
    cues: [
      'Stand tall—don’t lean forward through the toes.',
      'Pause one second at the top squeeze.',
      'Full stretch at bottom without bouncing.',
    ],
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
    tips: [
      'Short steps over-stress knee; stride for hip comfort.',
      'Lean torso slightly forward to shift load from quads to glutes.',
    ],
    cues: [
      'Torso stays tall; rib cage over pelvis.',
      'Front knee tracks over mid-foot, not past the toe line.',
      'Control the back knee—light tap, not a crash.',
    ],
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
    tips: [
      'Great for learning squat depth and torso position.',
      'Use deep depth to maximize glute stretch at the bottom.',
    ],
    cues: [
      'Elbows trace along ribs—use them to wedge knees out.',
      'Chest stays tall; weight sits over mid-foot.',
      'Drive evenly through both feet out of the hole.',
    ],
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
    cues: [
      'Plank from ears to heels—squeeze glutes.',
      'Elbows ~45°; chest meets the floor first.',
      'Press away like pushing the floor apart.',
    ],
  }),
  reg({
    id: 'cable-crunch',
    name: 'Cable Crunch',
    muscleGroups: ['core'],
    equipment: 'Cable',
    repBasedCore: true,
    summary: 'Kneeling crunch with high cable for abs.',
    instructions: [
      'Kneel facing stack, rope behind head or at shoulders.',
      'Crunch down by flexing spine, not pulling with arms.',
      'Pause; control the return.',
    ],
    tips: ['Hips stay mostly still; movement is thoracic flexion.'],
    cues: [
      'Knees under hips; glue hips to the stack—only your spine curls.',
      'Hands anchor the rope; ribs move toward pelvis, not arms pulling.',
      'Exhale hard at the bottom; inhale on the way up.',
    ],
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
    cues: [
      'Brace obliques before you move the handle.',
      'Rotate from hips and chest together—arms are an extension.',
      'Follow the cable with control both directions.',
    ],
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
    cues: [
      'Seat height sets shoulder safety—handles level with mid-chest.',
      'Fixed elbow bend; hug the arc, don’t press.',
      'Stop before shoulders roll forward at the stretch.',
    ],
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
    cues: [
      'Slight forward lean from ankles—stack joints.',
      'Hands meet in front of sternum, not the chin.',
      'Stretch wide without losing rib position.',
    ],
  }),
  reg({
    id: 'low-to-high-cable-fly',
    name: 'Low-to-High Cable Fly',
    muscleGroups: ['chest', 'shoulders'],
    tags: ['cable', 'upper chest', 'fly'],
    equipment: 'Cable',
    summary: 'Cable fly from low pulleys upward to emphasize upper chest and front delts.',
    instructions: [
      'Set both pulleys to the lowest position; grab handles with palms facing forward.',
      'Step forward into a staggered stance; slight bend in elbows throughout.',
      'Sweep hands up and together in an arc finishing around eye level.',
      'Control the return—feel the stretch across upper chest without shrugging.',
    ],
    tips: [
      'Use lighter weight than flat flies; tension peaks at the top.',
      'Keep ribs down—don’t hyperextend the lower back to finish the rep.',
    ],
    cues: [
      'Low pulleys, soft elbows—arc up and in.',
      'Squeeze upper chest at the top; shoulders stay down.',
      'Lower with control; don’t let handles yank you forward.',
    ],
  }),
  reg({
    id: 'cable-lateral-raise',
    name: 'Cable Lateral Raise',
    muscleGroups: ['shoulders'],
    tags: ['cable', 'medial delt', 'isolation'],
    equipment: 'Cable',
    summary: 'Constant-tension lateral raise from a low or mid pulley for medial delts.',
    instructions: [
      'Stand beside the stack with the cable crossing lightly in front of your body, or use a single low pulley at your side.',
      'With a slight elbow bend, raise your arm out to the side to shoulder height.',
      'Pause; lower under control without letting the stack pull your shoulder forward.',
    ],
    tips: [
      'Stay lighter than dumbbells—cables keep tension at the bottom.',
      'Keep the non-working hand on your hip or the rack for balance.',
    ],
    cues: [
      'Elbows soft; lead with the elbow, not the hand.',
      'Raise to shoulder height—no trap shrug at the top.',
      'Three-count lowering; stack stays quiet between reps.',
    ],
  }),
  reg({
    id: 'lean-away-cable-lateral-raise',
    name: 'Lean-Away Cable Lateral Raise',
    muscleGroups: ['shoulders'],
    tags: ['cable', 'medial delt', 'isolation', 'unilateral'],
    equipment: 'Cable',
    summary: 'Single-arm lateral raise leaning away from the stack for a longer medial-delt arc.',
    instructions: [
      'Grab the rack or post with your off hand; lean away so the working arm hangs with cable tension at the bottom.',
      'Raise the handle out to the side to shoulder height with a soft elbow bend.',
      'Pause; lower slowly without losing tension at the bottom.',
    ],
    tips: [
      'The lean increases range—use less weight than standing cable laterals.',
      'Keep ribs down; don’t side-bend to cheat the rep.',
    ],
    cues: [
      'Lean creates tension at the bottom—no dead hang between reps.',
      'Pinkies slightly high at the top.',
      'Shoulders down; traps stay quiet.',
    ],
  }),
  reg({
    id: 'leaning-dumbbell-lateral-raise',
    name: 'Leaning Dumbbell Lateral Raise',
    muscleGroups: ['shoulders'],
    tags: ['dumbbell', 'medial delt', 'isolation'],
    equipment: 'Dumbbell',
    summary: 'Single-arm lateral raise with a lean away from a post for a longer medial-delt arc.',
    instructions: [
      'Hold a rack or post with one hand; lean away so your working arm hangs freely.',
      'With a slight elbow bend, raise the dumbbell out to the side to shoulder height.',
      'Pause briefly; lower under control without resting tension at the bottom.',
    ],
    tips: [
      'The lean increases range—stay lighter than standing laterals.',
      'Lead with the elbow; don’t shrug the trap to finish the rep.',
    ],
    cues: [
      'Lean creates tension at the bottom—no dead hang between reps.',
      'Pinkies slightly high at the top (“pour water”).',
      'Three-count lowering beats swinging a heavy dumbbell.',
    ],
  }),
  reg({
    id: 'lateral-raise-partial',
    name: 'Lateral Raise Partial',
    muscleGroups: ['shoulders'],
    tags: ['burnout', 'finisher', 'medial delt'],
    equipment: 'Dumbbell',
    summary: 'Short-range lateral raise reps in the top half of the movement for a medial-delt burnout.',
    instructions: [
      'After main lateral work, use light dumbbells.',
      'Raise only through the top 30–50% of your normal range—no full rest at the bottom.',
      'Pump continuous partial reps until near failure.',
    ],
    tips: [
      'Best as a finisher—expect a deep burn with minimal load.',
      'Keep elbows soft; momentum from the hips defeats the purpose.',
    ],
    cues: [
      'Small arc, constant tension—no pause at the bottom.',
      'Shoulders down; traps stay quiet.',
      'Stop when form breaks, not when ego says one more.',
    ],
  }),
  reg({
    id: 'assisted-pull-up',
    name: 'Assisted Pull-Up',
    muscleGroups: ['back', 'biceps'],
    tags: ['pull-up', 'machine', 'bodyweight'],
    equipment: 'Machine',
    summary: 'Pull-up with counterweight assistance to build vertical pulling strength and volume.',
    instructions: [
      'Set assistance so you can hit target reps with 1–2 reps in reserve on early sets.',
      'Hang with active shoulders; pull chest toward the bar driving elbows down.',
      'Clear the chin over the bar; lower under control to a long but active hang.',
    ],
    tips: [
      'Reduce assistance over time as strength improves.',
      'Avoid excessive kipping unless training specifically for it.',
    ],
    cues: [
      'Shoulders set before you pull—no dead shrug hang.',
      'Drive elbows to your back pockets.',
      'Lower fully without relaxing into the shoulders.',
    ],
  }),
  reg({
    id: 'rear-delt-cable-fly',
    name: 'Rear Delt Cable Fly',
    muscleGroups: ['shoulders', 'back'],
    tags: ['cable', 'rear delts', 'isolation'],
    equipment: 'Cable',
    summary: 'Standing or bent cable fly targeting rear delts and upper back.',
    instructions: [
      'Set cables at shoulder height or use a rear-delt station; cross handles if needed.',
      'Hinge slightly with neutral spine; arms start in front of the torso.',
      'Pull handles apart and back, squeezing rear delts and shoulder blades.',
      'Return with control without rounding forward.',
    ],
    tips: [
      'Light weight, high reps—rear delts respond to tension, not load.',
      'Think “spread the chest” rather than rowing with the elbows low.',
    ],
    cues: [
      'Soft elbows fixed—open from the rear delts, not the lats.',
      'Pause at peak squeeze; scapulae retract.',
      'Stop before traps take over the movement.',
    ],
  }),
  reg({
    id: 'neutral-grip-lat-pulldown',
    name: 'Neutral Grip Lat Pulldown',
    muscleGroups: ['back', 'biceps'],
    tags: ['cable', 'lat', 'vertical pull'],
    equipment: 'Cable',
    summary: 'Lat pulldown with parallel handles—friendly on shoulders while building lat width.',
    instructions: [
      'Use a neutral (parallel) attachment on a high pulley; sit with thighs secured.',
      'Pull elbows down and slightly back toward your ribs without excessive lean.',
      'Squeeze lats at the bottom; return until arms are extended with shoulders set.',
    ],
    tips: [
      'Think elbows to back pockets, not hands to chest.',
      'A slight forward torso angle can help feel the lats—avoid swinging.',
    ],
    cues: [
      'Chest tall; ribs down before you pull.',
      'Drive elbows down—minimal wrist curl.',
      'Full stretch at the top without shrugging.',
    ],
  }),
  reg({
    id: 'chest-supported-lat-row',
    name: 'Chest Supported Lat-Focused Row',
    muscleGroups: ['back', 'biceps'],
    tags: ['machine', 'row', 'lat focus'],
    equipment: 'Machine',
    summary: 'Chest-supported row emphasizing lat depression and elbow path close to the torso.',
    instructions: [
      'Set chest pad so shoulders stay neutral; grab handles with a slight elbow tuck.',
      'Row by driving elbows back and down toward hips—think lats, not upper traps.',
      'Pause with shoulder blades squeezed; return until lats stretch without rounding.',
    ],
    tips: [
      'Reduce weight if you feel biceps or rear delts dominate.',
      'Avoid shrugging at the finish—keep shoulders down.',
    ],
    cues: [
      'Chest stays on pad; no hip lift.',
      'Elbows track toward back pockets.',
      'Squeeze lats at peak—two-count hold.',
    ],
  }),
  reg({
    id: 'single-arm-lat-pulldown',
    name: 'Single Arm Lat Pulldown',
    muscleGroups: ['back', 'biceps'],
    tags: ['cable', 'unilateral', 'lat'],
    equipment: 'Cable',
    summary: 'Unilateral vertical pull to train each lat independently with a full stretch.',
    instructions: [
      'Use a single handle on a high pulley; kneel or sit depending on station.',
      'Pull elbow down and slightly back toward the hip, not straight to the ribs.',
      'Pause at the bottom; control the return until the lat is fully stretched.',
    ],
    tips: [
      'Avoid rotating the torso excessively—small twist is OK, not a full twist.',
      'Match reps and quality side to side before adding load.',
    ],
    cues: [
      'Initiate by pulling the elbow to your back pocket.',
      'Stretch long at the top without shrugging the working shoulder.',
      'Same path every rep—no yanking with the arm.',
    ],
  }),
  reg({
    id: 'overhead-cable-tricep-extension',
    name: 'Overhead Cable Tricep Extension',
    muscleGroups: ['triceps'],
    tags: ['cable', 'overhead', 'long head'],
    equipment: 'Cable',
    summary: 'Overhead triceps extension with a rope or bar on a low pulley for long-head emphasis.',
    instructions: [
      'Face away from the stack; rope overhead with elbows beside the head.',
      'Extend forearms forward until arms are straight without flaring ribs.',
      'Lower behind the head under control to roughly 90° elbow bend.',
    ],
    tips: [
      'Stagger stance for balance; keep upper arms vertical.',
      'Slightly lighter than dumbbell overhead work—constant cable tension is demanding.',
    ],
    cues: [
      'Elbows point at the ceiling—don’t let them drift forward.',
      'Ribs down; move only at the elbow.',
      'Full lockout without hyperextending the lower back.',
    ],
  }),
  reg({
    id: 'overhead-dumbbell-tricep-extension',
    name: 'Overhead Dumbbell Tricep Extension',
    muscleGroups: ['triceps'],
    tags: ['dumbbell', 'overhead', 'single or double arm'],
    equipment: 'Dumbbell',
    summary: 'Standing or seated overhead extension with one or two dumbbells.',
    instructions: [
      'Press dumbbell(s) overhead; upper arms stay vertical beside the head.',
      'Lower behind the head by bending elbows while keeping upper arms fixed.',
      'Extend to lockout without arching the lower back.',
    ],
    tips: [
      'Single-arm allows a natural path; two-hand on one dumbbell needs stable wrists.',
      'Use a bench back for support if lower back tends to arch.',
    ],
    cues: [
      'Biceps beside ears at the start of each rep.',
      'Elbows stay in—don’t flare wide.',
      'Control the stretch; no free-fall behind the head.',
    ],
  }),
  reg({
    id: 'dumbbell-curl',
    name: 'Dumbbell Curl',
    muscleGroups: ['biceps', 'forearms'],
    tags: ['dumbbell', 'curl', 'arms'],
    equipment: 'Dumbbell',
    summary: 'Standing alternating or simultaneous dumbbell curl for biceps.',
    instructions: [
      'Stand tall with dumbbells at sides, palms forward (or neutral for hammer variation).',
      'Curl toward shoulders without swinging the hips or shoulders.',
      'Lower under control to full elbow extension.',
    ],
    tips: [
      'Supinate through the rep for peak biceps contraction if using standard grip.',
      'Alternate arms if grip fatigue is an issue in circuits.',
    ],
    cues: [
      'Elbows pinned at your sides.',
      'Curl to shoulder height—no shoulder roll forward.',
      'Lower until arms are straight without resting the weights on your thighs.',
    ],
  }),
  reg({
    id: 'standing-dumbbell-shoulder-press',
    name: 'Standing Dumbbell Shoulder Press',
    muscleGroups: ['shoulders', 'triceps', 'core'],
    tags: ['overhead', 'standing', 'strict press'],
    equipment: 'Dumbbell',
    summary: 'Vertical press from the shoulders while standing—trains delts with core bracing.',
    instructions: [
      'Dumbbells at shoulder height, palms forward or neutral; feet hip-width.',
      'Brace core and glutes; press overhead without excessive lean-back.',
      'Lower to ear level or shoulders under control.',
    ],
    tips: [
      'Slight leg drive is OK for heavy sets; keep it strict in conditioning circuits.',
      'Don’t flare ribs—stop the set if lower back arches hard.',
    ],
    cues: [
      'Ribs down; squeeze glutes lightly.',
      'Press up and slightly in—biceps beside ears at lockout.',
      'Head through the “window” only after the bell passes your face.',
    ],
  }),
  reg({
    id: 'decline-reverse-crunch',
    name: 'Decline Reverse Crunch',
    muscleGroups: ['core'],
    tags: ['decline', 'lower abs', 'bodyweight'],
    equipment: 'Bench',
    summary: 'Reverse crunch on a decline bench for extra lower-ab loading.',
    instructions: [
      'Lie on a decline bench, hold the pads behind your head for stability.',
      'Curl hips off the bench bringing knees toward chest; posterior pelvic tilt.',
      'Lower with control without swinging the legs.',
    ],
    tips: [
      'Small range beats wild leg swings.',
      'Skip decline if you feel neck strain—use flat bench reverse crunch instead.',
    ],
    cues: [
      'Tuck pelvis first—lift comes from abs, not momentum.',
      'Exhale as hips rise.',
      'Slow negative; don’t drop the legs.',
    ],
  }),
  reg({
    id: 'weighted-crunch',
    name: 'Weighted Crunch',
    muscleGroups: ['core'],
    tags: ['crunch', 'loaded', 'abs'],
    equipment: 'Dumbbell',
    summary: 'Crunch holding a plate or dumbbell on the chest for loaded flexion.',
    instructions: [
      'Lie on back, knees bent, feet flat; hold weight on upper chest.',
      'Curl shoulders off floor by flexing abs—chin stays a fist-width from chest.',
      'Pause; lower until shoulder blades lightly touch without fully relaxing.',
    ],
    tips: [
      'Don’t pull the weight with your arms—hands only anchor the load.',
      'Use moderate weight in circuits; quality reps over max load.',
    ],
    cues: [
      'Ribs move toward pelvis—no neck yanking.',
      'Exhale on the way up.',
      'Short pause at the top; control the descent.',
    ],
  }),
  reg({
    id: 'side-plank',
    name: 'Side Plank',
    muscleGroups: ['core', 'shoulders'],
    tags: ['isometric', 'obliques', 'anti-lateral-flexion'],
    equipment: 'Bodyweight',
    summary: 'Isometric hold on one forearm to train obliques and lateral core stability.',
    instructions: [
      'Forearm on floor, elbow under shoulder; stack feet or stagger for balance.',
      'Lift hips to a straight line from head to heels; top arm on hip or ceiling.',
      'Hold for time; breathe steadily without sagging at the hips.',
    ],
    tips: [
      'Regress to knees down if hips drop repeatedly.',
      'In circuits, hit each side within the listed time.',
    ],
    cues: [
      'Drive forearm and bottom foot into the floor.',
      'Hips forward—no banana sag.',
      'Neck neutral; squeeze glutes lightly.',
    ],
  }),
  reg({
    id: 'dead-bug',
    name: 'Dead Bug',
    muscleGroups: ['core'],
    tags: ['anti-extension', 'stability', 'abs'],
    equipment: 'Bodyweight',
    summary: 'Supine alternating arm and leg extensions while keeping the lower back pressed to the floor.',
    instructions: [
      'Lie on your back, arms toward the ceiling, hips and knees at 90°.',
      'Brace your core and press your lower back into the floor.',
      'Slowly extend opposite arm and leg; return and alternate sides.',
    ],
    tips: [
      'Move only as far as you can without your lower back arching off the floor.',
      'Exhale as you extend; keep ribs down throughout.',
    ],
    cues: [
      'Lower back glued to the mat—if it lifts, shorten the range.',
      'Reach long through heel and fingertips; don’t rush.',
      'Breathe out on the extension; reset the brace each rep.',
    ],
  }),
  reg({
    id: 'cable-side-crunch',
    name: 'Cable Side Crunch',
    muscleGroups: ['core'],
    tags: ['obliques', 'cable'],
    equipment: 'Cable',
    summary: 'Standing side bend with a low cable to target obliques.',
    instructions: [
      'Stand sideways to a low cable; hold the handle at your shoulder or behind your head.',
      'Crunch sideways by shortening the distance between rib cage and hip on the working side.',
      'Pause; control the return without leaning into the stack.',
    ],
    tips: [
      'Keep hips square—movement is lateral flexion, not rotation.',
      'Use a light load; quality side crunch beats heavy swinging.',
    ],
    cues: [
      'Elbow drives toward hip on the working side.',
      'Opposite hip stays planted; no twisting through the waist.',
      'Squeeze the oblique at the bottom; slow negative.',
    ],
  }),
  reg({
    id: 'weighted-decline-situp',
    name: 'Weighted Decline Sit-Up',
    muscleGroups: ['core'],
    tags: ['decline', 'weighted', 'abs'],
    equipment: 'Decline bench',
    summary: 'Decline sit-up holding a plate or dumbbell for loaded abdominal work.',
    instructions: [
      'Secure feet on a decline bench; hold a weight at your chest or overhead.',
      'Curl up by flexing your spine, not pulling with hip flexors alone.',
      'Lower under control to just above the bench without bouncing.',
    ],
    tips: [
      'Start with a modest decline and light weight—add load only when form stays crisp.',
      'If you feel pulling in the hip flexors, reduce decline or range.',
    ],
    cues: [
      'Ribs toward pelvis—think crunch, not sit-up swing.',
      'Weight stays close to chest until you own the movement.',
      'Exhale hard at the top; don’t yank with arms.',
    ],
  }),
  reg({
    id: 'machine-pullover',
    name: 'Machine Pullover',
    muscleGroups: ['back', 'chest'],
    tags: ['lat isolation', 'machine'],
    equipment: 'Machine',
    summary: 'Seated pullover machine emphasizing lats and serratus with a fixed arc.',
    instructions: [
      'Adjust seat so shoulders align with the machine pivot; grip handles or bar.',
      'With a slight elbow bend, pull the pad down and around in the machine’s arc.',
      'Squeeze lats at the bottom; return slowly without shrugging.',
    ],
    tips: [
      'Think “pull elbows to pockets” rather than bending arms like a curl.',
      'Keep ribs down—don’t over-arch to chase range.',
    ],
    cues: [
      'Chest tall; slight elbow bend fixed throughout.',
      'Drive elbows down and back through the pad’s arc.',
      'Feel lats and serratus—pause, then control the stretch.',
    ],
  }),
  reg({
    id: 'bicycle-crunch',
    name: 'Bicycle Crunch',
    muscleGroups: ['core'],
    tags: ['dynamic', 'obliques', 'abs'],
    equipment: 'Bodyweight',
    summary: 'Alternating elbow-to-knee crunch for rectus abdominis and obliques.',
    instructions: [
      'Lie on back, hands lightly behind head, legs in tabletop.',
      'Extend one leg while rotating opposite elbow toward the bent knee.',
      'Alternate sides in a controlled rhythm—don’t pull on the neck.',
    ],
    tips: [
      'Slow tempo improves control; speed is not the goal on recovery days.',
      'Keep lower back pressed down if you feel lumbar arching.',
    ],
    cues: [
      'Rotate from the ribs, not the elbows yanking forward.',
      'Fully extend the straight leg without letting the heel slam down.',
      'Exhale on each twist.',
    ],
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
    cues: [
      'Handles line up with upper chest when seated.',
      'Press evenly—don’t let one shoulder lead.',
      'Stop short of locking elbows backward.',
    ],
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
    tips: [
      'Do not hyperextend the lower back at the top.',
      'Pause at the top for 1 full second; chin tucked throughout.',
    ],
    cues: [
      'Chin tucked; eyes forward—neck long.',
      'Drive through heels; knees track over toes.',
      'Top position is glutes, not lumbar hyperextension.',
    ],
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
    cues: [
      'Forearms or palms active—push floor away.',
      'Glutes on; belt line parallel to floor.',
      'Quiet breathing—small sips, no collapsing hips.',
    ],
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
    cues: [
      'Seat and pads set so you flex the spine, not pull with arms.',
      'Short range, crisp contraction.',
      'Smooth return—no slamming the stack.',
    ],
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
    tips: [
      'Small range; focus on posterior pelvic tilt.',
      'Lift the pelvis off the floor using lower abs, not momentum from the legs.',
    ],
    cues: [
      'Posterior pelvic tilt before you lift feet.',
      'Low back stays pressed down if possible.',
      'Legs move from abs, not momentum from thighs.',
    ],
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
    cues: [
      'Active hang—shoulders plugged into sockets.',
      'Exhale as knees rise; control the negative.',
      'Stop before body swings into extension.',
    ],
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
    cues: [
      'Palms face you at the bottom; rotate as you clear the forehead.',
      'Wrists stacked; elbows under hands at the turnaround.',
      'Finish overhead without shrugging into ears.',
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
      'Take a wider stance and lean forward to bias the glutes over quads.',
    ],
    cues: [
      'Front foot planted; rear foot is a kickstand, not load-bearing.',
      'Knee tracks over shoelaces on the front leg.',
      'Torso angle stays steady—no bouncing out of the bottom.',
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
    cues: [
      'Brace before each pull; shoulders stay higher than hips.',
      'Pull elbows to pockets; squeeze blades at the top.',
      'Reset flat back every rep off the floor or pins.',
    ],
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
    cues: [
      'Torso parallel each rep; bar starts dead on the floor.',
      'Explosive pull, quiet eccentric.',
      'No thoracic rounding to “reach” the bar.',
    ],
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
    cues: [
      'Upper arms angled slightly back toward the rack.',
      'Elbows stay narrow—don’t let them wing out.',
      'Lower under control to the same spot every rep.',
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
    cues: [
      'Armpits on the pad; triceps stay touching.',
      'Only curl through the elbow joint.',
      'Pause at extension—don’t hyperextend harshly.',
    ],
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
    cues: [
      'Bar seated high on traps like a squat.',
      'Unlock knees slightly; hinge only at hips.',
      'Feel hamstrings load before you reverse.',
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
    cues: [
      'Hips extended; body is one line from knees to shoulders.',
      'Lower slowly—aim for five-plus seconds before progressing.',
      'Hands catch only when needed; push back up with hamstrings.',
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
    cues: [
      'Depress shoulders away from ears before bending elbows.',
      'Forward lean from hips; elbows drift back slightly.',
      'Press out of the bottom without losing shoulder position.',
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
    cues: [
      'Stand tall like there’s a string through the crown of your head.',
      'Short, quick steps; don’t let weights drift forward.',
      'Breathe behind the brace—no collapsing ribs.',
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
    cues: [
      'Shrug straight up—ears toward shoulders, not forward.',
      'One-second pause at the top.',
      'Control the lower; don’t drop the shoulders.',
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
    cues: [
      'Hands start at sternum; shoulders square to the front.',
      'Press the handle away without hips turning.',
      'Return hands to chest before losing tension.',
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
      'Squeeze glutes hard at lockout on every rep.',
    ],
    cues: [
      'Soft knees; arms are hooks—don’t row the rope.',
      'Hinge until hamstrings load; stand tall with glutes.',
      'Bell stays close as it travels between legs.',
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
    cues: [
      'Drive knees out over toes; shins stay more vertical.',
      'Grip narrow inside knees; lats on before you pull.',
      'Lock hips and knees together at the top—no hyper-extended back.',
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
    cues: [
      'Root feet; hike bell back with flat wrists.',
      'Snap hips to standing—arms float, don’t muscle the bell up.',
      'Bell floats to chest height for Russian swings.',
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
    cues: [
      'Body straight like a moving plank.',
      'Pull chest to bar—squeeze shoulder blades at the top.',
      'Lower until arms straight without sinking shoulders.',
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
    cues: [
      'Elbows high; bar sits on delts, not hands.',
      'Brace before each rep; knees steady.',
      'Drive up keeping torso as upright as mobility allows.',
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
    cues: [
      'Legs locked into pads before unracking.',
      'Bar tracks lower chest line on this angle.',
      'Control touch; drive feet through the bench.',
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
    cues: [
      'Feet slightly forward of hips if the bar tracks vertically.',
      'Sit between hips; knees track toes.',
      'Use safeties at a depth you own.',
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
    cues: [
      'Elbows level under the bar; torso stacked.',
      'Brace hard—this front load punishes soft cores.',
      'Squat between hips without dumping the elbows.',
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
    cues: [
      'Back flush on pad; feet rooted.',
      'Press up and slightly in—biceps beside ears.',
      'Lower to shoulders without flaring ribs.',
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
    cues: [
      'Chest on pad; slight elbow bend fixed.',
      'Open wide from rear delts—no upper trap shrug.',
      'Pause at peak contraction.',
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
    cues: [
      'Slight hip hinge; arms nearly straight to start.',
      'Pull with straight-arm lats—minimal elbow bend.',
      'Finish with hands by thighs, shoulders down.',
    ],
  }),
  reg({
    id: 'pike-push-up',
    name: 'Pike Push-Up',
    muscleGroups: ['shoulders', 'triceps', 'chest'],
    tags: ['bodyweight', 'vertical push', 'calisthenics'],
    equipment: 'Bodyweight',
    summary: 'Bodyweight pressing pattern with hips piked to emphasize shoulders and triceps.',
    instructions: [
      'Start in a pike position with hips high and hands shoulder-width.',
      'Bend elbows to lower head toward the floor in front of your hands.',
      'Press back up while keeping hips elevated and core braced.',
    ],
    tips: ['Elevate feet to increase difficulty and shoulder demand.'],
    cues: [
      'Hips high; head moves in front of hands, not straight down.',
      'Elbows track back—think “shoulders over hands.”',
      'Keep abs braced to protect the low back.',
    ],
  }),
  reg({
    id: 'bodyweight-squat',
    name: 'Bodyweight Squat',
    muscleGroups: ['quads', 'glutes', 'core'],
    tags: ['bodyweight', 'squat pattern', 'calisthenics'],
    equipment: 'Bodyweight',
    summary: 'Foundational squat pattern using body weight for lower-body strength and endurance.',
    instructions: [
      'Stand with feet around shoulder width and toes slightly out.',
      'Sit hips down and back while knees track over toes.',
      'Drive through mid-foot to stand tall with full control.',
    ],
    tips: [
      'Use a controlled tempo and full range that keeps your heels planted.',
      'Deep depth maximizes glute stretch at the bottom of each rep.',
    ],
    cues: [
      'Feet about shoulder width; toes slight turnout.',
      'Sit between hips; knees track over mid-foot.',
      'Stand tall without thrusting hips forward at lockout.',
    ],
  }),
  reg({
    id: 'glute-bridge',
    name: 'Glute Bridge',
    muscleGroups: ['glutes', 'hamstrings', 'core'],
    tags: ['bodyweight', 'posterior chain', 'calisthenics'],
    equipment: 'Bodyweight',
    summary: 'Hip extension movement to strengthen glutes and posterior chain without equipment.',
    instructions: [
      'Lie on your back with knees bent and feet flat.',
      'Brace core and drive through heels to lift hips until knees, hips, and shoulders align.',
      'Pause at the top, then lower hips under control.',
    ],
    tips: [
      'Avoid arching your lower back; think ribs down and glutes squeezed.',
      'Hold peak contraction for 2 seconds on warm-up sets.',
    ],
    cues: [
      'Drive through heels; dig shoulder blades into the floor.',
      'Top line is knees–hips–shoulders with glutes prime movers.',
      'Lower under control—don’t collapse.',
    ],
  }),
  reg({
    id: 'burpee',
    name: 'Burpee',
    muscleGroups: ['chest', 'shoulders', 'quads', 'core'],
    tags: ['bodyweight', 'conditioning', 'calisthenics'],
    equipment: 'Bodyweight',
    summary: 'Full-body conditioning movement combining squat, plank, and jump.',
    instructions: [
      'Squat down and place hands on floor.',
      'Jump or step feet back to a plank, then return feet forward.',
      'Stand and jump vertically before repeating.',
    ],
    tips: ['Step back and up instead of jumping if impact tolerance is limited.'],
    cues: [
      'Hands under shoulders; land softly into plank.',
      'Chest leads up from plank—stay stiff.',
      'Jump finishes tall with soft knees if you include it.',
    ],
  }),
  reg({
    id: 'mountain-climber',
    name: 'Mountain Climber',
    muscleGroups: ['core', 'shoulders', 'quads'],
    tags: ['bodyweight', 'conditioning', 'calisthenics'],
    equipment: 'Bodyweight',
    summary: 'Dynamic plank drill that trains core stiffness with hip flexion and cardio demand.',
    instructions: [
      'Start in a high plank with hands under shoulders.',
      'Drive one knee toward chest, then quickly alternate legs.',
      'Keep hips level and core tight throughout.',
    ],
    tips: ['Move smoothly before adding speed; do not let hips bounce high.'],
    cues: [
      'Hands stacked under shoulders.',
      'Drive knees toward sternum while hips stay low.',
      'Quiet upper body—movement is from hips.',
    ],
  }),
  reg({
    id: 'hollow-body-hold',
    name: 'Hollow Body Hold',
    muscleGroups: ['core'],
    tags: ['bodyweight', 'gymnastics', 'calisthenics'],
    equipment: 'Bodyweight',
    summary: 'Isometric core position that builds anti-extension strength and trunk control.',
    instructions: [
      'Lie on your back and press lower back into the floor.',
      'Lift shoulders and legs slightly off the floor with arms overhead or by your sides.',
      'Hold position while breathing shallowly and maintaining lower-back contact.',
    ],
    tips: ['Bend knees or lower arms if you cannot keep lower back flat.'],
    cues: [
      'Lower back glued down before you lift limbs.',
      'Reach long through fingertips and toes.',
      'Shallow breathing; ribs stay connected to pelvis.',
    ],
  }),
  reg({
    id: 'hanging-knee-raise',
    name: 'Hanging Knee Raise',
    muscleGroups: ['core'],
    tags: ['hanging', 'ab training', 'lower abs'],
    equipment: 'Bodyweight',
    summary: 'Hang from a bar or use a captain’s chair and curl knees toward chest for lower-ab emphasis.',
    instructions: [
      'Hang with active shoulders or support yourself on captain’s chair pads.',
      'Posterior pelvic tilt slightly; exhale as knees rise toward chest.',
      'Pause briefly; lower without swinging.',
    ],
    tips: [
      'Captain’s chair reduces grip demand if forearms fatigue first.',
      'Keep ribs down—avoid arching into lumbar extension at the top.',
    ],
    cues: [
      'Active hang; shoulders away from ears.',
      'Curl pelvis up as knees rise—think hips to ribs.',
      'Control the descent; no kipping.',
    ],
  }),
  reg({
    id: 'ab-wheel-rollout',
    name: 'Ab Wheel Rollout',
    muscleGroups: ['core', 'shoulders'],
    tags: ['anti-extension', 'core strength'],
    equipment: 'Ab wheel',
    summary: 'Roll forward from knees or feet while keeping a hollow, braced trunk.',
    instructions: [
      'Kneel (or stand) gripping the wheel; brace into a hollow body.',
      'Roll forward as far as you can without losing lower-back position.',
      'Pull back with lats and abs to return to start.',
    ],
    tips: [
      'Keep lower back rounded or in a hollow position—do not let ribs flare.',
      'Shorten range before form breaks; build distance over weeks.',
    ],
    cues: [
      'Ribs down; glutes lightly on if kneeling.',
      'Roll out only as far as you can pull back with control.',
      'Pull the wheel back with abs and lats, not hips sagging.',
    ],
  }),
  reg({
    id: 'incline-treadmill-walk',
    name: 'Incline Treadmill Walking',
    muscleGroups: ['quads', 'glutes', 'calves'],
    tags: ['cardio', 'LISS', 'conditioning'],
    isCardio: true,
    equipment: 'Treadmill',
    summary: 'Low-intensity steady-state walking on an incline to burn calories without heavy joint stress.',
    instructions: [
      'Set incline (typically 6–12%) and a comfortable walking pace.',
      'Stand tall; avoid holding the rails unless needed for balance.',
      'Maintain steady breathing for the full duration.',
    ],
    tips: [
      'Incline 6–10% at 2.8–3.2 mph is a common starting zone; progress incline or time weekly.',
      'Keep strides natural—do not lean excessively on the console.',
    ],
    cues: [
      'Chest up; soft landing through mid-foot.',
      'Arms swing naturally at your sides.',
      'Steady breath—you should be able to speak in short sentences.',
    ],
  }),
  reg({
    id: 'plank-shoulder-tap',
    name: 'Plank with Shoulder Taps',
    muscleGroups: ['core', 'shoulders'],
    tags: ['anti-rotation', 'isometric', 'core'],
    equipment: 'Bodyweight',
    summary: 'High plank while alternately tapping opposite shoulders—trains anti-rotation and deep core stability.',
    instructions: [
      'Set up in a strong high plank, feet slightly wider for stability.',
      'Shift weight slightly and tap one hand to the opposite shoulder.',
      'Alternate sides while keeping hips level and core braced.',
    ],
    tips: [
      'Widen feet or slow tempo if hips twist excessively.',
      'Excellent for a tight, stable waist without thickening obliques like heavy side bends.',
    ],
    cues: [
      'Feet wider than hip width if needed for control.',
      'Hips stay level—imagine a cup of water on your low back.',
      'Tap light and quick; brace before each tap.',
    ],
  }),
  reg({
    id: 'hip-90-90-switch',
    name: '90/90 Hip Switches',
    muscleGroups: ['glutes', 'hamstrings', 'core'],
    tags: ['mobility', 'warm-up', 'hips'],
    equipment: 'Bodyweight',
    summary: 'Seated hip mobility drill alternating internal and external rotation in a 90/90 position.',
    instructions: [
      'Sit with front shin parallel to torso and back shin perpendicular (both knees ~90°).',
      'Hinge forward over the front leg for a gentle stretch, then switch sides in one smooth motion.',
      'Flow side to side for the prescribed time.',
    ],
    tips: ['Use hands on the floor for balance; keep spine long rather than rounding aggressively.'],
    cues: [
      'Both sit bones grounded before you switch.',
      'Rotate from the hip, not the knee.',
      'Smooth transitions—no bouncing.',
    ],
  }),
  reg({
    id: 'cat-cow-child-pose',
    name: 'Cat-Cow to Child’s Pose',
    muscleGroups: ['back', 'core'],
    tags: ['mobility', 'warm-up', 'yoga'],
    equipment: 'Bodyweight',
    summary: 'Spinal flexion and extension flow finishing in child’s pose for thoracic and hip relaxation.',
    instructions: [
      'On all fours, alternate arching (cow) and rounding (cat) the spine with breath.',
      'After several cycles, sit hips back to heels into child’s pose with arms extended.',
      'Breathe into the back and hips.',
    ],
    tips: ['Move slowly—2–3 seconds per phase builds control and mind-body connection.'],
    cues: [
      'Cat: push floor away, tuck chin, exhale.',
      'Cow: chest through, tailbone up, inhale.',
      'Child’s pose: hips to heels; relax shoulders.',
    ],
  }),
  reg({
    id: 'worlds-greatest-stretch',
    name: 'World’s Greatest Stretch',
    muscleGroups: ['quads', 'glutes', 'hamstrings', 'core'],
    tags: ['mobility', 'dynamic stretch', 'warm-up'],
    equipment: 'Bodyweight',
    summary: 'Lunge with rotation and hamstring sweep—full-body opener for hips, thoracic spine, and groin.',
    instructions: [
      'Step into a long lunge; place opposite hand inside the front foot.',
      'Rotate open through the chest, then straighten the front leg for a hamstring stretch.',
      'Return to lunge and repeat for reps per side.',
    ],
    tips: ['Keep front knee tracking over toes in the lunge position.'],
    cues: [
      'Long lunge; back leg straight when possible.',
      'Open chest on the rotation—eyes follow the hand.',
      'Sweep to hamstring stretch without locking the knee aggressively.',
    ],
  }),
  reg({
    id: 'frog-stretch',
    name: 'Frog Stretch',
    muscleGroups: ['glutes', 'quads'],
    tags: ['mobility', 'adductors', 'hips'],
    equipment: 'Bodyweight',
    summary: 'Kneeling wide-knee position that opens adductors and inner thighs.',
    instructions: [
      'Kneel and spread knees wide, feet in line with knees or slightly turned out.',
      'Sink hips back toward heels while keeping spine neutral.',
      'Hold and breathe into the inner thighs.',
    ],
    tips: ['Opens adductors and inner thighs—ease into depth over several sessions.'],
    cues: [
      'Knees wide; ankles in line with knees.',
      'Hips shift back; chest stays lifted.',
      'Long exhales—never force painful range.',
    ],
  }),
  reg({
    id: 'brisk-walk',
    name: 'Light Brisk Walk',
    muscleGroups: ['quads', 'glutes', 'calves'],
    tags: ['cardio', 'recovery', 'low impact'],
    isCardio: true,
    equipment: 'Bodyweight',
    summary: 'Easy outdoor or treadmill walking to promote blood flow on recovery days.',
    instructions: [
      'Walk at a pace slightly faster than casual—you should feel warm but not breathless.',
      'Maintain upright posture and relaxed shoulders.',
      'Continue for the prescribed duration.',
    ],
    tips: ['Ideal after mobility work or on active recovery days.'],
    cues: [
      'Upright posture; eyes forward.',
      'Quick enough to elevate heart rate slightly.',
      'Relaxed arms and steady breathing.',
    ],
  }),
  reg({
    id: 'glute-kickback',
    name: 'Glute Kickback',
    muscleGroups: ['glutes'],
    tags: ['isolation', 'cable', 'bands'],
    equipment: 'Cable',
    summary: 'Hip extension behind the body with cable or band to isolate glute max.',
    instructions: [
      'Attach ankle strap or hold band; hinge slightly at hips for support.',
      'Extend leg back in an arc, squeezing glute at the top.',
      'Return without swinging; keep torso stable.',
    ],
    tips: [
      'Hold peak contraction 1–2 seconds on hypertrophy days.',
      'Avoid hyperextending the lower back—movement is from the hip only.',
    ],
    cues: [
      'Soft knee on the working leg.',
      'Squeeze glute at top—toes point slightly down.',
      'Torso still; no rocking.',
    ],
  }),
  reg({
    id: 'banded-clamshell',
    name: 'Seated or Banded Clamshell',
    muscleGroups: ['glutes'],
    tags: ['isolation', 'glute med', 'bands'],
    equipment: 'Band',
    summary: 'Hip abduction in side-lying or seated position to target gluteus medius for side-glute shape.',
    instructions: [
      'Band above knees (side-lying) or around thighs (seated).',
      'Keep feet together and open the top knee like a clamshell.',
      'Pause at end range; lower with control.',
    ],
    tips: ['Targets gluteus medius for the “side-glute” shelf—light weight, high quality reps.'],
    cues: [
      'Ribs stacked; pelvis does not roll back.',
      'Drive the knee up from the side glute, not the low back.',
      'Pause and squeeze at the top.',
    ],
  }),
  reg({
    id: 'sumo-squat',
    name: 'Sumo Squat (Plie Squat)',
    muscleGroups: ['quads', 'glutes'],
    tags: ['squat', 'inner thighs', 'hypertrophy'],
    equipment: 'Dumbbell',
    summary: 'Wide-stance squat with toes turned out to emphasize inner thighs and glutes.',
    instructions: [
      'Stand wide with toes out; hold one dumbbell vertically (goblet) or two at sides.',
      'Sit straight down between hips, knees tracking over toes.',
      'Drive through mid-foot to stand, squeezing glutes.',
    ],
    tips: [
      'Wide stance and toes out target inner thighs (gracilis) and glutes.',
      'Keep torso as upright as mobility allows.',
    ],
    cues: [
      'Knees track over second toe.',
      'Sit between hips—don’t collapse inward.',
      'Stand tall; squeeze glutes without thrusting ribs forward.',
    ],
  }),
  reg({
    id: 'deadbug',
    name: 'Deadbug',
    muscleGroups: ['core'],
    tags: ['anti-extension', 'coordination', 'lower abs'],
    equipment: 'Bodyweight',
    summary: 'Supine alternating arm and leg extensions while keeping the low back pressed down.',
    instructions: [
      'Lie on back, arms up, hips and knees at 90°.',
      'Brace; slowly extend opposite arm and leg toward the floor.',
      'Return and alternate sides.',
    ],
    tips: ['Focus on lifting the pelvis with lower abs on paired days—ribs stay down throughout.'],
    cues: [
      'Low back stays glued to the floor.',
      'Exhale as limbs extend; inhale to return.',
      'Move only as far as you can without arching.',
    ],
  }),
  reg({
    id: 'jump-squat',
    name: 'Jump Squat',
    muscleGroups: ['quads', 'glutes', 'calves'],
    tags: ['plyometric', 'HIIT', 'conditioning'],
    equipment: 'Bodyweight',
    summary: 'Explosive squat with vertical jump—power and metabolic demand for HIIT circuits.',
    instructions: [
      'Squat to comfortable depth with chest up.',
      'Explode upward, extending hips and knees fully.',
      'Land softly into the next rep with knees tracking toes.',
    ],
    tips: ['Land quietly—absorb through hips and knees to protect joints.'],
    cues: [
      'Chest up on the descent.',
      'Explode through mid-foot—full hip extension.',
      'Soft landing; immediate next rep or reset as programmed.',
    ],
  }),
  reg({
    id: 'russian-twist',
    name: 'Russian Twist',
    muscleGroups: ['core', 'shoulders'],
    tags: ['rotation', 'HIIT', 'conditioning'],
    equipment: 'Bodyweight',
    summary: 'Seated rotation of the torso for oblique endurance—often used in conditioning circuits.',
    instructions: [
      'Sit with knees bent, feet lifted or anchored for easier versions.',
      'Hold hands together; rotate torso side to side with control.',
      'Keep chest lifted and movement from the rib cage, not just arms.',
    ],
    tips: ['Controlled rotation beats fast sloppy reps for core training.'],
    cues: [
      'Chest tall; ribs down.',
      'Rotate through the thoracic spine.',
      'Feet light or lifted for more demand.',
    ],
  }),
  reg({
    id: 'pop-squat',
    name: 'Pop Squat',
    muscleGroups: ['quads', 'glutes'],
    tags: ['plyometric', 'HIIT', 'conditioning'],
    equipment: 'Bodyweight',
    summary: 'Quick squat with a small hop or “pop” at the top—lower-impact alternative to kettlebell swings in HIIT.',
    instructions: [
      'Perform a shallow to moderate squat.',
      'Drive up with a small hop or calf pop at lockout.',
      'Land immediately into the next rep with soft knees.',
    ],
    tips: ['Use when kettlebells are unavailable in HIIT circuits.'],
    cues: [
      'Quick rhythm—stay tall through the chest.',
      'Minimal ground contact on the pop.',
      'Knees track toes every landing.',
    ],
  }),
  reg({
    id: 'foam-roll-lower-body',
    name: 'Foam Rolling (Quads, IT Band, Glutes)',
    muscleGroups: ['quads', 'glutes'],
    tags: ['recovery', 'mobility', 'self-massage'],
    equipment: 'Foam roller',
    summary: 'Self-myofascial release for quads, IT bands, and glutes on rest or recovery days.',
    instructions: [
      'Roll slowly over each area for 30–60 seconds.',
      'Pause on tender spots and breathe; avoid rolling directly on joints or bones.',
      'Spend extra time on glutes and outer quad/IT band as needed.',
    ],
    tips: ['Light pressure is enough—more pain is not more gain.'],
    cues: [
      'Slow passes—about one inch per second.',
      'Breathe on tender spots; relax the muscle.',
      'Support your weight with hands to control pressure.',
    ],
  }),
  reg({
    id: 'hamstring-stretch-hold',
    name: 'Hamstring Stretch (Long Hold)',
    muscleGroups: ['hamstrings'],
    tags: ['stretch', 'recovery', 'flexibility'],
    equipment: 'Bodyweight',
    summary: 'Static hamstring stretch held 30–60 seconds per side for recovery and flexibility.',
    instructions: [
      'Hinge at hips with flat back or lie on back and raise one leg.',
      'Hold a gentle stretch without bouncing.',
      'Switch sides and repeat.',
    ],
    tips: ['Use on rest days after foam rolling for best recovery.'],
    cues: [
      'Hinge from hips—spine stays long.',
      'Gentle tension only; no bouncing.',
      'Breathe and relax into the hold.',
    ],
  }),
  reg({
    id: 'hip-flexor-stretch',
    name: 'Hip Flexor Stretch (Long Hold)',
    muscleGroups: ['quads', 'glutes'],
    tags: ['stretch', 'recovery', 'hips'],
    equipment: 'Bodyweight',
    summary: 'Half-kneeling or standing hip flexor stretch held 30–60 seconds per side.',
    instructions: [
      'Half-kneel with rear foot elevated optional; tuck pelvis slightly.',
      'Shift weight forward until you feel stretch in the front of the rear hip.',
      'Hold and breathe; switch sides.',
    ],
    tips: ['Posterior pelvic tilt increases the stretch—avoid arching the low back.'],
    cues: [
      'Squeeze glute on the back leg.',
      'Ribs down; tall posture.',
      'Forward shift comes from the hip, not lumbar arch.',
    ],
  }),
  reg({
    id: 'downward-dog-cobra-flow',
    name: 'Downward Dog to Cobra Flow',
    muscleGroups: ['back', 'shoulders', 'hamstrings'],
    tags: ['mobility', 'yoga', 'recovery'],
    equipment: 'Bodyweight',
    summary: 'Yoga-inspired flow between downward dog and cobra for spinal and shoulder mobility.',
    instructions: [
      'Start in downward dog—hips high, heels reaching down.',
      'Shift forward to plank, lower chest, and open into cobra or upward dog.',
      'Push back to downward dog and repeat for rounds.',
    ],
    tips: ['Move with breath—exhale into dog, inhale into cobra.'],
    cues: [
      'Long spine in downward dog.',
      'Shoulders away from ears in cobra.',
      'Smooth transitions—no rushing.',
    ],
  }),
  reg({
    id: 'pigeon-pose',
    name: 'Pigeon Pose',
    muscleGroups: ['glutes', 'hamstrings'],
    tags: ['stretch', 'yoga', 'recovery'],
    equipment: 'Bodyweight',
    summary: 'Deep glute and hip external rotator stretch held for extended time per side.',
    instructions: [
      'From all fours, bring one shin forward across the body; extend the back leg.',
      'Square hips toward the floor and hinge forward if comfortable.',
      'Hold for the prescribed time; switch sides.',
    ],
    tips: ['Deep glute release—use a block under the front hip if needed.'],
    cues: [
      'Front shin roughly parallel to the top of the mat (adjust as needed).',
      'Back leg long; hips level.',
      'Breathe into the outer hip of the front leg.',
    ],
  }),
  reg({
    id: 'low-lunge-hip-flexor-stretch',
    name: 'Low Lunge Hip Flexor Stretch',
    muscleGroups: ['quads', 'glutes'],
    tags: ['stretch', 'mobility', 'hips'],
    equipment: 'Bodyweight',
    summary: 'Low lunge position held to open hip flexors on the back leg.',
    instructions: [
      'Step into a low lunge, back knee down optional.',
      'Tuck pelvis and shift weight forward until stretch is felt in the rear hip.',
      'Hold; switch sides.',
    ],
    tips: ['Hold 60–90 seconds per side on recovery-focused days.'],
    cues: [
      'Front knee over ankle.',
      'Glute squeeze on back leg.',
      'Torso tall; ribs down.',
    ],
  }),
  reg({
    id: 'lying-spinal-twist',
    name: 'Lying Spinal Twist',
    muscleGroups: ['back', 'core'],
    tags: ['mobility', 'recovery', 'stretch'],
    equipment: 'Bodyweight',
    summary: 'Supine twist with knees dropped to one side for thoracic and lumbar decompression.',
    instructions: [
      'Lie on back; hug knees to chest or extend arms in T.',
      'Lower knees to one side while keeping shoulders on the floor.',
      'Hold and breathe; switch sides.',
    ],
    tips: ['Use for hip mobility and core decompression on active recovery days.'],
    cues: [
      'Shoulders stay heavy on the floor.',
      'Let gravity draw the knees down.',
      'Long exhales to deepen the twist gently.',
    ],
  }),
  reg({
    id: 'easy-stationary-bike',
    name: 'Easy Stationary Cycling',
    muscleGroups: ['quads', 'glutes', 'calves'],
    tags: ['cardio', 'recovery', 'low impact'],
    isCardio: true,
    equipment: 'Bike',
    summary: 'Light cycling to promote blood flow without taxing recovery.',
    instructions: [
      'Set low resistance on a stationary bike.',
      'Pedal at an easy, conversational pace for the prescribed duration.',
      'Stay upright with relaxed shoulders.',
    ],
    tips: ['Pair with mobility work on decompression days.'],
    cues: [
      'Low resistance; smooth cadence.',
      'Easy breathing throughout.',
      'Light contact on handlebars—no death grip.',
    ],
  }),
  reg({
    id: 'deep-static-stretch-lower',
    name: 'Deep Static Stretch (Hips & Lower Back)',
    muscleGroups: ['glutes', 'hamstrings', 'back'],
    tags: ['stretch', 'recovery', 'rest day'],
    equipment: 'Bodyweight',
    summary: 'Combined focus on hip flexors, glutes, hamstrings, and lower back for total recovery.',
    instructions: [
      'Cycle through hip flexor, figure-four glute, hamstring, and gentle lower-back stretches.',
      'Hold each 30–60 seconds per side with slow breathing.',
      'Avoid aggressive bouncing or painful ranges.',
    ],
    tips: [
      'Encourages optimal muscle recovery after a hard training week.',
      'Perfect for full rest and regeneration days.',
    ],
    cues: [
      'Pain-free tension only.',
      'Exhale longer than you inhale on each hold.',
      'Relax shoulders and jaw.',
    ],
  }),
]

import { CARDIO_LIBRARY } from '@/utils/cardioLibrary'

for (const ex of CARDIO_LIBRARY) {
  reg(ex)
  EXERCISE_LIBRARY.push(ex)
}

export function libraryExerciseIsCardio(ex: LibraryExercise | undefined): boolean {
  return ex?.isCardio === true
}

export function libraryExerciseIsCore(ex: LibraryExercise | undefined): boolean {
  if (!ex || libraryExerciseIsCardio(ex)) return false
  return ex.muscleGroups[0] === 'core'
}

export function resolveExerciseIsCore(exercise: {
  libraryId?: string
  isCore?: boolean
  isCardio?: boolean
  isCircuit?: boolean
  name?: string
}): boolean {
  if (exercise.isCircuit || exercise.isCardio) return false
  if (exercise.isCore === true) return true
  if (exercise.libraryId) return libraryExerciseIsCore(getLibraryExercise(exercise.libraryId))
  return libraryExerciseIsCore(findLibraryExerciseByName(exercise.name))
}

function resolveLibraryExerciseForCore(exercise: {
  libraryId?: string
  name?: string
}): LibraryExercise | undefined {
  if (exercise.libraryId) return getLibraryExercise(exercise.libraryId)
  return findLibraryExerciseByName(exercise.name)
}

/** Whether a core exercise shows the optional per-set time column. */
export function coreExerciseSupportsTimeLogging(exercise: {
  libraryId?: string
  isCore?: boolean
  isCardio?: boolean
  isCircuit?: boolean
  name?: string
}): boolean {
  if (!resolveExerciseIsCore(exercise)) return false
  const lib = resolveLibraryExerciseForCore(exercise)
  return lib?.repBasedCore !== true
}

export function libraryExerciseIsBodyweight(ex: LibraryExercise | undefined): boolean {
  if (!ex || libraryExerciseIsCardio(ex)) return false
  return ex.equipment === 'Bodyweight'
}

export function resolveExerciseIsCardio(
  entry: Pick<LibraryExercise, 'isCardio'> | undefined,
  libraryId?: string,
): boolean {
  if (entry?.isCardio === true) return true
  if (libraryId) return libraryExerciseIsCardio(getLibraryExercise(libraryId))
  return false
}

export function resolveExerciseIsBodyweight(exercise: {
  libraryId?: string
  isCardio?: boolean
  name?: string
}): boolean {
  if (exercise.isCardio) return false
  if (exercise.libraryId) {
    return libraryExerciseIsBodyweight(getLibraryExercise(exercise.libraryId))
  }
  const resolved = resolveManualExerciseInput((exercise.name ?? '').trim())
  return libraryExerciseIsBodyweight(resolved)
}

export function getLibraryExercise(id: string): LibraryExercise | undefined {
  return byId.get(id)
}

const byNormalizedName = new Map<string, LibraryExercise>()
for (const ex of EXERCISE_LIBRARY) {
  const key = ex.name.trim().toLowerCase()
  if (!byNormalizedName.has(key)) byNormalizedName.set(key, ex)
}

/**
 * Best-effort lookup for plan/log entries that have only a manually-typed name
 * (no `libraryId`). Case-insensitive, ignores surrounding whitespace.
 */
export function findLibraryExerciseByName(name: string | undefined): LibraryExercise | undefined {
  if (!name) return undefined
  return byNormalizedName.get(name.trim().toLowerCase())
}

/**
 * Library exercises that share at least one muscle group with the given exercise,
 * excluding the exercise itself. Sorted by number of overlapping muscle groups (desc),
 * then name. Used for “swap to a comparable movement” in the workout log.
 */
export function getComparableLibraryExercises(exercise: {
  libraryId?: string
  name: string
  isCardio?: boolean
}): LibraryExercise[] {
  const base =
    (exercise.libraryId && getLibraryExercise(exercise.libraryId)) ||
    findLibraryExerciseByName(exercise.name)
  if (!base) return []

  if (base.isCardio || exercise.isCardio) {
    return EXERCISE_LIBRARY.filter((ex) => ex.isCardio === true && ex.id !== base.id).sort(
      (a, b) => a.name.localeCompare(b.name),
    )
  }

  const baseGroups = new Set(base.muscleGroups)
  return EXERCISE_LIBRARY.filter((ex) => {
    if (ex.id === base.id) return false
    return ex.muscleGroups.some((g) => baseGroups.has(g))
  }).sort((a, b) => {
    const overlap = (ex: LibraryExercise) =>
      ex.muscleGroups.filter((g) => baseGroups.has(g)).length
    const d = overlap(b) - overlap(a)
    if (d !== 0) return d
    return a.name.localeCompare(b.name)
  })
}

/** Lowercase alphanumeric only — "Push-Up" and "pushups" both become "pushup". */
export function normalizeForExerciseMatch(s: string): string {
  return s.toLowerCase().replace(/[^a-z0-9]+/g, '')
}

const EXERCISE_QUERY_ALIASES = new Map<string, string>()

function registerExerciseAliases(exerciseId: string, phrases: string[]) {
  for (const phrase of phrases) {
    EXERCISE_QUERY_ALIASES.set(normalizeForExerciseMatch(phrase), exerciseId)
  }
}

registerExerciseAliases('push-up', [
  'pushups',
  'push ups',
  'pushup',
  'push up',
  'press ups',
  'pressups',
])
registerExerciseAliases('pull-up', [
  'pullups',
  'pull ups',
  'pullup',
  'pull up',
  'chinups',
  'chin ups',
  'chinup',
  'chin up',
])
registerExerciseAliases('hamstring-curl', [
  'leg curls',
  'leg curl',
  'legcurls',
  'legcurl',
  'lying leg curl',
  'seated leg curl',
  'ham curls',
  'ham curl',
])
registerExerciseAliases('bench-press', ['bench', 'flat bench', 'barbell bench'])
registerExerciseAliases('squat', ['squats', 'squat', 'back squat'])
registerExerciseAliases('romanian-deadlift', ['rdl', 'romanian deadlift', 'stiff leg deadlift'])
registerExerciseAliases('lat-pulldown', ['lat pulldown', 'lat pull down', 'pulldown'])
registerExerciseAliases('barbell-row', ['bent over row', 'bentover row', 'barbell row'])
registerExerciseAliases('overhead-press', ['ohp', 'shoulder press', 'military press'])
registerExerciseAliases('tricep-pushdown', [
  'tricep pushdown',
  'triceps pushdown',
  'rope pushdown',
  'cable pushdown',
])
registerExerciseAliases('dumbbell-curl', ['bicep curl', 'biceps curl', 'db curl', 'dumbbell curl'])
registerExerciseAliases('lateral-raise', ['lat raise', 'side raise', 'lateral raises'])
registerExerciseAliases('leg-press', ['legpress', 'leg press machine'])
registerExerciseAliases('leg-extension', ['leg extensions', 'leg extension', 'quad extension'])
registerExerciseAliases('calf-raise', ['calf raises', 'calf raise', 'calves'])
registerExerciseAliases('hip-thrust', ['hip thrusts', 'glute bridge weighted'])
registerExerciseAliases('face-pull', ['face pulls', 'face pull'])
registerExerciseAliases('cable-crunch', ['cable crunches', 'cable ab crunch'])
registerExerciseAliases('machine-pullover', ['machine pullover', 'pullover machine', 'nautilus pullover'])
registerExerciseAliases('cable-side-crunch', ['cable side crunches', 'side cable crunch', 'standing cable side crunch'])
registerExerciseAliases('weighted-decline-situp', ['weighted decline sit up', 'decline weighted situp', 'decline sit up weighted'])
registerExerciseAliases('dead-bug', ['dead bugs', 'deadbug'])

/** Body-region terms only — not movement keywords like "push" or "curl". */
const BODY_REGION_ALIASES: Record<string, MuscleGroup[]> = {
  legs: ['quads', 'hamstrings', 'glutes', 'calves'],
  leg: ['quads', 'hamstrings', 'glutes', 'calves'],
  'lower body': ['quads', 'hamstrings', 'glutes', 'calves'],
  lower: ['quads', 'hamstrings', 'glutes', 'calves'],
  arms: ['biceps', 'triceps', 'forearms'],
  arm: ['biceps', 'triceps', 'forearms'],
  'upper body': ['chest', 'back', 'shoulders', 'biceps', 'triceps'],
  upper: ['chest', 'back', 'shoulders', 'biceps', 'triceps'],
  abs: ['core'],
  core: ['core'],
  'posterior chain': ['hamstrings', 'glutes', 'back'],
}

function resolveBodyRegionGroups(needle: string): Set<MuscleGroup> {
  const groups = new Set<MuscleGroup>()
  for (const [alias, mapped] of Object.entries(BODY_REGION_ALIASES)) {
    const matches =
      needle === alias ||
      needle.startsWith(`${alias} `) ||
      (alias.includes(' ') && needle.includes(alias))
    if (!matches) continue
    for (const g of mapped) groups.add(g)
  }
  return groups
}

function fieldMatchesToken(field: string, token: string, normToken: string): boolean {
  const lower = field.toLowerCase()
  return lower.includes(token) || normalizeForExerciseMatch(field).includes(normToken)
}

function scoreExerciseForQuery(ex: LibraryExercise, query: string): number {
  const q = query.trim().toLowerCase()
  if (!q) return 0

  const normQ = normalizeForExerciseMatch(q)
  const normName = normalizeForExerciseMatch(ex.name)

  if (normName === normQ) return 1000
  if (ex.name.toLowerCase() === q) return 990

  const aliasId = EXERCISE_QUERY_ALIASES.get(normQ)
  if (aliasId === ex.id) return 950

  const tokens = q.split(/\s+/).filter(Boolean)
  let score = 0

  if (tokens.length === 1) {
    const token = tokens[0]!
    const normToken = normalizeForExerciseMatch(token)
    const nameMatch = fieldMatchesToken(ex.name, token, normToken)
    const tagMatch = ex.tags?.some((t) => fieldMatchesToken(t, token, normToken)) ?? false
    const equipMatch = ex.equipment ? fieldMatchesToken(ex.equipment, token, normToken) : false
    const muscleMatch = ex.muscleGroups.some((g) =>
      fieldMatchesToken(MUSCLE_GROUP_LABELS[g], token, normToken),
    )
    const normNameMatch = normName.includes(normToken)

    if (nameMatch) score += 120
    if (normNameMatch) score += 80
    if (tagMatch) score += 90
    if (equipMatch) score += 30
    if (muscleMatch) score += 25

    const primaryMatch = nameMatch || tagMatch || normNameMatch || equipMatch || muscleMatch
    if (primaryMatch) {
      if (fieldMatchesToken(ex.summary, token, normToken)) score += 25
      if (ex.cues?.some((c) => fieldMatchesToken(c, token, normToken))) score += 10
    } else if (token.length >= 5) {
      if (fieldMatchesToken(ex.summary, token, normToken)) score += 40
      if (ex.cues?.some((c) => fieldMatchesToken(c, token, normToken))) score += 15
    } else {
      return 0
    }

    const regionGroups = resolveBodyRegionGroups(q)
    if (regionGroups.size > 0 && ex.muscleGroups.some((g) => regionGroups.has(g))) {
      score += 55
    }
    return score
  }

  for (const token of tokens) {
    const normToken = normalizeForExerciseMatch(token)
    let tokenScore = 0
    if (fieldMatchesToken(ex.name, token, normToken)) tokenScore = 80
    else if (ex.tags?.some((t) => fieldMatchesToken(t, token, normToken))) tokenScore = 55
    else if (fieldMatchesToken(ex.summary, token, normToken)) tokenScore = 35
    else if (ex.equipment && fieldMatchesToken(ex.equipment, token, normToken)) tokenScore = 28
    else if (ex.cues?.some((c) => fieldMatchesToken(c, token, normToken))) tokenScore = 15
    else if (ex.muscleGroups.some((g) => fieldMatchesToken(MUSCLE_GROUP_LABELS[g], token, normToken))) {
      tokenScore = 20
    }
    if (tokenScore === 0) return 0
    score += tokenScore
  }

  if (normName.includes(normQ)) score += 140
  if (ex.name.toLowerCase().includes(q)) score += 100
  return score
}

const AUTO_MATCH_MIN_SCORE = 150
const AUTO_MATCH_SCORE_GAP = 45

function normNameStartsWithQuery(ex: LibraryExercise, normQuery: string): boolean {
  const normName = normalizeForExerciseMatch(ex.name)
  return normName.startsWith(normQuery) || normQuery.startsWith(normName)
}

/**
 * Best-effort library link for a manually typed exercise name (fuzzy names, slang, typos).
 * Returns undefined when the input is too ambiguous to auto-link.
 */
export function resolveManualExerciseInput(raw: string): LibraryExercise | undefined {
  const trimmed = raw.trim()
  if (!trimmed) return undefined

  const exact = findLibraryExerciseByName(trimmed)
  if (exact) return exact

  const norm = normalizeForExerciseMatch(trimmed)
  const aliasId = EXERCISE_QUERY_ALIASES.get(norm)
  if (aliasId) return getLibraryExercise(aliasId)

  for (const ex of EXERCISE_LIBRARY) {
    if (normalizeForExerciseMatch(ex.name) === norm) return ex
  }

  const ranked = searchLibrary(trimmed, 'all')
  if (ranked.length === 0) return undefined

  const top = ranked[0]!
  const topScore = scoreExerciseForQuery(top, trimmed)
  if (topScore < AUTO_MATCH_MIN_SCORE) return undefined

  if (ranked.length === 1) return top

  const secondScore = scoreExerciseForQuery(ranked[1]!, trimmed)
  if (topScore - secondScore >= AUTO_MATCH_SCORE_GAP) return top
  if (normNameStartsWithQuery(top, norm)) return top

  return undefined
}

/** Distinct equipment labels from the library (for filter chips). */
export function listLibraryEquipmentTypes(): string[] {
  const set = new Set<string>()
  for (const ex of EXERCISE_LIBRARY) {
    const eq = ex.equipment?.trim()
    if (eq) set.add(eq)
  }
  return [...set].sort((a, b) => a.localeCompare(b))
}

export function searchLibrary(
  q: string,
  group: LibraryFilterGroup,
): LibraryExercise[] {
  const needle = q.trim().toLowerCase()
  let list = EXERCISE_LIBRARY
  if (group === 'cardio') {
    list = list.filter((ex) => ex.isCardio === true)
  } else if (group !== 'all') {
    list = list.filter((ex) => ex.muscleGroups.includes(group))
  }
  if (!needle) return [...list].sort((a, b) => a.name.localeCompare(b.name))

  return list
    .map((ex) => ({ ex, score: scoreExerciseForQuery(ex, needle) }))
    .filter(({ score }) => score > 0)
    .sort((a, b) => {
      if (b.score !== a.score) return b.score - a.score
      return a.ex.name.localeCompare(b.ex.name)
    })
    .map(({ ex }) => ex)
}

export function isFavoritesLibrarySearchQuery(q: string): boolean {
  const needle = q.trim().toLowerCase()
  return needle === 'favorite' || needle === 'favorites'
}

export function libraryExercisesForFavoriteIds(favoriteIds: readonly string[]): LibraryExercise[] {
  const out: LibraryExercise[] = []
  for (const id of favoriteIds) {
    const ex = getLibraryExercise(id)
    if (ex) out.push(ex)
  }
  return out
}

/** Default cap for inline exercise-name suggestion dropdowns (use with ExerciseNameSuggestList). */
export const INLINE_LIBRARY_SUGGEST_LIMIT = 40

/** Inline add-exercise suggest list (library search, or saved favorites when query is "favorite(s)"). */
export function inlineLibrarySuggestMatches(
  q: string,
  favoriteIds: readonly string[],
  limit = INLINE_LIBRARY_SUGGEST_LIMIT,
): LibraryExercise[] {
  const trimmed = q.trim()
  if (!trimmed) return []
  if (isFavoritesLibrarySearchQuery(trimmed)) {
    return libraryExercisesForFavoriteIds(favoriteIds).slice(0, limit)
  }
  return searchLibrary(trimmed, 'all').slice(0, limit)
}