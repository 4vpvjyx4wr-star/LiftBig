import { type Ref, ref, watch } from 'vue'
import { LIFTBIG_LEGACY_STORAGE_KEY_ALIASES, LIFTBIG_STORAGE_KEYS } from '@/utils/liftbigStorageKeys'
import { loadJsonWithRecovery, saveJson } from '@/utils/storage'

const KEY = LIFTBIG_STORAGE_KEYS.libraryFavorites

function normalizeIds(raw: unknown): string[] {
  if (!Array.isArray(raw)) return []
  return raw.filter((x): x is string => typeof x === 'string' && x.length > 0)
}

export function useLibraryFavorites() {
  const favoriteIds = ref<string[]>(
    normalizeIds(
      loadJsonWithRecovery<unknown>(KEY, [], {
        legacyKeys: LIFTBIG_LEGACY_STORAGE_KEY_ALIASES.libraryFavorites,
      }),
    ),
  )

  function toggle(id: string) {
    const set = new Set(favoriteIds.value)
    if (set.has(id)) set.delete(id)
    else set.add(id)
    favoriteIds.value = [...set].sort()
  }

  function isFavorite(id: string): boolean {
    return favoriteIds.value.includes(id)
  }

  watch(
    favoriteIds,
    () => {
      saveJson(KEY, favoriteIds.value)
    },
    { deep: true },
  )

  return {
    favoriteIds: favoriteIds as Ref<string[]>,
    toggle,
    isFavorite,
  }
}

export type LibraryFavoritesApi = {
  favoriteIds: Ref<string[]>
  toggle: (id: string) => void
  isFavorite: (id: string) => boolean
}
