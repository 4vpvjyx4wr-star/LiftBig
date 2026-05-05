<script setup lang="ts">
import LibraryBrowser from '@/components/library/LibraryBrowser.vue'
import type { LibraryExercise } from '@/utils/exerciseLibrary'

defineProps<{
  show: boolean
}>()

const emit = defineEmits<{
  close: []
  pick: [exercise: LibraryExercise]
}>()

function onSelect(ex: LibraryExercise) {
  emit('pick', ex)
  emit('close')
}
</script>

<template>
  <Teleport to="body">
    <div
      v-if="show"
      class="fixed inset-0 z-[60] flex items-end justify-center bg-black/65 sm:items-center"
      role="dialog"
      aria-modal="true"
      aria-labelledby="library-picker-title"
      @click.self="emit('close')"
    >
      <div
        class="max-h-[90vh] w-full max-w-lg overflow-y-auto rounded-t-2xl border border-border bg-card p-4 sm:max-h-[85vh] sm:rounded-2xl"
        @click.stop
      >
        <h3 id="library-picker-title" class="text-lg font-extrabold text-foreground">
          Exercise library
        </h3>
        <p class="mt-1 text-xs text-muted">Pick an exercise to add. You can edit sets after.</p>
        <div class="mt-4">
          <LibraryBrowser @select-exercise="onSelect" />
        </div>
        <button
          type="button"
          class="mt-4 w-full rounded-lg border border-border py-3 text-sm font-bold text-muted"
          @click="emit('close')"
        >
          Cancel
        </button>
      </div>
    </div>
  </Teleport>
</template>
