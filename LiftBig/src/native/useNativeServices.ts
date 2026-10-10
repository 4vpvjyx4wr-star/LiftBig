import { onBeforeUnmount, onMounted, ref, watch, type Ref } from 'vue'
import { useRoute } from 'vue-router'
import { Capacitor } from '@capacitor/core'
import type { useLocalWorkouts } from '@/composables/useLocalWorkouts'
import type { useSettings } from '@/composables/useSettings'
import { usePro } from '@/composables/usePro'
import { startRestForSeconds } from '@/composables/useRestTimerState'
import { LiftBigNative } from '@/native/liftbigPlugin'
import { reconcileICloud } from '@/native/nativeFileStore'
import { syncDailyReminder } from '@/native/nativeNotifications'
import { applyCompanionMessage, buildWatchSession } from '@/native/workoutSession'
import { hasTrainedToday } from '@/utils/dailyLiftReminder'
import { planDurationAssumptionsFromSeconds } from '@/utils/planDuration'
import { healthWritesForLog } from '@/utils/healthWorkout'
import { getDayExercises } from '@/types/workout'
import {
  applyLiftBigBackupToStorage,
  markBackupRestorePending,
  parseLiftBigBackupJson,
} from '@/utils/liftbigBackup'
import { LIFTBIG_STORAGE_KEYS } from '@/utils/liftbigStorageKeys'
import { loadJson, saveJson } from '@/utils/storage'
import { displayInputToStoredLbsString, type WeightUnit } from '@/utils/units'

type Workouts = ReturnType<typeof useLocalWorkouts>
type Settings = ReturnType<typeof useSettings>

type WireMessage = {
  version: 1
  kind: 'completeSet' | 'adjustSet' | 'skipRest'
  dateKey: string
  exerciseId: string
  setIndex: number
  reps?: string
  weightDisplay?: string
  weightUnit?: WeightUnit
}

export function useNativeServices(workouts: Workouts, settings: Settings): {
  showImport: Ref<boolean>
  dismissImport: () => void
  importWebsiteBackup: (file: File) => Promise<void>
} {
  const route = useRoute()
  const pro = usePro()
  const showImport = ref(false)
  const watchPreview = ref(false)
  let healthTimer: ReturnType<typeof setTimeout> | null = null
  let removeCompanion: (() => void) | null = null

  function dismissImport() {
    saveJson(LIFTBIG_STORAGE_KEYS.importPromptDismissed, true)
    showImport.value = false
  }

  async function importWebsiteBackupText(text: string) {
    const parsed = parseLiftBigBackupJson(text)
    if (!parsed.ok) {
      window.alert(parsed.error)
      return
    }
    const ok = window.confirm(
      'Replace all LiftBig data on this device with this backup?\n\nCurrent workouts, plans, and settings will be overwritten.',
    )
    if (!ok) return
    workouts.flush()
    applyLiftBigBackupToStorage(parsed.data)
    saveJson(LIFTBIG_STORAGE_KEYS.importPromptDismissed, true)
    window.location.reload()
  }

  async function importWebsiteBackup(file: File) {
    let text = ''
    try {
      text = await file.text()
    } catch {
      window.alert('Could not read that file.')
      return
    }
    await importWebsiteBackupText(text)
  }

  async function publishWatch() {
    if (!Capacitor.isNativePlatform()) return
    const dateKey = typeof route.params.date === 'string' ? route.params.date : ''
    const session =
      route.name === 'workout' && dateKey
        ? buildWatchSession(
            dateKey,
            getDayExercises(workouts.log.value[dateKey]),
            settings.averageRestSeconds.value,
            settings.weightUnit.value,
            pro.active.value || watchPreview.value,
          )
        : { version: 1 as const, locked: true as const, reason: 'idle' as const }
    try {
      await LiftBigNative.sendWatchSession({ sessionJson: JSON.stringify(session) })
    } catch {
      // The watch app is optional until the companion target is installed.
    }
  }

  async function pushHealth() {
    if (!Capacitor.isNativePlatform() || !settings.appleHealthEnabled.value) return
    const writes = healthWritesForLog(workouts.log.value, {
      bodyWeightLbs: settings.bodyWeightLbs.value,
      assumptions: planDurationAssumptionsFromSeconds(
        settings.averageLiftSeconds.value,
        settings.averageRestSeconds.value,
      ),
      distanceUnit: settings.distanceUnit.value,
    })
    try {
      await LiftBigNative.writeHealthWorkouts({ workoutsJson: JSON.stringify(writes) })
    } catch {
      // Health writes wait until the user grants permission.
    }
  }

  function scheduleHealth() {
    if (healthTimer) clearTimeout(healthTimer)
    healthTimer = setTimeout(() => {
      healthTimer = null
      void pushHealth()
    }, 1500)
  }

  async function enableHealth() {
    if (!Capacitor.isNativePlatform()) return
    try {
      const access = await LiftBigNative.requestHealthAccess()
      if (!access.granted) {
        settings.setAppleHealthEnabled(false)
        return
      }
      const profile = await LiftBigNative.readHealthProfile()
      if (settings.bodyWeightLbs.value <= 0 && profile.bodyWeightLbs && profile.bodyWeightLbs > 0) {
        settings.setBodyWeightLbs(profile.bodyWeightLbs)
      }
      if (settings.heightInches.value <= 0 && profile.heightInches && profile.heightInches > 0) {
        settings.setHeightInches(profile.heightInches)
      }
      await pushHealth()
    } catch {
      settings.setAppleHealthEnabled(false)
    }
  }

  async function onReturnToApp() {
    if (document.visibilityState !== 'visible') return
    const changed = await reconcileICloud()
    if (!changed) return
    markBackupRestorePending()
    window.location.reload()
  }

  watch(
    [
      () => settings.dailyLiftReminderEnabled.value,
      () => settings.dailyLiftReminderTime.value,
      workouts.log,
    ],
    () => {
      void syncDailyReminder(
        settings.dailyLiftReminderEnabled.value,
        settings.dailyLiftReminderTime.value,
        hasTrainedToday(workouts.log.value),
      )
    },
    { deep: true },
  )

  watch(
    () => settings.appleHealthEnabled.value,
    (enabled, previous) => {
      if (enabled && previous === false) void enableHealth()
    },
  )

  watch(workouts.log, () => {
    if (settings.appleHealthEnabled.value) scheduleHealth()
  }, { deep: true })

  watch(
    [() => route.fullPath, workouts.log, pro.active, watchPreview, () => settings.weightUnit.value, () => settings.averageRestSeconds.value],
    () => {
      void publishWatch()
    },
    { deep: true },
  )

  watch(
    () => settings.iCloudSyncEnabled.value,
    (enabled, previous) => {
      if (enabled && previous === false) {
        void reconcileICloud().then((changed) => {
          if (!changed) return
          markBackupRestorePending()
          window.location.reload()
        })
      }
    },
  )

  onMounted(() => {
    if (!Capacitor.isNativePlatform()) return
    void LiftBigNative.isSimulator()
      .then((info) => {
        watchPreview.value = info.simulator
      })
      .catch(() => {
        watchPreview.value = false
      })
    const dismissed = loadJson<boolean>(LIFTBIG_STORAGE_KEYS.importPromptDismissed, false)
    showImport.value = !dismissed && Object.keys(workouts.log.value).length === 0
    void syncDailyReminder(
      settings.dailyLiftReminderEnabled.value,
      settings.dailyLiftReminderTime.value,
      hasTrainedToday(workouts.log.value),
    )
    if (settings.appleHealthEnabled.value) void enableHealth()
    void publishWatch()
    void LiftBigNative.addListener('companionMessage', (event) => {
      let wire: WireMessage
      try {
        wire = JSON.parse(event.messageJson) as WireMessage
      } catch {
        return
      }
      if (wire.version !== 1 || !wire.dateKey || !wire.exerciseId) return
      const weightLbs = wire.weightDisplay
        ? displayInputToStoredLbsString(wire.weightDisplay, wire.weightUnit ?? settings.weightUnit.value)
        : undefined
      workouts.log.value = applyCompanionMessage(workouts.log.value, {
        version: 1,
        kind: wire.kind,
        dateKey: wire.dateKey,
        exerciseId: wire.exerciseId,
        setIndex: wire.setIndex,
        reps: wire.reps,
        weightLbs: weightLbs || undefined,
      })
      workouts.flush()
      if (wire.kind === 'completeSet') startRestForSeconds(settings.averageRestSeconds.value)
    }).then((handle) => {
      removeCompanion = () => {
        void handle.remove()
      }
    }).catch(() => {
      // No native bridge in the browser.
    })
    void LiftBigNative.addListener('backupFile', (event) => {
      if (!event.json?.trim()) return
      void importWebsiteBackupText(event.json)
    }).catch(() => {
      // No native bridge in the browser.
    })
    document.addEventListener('visibilitychange', onReturnToApp)
  })

  onBeforeUnmount(() => {
    if (healthTimer) clearTimeout(healthTimer)
    removeCompanion?.()
    document.removeEventListener('visibilitychange', onReturnToApp)
  })

  return { showImport, dismissImport, importWebsiteBackup }
}
