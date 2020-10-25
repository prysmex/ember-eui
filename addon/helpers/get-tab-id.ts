import { helper } from '@ember/component/helper';
import { assert } from '@ember/debug';

export function getTabId([tabOrId]: [Tab | string | number]): string | number | undefined {
  if (tabOrId === undefined) {
    return;
  }

  if (typeof tabOrId === 'string' || typeof tabOrId === 'number') {
    return tabOrId;
  }

  assert('The passed `tab` object needs to have the `id` property', tabOrId.id !== undefined);
  return tabOrId.id;
}

export default helper(getTabId);
