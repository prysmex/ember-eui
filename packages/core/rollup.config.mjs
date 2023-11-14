import copy from 'rollup-plugin-copy';
import { babel } from '@rollup/plugin-babel';
import { Addon } from '@embroider/addon-dev/rollup';
import { nodeResolve } from '@rollup/plugin-node-resolve';
import { glimmerTemplateTag } from 'rollup-plugin-glimmer-template-tag';

const addon = new Addon({
  srcDir: 'src',
  destDir: 'dist'
});

const extensions = ['.js', '.ts', '.gts', '.gjs', '.hbs', '.json'];

export default {
  output: addon.output(),
  plugins: [
    addon.publicEntrypoints(['**/*.js', 'index.js', 'template-registry.js']),
    addon.appReexports([
      'components/**/*.js',
      'helpers/**/*.js',
      'utils/**/*.js',
      'modifiers/**/*.js',
      'services/**/*.js'
    ]),
    addon.dependencies(),
    glimmerTemplateTag(),
    nodeResolve({ extensions }),
    babel({ extensions, babelHelpers: 'bundled' }),
    addon.hbs(),
    // addon.gjs(),
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
