import { describe, expect, it } from 'vitest'
import { LIFTBIG_STORAGE_KEYS } from '@/utils/liftbigStorageKeys'
import { mergeSnapshots, stampSnapshot } from '@/utils/snapshotMerge'

const workoutsKey = LIFTBIG_STORAGE_KEYS.workouts

describe('snapshot merge', () => {
  it('stamps only the workout day that changed', () => {
    const previous = stampSnapshot(
      null,
      { [workoutsKey]: JSON.stringify({ '2026-10-01': { exercises: [] } }) },
      '2026-10-01T12:00:00.000Z',
    )
    const next = stampSnapshot(
      previous,
      {
        [workoutsKey]: JSON.stringify({
          '2026-10-01': { exercises: [] },
          '2026-10-02': { exercises: [{ id: 'a' }] },
        }),
      },
      '2026-10-02T12:00:00.000Z',
    )
    const stamps = JSON.parse(next.liftbig_day_stamps!) as Record<string, string>
    expect(stamps['2026-10-01']).toBe('2026-10-01T12:00:00.000Z')
    expect(stamps['2026-10-02']).toBe('2026-10-02T12:00:00.000Z')
  })

  it('keeps the newer copy of each day and the newer settings', () => {
    const local = stampSnapshot(
      null,
      {
        [workoutsKey]: JSON.stringify({
          '2026-10-01': { exercises: [{ id: 'local' }] },
          '2026-10-02': { exercises: [{ id: 'phone' }] },
        }),
        liftbig_settings: JSON.stringify({ theme: 'ocean' }),
      },
      '2026-10-02T15:00:00.000Z',
    )
    const remote = stampSnapshot(
      null,
      {
        [workoutsKey]: JSON.stringify({
          '2026-10-01': { exercises: [{ id: 'cloud' }] },
          '2026-10-03': { exercises: [{ id: 'ipad' }] },
        }),
        liftbig_settings: JSON.stringify({ theme: 'forest' }),
      },
      '2026-10-03T15:00:00.000Z',
    )
    const localStamps = JSON.parse(local.liftbig_day_stamps!) as Record<string, string>
    localStamps['2026-10-01'] = '2026-10-08T00:00:00.000Z'
    local.liftbig_day_stamps = JSON.stringify(localStamps)

    const merged = mergeSnapshots(local, remote)
    const days = JSON.parse(merged[workoutsKey]!) as Record<string, { exercises: { id: string }[] }>
    expect(days['2026-10-01']?.exercises[0]?.id).toBe('local')
    expect(days['2026-10-02']?.exercises[0]?.id).toBe('phone')
    expect(days['2026-10-03']?.exercises[0]?.id).toBe('ipad')
    expect(JSON.parse(merged.liftbig_settings!)).toEqual({ theme: 'forest' })
  })
})
