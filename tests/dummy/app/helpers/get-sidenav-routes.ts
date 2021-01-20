import { helper } from '@ember/component/helper';
import { humanize } from 'ember-cli-string-helpers/helpers/humanize';

type Page = {
  id: string;
  url: string;
  title: string;
}

type DocfyNode = {
  id: string | number | undefined;
  label: string;
  name: string;
  children: DocfyNode[];
  pages: Page[];
  onClick: boolean | (() => unknown);
}

type Item = {
  id: string | number | undefined;
  href?: string | undefined;
  label?: string;
  name: string;
  items: Item[];
  onClick: boolean | (() => unknown);
}



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
export function getSidenavRoutes([docfyNode, clickHandler]: [DocfyNode, () => unknown]) {
  let navigation = docfyNode.children.map((child) =>
    getItems({ ...child, onClick: false }, clickHandler)
  );
  return navigation;
}

function getItems(docfyNode: DocfyNode, clickHandler: () => unknown) : Item {
  let items: Item[] = [];
  if (docfyNode.children.length > 0) {
    items = docfyNode.children.map((child) => getItems(child, clickHandler));
  }

  items = [
    ...items,
    ...docfyNode.pages.map((page) => {
      return getItemFromPage(page, clickHandler);
    }),
  ].sort(compareFunction);

  return {
    name: humanize([docfyNode.label]),
    id: docfyNode.label,
    onClick: docfyNode.onClick ?? clickHandler.bind(clickHandler, docfyNode.label),
    items,
  };
}

function getItemFromPage(page: Page, clickHandler: () => unknown) : Item {
  return {
    id: page.title,
    href: page.url,
    name: humanize([page.title]),
    onClick: clickHandler.bind(clickHandler, page.title),
    items: [],
  };
}

export default helper(getSidenavRoutes);
