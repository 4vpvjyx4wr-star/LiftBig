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

/** Owner repo. Pushes stay here so this account can edit from Cursor on other devices. */
const OWNER_ORIGIN = 'https://github.com/4vpvjyx4wr-star/LiftBig.git'

// Route git hooks to the version-controlled .githooks dir.
git('config core.hooksPath .githooks', { stdio: 'inherit' })

// Never point origin at codycon1. That remote rejected edits from this account.
const originUrl = tryGit('remote get-url origin')
if (!originUrl) {
  git(`remote add origin ${OWNER_ORIGIN}`, { stdio: 'inherit' })
} else if (originUrl.includes('codycon1/LiftBig')) {
  git(`remote set-url origin ${OWNER_ORIGIN}`, { stdio: 'inherit' })
  tryGit('remote set-url --delete --push origin')
}

const pushUrls = (tryGit('remote get-url --push --all origin') ?? '')
  .split('\n')
  .map((url) => url.trim())
  .filter(Boolean)
for (const url of pushUrls) {
  if (url.includes('codycon1/LiftBig')) {
    tryGit(`remote set-url --delete --push origin ${url}`)
  }
}
