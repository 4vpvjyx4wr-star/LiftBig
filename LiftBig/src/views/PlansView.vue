<script setup lang="ts">
import { computed, inject, ref } from 'vue'
import PlanEditorModal from '@/components/plans/PlanEditorModal.vue'
import { templatesInjectionKey } from '@/composables/injectionKeys'
import type { WorkoutTemplate } from '@/types/workout'

const templates = inject(templatesInjectionKey)!

const planList = computed(() => templates.templates.value)

const modalOpen = ref(false)
const editing = ref<WorkoutTemplate | null>(null)

function openNew() {
  editing.value = null
  modalOpen.value = true
}

function openEdit(t: WorkoutTemplate) {
  editing.value = t
  modalOpen.value = true
}

function closeModal() {
  modalOpen.value = false
}

function onSave(payload: { id: string | null; name: string; exercises: import('@/types/workout').TemplateExercise[] }) {
  const list = planList.value
  let next: WorkoutTemplate[]
  if (payload.id) {
    next = list.map((t) =>
      t.id === payload.id
        ? { ...t, name: payload.name, exercises: payload.exercises }
        : t,
    )
  } else {
    const newT: WorkoutTemplate = {
      id: `${Date.now()}`,
      name: payload.name,
      exercises: payload.exercises,
    }
    next = [...list, newT]
  }
  templates.setAll(next)
  closeModal()
}

function deletePlan(id: string) {
  if (!confirm('Delete this plan?')) return
  templates.setAll(planList.value.filter((t) => t.id !== id))
}
</script>

<template>
  <div>
    <header class="mb-4 border-b border-border pb-3">
      <h1 class="text-3xl font-black tracking-[0.2em] text-primary">LIFTBIG</h1>
      <p class="text-[10px] font-bold tracking-[0.2em] text-muted">Training Journal</p>
    </header>

    <div v-if="planList.length === 0" class="py-12 text-center">
      <p class="text-lg font-bold text-foreground">No plans yet.</p>
      <p class="mt-2 text-sm text-muted">Create a template to reuse across your calendar.</p>
    </div>

    <ul v-else class="space-y-3 pb-24">
      <li
        v-for="item in planList"
        :key="item.id"
        class="rounded-xl border border-border bg-card p-4"
      >
        <div class="flex items-start justify-between gap-2">
          <h3 class="text-lg font-extrabold text-foreground">{{ item.name }}</h3>
          <div class="flex shrink-0 gap-2">
            <button
              type="button"
              class="rounded-lg bg-blue px-3 py-1 text-xs font-bold text-foreground"
              @click="openEdit(item)"
            >
              Edit
            </button>
            <button
              type="button"
              class="rounded-lg border border-red-900/50 px-3 py-1 text-xs font-bold text-red-400"
              @click="deletePlan(item.id)"
            >
              Delete
            </button>
          </div>
        </div>
        <p class="mt-1 text-xs text-muted">
          {{ item.exercises.length }} exercise{{ item.exercises.length !== 1 ? 's' : '' }}
        </p>
        <ul class="mt-2 space-y-1 border-t border-border pt-2">
          <li
            v-for="ex in item.exercises"
            :key="ex.id"
            class="flex flex-wrap gap-2 text-sm text-foreground"
          >
            <span class="text-muted">·</span>
            <span class="font-semibold">{{ ex.name }}</span>
            <span class="text-muted">
              {{ ex.sets.length }} × {{ ex.sets[0]?.targetReps || '?' }}
              <template v-if="ex.sets[0]?.targetWeight"> @ {{ ex.sets[0].targetWeight }}lbs</template>
            </span>
          </li>
        </ul>
      </li>
    </ul>

    <button
      type="button"
      class="fixed bottom-24 left-1/2 z-30 flex -translate-x-1/2 items-center rounded-full bg-primary px-6 py-3 text-sm font-extrabold tracking-wide text-foreground shadow-lg max-sm:left-1/2 max-sm:max-w-[calc(100%-2rem)]"
      @click="openNew"
    >
      + New Plan
    </button>

    <PlanEditorModal
      :show="modalOpen"
      :initial="editing"
      @close="closeModal"
      @save="onSave"
    />
  </div>
</template>
