/**
 * Finds a YouTube form tutorial for library exercises that do not have one.
 *
 * A match has to be a how-to for that exercise, under 3 minutes, and from a
 * recognized coaching, clinical, or equipment channel. Cardio and sports are
 * left alone. Existing URLs are never replaced.
 *
 *   node ./scripts/fill-exercise-tutorials.mjs
 *   node ./scripts/fill-exercise-tutorials.mjs --dry-run
 *   node ./scripts/fill-exercise-tutorials.mjs --only sit-up
 */
import { readFileSync, writeFileSync } from 'node:fs'
import path from 'node:path'
import { fileURLToPath, pathToFileURL } from 'node:url'

const appDir = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..')
const libraryPath = path.join(appDir, 'src/utils/exerciseLibrary.ts')
const tutorialsPath = path.join(appDir, 'src/utils/exerciseTutorials.ts')
const catalogPath = path.join(appDir, 'flutter/assets/liftbig_catalog.json')
const pickModuleUrl = pathToFileURL(path.join(appDir, 'src/utils/youtubeTutorialPick.ts')).href

const args = process.argv.slice(2)
const dryRun = args.includes('--dry-run')
const only = new Set()
for (let i = 0; i < args.length; i++) {
  if (args[i] === '--only' && args[i + 1]) only.add(args[++i])
}

function field(body, name) {
  const match = body.match(new RegExp(`\\b${name}:\\s*(?:'([^']*)'|"([^"]*)")`))
  return match ? (match[1] ?? match[2] ?? '') : ''
}

function libraryExercisesNeedingTutorials(source, existing) {
  const found = []
  for (const match of source.matchAll(/reg\(\{([\s\S]*?)\n  \}\),/g)) {
    const body = match[1]
    if (/isCardio:\s*true/.test(body)) continue
    const id = field(body, 'id')
    const name = field(body, 'name')
    if (!id || !name || existing[id]) continue
    if (only.size > 0 && !only.has(id)) continue
    found.push({
      id,
      name,
      equipment: field(body, 'equipment'),
      instructions: (body.match(/instructions:\s*\[([\s\S]*?)\]/)?.[1].match(/['"][^'"]+['"]/g) ?? []).length,
      cues: (body.match(/cues:\s*\[([\s\S]*?)\]/)?.[1].match(/['"][^'"]+['"]/g) ?? []).length,
      tips: (body.match(/tips:\s*\[([\s\S]*?)\]/)?.[1].match(/['"][^'"]+['"]/g) ?? []).length,
    })
  }
  return found
}

function readTutorialMap(source) {
  const map = {}
  for (const match of source.matchAll(/^\s*'?([A-Za-z0-9-]+)'?\s*:\s*'([^']+)'/gm)) {
    map[match[1]] = match[2]
  }
  return map
}

function quoteKey(id) {
  return /^[A-Za-z_$][A-Za-z0-9_$]*$/.test(id) ? id : `'${id}'`
}

function insertTutorial(source, id, url) {
  const line = `  ${quoteKey(id)}: '${url}',`
  const lines = source.split('\n')
  let insertAt = lines.findIndex((entry) => entry.trim() === '}')
  if (insertAt < 0) throw new Error('Could not find the end of EXERCISE_TUTORIAL_URLS')
  for (let i = 0; i < lines.length; i++) {
    const key = lines[i].match(/^\s*'?([A-Za-z0-9-]+)'?\s*:/)
    if (!key) continue
    if (key[1] === id) return source
    if (key[1].localeCompare(id) > 0) {
      insertAt = i
      break
    }
  }
  lines.splice(insertAt, 0, line)
  return lines.join('\n')
}

function parseLength(value) {
  if (!value) return null
  const parts = String(value)
    .trim()
    .split(':')
    .map((part) => Number(part))
  if (parts.some((part) => !Number.isFinite(part))) return null
  if (parts.length === 2) return parts[0] * 60 + parts[1]
  if (parts.length === 3) return parts[0] * 3600 + parts[1] * 60 + parts[2]
  return null
}

async function searchYoutube(query) {
  const response = await fetch('https://www.youtube.com/youtubei/v1/search?prettyPrint=false', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'User-Agent':
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36',
    },
    body: JSON.stringify({
      context: {
        client: {
          clientName: 'WEB',
          clientVersion: '2.20241010.00.00',
          hl: 'en',
          gl: 'US',
        },
      },
      query,
    }),
  })
  if (!response.ok) throw new Error(`YouTube search failed (${response.status}) for ${query}`)
  const data = await response.json()
  const videos = []
  const seen = new Set()
  const walk = (node) => {
    if (!node || typeof node !== 'object') return
    if (node.videoRenderer?.videoId && !seen.has(node.videoRenderer.videoId)) {
      seen.add(node.videoRenderer.videoId)
      const video = node.videoRenderer
      videos.push({
        id: video.videoId,
        title: video.title?.runs?.map((run) => run.text).join('') ?? '',
        channel: video.ownerText?.runs?.map((run) => run.text).join('') ?? '',
        durationSeconds: parseLength(video.lengthText?.simpleText) ?? Number.NaN,
        description: '',
      })
    }
    for (const value of Object.values(node)) walk(value)
  }
  walk(data)
  return videos
}

async function verifyVideo(videoId) {
  const response = await fetch(`https://www.youtube.com/watch?v=${videoId}`, {
    headers: {
      'User-Agent':
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36',
      'Accept-Language': 'en-US,en;q=0.9',
    },
  })
  if (!response.ok) return null
  const html = await response.text()
  const duration = html.match(/"lengthSeconds":"(\d+)"/)?.[1]
  const titleRaw = html.match(/"title":"((?:\\.|[^"\\])*)"/)?.[1]
  const channelRaw = html.match(/"ownerChannelName":"((?:\\.|[^"\\])*)"/)?.[1]
  const descriptionRaw = html.match(/"shortDescription":"((?:\\.|[^"\\])*)"/)?.[1]
  const parse = (value) => {
    if (!value) return ''
    try {
      return JSON.parse(`"${value}"`)
    } catch {
      return value
    }
  }
  if (!duration) return null
  return {
    id: videoId,
    title: parse(titleRaw),
    channel: parse(channelRaw),
    durationSeconds: Number(duration),
    description: parse(descriptionRaw),
  }
}

function searchQueries(exercise) {
  const queries = [`${exercise.name} how to form tutorial`, `How To: ${exercise.name}`]
  if (/machine/i.test(`${exercise.name} ${exercise.equipment}`)) {
    queries.push(`How To: ${exercise.name} Cybex`)
  }
  return queries
}

function syncCatalog(tutorialMap) {
  let catalog
  try {
    catalog = JSON.parse(readFileSync(catalogPath, 'utf8'))
  } catch {
    return 0
  }
  let updated = 0
  for (const lift of catalog.lifts ?? []) {
    const url = tutorialMap[lift.id]
    if (!url || lift.tutorialUrl) continue
    lift.tutorialUrl = url
    updated++
  }
  if (updated > 0 && !dryRun) {
    writeFileSync(catalogPath, JSON.stringify(catalog))
  }
  return updated
}

const { pickTutorial, rankTutorials, youtubeWatchUrl } = await import(pickModuleUrl)

const tutorialSource = readFileSync(tutorialsPath, 'utf8')
const existing = readTutorialMap(tutorialSource)
const missing = libraryExercisesNeedingTutorials(readFileSync(libraryPath, 'utf8'), existing)

if (missing.length === 0) {
  const synced = syncCatalog(existing)
  if (synced > 0) {
    console.log(
      dryRun
        ? `Would copy ${synced} existing tutorial URL${synced === 1 ? '' : 's'} into the Flutter catalog.`
        : `Copied ${synced} existing tutorial URL${synced === 1 ? '' : 's'} into the Flutter catalog.`,
    )
  } else {
    console.log('Every gym exercise already has a tutorial.')
  }
  process.exit(0)
}

let nextSource = tutorialSource
const failed = []

for (const exercise of missing) {
  const textGaps = []
  if (!exercise.instructions) textGaps.push('how to perform')
  if (!exercise.cues) textGaps.push('cues')
  if (!exercise.tips) textGaps.push('tips')
  if (textGaps.length) {
    console.warn(`${exercise.id} is missing ${textGaps.join(', ')}. Add that coaching text in exerciseLibrary.ts.`)
  }

  const byId = new Map()
  for (const query of searchQueries(exercise)) {
    const found = await searchYoutube(query)
    for (const video of found) {
      if (!byId.has(video.id)) byId.set(video.id, video)
    }
    await new Promise((resolve) => setTimeout(resolve, 300))
  }

  const ranked = rankTutorials(exercise, [...byId.values()]).filter((row) => row.score > 0)
  const verified = []
  for (const row of ranked.slice(0, 5)) {
    const checked = await verifyVideo(row.candidate.id)
    await new Promise((resolve) => setTimeout(resolve, 200))
    if (checked) verified.push(checked)
  }
  const pick = pickTutorial(exercise, verified)

  if (!pick) {
    failed.push(exercise.id)
    console.warn(`No tutorial under 3 minutes from a recognized source for ${exercise.name} (${exercise.id}).`)
    continue
  }

  const url = youtubeWatchUrl(pick.id)
  console.log(`${exercise.id}: ${pick.channel} — ${pick.title} (${pick.durationSeconds}s) ${url}`)
  nextSource = insertTutorial(nextSource, exercise.id, url)
  existing[exercise.id] = url
}

if (!dryRun && nextSource !== tutorialSource) {
  writeFileSync(tutorialsPath, nextSource)
}

const synced = syncCatalog(existing)
if (synced > 0) {
  console.log(
    dryRun
      ? `Would update ${synced} Flutter catalog tutorial URL${synced === 1 ? '' : 's'}.`
      : `Updated ${synced} Flutter catalog tutorial URL${synced === 1 ? '' : 's'}.`,
  )
}

if (failed.length > 0) {
  console.error(`Still missing tutorials: ${failed.join(', ')}`)
  process.exit(1)
}
