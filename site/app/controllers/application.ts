import Controller from '@ember/controller';
import { tracked } from '@glimmer/tracking';
import { inject as service } from '@ember/service';
import { getSidenavRoutes, Item, NodeId } from '../helpers/get-sidenav-routes';

export default class ApplicationController extends Controller {
  @service router: any;
  @service docfy: any;
  @tracked sideNavRoutes: Item[] = [];
  @tracked isOpenMobile = false;
  @tracked selectedItem: NodeId;

  init() {
    super.init();
    const root = this.docfy.nested.children.firstObject;
    const instructions = getSidenavRoutes([
      { ...root, children: [] },
      (id: NodeId) => {
        this.selectedItem = id;
      }
    ]);
    const coreNodes = getSidenavRoutes([
      root.children.find((child: Item) => child.name === 'core'),
      (id: NodeId) => {
        this.selectedItem = id;
      }
    ]);

    let others = root.children.filter((child: Item) => child.name !== 'core');

    const changeset = getSidenavRoutes([
      {
        id: 'addons',
        onClick: () => (id: NodeId) => {
          this.selectedItem = id;
        },
        name: 'Addons',
        label: 'Addons',
        children: others,
        pages: []
      },
      (id: NodeId) => {
        this.selectedItem = id;
      }
    ]);
    this.sideNavRoutes = [
      ...instructions,
      ...(this.removeDocs(coreNodes)?.firstObject?.items || []),
      ...changeset
    ];

    this.selectedItem = this.router.location.concreteImplementation.location.pathname;
  }

  get currentUrlFor() {
    if (this.router.currentRouteName) {
      return this.router.urlFor(this.router.currentRouteName);
    } else {
      return '';
    }
  }

  removeDocs(nodes: Item[]) {
    let firstChild = nodes.firstObject;
    if (firstChild?.items?.firstObject?.name === 'Documentation') {
      let docItems = firstChild.items.firstObject.items;
      firstChild.items = docItems;
    }
    return nodes;
  }
}
