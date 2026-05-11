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
    tips: ['Keep dumbbells close to legs; neutral neck.'],
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
    tips: ['Short steps over-stress knee; stride for hip comfort.'],
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
    tips: ['Great for learning squat depth and torso position.'],
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
    tips: ['Do not hyperextend the lower back at the top.'],
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
    tips: ['Small range; focus on posterior pelvic tilt.'],
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
      'Lean torso slightly forward if you want more glute bias.',
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
    tips: ['Use a controlled tempo and full range that keeps your heels planted.'],
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
    tips: ['Avoid arching your lower back; think ribs down and glutes squeezed.'],
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
]

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
}): LibraryExercise[] {
  const base =
    (exercise.libraryId && getLibraryExercise(exercise.libraryId)) ||
    findLibraryExerciseByName(exercise.name)
  if (!base) return []
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
      if (ex.cues?.some((c) => c.toLowerCase().includes(needle))) return true
      return ex.muscleGroups.some((g) => MUSCLE_GROUP_LABELS[g].toLowerCase().includes(needle))
    })
    .sort((a, b) => a.name.localeCompare(b.name))
}