import type { InjectionKey, Ref } from 'vue'
import type { LibraryFavoritesApi } from '@/composables/useLibraryFavorites'
import type { PlanFavoritesApi } from '@/composables/usePlanFavorites'
import type { PickAPlanStateApi } from '@/composables/usePickAPlanState'
import type { SettingsApi } from '@/composables/useSettings'
import type { Exercise, TemplateFolder, WorkoutLog, WorkoutTemplate } from '@/types/workout'

export type LocalWorkoutsApi = {
  log: Ref<WorkoutLog>
  flush: () => void
  getDay: (dateKey: string) => Exercise[]
  getDayNotesForDate: (dateKey: string) => string
  setDay: (dateKey: string, exercises: Exercise[]) => void
  setDayNotes: (dateKey: string, notes: string) => void
  appendExercises: (dateKey: string, exercises: Exercise[]) => void
  deleteDay: (dateKey: string) => void
  isRestDay: (dateKey: string) => boolean
  markRestDay: (dateKey: string) => void
  getPlanName: (dateKey: string) => string | undefined
  getPlanFolderName: (dateKey: string) => string | undefined
  getPlanNotes: (dateKey: string) => string | undefined
  assignPlanToDate: (dateKey: string, template: WorkoutTemplate, folderName?: string) => void
  applyPlanWithWeeklyRest: (
    startDateKey: string,
    template: WorkoutTemplate,
    restDaysPerWeek: number,
    folderName?: string,
  ) => void
  moveDay: (fromKey: string, toKey: string) => void
  swapDays: (keyA: string, keyB: string) => void
  copyExercisesToDay: (fromKey: string, toKey: string) => void
}

export type TemplatesApi = {
  templates: Ref<WorkoutTemplate[]>
  folders: Ref<TemplateFolder[]>
  persist: () => void
  setAll: (next: WorkoutTemplate[]) => void
  setFolders: (next: TemplateFolder[]) => void
  assignTemplateFolder: (templateId: string, folderId: string | null) => void
}

export const workoutsInjectionKey: InjectionKey<LocalWorkoutsApi> = Symbol('workouts')
export const templatesInjectionKey: InjectionKey<TemplatesApi> = Symbol('templates')

export const settingsInjectionKey: InjectionKey<SettingsApi> = Symbol('settings')

export const libraryFavoritesInjectionKey: InjectionKey<LibraryFavoritesApi> =
  Symbol('libraryFavorites')

export const planFavoritesInjectionKey: InjectionKey<PlanFavoritesApi> = Symbol('planFavorites')

export const pickAPlanStateInjectionKey: InjectionKey<PickAPlanStateApi> = Symbol('pickAPlanState')
