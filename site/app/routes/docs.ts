import { action } from '@ember/object';
import Route from '@ember/routing/route';

export default class Docs extends Route {
  @action
  didTransition() {
    window.scrollTo(0, 0);
  }
}
