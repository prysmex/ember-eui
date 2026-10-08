import { readFileSync, writeFileSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import plugin from '@docfy/core/lib/plugin.js';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const read = (path) => readFileSync(resolve(root, path), 'utf8');

// Use the site's build and runtime versions, without its docs or test tooling.
const DEPENDENCIES = [
  '@babel/core',
  '@babel/plugin-transform-runtime',
  '@babel/plugin-transform-typescript',
  '@babel/runtime',
  '@ember/optional-features',
  '@ember/string',
  '@embroider/compat',
  '@embroider/config-meta-loader',
  '@embroider/core',
  '@embroider/vite',
  '@glimmer/component',
  '@rollup/plugin-babel',
  'babel-plugin-ember-template-compilation',
  'decorator-transforms',
  'ember-basic-dropdown',
  'ember-cli',
  'ember-cli-babel',
  'ember-concurrency',
  'ember-focus-trap',
  'ember-load-initializers',
  'ember-power-select',
  'ember-resolver',
  'ember-source',
  'moment',
  'vite',
];

export function starterFiles() {
  const site = JSON.parse(read('package.json'));
  const dependencies = Object.fromEntries(
    DEPENDENCIES.map((name) => [name, site.devDependencies[name]]).filter(
      ([, version]) => version,
    ),
  );
  dependencies['@ember-eui/core'] = JSON.parse(
    read('../packages/core/package.json'),
  ).version;
  const files = {
    'package.json': JSON.stringify(
      {
        name: 'site',
        private: true,
        exports: { './*': './app/*' },
        scripts: { start: 'vite --host 0.0.0.0', build: 'vite build' },
        devDependencies: dependencies,
        ember: { edition: 'octane' },
      },
      null,
      2,
    ),
    'vite.config.mjs': `import { defineConfig } from 'vite';
import { extensions, classicEmberSupport, ember } from '@embroider/vite';
import { babel } from '@rollup/plugin-babel';
export default defineConfig({ plugins: [classicEmberSupport(), ember(), babel({ babelHelpers: 'runtime', extensions: extensions.filter(ext => ext !== '.json') })] });
`,
    'ember-cli-build.mjs': `import EmberApp from 'ember-cli/lib/broccoli/ember-app.js';
import { compatBuild } from '@embroider/compat';
export default async function(defaults) {
  const { buildOnce } = await import('@embroider/vite');
  return compatBuild(new EmberApp(defaults, { 'ember-cli-babel': { enableTypeScriptTransform: true } }), buildOnce);
}
`,
    'app/app.js': `import Application from '@ember/application';
import compatModules from '@embroider/virtual/compat-modules';
import Resolver from 'ember-resolver';
import loadInitializers from 'ember-load-initializers';
import config from 'site/config/environment';
import '@ember-eui/core/themes/light.css';
import '@ember-eui/core/styles/ember-eui.css';
export default class App extends Application {
  modulePrefix = config.modulePrefix;
  Resolver = Resolver.withModules(compatModules);
}
loadInitializers(App, config.modulePrefix, compatModules);
`,
    'app/router.js': `import EmberRouter from '@ember/routing/router';
import config from 'site/config/environment';
export default class Router extends EmberRouter {
  location = config.locationType;
  rootURL = config.rootURL;
}
Router.map(function () {});
`,
    'app/templates/application.hbs':
      '<main style="padding: 24px;"><Demo /></main>\n',
    'config/environment.js': `module.exports = function(environment) {
  return { modulePrefix: 'site', environment, rootURL: '/', locationType: 'hash', APP: {}, EmberENV: { EXTEND_PROTOTYPES: false }, '@ember-eui/core': { euiIcon: { useSvg: true } } };
};\n`,
    'app/config/environment.js': `import loadConfigFromMeta from '@embroider/config-meta-loader';
export default loadConfigFromMeta('site');\n`,
    'app/styles/app.css':
      'html { font-size: 14px; }\nbody { font-family: system-ui, sans-serif; }\n',
    'README.md':
      '# Ember EUI demo\n\nRun `npm install` and `npm start`, then edit app/components/demo.hbs and demo.js.\n',
  };
  for (const path of [
    'index.html',
    'babel.config.mjs',
    'config/optional-features.json',
  ]) {
    files[path] = read(path);
  }
  return files;
}

export function demoFiles(chunks) {
  const files = {};
  for (const { ext, code } of chunks)
    files[`app/components/demo.${ext}`] = code;
  if (!chunks.some(({ ext }) => ['js', 'ts', 'gjs', 'gts'].includes(ext))) {
    files['app/components/demo.js'] =
      "import templateOnly from '@ember/component/template-only';\nexport default templateOnly();\n";
  }
  return files;
}

export function playgroundOverrides(chunks, starter) {
  const source = chunks.map(({ code }) => code).join('\n');
  const pkg = JSON.parse(starter['package.json']);
  const needs = {
    '@ember-eui/changeset-form':
      /EuiChangesetForm|@ember-eui\/changeset-form/.test(source),
    '@ember-eui/validated-form':
      /ValidatedForm|@ember-eui\/validated-form/.test(source),
    '@ember-eui/flatpickr': /EuiFlatpickr|@ember-eui\/flatpickr/.test(source),
    '@ember-eui/pikaday': /EuiPikaday|@ember-eui\/pikaday/.test(source),
    'ember-changeset': /EuiChangesetForm|\bchangeset\b/.test(source),
    'ember-changeset-validations':
      /EuiChangesetForm|ember-changeset-validations/.test(source),
    flatpickr: /EuiFlatpickr|\bflatpickr\b/.test(source),
    'ember-intl': /\bintl\b|(?:\{\{#?|\()t\s/.test(source),
  };
  const site = JSON.parse(read('package.json'));
  for (const [dependency, required] of Object.entries(needs)) {
    if (!required) continue;
    pkg.devDependencies[dependency] = dependency.startsWith('@ember-eui/')
      ? JSON.parse(read(`../packages/${dependency.split('/')[1]}/package.json`))
          .version
      : site.devDependencies[dependency];
  }
  // Explicit npm imports in the backing class may need additional runtime packages.
  for (const [, specifier] of source.matchAll(
    /(?:from\s*|import\s*)['"]([^'"]+)['"]/g,
  )) {
    const name = specifier.startsWith('@')
      ? specifier.split('/').slice(0, 2).join('/')
      : specifier.split('/')[0];
    if (site.devDependencies[name] && !name.startsWith('@ember-eui/')) {
      pkg.devDependencies[name] = site.devDependencies[name];
    }
  }
  const files = {};
  if (needs.flatpickr) {
    files['app/app.js'] =
      "import 'flatpickr/dist/flatpickr.css';\n" + starter['app/app.js'];
  }
  const customIcons = /\.svg|site-(?:rocket|leaf|ember)/.test(source);
  const setupImports = [
    "import Route from '@ember/routing/route';",
    "import { service } from '@ember/service';",
  ];
  const services = [];
  const setup = [];
  if (needs['ember-intl']) {
    files['translations/en-us.json'] = read('translations/en-us.json');
    setupImports.push("import enUs from '../../translations/en-us.json';");
    services.push('  @service intl;');
    setup.push(
      "    this.intl.addTranslations('en-us', enUs);",
      "    this.intl.setLocale('en-us');",
    );
  }
  if (customIcons) {
    pkg.devDependencies['@svg-jar/plugin'] =
      site.devDependencies['@svg-jar/plugin'];
    files['vite.config.mjs'] =
      "import svgJar from '@svg-jar/plugin/vite';\n" +
      starter['vite.config.mjs'].replace(
        'ember(),',
        "ember(), svgJar({ target: 'ember' }),",
      );
    for (const icon of ['rocket', 'leaf', 'ember'])
      files[`app/icons/${icon}.svg`] = read(`app/icons/${icon}.svg`);
    setupImports.push(
      "import { iconsFromGlob } from '@ember-eui/core/utils/icons-from-glob';",
    );
    services.push('  @service euiConfig;');
    setup.push(
      "    this.euiConfig.updateConfig({ 'euiIcon.icons': iconsFromGlob(import.meta.glob('../icons/**/*.svg', { eager: true }), { prefix: 'site-' }) });",
    );
  }
  if (setup.length) {
    files['app/routes/application.js'] =
      `${setupImports.join('\n')}\nexport default class ApplicationRoute extends Route {\n${services.join('\n')}\n  beforeModel() {\n${setup.join('\n')}\n  }\n}\n`;
  }
  if (/TodoText/.test(source))
    files['app/components/todo-text.hbs'] = read(
      'app/components/todo-text.hbs',
    );
  if (/guideDemo__|text-white/.test(source))
    files['app/styles/app.css'] =
      starter['app/styles/app.css'] + read('app/styles/app.css');
  files['package.json'] = JSON.stringify(pkg, null, 2);
  return files;
}

export function playgroundManifest(pages) {
  const starter = starterFiles();
  const demos = {};
  for (const page of pages) {
    for (const demo of page.pluginData?.demoComponents ?? []) {
      demos[demo.name.dashCase] = {
        title: demo.description?.title ?? 'Ember EUI demo',
        files: {
          ...playgroundOverrides(demo.chunks, starter),
          ...demoFiles(demo.chunks),
        },
      };
    }
  }
  return { starter, demos };
}

export default plugin({
  runAfter(ctx) {
    writeFileSync(
      resolve(root, 'app/demo-playgrounds.json'),
      JSON.stringify(playgroundManifest(ctx.pages)),
    );
  },
});
