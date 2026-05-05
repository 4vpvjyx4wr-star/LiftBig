import type { InjectionKey, Ref } from 'vue'
import type { Exercise, WorkoutLog, WorkoutTemplate } from '@/types/workout'

export type LocalWorkoutsApi = {
  log: Ref<WorkoutLog>
  flush: () => void
  getDay: (dateKey: string) => Exercise[]
  setDay: (dateKey: string, exercises: Exercise[]) => void
  appendExercises: (dateKey: string, exercises: Exercise[]) => void
  deleteDay: (dateKey: string) => void
}

export type TemplatesApi = {
  templates: Ref<WorkoutTemplate[]>
  persist: () => void
  setAll: (next: WorkoutTemplate[]) => void
}

export const workoutsInjectionKey: InjectionKey<LocalWorkoutsApi> = Symbol('workouts')
export const templatesInjectionKey: InjectionKey<TemplatesApi> = Symbol('templates')
