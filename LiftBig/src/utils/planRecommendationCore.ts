import type {
  ExperienceLevel,
  PickAPlanAnswers,
  PlanCatalogEntry,
  PlanRecommendationBase,
  TrainingEnvironment,
  TrainingGoal,
  WorkoutDuration,
} from '@/types/planCatalog'
import { ALL_PLAN_CATALOG } from '@/utils/guidedPlans/guidedPlanCatalog'

const GOAL_LABELS: Record<TrainingGoal, string> = {
  strength: 'Build Strength',
  size: 'Build Size',
  weightLoss: 'Lose Weight',
  liftBig: 'Lift Big',
}

const DURATION_LABELS: Record<WorkoutDuration, string> = {
  quick: 'Quick duration',
  standard: 'Standard duration',
  long: 'Long sessions',
}

const EXPERIENCE_LABELS: Record<ExperienceLevel, string> = {
  beginner: 'Beginner',
  intermediate: 'Intermediate',
  experienced: 'Experienced',
  liftaholic: 'Liftaholic',
}

const DURATION_ORDER: WorkoutDuration[] = ['quick', 'standard', 'long']

function normalizeDays(days: number | number[]): number[] {
  return Array.isArray(days) ? days : [days]
}

function normalizeDuration(d: WorkoutDuration | WorkoutDuration[]): WorkoutDuration[] {
  return Array.isArray(d) ? d : [d]
}

function daysScore(answer: number | null, entryDays: number | number[]): number {
  if (answer == null) return 0
  const targets = normalizeDays(entryDays)
  let best = 0
  for (const t of targets) {
    const diff = Math.abs(answer - t)
    if (diff === 0) best = Math.max(best, 30)
    else if (diff === 1) best = Math.max(best, 20)
    else if (diff === 2) best = Math.max(best, 10)
  }
  return best
}

function durationScore(
  answer: WorkoutDuration | null,
  entryDuration: WorkoutDuration | WorkoutDuration[],
): number {
  if (answer == null) return 0
  const targets = normalizeDuration(entryDuration)
  if (targets.includes(answer)) return 25
  const answerIdx = DURATION_ORDER.indexOf(answer)
  for (const t of targets) {
    const tIdx = DURATION_ORDER.indexOf(t)
    if (Math.abs(answerIdx - tIdx) === 1) return 15
  }
  return 0
}

function equipmentMatches(
  answer: TrainingEnvironment,
  entryEquipment: TrainingEnvironment[],
): boolean {
  if (entryEquipment.includes(answer)) return true
  // Planet Fitness locations now offer barbells and full free-weight areas comparable to commercial gyms.
  if (answer === 'planetFitness' && entryEquipment.includes('commercialGym')) return true
  return false
}

export function scoreCatalogEntry(entry: PlanCatalogEntry, answers: PickAPlanAnswers): number {
  let score = 0
  if (answers.experienceLevel && entry.experienceLevels.includes(answers.experienceLevel)) {
    score += 50
  }
  if (answers.goal && entry.goals.includes(answers.goal)) {
    score += 40
  }
  score += daysScore(answers.daysPerWeek, entry.days)
  score += durationScore(answers.duration, entry.duration)
  if (answers.equipment && equipmentMatches(answers.equipment, entry.equipment)) {
    score += 30
  }
  if (answers.stylePreference && entry.styles.includes(answers.stylePreference)) {
    score += 20
  }
  return score
}

export function buildMatchReasons(entry: PlanCatalogEntry, answers: PickAPlanAnswers): string[] {
  const reasons: string[] = []
  if (answers.goal && entry.goals.includes(answers.goal)) {
    reasons.push(GOAL_LABELS[answers.goal])
  }
  if (answers.daysPerWeek != null) {
    const targets = normalizeDays(entry.days)
    if (targets.some((d) => Math.abs(d - answers.daysPerWeek!) <= 1)) {
      reasons.push(`${answers.daysPerWeek} days/week`)
    }
  }
  if (answers.duration && normalizeDuration(entry.duration).includes(answers.duration)) {
    reasons.push(DURATION_LABELS[answers.duration])
  }
  if (answers.equipment && equipmentMatches(answers.equipment, entry.equipment)) {
    reasons.push('Equipment match')
  }
  if (answers.stylePreference && entry.styles.includes(answers.stylePreference)) {
    reasons.push('Style match')
  }
  if (answers.experienceLevel && entry.experienceLevels.includes(answers.experienceLevel)) {
    reasons.push(EXPERIENCE_LABELS[answers.experienceLevel])
  }
  return reasons
}

function archetypeKey(entry: PlanCatalogEntry): string {
  return `${entry.styles[0] ?? ''}|${entry.category}|${entry.scheduleMode}|${entry.goalTag}`
}

function pickDiverse(
  sorted: { entry: PlanCatalogEntry; score: number }[],
  count: number,
): { entry: PlanCatalogEntry; score: number }[] {
  const picked: { entry: PlanCatalogEntry; score: number }[] = []
  const usedArchetypes = new Set<string>()

  for (const item of sorted) {
    if (picked.length >= count) break
    const key = archetypeKey(item.entry)
    if (picked.length > 0 && usedArchetypes.has(key)) continue
    picked.push(item)
    usedArchetypes.add(key)
  }

  for (const item of sorted) {
    if (picked.length >= count) break
    if (!picked.some((p) => p.entry.id === item.entry.id)) {
      picked.push(item)
    }
  }

  return picked
}

export function recommendPlansRaw(
  answers: PickAPlanAnswers,
  catalog: PlanCatalogEntry[] = ALL_PLAN_CATALOG,
): PlanRecommendationBase[] {
  const scored = catalog
    .map((entry) => ({ entry, score: scoreCatalogEntry(entry, answers) }))
    .sort((a, b) => b.score - a.score)

  const top = pickDiverse(scored, 3)

  return top.map((item) => ({
    entry: item.entry,
    score: item.score,
    matchReasons: buildMatchReasons(item.entry, answers),
  }))
}

export function motivationalIntro(answers: PickAPlanAnswers): string {
  const parts: string[] = []
  if (answers.goal) {
    const goalPhrases: Record<TrainingGoal, string> = {
      strength: 'build strength',
      size: 'build muscle',
      weightLoss: 'lose weight while keeping muscle',
      liftBig: 'lift big with high-volume training',
    }
    parts.push(`aiming to ${goalPhrases[answers.goal]}`)
  }
  if (answers.daysPerWeek != null) {
    parts.push(`can train ${answers.daysPerWeek} day${answers.daysPerWeek === 1 ? '' : 's'}/week`)
  }
  if (parts.length === 0) {
    return "Here's what we'd start with based on your answers."
  }
  return `Looks like you're ${parts.join(' and ')}. Here's what we'd start with.`
}

export function matchBecauseCopy(reasons: string[]): string {
  if (reasons.length === 0) return 'A solid fit for your profile.'
  return `Matched because you chose ${reasons.slice(0, 3).join(' + ')}.`
}

export function topRecommendationScore(answers: PickAPlanAnswers): number {
  const recs = recommendPlansRaw(answers)
  return recs[0]?.score ?? 0
}
