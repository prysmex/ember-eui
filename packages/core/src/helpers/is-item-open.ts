import { helper } from '@ember/component/helper';

interface SideNavItemLike {
  id?: string;
  isSelected?: boolean;
  forceOpen?: boolean;
  items?: SideNavItemLike[];
}

/**
 * Whether an EuiSideNav item is the current one: its own `isSelected` (as
 * upstream) or its `id` matching the side nav's `@selectedItem`.
 */
export function isItemSelected(
  item: SideNavItemLike,
  selectedItem?: string
): boolean {
  return Boolean(
    item.isSelected || (selectedItem !== undefined && item.id === selectedItem)
  );
}

export function isItemOpen(item: any, selectedItem?: string): boolean {
  // The developer can force the item to be open.
  if (item.forceOpen) {
    return true;
  }

  // Of course a selected item is open.
  if (isItemSelected(item, selectedItem)) {
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
export function isItemOpenHelper([item, selectedItem]: [any, string?]): boolean {
  return isItemOpen(item, selectedItem);
}

export default helper(isItemOpenHelper);
