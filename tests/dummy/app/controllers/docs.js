import Controller from '@ember/controller';
import { tracked } from '@glimmer/tracking';
import { inject as service } from '@ember/service';
import { getSidenavRoutes } from '../helpers/get-sidenav-routes';

export default class DocsController extends Controller {
  @service router;
  @service docfy;
  @tracked sideNavRoutes = [];
	@tracked isOpenMobile = true;
	@tracked selectedItem;

  constructor() {
    super(...arguments);
		window.docfy = this.docfy;
		window.docs = this;
    this.sideNavRoutes = getSidenavRoutes([
      this.docfy.findNestedChildrenByName('docs'),
      (id) => {
				this.selectedItem = id
			},
    ]);
  }
}
