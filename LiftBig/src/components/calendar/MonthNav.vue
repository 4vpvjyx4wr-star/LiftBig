<script setup lang="ts">
defineProps<{
  label: string
}>()

const emit = defineEmits<{
  prev: []
  next: []
}>()
</script>

<template>
  <div class="mb-3 flex items-center justify-between rounded-xl border border-border bg-card px-2 py-2">
    <button
      type="button"
      class="flex h-10 w-10 items-center justify-center rounded-lg text-2xl text-primary hover:bg-card-inner"
      aria-label="Previous month"
      @click="emit('prev')"
    >
      ‹
    </button>
    <h2 class="text-sm font-extrabold tracking-wide text-foreground">{{ label }}</h2>
    <button
      type="button"
      class="flex h-10 w-10 items-center justify-center rounded-lg text-2xl text-primary hover:bg-card-inner"
      aria-label="Next month"
      @click="emit('next')"
    >
      ›
    </button>
  </div>
</template>
