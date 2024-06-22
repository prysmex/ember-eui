import copy from 'rollup-plugin-copy';
import { babel } from '@rollup/plugin-babel';
import { Addon } from '@embroider/addon-dev/rollup';
import { execaCommand } from "execa";
import { fixBadDeclarationOutput } from "fix-bad-declaration-output";

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
    babel({ extensions, babelHelpers: 'inline' }),
    addon.hbs(),
    addon.gjs(),
    addon.keepAssets(['**/*.css']),
    addon.clean(),
    copy({
      targets: [
        { src: '../README.md', dest: '.' },
        { src: '../LICENSE.md', dest: '.' }
      ]
    }),
    {
      name: 'Build Declarations',
      closeBundle: async () => {
        /**
         * Generate the types (these include /// <reference types="ember-source/types"
         * but our consumers may not be using those, or have a new enough ember-source that provides them.
         */
        console.log('Building types');
        await execaCommand(`pnpm glint --build`, { stdio: 'inherit' });
        /**
         * https://github.com/microsoft/TypeScript/issues/56571#
         * README: https://github.com/NullVoxPopuli/fix-bad-declaration-output
         */
        console.log('Fixing types');
        await fixBadDeclarationOutput('declarations/**/*.d.ts', [
          ['TypeScript#56571', { types: 'all' }],
          'Glint#628',
          'Glint#697'
        ]);
        console.log(
          '⚠️ Dangerously (but neededly) fixed bad declaration output from typescript'
        );
      }
    }
  ]
};
