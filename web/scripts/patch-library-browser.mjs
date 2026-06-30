/**
 * Patches the production LibraryBrowser chunk to show Max/Avg on each tile.
 */
import { readFileSync, writeFileSync } from 'node:fs';
import { resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import esbuild from 'esbuild';

const __dirname = dirname(fileURLToPath(import.meta.url));
const target = resolve(__dirname, '../../dist/assets/LibraryBrowser-BlmrAKrd.js');

let source = readFileSync(target, 'utf8');

const helperFns = `
function formatTileMax(exercise){
  const stats=H(exercise);
  if(exercise.isCardio)return stats.maxDurationMinutes==null?"—":\`\${stats.maxDurationMinutes} min\`;
  if(!stats.maxSet)return"—";
  return\`\${C(stats.maxSet.weightLbs,N.value,1)} x \${stats.maxSet.reps}\`;
}
function formatTileAvg(exercise){
  const stats=H(exercise);
  if(exercise.isCardio)return"—";
  if(!stats.avgSet)return"—";
  return\`\${C(stats.avgSet.weightLbs,N.value,1)} x \${stats.avgSet.reps}\`;
}`;

const setupAnchor = 'let X=c(()=>{';
const setupIndex = source.indexOf(setupAnchor);
if (setupIndex === -1) {
  throw new Error('Could not find LibraryBrowser setup anchor');
}

source = source.slice(0, setupIndex) + helperFns + source.slice(setupIndex);

const tagsClose =
  ')),128))])],8,oe),m(`button`,{type:`button`,class:`absolute bottom-2 right-2';
const statsBlock =
  ')),128))]),m(`div`,{class:`mt-2 flex items-center gap-4 border-t border-border/60 pt-2 pr-6 text-[10px] leading-tight`},[m(`span`,null,[m(`span`,{class:`font-bold uppercase tracking-wide text-muted`},`Max`),d(` `),m(`span`,{class:`ml-1 font-semibold text-foreground`},r(formatTileMax(n)),1)]),m(`span`,null,[m(`span`,{class:`font-bold uppercase tracking-wide text-muted`},`Avg`),d(` `),m(`span`,{class:`ml-1 font-semibold text-foreground`},r(formatTileAvg(n)),1)])])],8,oe),m(`button`,{type:`button`,class:`absolute bottom-2 right-2';

if (!source.includes(tagsClose)) {
  throw new Error('Could not find LibraryBrowser tile close anchor');
}

source = source.replace(tagsClose, statsBlock);

const result = await esbuild.transform(source, {
  minify: true,
  format: 'esm',
  target: 'es2020',
});

writeFileSync(target, result.code);
console.log('Patched LibraryBrowser-BlmrAKrd.js with Max/Avg tile stats');
