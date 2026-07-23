import type { LibraryExercise } from '@/utils/exerciseLibrary'

type CardioSeed = Omit<LibraryExercise, 'isCardio' | 'muscleGroups'> & {
  muscleGroups?: LibraryExercise['muscleGroups']
}

function cardio(seed: CardioSeed): LibraryExercise {
  return {
    muscleGroups: seed.muscleGroups ?? ['quads', 'calves'],
    tags: ['cardio', ...(seed.tags ?? [])],
    isCardio: true,
    ...seed,
  }
}

/** Cardio and common sports — duration-only when added to a day or plan. */
export const CARDIO_LIBRARY: LibraryExercise[] = [
  cardio({
    id: 'walking',
    name: 'Walking',
    tags: ['outdoor', 'low impact', 'LISS'],
    equipment: 'Bodyweight',
    summary: 'Outdoor or indoor walking at an easy to moderate pace.',
    instructions: [
      'Walk at a steady pace you can sustain for the full session.',
      'Stand tall with relaxed shoulders and natural arm swing.',
      'Track time rather than distance unless you prefer miles or km.',
    ],
    tips: ['A conversational pace is ideal for recovery and fat-burning sessions.'],
  }),
  cardio({
    id: 'treadmill-walking',
    name: 'Treadmill Walking',
    tags: ['indoor', 'low impact', 'LISS'],
    equipment: 'Treadmill',
    summary: 'Flat or lightly inclined treadmill walking.',
    instructions: [
      'Set a comfortable walking speed (often 2.5–4.0 mph).',
      'Stand centered on the belt; avoid leaning on the rails.',
      'Maintain steady breathing for the prescribed duration.',
    ],
  }),
  cardio({
    id: 'running',
    name: 'Running',
    tags: ['outdoor', 'conditioning'],
    equipment: 'Bodyweight',
    summary: 'Outdoor running at an easy, moderate, or hard effort.',
    instructions: [
      'Warm up with easy jogging or walking if the session is longer.',
      'Land with quick, light steps; keep posture tall.',
      'Cool down with walking for a few minutes when finished.',
    ],
    tips: ['Easy runs should feel conversational; hard runs need adequate recovery.'],
  }),
  cardio({
    id: 'treadmill-running',
    name: 'Treadmill Running',
    tags: ['indoor', 'conditioning'],
    equipment: 'Treadmill',
    summary: 'Indoor running on a treadmill.',
    instructions: [
      'Set speed and incline to match your planned effort.',
      'Stay centered on the belt with a natural stride.',
      'Use the safety clip if available.',
    ],
  }),
  cardio({
    id: 'stairmaster',
    name: 'StairMaster',
    tags: ['indoor', 'conditioning', 'legs'],
    equipment: 'Stair climber',
    summary: 'Continuous stepping on a stair-climber machine.',
    instructions: [
      'Stand upright with a light hand grip on the rails for balance only.',
      'Drive through the full foot on each step.',
      'Keep a steady cadence for the full duration.',
    ],
    tips: ['Avoid leaning heavily on the handles — let your legs do the work.'],
  }),
  cardio({
    id: 'swimming',
    name: 'Swimming',
    tags: ['low impact', 'full body'],
    equipment: 'Pool',
    summary: 'Lap swimming or continuous pool work.',
    instructions: [
      'Choose a stroke and pace you can sustain (freestyle, backstroke, etc.).',
      'Focus on smooth breathing and long, relaxed strokes.',
      'Rest briefly at the wall only as needed to hit your time goal.',
    ],
  }),
  cardio({
    id: 'hiking',
    name: 'Hiking',
    tags: ['outdoor', 'LISS', 'legs'],
    equipment: 'Bodyweight',
    summary: 'Trail or hill walking with elevation and varied terrain.',
    instructions: [
      'Wear appropriate footwear and pace yourself on climbs.',
      'Use trekking poles if you like them for steep sections.',
      'Stay hydrated on longer outings.',
    ],
  }),
  cardio({
    id: 'indoor-cycling',
    name: 'Indoor Cycling',
    tags: ['indoor', 'low impact', 'LISS'],
    equipment: 'Stationary bike',
    summary: 'Stationary bike or spin bike at any intensity.',
    instructions: [
      'Adjust seat height so your knee has a slight bend at the bottom of the pedal stroke.',
      'Maintain smooth cadence and relaxed shoulders.',
      'Increase resistance or cadence to raise effort as desired.',
    ],
  }),
  cardio({
    id: 'outdoor-cycling',
    name: 'Outdoor Cycling',
    tags: ['outdoor', 'endurance'],
    equipment: 'Bike',
    summary: 'Road, trail, or commuter cycling outdoors.',
    instructions: [
      'Wear a helmet and check brakes and tires before heading out.',
      'Spin smoothly and shift gears to keep a sustainable cadence.',
      'Hydrate on longer rides.',
    ],
  }),
  cardio({
    id: 'tennis',
    name: 'Tennis',
    tags: ['sport', 'agility'],
    equipment: 'Racquet',
    summary: 'Singles or doubles tennis — rallies, drills, or match play.',
    instructions: [
      'Warm up with light hitting and footwork before full pace.',
      'Track total active time on court for your log.',
      'Include rest between games as part of your session if needed.',
    ],
  }),
  cardio({
    id: 'pickleball',
    name: 'Pickleball',
    tags: ['sport', 'agility'],
    equipment: 'Paddle',
    summary: 'Pickleball games or drills on indoor or outdoor courts.',
    instructions: [
      'Warm up with dinks and volleys before competitive play.',
      'Log total time on court including games and rest between points.',
    ],
  }),
  cardio({
    id: 'table-tennis',
    name: 'Table Tennis',
    tags: ['sport', 'agility'],
    equipment: 'Paddle',
    summary: 'Ping pong — casual rallies, drills, or matches.',
    instructions: [
      'Stay light on your feet and track total active session time.',
      'Include short breaks between games in your logged duration.',
    ],
  }),
  cardio({
    id: 'basketball',
    name: 'Basketball',
    tags: ['sport', 'conditioning'],
    equipment: 'Ball',
    summary: 'Shooting, scrimmages, or pickup games.',
    instructions: [
      'Warm up with layups and light shooting before full-court play.',
      'Log total court time for the session.',
    ],
  }),
  cardio({
    id: 'soccer',
    name: 'Soccer',
    tags: ['sport', 'conditioning'],
    equipment: 'Ball',
    summary: 'Soccer drills, small-sided games, or full matches.',
    instructions: [
      'Warm up with jogging and dynamic stretches.',
      'Log total field time including stoppages if tracking a full session.',
    ],
  }),
  cardio({
    id: 'volleyball',
    name: 'Volleyball',
    tags: ['sport', 'agility'],
    equipment: 'Ball',
    summary: 'Indoor or beach volleyball — drills or match play.',
    instructions: [
      'Warm up shoulders and ankles before jumping.',
      'Log total court or sand time.',
    ],
  }),
  cardio({
    id: 'rowing-machine',
    name: 'Rowing Machine',
    tags: ['indoor', 'full body', 'conditioning'],
    equipment: 'Rower',
    summary: 'Gym rowing ergometer.',
    instructions: [
      'Drive with legs first, then lean back and pull with arms.',
      'Return in reverse order: arms, body, legs.',
      'Maintain steady stroke rate for endurance sessions.',
    ],
  }),
  cardio({
    id: 'elliptical',
    name: 'Elliptical',
    tags: ['indoor', 'low impact', 'LISS'],
    equipment: 'Elliptical',
    summary: 'Low-impact elliptical trainer at any resistance.',
    instructions: [
      'Stand tall without leaning on the moving handles.',
      'Use a smooth, continuous stride.',
      'Adjust resistance to match your target effort.',
    ],
  }),
  cardio({
    id: 'jump-rope',
    name: 'Jump Rope',
    tags: ['conditioning', 'HIIT'],
    equipment: 'Jump rope',
    summary: 'Single unders, double unders, or interval rope work.',
    instructions: [
      'Stay on the balls of your feet with small, quick jumps.',
      'Start with short bouts and rest as needed to fill your duration.',
      'Keep elbows in and wrists turning the rope.',
    ],
  }),
  cardio({
    id: 'boxing',
    name: 'Boxing',
    tags: ['sport', 'HIIT', 'conditioning'],
    equipment: 'Gloves / bag',
    summary: 'Heavy bag, mitt work, or shadowboxing rounds.',
    instructions: [
      'Wrap hands and use proper form on the bag or pads.',
      'Work in rounds (e.g. 3 min on, 1 min off) until your total time is complete.',
    ],
  }),
  cardio({
    id: 'kickboxing',
    name: 'Kickboxing',
    tags: ['sport', 'HIIT', 'conditioning'],
    equipment: 'Gloves / bag',
    summary: 'Bag work or class-style kickboxing combinations.',
    instructions: [
      'Balance punches and kicks with a stable guard.',
      'Log total class or bag time including short rests between rounds.',
    ],
  }),
  cardio({
    id: 'racquetball',
    name: 'Racquetball',
    tags: ['sport', 'agility'],
    equipment: 'Racquet',
    summary: 'Racquetball or squash-style court play.',
    instructions: [
      'Warm up with easy rallies before match pace.',
      'Log total court time.',
    ],
  }),
  cardio({
    id: 'badminton',
    name: 'Badminton',
    tags: ['sport', 'agility'],
    equipment: 'Racquet',
    summary: 'Badminton rallies, drills, or match play.',
    instructions: [
      'Stay light on your feet and track total session time.',
    ],
  }),
  cardio({
    id: 'golf-walking',
    name: 'Golf (Walking)',
    tags: ['sport', 'low impact', 'outdoor'],
    equipment: 'Clubs',
    summary: 'Walking the course — bag carry or push cart.',
    instructions: [
      'Log total time on course for an active recovery day.',
      'Include walking between holes in your duration.',
    ],
  }),
  cardio({
    id: 'dance-cardio',
    name: 'Dance Cardio',
    tags: ['class', 'conditioning'],
    equipment: 'Bodyweight',
    summary: 'Dance fitness class or freestyle cardio dancing.',
    instructions: [
      'Follow class choreography or freestyle to music.',
      'Log total active dance time.',
    ],
  }),
  cardio({
    id: 'yoga-flow',
    name: 'Yoga',
    tags: ['mobility', 'recovery', 'low impact'],
    equipment: 'Mat',
    summary: 'Vinyasa, power yoga, or steady flow practice.',
    instructions: [
      'Move with breath through your chosen sequence.',
      'Log total mat time for the session.',
    ],
  }),
  cardio({
    id: 'pilates',
    name: 'Pilates',
    tags: ['mobility', 'core', 'low impact'],
    equipment: 'Mat',
    summary: 'Mat or reformer Pilates session.',
    instructions: [
      'Focus on controlled movement and breathing.',
      'Log total session duration.',
    ],
  }),
  cardio({
    id: 'martial-arts',
    name: 'Martial Arts',
    tags: ['sport', 'conditioning'],
    equipment: 'Gi / gear',
    summary: 'Karate, BJJ, muay thai, or other martial arts training.',
    instructions: [
      'Include warm-up, technique, and sparring time in your log.',
    ],
  }),
  cardio({
    id: 'rock-climbing',
    name: 'Rock Climbing',
    tags: ['sport', 'full body'],
    equipment: 'Climbing gym',
    summary: 'Bouldering or roped climbing at the gym or crag.',
    instructions: [
      'Warm up on easy routes before harder attempts.',
      'Log total active climbing time (rest between attempts counts toward session length).',
    ],
  }),
  cardio({
    id: 'skiing',
    name: 'Skiing',
    tags: ['sport', 'outdoor', 'seasonal'],
    equipment: 'Skis',
    summary: 'Downhill or alpine skiing.',
    instructions: [
      'Log total time on slopes for the day.',
      'Include lift rides as part of a full mountain session if desired.',
    ],
  }),
  cardio({
    id: 'cross-country-skiing',
    name: 'Cross-Country Skiing',
    tags: ['sport', 'outdoor', 'endurance', 'seasonal'],
    equipment: 'Skis',
    summary: 'Classic or skate skiing on trails.',
    instructions: [
      'Maintain steady effort appropriate to trail conditions.',
      'Dress in layers and stay hydrated.',
    ],
  }),
  cardio({
    id: 'snowboarding',
    name: 'Snowboarding',
    tags: ['sport', 'outdoor', 'seasonal'],
    equipment: 'Snowboard',
    summary: 'Snowboarding at the resort or backcountry.',
    instructions: [
      'Log total riding time for the session.',
    ],
  }),
  cardio({
    id: 'kayaking',
    name: 'Kayaking',
    tags: ['outdoor', 'upper body', 'low impact'],
    equipment: 'Kayak',
    summary: 'Flatwater or light touring kayak paddling.',
    instructions: [
      'Use torso rotation, not just arms, for each stroke.',
      'Wear a PFD and log total paddling time.',
    ],
  }),
  cardio({
    id: 'paddleboarding',
    name: 'Paddleboarding',
    tags: ['outdoor', 'core', 'balance'],
    equipment: 'SUP',
    summary: 'Stand-up paddleboarding on calm water.',
    instructions: [
      'Start kneeling if balance is new to you.',
      'Log total time on the board.',
    ],
  }),
  cardio({
    id: 'roller-skating',
    name: 'Roller Skating / Blading',
    tags: ['outdoor', 'conditioning'],
    equipment: 'Skates',
    summary: 'Roller skating, inline skating, or rink laps.',
    instructions: [
      'Wear protective gear when learning or going fast.',
      'Log total skating time.',
    ],
  }),
  cardio({
    id: 'hiit-class',
    name: 'HIIT / Bootcamp Class',
    tags: ['class', 'HIIT', 'conditioning'],
    equipment: 'Mixed',
    summary: 'Group HIIT, bootcamp, or circuit-style cardio class.',
    instructions: [
      'Follow instructor intervals and modify as needed.',
      'Log total class duration.',
    ],
  }),
]
