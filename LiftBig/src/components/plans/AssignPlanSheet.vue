<script setup lang="ts">
import type { WorkoutTemplate } from '@/types/workout'

defineProps<{
  open: boolean
  templates: WorkoutTemplate[]
}>()

const emit = defineEmits<{
  close: []
  pick: [template: WorkoutTemplate]
}>()
</script>

<template>
  <Teleport to="body">
    <div
      v-if="open"
      class="fixed inset-0 z-50 flex flex-col justify-end bg-black/65"
      role="dialog"
      aria-modal="true"
      @click.self="emit('close')"
    >
      <div
        class="max-h-[70vh] overflow-y-auto rounded-t-2xl border border-border border-b-0 bg-card px-4 pb-8 pt-2"
        @click.stop
      >
        <div class="mx-auto mb-3 h-1 w-10 rounded-full bg-border" />
        <h3 class="text-center text-lg font-extrabold text-foreground">Choose a Plan</h3>
        <p class="mb-4 text-center text-xs text-muted">Exercises will be appended to this day.</p>
        <ul class="space-y-2">
          <li v-for="t in templates" :key="t.id">
            <button
              type="button"
              class="flex w-full items-center justify-between rounded-xl border border-border bg-card-inner px-4 py-3 text-left hover:border-primary"
              @click="emit('pick', t)"
            >
              <div>
                <div class="font-bold text-foreground">{{ t.name }}</div>
                <div class="text-xs text-muted">
                  {{ t.exercises.length }} exercise{{ t.exercises.length !== 1 ? 's' : '' }}
                </div>
              </div>
              <span class="text-xl text-primary">›</span>
            </button>
          </li>
        </ul>
      </div>
    </div>
  </Teleport>
</template>
