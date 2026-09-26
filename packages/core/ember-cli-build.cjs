'use strict';

// Only used to build the test app through @embroider/compat, because some of
// our dependencies are still v1 addons. Not part of the published package.
const EmberApp = require('ember-cli/lib/broccoli/ember-app');
const { compatBuild } = require('@embroider/compat');

module.exports = async function (defaults) {
  const { buildOnce } = await import('@embroider/vite');

  let app = new EmberApp(defaults, {
    svgJar: {
      sourceDirs: ['vendor/icon']
    }
  });

  return compatBuild(app, buildOnce);
};
