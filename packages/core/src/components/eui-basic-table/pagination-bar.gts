import Component from '@glimmer/component';
import { cached, tracked } from '@glimmer/tracking';
import { next } from '@ember/runloop';

import { modifier } from 'ember-modifier';

import {
  DEFAULT_TABLE_BREAKPOINT,
  isTableResponsive,
  minBreakpointQuery,
  onMediaQueryChange
} from '../../-private/table.ts';
import { getEuiThemeContext } from '../../utils/emotion/consume.ts';
import { euiClass, useEuiBorealisStyles } from '../../utils/eui/styles.ts';
import { euiBasicTablePaginationBarStyles } from '../../utils/eui/styles.generated.ts';
import EuiTablePagination from '../eui-table-pagination.gts';

import type { Pagination } from '../../-private/basic-table.ts';
import type { TableResponsiveBreakpoint } from '../../-private/table.ts';

/** Upstream `euiTablePaginationDefaults`. */
export const PAGINATION_DEFAULTS = {
  itemsPerPage: 10,
  itemsPerPageOptions: [10, 25, 50],
  showPerPageOptions: true
};

/**
 * @private The pagination under an `EuiBasicTable` (upstream
 * `PaginationBar`): an `EuiTablePagination` with the panelled look, which
 * moves back to the last page when the current one no longer exists.
 */
export interface PaginationBarSignature {
  Element: HTMLDivElement;
  Args: {
    pagination: Pagination;
    panelled?: boolean;
    responsiveBreakpoint?: TableResponsiveBreakpoint;
    onPageSizeChange: (size: number) => void;
    onPageChange: (index: number) => void;
    /** Id of the table being controlled. */
    ariaControls?: string;
    /** Accessible name of the pagination navigation. */
    ariaLabel?: string;
  };
}

export default class PaginationBar extends Component<PaginationBarSignature> {
  @tracked private mediaVersion = 0;

  get pageSize(): number {
    return this.args.pagination.pageSize ?? PAGINATION_DEFAULTS.itemsPerPage;
  }

  get pageCount(): number {
    const { totalItemCount } = this.args.pagination;
    return this.pageSize ? Math.ceil(totalItemCount / this.pageSize) : 1;
  }

  get breakpoint(): TableResponsiveBreakpoint {
    return this.args.responsiveBreakpoint ?? DEFAULT_TABLE_BREAKPOINT;
  }

  @cached
  get query(): string | undefined {
    return minBreakpointQuery(getEuiThemeContext(this).upstream, this.breakpoint);
  }

  @cached
  get isResponsive(): boolean {
    void this.mediaVersion;
    return isTableResponsive(this.breakpoint, this.query);
  }

  onBreakpointChange = (): void => {
    this.mediaVersion++;
  };

  @cached
  get classes(): string {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiBasicTablePaginationBarStyles);
    return euiClass(
      context,
      styles.root,
      !this.isResponsive && this.args.panelled ? styles.panelled : undefined
    );
  }

  /** Upstream effect: go back to the last page that exists. */
  keepPageInRange = modifier(
    (_element: Element, [pageCount, pageIndex]: [number, number]) => {
      if (pageCount < pageIndex + 1) {
        next(() => this.args.onPageChange?.(pageCount - 1));
      }
    }
  );

  <template>
    <div
      class={{this.classes}}
      {{onMediaQueryChange this.query this.onBreakpointChange}}
      {{this.keepPageInRange this.pageCount @pagination.pageIndex}}
    >
      <EuiTablePagination
        @activePage={{@pagination.pageIndex}}
        @showPerPageOptions={{if (isFalse @pagination.showPerPageOptions) false true}}
        @itemsPerPage={{this.pageSize}}
        @itemsPerPageOptions={{if
          @pagination.pageSizeOptions
          @pagination.pageSizeOptions
          PAGINATION_DEFAULTS.itemsPerPageOptions
        }}
        @pageCount={{this.pageCount}}
        @onChangeItemsPerPage={{@onPageSizeChange}}
        @onChangePage={{@onPageChange}}
        @ariaControls={{@ariaControls}}
        @aria-label={{@ariaLabel}}
      />
    </div>
  </template>
}

function isFalse(value: unknown): boolean {
  return value === false;
}
