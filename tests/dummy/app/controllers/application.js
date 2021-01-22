import Controller from '@ember/controller';
import { tracked } from '@glimmer/tracking';
import { inject as service } from '@ember/service';
import { getSidenavRoutes } from '../helpers/get-sidenav-routes';
import { action } from '@ember/object';

export default class ApplicationController extends Controller {
  @service router;
  @service docfy;
  @tracked sideNavRoutes = [];
  @tracked isOpenMobile = true;
  @tracked selectedItem;
  @tracked flyoutOpen = false;

  constructor() {
    super(...arguments);
    this.sideNavRoutes = getSidenavRoutes([
      this.docfy.findNestedChildrenByName('docs'),
      (id) => {
        this.selectedItem = id;
      },
    ]);
  }

  @action
  openFlyout() {
    this.flyoutOpen = true;
  }
  @action
  closeFlyout() {
    this.flyoutOpen = false;
  }
}
