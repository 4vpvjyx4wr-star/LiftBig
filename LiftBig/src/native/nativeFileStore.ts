import { Capacitor } from '@capacitor/core'
import { Directory, Encoding, Filesystem } from '@capacitor/filesystem'
import {
  applyLiftbigRawStorageSnapshot,
  clearLiftbigPrefixedStorage,
  collectLiftbigRawStorageSnapshot,
  LIFTBIG_STORAGE_KEYS,
} from '@/utils/liftbigStorageKeys'
import { setStorageChangeListener } from '@/utils/storage'
import { mergeSnapshots, sameJournal, stampSnapshot, type RawSnapshot } from '@/utils/snapshotMerge'
import { LiftBigNative } from '@/native/liftbigPlugin'

const SNAPSHOT_PATH = 'liftbig-snapshot.json'

let mirrorTimer: ReturnType<typeof setTimeout> | null = null
let applying = false

function iCloudEnabled(snapshot: RawSnapshot): boolean {
  try {
    const parsed = JSON.parse(snapshot[LIFTBIG_STORAGE_KEYS.settings] ?? '{}') as {
      iCloudSyncEnabled?: boolean
    }
    return parsed.iCloudSyncEnabled === true
  } catch {
    return false
  }
}

export async function readSnapshotFile(): Promise<RawSnapshot | null> {
  try {
    const result = await Filesystem.readFile({
      path: SNAPSHOT_PATH,
      directory: Directory.Data,
      encoding: Encoding.UTF8,
    })
    const text = typeof result.data === 'string' ? result.data : ''
    const parsed = JSON.parse(text) as unknown
    if (!parsed || typeof parsed !== 'object' || Array.isArray(parsed)) return null
    return parsed as RawSnapshot
  } catch {
    return null
  }
}

export async function writeSnapshotFile(snapshot: RawSnapshot): Promise<void> {
  await Filesystem.writeFile({
    path: SNAPSHOT_PATH,
    directory: Directory.Data,
    data: JSON.stringify(snapshot),
    encoding: Encoding.UTF8,
    recursive: true,
  })
}

function applySnapshot(snapshot: RawSnapshot): void {
  applying = true
  try {
    clearLiftbigPrefixedStorage()
    applyLiftbigRawStorageSnapshot(snapshot)
  } finally {
    applying = false
  }
}

async function pullRemote(snapshot: RawSnapshot): Promise<RawSnapshot> {
  if (!iCloudEnabled(snapshot)) return snapshot
  try {
    const remote = await LiftBigNative.pullICloud()
    if (!remote.snapshotJson) return snapshot
    const parsed = JSON.parse(remote.snapshotJson) as RawSnapshot
    return mergeSnapshots(snapshot, parsed)
  } catch {
    return snapshot
  }
}

/** Restore the private file (and iCloud, when enabled) before the Vue app reads storage. */
export async function hydrateNativeStore(): Promise<void> {
  if (!Capacitor.isNativePlatform()) return
  const local = collectLiftbigRawStorageSnapshot()
  const file = await readSnapshotFile()
  let merged = file ? mergeSnapshots(local, file) : local
  merged = await pullRemote(merged)
  const stamped = stampSnapshot(file ?? local, merged, new Date().toISOString())
  if (!sameJournal(stamped, local)) applySnapshot(stamped)
  try {
    await writeSnapshotFile(stamped)
  } catch {
    // The WebView copy is still in place.
  }
  if (iCloudEnabled(stamped)) {
    try {
      await LiftBigNative.pushICloud({ snapshotJson: JSON.stringify(stamped) })
    } catch {
      // iCloud can be unavailable in the simulator.
    }
  }
  setStorageChangeListener(() => {
    if (applying) return
    scheduleSnapshotMirror()
  })
}

export function scheduleSnapshotMirror(): void {
  if (!Capacitor.isNativePlatform() || applying) return
  if (mirrorTimer) clearTimeout(mirrorTimer)
  mirrorTimer = setTimeout(() => {
    mirrorTimer = null
    void flushNativeSnapshot()
  }, 400)
}

export async function flushNativeSnapshot(): Promise<void> {
  if (!Capacitor.isNativePlatform()) return
  const previous = await readSnapshotFile()
  const stamped = stampSnapshot(previous, collectLiftbigRawStorageSnapshot(), new Date().toISOString())
  try {
    await writeSnapshotFile(stamped)
  } catch {
    return
  }
  if (!iCloudEnabled(stamped)) return
  try {
    await LiftBigNative.pushICloud({ snapshotJson: JSON.stringify(stamped) })
  } catch {
    // Keep the on-device file when iCloud is unreachable.
  }
}

/** Pull iCloud, merge by workout day, and report whether the on-device journal changed. */
export async function reconcileICloud(): Promise<boolean> {
  if (!Capacitor.isNativePlatform()) return false
  const local = collectLiftbigRawStorageSnapshot()
  if (!iCloudEnabled(local)) return false
  try {
    const remote = await LiftBigNative.pullICloud()
    if (!remote.snapshotJson) return false
    const merged = stampSnapshot(
      local,
      mergeSnapshots(local, JSON.parse(remote.snapshotJson) as RawSnapshot),
      new Date().toISOString(),
    )
    if (sameJournal(merged, local)) return false
    applySnapshot(merged)
    await writeSnapshotFile(merged)
    await LiftBigNative.pushICloud({ snapshotJson: JSON.stringify(merged) })
    return true
  } catch {
    return false
  }
}
