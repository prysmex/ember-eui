import copy from 'rollup-plugin-copy';
import { babel } from '@rollup/plugin-babel';
import svgJar from '@svg-jar/plugin/rollup';
import svgoConfig from './svgo.config.mjs';
import { Addon } from '@embroider/addon-dev/rollup';
import { fileURLToPath } from 'node:url';
import { resolve, dirname } from 'node:path';

const addon = new Addon({
  srcDir: 'src',
  destDir: 'dist'
});

const rootDirectory = dirname(fileURLToPath(import.meta.url));
const babelConfig = resolve(rootDirectory, './babel.publish.config.cjs');

export default {
  output: addon.output(),
  plugins: [
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
