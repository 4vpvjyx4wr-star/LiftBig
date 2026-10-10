import { Capacitor } from '@capacitor/core'
import { LocalNotifications } from '@capacitor/local-notifications'
import { LiftBigNative } from '@/native/liftbigPlugin'
import {
  DAILY_NOTIFICATION_ID,
  nextDailyReminderAt,
  REST_NOTIFICATION_ID,
} from '@/utils/reminderSchedule'

async function notificationsAllowed(): Promise<boolean> {
  const current = await LocalNotifications.checkPermissions()
  if (current.display === 'granted') return true
  const requested = await LocalNotifications.requestPermissions()
  return requested.display === 'granted'
}

const ALERT_CHANNEL_ID = 'liftbig-alerts'

async function ensureAlertChannel(): Promise<void> {
  if (Capacitor.getPlatform() !== 'android') return
  await LocalNotifications.createChannel({
    id: ALERT_CHANNEL_ID,
    name: 'LiftBig alerts',
    description: 'Rest timer and daily reminder',
    importance: 5,
    vibration: true,
    visibility: 1,
  })
}

export async function syncRestNotification(running: boolean, endsAtMs: number | null): Promise<void> {
  if (!Capacitor.isNativePlatform()) return
  try {
    await LocalNotifications.cancel({ notifications: [{ id: REST_NOTIFICATION_ID }] })
    if (!running || endsAtMs == null || endsAtMs <= Date.now() + 500) {
      await LiftBigNative.endRestActivity()
      return
    }
    if (!(await notificationsAllowed())) return
    if (Capacitor.getPlatform() === 'ios') {
      await LiftBigNative.scheduleRestAlert({ endsAtMs })
    } else {
      await ensureAlertChannel()
      await LocalNotifications.schedule({
        notifications: [
          {
            id: REST_NOTIFICATION_ID,
            title: 'Time to Lift Big',
            body: 'Your rest timer is done — get back to it!',
            channelId: ALERT_CHANNEL_ID,
            sound: 'default',
            schedule: { at: new Date(endsAtMs), allowWhileIdle: true },
          },
        ],
      })
    }
    await LiftBigNative.startRestActivity({ endsAtMs, title: 'Rest' })
  } catch {
    // Notifications stay optional.
  }
}

export async function syncDailyReminder(
  enabled: boolean,
  timeHHMM: string,
  trainedToday: boolean,
): Promise<void> {
  if (!Capacitor.isNativePlatform()) return
  try {
    await LocalNotifications.cancel({ notifications: [{ id: DAILY_NOTIFICATION_ID }] })
    if (!enabled) return
    if (!(await notificationsAllowed())) return
    await ensureAlertChannel()
    const at = nextDailyReminderAt(timeHHMM, trainedToday)
    await LocalNotifications.schedule({
      notifications: [
        {
          id: DAILY_NOTIFICATION_ID,
          title: 'Time to lift big',
          body: "Your daily nudge — log today's workout when you're ready.",
          channelId: ALERT_CHANNEL_ID,
          sound: 'default',
          schedule: { at, repeats: true, allowWhileIdle: true },
        },
      ],
    })
  } catch {
    // The in-app banner still works if notifications are denied.
  }
}
