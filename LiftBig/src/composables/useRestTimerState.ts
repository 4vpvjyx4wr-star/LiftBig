import { computed, ref, watch } from 'vue'
import { haptic } from '@/utils/haptics'
import {
  requestNotificationPermission,
  showTimerFinishedNotification,
} from '@/utils/notifications'
import { playTimerDoneSound } from '@/utils/timerSound'
import { LIFTBIG_STORAGE_KEYS } from '@/utils/liftbigStorageKeys'

const TIMER_OPTIONS = [30, 60, 90, 120] as const

const MIN_SECONDS = 5
const MAX_SECONDS = 60 * 30

const duration = ref(60)
const remaining = ref(60)
const running = ref(false)
const pickerOpen = ref(false)
const customSecondsInput = ref('')
let intervalId: ReturnType<typeof setInterval> | null = null
let longPressTimer: ReturnType<typeof setTimeout> | null = null
const longPressConsumed = ref(false)
let notificationPermissionRequested = false
let endsAtMs: number | null = null
let alertedThisRun = false
let resumeListenersAttached = false

function isTimerSoundEnabled(): boolean {
  if (typeof localStorage === 'undefined') return true
  try {
    const raw = localStorage.getItem(LIFTBIG_STORAGE_KEYS.settings)
    if (!raw) return true
    const parsed = JSON.parse(raw) as { timerSoundEnabled?: boolean }
    return parsed.timerSoundEnabled !== false
  } catch {
    return true
  }
}

function maybeNotifyTimerFinished() {
  showTimerFinishedNotification({
    title: 'Time to Lift Big',
    body: 'Your rest timer is done — get back to it!',
  })
  if (isTimerSoundEnabled()) playTimerDoneSound()
}

function tickFromClock() {
  if (!running.value || endsAtMs == null) return
  const next = Math.max(0, Math.ceil((endsAtMs - Date.now()) / 1000))
  remaining.value = next
  if (next > 0) return
  running.value = false
  endsAtMs = null
  clearTick()
  if (!alertedThisRun) {
    alertedThisRun = true
    haptic('timerDone')
    maybeNotifyTimerFinished()
  }
}

function attachResumeListenersIfNeeded() {
  if (resumeListenersAttached || typeof window === 'undefined' || typeof document === 'undefined') return
  const onResume = () => tickFromClock()
  window.addEventListener('focus', onResume)
  window.addEventListener('pageshow', onResume)
  document.addEventListener('visibilitychange', () => {
    if (document.visibilityState === 'visible') onResume()
  })
  resumeListenersAttached = true
}

function requestNotificationPermissionIfNeeded() {
  if (notificationPermissionRequested) return
  notificationPermissionRequested = true
  void requestNotificationPermission()
}

function clearTick() {
  if (intervalId) {
    clearInterval(intervalId)
    intervalId = null
  }
}

watch(running, (r) => {
  clearTick()
  if (!r) {
    endsAtMs = null
    return
  }
  endsAtMs = Date.now() + remaining.value * 1000
  alertedThisRun = false
  tickFromClock()
  intervalId = setInterval(tickFromClock, 1000)
})

function clampSeconds(sec: number): number {
  return Math.min(MAX_SECONDS, Math.max(MIN_SECONDS, Math.round(sec)))
}

function parseCustomDuration(raw: string): number | null {
  const t = raw.trim()
  if (!t) return null
  if (t.includes(':')) {
    const parts = t.split(':').map((p) => p.trim())
    if (parts.length !== 2) return null
    const m = Number(parts[0])
    const s = Number(parts[1])
    if (
      !Number.isFinite(m) ||
      !Number.isFinite(s) ||
      m < 0 ||
      s < 0 ||
      s >= 60 ||
      !Number.isInteger(m) ||
      !Number.isInteger(s)
    ) {
      return null
    }
    return m * 60 + s
  }
  const n = Number(t)
  if (!Number.isFinite(n) || n <= 0) return null
  return Math.round(n)
}

function selectDur(d: number) {
  const sec = clampSeconds(d)
  duration.value = sec
  remaining.value = sec
  running.value = false
  alertedThisRun = false
  customSecondsInput.value = String(sec)
  pickerOpen.value = false
}

function applyCustomDuration() {
  const parsed = parseCustomDuration(customSecondsInput.value)
  if (parsed === null) return
  selectDur(parsed)
}

watch(pickerOpen, (open) => {
  if (open) customSecondsInput.value = String(duration.value)
})

function reset() {
  remaining.value = duration.value
  running.value = false
  alertedThisRun = false
}

function toggle() {
  if (remaining.value === 0) {
    reset()
    return
  }
  const starting = !running.value
  if (starting) {
    requestNotificationPermissionIfNeeded()
    haptic('timerStart')
  }
  running.value = !running.value
}

function onPointerDown() {
  longPressConsumed.value = false
  longPressTimer = setTimeout(() => {
    longPressConsumed.value = true
    running.value = false
    pickerOpen.value = true
    longPressTimer = null
  }, 550)
}

function onPointerUp() {
  if (longPressTimer) {
    clearTimeout(longPressTimer)
    longPressTimer = null
  }
}

function onClick() {
  if (longPressConsumed.value) {
    longPressConsumed.value = false
    return
  }
  toggle()
}

const mins = computed(() => Math.floor(remaining.value / 60))
const secs = computed(() => String(remaining.value % 60).padStart(2, '0'))
const isFinished = computed(() => remaining.value === 0)
const isPartial = computed(() => remaining.value < duration.value && remaining.value > 0)
const isFloatingActive = computed(() => remaining.value < duration.value)

const bubbleClass = computed(() => {
  if (isFinished.value) return 'border-primary bg-[#2a1008]'
  if (running.value) return 'border-[#16a34a] bg-[#163020]'
  return 'border-border bg-card-inner'
})

export function useRestTimerState() {
  attachResumeListenersIfNeeded()
  return {
    TIMER_OPTIONS,
    MIN_SECONDS,
    MAX_SECONDS,
    duration,
    remaining,
    running,
    pickerOpen,
    customSecondsInput,
    mins,
    secs,
    isFinished,
    isPartial,
    isFloatingActive,
    bubbleClass,
    selectDur,
    applyCustomDuration,
    onPointerDown,
    onPointerUp,
    onClick,
    reset,
    clearTick,
  }
}
