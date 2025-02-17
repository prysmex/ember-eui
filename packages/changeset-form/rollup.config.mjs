import copy from 'rollup-plugin-copy';
import { babel } from '@rollup/plugin-babel';
import { Addon } from '@embroider/addon-dev/rollup';
import { nodeResolve } from '@rollup/plugin-node-resolve';

const addon = new Addon({
  srcDir: 'src',
  destDir: 'dist'
});

const extensions = ['.js', '.ts', '.gts', '.gjs', '.hbs', '.json'];

export default {
  output: addon.output(),

  plugins: [
    addon.publicEntrypoints([
      '**/*.js',
      'index.js',
      '**/*.cjs',
      'template-registry.js',
    ]),
    addon.appReexports([
      'components/**/*.js',
      'helpers/**/*.js',
      'modifiers/**/*.js',
      'services/**/*.js'
    ]),

    addon.dependencies(),

    nodeResolve({ extensions }),

    babel({
      extensions: extensions,
      babelHelpers: 'bundled'
    }),

    addon.hbs(),

    addon.gjs(),

    // Emit .d.ts declaration files
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
