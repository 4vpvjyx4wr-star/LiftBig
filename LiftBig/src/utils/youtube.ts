/** Extract a YouTube video id from watch, shorts, or youtu.be URLs. */
export function youtubeVideoId(url: string): string | null {
  try {
    const u = new URL(url)
    if (u.hostname.includes('youtube.com')) {
      if (u.pathname.startsWith('/shorts/')) {
        const id = u.pathname.split('/')[2]
        return id || null
      }
      if (u.pathname.startsWith('/embed/')) {
        const id = u.pathname.split('/')[2]
        return id || null
      }
      return u.searchParams.get('v')
    }
    if (u.hostname === 'youtu.be') {
      const id = u.pathname.replace(/^\//, '').split('/')[0]
      return id || null
    }
  } catch {
    return null
  }
  return null
}

/** Privacy-enhanced embed URL for in-app playback. */
export function youtubeEmbedUrl(url: string): string | null {
  const id = youtubeVideoId(url)
  if (!id) return null
  return `https://www.youtube-nocookie.com/embed/${id}?rel=0`
}
