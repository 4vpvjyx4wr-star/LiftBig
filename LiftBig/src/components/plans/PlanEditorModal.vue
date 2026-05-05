<script setup lang="ts">
import { watch, ref } from 'vue'
import type { TemplateExercise, WorkoutTemplate } from '@/types/workout'

const props = defineProps<{
  show: boolean
  initial: WorkoutTemplate | null
}>()

const emit = defineEmits<{
  close: []
  save: [payload: { id: string | null; name: string; exercises: TemplateExercise[] }]
}>()

const planName = ref('')
const exercises = ref<TemplateExercise[]>([])

function blankExercise(): TemplateExercise {
  return {
    id: `new-ex-${Date.now()}-${Math.random().toString(36).slice(2, 9)}`,
    name: '',
    sets: [{ targetReps: '', targetWeight: '' }],
  }
}

function resetFromProps() {
  if (props.initial) {
    planName.value = props.initial.name
    exercises.value = JSON.parse(JSON.stringify(props.initial.exercises)) as TemplateExercise[]
  } else {
    planName.value = ''
    exercises.value = [blankExercise()]
  }
}

watch(
  () => props.show,
  (v) => {
    if (v) resetFromProps()
  },
)

function updateExercise(index: number, updated: TemplateExercise) {
  exercises.value = exercises.value.map((e, i) => (i === index ? updated : e))
}

function addSet(exIndex: number) {
  const ex = exercises.value[exIndex]
  if (!ex) return
  updateExercise(exIndex, {
    ...ex,
    sets: [...ex.sets, { targetReps: '', targetWeight: '' }],
  })
}

function removeSet(exIndex: number, setIndex: number) {
  const ex = exercises.value[exIndex]
  if (!ex || ex.sets.length <= 1) return
  updateExercise(exIndex, {
    ...ex,
    sets: ex.sets.filter((_, i) => i !== setIndex),
  })
}

function addExercise() {
  exercises.value = [...exercises.value, blankExercise()]
}

function removeExercise(index: number) {
  exercises.value = exercises.value.filter((_, i) => i !== index)
}

function save() {
  const name = planName.value.trim()
  if (!name) {
    window.alert('Please give your plan a name.')
    return
  }
  const named = exercises.value.filter((e) => e.name.trim().length > 0)
  if (named.length === 0) {
    window.alert('Add at least one exercise with a name.')
    return
  }
  emit('save', {
    id: props.initial?.id ?? null,
    name,
    exercises: named,
  })
}
</script>

<template>
  <Teleport to="body">
    <div
      v-if="show"
      class="fixed inset-0 z-50 flex items-end justify-center bg-black/65 sm:items-center"
      @click.self="emit('close')"
    >
      <div
        class="max-h-[90vh] w-full max-w-lg overflow-y-auto rounded-t-2xl border border-border bg-card p-4 sm:max-h-[85vh] sm:rounded-2xl"
        @click.stop
      >
        <h3 class="text-lg font-extrabold text-foreground">
          {{ initial ? 'Edit Plan' : 'New Plan' }}
        </h3>
        <label class="mt-3 block text-xs font-bold uppercase tracking-wide text-muted">Plan name</label>
        <input
          v-model="planName"
          type="text"
          class="mt-1 w-full rounded-lg border border-border bg-card-inner px-3 py-2 text-foreground outline-none focus:border-primary"
          placeholder="e.g. Push Day"
        />

        <div class="mt-4 space-y-3">
          <div
            v-for="(ex, ei) in exercises"
            :key="ex.id"
            class="rounded-xl border border-border bg-card-inner p-3"
          >
            <div class="mb-2 flex items-center justify-between">
              <span class="text-xs font-bold text-muted">Exercise {{ ei + 1 }}</span>
              <button
                type="button"
                class="text-xs font-semibold text-red-400"
                @click="removeExercise(ei)"
              >
                Remove
              </button>
            </div>
            <input
              v-model="ex.name"
              type="text"
              class="mb-2 w-full rounded-lg border border-border bg-background px-3 py-2 text-sm text-foreground"
              placeholder="Exercise name"
            />
            <div class="grid grid-cols-[2fr_1fr_1fr_28px] gap-1 text-[10px] font-bold uppercase text-muted">
              <span>Set</span>
              <span class="text-center">Reps</span>
              <span class="text-center">lbs</span>
              <span />
            </div>
            <div
              v-for="(set, si) in ex.sets"
              :key="si"
              class="mt-1 grid grid-cols-[2fr_1fr_1fr_28px] gap-1"
            >
              <span class="flex items-center text-xs text-muted">{{ si + 1 }}</span>
              <input
                v-model="set.targetReps"
                type="text"
                inputmode="numeric"
                class="rounded border border-border bg-background px-1 py-1 text-center text-sm text-foreground"
              />
              <input
                v-model="set.targetWeight"
                type="text"
                inputmode="numeric"
                class="rounded border border-border bg-background px-1 py-1 text-center text-sm text-foreground"
              />
              <button
                type="button"
                class="text-muted"
                :disabled="ex.sets.length <= 1"
                @click="removeSet(ei, si)"
              >
                ✕
              </button>
            </div>
            <button
              type="button"
              class="mt-2 text-xs font-bold text-primary"
              @click="addSet(ei)"
            >
              + Add Set
            </button>
          </div>
        </div>

        <button
          type="button"
          class="mt-3 w-full rounded-lg border border-border py-2 text-sm font-bold text-foreground"
          @click="addExercise"
        >
          + Add exercise
        </button>

        <div class="mt-4 flex gap-2">
          <button
            type="button"
            class="flex-1 rounded-lg bg-primary py-3 text-sm font-extrabold text-foreground"
            @click="save"
          >
            Save
          </button>
          <button
            type="button"
            class="flex-1 rounded-lg border border-border py-3 text-sm font-bold text-muted"
            @click="emit('close')"
          >
            Cancel
          </button>
        </div>
      </div>
    </div>
  </Teleport>
</template>
