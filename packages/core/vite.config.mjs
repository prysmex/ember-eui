import { defineConfig } from 'vite';
import { extensions, ember, classicEmberSupport } from '@embroider/vite';
import { babel } from '@rollup/plugin-babel';
import svgJar from '@svg-jar/plugin/vite';
import svgoConfig from './svgo.config.mjs';

// ember-power-select 8 still depends on a v1 addon (@embroider/util), so
// the test app runs through the classic compat layer (see
// ember-cli-build.cjs). Once that is gone this can be driven by
// ENABLE_COMPAT_BUILD like the upstream blueprint.
const isCompat = true;

export default defineConfig({
  plugins: [
    ...(isCompat ? [classicEmberSupport()] : []),
    ember(),
    // same transform as the addon build (rollup.config.mjs), for the EUI icons
    svgJar({ target: 'ember', svgo: svgoConfig }),
    babel({
      babelHelpers: 'inline',
      extensions
    })
  ],
  build: {
    rollupOptions: {
      input: {
        tests: 'tests/index.html'
      }
    }
  }
});
