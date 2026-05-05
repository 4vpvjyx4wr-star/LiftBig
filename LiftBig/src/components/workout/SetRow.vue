<script setup lang="ts">
import type { SetLog } from '@/types/workout'

defineProps<{
  set: SetLog
  index: number
  targetReps?: string
}>()

const emit = defineEmits<{
  update: [field: 'reps' | 'weight', value: string]
  delete: []
}>()
</script>

<template>
  <div class="mb-2 flex items-center gap-2">
    <div class="flex w-16 flex-col items-center">
      <span class="text-[11px] font-semibold text-muted">Set {{ index + 1 }}</span>
      <span v-if="targetReps" class="mt-0.5 text-[9px] font-bold text-primary">{{ targetReps }}</span>
    </div>
    <input
      :value="set.reps"
      type="text"
      inputmode="numeric"
      class="flex-1 rounded-lg border border-border bg-card-inner px-2 py-1.5 text-center text-[15px] text-foreground outline-none focus:border-primary"
      placeholder="Reps"
      @input="emit('update', 'reps', ($event.target as HTMLInputElement).value)"
    />
    <input
      :value="set.weight"
      type="text"
      inputmode="decimal"
      class="flex-1 rounded-lg border border-border bg-card-inner px-2 py-1.5 text-center text-[15px] text-foreground outline-none focus:border-primary"
      placeholder="lbs"
      @input="emit('update', 'weight', ($event.target as HTMLInputElement).value)"
    />
    <button type="button" class="w-8 py-1 text-center text-sm text-muted" @click="emit('delete')">
      ✕
    </button>
  </div>
</template>
