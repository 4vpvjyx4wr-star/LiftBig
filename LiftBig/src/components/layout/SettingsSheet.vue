<script setup lang="ts">
import { ref } from 'vue'
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
  exportBackup: []
  importBackup: [file: File]
}>()

const importInputRef = ref<HTMLInputElement | null>(null)

function triggerImportPick() {
  importInputRef.value?.click()
}

function onImportFileChange(ev: Event) {
  const input = ev.target as HTMLInputElement
  const file = input.files?.[0]
  input.value = ''
  if (!file) return
  emit('importBackup', file)
}
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
          <label class="sr-only" for="liftbig-theme-select">Theme</label>
          <div class="relative">
            <select
              id="liftbig-theme-select"
              class="w-full appearance-none rounded-xl border border-border bg-card-inner py-3 pl-4 pr-10 text-left text-sm font-semibold text-foreground shadow-sm focus:border-primary focus:outline-none focus:ring-2 focus:ring-primary/25"
              :value="theme"
              @change="
                emit('update:theme', ($event.target as HTMLSelectElement).value as ThemeId)
              "
            >
              <option v-for="opt in THEME_OPTIONS" :key="opt.id" :value="opt.id">
                {{ opt.label }}
              </option>
            </select>
            <span
              class="pointer-events-none absolute right-3 top-1/2 -translate-y-1/2 text-muted"
              aria-hidden="true"
            >
              <i class="fa-solid fa-chevron-down text-xs" />
            </span>
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

        <section class="mb-6 border-t border-border pt-5">
          <h3 class="mb-2 text-xs font-bold uppercase tracking-wide text-muted">Backup</h3>
          <p class="mb-3 text-[11px] leading-snug text-muted">
            Your journal is saved in this browser automatically (including after you close it or when the app is
            updated), using storage under <span class="font-mono text-[10px]">liftbig_*</span>. Export saves everything
            in that namespace today—workouts, plans, settings, favorites—and future keys using that prefix are included
            automatically. Import replaces all of it on this device. Clearing site data, private browsing limits, or a
            different browser won’t see the same data—use export if you might switch devices.
          </p>
          <input
            ref="importInputRef"
            type="file"
            accept="application/json,.json"
            class="sr-only"
            aria-hidden="true"
            tabindex="-1"
            @change="onImportFileChange"
          />
          <div class="flex flex-col gap-2">
            <button
              type="button"
              class="w-full rounded-xl border border-border bg-card-inner py-3 text-sm font-bold text-foreground hover:border-primary/50"
              @click="emit('exportBackup')"
            >
              <i class="fa-solid fa-download mr-2" aria-hidden="true" />
              Export backup…
            </button>
            <button
              type="button"
              class="w-full rounded-xl border border-border bg-card-inner py-3 text-sm font-bold text-foreground hover:border-primary/50"
              @click="triggerImportPick"
            >
              <i class="fa-solid fa-upload mr-2" aria-hidden="true" />
              Import backup…
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
