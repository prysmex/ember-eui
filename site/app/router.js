import EmberRouter from '@embroider/router';

import { addDocfyRoutes } from '@docfy/ember';
import { withHashSupport } from 'ember-url-hash-polyfill';
import config from 'site/config/environment';

@withHashSupport
export default class Router extends EmberRouter {
  location = config.locationType;
  rootURL = config.rootURL;
}

Router.map(function () {
  addDocfyRoutes(this);
});
