import Helper from '@ember/component/helper';
import { service } from '@ember/service';

import type DocfyService from '@docfy/ember/services/docfy';

function humanize(str?: string) {
  return (
    str
      ?.replace(/^[\s_]+|[\s_]+$/g, '')
      .replace(/[_\s]+/g, ' ')
      .replace(/[-\s]+/g, ' ')
      .replace(/^[a-z]/, function (m) {
        return m.toUpperCase();
      }) ?? ''
  );
}

export type Heading = {
  id: string;
  title: string;
  headings: Heading[];
};

export type Page = {
  id: string;
  url: string;
  title: string;
  headings: Heading[];
  frontmatter: {
    disabled: boolean;
    disabled_demos: string[];
    order?: number;
    // `nav: false`: the page is routed but not listed (an old URL's page
    // that links to where its sections went)
    nav?: boolean;
  };
};

export type NodeId = string | number | undefined;

export type DocfyNode = {
  id: NodeId;
  label: string;
  name: string;
  children: DocfyNode[];
  pages: Page[];
  onClick: boolean | ((id: NodeId) => void);
};

export type Item = {
  id: NodeId;
  href?: string | undefined;
  label?: string;
  name: string;
  items: Item[];
  onClick: boolean | ((id: NodeId) => void);
  forceOpen?: boolean;
  disabled?: boolean;
  // the page's `order` front matter, used with `byOrder`
  order?: number;
};

export type SidenavOptions = {
  // pages with an `order` front matter first, by it; the rest by name
  byOrder?: boolean;
};

function compareFunction(a: Item, b: Item) {
  if (a.name < b.name) {
    return -1;
  }

  if (b.name < a.name) {
    return 1;
  }

  // a debe ser igual b
  return 0;
}

function compareByOrder(a: Item, b: Item) {
  const hasA = typeof a.order === 'number';
  const hasB = typeof b.order === 'number';

  if (hasA && hasB && a.order !== b.order) {
    return (a.order as number) - (b.order as number);
  }

  if (hasA !== hasB) return hasA ? -1 : 1;

  return compareFunction(a, b);
}

export function getSidenavRoutes([docfyNode, clickHandler, options]: [
  DocfyNode | undefined,
  (id: NodeId) => void,
  SidenavOptions?,
]): Item[] {
  return docfyNode
    ? [getItems(docfyNode, clickHandler, docfyNode.name, options ?? {}, 0)]
    : [];
}

/** The lowest `order` among a group's items, at any depth. */
function firstOrder(items: Item[]): number | undefined {
  const orders = items.flatMap((item) =>
    typeof item.order === 'number'
      ? [item.order]
      : item.items.length
        ? [firstOrder(item.items) ?? Infinity]
        : [],
  );
  const lowest = Math.min(...orders);

  return Number.isFinite(lowest) ? lowest : undefined;
}

function getItems(
  docfyNode: DocfyNode,
  clickHandler: (id: NodeId) => void,
  parent: string,
  options: SidenavOptions,
  depth: number,
): Item {
  let items: Item[] = [];

  if (docfyNode.children.length > 0) {
    const children = docfyNode.children;

    items = children.map((child) => {
      return getItems(
        child,
        clickHandler,
        `${parent}-${docfyNode.name}`,
        options,
        depth + 1,
      );
    });
  }

  items = [
    ...items,
    ...(docfyNode.pages
      ?.filter((page) => page.frontmatter?.nav !== false)
      .map((page) => {
        return getItemFromPage(page, clickHandler, options);
      }) ?? []),
  ].sort(options.byOrder ? compareByOrder : compareFunction);

  // a group inside an addon (the sheet's "Validation") sorts by its first
  // page's `order`; the addons themselves (depth 1) keep their name order
  const order = options.byOrder && depth >= 2 ? firstOrder(items) : undefined;

  return {
    name: humanize(docfyNode.label),
    id: `${parent}-${docfyNode.label}`,
    onClick:
      docfyNode.onClick ??
      clickHandler.bind(clickHandler, `${parent}-${docfyNode.label}`),
    items,
    ...(order === undefined ? {} : { order }),
  };
}

function getItemFromPage(
  page: Page,
  clickHandler: (id: NodeId) => void,
  options: SidenavOptions,
): Item {
  const order = Number(page.frontmatter?.order);

  return {
    id: `${page.url}`,
    name: humanize(page.title),
    onClick: clickHandler.bind(clickHandler, page.url),
    items: [],
    ...(options.byOrder && Number.isFinite(order) ? { order } : {}),
  };
}

export default class GetSidenavRoutes extends Helper {
  @service declare docfy: DocfyService;

  compute([name, clickHandler]: [string, (id: NodeId) => void]) {
    return getSidenavRoutes([
      this.docfy.findNestedChildrenByName(name) as unknown as
        DocfyNode | undefined,
      clickHandler,
    ]);
  }
}
