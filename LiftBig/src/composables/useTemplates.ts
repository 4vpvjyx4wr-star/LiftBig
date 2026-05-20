import { ref } from 'vue'
import type { TemplateFolder, WorkoutTemplate } from '@/types/workout'
import { BUNS_AND_THIGHS_FOLDER, BUNS_AND_THIGHS_PLANS } from '@/utils/bunsAndThighsPlans'
import {
  CALISTHENICS_FULL_BODY_FOLDER,
  CALISTHENICS_FULL_BODY_PLANS,
  DEFAULT_PLANS,
  SBD_STRENGTH_FOLDER,
  SBD_STRENGTH_PLANS,
} from '@/utils/defaultPlans'
import {
  JOEY_CUT_SPLIT_FOLDER,
  JOEY_CUT_SPLIT_PLANS,
  JOEY_SUMMER_LEGACY_PLAN_IDS,
  LEGACY_JOEY_SUMMER_FOLDER_ID,
  LEGACY_JOEY_SUMMER_FOLDER_NAME,
} from '@/utils/joeySummerCutSplitPlans'
import { LIFTBIG_LEGACY_STORAGE_KEY_ALIASES, LIFTBIG_STORAGE_KEYS } from '@/utils/liftbigStorageKeys'
import { loadJsonWithRecovery, saveJson } from '@/utils/storage'

const KEY = LIFTBIG_STORAGE_KEYS.templates

function clonePlans(plans: WorkoutTemplate[]): WorkoutTemplate[] {
  return JSON.parse(JSON.stringify(plans)) as WorkoutTemplate[]
}

function cloneFolders(folders: TemplateFolder[]): TemplateFolder[] {
  return JSON.parse(JSON.stringify(folders)) as TemplateFolder[]
}

type TemplatesState = {
  templates: WorkoutTemplate[]
  folders: TemplateFolder[]
}

function ensureProgramSeeds(state: TemplatesState): TemplatesState {
  const hasFolder = state.folders.some((folder) => folder.id === SBD_STRENGTH_FOLDER.id)
  const withSbdFolder = hasFolder
    ? state.folders.map((folder) =>
        folder.id === SBD_STRENGTH_FOLDER.id
          ? { ...folder, name: SBD_STRENGTH_FOLDER.name, purpose: SBD_STRENGTH_FOLDER.purpose }
          : folder,
      )
    : [...state.folders, ...cloneFolders([SBD_STRENGTH_FOLDER])]
  const hasCalisFolder = withSbdFolder.some((folder) => folder.id === CALISTHENICS_FULL_BODY_FOLDER.id)
  const withCalisFolders = hasCalisFolder
    ? withSbdFolder.map((folder) =>
        folder.id === CALISTHENICS_FULL_BODY_FOLDER.id
          ? {
              ...folder,
              name: CALISTHENICS_FULL_BODY_FOLDER.name,
              purpose: CALISTHENICS_FULL_BODY_FOLDER.purpose,
            }
          : folder,
      )
    : [...withSbdFolder, ...cloneFolders([CALISTHENICS_FULL_BODY_FOLDER])]
  const hasBunsFolder = withCalisFolders.some((folder) => folder.id === BUNS_AND_THIGHS_FOLDER.id)
  const withBunsFolders = hasBunsFolder
    ? withCalisFolders.map((folder) =>
        folder.id === BUNS_AND_THIGHS_FOLDER.id
          ? {
              ...folder,
              name: BUNS_AND_THIGHS_FOLDER.name,
              purpose: BUNS_AND_THIGHS_FOLDER.purpose,
            }
          : folder,
      )
    : [...withCalisFolders, ...cloneFolders([BUNS_AND_THIGHS_FOLDER])]

  const legacyJoeyFolderIds = new Set(
    withBunsFolders
      .filter(
        (f) => f.id === LEGACY_JOEY_SUMMER_FOLDER_ID || f.name === LEGACY_JOEY_SUMMER_FOLDER_NAME,
      )
      .map((f) => f.id),
  )
  let templates = state.templates.map((template) => {
    const legacyJoeyPlan = JOEY_SUMMER_LEGACY_PLAN_IDS.includes(template.id)
    const inLegacyFolder =
      template.folderId != null && legacyJoeyFolderIds.has(template.folderId)
    if (legacyJoeyPlan || inLegacyFolder) {
      return { ...template, folderId: null }
    }
    return template
  })
  let folders = withBunsFolders.filter((f) => !legacyJoeyFolderIds.has(f.id))

  const hasCutSplitFolder = folders.some((folder) => folder.id === JOEY_CUT_SPLIT_FOLDER.id)
  folders = hasCutSplitFolder
    ? folders.map((folder) =>
        folder.id === JOEY_CUT_SPLIT_FOLDER.id
          ? {
              ...folder,
              name: JOEY_CUT_SPLIT_FOLDER.name,
              purpose: JOEY_CUT_SPLIT_FOLDER.purpose,
            }
          : folder,
      )
    : [...folders, ...cloneFolders([JOEY_CUT_SPLIT_FOLDER])]

  const existingIds = new Set(templates.map((template) => template.id))
  const missingSbdPlans = SBD_STRENGTH_PLANS.filter((template) => !existingIds.has(template.id))
  const missingCalisPlans = CALISTHENICS_FULL_BODY_PLANS.filter((template) => !existingIds.has(template.id))
  const missingBunsPlans = BUNS_AND_THIGHS_PLANS.filter((template) => !existingIds.has(template.id))
  const missingCutSplitPlans = JOEY_CUT_SPLIT_PLANS.filter((template) => !existingIds.has(template.id))
  const missingDefaultPlans = DEFAULT_PLANS.filter((template) => !existingIds.has(template.id))
  const missingPlans = [
    ...missingSbdPlans,
    ...missingCalisPlans,
    ...missingBunsPlans,
    ...missingCutSplitPlans,
    ...missingDefaultPlans,
  ]
  templates = missingPlans.length > 0 ? [...templates, ...clonePlans(missingPlans)] : templates

  const seededById = new Map([
    ...BUNS_AND_THIGHS_PLANS.map((plan) => [plan.id, plan] as const),
    ...JOEY_CUT_SPLIT_PLANS.map((plan) => [plan.id, plan] as const),
  ])
  templates = templates.map((template) => {
    const seed = seededById.get(template.id)
    return seed ? (clonePlans([seed])[0] ?? template) : template
  })

  return { templates, folders }
}

function loadTemplatesInitial(): TemplatesState {
  const loaded = loadJsonWithRecovery<unknown>(KEY, null, {
    legacyKeys: LIFTBIG_LEGACY_STORAGE_KEY_ALIASES.templates,
  })

  const seedTemplates = clonePlans(DEFAULT_PLANS)
  const emptyState = ensureProgramSeeds({ templates: seedTemplates, folders: [] })

  if (loaded === null) {
    saveJson(KEY, emptyState)
    return emptyState
  }

  // Backward compatibility: old shape was WorkoutTemplate[].
  if (Array.isArray(loaded)) {
    const merged = ensureProgramSeeds({ templates: loaded as WorkoutTemplate[], folders: [] })
    saveJson(KEY, merged)
    return merged
  }

  if (loaded && typeof loaded === 'object') {
    const obj = loaded as { templates?: unknown; folders?: unknown }
    const templates = Array.isArray(obj.templates) ? (obj.templates as WorkoutTemplate[]) : []
    const folders = Array.isArray(obj.folders) ? (obj.folders as TemplateFolder[]) : []

    if (templates.length > 0) {
      const merged = ensureProgramSeeds({ templates, folders })
      saveJson(KEY, merged)
      return merged
    }
  }

  saveJson(KEY, emptyState)
  return emptyState
}

export function useTemplates() {
  const initial = loadTemplatesInitial()
  const templates = ref<WorkoutTemplate[]>(initial.templates)
  const folders = ref<TemplateFolder[]>(initial.folders)

  function persist() {
    saveJson(KEY, { templates: templates.value, folders: folders.value })
  }

  function setAll(next: WorkoutTemplate[]) {
    templates.value = next
    persist()
  }

  function setFolders(next: TemplateFolder[]) {
    folders.value = next
    persist()
  }

  function assignTemplateFolder(templateId: string, folderId: string | null) {
    templates.value = templates.value.map((t) =>
      t.id === templateId
        ? {
            ...t,
            folderId,
          }
        : t,
    )
    persist()
  }

  return {
    templates,
    folders,
    persist,
    setAll,
    setFolders,
    assignTemplateFolder,
  }
}
