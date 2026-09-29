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
    /** Rows per page. Defaults to `50`. */
    itemsPerPage?: number;
    /** Choices of rows per page. Defaults to `[10, 20, 50, 100]`. */
    itemsPerPageOptions?: number[];
    /** Called with the chosen rows per page. */
    onChangeItemsPerPage?: (itemsPerPage: number) => void;
    /** Hides the "Rows per page" menu. */
    hidePerPageOptions?: boolean;
    /** Smaller page buttons. */
    compressed?: boolean;
  };
}

export default class EuiTablePagination extends Component<EuiTablePaginationSignature> {
  @service declare euiI18n: EuiI18n;

  @tracked isPopoverOpen = false;

  get itemsPerPage(): number {
    return this.args.itemsPerPage ?? 50;
  }

  get options(): number[] {
    return this.args.itemsPerPageOptions ?? [10, 20, 50, 100];
  }

  get rowsPerPage(): string {
    return this.euiI18n.lookupToken('euiTablePagination.rowsPerPage', 'Rows per page');
  }

  optionLabel = (rows: number): string =>
    this.euiI18n.lookupToken('euiTablePagination.rowsPerPageOption', '{rowsPerPage} rows', {
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
      ...attributes
    >
      <EuiFlexItem @grow={{false}}>
        {{#unless @hidePerPageOptions}}
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
                @iconType="arrowDown"
                @iconSide="right"
                data-test-subj="tablePaginationPopoverButton"
                {{on "click" this.toggle}}
              >{{this.rowsPerPage}}: {{this.itemsPerPage}}</EuiButtonEmpty>
            </:button>
            <:content>
              <EuiContextMenuPanel>
                {{#each this.options as |rows|}}
                  <EuiContextMenuItem
                    @icon={{if (this.isCurrent rows) "check" "empty"}}
                    data-test-subj="tablePagination-{{rows}}-rows"
                    {{on "click" (fn this.choose rows)}}
                  >{{this.optionLabel rows}}</EuiContextMenuItem>
                {{/each}}
              </EuiContextMenuPanel>
            </:content>
          </EuiPopover>
        {{/unless}}
      </EuiFlexItem>
      <EuiFlexItem @grow={{false}}>
        <EuiPagination
          @pageCount={{@pageCount}}
          @activePage={{@activePage}}
          @onPageClick={{@onChangePage}}
          @compressed={{@compressed}}
        />
      </EuiFlexItem>
    </EuiFlexGroup>
  </template>
}
