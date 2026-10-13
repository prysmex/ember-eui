/**
 * Ember EUI extension (row-tree): the logic behind the `@rowTree`/`@grouping`
 * hooks in the ported upstream data grid files. Each hook in those files is
 * a single call into this module (or `row-model.ts`), marked with
 * `ember-eui extension (row-tree)`, so re-porting upstream only means
 * re-applying the marked lines. See
 * `internal/spikes/eui-latest/data-grid-extensions.md`.
 */
import { modifier } from 'ember-modifier';

import { afterRender } from '../../utils/data-grid/scheduling.ts';
import * as keys from '../../utils/keys.ts';

import type EuiDataGrid from '../eui-data-grid.gts';
import type { RowTreeVisibleRow } from '../../utils/data-grid/row-tree.ts';
import type { EuiDataGridColumn } from '../../utils/data-grid/types.ts';

/* ------------------------------------------------------------------------ */
/* Cells                                                                    */
/* ------------------------------------------------------------------------ */

export interface RowTreeCellState {
  /** The tree row shown by the cell (undefined without the args). */
  row: RowTreeVisibleRow | undefined;
  isGroupRow: boolean;
  /** The cell holding the indentation and the toggle. */
  isToggleCell: boolean;
  /** The row object, passed to renderers as `@row`. */
  rowData: unknown;
}

const NO_TREE: RowTreeCellState = {
  row: undefined,
  isGroupRow: false,
  isToggleCell: false,
  rowData: undefined
};

/** Tree state of a cell (`cell.gts` `rowTree` getter). */
export function rowTreeCellState(
  grid: EuiDataGrid,
  {
    visibleRowIndex,
    rowIndex,
    column,
    isFooter
  }: { visibleRowIndex: number; rowIndex: number; column: EuiDataGridColumn | undefined; isFooter?: boolean }
): RowTreeCellState {
  const rowModel = grid.rowModel;
  if (!rowModel || isFooter) return NO_TREE;
  const row = rowModel.visibleRowAt(visibleRowIndex, grid.visibleRows.startRow);
  const toggleColumnId = rowModel.toggleColumnId ?? grid.columns[0]?.id;
  return {
    row,
    isGroupRow: row?.kind === 'group',
    isToggleCell: !!row && !!column && column.id === toggleColumnId,
    rowData: rowModel.rowAt(rowIndex)
  };
}

/**
 * Keyboard in the toggle cell, following the WAI-ARIA treegrid pattern:
 *
 * - Space toggles; Enter toggles when the cell has no popover to open and
 *   no interactive content to enter.
 * - ArrowRight expands a collapsed row (otherwise the grid moves right).
 * - ArrowLeft collapses an expanded row, or moves to the parent row's toggle
 *   cell (top-level rows: the grid moves left).
 *
 * Only when the cell itself has focus: not while its popover is open or its
 * interactive content (focus trap, editing) has focus. Returns whether the
 * key was handled.
 */
export function handleRowTreeCellKeyDown(
  event: KeyboardEvent,
  {
    grid,
    tree,
    cellElement,
    colIndex,
    isExpandable,
    isPopoverOpen,
    hasFocusTrap
  }: {
    grid: EuiDataGrid;
    tree: RowTreeCellState;
    cellElement: HTMLElement | null;
    colIndex: number;
    isExpandable: boolean;
    isPopoverOpen: boolean;
    /** Enter enters cells with interactive content instead. */
    hasFocusTrap: boolean;
  }
): boolean {
  const row = tree.row;
  if (!row || !tree.isToggleCell || isPopoverOpen) return false;
  if (event.target !== cellElement) return false;
  if (event.ctrlKey || event.metaKey || event.altKey || event.shiftKey) return false;
  switch (event.key) {
    case keys.SPACE:
      if (!row.hasChildren) return false;
      grid.toggleRow(row);
      break;
    case keys.ENTER:
      if (!row.hasChildren || isExpandable || hasFocusTrap) return false;
      grid.toggleRow(row);
      break;
    case keys.ARROW_RIGHT:
      if (!row.hasChildren || row.isExpanded) return false;
      grid.toggleRow(row);
      event.stopPropagation(); // the grid would move right
      break;
    case keys.ARROW_LEFT:
      if (row.hasChildren && row.isExpanded) {
        grid.toggleRow(row);
      } else if (row.parentId != null) {
        focusParentRow(grid, row.parentId, colIndex);
      } else {
        return false;
      }
      event.stopPropagation(); // the grid would move left
      break;
    default:
      return false;
  }
  event.preventDefault();
  return true;
}

function focusParentRow(grid: EuiDataGrid, parentId: string, colIndex: number): void {
  const rowModel = grid.rowModel;
  if (!rowModel) return;
  const index = rowModel.visibleRows.findIndex((row) => row.id === parentId);
  if (index === -1) return;
  const pagination = grid.pagination;
  if (pagination && pagination.pageSize > 0) {
    const pageIndex = Math.floor(index / pagination.pageSize);
    if (pageIndex !== pagination.pageIndex) pagination.onChangePage(pageIndex);
    grid.setFocusedCell([colIndex, index % pagination.pageSize]);
  } else {
    grid.setFocusedCell([colIndex, index]);
  }
}

/* ------------------------------------------------------------------------ */
/* Rows                                                                     */
/* ------------------------------------------------------------------------ */

export interface RowTreeRowAttributes {
  level?: number;
  expanded?: string;
  setSize?: number;
  posInSet?: number;
  className?: string;
}

const NO_ROW_ATTRIBUTES: RowTreeRowAttributes = {};

/** Treegrid ARIA attributes and class of a `role=row` (`row.gts`). */
export function rowTreeRowAttributes(grid: EuiDataGrid, visibleRowIndex: number): RowTreeRowAttributes {
  const rowModel = grid.rowModel;
  if (!rowModel) return NO_ROW_ATTRIBUTES;
  const row = rowModel.visibleRowAt(visibleRowIndex, grid.visibleRows.startRow);
  if (!row) return NO_ROW_ATTRIBUTES;
  return {
    level: row.depth + 1,
    expanded: row.hasChildren ? String(row.isExpanded) : undefined,
    setSize: row.setSize,
    posInSet: row.posInSet,
    className: row.kind === 'group' ? 'euiDataGridRow--group' : undefined
  };
}

/* ------------------------------------------------------------------------ */
/* Grid                                                                     */
/* ------------------------------------------------------------------------ */

/**
 * Collapsing rows can leave the page index past the last page: move to the
 * last page (only with `@rowTree`/`@grouping`).
 */
export const clampRowTreePageIndex = modifier(
  (
    _element: HTMLElement,
    [grid, rowCount, pageIndex, pageSize]: [EuiDataGrid, number, number | undefined, number | undefined]
  ) => {
    if (!grid.rowModel || pageIndex == null || !pageSize || rowCount === 0) return;
    const lastPage = Math.ceil(rowCount / pageSize) - 1;
    if (pageIndex > lastPage) afterRender(grid, () => grid.pagination?.onChangePage(lastPage));
  }
);
