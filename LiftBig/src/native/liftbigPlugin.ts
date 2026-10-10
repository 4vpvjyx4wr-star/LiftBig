import { registerPlugin, type PluginListenerHandle } from '@capacitor/core'

export type ProProduct = { id: string; displayPrice: string }

export interface LiftBigPlugin {
  requestHealthAccess(): Promise<{ granted: boolean }>
  readHealthProfile(): Promise<{ bodyWeightLbs: number | null; heightInches: number | null }>
  writeHealthWorkouts(options: { workoutsJson: string }): Promise<{ written: number }>
  iCloudAvailable(): Promise<{ available: boolean }>
  pushICloud(options: { snapshotJson: string }): Promise<void>
  pullICloud(): Promise<{ snapshotJson: string | null }>
  getProStatus(): Promise<{ active: boolean }>
  purchasePro(options: { productId: string }): Promise<{ active: boolean; message?: string }>
  restorePro(): Promise<{ active: boolean }>
  loadProProducts(): Promise<{ products: ProProduct[] }>
  startRestActivity(options: { endsAtMs: number; title: string }): Promise<void>
  endRestActivity(): Promise<void>
  scheduleRestAlert(options: { endsAtMs: number }): Promise<void>
  sendWatchSession(options: { sessionJson: string }): Promise<void>
  isSimulator(): Promise<{ simulator: boolean }>
  addListener(
    eventName: 'companionMessage',
    listenerFunc: (event: { messageJson: string }) => void,
  ): Promise<PluginListenerHandle>
  addListener(
    eventName: 'backupFile',
    listenerFunc: (event: { json: string }) => void,
  ): Promise<PluginListenerHandle>
}

export const LiftBigNative = registerPlugin<LiftBigPlugin>('LiftBig')
