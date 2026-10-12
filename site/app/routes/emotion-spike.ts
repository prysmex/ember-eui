import Route from '@ember/routing/route';
import { service } from '@ember/service';
import type RouterService from '@ember/routing/router-service';

/** Preserve the original spike URL while making the docs page canonical. */
export default class EmotionSpikeRoute extends Route {
  @service declare router: RouterService;

  beforeModel() {
    this.router.replaceWith('/docs/emotion');
  }
}
