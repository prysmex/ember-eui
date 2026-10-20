/**
 * Measures what importing an ember-eui module costs a consuming app.
 *
 * Builds the entries in site/size-probe/ as one production Vite + Embroider
 * app (minified, like a consumer's `vite build`) and reports, for each entry,
 * the bytes of its chunk plus every chunk it imports statically: what the
 * browser must load before the entry runs. Chunks it only imports
 * dynamically (`import()`) are listed separately as "lazy". The `baseline`
 * entry (Ember alone) is subtracted, so the numbers are ember-eui's share.
 *
 *   pnpm build:packages                       build the packages first
 *   node scripts/measure-bundle-size.mjs      print the table
 *   node scripts/measure-bundle-size.mjs --json out.json
 *   node scripts/measure-bundle-size.mjs --modules eui-button
 *                                             largest modules in an entry
 *   … --modules eui-markdown-format --chunk markdown-engine
 *                                             largest modules in its lazy chunk
 */
import {
  mkdirSync,
  readFileSync,
  readdirSync,
  rmSync,
  writeFileSync
} from 'node:fs';
import { createRequire } from 'node:module';
import { tmpdir } from 'node:os';
import { basename, dirname, extname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { gzipSync } from 'node:zlib';
import { execFileSync } from 'node:child_process';

const workspaceDir = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const siteDir = join(workspaceDir, 'site');
const probeDir = join(siteDir, 'size-probe');
const outDir = join(tmpdir(), 'ember-eui-size-probe');
const require = createRequire(join(siteDir, 'package.json'));

const args = process.argv.slice(2);
const jsonOut = args.includes('--json')
  ? args[args.indexOf('--json') + 1]
  : null;
const modulesOf = args.includes('--modules')
  ? args[args.indexOf('--modules') + 1]
  : null;
// with --modules: list the modules of the (lazy) chunks whose file name
// contains this instead of the entry's static graph
const chunkOf = args.includes('--chunk') ? args[args.indexOf('--chunk') + 1] : null;

// the site consumes the packages as injected copies (pnpm-workspace.yaml)
if (!args.includes('--entry'))
  execFileSync('node', [join(workspaceDir, 'scripts/sync-injected.mjs')], {
    stdio: 'ignore'
  });

const { build } = await import(require.resolve('vite'));
const { ember, extensions } = await import(require.resolve('@embroider/vite'));
const { babel } = await import(require.resolve('@rollup/plugin-babel'));
const { buildMacros } = require('@embroider/macros/babel');
const macros = buildMacros();

const entries = Object.fromEntries(
  readdirSync(probeDir)
    .filter((file) => /\.(gjs|js)$/.test(file))
    .map((file) => [basename(file, extname(file)), join(probeDir, file)])
);

// Embroider reads the app (site/package.json) from the working directory
process.chdir(siteDir);

/**
 * Builds one entry on its own, so chunks shared with other entries cannot
 * hide or inflate its cost.
 */
async function buildEntry(name) {
  const dir = join(outDir, name);
  const moduleSizes = new Map();
  await build({
    configFile: false,
    root: probeDir,
    logLevel: 'error',
    mode: 'production',
    plugins: [
      {
        // The site sees some packages as symlinks and others as injected
        // copies, each with its own @ember-eui/core. Resolve every
        // @ember-eui import from the site root, as one copy, like an app.
        name: 'one-ember-eui',
        enforce: 'pre',
        resolveId(id) {
          if (id.startsWith('@ember-eui/')) return require.resolve(id);
        }
      },
      ember(),
      babel({
        babelHelpers: 'inline',
        extensions,
        babelrc: false,
        configFile: false,
        plugins: [
          [
            require.resolve('@babel/plugin-transform-typescript'),
            {
              allExtensions: true,
              onlyRemoveTypeImports: true,
              allowDeclareFields: true
            }
          ],
          [
            require.resolve('babel-plugin-ember-template-compilation'),
            { transforms: [...macros.templateMacros] }
          ],
          [
            require.resolve('decorator-transforms'),
            {
              runtime: {
                import: require.resolve('decorator-transforms/runtime-esm')
              }
            }
          ],
          ...macros.babelMacros
        ]
      }),
      {
        name: 'record-module-sizes',
        generateBundle(_options, bundle) {
          for (const chunk of Object.values(bundle)) {
            if (chunk.type !== 'chunk') continue;
            for (const [id, info] of Object.entries(chunk.modules)) {
              moduleSizes.set(id, {
                chunk: chunk.fileName,
                bytes: info.renderedLength
              });
            }
          }
        }
      }
    ],
    build: {
      outDir: dir,
      emptyOutDir: true,
      manifest: true,
      chunkSizeWarningLimit: Infinity,
      rolldownOptions: {
        input: { [name]: entries[name] },
        preserveEntrySignatures: false
      }
    }
  });

  const manifest = JSON.parse(
    readFileSync(join(dir, '.vite/manifest.json'), 'utf8')
  );
  const sizeOf = (file) => {
    const contents = readFileSync(join(dir, file));
    return { raw: contents.length, gzip: gzipSync(contents).length };
  };
  const graph = new Set();
  const walk = (key) => {
    if (graph.has(key)) return;
    graph.add(key);
    for (const dep of manifest[key].imports ?? []) walk(dep);
  };
  walk(Object.keys(manifest).find((k) => manifest[k].isEntry));
  const files = [...graph].map((k) => manifest[k].file);
  const lazy = new Set();
  for (const k of graph) {
    for (const dep of manifest[k].dynamicImports ?? []) {
      if (!graph.has(dep)) lazy.add(manifest[dep].file);
    }
  }
  const total = files
    .map(sizeOf)
    .reduce((sum, s) => ({ raw: sum.raw + s.raw, gzip: sum.gzip + s.gzip }), {
      raw: 0,
      gzip: 0
    });
  const modules = [...moduleSizes].filter(([, m]) => files.includes(m.chunk));
  const allModules = [...moduleSizes];
  return { total, lazyChunks: lazy.size, modules, allModules };
}

// `--entry <name>` (internal): build one entry and print its result. Each
// entry builds in its own process; one process for all of them runs out of
// memory on small machines.
if (args.includes('--entry')) {
  const name = args[args.indexOf('--entry') + 1];
  const result = await buildEntry(name);
  writeFileSync(join(outDir, `${name}.json`), JSON.stringify(result));
  process.exit(0);
}

rmSync(outDir, { recursive: true, force: true });
mkdirSync(outDir, { recursive: true });
const results = {};
for (const name of Object.keys(entries)) {
  execFileSync(
    process.execPath,
    [fileURLToPath(import.meta.url), '--entry', name],
    {
      stdio: ['ignore', 'ignore', 'inherit']
    }
  );
  results[name] = JSON.parse(
    readFileSync(join(outDir, `${name}.json`), 'utf8')
  );
}
const baseline = results.baseline;

const kb = (n) => (n / 1024).toFixed(1).padStart(7);
const rows = {};
console.log(
  `${'entry'.padEnd(24)} ${'static KB'.padStart(9)} ${'gzip KB'.padStart(8)}  lazy chunks`
);
for (const name of Object.keys(entries).sort()) {
  if (name === 'baseline') continue;
  const { total, lazyChunks } = results[name];
  const raw = total.raw - baseline.total.raw;
  const gzip = total.gzip - baseline.total.gzip;
  rows[name] = { raw, gzip, lazyChunks };
  console.log(
    `${name.padEnd(24)} ${kb(raw)}  ${kb(gzip)}  ${String(lazyChunks).padStart(5)}`
  );
}
console.log(
  `(minus baseline: Ember alone, ${kb(baseline.total.raw).trim()} KB / ${kb(baseline.total.gzip).trim()} KB gzip)`
);

if (modulesOf) {
  const baselineIds = new Set(baseline.modules.map(([id]) => id));
  const own = (
    chunkOf
      ? results[modulesOf].allModules.filter(([, m]) => m.chunk.includes(chunkOf))
      : results[modulesOf].modules
  )
    .filter(([id]) => !baselineIds.has(id))
    .sort((a, b) => b[1].bytes - a[1].bytes)
    .slice(0, Number(process.env.SIZE_TOP ?? 40));
  console.log(
    `\nlargest modules loaded by ${modulesOf} (rendered bytes, before minify):`
  );
  for (const [id, m] of own) {
    console.log(
      `${kb(m.bytes)}  ${id.replace(/.*node_modules\//, '').replace(workspaceDir + '/', '')}`
    );
  }
}

if (jsonOut)
  writeFileSync(
    resolve(workspaceDir, jsonOut),
    JSON.stringify(rows, null, 2) + '\n'
  );
