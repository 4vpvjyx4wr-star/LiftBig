export type ExperienceLevel = 'beginner' | 'intermediate' | 'experienced' | 'liftaholic'
export type TrainingGoal = 'strength' | 'size' | 'weightLoss' | 'liftBig'
export type WorkoutDuration = 'quick' | 'standard' | 'long'
export type TrainingEnvironment =
  | 'commercialGym'
  | 'planetFitness'
  | 'homeGym'
  | 'dumbbellsOnly'
  | 'minimalEquipment'
export type StylePreference =
  | 'balanced'
  | 'compound'
  | 'bodybuilding'
  | 'minimalist'
  | 'supersets'
  | 'machines'
  | 'aesthetic'
  | 'athletic'

export type PlanScheduleMode = 'repeat' | 'folder'

export type PlanCatalogEntry = {
  id: string
  title: string
  description: string
  experienceLevels: ExperienceLevel[]
  goals: TrainingGoal[]
  days: number | number[]
  duration: WorkoutDuration | WorkoutDuration[]
  equipment: TrainingEnvironment[]
  styles: StylePreference[]
  volumeScore: number
  difficulty: 'Beginner' | 'Intermediate' | 'Advanced' | 'Elite'
  estimatedMinutes: number
  primaryMuscles: string[]
  progressionStyle: string
  goalTag: string
  scheduleMode: PlanScheduleMode
  templateId?: string
  folderId?: string
  /** When scheduleMode is folder, rotate only these template IDs (in order). */
  scheduleTemplateIds?: string[]
  category: ExperienceLevel
}

export type PickAPlanAnswers = {
  experienceLevel: ExperienceLevel | null
  goal: TrainingGoal | null
  daysPerWeek: number | null
  duration: WorkoutDuration | null
  equipment: TrainingEnvironment | null
  stylePreference: StylePreference | null
}

export type RecommendationBadge = 'bestMatch' | 'greatAlternative' | 'somethingDifferent'

export type PlanRecommendation = {
  entry: PlanCatalogEntry
  score: number
  badge: RecommendationBadge
  matchReasons: string[]
}

export type PlanRecommendationBase = Omit<PlanRecommendation, 'badge'>
