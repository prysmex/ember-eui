import EmberApp from 'ember-cli/lib/broccoli/ember-app.js';
import { compatBuild } from '@embroider/compat';

import docsPageRoutes from './lib/docs-routes.mjs';

export default async function (defaults) {
  const { buildOnce } = await import('@embroider/vite');

  const app = new EmberApp(defaults, {
    'ember-cli-babel': { enableTypeScriptTransform: true },
  });

  return compatBuild(app, buildOnce, {
    // imported by the docs pages only (see vite.config.mjs), so it loads
    // with them instead of up front like other app files
    staticAppPaths: ['docfy-overrides.js'],
    // every docs page is its own bundle, loaded when you visit it; with
    // components imported one by one, a page brings only what it uses
    splitAtRoutes: [
      ...docsPageRoutes(),
      // each page's generated demo components (`<page>_gen/`): Embroider
      // takes every file under app/templates for a route, so split them
      // off too; only their page imports them
      /_gen$/,
    ],
  });
}
