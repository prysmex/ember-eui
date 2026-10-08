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
  '@ember/render-modifiers',
  '@ember/string',
  '@ember/test-waiters',
  '@embroider/compat',
  '@embroider/config-meta-loader',
  '@embroider/core',
  '@embroider/macros',
  '@embroider/router',
  '@embroider/vite',
  '@glimmer/component',
  '@glimmer/tracking',
  '@nullvoxpopuli/ember-composable-helpers',
  '@rollup/plugin-babel',
  '@svg-jar/plugin',
  'babel-plugin-ember-template-compilation',
  'decorator-transforms',
  'ember-basic-dropdown',
  'ember-changeset',
  'ember-changeset-validations',
  'ember-cli',
  'ember-cli-babel',
  'ember-concurrency',
  'ember-focus-trap',
  'ember-intl',
  'ember-keyboard',
  'ember-load-initializers',
  'ember-modifier',
  'ember-power-select',
  'ember-resolver',
  'ember-set-helper',
  'ember-source',
  'ember-truth-helpers',
  'flatpickr',
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
  for (const pkg of [
    'core',
    'changeset-form',
    'validated-form',
    'flatpickr',
    'pikaday',
  ]) {
    dependencies[`@ember-eui/${pkg}`] = JSON.parse(
      read(`../packages/${pkg}/package.json`),
    ).version;
  }
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
import svgJar from '@svg-jar/plugin/vite';
export default defineConfig({ plugins: [classicEmberSupport(), ember(), svgJar({ target: 'ember' }), babel({ babelHelpers: 'runtime', extensions: extensions.filter(ext => ext !== '.json') })] });
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
import 'flatpickr/dist/flatpickr.css';
export default class App extends Application {
  modulePrefix = config.modulePrefix;
  Resolver = Resolver.withModules(compatModules);
}
loadInitializers(App, config.modulePrefix, compatModules);
`,
    'app/router.js': `import EmberRouter from '@embroider/router';
import config from 'site/config/environment';
export default class Router extends EmberRouter {
  location = config.locationType;
  rootURL = config.rootURL;
}
Router.map(function () {});
`,
    'app/templates/application.hbs':
      '<main style="padding: 24px;"><Demo /></main>\n<div id="ember-basic-dropdown-wormhole"></div>\n',
    'config/environment.js': `module.exports = function(environment) {
  return { modulePrefix: 'site', environment, rootURL: '/', locationType: 'hash', APP: {}, EmberENV: { EXTEND_PROTOTYPES: false }, '@ember-eui/core': { euiIcon: { useSvg: true } } };
};\n`,
    'app/config/environment.js': `import loadConfigFromMeta from '@embroider/config-meta-loader';
export default loadConfigFromMeta('site');\n`,
    'app/routes/application.js': `import Route from '@ember/routing/route';
import { service } from '@ember/service';
import { iconsFromGlob } from '@ember-eui/core/utils/icons-from-glob';
import enUs from '../../translations/en-us.json';
export default class ApplicationRoute extends Route {
  @service intl;
  @service euiConfig;
  beforeModel() {
    this.intl.addTranslations('en-us', enUs);
    this.intl.setLocale('en-us');
    this.euiConfig.updateConfig({ 'euiIcon.icons': iconsFromGlob(import.meta.glob('../icons/**/*.svg', { eager: true }), { prefix: 'site-' }) });
  }
}\n`,
    'README.md':
      '# Ember EUI demo\n\nRun `npm install` and `npm start`, then edit app/components/demo.hbs and demo.js.\n',
  };
  for (const path of [
    'index.html',
    'babel.config.mjs',
    'config/optional-features.json',
    'translations/en-us.json',
    'app/styles/app.css',
    'app/components/todo-text.hbs',
    'app/icons/rocket.svg',
    'app/icons/leaf.svg',
    'app/icons/ember.svg',
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

export function playgroundManifest(pages) {
  const demos = {};
  for (const page of pages) {
    for (const demo of page.pluginData?.demoComponents ?? []) {
      demos[demo.name.dashCase] = {
        title: demo.description?.title ?? 'Ember EUI demo',
        files: demoFiles(demo.chunks),
      };
    }
  }
  return { starter: starterFiles(), demos };
}

export default plugin({
  runAfter(ctx) {
    writeFileSync(
      resolve(root, 'app/demo-playgrounds.json'),
      JSON.stringify(playgroundManifest(ctx.pages)),
    );
  },
});
