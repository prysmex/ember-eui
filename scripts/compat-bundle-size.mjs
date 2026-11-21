/**
 * `pnpm size --compat`: what ember-eui costs an app built the way the
 * standard blueprint (@ember/app-blueprint) builds one, and a check that
 * the sheet stays out of a host's bundle until the host imports it.
 *
 * measure-bundle-size.mjs builds entries that import a module directly; an
 * app from the blueprint also boots through `@embroider/virtual/compat-
 * modules` (`Resolver.withModules(compatModules)`, `loadInitializers`),
 * which pulls in the addons' `app-js` modules that are not components,
 * helpers or modifiers (services, initializers, ...) and, with
 * `staticInvokables: false`, every app-js component, helper and modifier
 * too. Each case here is a small app (index.html, app.ts with
 * compatModules, a router, one .gts or .hbs application template) built
 * with `vite build` (production, minified) against the site's
 * node_modules, so it sees the same package versions as the site.
 *
 *   pnpm build:packages                         build the packages first
 *   node scripts/measure-bundle-size.mjs --compat
 *   … --compat --only sheet,sheet-none          some cases only
 *   … --compat --json out.json
 *
 * It exits with 1 when a check fails (see CHECKS below).
 */
import {
  mkdirSync,
  readFileSync,
  readdirSync,
  rmSync,
  symlinkSync,
  writeFileSync
} from 'node:fs';
import { tmpdir } from 'node:os';
import { join, resolve } from 'node:path';
import { gzipSync } from 'node:zlib';
import { execFileSync } from 'node:child_process';

const eui = [
  '@ember-eui/core',
  'ember-basic-dropdown',
  'ember-concurrency',
  'ember-focus-trap',
  'ember-power-select',
  'moment'
];
const sheet = [...eui, '@ember-eui/sheet'];

/**
 * deps: what the app installs besides the blueprint's own; gts: the
 * application template's imports and body; hbs: a loose-mode application
 * template instead; files: extra app files; dynamic: `staticInvokables:
 * false` in ember-cli-build.
 */
const CASES = {
  bare: { deps: [], gts: ['', ''] },
  'core-none': { deps: eui, gts: ['', ''] },
  'core-button': {
    deps: eui,
    gts: [
      "import EuiButton from '@ember-eui/core/components/eui-button';",
      '<EuiButton>hi</EuiButton>'
    ]
  },
  'sheet-none': { deps: sheet, gts: ['', ''] },
  sheet: {
    deps: sheet,
    gts: [
      "import { EuiSheet } from '@ember-eui/sheet';",
      '<EuiSheet @fields={{array}} @records={{array}} />'
    ]
  },
  'sheet-import': {
    deps: sheet,
    gts: [
      "import { EuiSheet, EuiSheetImport } from '@ember-eui/sheet';",
      '<EuiSheet @fields={{array}} @records={{array}} /><EuiSheetImport @fields={{array}} />'
    ]
  },
  // loose mode, the opt-in way: the host re-exports the component into its
  // own app tree (docs/sheet.md, "Loose-mode templates")
  'sheet-loose-host': {
    deps: sheet,
    hbs: '<EuiSheet @fields={{array}} @records={{array}} />',
    files: {
      'app/components/eui-sheet.js':
        "export { default } from '@ember-eui/sheet/components/eui-sheet';\n"
    }
  },
  // `staticInvokables: false`: every app-js component, helper and modifier
  // is in compatModules
  'dynamic-core-none': { deps: eui, gts: ['', ''], dynamic: true },
  'dynamic-sheet-none': { deps: sheet, gts: ['', ''], dynamic: true }
};

// the blueprint's devDependencies that a probe app needs
const blueprintDeps = [
  '@babel/core',
  '@babel/plugin-transform-runtime',
  '@babel/plugin-transform-typescript',
  '@babel/runtime',
  '@ember/optional-features',
  '@ember/string',
  '@ember/test-waiters',
  '@embroider/compat',
  '@embroider/config-meta-loader',
  '@embroider/core',
  '@embroider/legacy-inspector-support',
  '@embroider/macros',
  '@embroider/router',
  '@embroider/vite',
  '@glimmer/component',
  '@rollup/plugin-babel',
  'babel-plugin-ember-template-compilation',
  'decorator-transforms',
  'ember-cli',
  'ember-cli-babel',
  'ember-load-initializers',
  'ember-modifier',
  'ember-page-title',
  'ember-resolver',
  'ember-source',
  'vite'
];

// the blueprint's files (@ember/app-blueprint 7.3, TypeScript, no
// WarpDrive, no welcome page), trimmed to what a build reads
const appFiles = (c) => ({
  'ember-cli-build.mjs': `import EmberApp from 'ember-cli/lib/broccoli/ember-app.js';
import { compatBuild } from '@embroider/compat';

export default async function (defaults) {
  const { buildOnce } = await import('@embroider/vite');
  const app = new EmberApp(defaults, {});
  return compatBuild(app, buildOnce${c.dynamic ? ', { staticInvokables: false }' : ''});
}
`,
  'babel.config.mjs': `import { dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { babelCompatSupport, templateCompatSupport } from '@embroider/compat/babel';

export default {
  plugins: [
    ['@babel/plugin-transform-typescript', { allExtensions: true, onlyRemoveTypeImports: true, allowDeclareFields: true }],
    ['babel-plugin-ember-template-compilation', {
      enableLegacyModules: ['ember-cli-htmlbars', 'ember-cli-htmlbars-inline-precompile', 'htmlbars-inline-precompile'],
      transforms: [...templateCompatSupport()],
    }],
    ['module:decorator-transforms', { runtime: { import: fileURLToPath(import.meta.resolve('decorator-transforms/runtime-esm')) } }],
    ['@babel/plugin-transform-runtime', { absoluteRuntime: dirname(fileURLToPath(import.meta.url)), useESModules: true, regenerator: false }],
    ...babelCompatSupport(),
  ],
  generatorOpts: { compact: false },
};
`,
  // record-modules: which modules each chunk holds, for the checks
  'vite.config.mjs': `import { writeFileSync } from 'node:fs';
import { defineConfig } from 'vite';
import { extensions, classicEmberSupport, ember } from '@embroider/vite';
import { babel } from '@rollup/plugin-babel';

export default defineConfig({
  plugins: [
    classicEmberSupport(),
    ember(),
    babel({ babelHelpers: 'runtime', extensions }),
    {
      name: 'record-modules',
      generateBundle(_options, bundle) {
        const chunks = {};
        for (const chunk of Object.values(bundle)) {
          if (chunk.type !== 'chunk') continue;
          chunks[chunk.fileName] = { isEntry: chunk.isEntry, imports: chunk.imports, modules: Object.keys(chunk.modules) };
        }
        writeFileSync('modules.json', JSON.stringify(chunks));
      },
    },
  ],
  build: {
    chunkSizeWarningLimit: Infinity,
    // with staticInvokables: false, core's app-js re-exports a default
    // from four modules that have none (eui-data-grid/cell-actions,
    // row-tree-hooks, eui-super-date-picker/utils/pretty-interval,
    // time-window), which fails the build; shim them to measure the rest
    ${c.dynamic ? "rolldownOptions: { shimMissingExports: true, external: ['ember'] }," : ''}
  },
});
`,
  'index.html': `<!DOCTYPE html>
<html>
  <head>
    <meta charset="utf-8">
    <title>probe</title>
    {{content-for "head"}}
    <link integrity="" rel="stylesheet" href="/@embroider/virtual/vendor.css">
    <link integrity="" rel="stylesheet" href="/@embroider/virtual/app.css">
    {{content-for "head-footer"}}
  </head>
  <body>
    {{content-for "body"}}
    <script src="/@embroider/virtual/vendor.js"></script>
    <script type="module">
      import Application from './app/app';
      import environment from './app/config/environment';

      Application.create(environment.APP);
    </script>
    {{content-for "body-footer"}}
  </body>
</html>
`,
  'config/environment.js': `'use strict';

module.exports = function (environment) {
  return {
    modulePrefix: 'probe',
    environment,
    rootURL: '/',
    locationType: 'history',
    EmberENV: { EXTEND_PROTOTYPES: false, FEATURES: {} },
    APP: {},
  };
};
`,
  'config/optional-features.json': JSON.stringify({
    'application-template-wrapper': false,
    'default-async-observers': true,
    'jquery-integration': false,
    'template-only-glimmer-components': true,
    'no-implicit-route-model': true
  }),
  'config/targets.js': `'use strict';

module.exports = {
  browsers: ['last 1 Chrome versions', 'last 1 Firefox versions', 'last 1 Safari versions'],
};
`,
  'app/app.ts': `import Application from '@ember/application';
import compatModules from '@embroider/virtual/compat-modules';
import Resolver from 'ember-resolver';
import loadInitializers from 'ember-load-initializers';
import config from 'probe/config/environment';
import setupInspector from '@embroider/legacy-inspector-support/ember-source-4.12';

export default class App extends Application {
  modulePrefix = config.modulePrefix;
  podModulePrefix = config.podModulePrefix;
  Resolver = Resolver.withModules(compatModules);
  inspector = setupInspector(this);
}

loadInitializers(App, config.modulePrefix, compatModules);
`,
  'app/config/environment.ts': `import loadConfigFromMeta from '@embroider/config-meta-loader';

export default loadConfigFromMeta('probe') as {
  modulePrefix: string;
  podModulePrefix?: string;
  locationType: string;
  rootURL: string;
  APP: Record<string, unknown>;
};
`,
  'app/router.ts': `import EmberRouter from '@embroider/router';
import config from 'probe/config/environment';

export default class Router extends EmberRouter {
  location = config.locationType;
  rootURL = config.rootURL;
}

Router.map(function () {});
`,
  'app/styles/app.css': '',
  ...(c.hbs
    ? {
        'app/templates/application.hbs': `<h2>probe</h2>${c.hbs}{{outlet}}\n`
      }
    : {
        'app/templates/application.gts': `import { pageTitle } from 'ember-page-title';
import { array } from '@ember/helper';
${c.gts[0]}

<template>
  {{pageTitle "probe"}}
  <h2>probe</h2>
  ${c.gts[1]}
  {{outlet}}
</template>
`
      }),
  ...c.files
});

/** The checks: each returns a list of failures. */
const CHECKS = {
  // installing the sheet adds nothing to an app that does not use it
  'sheet-none': (r) => absent(r, 'all', SHEET, 'sheet modules'),
  'dynamic-sheet-none': (r) => absent(r, 'all', SHEET, 'sheet modules'),
  // positive control: the dynamic mode does put app-js components in
  'dynamic-core-none': (r) =>
    r.coreAppJsComponents.static > 300
      ? []
      : [
          `only ${r.coreAppJsComponents.static} of core's app-js components (expected all)`
        ],
  sheet: (r) => [
    ...present(r, 'static', /\/components\/eui-sheet\.js$/, '<EuiSheet>'),
    ...(r.sheetModules.static > 50
      ? []
      : [`only ${r.sheetModules.static} sheet modules`]),
    ...absent(
      r,
      'static',
      /\/components\/eui-sheet-import\.js$|\/-private\/import\//,
      'the import screen'
    ),
    ...absent(r, 'static', /barcode-scan-panel/, 'the barcode scan panel'),
    ...present(r, 'all', /barcode-scan-panel/, 'the lazy barcode scan panel')
  ],
  'sheet-import': (r) =>
    present(
      r,
      'static',
      /\/components\/eui-sheet-import\.js$/,
      '<EuiSheetImport>'
    ),
  'sheet-loose-host': (r) =>
    present(r, 'static', /\/components\/eui-sheet\.js$/, '<EuiSheet>')
};

// the packages' files, as a symlink (packages/sheet) or an injected copy
// (node_modules/@ember-eui/sheet) resolves them
const SHEET = /(?:packages\/sheet|@ember-eui\/sheet)\/dist\//;
const CORE = /(?:packages\/core|@ember-eui\/core)\/dist\//;

function absent(r, where, re, what) {
  const found = r.modules[where].filter((id) => re.test(id));
  return found.length
    ? [
        `${what} in the ${where === 'all' ? 'bundle' : 'static graph'}: ${found.slice(0, 3).join(', ')}${found.length > 3 ? ` and ${found.length - 3} more` : ''}`
      ]
    : [];
}

function present(r, where, re, what) {
  return r.modules[where].some((id) => re.test(id))
    ? []
    : [`${what} not in the ${where === 'all' ? 'bundle' : 'static graph'}`];
}

function makeApp(dir, siteDir, sitePkg, c) {
  rmSync(dir, { recursive: true, force: true });
  mkdirSync(join(dir, 'node_modules'), { recursive: true });
  // the site's packages, one link each (Embroider writes its own
  // node_modules/.embroider here, not in the site's)
  for (const entry of readdirSync(join(siteDir, 'node_modules'))) {
    if (entry.startsWith('.')) continue;
    symlinkSync(
      join(siteDir, 'node_modules', entry),
      join(dir, 'node_modules', entry)
    );
  }
  const devDependencies = {};
  for (const dep of [...blueprintDeps, ...c.deps]) {
    devDependencies[dep] = sitePkg.devDependencies[dep] ?? '*';
  }
  const files = {
    'package.json': JSON.stringify({
      name: 'probe',
      version: '0.0.0',
      private: true,
      exports: { './tests/*': './tests/*', './*': './app/*' },
      devDependencies,
      ember: { edition: 'octane' }
    }),
    ...appFiles(c)
  };
  for (const [path, contents] of Object.entries(files)) {
    mkdirSync(join(dir, path, '..'), { recursive: true });
    writeFileSync(join(dir, path), contents);
  }
}

function analyze(dir) {
  const chunks = JSON.parse(readFileSync(join(dir, 'modules.json'), 'utf8'));
  const graph = new Set();
  const walk = (file) => {
    if (graph.has(file) || !chunks[file]) return;
    graph.add(file);
    for (const dep of chunks[file].imports) walk(dep);
  };
  for (const file of Object.keys(chunks)) if (chunks[file].isEntry) walk(file);
  const bytes = (files) =>
    files
      .map((file) => readFileSync(join(dir, 'dist', file)))
      .reduce(
        (sum, b) => ({
          raw: sum.raw + b.length,
          gzip: sum.gzip + gzipSync(b).length
        }),
        { raw: 0, gzip: 0 }
      );
  const ids = (files) => [
    ...new Set(
      files.flatMap((file) =>
        chunks[file].modules.map((id) => id.replace(/\?.*$/, ''))
      )
    )
  ];
  const modules = { static: ids([...graph]), all: ids(Object.keys(chunks)) };
  const count = (re) => ({
    static: modules.static.filter((id) => re.test(id)).length,
    all: modules.all.filter((id) => re.test(id)).length
  });
  return {
    static: bytes([...graph]),
    all: bytes(Object.keys(chunks)),
    lazyChunks: Object.keys(chunks).length - graph.size,
    modules,
    sheetModules: count(SHEET),
    coreModules: count(CORE),
    coreAppJsComponents: count(
      /(?:packages\/core|@ember-eui\/core)\/dist\/_app_\/components\//
    )
  };
}

export async function runCompat({ workspaceDir, siteDir, args }) {
  const sitePkg = JSON.parse(
    readFileSync(join(siteDir, 'package.json'), 'utf8')
  );
  const only = args.includes('--only')
    ? args[args.indexOf('--only') + 1].split(',')
    : null;
  const jsonOut = args.includes('--json')
    ? args[args.indexOf('--json') + 1]
    : null;
  const root = join(tmpdir(), 'ember-eui-compat-probe');
  const vite = join(siteDir, 'node_modules/vite/bin/vite.js');
  const results = {};
  for (const [name, c] of Object.entries(CASES)) {
    if (only && !only.includes(name) && name !== 'bare') continue;
    const dir = join(root, name);
    makeApp(dir, siteDir, sitePkg, { files: {}, ...c });
    execFileSync(process.execPath, [vite, 'build', '--logLevel', 'error'], {
      cwd: dir,
      stdio: ['ignore', 'ignore', 'inherit']
    });
    results[name] = analyze(dir);
  }

  const kb = (n) => (n / 1024).toFixed(1).padStart(8);
  const bare = results.bare;
  console.log(
    `${'compat app'.padEnd(20)} ${'static KB'.padStart(9)} ${'gzip KB'.padStart(8)}  lazy  sheet mods  core app-js components`
  );
  const rows = {};
  const failures = [];
  for (const [name, r] of Object.entries(results)) {
    const raw = r.static.raw - bare.static.raw;
    const gzip = r.static.gzip - bare.static.gzip;
    rows[name] = {
      raw,
      gzip,
      lazyChunks: r.lazyChunks,
      sheetModules: r.sheetModules,
      coreAppJsComponents: r.coreAppJsComponents.static
    };
    console.log(
      `${name.padEnd(20)} ${kb(raw)} ${kb(gzip)}  ${String(r.lazyChunks).padStart(4)}  ${String(r.sheetModules.static).padStart(10)}  ${String(r.coreAppJsComponents.static).padStart(5)}`
    );
    for (const failure of CHECKS[name]?.(r) ?? [])
      failures.push(`${name}: ${failure}`);
  }
  console.log(
    `(minus a blueprint app without ember-eui, ${kb(bare.static.raw).trim()} KB / ${kb(bare.static.gzip).trim()} KB gzip; static graph from index.html)`
  );
  if (jsonOut) {
    writeFileSync(
      resolve(workspaceDir, jsonOut),
      JSON.stringify(rows, null, 2) + '\n'
    );
  }
  if (failures.length) {
    console.error(
      `\n${failures.length} check(s) failed:\n  ${failures.join('\n  ')}`
    );
    return 1;
  }
  console.log(
    `\nchecks passed (${Object.keys(CHECKS)
      .filter((n) => n in results)
      .join(', ')})`
  );
  return 0;
}
