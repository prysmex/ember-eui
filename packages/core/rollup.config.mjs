import copy from 'rollup-plugin-copy';
import { babel } from '@rollup/plugin-babel';
import { Addon } from '@embroider/addon-dev/rollup';
import { nodeResolve } from '@rollup/plugin-node-resolve';

const addon = new Addon({
  srcDir: 'src',
  destDir: 'dist'
});

const extensions = ['.js', '.gjs', '.ts', '.gts'];

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
      'utils/**/*.js',
      'modifiers/**/*.js',
      'services/**/*.js'
    ]),

    addon.dependencies(),

    nodeResolve({ extensions }),

    babel({ extensions, babelHelpers: 'bundled' }),

    addon.clean(),
    addon.hbs(),
    addon.gjs(),
    addon.declarations('declarations'),
    addon.keepAssets(['**/*.css']),
    addon.clean(),
    copy({
      targets: [
        { src: '../README.md', dest: '.' },
        { src: '../LICENSE.md', dest: '.' }
      ]
    })
  ]
};
