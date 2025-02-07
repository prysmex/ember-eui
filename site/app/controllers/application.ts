import { tracked } from '@glimmer/tracking';
import { getOwner } from '@ember/application';
import Controller from '@ember/controller';
import { inject as service } from '@ember/service';

import { scrollToHash } from 'ember-url-hash-polyfill';

import {
  getSidenavRoutes
} from '../helpers/get-sidenav-routes';

// import EuiSideNavItemButton from '@ember-eui/core/components/eui-side-nav-item/button';
import type {
  DocfyNode,
  Item,
  NodeId,
  Page
} from '../helpers/get-sidenav-routes';
import type RouterService from '@ember/routing/router-service';
import type ThemeManager from 'site/services/theme-manager';

interface Props {}

export default class ApplicationController extends Controller {
  // EuiSideNavItemButton = EuiSideNavItemButton;
  @service declare router: RouterService;
  @service docfy: any;
  @service declare themeManager: ThemeManager;
  @tracked sideNavRoutes: Item[] = [];
  @tracked currentSideNavRoutes: Item[] = [];
  @tracked isOpenMobile = false;
  @tracked selectedItem: NodeId;
  @tracked searchValue?: string;
  @tracked themePopover: boolean = false;

  constructor(props?: Props) {
    super(props);

    this.initializeSidenav();

    this.router.on('routeDidChange', () => {
      //@ts-expect-error
      this.selectedItem = this.router.location.location.pathname;
    });
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

  initializeSidenav() {
    // uppermost node
    const docsNode = this.docfy.nested.children[0];

    const handlerFn = (id: NodeId) => {
      this.selectedItem = id;
      this.router.transitionTo(id);
      scrollToHash(id);
    };

    // -- Documentation section
    // TODO: remove the onClick that just sets selectedItem, it shouldn't be needed with the new docs structure
    const docsNodeRoutes = getSidenavRoutes([
      { ...docsNode, children: [] },
      handlerFn
    ]);

    // -- Display, Forms, Layout, Utilities, Editors & Syntax, Navigation sections
    let coreNode = docsNode.children.find(
      (child: DocfyNode) => child.name === 'core'
    );
    let coreNodes = this._getDocsNode(coreNode)?.children;
    let coreNodeRoutes = [
      'templates',
      'layout',
      'navigation',
      'display',
      'forms',
      'tabular',
      'editors',
      'charts',
      'utilities'
    ].reduce<Item[]>((acum, curr) => {
      let node = coreNodes?.find((child: DocfyNode) => child.name == curr);

      if (node) {
        // build routes for node
        let nodeRoutes = getSidenavRoutes([node, handlerFn]);

        // add fake items based on page headings to simulate 'on this page' feature inside sidebar
        node.pages.forEach((page: Page) => {
          let headings = page?.headings?.[0]?.headings;
          let item = nodeRoutes?.[0]?.items?.find(
            (item: Item) => item.name == page.title
          );

          if (item) {
            // set disabled to page item
            item.disabled = !!page.frontmatter.disabled;
            // create fake items
            headings?.forEach((heading: any) => {
              item?.items.push({
                id: `fake-${heading.id}`,
                items: [],
                name: heading.title,
                onClick: () => {
                  this.router.transitionTo(page.url);
                  scrollToHash(heading.id);
                },
                disabled:
                  item.disabled ||
                  !!page.frontmatter.disabled_demos?.includes(heading.title)
              });
            });
          }
        });

        acum.push(...nodeRoutes);
      }

      return acum;
    }, []);

    // -- Addons section
    let fakeNode = {
      id: 'addons',
      onClick: handlerFn,
      name: 'Addons',
      label: 'Addons',
      children: [],
      pages: []
    } as DocfyNode;

    docsNode.children.forEach((child: DocfyNode) => {
      if (child.name == 'core' || child.name == 'package') {
        return;
      }

      let innerDocsNode = this._getDocsNode(child);

      fakeNode.children.push(...(innerDocsNode?.children || []));
      fakeNode.pages.push(...(innerDocsNode?.pages || []));
    });

    const addonsRoutes = getSidenavRoutes([fakeNode, handlerFn]);

    // -- Package section

    let packageNode = docsNode.children.find(
      (child: Item) => child.name === 'package'
    );

    const packageRoutes = getSidenavRoutes([packageNode, handlerFn]);

    // set state
    this.sideNavRoutes = [
      ...docsNodeRoutes,
      ...coreNodeRoutes,
      ...addonsRoutes,
      ...packageRoutes
    ];
    this.currentSideNavRoutes = this.sideNavRoutes;
  }

  _getDocsNode(node: DocfyNode) {
    return node.children?.[0];
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
        curr.name[0]?.toLowerCase().indexOf(str?.toLowerCase()) > -1 ||
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
    //@ts-ignore
    const config = getOwner(this).resolveRegistration('config:environment');

    if (config.environment === 'development') return 'Local';
    else return `v${config.version}`;
  }
}
