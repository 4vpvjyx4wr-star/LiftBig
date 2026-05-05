<script setup lang="ts">
import { computed } from 'vue'
import { RouterLink, RouterView } from 'vue-router'
import { todayKey } from '@/utils/dateKey'

const liftHref = computed(() => `/workout/${todayKey()}`)
</script>

<template>
  <div class="flex min-h-full flex-col bg-background pb-24">
    <div class="mx-auto w-full max-w-lg flex-1 px-3 pt-3">
      <RouterView />
    </div>

    <nav
      class="fixed bottom-0 left-0 right-0 z-40 border-t border-border bg-card/95 backdrop-blur-sm"
    >
      <div class="relative mx-auto flex max-w-lg items-end justify-around px-1 pb-safe pt-2">
        <RouterLink
          to="/"
          class="flex flex-col items-center gap-0.5 px-2 py-1 text-[10px] font-bold tracking-wide text-muted"
          active-class="!text-primary"
        >
          <i class="fa-solid fa-house text-lg" aria-hidden="true" />
          Home
        </RouterLink>
        <RouterLink
          to="/overview"
          class="flex flex-col items-center gap-0.5 px-2 py-1 text-[10px] font-bold tracking-wide text-muted"
          active-class="!text-primary"
        >
          <i class="fa-solid fa-calendar-days text-lg" aria-hidden="true" />
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
          class="flex flex-col items-center gap-0.5 px-2 py-1 text-[10px] font-bold tracking-wide text-muted"
          active-class="!text-primary"
        >
          <i class="fa-solid fa-clipboard-list text-lg" aria-hidden="true" />
          Plans
        </RouterLink>
        <RouterLink
          to="/plates"
          class="flex flex-col items-center gap-0.5 px-2 py-1 text-[10px] font-bold tracking-wide text-muted"
          active-class="!text-primary"
        >
          <i class="fa-solid fa-weight-hanging text-lg" aria-hidden="true" />
          Plates
        </RouterLink>
      </div>
    </nav>
  </div>
</template>

<style scoped>
.pb-safe {
  padding-bottom: max(0.5rem, env(safe-area-inset-bottom, 0px));
}
</style>
