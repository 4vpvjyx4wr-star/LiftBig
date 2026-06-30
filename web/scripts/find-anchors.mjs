import { readFileSync } from 'node:fs';

const s = readFileSync('/workspace/dist/assets/LibraryBrowser-BlmrAKrd.js', 'utf8');
const i = s.indexOf('let X=c(()=>{');
console.log('X index', i);
const needle = '],8,oe),m(`button`,{type:`button`,class:`absolute bottom-2 right-2';
const j = s.indexOf(needle);
console.log('tile close index', j);
if (j >= 0) console.log(s.slice(j - 150, j + needle.length + 40));
