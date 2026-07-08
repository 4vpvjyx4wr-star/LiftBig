import { execSync } from 'node:child_process'
import path from 'node:path'
import { fileURLToPath } from 'node:url'

const repoRoot = execSync('git rev-parse --show-toplevel', {
  cwd: path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..'),
  encoding: 'utf8',
}).trim()

execSync('git config core.hooksPath .githooks', {
  cwd: repoRoot,
  stdio: 'inherit',
})
