import Helper from "@ember/component/helper";
import { humanize } from "ember-cli-string-helpers/helpers/humanize";
import { inject as service } from "@ember/service";

type Page = {
  id: string;
  url: string;
  title: string;
};

export type NodeId = string | number | undefined;

type DocfyNode = {
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
    items = children.map((child) => getItems(child, clickHandler, parent));
  }
  items = [
    ...items,
    ...docfyNode.pages.map((page) => {
      return getItemFromPage(page, clickHandler);
    }),
  ].sort(compareFunction);
  return {
    name: humanize([docfyNode.label]),
    id: `${parent}-${docfyNode.label}`,
    onClick:
      docfyNode.onClick ??
      clickHandler.bind(clickHandler, `${parent}-${docfyNode.label}`),
    items,
  };
}

function getItemFromPage(page: Page, clickHandler: (id: NodeId) => void): Item {
  return {
    id: `${page.url}`,
    href: page.url,
    name: humanize([page.title]),
    onClick: clickHandler.bind(clickHandler, page.url),
    items: [],
  };
}

export default class GetSidenavRoutes extends Helper {
  @service docfy: any;
  compute([name, clickHandler]: [string, (id: NodeId) => void]) {
    return getSidenavRoutes([
      this.docfy.findNestedChildrenByName(name),
      clickHandler,
    ]);
  }
}
