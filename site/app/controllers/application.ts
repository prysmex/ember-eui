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
import config from 'ember-get-config';
import { changeTheme } from '../utils/change-theme';

interface Props {}

type ThemeShape = {
  name: string;
  key: string;
};

export default class ApplicationController extends Controller {
  @service declare router: RouterService;
  @service docfy: any;
  @tracked sideNavRoutes: Item[] = [];
  @tracked currentSideNavRoutes: Item[] = [];
  @tracked isOpenMobile = false;
  @tracked selectedItem: NodeId;
  @tracked searchValue?: string;
  @tracked currentTheme?: ThemeShape | null;
  @tracked themePopover: boolean = false;
  themes: ThemeShape[] = [
    {
      name: 'Light',
      key: 'light'
    },
    {
      name: 'Dark',
      key: 'dark'
    },
    {
      name: 'Amsterdam Light',
      key: 'amsterdam_light'
    },
    {
      name: 'Amsterdam Dark',
      key: 'amsterdam_dark'
    }
  ];

  constructor(props?: Props) {
    super(props);
    this.currentTheme =
      this.themes.findBy('key', window?.localStorage?.getItem('theme')) ||
      this.themes[0];
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

    let others = root.children.filter(
      (child: Item) => child.name !== 'core' && child.name !== 'package'
    );

    others = this.removeDocsFromDocfyNodes(others);
    const finalOthersPages = others.reduce((prev: Page[], curr: DocfyNode) => {
      prev.push(...curr.pages);
      return prev;
    }, []);

    const addons = getSidenavRoutes([
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

    let packagesNode = root.children.filter(
      (child: Item) => child.name === 'package'
    );

    packagesNode = this.removeDocsFromDocfyNodes(packagesNode);

    const packageRoutes = getSidenavRoutes([
      packagesNode?.[0],
      (id: NodeId) => {
        this.selectedItem = id;
      }
    ]);

    this.sideNavRoutes = [
      ...instructions,
      ...(this.removeDocs(coreNodes)?.firstObject?.items || []),
      ...addons,
      ...packageRoutes
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

  get currentVersion() {
    if (config.environment === 'development') return 'Local';
    else return config.version;
  }

  setTheme = (theme: ThemeShape) => {
    changeTheme(theme.key);
    this.currentTheme = theme;
  };
}
