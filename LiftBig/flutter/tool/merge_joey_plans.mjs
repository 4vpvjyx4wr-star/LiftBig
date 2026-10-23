import { writeFileSync } from 'node:fs'
import { createServer } from 'vite'

const server = await createServer({
  root: new URL('../../', import.meta.url).pathname,
  server: { middlewareMode: true },
  appType: 'custom',
  logLevel: 'error',
})

function mapWorkout(workout) {
  return {
    id: workout.id,
    name: workout.name,
    folderId: workout.folderId ?? null,
    notes: workout.notes ?? '',
    exercises: (workout.exercises ?? []).map((exercise) => ({
      name: exercise.name,
      libraryId: exercise.libraryId ?? null,
      isCardio: exercise.isCardio === true,
      isCore: exercise.isCore === true,
      isCircuit: exercise.isCircuit === true,
      targetDuration: exercise.targetDuration ?? null,
      supersetGroupId: exercise.supersetGroupId ?? null,
      supersetLabel: exercise.supersetLabel ?? null,
      supersetOrder: exercise.supersetOrder ?? null,
      sets: (exercise.sets ?? []).map((set) => ({
        reps: set.targetReps ?? '',
        weight: set.targetWeight ?? '',
      })),
    })),
  }
}

try {
  const fall = await server.ssrLoadModule('/src/utils/joeyFallBulk.ts')
  const v2 = await server.ssrLoadModule('/src/utils/joeyFallBulkV2.ts')
  const summer = await server.ssrLoadModule('/src/utils/joeySummerPlan2.ts')
  const cut = await server.ssrLoadModule('/src/utils/joeySummerCutSplitPlans.ts')
  const folders = [
    fall.JOEY_FALL_BULK_FOLDER,
    v2.JOEY_FALL_BULK_V2_FOLDER,
    summer.JOEY_SUMMER_PLAN2_FOLDER,
    cut.JOEY_CUT_SPLIT_FOLDER,
  ].map((folder) => ({
    id: folder.id,
    name: folder.name,
    purpose: folder.purpose ?? '',
  }))
  const workouts = [
    ...fall.JOEY_FALL_BULK_PLANS,
    ...v2.JOEY_FALL_BULK_V2_PLANS,
    ...summer.JOEY_SUMMER_PLAN2_PLANS,
    ...cut.JOEY_CUT_SPLIT_PLANS,
  ].map(mapWorkout)
  const out = new URL('../assets/joey_plans_fragment.json', import.meta.url)
  writeFileSync(out, JSON.stringify({ folders, workouts }))
  const linked = workouts.filter((workout) =>
    workout.exercises.some((exercise) => exercise.supersetGroupId),
  ).length
  console.log(JSON.stringify({ folders: folders.map((folder) => folder.name), workouts: workouts.length, linked }))
} finally {
  await server.close()
}
