import { ref } from 'vue'
import type { TemplateFolder, WorkoutTemplate } from '@/types/workout'
import {
  CALISTHENICS_FULL_BODY_FOLDER,
  CALISTHENICS_FULL_BODY_PLANS,
  DEFAULT_PLANS,
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

const FOLDER_PURPOSE_DEFAULTS: Record<string, string> = {
  "Joey's Summer PPL/Core/Circuit":
    'My summer plan to build upper chest/delts/lats for my #hotgirlsummer',
}

function applyFolderPurposeDefaults(folders: TemplateFolder[]): TemplateFolder[] {
  return folders.map((folder) => {
    const defaultPurpose = FOLDER_PURPOSE_DEFAULTS[folder.name]
    if (!defaultPurpose) return folder
    return { ...folder, purpose: defaultPurpose }
  })
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
  const seededFolders = hasCalisFolder
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
  const folders = applyFolderPurposeDefaults(seededFolders)

  const existingIds = new Set(state.templates.map((template) => template.id))
  const missingSbdPlans = SBD_STRENGTH_PLANS.filter((template) => !existingIds.has(template.id))
  const missingCalisPlans = CALISTHENICS_FULL_BODY_PLANS.filter((template) => !existingIds.has(template.id))
  const missingPlans = [...missingSbdPlans, ...missingCalisPlans]
  const templates =
    missingPlans.length > 0 ? [...state.templates, ...clonePlans(missingPlans)] : state.templates

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
    return ensureProgramSeeds({ templates: loaded as WorkoutTemplate[], folders: [] })
  }

  if (loaded && typeof loaded === 'object') {
    const obj = loaded as { templates?: unknown; folders?: unknown }
    const templates = Array.isArray(obj.templates) ? (obj.templates as WorkoutTemplate[]) : []
    const folders = Array.isArray(obj.folders) ? (obj.folders as TemplateFolder[]) : []

    if (templates.length > 0) return ensureProgramSeeds({ templates, folders })
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
