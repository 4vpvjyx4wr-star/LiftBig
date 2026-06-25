/** Browser notifications for rest timer and similar alerts. */

export type TimerNotificationOptions = {
  title?: string
  body?: string
  tag?: string
}

export function canUseNotifications(): boolean {
  return typeof window !== 'undefined' && typeof Notification !== 'undefined'
}

export function getNotificationPermission(): NotificationPermission | 'unsupported' {
  if (!canUseNotifications()) return 'unsupported'
  return Notification.permission
}

export async function requestNotificationPermission(): Promise<NotificationPermission | 'unsupported'> {
  if (!canUseNotifications()) return 'unsupported'
  if (Notification.permission !== 'default') return Notification.permission
  try {
    return await Notification.requestPermission()
  } catch {
    return Notification.permission
  }
}

export function showTimerFinishedNotification(options: TimerNotificationOptions = {}): void {
  if (!canUseNotifications() || Notification.permission !== 'granted') return
  const title = options.title ?? 'Rest complete'
  const body = options.body ?? 'Time to lift — your rest timer is done.'
  try {
    void new Notification(title, {
      body,
      tag: options.tag ?? 'liftbig-rest-timer',
      icon: '/pwa-192x192.svg',
      badge: '/pwa-192x192.svg',
      silent: false,
    })
  } catch {
    // Ignore notification failures.
  }
}
