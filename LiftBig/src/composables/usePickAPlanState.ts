import { computed, ref, watch } from 'vue'
import type {
  ExperienceLevel,
  PickAPlanAnswers,
  StylePreference,
  TrainingEnvironment,
  TrainingGoal,
  WorkoutDuration,
} from '@/types/planCatalog'
import { LIFTBIG_LEGACY_STORAGE_KEY_ALIASES, LIFTBIG_STORAGE_KEYS } from '@/utils/liftbigStorageKeys'
import { loadJsonWithRecovery, saveJson } from '@/utils/storage'
import { haptic } from '@/utils/haptics'

const KEY = LIFTBIG_STORAGE_KEYS.pickAPlan
const TOTAL_STEPS = 6

export type StepOption<T> = {
  value: T
  emoji: string
  title: string
  description: string
}

export const EXPERIENCE_OPTIONS: StepOption<ExperienceLevel>[] = [
  { value: 'beginner', emoji: '🌱', title: 'Beginner', description: 'New to lifting or inconsistent (<1 year)' },
  { value: 'intermediate', emoji: '🔥', title: 'Intermediate', description: 'Comfortable in the gym and understands progression' },
  { value: 'experienced', emoji: '⚡', title: 'Experienced', description: 'Several years training with clear goals' },
  { value: 'liftaholic', emoji: '💀', title: 'Liftaholic', description: 'Lives in the gym and wants serious volume' },
]

export const GOAL_OPTIONS: StepOption<TrainingGoal>[] = [
  { value: 'strength', emoji: '🏋️', title: 'Build Strength', description: 'Increase compound lifts.' },
  { value: 'size', emoji: '💪', title: 'Build Size', description: 'Hypertrophy and aesthetics.' },
  { value: 'weightLoss', emoji: '⚖️', title: 'Lose Weight', description: 'Preserve muscle while increasing calorie expenditure.' },
  { value: 'liftBig', emoji: '🚀', title: 'I Just Wanna Lift Big', description: 'High-volume balanced training.' },
]

export const DAYS_OPTIONS: StepOption<number>[] = [2, 3, 4, 5, 6, 7].map((n) => ({
  value: n,
  emoji: String(n),
  title: `${n} days`,
  description: n === 2 ? 'Minimal commitment' : n >= 6 ? 'High frequency' : 'Balanced weekly load',
}))

export const DURATION_OPTIONS: StepOption<WorkoutDuration>[] = [
  { value: 'quick', emoji: '⚡', title: 'Quick (≈30 min)', description: 'Short, focused sessions.' },
  { value: 'standard', emoji: '⏱️', title: 'Standard (≈60 min)', description: 'Classic gym session length.' },
  { value: 'long', emoji: '🕐', title: 'Long (60–90+ min)', description: 'More volume and accessories.' },
]

export const EQUIPMENT_OPTIONS: StepOption<TrainingEnvironment>[] = [
  { value: 'commercialGym', emoji: '🏢', title: 'Commercial Gym', description: 'Full gym with barbells and machines.' },
  { value: 'planetFitness', emoji: '🪐', title: 'Planet Fitness', description: 'Barbells, dumbbells, machines, and cables — full gym access.' },
  { value: 'homeGym', emoji: '🏠', title: 'Home Gym', description: 'Barbell, rack, and some equipment.' },
  { value: 'dumbbellsOnly', emoji: '🏋️', title: 'Dumbbells Only', description: 'Pairs of dumbbells at home.' },
  { value: 'minimalEquipment', emoji: '🎒', title: 'Minimal Equipment', description: 'Bodyweight and bands.' },
]

export const STYLE_OPTIONS: StepOption<StylePreference>[] = [
  { value: 'balanced', emoji: '⚖️', title: 'Balanced', description: 'Mix of compounds and accessories.' },
  { value: 'compound', emoji: '🏋️', title: 'Heavy Compound Focus', description: 'Squat, bench, deadlift priority.' },
  { value: 'bodybuilding', emoji: '💪', title: 'Bodybuilding', description: 'Muscle isolation and pump.' },
  { value: 'minimalist', emoji: '✨', title: 'Minimalist', description: 'Few exercises, high quality.' },
  { value: 'supersets', emoji: '🔥', title: 'Supersets / Fast Pace', description: 'Keep heart rate up.' },
  { value: 'machines', emoji: '⚙️', title: 'Machines Preferred', description: 'Stable, joint-friendly paths.' },
  { value: 'aesthetic', emoji: '🎯', title: 'Aesthetic / V-Taper', description: 'Shoulders, back, proportions.' },
  { value: 'athletic', emoji: '🏃', title: 'Athletic', description: 'Power, conditioning, movement.' },
]

const EMPTY_ANSWERS: PickAPlanAnswers = {
  experienceLevel: null,
  goal: null,
  daysPerWeek: null,
  duration: null,
  equipment: null,
  stylePreference: null,
}

type PersistedMeta = {
  lastTopMatchTitle: string | null
  completedAt: string | null
}

function loadMeta(): PersistedMeta {
  const raw = loadJsonWithRecovery<unknown>(KEY, null, {
    legacyKeys: LIFTBIG_LEGACY_STORAGE_KEY_ALIASES.pickAPlan,
  })
  if (!raw || typeof raw !== 'object') {
    return { lastTopMatchTitle: null, completedAt: null }
  }
  const o = raw as PersistedMeta & { answers?: PickAPlanAnswers }
  return {
    lastTopMatchTitle: typeof o.lastTopMatchTitle === 'string' ? o.lastTopMatchTitle : null,
    completedAt: typeof o.completedAt === 'string' ? o.completedAt : null,
  }
}

export function usePickAPlanState() {
  const meta = loadMeta()
  const stepIndex = ref(0)
  const answers = ref<PickAPlanAnswers>({ ...EMPTY_ANSWERS })
  const lastTopMatchTitle = ref<string | null>(meta.lastTopMatchTitle)
  const completedAt = ref<string | null>(meta.completedAt)

  const isResults = computed(() => stepIndex.value >= TOTAL_STEPS)
  const progressLabel = computed(() =>
    isResults.value ? 'Your recommendations' : `Step ${stepIndex.value + 1} of ${TOTAL_STEPS}`,
  )
  const progressPercent = computed(() =>
    isResults.value ? 100 : Math.round(((stepIndex.value + 1) / TOTAL_STEPS) * 100),
  )

  function persistMeta() {
    saveJson(KEY, {
      answers: answers.value,
      lastTopMatchTitle: lastTopMatchTitle.value,
      completedAt: completedAt.value,
    })
  }

  function selectAndAdvance<K extends keyof PickAPlanAnswers>(key: K, value: PickAPlanAnswers[K]) {
    haptic('tap')
    answers.value = { ...answers.value, [key]: value }
    stepIndex.value += 1
    persistMeta()
  }

  function skipStep() {
    stepIndex.value += 1
    persistMeta()
  }

  function goBack() {
    if (stepIndex.value > 0) stepIndex.value -= 1
  }

  function restart() {
    answers.value = { ...EMPTY_ANSWERS }
    stepIndex.value = 0
    persistMeta()
  }

  function finishWithMatch(title: string) {
    lastTopMatchTitle.value = title
    completedAt.value = new Date().toISOString()
    persistMeta()
  }

  watch([answers, lastTopMatchTitle, completedAt], persistMeta, { deep: true })

  return {
    stepIndex,
    answers,
    isResults,
    progressLabel,
    progressPercent,
    lastTopMatchTitle,
    selectAndAdvance,
    skipStep,
    goBack,
    restart,
    finishWithMatch,
  }
}

export type PickAPlanStateApi = ReturnType<typeof usePickAPlanState>
