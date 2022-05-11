import EmberRouter from '@embroider/router';
import config from 'site/config/environment';
import { addDocfyRoutes } from 'prysmex-docfy-ember';

export default class Router extends EmberRouter {
  location = config.locationType;
  rootURL = config.rootURL;
}

Router.map(function () {
  addDocfyRoutes(this);
});
