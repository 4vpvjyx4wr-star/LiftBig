import fs from 'fs'
const candidates = process.argv[2]?.endsWith('.json')
  ? JSON.parse(fs.readFileSync(process.argv[2], 'utf8'))
  : JSON.parse(process.argv[2] || '[]')

async function getMeta(videoId) {
  const res = await fetch(`https://www.youtube.com/watch?v=${videoId}`, {
    headers: { 'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36' },
  })
  const html = await res.text()
  const durationMatch = html.match(/"lengthSeconds":"(\d+)"/)
  const titleMatch = html.match(/"title":"((?:\\.|[^"\\])*)"/)
  const channelMatch = html.match(/"ownerChannelName":"((?:\\.|[^"\\])*)"/)
  const title = titleMatch ? JSON.parse(`"${titleMatch[1]}"`) : null
  const channel = channelMatch ? JSON.parse(`"${channelMatch[1]}"`) : null
  return {
    duration: durationMatch ? Number(durationMatch[1]) : null,
    title,
    channel,
  }
}

for (const c of candidates) {
  const videoId = c.url.match(/(?:v=|shorts\/|youtu\.be\/)([A-Za-z0-9_-]+)/)?.[1]
  if (!videoId) {
    console.log(JSON.stringify({ ...c, error: 'bad url' }))
    continue
  }
  try {
    const meta = await getMeta(videoId)
    console.log(JSON.stringify({ exercise_id: c.exercise_id, youtube_url: c.url, ...meta, ok: meta.duration != null && meta.duration <= 180 }))
    await new Promise((r) => setTimeout(r, 250))
  } catch (e) {
    console.log(JSON.stringify({ ...c, error: String(e) }))
  }
}
