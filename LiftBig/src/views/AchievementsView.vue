<script setup lang="ts">
import { computed, inject, ref, watch } from 'vue'
import { workoutsInjectionKey } from '@/composables/injectionKeys'
import {
  ACHIEVEMENTS,
  computeUnlockedAchievements,
  loadCelebratedAchievementIds,
  markAchievementCelebrated,
  type AchievementId,
} from '@/utils/achievements'
import { haptic } from '@/utils/haptics'

const workouts = inject(workoutsInjectionKey)!

const unlocked = computed(() => computeUnlockedAchievements(workouts.log.value))
const celebrated = ref(loadCelebratedAchievementIds())

watch(
  unlocked,
  (ids) => {
    for (const id of ids) {
      if (!celebrated.value.has(id)) {
        haptic('celebrate')
        markAchievementCelebrated(id)
        celebrated.value = loadCelebratedAchievementIds()
      }
    }
  },
  { immediate: true },
)

function isUnlocked(id: AchievementId): boolean {
  return unlocked.value.has(id)
}

const unlockedCount = computed(() => unlocked.value.size)
</script>

<template>
  <div class="pb-6">
    <h1 class="mb-1 text-2xl font-black tracking-tight text-foreground">Achievements</h1>
    <p class="mb-5 text-sm leading-relaxed text-muted">
      Milestones from your training journal. {{ unlockedCount }} of {{ ACHIEVEMENTS.length }} unlocked.
    </p>

    <ul class="space-y-2">
      <li
        v-for="item in ACHIEVEMENTS"
        :key="item.id"
        class="flex items-start gap-3 rounded-xl border px-4 py-3"
        :class="
          isUnlocked(item.id)
            ? 'border-primary/40 bg-primary/10'
            : 'border-border bg-card-inner opacity-80'
        "
      >
        <div
          class="flex h-10 w-10 shrink-0 items-center justify-center rounded-lg"
          :class="isUnlocked(item.id) ? 'bg-primary/20 text-primary' : 'bg-card text-muted'"
        >
          <i
            class="fa-solid text-lg"
            :class="isUnlocked(item.id) ? item.icon : 'fa-lock'"
            aria-hidden="true"
          />
        </div>
        <div class="min-w-0 flex-1">
          <div class="flex items-center gap-2">
            <h2 class="font-extrabold text-foreground">{{ item.title }}</h2>
            <i
              v-if="isUnlocked(item.id)"
              class="fa-solid fa-circle-check text-xs text-primary"
              aria-label="Unlocked"
            />
          </div>
          <p class="mt-0.5 text-xs leading-snug text-muted">{{ item.description }}</p>
        </div>
      </li>
    </ul>
  </div>
</template>
