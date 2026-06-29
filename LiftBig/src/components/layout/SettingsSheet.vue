<script setup lang="ts">
import { computed, inject, nextTick, ref, watch } from 'vue'
import CustomThemeEditor from '@/components/layout/CustomThemeEditor.vue'
import { settingsInjectionKey, workoutsInjectionKey } from '@/composables/injectionKeys'
import { THEME_OPTIONS } from '@/composables/useSettings'
import { customThemeRef, isCustomThemeRef, paletteCssVariables, type CustomTheme, type ThemePalette } from '@/utils/themePalette'
import { displayInputToStoredLbsString, parseStoredLbs, storedLbsStringToDisplay } from '@/utils/units'
import {
  getNotificationPermission,
  requestNotificationPermission as requestTimerNotifications,
} from '@/utils/notifications'
import {
  findDuplicateExerciseGroups,
  mergeExerciseNameVariants,
} from '@/utils/exerciseDuplicates'
import type { DistanceUnit } from '@/utils/distances'
import type { WeightUnit } from '@/utils/units'

const props = defineProps<{
  open: boolean
  theme: string
  weightUnit: WeightUnit
  distanceUnit: DistanceUnit
  averageRestSeconds: number
  averageLiftSeconds: number
  bodyWeightLbs: number
}>()

const emit = defineEmits<{
  close: []
  'update:theme': [id: string]
  'update:weightUnit': [u: WeightUnit]
  'update:distanceUnit': [u: DistanceUnit]
  'update:averageRestSeconds': [seconds: number]
  'update:averageLiftSeconds': [seconds: number]
  'update:bodyWeightLbs': [lbs: number]
  exportBackup: []
  importBackup: [file: File]
}>()

const settings = inject(settingsInjectionKey)!
const workouts = inject(workoutsInjectionKey)!

const duplicateGroups = computed(() => findDuplicateExerciseGroups(workouts.log.value))

function mergeDuplicateGroup(key: string, variants: string[]) {
  const canonical = variants.slice().sort((a, b) => a.localeCompare(b))[0]
  if (!canonical) return
  const ok = window.confirm(
    `Merge these names into "${canonical}"?\n\n${variants.join('\n')}\n\nAll history will use the canonical name.`,
  )
  if (!ok) return
  const next = mergeExerciseNameVariants(workouts.log.value, key, canonical)
  workouts.log.value = next
  workouts.flush()
}

function syncBodyWeightDraftFromProp() {
  bodyWeightDraft.value =
    props.bodyWeightLbs > 0
      ? storedLbsStringToDisplay(String(props.bodyWeightLbs), props.weightUnit)
      : ''
}

function commitBodyWeight() {
  const stored = displayInputToStoredLbsString(bodyWeightDraft.value, props.weightUnit)
  if (!stored.trim()) {
    emit('update:bodyWeightLbs', 0)
    return
  }
  const lbs = parseStoredLbs(stored)
  emit('update:bodyWeightLbs', Number.isFinite(lbs) ? lbs : 0)
}

const bodyWeightDraft = ref('')

const importInputRef = ref<HTMLInputElement | null>(null)
const notificationPermission = ref<'unsupported' | NotificationPermission>(
  getNotificationPermission(),
)

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

function refreshNotificationPermission() {
  notificationPermission.value = getNotificationPermission()
}

async function requestNotificationPermission() {
  notificationPermission.value = await requestTimerNotifications()
}

const permissionLabel = computed(() => {
  switch (notificationPermission.value) {
    case 'granted':
      return 'Allowed'
    case 'denied':
      return 'Blocked'
    case 'default':
      return 'Not enabled'
    default:
      return 'Not supported in this browser'
  }
})

watch(
  () => props.open,
  (open, wasOpen) => {
    refreshNotificationPermission()
    if (open) {
      syncBodyWeightDraftFromProp()
      scrollActiveThemeIntoView()
    } else if (wasOpen) {
      commitBodyWeight()
    }
  },
  { immediate: true },
)

watch(
  () => props.weightUnit,
  () => {
    if (!props.open) return
    commitBodyWeight()
    syncBodyWeightDraftFromProp()
  },
)

function pickRandomTheme() {
  const presetCandidates = THEME_OPTIONS.filter((o) => o.id !== props.theme)
  const customCandidates = settings.customThemes.value
    .map((t) => ({ id: customThemeRef(t.id), label: t.name }))
    .filter((o) => o.id !== props.theme)
  const pool = [...presetCandidates, ...customCandidates]
  if (pool.length === 0) {
    emit('update:theme', THEME_OPTIONS[0]!.id)
    return
  }
  const pick = pool[Math.floor(Math.random() * pool.length)]!
  emit('update:theme', pick.id)
}

const customThemes = computed(() => settings.customThemes.value)

const activeThemeLabel = computed(() => {
  if (isCustomThemeRef(props.theme)) {
    const id = props.theme.slice('custom:'.length)
    return customThemes.value.find((t) => t.id === id)?.name ?? 'Custom theme'
  }
  return THEME_OPTIONS.find((o) => o.id === props.theme)?.label ?? 'LiftBig (orange)'
})

const themeButtonRefs = ref<Record<string, HTMLButtonElement>>({})

function setThemeButtonRef(id: string, el: Element | null) {
  if (el instanceof HTMLButtonElement) {
    themeButtonRefs.value[id] = el
  } else {
    delete themeButtonRefs.value[id]
  }
}

function customSwatchStyle(theme: CustomTheme) {
  return paletteCssVariables(theme.colors)
}

const customEditorOpen = ref(false)
const editingCustomTheme = ref<CustomTheme | null>(null)

function openCreateCustomTheme() {
  editingCustomTheme.value = null
  customEditorOpen.value = true
}

function openEditCustomTheme(theme: CustomTheme) {
  editingCustomTheme.value = theme
  customEditorOpen.value = true
}

function closeCustomEditor() {
  customEditorOpen.value = false
  editingCustomTheme.value = null
}

function confirmDeleteCustomTheme(theme: CustomTheme): boolean {
  return window.confirm(
    `Delete "${theme.name}"?\n\nThis custom theme will be permanently removed from this device.`,
  )
}

function requestDeleteCustomTheme(theme: CustomTheme) {
  if (!confirmDeleteCustomTheme(theme)) return
  if (editingCustomTheme.value?.id === theme.id) {
    closeCustomEditor()
  }
  settings.deleteCustomTheme(theme.id)
}

function onSaveCustomTheme(payload: { name: string; colors: ThemePalette }) {
  if (editingCustomTheme.value) {
    settings.updateCustomTheme(editingCustomTheme.value.id, payload.name, payload.colors)
  } else {
    settings.addCustomTheme(payload.name, payload.colors)
  }
  closeCustomEditor()
}

function onDeleteCustomTheme() {
  if (!editingCustomTheme.value) return
  requestDeleteCustomTheme(editingCustomTheme.value)
}

function scrollActiveThemeIntoView() {
  nextTick(() => {
    themeButtonRefs.value[props.theme]?.scrollIntoView({ block: 'nearest' })
  })
}

watch(
  () => props.theme,
  () => {
    if (props.open) scrollActiveThemeIntoView()
  },
)
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

        <section class="mb-4 rounded-2xl border border-border bg-card-inner p-4">
          <div class="mb-2 flex items-center justify-between gap-2">
            <h3 class="text-[11px] font-extrabold uppercase tracking-wider text-foreground/80">Theme</h3>
            <span class="truncate text-[11px] font-semibold text-primary">{{ activeThemeLabel }}</span>
          </div>
          <div class="relative">
            <div
              class="theme-picker-scroll max-h-56 overflow-y-auto rounded-xl border border-border bg-card-inner p-2 [-ms-overflow-style:none] [scrollbar-width:none] [&::-webkit-scrollbar]:hidden"
              role="listbox"
              aria-label="Theme"
            >
              <div class="grid grid-cols-2 gap-1.5">
                <button
                  v-for="opt in THEME_OPTIONS"
                  :key="opt.id"
                  :ref="(el) => setThemeButtonRef(opt.id, el as Element | null)"
                  type="button"
                  role="option"
                  :aria-selected="theme === opt.id"
                  class="group flex items-center gap-2 rounded-lg border px-2 py-2 text-left transition-colors"
                  :class="
                    theme === opt.id
                      ? 'border-primary bg-primary/10 shadow-[inset_0_0_0_1px_color-mix(in_srgb,var(--color-primary)_35%,transparent)]'
                      : 'border-transparent hover:border-border hover:bg-card'
                  "
                  :data-theme="opt.id"
                  @click="emit('update:theme', opt.id)"
                >
                  <span
                    class="theme-swatch-preview h-9 w-9 shrink-0 rounded-lg"
                    aria-hidden="true"
                  />
                  <span class="min-w-0 flex-1">
                    <span
                      class="block truncate text-xs font-bold leading-tight"
                      :class="theme === opt.id ? 'text-foreground' : 'text-foreground/90'"
                    >
                      {{ opt.label }}
                    </span>
                  </span>
                  <i
                    v-if="theme === opt.id"
                    class="fa-solid fa-circle-check shrink-0 text-xs text-primary"
                    aria-hidden="true"
                  />
                </button>
              </div>
            </div>
            <div
              class="pointer-events-none absolute inset-x-0 bottom-0 h-8 rounded-b-xl bg-gradient-to-t from-card-inner to-transparent"
              aria-hidden="true"
            />
          </div>
          <button
            type="button"
            class="mt-2 w-full rounded-xl border border-border bg-card-inner py-3 text-sm font-bold text-foreground transition-colors hover:border-primary/50"
            @click="pickRandomTheme"
          >
            <i class="fa-solid fa-shuffle mr-2" aria-hidden="true" />
            Random theme
          </button>

          <div class="mt-4">
            <div class="mb-2 flex items-center justify-between gap-2">
              <h3 class="text-[11px] font-extrabold uppercase tracking-wider text-foreground/80">Custom themes</h3>
              <span v-if="customThemes.length > 0" class="text-[11px] font-semibold text-muted">
                {{ customThemes.length }}
              </span>
            </div>
            <div
              v-if="customThemes.length > 0"
              class="relative mb-2"
            >
              <div
                class="max-h-40 overflow-y-auto rounded-xl border border-border bg-card-inner p-2 [-ms-overflow-style:none] [scrollbar-width:none] [&::-webkit-scrollbar]:hidden"
                role="listbox"
                aria-label="Custom themes"
              >
                <div class="grid grid-cols-2 gap-1.5">
                  <div
                    v-for="custom in customThemes"
                    :key="custom.id"
                    class="flex items-center gap-1 rounded-lg border px-1 py-1 transition-colors"
                    :class="
                      theme === customThemeRef(custom.id)
                        ? 'border-primary bg-primary/10 shadow-[inset_0_0_0_1px_color-mix(in_srgb,var(--color-primary)_35%,transparent)]'
                        : 'border-transparent hover:border-border hover:bg-card'
                    "
                    data-theme="custom"
                    :style="customSwatchStyle(custom)"
                  >
                    <button
                      :ref="(el) => setThemeButtonRef(customThemeRef(custom.id), el as Element | null)"
                      type="button"
                      role="option"
                      :aria-selected="theme === customThemeRef(custom.id)"
                      class="flex min-w-0 flex-1 items-center gap-2 rounded-md px-1 py-1 text-left"
                      @click="emit('update:theme', customThemeRef(custom.id))"
                    >
                      <span
                        class="theme-swatch-preview h-9 w-9 shrink-0 rounded-lg"
                        aria-hidden="true"
                      />
                      <span class="min-w-0 flex-1">
                        <span
                          class="block truncate text-xs font-bold leading-tight"
                          :class="theme === customThemeRef(custom.id) ? 'text-foreground' : 'text-foreground/90'"
                        >
                          {{ custom.name }}
                        </span>
                      </span>
                      <i
                        v-if="theme === customThemeRef(custom.id)"
                        class="fa-solid fa-circle-check shrink-0 text-xs text-primary"
                        aria-hidden="true"
                      />
                    </button>
                    <button
                      type="button"
                      class="shrink-0 rounded-md p-1.5 text-muted hover:bg-card hover:text-foreground"
                      aria-label="Edit custom theme"
                      @click="openEditCustomTheme(custom)"
                    >
                      <i class="fa-solid fa-pen text-[10px]" aria-hidden="true" />
                    </button>
                    <button
                      type="button"
                      class="shrink-0 rounded-md p-1.5 text-muted hover:bg-card hover:text-primary"
                      aria-label="Delete custom theme"
                      @click="requestDeleteCustomTheme(custom)"
                    >
                      <i class="fa-solid fa-trash text-[10px]" aria-hidden="true" />
                    </button>
                  </div>
                </div>
              </div>
            </div>
            <p
              v-else
              class="mb-2 rounded-xl border border-dashed border-border bg-card-inner px-3 py-4 text-center text-[11px] leading-snug text-muted"
            >
              No custom themes yet. Build your own palette below.
            </p>
            <button
              type="button"
              class="w-full rounded-xl border border-border bg-card-inner py-3 text-sm font-bold text-foreground transition-colors hover:border-primary/50"
              @click="openCreateCustomTheme"
            >
              <i class="fa-solid fa-plus mr-2" aria-hidden="true" />
              Create custom theme
            </button>
            <CustomThemeEditor
              :open="customEditorOpen"
              :editing="editingCustomTheme"
              @cancel="closeCustomEditor"
              @save="onSaveCustomTheme"
              @delete="onDeleteCustomTheme"
            />
          </div>
        </section>

        <section class="mb-4 rounded-2xl border border-border bg-card-inner p-4">
          <h3 class="mb-1 text-[11px] font-extrabold uppercase tracking-wider text-foreground/80">Weight</h3>
          <p class="mb-3 text-[11px] leading-snug text-muted">
            Workouts stay stored in pounds; kg mode converts for display and when you type weights.
          </p>
          <div class="flex rounded-xl border border-border bg-card p-1">
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
          <div class="mt-4 border-t border-border/70 pt-4">
            <h4 class="mb-1 text-[11px] font-extrabold uppercase tracking-wider text-foreground/80">Distance</h4>
            <p class="mb-3 text-[11px] leading-snug text-muted">
              Used for optional distance on cardio like walking, running, and cycling.
            </p>
            <div class="flex rounded-xl border border-border bg-card p-1">
              <button
                type="button"
                class="flex-1 rounded-lg py-2.5 text-sm font-bold transition-colors"
                :class="distanceUnit === 'mi' ? 'bg-primary text-foreground' : 'text-muted'"
                @click="emit('update:distanceUnit', 'mi')"
              >
                mi
              </button>
              <button
                type="button"
                class="flex-1 rounded-lg py-2.5 text-sm font-bold transition-colors"
                :class="distanceUnit === 'km' ? 'bg-primary text-foreground' : 'text-muted'"
                @click="emit('update:distanceUnit', 'km')"
              >
                km
              </button>
            </div>
          </div>
        </section>

        <section class="mb-4 rounded-2xl border border-border bg-card-inner p-4">
          <h3 class="mb-1 text-[11px] font-extrabold uppercase tracking-wider text-foreground/80">Body weight</h3>
          <p class="mb-3 text-[11px] leading-snug text-muted">
            Used for calorie estimates during workouts.
          </p>
          <label class="block text-[11px] font-semibold text-muted">
            Body weight
            <input
              v-model="bodyWeightDraft"
              type="text"
              inputmode="decimal"
              data-touch-input
              class="mt-1 w-full rounded-lg border border-border bg-card px-3 py-2 text-sm text-foreground outline-none focus:border-primary"
              :placeholder="weightUnit === 'lb' ? 'e.g. 180 lb' : 'e.g. 82 kg'"
              @blur="commitBodyWeight(); syncBodyWeightDraftFromProp()"
            />
          </label>
        </section>

        <section class="mb-4 rounded-2xl border border-border bg-card-inner p-4">
          <h3 class="mb-1 text-[11px] font-extrabold uppercase tracking-wider text-foreground/80">Workout time estimates</h3>
          <p class="mb-3 text-[11px] leading-snug text-muted">
            These values are used for plan duration estimates, calorie estimates, and workout shuffle target duration matching.
          </p>
          <div class="grid grid-cols-2 gap-2">
            <label class="text-[11px] font-semibold text-muted">
              Average rest time (sec)
              <input
                type="number"
                min="5"
                max="600"
                step="5"
                class="mt-1 w-full rounded-lg border border-border bg-card px-3 py-2 text-sm text-foreground outline-none focus:border-primary"
                :value="averageRestSeconds"
                @change="
                  emit(
                    'update:averageRestSeconds',
                    Number(($event.target as HTMLInputElement).value) || 60,
                  )
                "
              />
            </label>
            <label class="text-[11px] font-semibold text-muted">
              Average lift time (sec)
              <input
                type="number"
                min="5"
                max="600"
                step="5"
                class="mt-1 w-full rounded-lg border border-border bg-card px-3 py-2 text-sm text-foreground outline-none focus:border-primary"
                :value="averageLiftSeconds"
                @change="
                  emit(
                    'update:averageLiftSeconds',
                    Number(($event.target as HTMLInputElement).value) || 60,
                  )
                "
              />
            </label>
          </div>
        </section>

        <section class="mb-4 rounded-2xl border border-border bg-card-inner p-4">
          <h3 class="mb-1 text-[11px] font-extrabold uppercase tracking-wider text-foreground/80">Daily lift reminder</h3>
          <p class="mb-3 text-[11px] leading-snug text-muted">
            Gentle nudge on Home when it's past your chosen time and you haven't logged today. Uses a system
            notification when allowed; otherwise an in-app banner.
          </p>
          <label class="mb-3 flex items-center justify-between gap-3">
            <span class="text-sm font-bold text-foreground">Enable daily nudge</span>
            <input
              type="checkbox"
              class="h-5 w-5 rounded border-border"
              :checked="settings.dailyLiftReminderEnabled.value"
              @change="settings.setDailyLiftReminderEnabled(($event.target as HTMLInputElement).checked)"
            />
          </label>
          <label class="block text-[11px] font-semibold text-muted">
            Reminder time
            <input
              type="time"
              class="mt-1 w-full rounded-lg border border-border bg-card px-3 py-2 text-sm text-foreground outline-none focus:border-primary"
              :value="settings.dailyLiftReminderTime.value"
              :disabled="!settings.dailyLiftReminderEnabled.value"
              @change="settings.setDailyLiftReminderTime(($event.target as HTMLInputElement).value)"
            />
          </label>
        </section>

        <section class="mb-4 rounded-2xl border border-border bg-card-inner p-4">
          <h3 class="mb-1 text-[11px] font-extrabold uppercase tracking-wider text-foreground/80">Workout logging</h3>
          <label class="mb-3 flex items-center justify-between gap-3">
            <span class="text-sm font-bold text-foreground">Double-tap reps or weight to copy previous set</span>
            <input
              type="checkbox"
              class="h-5 w-5 rounded border-border"
              :checked="settings.doubleTapCopyWeight.value"
              @change="settings.setDoubleTapCopyWeight(($event.target as HTMLInputElement).checked)"
            />
          </label>
          <label class="flex items-center justify-between gap-3">
            <span class="text-sm font-bold text-foreground">Auto-advance to next set's weight after reps</span>
            <input
              type="checkbox"
              class="h-5 w-5 rounded border-border"
              :checked="settings.autoAdvanceRepsToWeight.value"
              @change="settings.setAutoAdvanceRepsToWeight(($event.target as HTMLInputElement).checked)"
            />
          </label>
        </section>

        <section class="mb-4 rounded-2xl border border-border bg-card-inner p-4">
          <h3 class="mb-1 text-[11px] font-extrabold uppercase tracking-wider text-foreground/80">Controls &amp; tips</h3>
          <ul class="space-y-2 text-[11px] leading-snug text-muted">
            <li>
              <span class="font-bold text-foreground">Double-tap reps or weight</span> — copies the previous set's
              reps or weight (toggle above).
            </li>
            <li>
              <span class="font-bold text-foreground">Hold exercise name</span> in the workout log, then drag to
              reorder exercises.
            </li>
            <li>
              <span class="font-bold text-foreground">Hold exercise name</span> on Home's day preview to reorder that
              day's plan.
            </li>
          </ul>
        </section>

        <section class="mb-4 rounded-2xl border border-border bg-card-inner p-4">
          <h3 class="mb-1 text-[11px] font-extrabold uppercase tracking-wider text-foreground/80">Timer sound</h3>
          <p class="mb-3 text-[11px] leading-snug text-muted">
            Short beep when the rest timer completes (in addition to haptic and notifications).
          </p>
          <label class="flex items-center justify-between gap-3">
            <span class="text-sm font-bold text-foreground">Play sound when timer ends</span>
            <input
              type="checkbox"
              class="h-5 w-5 rounded border-border"
              :checked="settings.timerSoundEnabled.value"
              @change="settings.setTimerSoundEnabled(($event.target as HTMLInputElement).checked)"
            />
          </label>
        </section>

        <section class="mb-4 rounded-2xl border border-border bg-card-inner p-4">
          <h3 class="mb-1 text-[11px] font-extrabold uppercase tracking-wider text-foreground/80">Data health</h3>
          <p class="mb-3 text-[11px] leading-snug text-muted">
            Exercises logged with different capitalization or spacing are grouped below. Merge only when they're the
            same lift.
          </p>
          <p v-if="duplicateGroups.length === 0" class="text-xs text-muted">No duplicate exercise names found.</p>
          <ul v-else class="space-y-2">
            <li
              v-for="group in duplicateGroups"
              :key="group.key"
              class="rounded-lg border border-border bg-card px-3 py-2"
            >
              <p class="text-xs font-bold text-foreground">{{ group.variants.join(' · ') }}</p>
              <button
                type="button"
                class="mt-2 text-xs font-bold text-primary hover:text-foreground"
                @click="mergeDuplicateGroup(group.key, group.variants)"
              >
                Merge to canonical name
              </button>
            </li>
          </ul>
        </section>

        <section class="mb-4 rounded-2xl border border-border bg-card-inner p-4">
          <h3 class="mb-1 text-[11px] font-extrabold uppercase tracking-wider text-foreground/80">Timer notifications</h3>
          <p class="mb-2 text-[11px] leading-snug text-muted">
            Get a system alert when your rest timer ends: <span class="font-semibold">{{ permissionLabel }}</span>.
          </p>
          <button
            v-if="notificationPermission === 'default'"
            type="button"
            class="w-full rounded-xl border border-border bg-card-inner py-3 text-sm font-bold text-foreground hover:border-primary/50"
            @click="requestNotificationPermission"
          >
            Enable timer notifications
          </button>
          <p v-else-if="notificationPermission === 'denied'" class="text-[11px] leading-snug text-muted">
            Notifications are blocked. Enable them in your browser/site settings to get timer alerts.
          </p>
        </section>

        <section class="mb-4 rounded-2xl border border-border bg-card-inner p-4">
          <h3 class="mb-1 text-[11px] font-extrabold uppercase tracking-wider text-foreground/80">Backup</h3>
          <p class="mb-3 text-[11px] leading-snug text-muted">
            Your journal is saved in this browser automatically (including after you close it or when the app is
            updated), using storage under <span class="font-mono text-[10px]">liftbig_*</span>. Export saves everything
            in that namespace today—workouts, plans, settings, custom themes, favorites—and future keys using that prefix are included
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
