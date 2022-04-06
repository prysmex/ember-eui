import Controller from '@ember/controller';
import { tracked } from '@glimmer/tracking';
import { inject as service } from '@ember/service';
import {
  DocfyNode,
  getSidenavRoutes,
  Item,
  NodeId,
  Page
} from '../helpers/get-sidenav-routes';
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
    others = this.removeDocsFromDocfyNodes(others);
    console.log(others);
    const finalOthersPages = others.reduce((prev: Page[], curr: DocfyNode) => {
      prev.push(...curr.pages);
      return prev;
    }, []);
    const changeset = getSidenavRoutes([
      {
        id: 'addons',
        onClick: () => (id: NodeId) => {
          this.selectedItem = id;
        },
        name: 'Addons',
        label: 'Addons',
        children: [],
        pages: finalOthersPages
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

  removeDocsFromDocfyNodes(nodes: DocfyNode[]) {
    nodes.forEach((node) => {
      //Changeset-form node
      let firstChild = node.children.firstObject;
      if (firstChild?.label === 'Documentation') {
        let docPages = firstChild.pages;
        node.pages = docPages;
        node.children = [];
      }
    });
    console.log(nodes);
    return nodes;
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
