<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import {
  clonePalette,
  DEFAULT_THEME_PALETTE,
  normalizeHexColor,
  paletteCssVariables,
  randomHexColor,
  randomThemePalette,
  THEME_PALETTE_FIELDS,
  type CustomTheme,
  type ThemePalette,
  type ThemePaletteKey,
} from '@/utils/themePalette'

const props = defineProps<{
  open: boolean
  editing: CustomTheme | null
}>()

const emit = defineEmits<{
  cancel: []
  save: [payload: { name: string; colors: ThemePalette }]
  delete: []
}>()

const nameDraft = ref('')
const colorsDraft = ref<ThemePalette>(clonePalette(DEFAULT_THEME_PALETTE))
const hexDrafts = ref<Record<ThemePaletteKey, string>>({} as Record<ThemePaletteKey, string>)

function syncHexDraftsFromColors() {
  const next = {} as Record<ThemePaletteKey, string>
  for (const field of THEME_PALETTE_FIELDS) {
    next[field.key] = colorsDraft.value[field.key]
  }
  hexDrafts.value = next
}

function resetDrafts() {
  if (props.editing) {
    nameDraft.value = props.editing.name
    colorsDraft.value = clonePalette(props.editing.colors)
  } else {
    nameDraft.value = 'My theme'
    colorsDraft.value = clonePalette(DEFAULT_THEME_PALETTE)
  }
  syncHexDraftsFromColors()
}

watch(
  () => [props.open, props.editing] as const,
  ([open]) => {
    if (open) resetDrafts()
  },
  { immediate: true },
)

const swatchStyle = computed(() => paletteCssVariables(colorsDraft.value))

function setPaletteColor(key: ThemePaletteKey, value: string) {
  colorsDraft.value = { ...colorsDraft.value, [key]: value }
  hexDrafts.value = { ...hexDrafts.value, [key]: value }
}

function randomizeAllColors() {
  colorsDraft.value = randomThemePalette()
  syncHexDraftsFromColors()
}

function randomizeColor(key: ThemePaletteKey) {
  setPaletteColor(key, randomHexColor())
}

function onColorPicker(key: ThemePaletteKey, ev: Event) {
  setPaletteColor(key, (ev.target as HTMLInputElement).value)
}

function onHexInput(key: ThemePaletteKey, ev: Event) {
  const raw = (ev.target as HTMLInputElement).value
  hexDrafts.value = { ...hexDrafts.value, [key]: raw }
}

function onHexBlur(key: ThemePaletteKey) {
  const normalized = normalizeHexColor(hexDrafts.value[key] ?? '')
  if (!normalized) {
    hexDrafts.value = { ...hexDrafts.value, [key]: colorsDraft.value[key] }
    return
  }
  setPaletteColor(key, normalized)
}

function submit() {
  const trimmed = nameDraft.value.trim()
  if (!trimmed) return
  emit('save', { name: trimmed, colors: clonePalette(colorsDraft.value) })
}
</script>

<template>
  <div
    v-if="open"
    class="mt-3 rounded-xl border border-border bg-card-inner p-3"
    data-theme="custom"
    :style="swatchStyle"
  >
    <div class="mb-3 flex items-start justify-between gap-2">
      <div class="min-w-0 flex-1">
        <h4 class="text-xs font-bold uppercase tracking-wide text-muted">
          {{ editing ? 'Edit custom theme' : 'New custom theme' }}
        </h4>
        <p class="mt-1 text-[11px] leading-snug text-muted">
          Pick each color with the wheel or type a hex code. Changes preview live below.
        </p>
      </div>
      <button
        type="button"
        class="shrink-0 rounded-lg px-2 py-1 text-xs font-bold text-muted hover:bg-card"
        aria-label="Close editor"
        @click="emit('cancel')"
      >
        <i class="fa-solid fa-xmark" aria-hidden="true" />
      </button>
    </div>

    <button
      type="button"
      class="mb-3 w-full rounded-xl border border-border bg-card py-2.5 text-sm font-bold text-foreground transition-colors hover:border-primary/50"
      @click="randomizeAllColors"
    >
      <i class="fa-solid fa-shuffle mr-2" aria-hidden="true" />
      Randomize all colors
    </button>

    <label class="mb-3 block text-[11px] font-semibold text-muted">
      Theme name
      <input
        v-model="nameDraft"
        type="text"
        maxlength="48"
        class="mt-1 w-full rounded-lg border border-border bg-card px-3 py-2 text-sm font-bold text-foreground outline-none focus:border-primary"
        placeholder="My theme"
      />
    </label>

    <div
      class="mb-3 flex items-center gap-3 rounded-lg border border-border bg-card px-3 py-2"
      aria-hidden="true"
    >
      <span class="theme-swatch-preview h-12 w-12 shrink-0 rounded-lg" />
      <span class="text-xs font-semibold text-muted">Live preview</span>
    </div>

    <div class="max-h-52 space-y-2 overflow-y-auto pr-1 [-ms-overflow-style:none] [scrollbar-width:none] [&::-webkit-scrollbar]:hidden">
      <div
        v-for="field in THEME_PALETTE_FIELDS"
        :key="field.key"
        class="grid grid-cols-[auto_1fr] items-center gap-2 rounded-lg border border-border/60 bg-card px-2 py-1.5"
      >
        <div class="flex shrink-0 flex-col items-center gap-1">
          <input
            :id="`custom-theme-color-${field.key}`"
            type="color"
            class="h-9 w-9 cursor-pointer rounded-md border border-border bg-transparent p-0.5"
            :value="colorsDraft[field.key]"
            :aria-label="`${field.label} color picker`"
            @input="onColorPicker(field.key, $event)"
          />
          <button
            type="button"
            class="rounded-md border border-border px-1.5 py-0.5 text-[10px] font-bold text-muted hover:border-primary/50 hover:text-foreground"
            :aria-label="`Random ${field.label} color`"
            @click="randomizeColor(field.key)"
          >
            <i class="fa-solid fa-dice mr-0.5" aria-hidden="true" />
            Random
          </button>
        </div>
        <div class="min-w-0">
          <label class="text-[11px] font-bold text-foreground" :for="`custom-theme-color-${field.key}`">
            {{ field.label }}
          </label>
          <p v-if="field.hint" class="text-[10px] text-muted">{{ field.hint }}</p>
          <input
            type="text"
            class="mt-1 w-full rounded-md border border-border bg-card-inner px-2 py-1 font-mono text-[11px] text-foreground outline-none focus:border-primary"
            :value="hexDrafts[field.key]"
            spellcheck="false"
            autocapitalize="off"
            placeholder="#000000"
            @input="onHexInput(field.key, $event)"
            @blur="onHexBlur(field.key)"
          />
        </div>
      </div>
    </div>

    <div class="mt-3 flex flex-col gap-2">
      <button
        type="button"
        class="w-full rounded-xl bg-primary py-2.5 text-sm font-bold text-foreground"
        @click="submit"
      >
        {{ editing ? 'Save changes' : 'Save custom theme' }}
      </button>
      <button
        v-if="editing"
        type="button"
        class="w-full rounded-xl border border-border py-2.5 text-sm font-bold text-foreground hover:border-primary/50"
        @click="emit('delete')"
      >
        Delete theme
      </button>
      <button
        type="button"
        class="w-full rounded-xl border border-border py-2.5 text-sm font-bold text-muted hover:text-foreground"
        @click="emit('cancel')"
      >
        Cancel
      </button>
    </div>
  </div>
</template>
