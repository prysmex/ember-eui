import { helper } from '@ember/component/helper';

export function isItemOpen(item: any, selectedItem: string): boolean {
  // The developer can force the item to be open.
  if (item.forceOpen) {
    return true;
  }

	// Of course a selected item is open.
	if(item.id === selectedItem) {
		return true;
	}

  // The item has to be open if it has a child that's open.
  if (item.items) {
    return item.items.some((item: any) => isItemOpen(item, selectedItem));
  }

  return false;
}

/**
 * Retuns wether an item is open taking into account his childs
 *
 * @param { any } ref
 */
export function isItemOpenHelper([item, selectedItem]: [any, string]): boolean {
  return isItemOpen(item, selectedItem);
}

export default helper(isItemOpenHelper);
