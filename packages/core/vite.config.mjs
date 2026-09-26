import { defineConfig } from 'vite';
import { extensions, ember, classicEmberSupport } from '@embroider/vite';
import { babel } from '@rollup/plugin-babel';

// Several dependencies are still v1 addons (ember-svg-jar,
// @ember/render-modifiers, ember-set-helper, ...), so the test app always
// runs through the classic compat layer (see ember-cli-build.cjs).
// Once those are gone this can be driven by ENABLE_COMPAT_BUILD like the
// upstream blueprint.
const isCompat = true;

export default defineConfig({
  plugins: [
    ...(isCompat ? [classicEmberSupport()] : []),
    ember(),
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
