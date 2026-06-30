<script setup lang="ts">
export type StatTile = {
  key: string
  label: string
  value: string
  hint?: string
  delta?: string
  deltaPositive?: boolean | null
}

defineProps<{
  tiles: StatTile[]
  columns?: 2 | 3 | 4 | 5
}>()

function deltaClass(positive: boolean | null | undefined): string {
  if (positive === true) return 'text-success-text'
  if (positive === false) return 'text-muted'
  return 'text-muted'
}

const colClass: Record<number, string> = {
  2: 'grid-cols-2',
  3: 'grid-cols-2 sm:grid-cols-3',
  4: 'grid-cols-2 sm:grid-cols-4',
  5: 'grid-cols-2 sm:grid-cols-3 lg:grid-cols-5',
}
</script>

<template>
  <div class="grid gap-2" :class="colClass[columns ?? 4]">
    <div
      v-for="tile in tiles"
      :key="tile.key"
      class="rounded-xl border border-border bg-card px-3 py-3 text-center"
    >
      <div class="text-[10px] font-bold uppercase text-muted">{{ tile.label }}</div>
      <div
        class="mt-1 font-black leading-tight text-foreground"
        :class="tile.value.length > 8 ? 'text-sm' : 'text-lg'"
      >
        {{ tile.value }}
      </div>
      <div v-if="tile.hint" class="mt-0.5 truncate text-[10px] font-semibold text-primary">
        {{ tile.hint }}
      </div>
      <div
        v-if="tile.delta"
        class="mt-0.5 text-[10px] font-bold"
        :class="deltaClass(tile.deltaPositive)"
      >
        {{ tile.delta }}
      </div>
    </div>
  </div>
</template>
