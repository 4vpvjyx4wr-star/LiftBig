import type { Exercise } from '@/types/workout'

function newId(): string {
  return `${Date.now()}-${Math.random().toString(36).slice(2, 11)}`
}

export type ExerciseDisplayItem =
  | { kind: 'standalone'; exercise: Exercise }
  | { kind: 'superset'; groupId: string; label?: string; exercises: Exercise[] }

export function newSupersetGroupId(): string {
  return `ss-${newId()}`
}

export function nextSupersetLabel(exercises: Exercise[]): string {
  const used = new Set(
    exercises
      .map((ex) => ex.supersetLabel?.trim())
      .filter((label): label is string => Boolean(label)),
  )
  for (let i = 0; i < 26; i++) {
    const letter = String.fromCharCode(65 + i)
    if (!used.has(letter)) return letter
  }
  return 'Z'
}

export function exerciseInSuperset(ex: Pick<Exercise, 'supersetGroupId'>): boolean {
  return Boolean(ex.supersetGroupId?.trim())
}

export function supersetBadgeLabel(
  ex: Pick<Exercise, 'supersetLabel' | 'supersetOrder'>,
): string | null {
  const label = ex.supersetLabel?.trim()
  if (!label) return null
  if (ex.supersetOrder === 1 || ex.supersetOrder === 2) {
    return `Superset ${label} · ${ex.supersetOrder}/2`
  }
  return `Superset ${label}`
}

/** Flat list → standalone cards and superset blocks (preserves workout order). */
export function groupExercisesForDisplay(exercises: Exercise[]): ExerciseDisplayItem[] {
  const items: ExerciseDisplayItem[] = []
  let i = 0
  while (i < exercises.length) {
    const ex = exercises[i]!
    const groupId = ex.supersetGroupId?.trim()
    if (!groupId) {
      items.push({ kind: 'standalone', exercise: ex })
      i++
      continue
    }
    const group: Exercise[] = [ex]
    let j = i + 1
    while (j < exercises.length && exercises[j]?.supersetGroupId?.trim() === groupId) {
      group.push(exercises[j]!)
      j++
    }
    items.push({
      kind: 'superset',
      groupId,
      label: ex.supersetLabel?.trim() || undefined,
      exercises: group,
    })
    i = j
  }
  return items
}

export function linkExercisesAsSuperset(
  exercises: Exercise[],
  firstId: string,
  secondId: string,
  label?: string,
): Exercise[] {
  const firstIdx = exercises.findIndex((ex) => ex.id === firstId)
  const secondIdx = exercises.findIndex((ex) => ex.id === secondId)
  if (firstIdx < 0 || secondIdx < 0 || firstIdx === secondIdx) return exercises

  const groupId = newSupersetGroupId()
  const groupLabel = label?.trim() || nextSupersetLabel(exercises)

  const linked = exercises.map((ex) => {
    if (ex.id !== firstId && ex.id !== secondId) return ex
    const order = ex.id === firstId ? 1 : 2
    return {
      ...ex,
      supersetGroupId: groupId,
      supersetLabel: groupLabel,
      supersetOrder: order,
    }
  })

  const [lo, hi] = firstIdx < secondIdx ? [firstIdx, secondIdx] : [secondIdx, firstIdx]
  const reordered = [...linked]
  const pair = [reordered[lo]!, reordered[hi]!].map((ex, idx) => ({
    ...ex,
    supersetGroupId: groupId,
    supersetLabel: groupLabel,
    supersetOrder: idx + 1,
  }))
  reordered.splice(hi, 1)
  reordered.splice(lo, 1)
  reordered.splice(lo, 0, ...pair)
  return reordered
}

export function unlinkSupersetGroup(exercises: Exercise[], groupId: string): Exercise[] {
  const id = groupId.trim()
  if (!id) return exercises
  return exercises.map((ex) => {
    if (ex.supersetGroupId?.trim() !== id) return ex
    const next = { ...ex }
    delete next.supersetGroupId
    delete next.supersetLabel
    delete next.supersetOrder
    return next
  })
}

/** Swap the two exercises in a superset pair (order in log + supersetOrder). */
export function swapSupersetPairOrder(exercises: Exercise[], groupId: string): Exercise[] {
  const id = groupId.trim()
  if (!id) return exercises

  const indices: number[] = []
  for (let i = 0; i < exercises.length; i++) {
    if (exercises[i]?.supersetGroupId?.trim() === id) indices.push(i)
  }
  if (indices.length !== 2) return exercises

  const [a, b] = indices
  if (a === undefined || b === undefined) return exercises

  const next = [...exercises]
  const first = next[a]!
  const second = next[b]!
  next[a] = {
    ...second,
    supersetOrder: 1,
    supersetLabel: first.supersetLabel ?? second.supersetLabel,
  }
  next[b] = {
    ...first,
    supersetOrder: 2,
    supersetLabel: first.supersetLabel ?? second.supersetLabel,
  }
  return next
}

export function unlinkExercise(exercises: Exercise[], exerciseId: string): Exercise[] {
  const target = exercises.find((ex) => ex.id === exerciseId)
  const groupId = target?.supersetGroupId?.trim()
  if (!groupId) return exercises
  return unlinkSupersetGroup(exercises, groupId)
}

export function moveDisplayItem(
  exercises: Exercise[],
  fromIndex: number,
  toIndex: number,
): Exercise[] {
  const items = groupExercisesForDisplay(exercises)
  if (fromIndex < 0 || fromIndex >= items.length || toIndex < 0 || toIndex >= items.length) {
    return exercises
  }
  if (fromIndex === toIndex) return exercises
  const nextItems = [...items]
  const [moved] = nextItems.splice(fromIndex, 1)
  if (!moved) return exercises
  nextItems.splice(toIndex, 0, moved)
  return nextItems.flatMap((item) =>
    item.kind === 'standalone' ? [item.exercise] : item.exercises,
  )
}
