import Route from '@ember/routing/route';
import { action } from '@ember/object';

export default class Docs extends Route {
  @action
  didTransition() {
    window.scrollTo(0, 0);
  }
}
