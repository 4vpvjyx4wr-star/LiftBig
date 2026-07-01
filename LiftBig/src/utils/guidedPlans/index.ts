import type { TemplateFolder, WorkoutTemplate } from '@/types/workout'
import { BEGINNER_PLANS, BEGINNER_UPPER_LOWER_FOLDER } from './beginnerPlans'
import { EXPERIENCED_GUIDED_PLANS } from './experiencedPlans'
import { GUIDED_PLAN_FOLDERS } from './guidedPlanFolders'
import { INTERMEDIATE_GUIDED_PLANS } from './intermediatePlans'
import { LIFTAHOLIC_GUIDED_PLANS } from './liftaholicPlans'

export * from './guidedPlanFolders'
export * from './guidedPlanCatalog'
export * from './beginnerPlans'
export * from './intermediatePlans'
export * from './experiencedPlans'
export * from './liftaholicPlans'

export const ALL_GUIDED_FOLDERS: TemplateFolder[] = [
  ...GUIDED_PLAN_FOLDERS,
  BEGINNER_UPPER_LOWER_FOLDER,
]

export const ALL_GUIDED_PLANS: WorkoutTemplate[] = [
  ...BEGINNER_PLANS,
  ...INTERMEDIATE_GUIDED_PLANS,
  ...EXPERIENCED_GUIDED_PLANS,
  ...LIFTAHOLIC_GUIDED_PLANS,
]

export const GUIDED_PLAN_IDS = new Set(ALL_GUIDED_PLANS.map((p) => p.id))
