'use strict';

const EmberApp = require('ember-cli/lib/broccoli/ember-app');
const path = require('path');
const env = EmberApp.env();

const purgecssOptions = {
  content: [
    './app/index.html',
    './app/**/*.hbs',
    '../**/*.md',
    './node_modules/**/*.hbs',
    '../node_modules/**/*.hbs'
  ]
};

module.exports = function (defaults) {
  let postcssPlugins = [
    {
      module: require('postcss-import'),
      options: {
        path: [path.join(__dirname, '../node_modules')]
      }
    },
    require('tailwindcss')(path.join('app', 'styles', 'tailwind.config.js')),
    require('postcss-nested'),
    require('autoprefixer')
  ];

  if (env !== 'development' || process.env.PURGE_CSS === 'true') {
    const purgecss = require('@fullhuman/postcss-purgecss')(purgecssOptions);
    postcssPlugins.push(purgecss);
  }

  let app = new EmberApp(defaults, {
    postcssOptions: {
      compile: {
        enabled: true,
        cacheInclude: [/.*\.css$/, /.tailwind\.config\.js$/],
        plugins: postcssPlugins
      }
    },

    'ember-composable-helpers': {
      only: [
        'optional',
        'find-by',
        'pipe',
        'object-at',
        'noop',
        'repeat',
        'pick',
        'queue'
      ]
    },

    // Add options here
    '@ember-eui/core': {
      theme: 'light'
    },
    'ember-cli-netlify': {
      redirects: ['/* /index.html 200']
    },

    fingerprint: {
      enabled: env === 'production',
      generateAssetMap: true
    },

    'ember-fetch': {
      preferNative: true // Recommended to enable faster preloading for browsers that support it.
    },

    svgJar: {
      strategy: ['hbs'],
      hbs: {
        stripPath: false
      },
      sourceDirs: [
        'public/assets',
        '../node_modules/@ember-eui/core/public',
        '../node_modules/@elastic/eui/lib/components/icon'
      ]
    }
  });

  return app.toTree();
};
