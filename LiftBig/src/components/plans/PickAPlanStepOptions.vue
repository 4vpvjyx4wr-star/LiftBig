<script setup lang="ts" generic="T extends string | number">
import { haptic } from '@/utils/haptics'

export type StepOption<T extends string | number> = {
  value: T
  emoji: string
  title: string
  description: string
}

defineProps<{
  options: StepOption<T>[]
  selected: T | null
}>()

const emit = defineEmits<{
  select: [value: T]
}>()

function onSelect(value: T) {
  haptic('tap')
  emit('select', value)
}
</script>

<template>
  <div class="flex flex-col gap-3">
    <button
      v-for="opt in options"
      :key="String(opt.value)"
      type="button"
      class="flex w-full items-start gap-3 rounded-xl border px-4 py-3 text-left transition-colors"
      :class="
        selected === opt.value
          ? 'border-primary bg-primary/10'
          : 'border-border bg-card-inner hover:border-primary/50'
      "
      @click="onSelect(opt.value)"
    >
      <span class="text-2xl leading-none" aria-hidden="true">{{ opt.emoji }}</span>
      <span class="min-w-0 flex-1">
        <span class="block text-sm font-extrabold text-foreground">{{ opt.title }}</span>
        <span class="mt-0.5 block text-xs leading-snug text-muted">{{ opt.description }}</span>
      </span>
      <i
        v-if="selected === opt.value"
        class="fa-solid fa-check mt-0.5 text-primary"
        aria-hidden="true"
      />
    </button>
  </div>
</template>
