import Route from '@ember/routing/route';
import { inject as service } from '@ember/service';

class Index extends Route {
  @service declare router: RouterService;

  // normal class body definition here
  beforeModel() {
    this.router.replaceWith('docs.introduction');
  }
}

export default Index;
