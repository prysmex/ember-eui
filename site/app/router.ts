import EmberRouter from '@embroider/router';

import { addDocfyRoutes } from '@docfy/ember';
import config from 'site/config/environment';

export default class Router extends EmberRouter {
  location = config.locationType;
  rootURL = config.rootURL;
}

Router.map(function () {
  addDocfyRoutes(this);
});
