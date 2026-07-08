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

// 1. Route git hooks to the version-controlled .githooks dir (Node-based, no shell needed).
git('config core.hooksPath .githooks', { stdio: 'inherit' })

// 2. Make pushes default to `origin` so every clone (PC, mobile, cloud agents) targets the
//    same remote (codycon1). Remotes live in .git/config per clone, so this only takes effect
//    wherever `npm install` runs — but it keeps environments consistent when it does.
const remotes = (tryGit('remote') ?? '').split('\n').filter(Boolean)
if (remotes.includes('origin')) {
  git('config push.default current', { stdio: 'inherit' })
  git('config remote.pushDefault origin', { stdio: 'inherit' })

  // 3. Ensure the current branch tracks origin so plain `git push` has a destination.
  const branch = tryGit('rev-parse --abbrev-ref HEAD')
  if (branch && branch !== 'HEAD' && !tryGit(`config branch.${branch}.remote`)) {
    tryGit(`branch --set-upstream-to=origin/${branch} ${branch}`)
  }
}
