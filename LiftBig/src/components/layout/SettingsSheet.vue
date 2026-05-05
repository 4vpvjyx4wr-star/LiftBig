<script setup lang="ts">
import { THEME_OPTIONS, type ThemeId } from '@/composables/useSettings'
import type { WeightUnit } from '@/utils/units'

defineProps<{
  open: boolean
  theme: ThemeId
  weightUnit: WeightUnit
}>()

const emit = defineEmits<{
  close: []
  'update:theme': [id: ThemeId]
  'update:weightUnit': [u: WeightUnit]
}>()
</script>

<template>
  <Teleport to="body">
    <div
      v-if="open"
      class="fixed inset-0 z-50 flex flex-col justify-end bg-black/65"
      role="dialog"
      aria-modal="true"
      aria-label="Settings"
      @click.self="emit('close')"
    >
      <div
        class="max-h-[85vh] overflow-y-auto rounded-t-2xl border border-border border-b-0 bg-card px-4 pb-10 pt-2"
        @click.stop
      >
        <div class="mx-auto mb-3 h-1 w-10 rounded-full bg-border" />
        <h2 class="text-center text-lg font-extrabold text-foreground">Settings</h2>
        <p class="mb-5 text-center text-xs text-muted">Theme and units apply everywhere in the app.</p>

        <section class="mb-6">
          <h3 class="mb-2 text-xs font-bold uppercase tracking-wide text-muted">Theme</h3>
          <div class="flex flex-col gap-2">
            <button
              v-for="opt in THEME_OPTIONS"
              :key="opt.id"
              type="button"
              class="flex w-full items-center justify-between rounded-xl border px-4 py-3 text-left text-sm font-semibold transition-colors"
              :class="
                theme === opt.id
                  ? 'border-primary bg-card-inner text-foreground'
                  : 'border-border bg-card-inner/60 text-muted hover:border-primary/50'
              "
              @click="emit('update:theme', opt.id)"
            >
              {{ opt.label }}
              <span v-if="theme === opt.id" class="text-primary" aria-hidden="true">✓</span>
            </button>
          </div>
        </section>

        <section class="mb-4">
          <h3 class="mb-2 text-xs font-bold uppercase tracking-wide text-muted">Weight</h3>
          <p class="mb-3 text-[11px] leading-snug text-muted">
            Workouts stay stored in pounds; kg mode converts for display and when you type weights.
          </p>
          <div class="flex rounded-xl border border-border p-1">
            <button
              type="button"
              class="flex-1 rounded-lg py-2.5 text-sm font-bold transition-colors"
              :class="weightUnit === 'lb' ? 'bg-primary text-foreground' : 'text-muted'"
              @click="emit('update:weightUnit', 'lb')"
            >
              lb
            </button>
            <button
              type="button"
              class="flex-1 rounded-lg py-2.5 text-sm font-bold transition-colors"
              :class="weightUnit === 'kg' ? 'bg-primary text-foreground' : 'text-muted'"
              @click="emit('update:weightUnit', 'kg')"
            >
              kg
            </button>
          </div>
        </section>

        <button
          type="button"
          class="mt-2 w-full rounded-xl border border-border py-3 text-sm font-bold text-foreground hover:bg-card-inner"
          @click="emit('close')"
        >
          Done
        </button>
      </div>
    </div>
  </Teleport>
</template>
