/**
 * Downloads the current production static assets into dist/, then web/ patches
 * library stats modules on top. Used before deploy when dist is not fully committed.
 */
import { mkdirSync, writeFileSync } from 'node:fs';
import { resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { execSync } from 'node:child_process';

const __dirname = dirname(fileURLToPath(import.meta.url));
const root = resolve(__dirname, '..');
const dist = resolve(root, 'dist');
const assets = resolve(dist, 'assets');
const base = process.env.LIFTBIG_SITE_URL ?? 'https://liftbig.julianmcgookin.com';

mkdirSync(assets, { recursive: true });

const rootFiles = ['index.html', 'manifest.webmanifest', 'favicon.ico'];
for (const file of rootFiles) {
  execSync(`curl -sL "${base}/${file}" -o "${resolve(dist, file)}"`, { stdio: 'inherit' });
}

const assetFiles = [
  'index-BSsajrYB.js',
  'injectionKeys-DWh5N0Cf.js',
  'workout-Dl4ULJf6.js',
  'exerciseLibrary-PHUUbGWG.js',
  'dateKey-CYtjlmzc.js',
  'libraryExerciseTracking-CAhSe-yn.js',
  'LibraryBrowser-BlmrAKrd.js',
  'LibraryView-C9pT185x.js',
  'storage-C0QXLldy.js',
  'units-D1Q8qPMV.js',
  'index-ByXYs5NQ.css',
  'HomeView-CFy1GvNj.js',
  'supersetUtils-D1vwCCtv.js',
  'circuitExerciseDisplay-Bc9lUPh6.js',
  'PlansView-KGOBIOAV.js',
  'cardioDistance-D2Q8e3gp.js',
  'distances-CEE45Vcb.js',
  'PlatesView-Ke-aOwFX.js',
  'OneRepMaxView-BeToUvIi.js',
  'ProgressView-BlOYqEIp.js',
  'AchievementsView-D-RdmouN.js',
  'WorkoutLogView-DFrj8r89.js',
  'notifications-C-hkQ0jB.js',
];

for (const file of assetFiles) {
  execSync(`curl -sL "${base}/assets/${file}" -o "${resolve(assets, file)}"`, { stdio: 'inherit' });
}

writeFileSync(resolve(assets, 'LibraryBrowser-BlmrAKrd.js.orig'), '');
execSync(`cp "${resolve(assets, 'LibraryBrowser-BlmrAKrd.js')}" "${resolve(assets, 'LibraryBrowser-BlmrAKrd.js.orig')}"`);
writeFileSync(resolve(dist, '_redirects'), '/*    /index.html   200\n');

console.log(`Synced production assets from ${base}`);
