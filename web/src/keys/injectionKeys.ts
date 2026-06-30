import type { InjectionKey, Ref } from 'vue';
import type { WorkoutLog } from '../utils/libraryExerciseTracking';

export type WeightUnit = 'lb' | 'kg';

export type SettingsContext = {
  weightUnit: Ref<WeightUnit>;
  equipmentFilterPrefs: Ref<string[]>;
  toggleEquipmentFilter: (equipment: string) => void;
  clearEquipmentFilters: () => void;
};

export type LibraryFavoritesContext = {
  isFavorite: (id: string) => boolean;
  toggle: (id: string) => void;
};

export type WorkoutLogContext = {
  log: Ref<WorkoutLog>;
};

/** Production: Symbol('workouts') */
export const WORKOUT_LOG_KEY: InjectionKey<WorkoutLogContext> = Symbol('workouts');

/** Production: Symbol('settings') */
export const SETTINGS_KEY: InjectionKey<SettingsContext> = Symbol('settings');

/** Production: Symbol('libraryFavorites') */
export const LIBRARY_FAVORITES_KEY: InjectionKey<LibraryFavoritesContext> =
  Symbol('libraryFavorites');
