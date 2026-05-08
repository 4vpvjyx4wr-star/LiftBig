<script setup lang="ts">
import { getDayExercises, type WorkoutLog } from '@/types/workout'

const props = defineProps<{
  cellKeys: (string | null)[]
  selectedKey: string | null
  todayKey: string
  log: WorkoutLog
  highlightSelection?: boolean
}>()

const emit = defineEmits<{
  pick: [dateKey: string]
}>()

function hasWork(key: string) {
  return getDayExercises(props.log[key]).length > 0
}
</script>

<template>
  <div class="grid grid-cols-7 gap-1">
    <div
      v-for="d in ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT']"
      :key="d"
      class="py-1 text-center text-[10px] font-bold tracking-wider text-muted"
    >
      {{ d }}
    </div>
    <template v-for="(key, idx) in cellKeys" :key="idx">
      <div v-if="key === null" class="aspect-square rounded-lg bg-transparent" />
      <button
        v-else
        type="button"
        class="relative flex aspect-square items-center justify-center rounded-lg border text-sm font-bold transition-colors"
        :class="[
          hasWork(key) ? 'border-border bg-card-inner text-foreground' : 'border-transparent text-muted',
          highlightSelection && selectedKey === key
            ? 'border-primary bg-primary/20 text-primary'
            : '',
          todayKey === key && !(highlightSelection && selectedKey === key)
            ? 'ring-2 ring-[#1d4ed8] ring-offset-2 ring-offset-background'
            : '',
        ]"
        @click="emit('pick', key)"
      >
        {{ Number(key.split('-')[2]) }}
        <span
          v-if="hasWork(key)"
          class="absolute bottom-1 h-1 w-1 rounded-full bg-primary"
          aria-hidden="true"
        />
      </button>
    </template>
  </div>
</template>
