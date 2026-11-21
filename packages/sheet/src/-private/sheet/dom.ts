/** The grid's DOM: cell and header lookups, focus by position, boxes (V03C-DESIGN.md 3.2). */
import { assert } from '@ember/debug';

import { EDITOR_SURFACE_SELECTOR } from '../editor-frame.gts';
import { FIELD_EDITOR_SELECTOR } from '../field-editor.gts';
import { LAYER_SELECTOR } from '../layer.gts';
import { ADD_FIELD_COLUMN_ID, ROW_COLUMN_ID } from './util.ts';

import type EuiSheet from '../../components/eui-sheet.gts';
import type { Pos } from '../../core/index.ts';
import type { SheetEditorRect } from '../../types.ts';
import type { LayerAnchor } from '../layer.gts';
import type { WrapperBox } from './types.ts';

export default class SheetDom<T extends object> {
  sheet: EuiSheet<T>;

  constructor(sheet: EuiSheet<T>) {
    this.sheet = sheet;
  }

  /** Focuses a cell by its position (data column). */
  focusGridCell(pos: Pos): void {
    this.sheet.frozen.noteScrollLeft();
    this.sheet.gridApi?.setFocusedCell({
      rowIndex: pos.row,
      colIndex: pos.col + this.sheet.colOffset
    });
  }

  /** The rendered grid cell at a position, if it is rendered. */
  cellElement(pos: Pos): HTMLElement | null {
    return (
      this.sheet.wrapper?.querySelector<HTMLElement>(
        `[role=gridcell][data-gridcell-visible-row-index="${pos.row}"][data-gridcell-column-index="${pos.col + this.sheet.colOffset}"]`
      ) ?? null
    );
  }

  /** The data cell an event belongs to, or null (header, footer, control column, toolbar, editor). */
  dataCell(target: EventTarget | null): HTMLElement | null {
    if (!(target instanceof Element)) return null;
    const cell = target.closest<HTMLElement>(
      '[role=gridcell][data-gridcell-visible-row-index]'
    );
    if (!cell || !this.sheet.wrapper?.contains(cell)) return null;
    if (
      cell.classList.contains('euiDataGridFooterCell') ||
      cell.classList.contains('euiDataGridRowCell--controlColumn')
    ) {
      return null;
    }
    return cell;
  }

  /** The row-number cell an event belongs to, or null. */
  rowNumberCell(target: EventTarget | null): HTMLElement | null {
    if (!this.sheet.colOffset || !(target instanceof Element)) return null;
    const cell = target.closest<HTMLElement>(
      `[role=gridcell][data-gridcell-column-id="${ROW_COLUMN_ID}"]`
    );
    if (!cell || !this.sheet.wrapper?.contains(cell)) return null;
    if (cell.classList.contains('euiDataGridFooterCell')) return null;
    return cell;
  }

  /** The row-number column's header an event belongs to, or null. */
  rowNumberHeader(target: EventTarget | null): HTMLElement | null {
    if (!this.sheet.colOffset || !(target instanceof Element)) return null;
    const header = target.closest<HTMLElement>(
      `[role=columnheader][data-gridcell-column-id="${ROW_COLUMN_ID}"]`
    );
    if (!header || !this.sheet.wrapper?.contains(header)) return null;
    return header;
  }

  /** The data column header an event belongs to, or null (not a control column's). */
  headerCell(target: EventTarget | null): HTMLElement | null {
    if (!(target instanceof Element)) return null;
    const header = target.closest<HTMLElement>('[role=columnheader]');
    if (!header || !this.sheet.wrapper?.contains(header)) return null;
    const id = header.dataset['gridcellColumnId'];
    if (id === ROW_COLUMN_ID || id === ADD_FIELD_COLUMN_ID) return null;
    return header;
  }

  /** The "+" column's header an event belongs to, or null (V03 6.3). */
  addFieldHeader(target: EventTarget | null): HTMLElement | null {
    if (
      !this.sheet.gridColumns.hasAddFieldColumn ||
      !(target instanceof Element)
    )
      return null;
    const header = target.closest<HTMLElement>(
      `[role=columnheader][data-gridcell-column-id="${ADD_FIELD_COLUMN_ID}"]`
    );
    return header && this.sheet.wrapper?.contains(header) ? header : null;
  }

  /** A body (or footer) cell of the "+" column an event belongs to, or null. */
  addFieldCell(target: EventTarget | null): HTMLElement | null {
    if (
      !this.sheet.gridColumns.hasAddFieldColumn ||
      !(target instanceof Element)
    )
      return null;
    const cell = target.closest<HTMLElement>(
      `[role=gridcell][data-gridcell-column-id="${ADD_FIELD_COLUMN_ID}"]`
    );
    return cell && this.sheet.wrapper?.contains(cell) ? cell : null;
  }

  /** The rendered header cell of a column, by id. */
  headerElement(columnId: string): HTMLElement | null {
    return (
      this.sheet.wrapper?.querySelector<HTMLElement>(
        `[role=columnheader][data-gridcell-column-id="${CSS.escape(columnId)}"]`
      ) ?? null
    );
  }

  isInFieldEditor(target: EventTarget | null): boolean {
    return target instanceof Element && !!target.closest(FIELD_EDITOR_SELECTOR);
  }

  /** The row of a grid cell (data or control), read from its markup. */
  rowIndexOf(cell: HTMLElement): number {
    return Number(cell.dataset['gridcellVisibleRowIndex']);
  }

  /** The rendered row-number cell of a row. */
  rowNumberElement(row: number): HTMLElement | null {
    return (
      this.sheet.wrapper?.querySelector<HTMLElement>(
        `[role=gridcell][data-gridcell-visible-row-index="${row}"][data-gridcell-column-id="${ROW_COLUMN_ID}"]`
      ) ?? null
    );
  }

  /** Focuses a row's row-number cell. */
  focusRowNumberCell(row: number): void {
    if (!this.sheet.colOffset) return;
    this.sheet.frozen.noteScrollLeft();
    this.sheet.gridApi?.setFocusedCell({ rowIndex: row, colIndex: 0 });
  }

  isInMenu(target: EventTarget | null): boolean {
    return (
      target instanceof Element && !!target.closest('[data-eui-sheet-menu]')
    );
  }

  /** A viewport point in the wrapper's CSS px. */
  pointInWrapper(x: number, y: number): { top: number; left: number } {
    const wrapper = this.sheet.wrapper;
    if (!wrapper) return { top: 0, left: 0 };
    const origin = wrapper.getBoundingClientRect();
    const scale = wrapper.offsetWidth ? origin.width / wrapper.offsetWidth : 1;
    return { top: (y - origin.top) / scale, left: (x - origin.left) / scale };
  }

  /** A box relative to the wrapper, in the viewport now (it follows a page scroll). */
  toViewport(box: WrapperBox): LayerAnchor | null {
    const wrapper = this.sheet.wrapper;
    if (!wrapper) return null;
    const origin = wrapper.getBoundingClientRect();
    const scale = wrapper.offsetWidth ? origin.width / wrapper.offsetWidth : 1;
    const top = origin.top + box.top * scale;
    const left = origin.left + box.left * scale;
    return {
      top,
      left,
      bottom: top + box.height * scale,
      right: left + box.width * scale
    };
  }

  /** Whether `node` is in this sheet: its wrapper or one of its layers (portaled). */
  ownsNode(node: Node): boolean {
    if (this.sheet.wrapper?.contains(node)) return true;
    const element = node instanceof Element ? node : node.parentElement;
    const layer = element?.closest<HTMLElement>(LAYER_SELECTOR);
    return !!layer && layer.dataset['euiSheetLayer'] === this.sheet.sheetId;
  }

  /**
   * Whether a clipboard event on `target` belongs to the sheet. Real copy and
   * paste events are dispatched where the browser's selection is, which after
   * a click is the cell's content element, not the cell (RESULTS.md D22).
   * Interactive children of a cell keep their own clipboard behaviour.
   */
  isClipboardTarget(target: EventTarget | null, cell: HTMLElement): boolean {
    if (target === cell) return true;
    if (!(target instanceof Element) || !cell.contains(target)) return false;
    return !target.closest(
      'input, textarea, select, button, a[href], [contenteditable=""], [contenteditable=true]'
    );
  }

  isInEditor(target: EventTarget | null): boolean {
    return (
      target instanceof Element && !!target.closest(EDITOR_SURFACE_SELECTOR)
    );
  }

  /** The cell's position (data column), read from its markup. */
  cursor(cell: HTMLElement): Pos {
    const row = Number(cell.dataset['gridcellVisibleRowIndex']);
    const col =
      Number(cell.dataset['gridcellColumnIndex']) - this.sheet.colOffset;
    // the sheet passes no sorting/pagination/row tree
    assert(
      'EuiSheet: data and visible row indexes differ',
      cell.dataset['gridcellRowIndex'] ===
        cell.dataset['gridcellVisibleRowIndex']
    );
    return { row, col };
  }

  /* -------------------------------------------------------------------- */
  /* Edit lifecycle                                                        */
  /* -------------------------------------------------------------------- */

  /** A cell's box relative to the wrapper, in the wrapper's CSS px. */
  rectOf(cell: HTMLElement): SheetEditorRect | null {
    const wrapper = this.sheet.wrapper;
    if (!wrapper) return null;
    const box = cell.getBoundingClientRect();
    const origin = wrapper.getBoundingClientRect();
    // client rects are in screen px; an ancestor transform (the test
    // container is scaled to 50%) makes them differ from the CSS px the
    // editor is positioned in
    const scale = wrapper.offsetWidth ? origin.width / wrapper.offsetWidth : 1;
    return {
      top: (box.top - origin.top) / scale,
      left: (box.left - origin.left) / scale,
      width: box.width / scale,
      height: box.height / scale,
      wrapperHeight: wrapper.offsetHeight
    };
  }

  /** Focuses a header by column id, else the data header at that grid index (clamped). */
  focusHeader(at: { columnId: string; index: number }): void {
    let header = at.columnId ? this.headerElement(at.columnId) : null;
    if (!header && at.index >= 0) {
      const last =
        this.sheet.fields.visibleFields.length - 1 + this.sheet.colOffset;
      const index = Math.min(at.index, last);
      header =
        this.sheet.wrapper?.querySelector<HTMLElement>(
          `[role=columnheader][data-gridcell-column-index="${index}"]`
        ) ?? null;
    }
    header?.focus();
  }

  /** Whether `target` is in this sheet's grid (a cell, a row number, a header). */
  isInGrid(target: EventTarget | null): boolean {
    if (!(target instanceof Element)) return false;
    const grid = target.closest('[role=grid]');
    return !!grid && !!this.sheet.wrapper?.contains(grid);
  }
}
