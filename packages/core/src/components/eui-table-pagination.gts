import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { fn } from '@ember/helper';
import { on } from '@ember/modifier';
import { action } from '@ember/object';
import { service } from '@ember/service';

import EuiButtonEmpty from './eui-button-empty.gts';
import EuiContextMenuItem from './eui-context-menu-item.gts';
import EuiContextMenuPanel from './eui-context-menu-panel.gts';
import EuiFlexGroup from './eui-flex-group.gts';
import EuiFlexItem from './eui-flex-item.gts';
import EuiPagination from './eui-pagination.gts';
import EuiPopover from './eui-popover.gts';

import type EuiI18n from '../services/eui-i18n';
import type { EuiPaginationSignature } from './eui-pagination.gts';

/**
 * The pagination under a table: a "Rows per page" menu on the left and
 * the page buttons on the right. You keep the page and the page size.
 */
export interface EuiTablePaginationSignature {
  Element: HTMLDivElement | HTMLSpanElement;
  Args: {
    /** The current page, from `0`. */
    activePage?: number;
    /** Number of pages. */
    pageCount?: number;
    /** Called with the clicked page (from `0`). */
    onChangePage?: (page: number) => void;
    /**
     * Rows per page. Defaults to `10` (upstream). `0` means all rows: the
     * menu reads "Showing all rows" and the pages are hidden.
     */
    itemsPerPage?: number;
    /**
     * Choices of rows per page. Defaults to `[10, 25, 50]` (upstream). `0`
     * is the "Show all rows" choice.
     */
    itemsPerPageOptions?: number[];
    /** Called with the chosen rows per page. */
    onChangeItemsPerPage?: (itemsPerPage: number) => void;
    /** Shows the "Rows per page" menu. Defaults to `true`. */
    showPerPageOptions?: boolean;
    /** @deprecated Use `@showPerPageOptions={{false}}`. Hides the menu. */
    hidePerPageOptions?: boolean;
    /** Passed to `EuiPagination`: "page of total" with arrows. */
    compressed?: boolean;
    /** Passed to `EuiPagination`: breakpoints at which it is compressed. */
    responsive?: EuiPaginationSignature['Args']['responsive'];
    /** Passed to `EuiPagination`: id of the content the pages change. */
    ariaControls?: string;
    /**
     * Accessible name of the pagination navigation (upstream
     * `aria-label`), e.g. "Pagination for table: Users".
     */
    'aria-label'?: string;
    /** Id of the element naming the pagination navigation. */
    'aria-labelledby'?: string;
  };
}

/** Upstream `euiTablePaginationDefaults`. */
const ITEMS_PER_PAGE = 10;
const ITEMS_PER_PAGE_OPTIONS = [10, 25, 50];

export default class EuiTablePagination extends Component<EuiTablePaginationSignature> {
  @service declare euiI18n: EuiI18n;

  @tracked isPopoverOpen = false;

  get itemsPerPage(): number {
    return this.args.itemsPerPage ?? ITEMS_PER_PAGE;
  }

  get options(): number[] {
    return this.args.itemsPerPageOptions ?? ITEMS_PER_PAGE_OPTIONS;
  }

  get showPerPageOptions(): boolean {
    if (this.args.showPerPageOptions !== undefined) {
      return this.args.showPerPageOptions;
    }
    return !this.args.hidePerPageOptions;
  }

  get showPages(): boolean {
    return this.itemsPerPage > 0;
  }

  get buttonLabel(): string {
    if (this.itemsPerPage === 0) {
      return this.euiI18n.lookupToken('euiTablePagination.allRows', 'Showing all rows');
    }
    const rows = this.euiI18n.lookupToken('euiTablePagination.rowsPerPage', 'Rows per page');
    return `${rows}: ${this.itemsPerPage}`;
  }

  optionLabel = (rows: number): string =>
    rows === 0
      ? this.euiI18n.lookupToken(
          'euiTablePagination.rowsPerPageOptionShowAllRows',
          'Show all rows'
        )
      : this.euiI18n.lookupToken('euiTablePagination.rowsPerPageOption', '{rowsPerPage} rows', {
          rowsPerPage: rows
        });

  isCurrent = (rows: number): boolean => rows === this.itemsPerPage;

  @action
  toggle(): void {
    this.isPopoverOpen = !this.isPopoverOpen;
  }

  @action
  close(): void {
    this.isPopoverOpen = false;
  }

  @action
  choose(rows: number): void {
    this.close();
    this.args.onChangeItemsPerPage?.(rows);
  }

  <template>
    <EuiFlexGroup
      @justifyContent="spaceBetween"
      @alignItems="center"
      @responsive={{false}}
      @wrap={{true}}
      @gutterSize="s"
      ...attributes
    >
      <EuiFlexItem @grow={{false}}>
        {{#if this.showPerPageOptions}}
          <EuiPopover
            @isOpen={{this.isPopoverOpen}}
            @closePopover={{this.close}}
            @panelPaddingSize="none"
            @anchorPosition="upRight"
          >
            <:button>
              <EuiButtonEmpty
                @size="xs"
                @color="text"
                @iconType="chevronSingleDown"
                @iconSide="right"
                data-test-subj="tablePaginationPopoverButton"
                {{on "click" this.toggle}}
              >{{this.buttonLabel}}</EuiButtonEmpty>
            </:button>
            <:content>
              <EuiContextMenuPanel data-test-subj="tablePaginationRowOptions">
                {{#each this.options as |rows|}}
                  <EuiContextMenuItem
                    @icon={{if (this.isCurrent rows) "check" "empty"}}
                    aria-current={{if (this.isCurrent rows) "true"}}
                    data-test-subj="tablePagination-{{rows}}-rows"
                    {{on "click" (fn this.choose rows)}}
                  >{{this.optionLabel rows}}</EuiContextMenuItem>
                {{/each}}
              </EuiContextMenuPanel>
            </:content>
          </EuiPopover>
        {{/if}}
      </EuiFlexItem>
      <EuiFlexItem @grow={{false}}>
        {{#if this.showPages}}
          <EuiPagination
            @pageCount={{@pageCount}}
            @activePage={{@activePage}}
            @onPageClick={{@onChangePage}}
            @compressed={{@compressed}}
            @responsive={{@responsive}}
            @ariaControls={{@ariaControls}}
            aria-label={{@aria-label}}
            aria-labelledby={{@aria-labelledby}}
          />
        {{/if}}
      </EuiFlexItem>
    </EuiFlexGroup>
  </template>
}
