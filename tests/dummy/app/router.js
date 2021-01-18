import EmberRouter from '@ember/routing/router';
import config from 'dummy/config/environment';

export default class Router extends EmberRouter {
  location = config.locationType;
  rootURL = config.rootURL;
}

Router.map(function() {
  this.route('demo', function() {
    this.route('icon');
    this.route('accordion');
    this.route('page');
    this.route('loading');
    this.route('text-block');
    this.route('title');
    this.route('image');
    this.route('overlay-mask');
    this.route('avatar');
    this.route('callout');
    this.route('badge');
    this.route('side-nav');
    this.route('card');
    this.route('button');
    this.route('health');
    this.route('modal');
    this.route('flex');
    this.route('header');
    this.route('horizontal-rule');
    this.route('panel');
    this.route('collapsible-nav');
  })
});
