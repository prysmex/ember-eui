import Route from '@ember/routing/route';
import { inject as service } from '@ember/service';

class Application extends Route {
  // normal class body definition here
  @service declare intl: IntlService;

  beforeModel() {
    this.intl.setLocale('en-us');
  }
}

export default Application;
