/**
 * SVGO config for the EUI icons, shared by the addon build
 * (rollup.config.mjs) and the test build (vite.config.mjs).
 *
 * It is @svg-jar/plugin's baseline config (keep ids, which the plugin
 * prefixes per icon, keep hidden elements, drop <title>), but it also
 * optimizes path data like ember-svg-jar did, roughly halving the size of
 * the icons.
 */
export default {
  plugins: [
    {
      name: 'preset-default',
      params: {
        overrides: {
          cleanupIds: { minify: false, remove: false },
          removeHiddenElems: false,
          cleanupNumericValues: false
        }
      }
    },
    'removeTitle'
  ]
};
