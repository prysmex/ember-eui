'use strict';

const EmberAddon = require('ember-cli/lib/broccoli/ember-addon');
const path = require('path');

module.exports = function (defaults) {
  let app = new EmberAddon(defaults, {
    postcssOptions: {
      compile: {
        enabled: true,
        cacheInclude: [/.*\.css$/, /.tailwind\.config\.js$/],
        plugins: [
          {
            module: require('postcss-import'),
            options: {
              path: ['node_modules'],
            },
          },
          require('tailwindcss')(
            path.join('tests', 'dummy', 'app', 'styles', 'tailwind.config.js')
          ),
          require('postcss-nested'),
          require('autoprefixer'),
        ],
      },
    },

    'ember-composable-helpers': {
      only: [
        'optional',
        'find-by',
        'pipe',
        'object-at',
        'noop',
        'repeat'
      ]
    },

    'tracked-toolbox': {
      only: [
        'localCopy'
      ]
    },
    // Add options here
    'ember-eui': {
      theme: 'dark',
      useCompiledCss: true,
    },

    fingerprint: {
      enabled: true,
      generateAssetMap: true,
    },

    'ember-fetch': {
      preferNative: true, // Recommended to enable faster preloading for browsers that support it.
    },

    svgJar: {
      strategy: ['hbs'],
      hbs: {
        stripPath: false,
      },
      sourceDirs: ['public/assets', 'node_modules/@elastic/eui/lib/components/icon'],
    },
  });

  /*
    This build file specifies the options for the dummy test app of this
    addon, located in `/tests/dummy`
    This build file does *not* influence how the addon or the app using it
    behave. You most likely want to be modifying `./index.js` or app's build file
  */
  return app.toTree();
};
