import { LIFTBIG_STORAGE_KEYS } from '@/utils/liftbigStorageKeys'

/** Raw localStorage snapshot: liftbig_* key to the string stored for that key. */
export type RawSnapshot = Record<string, string>

export const DAY_STAMPS_KEY = 'liftbig_day_stamps'
export const SNAPSHOT_WRITTEN_AT_KEY = 'liftbig_snapshot_written_at'

const WORKOUTS_KEY = LIFTBIG_STORAGE_KEYS.workouts

function parseObject(raw: string | undefined): Record<string, unknown> {
  if (!raw) return {}
  try {
    const value = JSON.parse(raw) as unknown
    if (!value || typeof value !== 'object' || Array.isArray(value)) return {}
    return value as Record<string, unknown>
  } catch {
    return {}
  }
}

function parseStampMap(raw: string | undefined): Record<string, string> {
  const obj = parseObject(raw)
  const out: Record<string, string> = {}
  for (const [key, value] of Object.entries(obj)) {
    if (typeof value === 'string') out[key] = value
  }
  return out
}

export function snapshotWrittenAt(snapshot: RawSnapshot): string {
  const raw = snapshot[SNAPSHOT_WRITTEN_AT_KEY]
  if (!raw) return ''
  try {
    const value = JSON.parse(raw) as unknown
    return typeof value === 'string' ? value : ''
  } catch {
    return ''
  }
}

function stable(value: unknown): string {
  return JSON.stringify(value)
}

/** Stamp workout days that changed and record when this snapshot was written. */
export function stampSnapshot(
  previous: RawSnapshot | null,
  next: RawSnapshot,
  nowIso: string,
): RawSnapshot {
  const prevWorkouts = parseObject(previous?.[WORKOUTS_KEY])
  const nextWorkouts = parseObject(next[WORKOUTS_KEY])
  const prevStamps = parseStampMap(previous?.[DAY_STAMPS_KEY])
  const stamps: Record<string, string> = {}
  for (const day of Object.keys(nextWorkouts)) {
    const changed = stable(prevWorkouts[day]) !== stable(nextWorkouts[day])
    const prior = prevStamps[day]
    stamps[day] = changed || !prior ? nowIso : prior
  }
  return {
    ...next,
    [DAY_STAMPS_KEY]: JSON.stringify(stamps),
    [SNAPSHOT_WRITTEN_AT_KEY]: JSON.stringify(nowIso),
  }
}

function pickDay(
  localValue: unknown,
  remoteValue: unknown,
  localStamp: string,
  remoteStamp: string,
): { value: unknown; stamp: string } {
  if (localValue === undefined) return { value: remoteValue, stamp: remoteStamp }
  if (remoteValue === undefined) return { value: localValue, stamp: localStamp }
  if (remoteStamp > localStamp) return { value: remoteValue, stamp: remoteStamp }
  return { value: localValue, stamp: localStamp }
}

/**
 * Newer snapshot wins for settings and other keys.
 * Workout days merge individually: the newer stamp for that day wins.
 */
export function mergeSnapshots(local: RawSnapshot, remote: RawSnapshot): RawSnapshot {
  const localKeys = Object.keys(local)
  const remoteKeys = Object.keys(remote)
  if (localKeys.length === 0) return { ...remote }
  if (remoteKeys.length === 0) return { ...local }

  const localAt = snapshotWrittenAt(local)
  const remoteAt = snapshotWrittenAt(remote)
  const newer = remoteAt > localAt ? remote : local
  const older = newer === remote ? local : remote
  const merged: RawSnapshot = { ...older, ...newer }

  const localWorkouts = parseObject(local[WORKOUTS_KEY])
  const remoteWorkouts = parseObject(remote[WORKOUTS_KEY])
  const localStamps = parseStampMap(local[DAY_STAMPS_KEY])
  const remoteStamps = parseStampMap(remote[DAY_STAMPS_KEY])
  const days = new Set([...Object.keys(localWorkouts), ...Object.keys(remoteWorkouts)])
  const workouts: Record<string, unknown> = {}
  const stamps: Record<string, string> = {}

  for (const day of days) {
    const chosen = pickDay(
      localWorkouts[day],
      remoteWorkouts[day],
      localStamps[day] || localAt,
      remoteStamps[day] || remoteAt,
    )
    if (chosen.value !== undefined) {
      workouts[day] = chosen.value
      stamps[day] = chosen.stamp
    }
  }

  merged[WORKOUTS_KEY] = JSON.stringify(workouts)
  merged[DAY_STAMPS_KEY] = JSON.stringify(stamps)
  const newest = localAt > remoteAt ? localAt : remoteAt
  merged[SNAPSHOT_WRITTEN_AT_KEY] = JSON.stringify(newest)
  return merged
}

/** Compare journal keys, ignoring bookkeeping stamps. */
export function sameJournal(left: RawSnapshot, right: RawSnapshot): boolean {
  const ignore = new Set([DAY_STAMPS_KEY, SNAPSHOT_WRITTEN_AT_KEY])
  const keys = new Set([...Object.keys(left), ...Object.keys(right)])
  for (const key of keys) {
    if (ignore.has(key)) continue
    if ((left[key] ?? '') !== (right[key] ?? '')) return false
  }
  return true
}
