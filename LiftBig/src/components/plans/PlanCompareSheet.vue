<script setup lang="ts">
import type { PlanCatalogEntry } from '@/types/planCatalog'

defineProps<{
  open: boolean
  entries: PlanCatalogEntry[]
}>()

const emit = defineEmits<{
  close: []
}>()

function formatDays(e: PlanCatalogEntry): string {
  const d = Array.isArray(e.days) ? e.days : [e.days]
  if (d.length === 1) return `${d[0]}d/wk`
  return `${Math.min(...d)}–${Math.max(...d)}d/wk`
}

function formatDuration(e: PlanCatalogEntry): string {
  const d = Array.isArray(e.duration) ? e.duration : [e.duration]
  const labels: Record<string, string> = { quick: 'Quick', standard: 'Standard', long: 'Long' }
  return d.map((x) => labels[x] ?? x).join(', ')
}
</script>

<template>
  <Teleport to="body">
    <div
      v-if="open && entries.length > 0"
      class="fixed inset-0 z-50 flex flex-col justify-end bg-black/65"
      role="dialog"
      aria-modal="true"
      @click.self="emit('close')"
    >
      <div
        class="max-h-[90vh] overflow-y-auto rounded-t-2xl border border-border border-b-0 bg-card px-4 pb-8 pt-2"
        @click.stop
      >
        <div class="mx-auto mb-3 h-1 w-10 rounded-full bg-border" />
        <h3 class="text-center text-lg font-extrabold text-foreground">Compare plans</h3>

        <div class="mt-4 overflow-x-auto">
          <table class="w-full min-w-[480px] border-collapse text-xs">
            <thead>
              <tr>
                <th class="p-2 text-left font-bold text-muted" />
                <th
                  v-for="entry in entries"
                  :key="entry.id"
                  class="p-2 text-left font-extrabold text-foreground"
                >
                  {{ entry.title }}
                </th>
              </tr>
            </thead>
            <tbody class="text-foreground">
              <tr class="border-t border-border">
                <td class="p-2 font-bold text-muted">Difficulty</td>
                <td v-for="entry in entries" :key="`${entry.id}-diff`" class="p-2">{{ entry.difficulty }}</td>
              </tr>
              <tr class="border-t border-border">
                <td class="p-2 font-bold text-muted">Days</td>
                <td v-for="entry in entries" :key="`${entry.id}-days`" class="p-2">{{ formatDays(entry) }}</td>
              </tr>
              <tr class="border-t border-border">
                <td class="p-2 font-bold text-muted">Duration</td>
                <td v-for="entry in entries" :key="`${entry.id}-dur`" class="p-2">{{ formatDuration(entry) }}</td>
              </tr>
              <tr class="border-t border-border">
                <td class="p-2 font-bold text-muted">Est. time</td>
                <td v-for="entry in entries" :key="`${entry.id}-min`" class="p-2">~{{ entry.estimatedMinutes }} min</td>
              </tr>
              <tr class="border-t border-border">
                <td class="p-2 font-bold text-muted">Equipment</td>
                <td v-for="entry in entries" :key="`${entry.id}-eq`" class="p-2">
                  {{ entry.equipment.length }} options
                </td>
              </tr>
              <tr class="border-t border-border">
                <td class="p-2 font-bold text-muted">Progression</td>
                <td v-for="entry in entries" :key="`${entry.id}-prog`" class="p-2">{{ entry.progressionStyle }}</td>
              </tr>
              <tr class="border-t border-border">
                <td class="p-2 font-bold text-muted">Schedule</td>
                <td v-for="entry in entries" :key="`${entry.id}-sched`" class="p-2">
                  {{ entry.scheduleMode === 'folder' ? 'Rotating split' : 'Weekly repeat' }}
                </td>
              </tr>
              <tr class="border-t border-border">
                <td class="p-2 font-bold text-muted">Goal tag</td>
                <td v-for="entry in entries" :key="`${entry.id}-tag`" class="p-2">{{ entry.goalTag }}</td>
              </tr>
            </tbody>
          </table>
        </div>

        <button
          type="button"
          class="mt-6 w-full rounded-lg border border-border py-3 text-sm font-bold text-foreground"
          @click="emit('close')"
        >
          Close
        </button>
      </div>
    </div>
  </Teleport>
</template>
