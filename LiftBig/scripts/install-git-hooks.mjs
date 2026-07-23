import { execSync } from 'node:child_process'
import path from 'node:path'
import { fileURLToPath } from 'node:url'

const scriptDir = path.dirname(fileURLToPath(import.meta.url))

function git(args, opts = {}) {
  return execSync(`git ${args}`, {
    cwd: repoRoot,
    encoding: 'utf8',
    ...opts,
  })
}

function tryGit(args) {
  try {
    return git(args, { stdio: ['ignore', 'pipe', 'ignore'] }).trim()
  } catch {
    return null
  }
}

const repoRoot = execSync('git rev-parse --show-toplevel', {
  cwd: path.resolve(scriptDir, '..'),
  encoding: 'utf8',
}).trim()

/** Canonical GitHub repo — all work ships here. */
const CODYCON_ORIGIN = 'https://github.com/codycon1/LiftBig.git'
/**
 * Live mirror (Cloudflare Pages Action / git integration historically pointed here).
 * Plain `git push` updates both so production always receives codycon1's main.
 */
const LIVE_MIRROR = 'https://github.com/4vpvjyx4wr-star/LiftBig.git'

// 1. Route git hooks to the version-controlled .githooks dir.
git('config core.hooksPath .githooks', { stdio: 'inherit' })

// 2. Ensure `origin` fetch URL is always codycon1/LiftBig.
const originUrl = tryGit('remote get-url origin')
if (!originUrl) {
  tryGit(`remote add origin ${CODYCON_ORIGIN}`)
} else if (!originUrl.includes('codycon1/LiftBig')) {
  git(`remote set-url origin ${CODYCON_ORIGIN}`, { stdio: 'inherit' })
}

// 3. Plain `git push` defaults to origin.
git('config push.default current', { stdio: 'inherit' })
git('config remote.pushDefault origin', { stdio: 'inherit' })

// 4. origin pushes to BOTH remotes (codycon1 first, then live mirror).
//    Clear any prior push URLs by resetting origin, then add both push targets.
git(`remote set-url origin ${CODYCON_ORIGIN}`, { stdio: 'inherit' })
tryGit(`remote set-url --add --push origin ${CODYCON_ORIGIN}`)
tryGit(`remote set-url --add --push origin ${LIVE_MIRROR}`)

const branch = tryGit('rev-parse --abbrev-ref HEAD')
if (branch && branch !== 'HEAD') {
  git(`config branch.${branch}.remote origin`, { stdio: 'inherit' })
  git(`config branch.${branch}.merge refs/heads/${branch}`, { stdio: 'inherit' })
}

// 5. Keep `upstream` pointing at the live mirror for fetch/manual use.
const remotes = (tryGit('remote') ?? '').split('\n').filter(Boolean)
if (remotes.includes('upstream')) {
  tryGit(`remote set-url upstream ${LIVE_MIRROR}`)
  tryGit(`remote set-url --push upstream ${LIVE_MIRROR}`)
} else {
  tryGit(`remote add upstream ${LIVE_MIRROR}`)
}
