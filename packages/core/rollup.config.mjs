import copy from 'rollup-plugin-copy';
import { babel } from '@rollup/plugin-babel';
import svgJar from '@svg-jar/plugin/rollup';
import svgoConfig from './svgo.config.mjs';
import { Addon } from '@embroider/addon-dev/rollup';
import { existsSync } from 'node:fs';
import { createRequire } from 'node:module';
import { fileURLToPath } from 'node:url';
import { resolve, dirname, sep } from 'node:path';

const addon = new Addon({
  srcDir: 'src',
  destDir: 'dist'
});

const rootDirectory = dirname(fileURLToPath(import.meta.url));
const require = createRequire(import.meta.url);

/**
 * The Borealis theme packages are bundled (from their ESM builds) instead of
 * left to the app. They declare no `sideEffects`, and borealis imports
 * eui-theme-common's index, which reaches `services/vis_color_store.js` and
 * its `import { uniqueId } from 'lodash'`: every app booting ember-eui got
 * all of CommonJS lodash (~70KB minified) next to lodash-es. Here they are
 * side-effect free modules, their lodash imports go to lodash-es, and
 * vis_color_store (unused) is tree-shaken. They stay `dependencies` for
 * their types, which the declarations reference.
 */
const themePackages = new Map(
  ['@elastic/eui-theme-common', '@elastic/eui-theme-borealis'].map((name) => [
    name,
    // `require` resolves lib/cjs/index.js; the ESM build sits next to it
    resolve(dirname(require.resolve(name)), '../esm')
  ])
);
const isThemeModule = (id) =>
  [...themePackages.values()].some((dir) => id?.startsWith(dir + sep));

function bundleEuiTheme() {
  return {
    name: 'bundle-eui-theme',
    resolveId(source, importer) {
      if (themePackages.has(source)) {
        return {
          id: resolve(themePackages.get(source), 'index.js'),
          moduleSideEffects: false
        };
      }
      if (!isThemeModule(importer)) return;
      if (source === 'lodash' || source.startsWith('lodash/')) {
        return { id: source.replace(/^lodash/, 'lodash-es'), external: true };
      }
      if (source.startsWith('.')) {
        // extension-less and directory imports, as in a CommonJS resolver
        const path = resolve(dirname(importer), source);
        const id = [path, `${path}.js`, resolve(path, 'index.js')].find(
          (candidate) => candidate.endsWith('.js') && existsSync(candidate)
        );
        return id && { id, moduleSideEffects: false };
      }
    }
  };
}
const babelConfig = resolve(rootDirectory, './babel.publish.config.cjs');

export default {
  treeshake: {
    // The generated EUI style modules (scripts/generate-eui-styles.mjs) only
    // define factories; their top-level `css()` calls are pure. Saying so
    // lets each component's chunk import just the style modules it uses
    // instead of every module the styles.generated barrel re-exports.
    moduleSideEffects: (id) => !/[\\/]utils[\\/]eui[\\/]styles\.generated[./\\]/.test(id)
  },
  output: {
    ...addon.output(),
    // the svgs shared by several icon types (src/icons/*.ts) and the
    // svg-jar runtime they use, kept with the icons instead of next to the
    // public entrypoints
    chunkFileNames: (chunk) =>
      chunk.moduleIds.every(
        (id) => /\.svg(\?|$)/.test(id) || id.includes('@svg-jar/plugin/')
      )
        ? 'icons/[name]-[hash].js'
        : chunk.moduleIds.every(isThemeModule)
          ? 'eui-theme/[name]-[hash].js'
          : '[name]-[hash].js'
  },
  plugins: [
    // before addon.dependencies(), which would leave them to the app
    bundleEuiTheme(),

    addon.publicEntrypoints([
      '**/*.js',
      'index.js',
      'template-registry.js',
      '**/*.cjs'
    ]),

    addon.appReexports([
      'components/**/*.js',
      'helpers/**/*.js',
      'modifiers/**/*.js',
      'services/**/*.js'
    ]),

    addon.dependencies(),

    // EUI icons: `import x from './x.svg?unsafe-inline'` becomes an Ember
    // component rendering the inline svg (see scripts/generate-icons.mjs).
    svgJar({ target: 'ember', svgo: svgoConfig }),

    // The generated components import @svg-jar/plugin's tiny ember runtime.
    // Bundle it (instead of leaving it for the app to resolve) so babel
    // precompiles its `template()` calls: consuming apps then need neither
    // @svg-jar/plugin nor the runtime template compiler.
    {
      name: 'bundle-svg-jar-runtime',
      resolveId(id) {
        if (id.startsWith('@svg-jar/plugin/runtime/')) {
          return fileURLToPath(import.meta.resolve(id));
        }
      }
    },

    babel({
      extensions: ['.js', '.gjs', '.ts', '.gts'],
      babelHelpers: 'bundled',
      configFile: babelConfig
    }),

    addon.hbs(),
    addon.gjs(),
    addon.declarations('declarations'),
    addon.keepAssets(['**/*.css']),
    addon.clean(),
    copy({
      targets: [
        { src: '../README.md', dest: '.' },
        { src: '../LICENSE.md', dest: '.' },
        // standalone stylesheet exported as `@ember-eui/core/styles/*`; no
        // module imports it, so keepAssets (addon-dev 8) does not emit it
        { src: 'src/styles/*.css', dest: 'dist/styles' }
      ],
      // after addon.clean() has emptied dist
      hook: 'writeBundle'
    })
  ]
};
