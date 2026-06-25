import { computed, inject, ref, type Ref } from 'vue'
import { libraryFavoritesInjectionKey } from '@/composables/injectionKeys'
import {
  INLINE_LIBRARY_SUGGEST_LIMIT,
  inlineLibrarySuggestMatches,
} from '@/utils/exerciseLibrary'

/** Pair with `ExerciseNameSuggestList` for any typed exercise-name field. */
export function useExerciseNameSuggest(
  query: Ref<string>,
  limit = INLINE_LIBRARY_SUGGEST_LIMIT,
) {
  const favorites = inject(libraryFavoritesInjectionKey)!
  const show = ref(false)

  const matches = computed(() =>
    inlineLibrarySuggestMatches(query.value, favorites.favoriteIds.value, limit),
  )

  function onFocus() {
    show.value = true
  }

  function hideSoon() {
    window.setTimeout(() => {
      show.value = false
    }, 120)
  }

  function dismiss() {
    show.value = false
  }

  return { show, matches, onFocus, hideSoon, dismiss }
}
