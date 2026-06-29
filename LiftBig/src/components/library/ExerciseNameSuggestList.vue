<script setup lang="ts">
import { computed } from 'vue'
import type { LibraryExercise } from '@/utils/exerciseLibrary'

const props = withDefaults(
  defineProps<{
    show: boolean
    matches: LibraryExercise[]
    placement?: 'above' | 'below'
  }>(),
  {
    placement: 'above',
  },
)

const emit = defineEmits<{
  pick: [exercise: LibraryExercise]
}>()

let touchStartY = 0

const placementClass = computed(() =>
  props.placement === 'below' ? 'top-full mt-0.5' : 'bottom-full mb-1',
)

function onTouchStart(e: TouchEvent) {
  touchStartY = e.touches[0]?.clientY ?? 0
}

function onTouchMove(e: TouchEvent) {
  const el = e.currentTarget as HTMLElement | null
  if (!el || e.touches.length === 0) return
  const y = e.touches[0]!.clientY
  const delta = y - touchStartY
  touchStartY = y
  if (el.scrollHeight <= el.clientHeight) {
    e.preventDefault()
    return
  }
  const atTop = el.scrollTop <= 0
  const atBottom = el.scrollTop + el.clientHeight >= el.scrollHeight - 1
  if ((atTop && delta > 0) || (atBottom && delta < 0)) {
    e.preventDefault()
  }
}
</script>

<template>
  <div
    v-if="show && matches.length > 0"
    class="inline-suggest-scroll absolute left-0 right-0 z-20 rounded-lg border border-border bg-card p-1 shadow-lg"
    :class="placementClass"
    @mousedown.prevent
    @touchstart.passive="onTouchStart"
    @touchmove="onTouchMove"
    @wheel.stop
  >
    <button
      v-for="match in matches"
      :key="match.id"
      type="button"
      class="block w-full rounded-md px-3 py-2 text-left text-sm text-foreground hover:bg-card-inner"
      @mousedown.prevent
      @click.prevent="emit('pick', match)"
    >
      <span class="font-semibold">{{ match.name }}</span>
      <span class="ml-2 text-xs text-muted">{{ match.equipment ?? 'Exercise' }}</span>
    </button>
  </div>
</template>
