import { ref } from 'vue'
import type { TemplateFolder, WorkoutTemplate } from '@/types/workout'
import {
  CALISTHENICS_FULL_BODY_FOLDER,
  CALISTHENICS_FULL_BODY_PLANS,
  DEFAULT_PLANS,
  JOEY_SUMMER_FOLDER,
  JOEY_SUMMER_PLAN_IDS,
  SBD_STRENGTH_FOLDER,
  SBD_STRENGTH_PLANS,
} from '@/utils/defaultPlans'
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
  const hasJoeyFolder = withCalisFolders.some((folder) => folder.id === JOEY_SUMMER_FOLDER.id)
  let folders = hasJoeyFolder
    ? withCalisFolders.map((folder) =>
        folder.id === JOEY_SUMMER_FOLDER.id
          ? { ...folder, name: JOEY_SUMMER_FOLDER.name, purpose: JOEY_SUMMER_FOLDER.purpose }
          : folder,
      )
    : [...withCalisFolders, ...cloneFolders([JOEY_SUMMER_FOLDER])]

  const joeyPlanIdSet = new Set(JOEY_SUMMER_PLAN_IDS)
  let templates = state.templates.map((template) =>
    joeyPlanIdSet.has(template.id) && template.folderId == null
      ? { ...template, folderId: JOEY_SUMMER_FOLDER.id }
      : template,
  )

  // Deduplicate: some older saved states can contain multiple "Joey's Summer PPL/Core/Circuit"
  // folders (same name, different ids). Remap all Joey plans to the canonical folder id.
  const joeyFolderIdsByName = folders.filter((f) => f.name === JOEY_SUMMER_FOLDER.name).map((f) => f.id)
  const duplicateJoeyFolderIds = joeyFolderIdsByName.filter((id) => id !== JOEY_SUMMER_FOLDER.id)
  if (duplicateJoeyFolderIds.length > 0) {
    templates = templates.map((t) =>
      joeyPlanIdSet.has(t.id) && t.folderId != null && duplicateJoeyFolderIds.includes(t.folderId)
        ? { ...t, folderId: JOEY_SUMMER_FOLDER.id }
        : t,
    )
    folders = folders.filter((f) => !duplicateJoeyFolderIds.includes(f.id))
  }

  const existingIds = new Set(templates.map((template) => template.id))
  const missingSbdPlans = SBD_STRENGTH_PLANS.filter((template) => !existingIds.has(template.id))
  const missingCalisPlans = CALISTHENICS_FULL_BODY_PLANS.filter((template) => !existingIds.has(template.id))
  const missingDefaultPlans = DEFAULT_PLANS.filter((template) => !existingIds.has(template.id))
  const missingPlans = [...missingSbdPlans, ...missingCalisPlans, ...missingDefaultPlans]
  templates = missingPlans.length > 0 ? [...templates, ...clonePlans(missingPlans)] : templates

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
