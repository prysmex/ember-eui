import { tracked } from '@glimmer/tracking';
import Controller from '@ember/controller';
import { service } from '@ember/service';

import config from 'site/config/environment';

import { scrollToHash } from '../utils/scroll-to-hash';

import { getSidenavRoutes } from '../helpers/get-sidenav-routes';

import type {
  DocfyNode,
  Heading,
  Item,
  NodeId,
  Page,
} from '../helpers/get-sidenav-routes';
import type DocfyService from '@docfy/ember/services/docfy';
import type Owner from '@ember/owner';
import type RouterService from '@ember/routing/router-service';
import type ThemeManager from 'site/services/theme-manager';

/** Every page of a docfy node, including those of its child nodes. */
function allPages(node: DocfyNode): Page[] {
  return [...node.pages, ...node.children.flatMap(allPages)];
}

/** The side nav item with the given id, at any depth. */
function findItem(items: Item[], id: NodeId): Item | undefined {
  for (const item of items) {
    if (item.id === id) return item;

    const found = findItem(item.items, id);
    if (found) return found;
  }

  return undefined;
}

export default class ApplicationController extends Controller {
  @service declare router: RouterService;
  @service declare docfy: DocfyService;
  @service declare themeManager: ThemeManager;
  @tracked sideNavRoutes: Item[] = [];
  @tracked currentSideNavRoutes: Item[] = [];
  @tracked isOpenMobile = false;
  @tracked selectedItem: NodeId;
  @tracked searchValue?: string;
  @tracked themePopover: boolean = false;

  constructor(owner?: Owner) {
    super(owner);

    this.initializeSidenav();

    this.router.on('routeDidChange', () => {
      this.selectedItem = this.currentPath;
    });

    this.selectedItem = this.currentPath;
  }

  // the side nav item ids are page paths
  get currentPath(): string {
    return (this.router.currentURL ?? '').split(/[?#]/)[0] ?? '';
  }

  get currentUrlFor() {
    if (this.router.currentRouteName) {
      return this.router.urlFor(this.router.currentRouteName);
    } else {
      return '';
    }
  }

  initializeSidenav() {
    // uppermost node
    // the side nav helpers model docfy's nested output as DocfyNode
    const docsNode = this.docfy.nested.children[0] as unknown as DocfyNode;

    const handlerFn = (id: NodeId) => {
      this.selectedItem = id;
      this.router.transitionTo(id);
      scrollToHash(id as string);
    };

    // -- Documentation section
    // TODO: remove the onClick that just sets selectedItem, it shouldn't be needed with the new docs structure
    const docsNodeRoutes = getSidenavRoutes([
      { ...docsNode, children: [] },
      handlerFn,
    ]);

    // -- Display, Forms, Layout, Utilities, Editors & Syntax, Navigation sections
    const coreNode = docsNode.children.find(
      (child: DocfyNode) => child.name === 'core',
    );
    const coreNodes = this._getDocsNode(coreNode)?.children;
    const coreNodeRoutes = [
      'templates',
      'layout',
      'navigation',
      'display',
      'forms',
      'tabular',
      'editors',
      'charts',
      'utilities',
    ].reduce<Item[]>((acum, curr) => {
      const node = coreNodes?.find((child: DocfyNode) => child.name == curr);

      if (node) {
        // build routes for node
        const nodeRoutes = getSidenavRoutes([node, handlerFn]);

        // add fake items based on page headings to simulate 'on this page' feature inside sidebar:
        // the page's own sections and its demos (the children of "Examples"),
        // but not the API reference tables
        allPages(node).forEach((page: Page) => {
          const headings = (page?.headings ?? []).flatMap(
            (heading: Heading) => {
              if (heading.id === 'api-reference') return [];
              if (heading.id === 'examples') return heading.headings ?? [];
              return [heading];
            },
          );
          // pages can be nested (forms > form controls > checkbox)
          const item = findItem(nodeRoutes, page.url);

          if (item) {
            // set disabled to page item
            item.disabled = !!page.frontmatter.disabled;
            // create fake items
            headings?.forEach((heading: Heading) => {
              item?.items.push({
                id: `fake-${page.url}#${heading.id}`,
                items: [],
                name: heading.title,
                onClick: () => {
                  this.router.transitionTo(page.url);
                  scrollToHash(heading.id);
                },
                disabled:
                  item.disabled ||
                  !!page.frontmatter.disabled_demos?.includes(heading.title),
              });
            });
          }
        });

        acum.push(...nodeRoutes);
      }

      return acum;
    }, []);

    // -- Addons section
    const fakeNode = {
      id: 'addons',
      onClick: handlerFn,
      name: 'Addons',
      label: 'Addons',
      children: [],
      pages: [],
    } as DocfyNode;

    docsNode.children.forEach((child: DocfyNode) => {
      if (child.name == 'core' || child.name == 'package') {
        return;
      }

      const innerDocsNode = this._getDocsNode(child);

      fakeNode.children.push(...(innerDocsNode?.children || []));
      fakeNode.pages.push(...(innerDocsNode?.pages || []));
    });

    const addonsRoutes = getSidenavRoutes([fakeNode, handlerFn]);

    // -- Package section

    const packageNode = docsNode.children.find(
      (child: DocfyNode) => child.name === 'package',
    );

    const packageRoutes = getSidenavRoutes([packageNode, handlerFn]);

    // set state
    this.sideNavRoutes = [
      ...docsNodeRoutes,
      ...coreNodeRoutes,
      ...addonsRoutes,
      ...packageRoutes,
    ];
    this.currentSideNavRoutes = this.sideNavRoutes;
  }

  _getDocsNode(node?: DocfyNode) {
    return node?.children?.[0];
  }

  filterSideNav(str: string, nodes: Item[], depth: number = 0): Item[] {
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
        forceOpen: true,
      };

      curr.items.forEach((item) => {
        toAdd.items.push(...this.filterSideNav(str, [item], depth + 1));
      });

      const nameMatches = curr.name
        .toLowerCase()
        .includes(str.trim().toLowerCase());

      if (nameMatches || toAdd.items.length > 0) {
        toAdd = {
          ...toAdd,
          ...curr,
          // a matching page keeps all of its demos and sections
          items:
            nameMatches && toAdd.items.length === 0 ? curr.items : toAdd.items,
          forceOpen: true,
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
        0,
      );
    }
  };

  get currentVersion() {
    if (config.environment === 'development') return 'Local';
    else return `v${config['version'] as string}`;
  }
}
