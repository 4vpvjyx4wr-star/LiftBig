<script setup lang="ts">
import { computed, inject, ref } from 'vue'
import { RouterLink, RouterView, useRoute } from 'vue-router'
import SettingsSheet from '@/components/layout/SettingsSheet.vue'
import RestTimer from '@/components/workout/RestTimer.vue'
import { settingsInjectionKey, workoutsInjectionKey } from '@/composables/injectionKeys'
import { todayKey } from '@/utils/dateKey'
import {
  applyLiftBigBackupToStorage,
  collectLiftBigBackupPayload,
  downloadLiftBigBackupJson,
  parseLiftBigBackupJson,
} from '@/utils/liftbigBackup'

const route = useRoute()
const liftHref = computed(() => `/workout/${todayKey()}`)
const showTrainingJournalTagline = computed(() => route.name === 'home')
const settings = inject(settingsInjectionKey)!
const workouts = inject(workoutsInjectionKey)!
const settingsOpen = ref(false)
const menuOpen = ref(false)

function closeMenu() {
  menuOpen.value = false
}

function openSettingsFromMenu() {
  settingsOpen.value = true
  menuOpen.value = false
}

function onExportBackup() {
  workouts.flush()
  downloadLiftBigBackupJson(collectLiftBigBackupPayload())
}

async function onImportBackup(file: File) {
  let text: string
  try {
    text = await file.text()
  } catch {
    window.alert('Could not read that file.')
    return
  }

  const parsed = parseLiftBigBackupJson(text)
  if (!parsed.ok) {
    window.alert(parsed.error)
    return
  }

  const ok = window.confirm(
    'Replace all LiftBig data on this device with this backup?\n\nCurrent workouts, plans, and settings will be overwritten.',
  )
  if (!ok) return

  workouts.flush()
  applyLiftBigBackupToStorage(parsed.data)
  settingsOpen.value = false
  window.location.reload()
}
const sheetTheme = computed(() => settings.theme.value)
const sheetWeightUnit = computed(() => settings.weightUnit.value)
const sheetAverageRestSeconds = computed(() => settings.averageRestSeconds.value)
const sheetAverageLiftSeconds = computed(() => settings.averageLiftSeconds.value)
</script>

<template>
  <div class="flex min-h-full flex-col bg-background pb-above-bottom-tabs">
    <RestTimer :show-launcher="false" :show-floating="true" />

    <Teleport to="body">
      <div
        v-if="menuOpen"
        class="fixed inset-0 z-40 bg-black/50"
        aria-hidden="true"
        @click="closeMenu"
      />
    </Teleport>

    <div class="mx-auto flex w-full max-w-lg flex-1 flex-col px-3">
      <header
        class="sticky top-0 z-50 flex shrink-0 items-center justify-between gap-3 border-b border-border bg-background/95 py-3 backdrop-blur-sm supports-[backdrop-filter]:bg-background/80"
        :style="{ paddingTop: 'max(0.75rem, env(safe-area-inset-top, 0px))' }"
      >
        <div class="min-w-0 flex-1">
          <h1 class="truncate text-2xl font-black tracking-[0.2em] text-primary sm:text-3xl">
            LIFTBIG
          </h1>
          <p
            v-if="showTrainingJournalTagline"
            class="mt-0.5 text-xs font-bold tracking-[0.2em] text-muted"
          >
            Training Journal
          </p>
        </div>
        <div class="relative shrink-0">
          <button
            type="button"
            class="flex h-11 w-11 items-center justify-center rounded-xl border border-border bg-card text-foreground shadow-sm outline-none focus-visible:ring-2 focus-visible:ring-primary"
            :aria-expanded="menuOpen"
            aria-controls="app-shell-menu"
            aria-label="Open menu"
            @click="menuOpen = !menuOpen"
          >
            <i class="fa-solid fa-bars text-lg" aria-hidden="true" />
          </button>
          <div
            v-if="menuOpen"
            id="app-shell-menu"
            class="absolute right-0 top-[calc(100%+0.5rem)] z-[60] w-[min(calc(100vw-1.5rem),13rem)] rounded-2xl border border-border bg-card-inner py-1 shadow-xl"
            role="menu"
            @click.stop
          >
            <RouterLink
              v-slot="{ navigate, isActive }"
              to="/plates"
              custom
            >
              <button
                type="button"
                role="menuitem"
                class="flex w-full items-center gap-3 px-4 py-3 text-left text-sm font-bold text-foreground active:bg-card"
                :class="{ '!text-primary': isActive }"
                @click="closeMenu(); navigate($event)"
              >
                <i class="fa-solid fa-weight-hanging w-5 text-center text-base text-muted" aria-hidden="true" />
                Plates
              </button>
            </RouterLink>
            <RouterLink
              v-slot="{ navigate, isActive }"
              to="/one-rep-max"
              custom
            >
              <button
                type="button"
                role="menuitem"
                class="flex w-full items-center gap-3 px-4 py-3 text-left text-sm font-bold text-foreground active:bg-card"
                :class="{ '!text-primary': isActive }"
                @click="closeMenu(); navigate($event)"
              >
                <i class="fa-solid fa-calculator w-5 text-center text-base text-muted" aria-hidden="true" />
                1RM
              </button>
            </RouterLink>
            <button
              type="button"
              role="menuitem"
              class="flex w-full items-center gap-3 px-4 py-3 text-left text-sm font-bold text-foreground active:bg-card"
              @click="openSettingsFromMenu"
            >
              <i class="fa-solid fa-gear w-5 text-center text-base text-muted" aria-hidden="true" />
              Settings
            </button>
          </div>
        </div>
      </header>

      <div class="min-h-0 flex-1 pb-1 pt-3">
        <RouterView />
      </div>
    </div>

    <!-- Teleport keeps fixed positioning tied to the viewport (no ancestor stacking quirks). -->
    <Teleport to="body">
      <nav
        id="app-bottom-tabs"
        class="fixed inset-x-0 bottom-0 z-40 w-full touch-manipulation border-t border-border bg-card/95 backdrop-blur-sm select-none [transform:translateZ(0)] [-webkit-transform:translateZ(0)] [-webkit-touch-callout:none]"
      >
        <div
          class="relative mx-auto flex max-w-lg items-end gap-0 px-1 pb-bottom-nav-safe pt-2.5"
        >
        <RouterLink v-slot="{ navigate, isExactActive }" to="/" custom>
          <button
            type="button"
            class="flex min-w-0 flex-1 flex-col items-center gap-0.5 py-1 text-[9px] font-bold tracking-wide text-muted sm:text-[10px]"
            :class="{ '!text-primary': isExactActive }"
            :aria-current="isExactActive ? 'page' : undefined"
            @click="navigate($event)"
          >
            <i class="fa-solid fa-house text-base sm:text-lg" aria-hidden="true" />
            Home
          </button>
        </RouterLink>
        <RouterLink v-slot="{ navigate, isActive }" to="/progress" custom>
          <button
            type="button"
            class="flex min-w-0 flex-1 flex-col items-center gap-0.5 py-1 text-[9px] font-bold tracking-wide text-muted sm:text-[10px]"
            :class="{ '!text-primary': isActive }"
            :aria-current="isActive ? 'page' : undefined"
            @click="navigate($event)"
          >
            <i class="fa-solid fa-chart-line text-base sm:text-lg" aria-hidden="true" />
            Progress
          </button>
        </RouterLink>

        <!-- Fixed w-14 column: LIFT lives here so the bar layout treats it like a fifth “tab” slot -->
        <div class="pointer-events-none relative z-10 w-14 shrink-0 self-stretch">
          <RouterLink v-slot="{ navigate, isActive }" :to="liftHref" custom>
            <button
              type="button"
              class="pointer-events-auto absolute bottom-6 left-1/2 flex h-14 w-14 -translate-x-1/2 items-center justify-center rounded-full bg-primary text-xs font-black tracking-widest text-foreground shadow-lg ring-4 ring-background outline-none focus-visible:ring-2 focus-visible:ring-primary focus-visible:ring-offset-2 focus-visible:ring-offset-background"
              :aria-current="isActive ? 'page' : undefined"
              aria-label="Open workout log"
              @click="navigate($event)"
            >
              LIFT
            </button>
          </RouterLink>
        </div>

        <RouterLink v-slot="{ navigate, isActive }" to="/plans" custom>
          <button
            type="button"
            class="flex min-w-0 flex-1 flex-col items-center gap-0.5 py-1 text-[9px] font-bold tracking-wide text-muted sm:text-[10px]"
            :class="{ '!text-primary': isActive }"
            :aria-current="isActive ? 'page' : undefined"
            @click="navigate($event)"
          >
            <i class="fa-solid fa-clipboard-list text-base sm:text-lg" aria-hidden="true" />
            Plans
          </button>
        </RouterLink>
        <RouterLink v-slot="{ navigate, isActive }" to="/library" custom>
          <button
            type="button"
            class="flex min-w-0 flex-1 flex-col items-center gap-0.5 py-1 text-[9px] font-bold tracking-wide text-muted sm:text-[10px]"
            :class="{ '!text-primary': isActive }"
            :aria-current="isActive ? 'page' : undefined"
            @click="navigate($event)"
          >
            <i class="fa-solid fa-book text-base sm:text-lg" aria-hidden="true" />
            Library
          </button>
        </RouterLink>
        </div>
      </nav>
    </Teleport>

    <SettingsSheet
      :open="settingsOpen"
      :theme="sheetTheme"
      :weight-unit="sheetWeightUnit"
      :average-rest-seconds="sheetAverageRestSeconds"
      :average-lift-seconds="sheetAverageLiftSeconds"
      @close="settingsOpen = false"
      @update:theme="settings.setTheme"
      @update:weight-unit="settings.setWeightUnit"
      @update:average-rest-seconds="settings.setAverageRestSeconds"
      @update:average-lift-seconds="settings.setAverageLiftSeconds"
      @export-backup="onExportBackup"
      @import-backup="onImportBackup"
    />
  </div>
</template>
