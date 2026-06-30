/**
 * Stub for the production exercise library chunk (`exerciseLibrary-PHUUbGWG.js`).
 * Replaced by the real bundle at build time.
 */

export type Exercise = {
  id: string;
  name: string;
  equipment?: string;
  summary: string;
  muscleGroups: string[];
  tags?: string[];
  isCardio?: boolean;
  tutorialUrl?: string;
  instructions?: string[];
  cues?: string[];
  tips?: string[];
};

export const MUSCLE_GROUP_KEYS = [
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
] as const;

export type MuscleGroupKey = (typeof MUSCLE_GROUP_KEYS)[number];

export const MUSCLE_GROUP_LABELS: Record<MuscleGroupKey, string> = {
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
};

const SAMPLE_EXERCISES: Exercise[] = [
  {
    id: 'bench-press',
    name: 'Barbell Bench Press',
    muscleGroups: ['chest', 'triceps', 'shoulders'],
    tags: ['compound', 'push', 'powerlifting'],
    equipment: 'Barbell',
    summary: 'Horizontal press for chest with barbell on a flat bench.',
    instructions: ['Lie on the bench with feet flat.', 'Lower the bar to mid-chest.', 'Press up to lockout.'],
    tutorialUrl: 'https://www.youtube.com/shorts/hWbUlkb5Ms4',
  },
  {
    id: 'barbell-squat',
    name: 'Barbell Back Squat',
    muscleGroups: ['quads', 'glutes', 'core'],
    tags: ['compound', 'legs'],
    equipment: 'Barbell',
    summary: 'Bilateral squat with the bar on your upper back.',
    instructions: ['Brace and descend with control.', 'Drive through mid-foot to stand.'],
  },
  {
    id: 'brisk-walk',
    name: 'Brisk Walk',
    muscleGroups: ['quads', 'calves'],
    tags: ['cardio'],
    equipment: 'Bodyweight',
    summary: 'Low-impact steady-state cardio.',
    isCardio: true,
    instructions: ['Maintain an elevated pace you can sustain.'],
    tutorialUrl: 'https://www.youtube.com/shorts/RO1IRfIKlWM',
  },
];

/** Production export `d` — distinct equipment strings sorted alphabetically. */
export function getEquipmentOptions(): string[] {
  const set = new Set<string>();
  for (const ex of SAMPLE_EXERCISES) {
    const equipment = ex.equipment?.trim();
    if (equipment) set.add(equipment);
  }
  return [...set].sort((a, b) => a.localeCompare(b));
}

/** Production export `g` — filter/search exercises by query and muscle scope. */
export function searchExercises(
  query: string,
  muscleFilter: 'all' | 'cardio' | MuscleGroupKey
): Exercise[] {
  const needle = query.trim().toLowerCase();
  let list = SAMPLE_EXERCISES;

  if (muscleFilter === 'cardio') {
    list = list.filter((ex) => ex.isCardio === true);
  } else if (muscleFilter !== 'all') {
    list = list.filter((ex) => ex.muscleGroups.includes(muscleFilter));
  }

  if (!needle) {
    return [...list].sort((a, b) => a.name.localeCompare(b.name));
  }

  return list
    .filter((ex) => {
      const haystack = [
        ex.name,
        ex.summary,
        ex.equipment ?? '',
        ...ex.muscleGroups.map((mg) => MUSCLE_GROUP_LABELS[mg as MuscleGroupKey] ?? mg),
        ...(ex.tags ?? []),
      ]
        .join(' ')
        .toLowerCase();
      return haystack.includes(needle);
    })
    .sort((a, b) => a.name.localeCompare(b.name));
}
