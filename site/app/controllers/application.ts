import Controller from '@ember/controller';
import { tracked } from '@glimmer/tracking';
import { inject as service } from '@ember/service';
import { getSidenavRoutes, Item, NodeId } from '../helpers/get-sidenav-routes';
import RouterService from '@ember/routing/router-service';

interface Props {}

export default class ApplicationController extends Controller {
  @service declare router: RouterService;
  @service docfy: any;
  @tracked sideNavRoutes: Item[] = [];
  @tracked currentSideNavRoutes: Item[] = [];
  @tracked isOpenMobile = false;
  @tracked selectedItem: NodeId;
  @tracked searchValue?: string;

  constructor(props?: Props) {
    super(props);
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
    this.currentSideNavRoutes = this.sideNavRoutes;
    //@ts-expect-error
    this.selectedItem = this.router.location.location.pathname;
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

  filterSideNav(str: string, nodes: Item[], depth: number = 0): Item[] {
    //@ts-ignore
    return nodes.reduce<Item[]>((acum, curr) => {
      if (depth === 0) {
        const foundItems = this.filterSideNav(str, curr.items, depth + 1);
        if (foundItems.length > 0) {
          acum.push({ ...curr, forceOpen: true, items: foundItems });
        }
        return acum;
      }

      let toAdd: Item = {
        items: [],
        name: '',
        id: '',
        onClick: true,
        forceOpen: true
      };

      curr.items.forEach((item) => {
        toAdd.items.push(...this.filterSideNav(str, [item], depth + 1));
      });

      if (
        curr.name.toLowerCase().indexOf(str?.toLowerCase()) > -1 ||
        toAdd.items.length > 0
      ) {
        toAdd = {
          ...toAdd,
          ...curr,
          items: toAdd.items
        };
      }

      if (toAdd.name !== '') {
        acum.push(toAdd);
      }

      return acum;
    }, []);
  }

  onSearch = (str: string) => {
    this.searchValue = str;
    if (!str) {
      this.currentSideNavRoutes = this.sideNavRoutes;
    } else {
      this.currentSideNavRoutes = this.filterSideNav(
        str,
        this.sideNavRoutes,
        0
      );
    }
  };
}
