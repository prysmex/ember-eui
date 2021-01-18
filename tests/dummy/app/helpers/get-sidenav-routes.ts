import { helper } from '@ember/component/helper';
import { humanize } from 'ember-cli-string-helpers/helpers/humanize';

function compareFunction(a, b) {
  if (a.name < b.name) {
    return -1;
  }
  if (b.name < a.name) {
    return 1;
  }
  // a debe ser igual b
  return 0;
}
export function getSidenavRoutes([docfyNode, clickHandler]) {
  let navigation = docfyNode.children.map((child) =>
    getItems({ ...child, onClick: false }, clickHandler)
  );
  return navigation;
}

function getItems(node, clickHandler) {
  let items = [];
  if (node.children.length > 0) {
    items = node.children.map((child) => getItems(child, clickHandler));
  }

  items = [
    ...items,
    ...node.pages.map((page) => {
      return getItemFromPage(page, clickHandler);
    }),
  ].sort(compareFunction);

  return {
    name: humanize([node.label]),
    id: node.label,
    onClick: node.onClick ?? clickHandler.bind(clickHandler, node.label),
    items,
  };
}

function getItemFromPage(page, clickHandler) {
  return {
    ...page,
    id: page.title,
    href: page.url,
    name: humanize([page.title]),
    onClick: clickHandler.bind(clickHandler, page.title),
    items: [],
  };
}

export default helper(getSidenavRoutes);
