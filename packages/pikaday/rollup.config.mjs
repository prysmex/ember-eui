import copy from 'rollup-plugin-copy';
import { babel } from '@rollup/plugin-babel';
import { Addon } from '@embroider/addon-dev/rollup';
import { fileURLToPath } from 'node:url';
import { readFileSync } from 'node:fs';
import { resolve, dirname } from 'node:path';

const addon = new Addon({
  srcDir: 'src',
  destDir: 'dist'
});

const rootDirectory = dirname(fileURLToPath(import.meta.url));
const babelConfig = resolve(rootDirectory, './babel.publish.config.cjs');

// Ship src/pikaday.css as-is so apps can import '@ember-eui/pikaday/pikaday.css'
function pikadayCss() {
  const fileName = 'pikaday.css';
  const source = resolve(rootDirectory, 'src', fileName);

  return {
    name: 'pikaday-css',
    buildStart() {
      this.addWatchFile(source);
    },
    generateBundle() {
      this.emitFile({
        type: 'asset',
        fileName,
        source: readFileSync(source, 'utf8')
      });
    }
  };
}

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
    babel({
      extensions: ['.js', '.gjs', '.ts', '.gts'],
      babelHelpers: 'bundled',
      configFile: babelConfig
    }),
    addon.hbs(),
    addon.gjs(),
    addon.declarations('declarations'),
    addon.keepAssets(['**/*.css']),
    pikadayCss(),
    addon.clean(),
    copy({
      targets: [
        { src: '../README.md', dest: '.' },
        { src: '../LICENSE.md', dest: '.' }
      ]
    })
  ]
};
