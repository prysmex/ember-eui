import Helper from '@ember/component/helper';
import { inject as service } from '@ember/service';

function humanize(str?: string) {
  return str
    ?.replace(/^[\s_]+|[\s_]+$/g, '')
    .replace(/[_\s]+/g, ' ')
    .replace(/[-\s]+/g, ' ')
    .replace(/^[a-z]/, function (m) {
      return m.toUpperCase();
    }) ?? '';
}

export type Heading = {
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

export function getSidenavRoutes([docfyNode, clickHandler]: [
  DocfyNode,
  (id: NodeId) => void
]) {
  return [getItems(docfyNode, clickHandler, docfyNode.name)];
}

function getItems(
  docfyNode: DocfyNode,
  clickHandler: (id: NodeId) => void,
  parent: string
): Item {
  let items: Item[] = [];

  if (docfyNode.children.length > 0) {
    let children = docfyNode.children;

    items = children.map((child) => {
      return getItems(child, clickHandler, `${parent}-${docfyNode.name}`);
    });
  }

  items = [
    ...items,
    ...(docfyNode.pages?.map((page) => {
      return getItemFromPage(page, clickHandler);
    }) ?? [])
  ].sort(compareFunction);

  return {
    name: humanize(docfyNode.label),
    id: `${parent}-${docfyNode.label}`,
    onClick:
      docfyNode.onClick ??
      clickHandler.bind(clickHandler, `${parent}-${docfyNode.label}`),
    items
  };
}

function getItemFromPage(page: Page, clickHandler: (id: NodeId) => void): Item {
  return {
    id: `${page.url}`,
    name: humanize(page.title),
    onClick: clickHandler.bind(clickHandler, page.url),
    items: []
  };
}

export default class GetSidenavRoutes extends Helper {
  @service docfy: any;
  compute([name, clickHandler]: [string, (id: NodeId) => void]) {
    return getSidenavRoutes([
      this.docfy.findNestedChildrenByName(name),
      clickHandler
    ]);
  }
}
