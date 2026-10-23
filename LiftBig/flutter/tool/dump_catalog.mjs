import { writeFileSync } from 'node:fs'
import { spawnSync } from 'node:child_process'
import path from 'node:path'
import { createServer } from 'vite'

const root = new URL('../../', import.meta.url).pathname
const fill = spawnSync(
  process.execPath,
  ['--experimental-strip-types', path.join(root, 'scripts/fill-exercise-tutorials.mjs')],
  { cwd: root, stdio: 'inherit' },
)
if (fill.status !== 0) {
  process.exit(fill.status ?? 1)
}

const server = await createServer({
  root,
  server: { middlewareMode: true },
  appType: 'custom',
  logLevel: 'error',
})

try {
  const library = await server.ssrLoadModule('/src/utils/exerciseLibrary.ts')
  const guided = await server.ssrLoadModule('/src/utils/guidedPlans/index.ts')
  const catalogMod = await server.ssrLoadModule('/src/utils/guidedPlans/guidedPlanCatalog.ts')
  const defaults = await server.ssrLoadModule('/src/utils/defaultPlans.ts')
  const fall = await server.ssrLoadModule('/src/utils/joeyFallBulk.ts')
  const fallV2 = await server.ssrLoadModule('/src/utils/joeyFallBulkV2.ts')
  const summer = await server.ssrLoadModule('/src/utils/joeySummerPlan2.ts')
  const cut = await server.ssrLoadModule('/src/utils/joeySummerCutSplitPlans.ts')
  const c4 = await server.ssrLoadModule('/src/utils/joeyC4.ts')

  const lifts = library.EXERCISE_LIBRARY.map((ex) => ({
    id: ex.id,
    name: ex.name,
    muscleGroups: ex.muscleGroups,
    tags: ex.tags ?? [],
    equipment: ex.equipment ?? '',
    summary: ex.summary,
    instructions: ex.instructions ?? [],
    tips: ex.tips ?? [],
    cues: ex.cues ?? [],
    tutorialUrl: ex.tutorialUrl ?? '',
    isCardio: ex.isCardio === true,
    repBasedCore: ex.repBasedCore === true,
  }))

  const workouts = [
    ...guided.ALL_GUIDED_PLANS,
    ...defaults.DEFAULT_PLANS,
    ...fall.JOEY_FALL_BULK_PLANS,
    ...fallV2.JOEY_FALL_BULK_V2_PLANS,
    ...summer.JOEY_SUMMER_PLAN2_PLANS,
    ...cut.JOEY_CUT_SPLIT_PLANS,
    ...c4.JOEY_C4_PLANS,
  ].map((workout) => ({
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
      sets: (exercise.sets ?? []).map((set) => ({
        reps: set.targetReps ?? '',
        weight: set.targetWeight ?? '',
      })),
      supersetGroupId: exercise.supersetGroupId ?? null,
      supersetLabel: exercise.supersetLabel ?? null,
      supersetOrder: exercise.supersetOrder ?? null,
    })),
  }))

  const folders = [
    ...guided.ALL_GUIDED_FOLDERS,
    fall.JOEY_FALL_BULK_FOLDER,
    fallV2.JOEY_FALL_BULK_V2_FOLDER,
    summer.JOEY_SUMMER_PLAN2_FOLDER,
    cut.JOEY_CUT_SPLIT_FOLDER,
    c4.JOEY_C4_FOLDER,
  ].map((folder) => ({
    id: folder.id,
    name: folder.name,
    purpose: folder.purpose ?? '',
  }))

  const quiz = catalogMod.ALL_PLAN_CATALOG.map((entry) => ({
    id: entry.id,
    title: entry.title,
    description: entry.description,
    experienceLevels: entry.experienceLevels,
    goals: entry.goals,
    days: Array.isArray(entry.days) ? entry.days : [entry.days],
    duration: Array.isArray(entry.duration) ? entry.duration : [entry.duration],
    equipment: entry.equipment,
    styles: entry.styles,
    difficulty: entry.difficulty,
    estimatedMinutes: entry.estimatedMinutes,
    primaryMuscles: entry.primaryMuscles,
    progressionStyle: entry.progressionStyle,
    goalTag: entry.goalTag,
    category: entry.category,
    workoutIds: entry.scheduleTemplateIds?.length
      ? entry.scheduleTemplateIds
      : entry.templateId
        ? [entry.templateId]
        : [],
  }))

  const out = {
    lifts,
    workouts,
    folders,
    quiz,
  }
  const path = new URL('../assets/liftbig_catalog.json', import.meta.url)
  writeFileSync(path, JSON.stringify(out))
  const missingTutorial = lifts.filter((lift) => !lift.tutorialUrl).length
  console.log(
    JSON.stringify({
      lifts: lifts.length,
      workouts: workouts.length,
      folders: folders.length,
      quiz: quiz.length,
      missingTutorial,
      bytes: Buffer.byteLength(JSON.stringify(out)),
    }),
  )
} finally {
  await server.close()
}
