<script setup lang="ts">
import { computed, inject, ref } from 'vue'
import { RouterLink, RouterView } from 'vue-router'
import SettingsSheet from '@/components/layout/SettingsSheet.vue'
import { settingsInjectionKey, workoutsInjectionKey } from '@/composables/injectionKeys'
import { todayKey } from '@/utils/dateKey'
import {
  applyLiftBigBackupToStorage,
  collectLiftBigBackupPayload,
  downloadLiftBigBackupJson,
  parseLiftBigBackupJson,
} from '@/utils/liftbigBackup'

const liftHref = computed(() => `/workout/${todayKey()}`)
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
</script>

<template>
  <div class="flex min-h-full flex-col bg-background pb-24">
    <Teleport to="body">
      <div
        v-if="menuOpen"
        class="fixed inset-0 z-40 bg-black/50"
        aria-hidden="true"
        @click="closeMenu"
      />
    </Teleport>

    <div
      class="pointer-events-none fixed right-3 z-50 flex w-0 justify-end"
      :style="{ top: 'max(0.75rem, env(safe-area-inset-top, 0px))' }"
    >
      <div class="pointer-events-auto flex flex-col items-end">
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
          class="mt-2 w-[min(100vw-1.5rem,13rem)] rounded-2xl border border-border bg-card-inner py-1 shadow-xl"
          role="menu"
          @click.stop
        >
          <RouterLink
            to="/plates"
            role="menuitem"
            class="flex items-center gap-3 px-4 py-3 text-left text-sm font-bold text-foreground active:bg-card"
            active-class="!text-primary"
            @click="closeMenu"
          >
            <i class="fa-solid fa-weight-hanging w-5 text-center text-base text-muted" aria-hidden="true" />
            Plates
          </RouterLink>
          <RouterLink
            to="/progress"
            role="menuitem"
            class="flex items-center gap-3 px-4 py-3 text-left text-sm font-bold text-foreground active:bg-card"
            active-class="!text-primary"
            @click="closeMenu"
          >
            <i class="fa-solid fa-chart-line w-5 text-center text-base text-muted" aria-hidden="true" />
            Progress
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
    </div>

    <div class="mx-auto w-full max-w-lg flex-1 px-3 pt-14">
      <RouterView />
    </div>

    <nav
      class="fixed bottom-0 left-0 right-0 z-40 border-t border-border bg-card/95 backdrop-blur-sm"
    >
      <div class="relative mx-auto flex max-w-lg items-end justify-between gap-0 px-1 pb-safe pt-2">
        <RouterLink
          to="/"
          class="flex min-w-0 flex-1 flex-col items-center gap-0.5 py-1 text-[9px] font-bold tracking-wide text-muted sm:text-[10px]"
          active-class="!text-primary"
        >
          <i class="fa-solid fa-house text-base sm:text-lg" aria-hidden="true" />
          Home
        </RouterLink>
        <RouterLink
          to="/overview"
          class="flex min-w-0 flex-1 flex-col items-center gap-0.5 py-1 text-[9px] font-bold tracking-wide text-muted sm:text-[10px]"
          active-class="!text-primary"
        >
          <i class="fa-solid fa-calendar-days text-base sm:text-lg" aria-hidden="true" />
          Overview
        </RouterLink>

        <RouterLink
          :to="liftHref"
          class="absolute bottom-6 left-1/2 flex h-14 w-14 -translate-x-1/2 items-center justify-center rounded-full bg-primary text-xs font-black tracking-widest text-foreground shadow-lg ring-4 ring-background"
        >
          LIFT
        </RouterLink>

        <RouterLink
          to="/plans"
          class="flex min-w-0 flex-1 flex-col items-center gap-0.5 py-1 text-[9px] font-bold tracking-wide text-muted sm:text-[10px]"
          active-class="!text-primary"
        >
          <i class="fa-solid fa-clipboard-list text-base sm:text-lg" aria-hidden="true" />
          Plans
        </RouterLink>
        <RouterLink
          to="/library"
          class="flex min-w-0 flex-1 flex-col items-center gap-0.5 py-1 text-[9px] font-bold tracking-wide text-muted sm:text-[10px]"
          active-class="!text-primary"
        >
          <i class="fa-solid fa-book text-base sm:text-lg" aria-hidden="true" />
          Library
        </RouterLink>
      </div>
    </nav>

    <SettingsSheet
      :open="settingsOpen"
      :theme="sheetTheme"
      :weight-unit="sheetWeightUnit"
      @close="settingsOpen = false"
      @update:theme="settings.setTheme"
      @update:weight-unit="settings.setWeightUnit"
      @export-backup="onExportBackup"
      @import-backup="onImportBackup"
    />
  </div>
</template>

<style scoped>
.pb-safe {
  padding-bottom: max(0.5rem, env(safe-area-inset-bottom, 0px));
}
</style>
