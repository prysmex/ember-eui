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
import type ThemeManager from 'site/services/theme-manager';

interface Props {}

const coreSectionsOrder = [
  'layout',
  'navigation',
  'display',
  'forms',
  'tabular',
  'editors',
  'charts',
  'utilities'
]

export default class ApplicationController extends Controller {
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

    this.initializeSidenav()
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
    const docsNode = this.docfy.nested.children.firstObject;

    // -- Documentation section

    const docsNodeRoutes = getSidenavRoutes([
      { ...docsNode, children: [] },
      (id: NodeId) => {
        this.selectedItem = id;
      }
    ]);

    // -- Display, Forms, Layout, Utilities, Editors & Syntax, Navigation sections
    let coreNode = docsNode.children.find((child: DocfyNode) => child.name === 'core')
    let coreNodes = this._getDocsNode(coreNode)?.children
    let coreNodeRoutes = coreSectionsOrder?.reduce<Item[]>((acum, curr) => {
      let node = coreNodes?.find((child: DocfyNode) => child.name == curr)
      if (node){
        // build routes for node
        let nodeRoutes = getSidenavRoutes([
          node,
          (id: NodeId) => {
            this.selectedItem = id;
          }
        ])

        // add fake items based on page headings to simulate 'on this page' feature inside sidebar
        node.pages.forEach((page: Page) => {
          let headings = page?.headings?.firstObject?.headings
          let item = nodeRoutes?.firstObject?.items?.find((item: Item) => item.name == page.title )

          if(item) {
            // set disabled to page item
            item.disabled = !!page.frontmatter.disabled
  
            // create fake items
            headings?.forEach((heading: any) => {
              item?.items.push(
                {
                  id: `fake-${heading.id}`,
                  items: [],
                  name: heading.title,
                  onClick: ((id: NodeId) => null),
                  href: `#${heading.id}`,
                  disabled: item.disabled || !!page.frontmatter.disabled_demos?.includes(heading.title)
                }
              )
            });
          }

        })

        acum.push(...nodeRoutes)
      }
      return acum
    }, [])

    // -- Addons section
    let fakeNode = {
      id: 'addons',
      onClick: () => (id: NodeId) => {
        this.selectedItem = id;
      },
      name: 'Addons',
      label: 'Addons',
      children: [],
      pages: []
    }

    docsNode.children.forEach((child: DocfyNode) => {
      if(child.name == 'core' || child.name == 'package'){
        return
      }
      let innerDocsNode = this._getDocsNode(child)
      fakeNode.children.push(...innerDocsNode?.children)
      fakeNode.pages.push(...innerDocsNode?.pages)
    });

    const addonsRoutes = getSidenavRoutes([
      fakeNode,
      (id: NodeId) => {
        this.selectedItem = id;
      }
    ]);

    // -- Package section

    let packageNode = docsNode.children.find(
      (child: Item) => child.name === 'package'
    );

    const packageRoutes = getSidenavRoutes([
      packageNode,
      (id: NodeId) => {
        this.selectedItem = id;
      }
    ]);

    // set state
    this.sideNavRoutes = [
      ...docsNodeRoutes,
      ...coreNodeRoutes,
      ...addonsRoutes,
      ...packageRoutes
    ];
    this.currentSideNavRoutes = this.sideNavRoutes;
    //@ts-expect-error
    this.selectedItem = this.router.location.location.pathname;
  }

  _getDocsNode(node: DocfyNode) {
    return node.children?.firstObject
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
    else return `v${config.version}`;
  }
}
