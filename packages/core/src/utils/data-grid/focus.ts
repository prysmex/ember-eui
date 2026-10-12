/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License
 * 2.0 and the Server Side Public License, v 1; you may not use this file except
 * in compliance with, at your election, the Elastic License 2.0 or the Server
 * Side Public License, v 1.
 */

/**
 * Ports of EUI 123.1.0 `components/datagrid/utils/focus.ts` (keyboard
 * navigation, tab management) and `body/cell/focus_utils.tsx` helpers.
 */
import { tabbable } from 'tabbable';

import * as keys from '../keys.ts';

import type {
  EuiDataGridFocusedCell,
  EuiDataGridPaginationProps
} from './types.ts';

export interface DataGridKeyDownOptions {
  gridElement: HTMLElement | null;
  visibleColCount: number;
  visibleRowCount: number;
  visibleRowStartIndex: number;
  rowCount: number;
  pagination?: EuiDataGridPaginationProps & { pageSize: number };
  hasFooter: boolean;
  focusedCell: EuiDataGridFocusedCell | undefined;
  setFocusedCell: (cell: EuiDataGridFocusedCell) => void;
}

/** Keydown handler connecting focus state with keyboard navigation. */
export function handleGridKeyDown(
  event: KeyboardEvent,
  {
    gridElement,
    visibleColCount,
    visibleRowCount,
    visibleRowStartIndex,
    rowCount,
    pagination,
    hasFooter,
    focusedCell,
    setFocusedCell
  }: DataGridKeyDownOptions
): void {
  if (focusedCell == null) return;
  if (gridElement == null || !gridElement.contains(document.activeElement)) {
    // the key event did not come from inside the grid (e.g. a portaled popover)
    return;
  }
  const [x, y] = focusedCell;
  const { key, ctrlKey } = event;

  if (key === keys.ARROW_DOWN) {
    event.preventDefault();
    if (hasFooter ? y < visibleRowCount : y < visibleRowCount - 1) {
      if (y === -1) {
        // The header is sticky, so on scrolled virtualized grids row 0 is not
        // always rendered; move to the first visible row instead
        setFocusedCell([x, visibleRowStartIndex]);
      } else {
        setFocusedCell([x, y + 1]);
      }
    }
  } else if (key === keys.ARROW_LEFT) {
    event.preventDefault();
    if (x > 0) setFocusedCell([x - 1, y]);
  } else if (key === keys.ARROW_UP) {
    event.preventDefault();
    if (y > -1) setFocusedCell([x, y - 1]);
  } else if (key === keys.ARROW_RIGHT) {
    event.preventDefault();
    if (x < visibleColCount - 1) setFocusedCell([x + 1, y]);
  } else if (key === keys.PAGE_DOWN) {
    if (pagination && pagination.pageSize > 0) {
      event.preventDefault();
      const pageCount = Math.ceil(rowCount / pagination.pageSize);
      if (pagination.pageIndex < pageCount - 1) {
        pagination.onChangePage(pagination.pageIndex + 1);
      }
      setFocusedCell([x, 0]);
    }
  } else if (key === keys.PAGE_UP) {
    if (pagination && pagination.pageSize > 0) {
      event.preventDefault();
      if (pagination.pageIndex > 0) {
        pagination.onChangePage(pagination.pageIndex - 1);
      }
      setFocusedCell([x, pagination.pageSize - 1]);
    }
  } else if (ctrlKey && key === keys.END) {
    event.preventDefault();
    setFocusedCell([visibleColCount - 1, visibleRowCount - 1]);
  } else if (ctrlKey && key === keys.HOME) {
    event.preventDefault();
    setFocusedCell([0, 0]);
  } else if (key === keys.END) {
    event.preventDefault();
    setFocusedCell([visibleColCount - 1, y]);
  } else if (key === keys.HOME) {
    event.preventDefault();
    setFocusedCell([0, y]);
  }
}

/**
 * Mutation observer callback for the grid body: removes interactive elements
 * that appear in cells from the tab order (cells are navigated with arrows).
 */
export function preventTabbing(records: MutationRecord[]): void {
  // multiple mutation records can implicate the same cell
  const processedCells = new Set<HTMLElement | null>();
  for (const record of records) {
    const cell = getParentCellContent(record.target);
    if (processedCells.has(cell)) continue;
    processedCells.add(cell);
    if (cell) {
      for (const element of tabbable(cell)) {
        if (!element.hasAttribute('data-euigrid-tab-managed')) {
          element.setAttribute('tabIndex', '-1');
          element.setAttribute('data-datagrid-interactable', 'true');
        }
      }
    }
  }
}

/** The `div[data-datagrid-cellcontent]` owning a node, if any. */
export function getParentCellContent(node: Node): HTMLElement | null {
  let element: HTMLElement | null =
    node.nodeType === Node.ELEMENT_NODE
      ? (node as HTMLElement)
      : node.parentElement;
  while (element && !element.hasAttribute('data-datagrid-cellcontent')) {
    element = element.parentElement;
  }
  return element;
}

/**
 * Take every interactive child of a cell out of the tab order. Returns all
 * managed children, including ones a previous call already disabled.
 */
export function disableInteractives(cell: HTMLElement): Element[] {
  for (const element of tabbable(cell)) {
    element.setAttribute('data-euigrid-tab-managed', 'true');
    element.setAttribute('tabindex', '-1');
  }
  return Array.from(cell.querySelectorAll('[data-euigrid-tab-managed]'));
}

/** Restore the managed interactive children and focus the first one. */
export function enableAndFocusInteractives(cell: HTMLElement): void {
  const interactives = cell.querySelectorAll<HTMLElement>(
    '[data-euigrid-tab-managed]'
  );
  interactives.forEach((element, i) => {
    element.setAttribute('tabindex', '0');
    // focus the first element only if we're on the cell and not inside of it
    if (i === 0 && !cell.contains(document.activeElement)) element.focus();
  });
}

/** Copies the focused data cell value when nothing is selected. */
export function copyFocusedDataGridCell(event: ClipboardEvent): void {
  if (event.defaultPrevented) return;
  const cell = document.activeElement;
  if (!(cell instanceof HTMLElement)) return;
  if (!cell.classList.contains('euiDataGridRowCell')) return;
  if (cell.classList.contains('euiDataGridRowCell--controlColumn')) return;
  if (window.getSelection()?.toString()) return;
  if (!event.clipboardData) return;
  const cellContent = cell.querySelector<HTMLElement>('[data-datagrid-cellcontent]');
  const text = cellContent?.innerText ?? cellContent?.textContent ?? '';
  if (!text) return;
  event.clipboardData.setData('text/plain', text);
  event.preventDefault();
}
