// Instruments (or restores) Glimmer's validator in the production build's
// template chunk (site/dist/assets/template-*.js):
//   globalThis.__tc  every tag compute ([TAG_COMPUTE] of MonomorphicTag)
//   globalThis.__rc  every re-walk (the `lastChecked !== $REVISION` branch)
//   globalThis.__dc  every tracked write (dirtyTag); with globalThis.__rec
//                    set, its stack goes to globalThis.__stacks
//
//   node instrument.mjs apply   [site/dist]   (keeps the original as *.orig)
//   node instrument.mjs restore [site/dist]
import {
  readdirSync,
  readFileSync,
  writeFileSync,
  existsSync,
  renameSync
} from 'node:fs';
import { join } from 'node:path';

const [
  mode,
  dist = new URL('../../../../site/dist', import.meta.url).pathname
] = process.argv.slice(2);
const dir = join(dist, 'assets');
const chunks = readdirSync(dir).filter((f) =>
  /^template-(?!only).*\.js$/.test(f)
);
if (chunks.length !== 1)
  throw new Error(
    `expected one template-*.js chunk in ${dir}, found ${chunks.join(', ') || 'none'}`
  );
const file = join(dir, chunks[0]);
const orig = file + '.orig';

if (mode === 'restore') {
  if (!existsSync(orig)) throw new Error(`no ${orig}: nothing to restore`);
  renameSync(orig, file);
  console.log('restored', file);
} else if (mode === 'apply') {
  if (existsSync(orig))
    throw new Error(`${orig} exists: already instrumented (restore first)`);
  const src = readFileSync(file, 'utf8');
  let out = src;
  const swap = (re, fn, what) => {
    const hits = out.match(new RegExp(re.source, 'g')) || [];
    if (hits.length !== 1)
      throw new Error(`${what}: ${hits.length} matches, expected 1`);
    out = out.replace(re, fn);
  };
  // the compute: `[O](){let{lastChecked:e}=this;`
  swap(
    /\[(\w+)\]\(\)\{let\{lastChecked:(\w+)\}=this;/,
    (m) => m.replace('{let', '{globalThis.__tc=(globalThis.__tc|0)+1;let'),
    'tag compute'
  );
  // the re-walk: `else if(e!==D){this.isUpdating=!0`
  swap(
    /else if\((\w+)!==(\w+)\)\{this\.isUpdating=!0/,
    (m) => m.replace('{this.', '{globalThis.__rc=(globalThis.__rc|0)+1;this.'),
    're-walk'
  );
  // the write: `static dirtyTag(e,t){`
  swap(
    /static dirtyTag\((\w+),(\w+)\)\{/,
    (m) =>
      m +
      'globalThis.__dc=(globalThis.__dc|0)+1;if(globalThis.__rec)globalThis.__stacks.push(new Error().stack);',
    'dirtyTag'
  );
  // counters exist from the start (count-tags.js checks for them)
  out = 'globalThis.__tc=0;globalThis.__rc=0;globalThis.__dc=0;\n' + out;
  writeFileSync(orig, src);
  writeFileSync(file, out);
  console.log('instrumented', file);
} else {
  console.error('usage: node instrument.mjs apply|restore [site/dist]');
  process.exit(2);
}
