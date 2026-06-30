/**
 * Writes dist/version.json and bumps sw.js so installed PWAs pick up new assets.
 */
import { readFileSync, writeFileSync, existsSync } from 'node:fs';
import { resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { execSync } from 'node:child_process';

const __dirname = dirname(fileURLToPath(import.meta.url));
const dist = resolve(__dirname, '../dist');
const version = process.env.DIST_VERSION ?? new Date().toISOString();
const gitSha = process.env.GITHUB_SHA?.slice(0, 7) ?? execSync('git rev-parse --short HEAD', { encoding: 'utf8' }).trim();

const payload = {
  version,
  gitSha,
  features: ['library-tile-max-avg'],
};

writeFileSync(resolve(dist, 'version.json'), `${JSON.stringify(payload, null, 2)}\n`);

const swPath = resolve(dist, 'sw.js');
if (existsSync(swPath)) {
  let sw = readFileSync(swPath, 'utf8');
  sw = sw.replace(/\/\* liftbig-deploy:[^*]*\*\//, '');
  sw = `/* liftbig-deploy:${version} */\n${sw}`;
  writeFileSync(swPath, sw);
}

console.log(`Stamped dist version ${version} (${gitSha})`);
