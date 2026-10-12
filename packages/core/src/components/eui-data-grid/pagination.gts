import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';
import { action } from '@ember/object';
import { service } from '@ember/service';

import { getEuiThemeContext } from '../../utils/emotion/consume.ts';
import { euiClass, useEuiBorealisStyles } from '../../utils/eui/styles.ts';
import { euiDataGridPaginationStyles } from '../../utils/eui/styles.generated.ts';
import EuiTablePagination from '../eui-table-pagination.gts';

import type EuiI18n from '../../services/eui-i18n.ts';
import type EuiDataGrid from '../eui-data-grid.gts';
import type { EuiDataGridPaginationProps } from '../../utils/data-grid/types.ts';

/**
 * Do not render the pagination when the row count is below the smallest
 * page size option (or the page size without options).
 */
export function shouldRenderPagination(
  rowCount: number,
  { pageSize, pageSizeOptions }: { pageSize?: number; pageSizeOptions?: number[] }
): boolean {
  const minSizeOption = [...(pageSizeOptions ?? [])].sort((a, b) => a - b)[0];
  return !(rowCount < (minSizeOption || pageSize || 0));
}

export interface EuiDataGridPaginationSignature {
  Args: {
    grid: EuiDataGrid;
    pagination: EuiDataGridPaginationProps & { pageSize: number; pageSizeOptions: number[] };
  };
}

/** EuiTablePagination below the grid, controlling the grid body. */
export default class EuiDataGridPagination extends Component<EuiDataGridPaginationSignature> {
  @service declare euiI18n: EuiI18n;

  @cached
  get classes(): string {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiDataGridPaginationStyles);
    return `euiDataGrid__pagination ${euiClass(context, styles.euiDataGrid__pagination)}`;
  }

  get pageCount(): number {
    const { pageSize } = this.args.pagination;
    return pageSize ? Math.ceil(this.args.grid.args.rowCount / pageSize) : 1;
  }

  get ariaLabel(): string {
    const label = this.args.grid.rawAriaLabel;
    return label
      ? this.euiI18n.lookupToken(
          'euiDataGridPagination.detailedPaginationLabel',
          'Pagination for preceding grid: {label}',
          { label }
        )
      : this.euiI18n.lookupToken(
          'euiDataGridPagination.paginationLabel',
          'Pagination for preceding grid'
        );
  }

  /** Focus the first data cell & scroll to the top whenever the page changes. */
  @action
  onChangePage(pageIndex: number): void {
    this.args.pagination.onChangePage(pageIndex);
    this.args.grid.setFocusedCell([0, 0]);
  }

  <template>
    <div class={{this.classes}}>
      <EuiTablePagination
        @ariaControls={{@grid.gridId}}
        @activePage={{@pagination.pageIndex}}
        @itemsPerPage={{@pagination.pageSize}}
        @itemsPerPageOptions={{@pagination.pageSizeOptions}}
        @showPerPageOptions={{if @pagination.pageSizeOptions.length true false}}
        @pageCount={{this.pageCount}}
        @onChangePage={{this.onChangePage}}
        @onChangeItemsPerPage={{@pagination.onChangeItemsPerPage}}
        aria-label={{this.ariaLabel}}
      />
    </div>
  </template>
}
