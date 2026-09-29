import { on } from '@ember/modifier';

import EuiContextMenuItem from './eui-context-menu-item.gts';

import type { TemplateOnlyComponent } from '@ember/component/template-only';

/** A column in the `EuiTableSortMobile` menu. */
export interface EuiTableSortMobileItemSignature {
  Element: HTMLButtonElement | HTMLAnchorElement;
  Args: {
    /** Sorts by this column. */
    onSort?: (event: MouseEvent) => void;
    /** The table is sorted by this column. */
    isSorted?: boolean;
    /** Ascending order (arrow up); descending otherwise. */
    isSortAscending?: boolean;
    /** The column's name, for the accessible label (defaults to the text). */
    ariaLabel?: string;
  };
  Blocks: {
    /** The column's name. */
    default: [];
  };
}

function icon(isSorted?: boolean, isSortAscending?: boolean): string {
  if (!isSorted) return 'empty';

  return isSortAscending ? 'sortUp' : 'sortDown';
}

function noop(): void {}

const EuiTableSortMobileItem: TemplateOnlyComponent<EuiTableSortMobileItemSignature> = <template>
  <EuiContextMenuItem
    class="euiTableSortMobileItem {{if @isSorted 'euiTableSortMobileItem-isSorted'}}"
    @icon={{icon @isSorted @isSortAscending}}
    aria-label={{if @ariaLabel (label @ariaLabel @isSortAscending)}}
    {{on "click" (if @onSort @onSort noop)}}
    ...attributes
  >{{yield}}</EuiContextMenuItem>
</template>;

function label(column: string, isSortAscending?: boolean): string {
  return `Sort ${column} ${isSortAscending ? 'descending' : 'ascending'}`;
}

export default EuiTableSortMobileItem;
