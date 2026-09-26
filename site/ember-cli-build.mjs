import EmberApp from 'ember-cli/lib/broccoli/ember-app.js';
import { compatBuild } from '@embroider/compat';

export default async function (defaults) {
  const { buildOnce } = await import('@embroider/vite');

  const app = new EmberApp(defaults, {
    'ember-cli-babel': { enableTypeScriptTransform: true },
  });

  return compatBuild(app, buildOnce);
}
