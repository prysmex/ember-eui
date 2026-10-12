import Component from '@glimmer/component';
import { cached, tracked } from '@glimmer/tracking';
import { on } from '@ember/modifier';
import { action } from '@ember/object';
import { service } from '@ember/service';

import EuiButtonEmpty from './eui-button-empty.gts';
import EuiContextMenuPanel from './eui-context-menu-panel.gts';
import EuiPopover from './eui-popover.gts';
import EuiTableSortMobileItem from './eui-table-sort-mobile-item.gts';
import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { euiClass } from '../utils/eui/styles.ts';

import type EuiI18n from '../services/eui-i18n';
import type { EuiPopoverSignature } from './eui-popover';

export interface EuiTableSortMobileItemOption {
  /** Unique key. */
  key?: string;
  /** The column's name. */
  name: string;
  /** Sorts by this column. */
  onSort?: (event: MouseEvent) => void;
  /** The table is sorted by this column. */
  isSorted?: boolean;
  /** Ascending order. */
  isSortAscending?: boolean;
}

/**
 * A "Sorting" button opening a menu of the sortable columns, for small
 * screens where a responsive `EuiTable` hides its header. Usually in an
 * `EuiTableHeaderMobile`.
 */
export interface EuiTableSortMobileSignature {
  Element: HTMLDivElement;
  Args: {
    /** The sortable columns. */
    items?: EuiTableSortMobileItemOption[];
    /** Where the menu opens. Defaults to `'downRight'`. */
    anchorPosition?: EuiPopoverSignature['Args']['anchorPosition'];
  };
}

// Upstream: aligns the button to the end even when it is alone.
const ROOT = { marginInlineStart: 'auto', label: 'euiTableSortMobile' } as const;

export default class EuiTableSortMobile extends Component<EuiTableSortMobileSignature> {
  @service declare euiI18n: EuiI18n;

  @tracked isPopoverOpen = false;

  get label(): string {
    return this.euiI18n.lookupToken('euiTableSortMobile.sorting', 'Sorting');
  }

  @cached
  get classes(): string {
    return euiClass(getEuiThemeContext(this), ROOT);
  }

  @action
  toggle(): void {
    this.isPopoverOpen = !this.isPopoverOpen;
  }

  @action
  close(): void {
    this.isPopoverOpen = false;
  }

  <template>
    <div class="euiTableSortMobile {{this.classes}}" ...attributes>
      <EuiPopover
        @isOpen={{this.isPopoverOpen}}
        @closePopover={{this.close}}
        @anchorPosition={{if @anchorPosition @anchorPosition "downRight"}}
        @panelPaddingSize="none"
      >
        <:button>
          <EuiButtonEmpty
            @iconType="arrowDown"
            @iconSide="right"
            @flush="right"
            @size="xs"
            {{on "click" this.toggle}}
          >{{this.label}}</EuiButtonEmpty>
        </:button>
        <:content>
          <EuiContextMenuPanel style="min-width: 200px;">
            {{#each @items as |item|}}
              <EuiTableSortMobileItem
                @onSort={{item.onSort}}
                @isSorted={{item.isSorted}}
                @isSortAscending={{item.isSortAscending}}
                @ariaLabel={{item.name}}
              >{{item.name}}</EuiTableSortMobileItem>
            {{/each}}
          </EuiContextMenuPanel>
        </:content>
      </EuiPopover>
    </div>
  </template>
}
