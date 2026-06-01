import { inject, provide, ref, type InjectionKey, type Ref } from 'vue'

type WorkoutSetLoggingFocusApi = {
  enter: () => void
  leave: (delayMs?: number) => void
}

const workoutSetLoggingFocusKey: InjectionKey<WorkoutSetLoggingFocusApi> = Symbol(
  'workoutSetLoggingFocus',
)

function isWorkoutSetInputFocused(): boolean {
  const el = document.activeElement
  return el instanceof HTMLElement && el.matches('[data-workout-set-input]')
}

/** Hides the workout “add exercise” dock while the user logs set weight/reps. */
export function provideWorkoutSetLoggingFocus(): Ref<boolean> {
  const active = ref(false)
  let leaveTimer: ReturnType<typeof setTimeout> | null = null

  function enter() {
    if (leaveTimer) {
      clearTimeout(leaveTimer)
      leaveTimer = null
    }
    active.value = true
  }

  function leave(delayMs = 400) {
    if (leaveTimer) clearTimeout(leaveTimer)
    leaveTimer = setTimeout(() => {
      leaveTimer = null
      if (isWorkoutSetInputFocused()) return
      active.value = false
    }, delayMs)
  }

  provide(workoutSetLoggingFocusKey, { enter, leave })
  return active
}

export function useWorkoutSetLoggingFocusConsumer(): WorkoutSetLoggingFocusApi | null {
  return inject(workoutSetLoggingFocusKey, null)
}
