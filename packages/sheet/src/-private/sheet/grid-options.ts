/** The grid's row height, style, custom properties and virtualization (V03C-DESIGN.md 3.2). */
import { cached, tracked } from '@glimmer/tracking';
import { isDestroyed, isDestroying } from '@ember/destroyable';
import { htmlSafe } from '@ember/template';
import { modifier } from 'ember-modifier';

import { ADD_FIELD_WIDTH } from './util.ts';

import type EuiSheet from '../../components/eui-sheet.gts';
import type { SheetRowHeight } from '../../types.ts';
import type {
  EuiDataGridRowHeightsOptions,
  EuiDataGridStyle,
  EuiDataGridVirtualizationOptions
} from '@ember-eui/core/utils/data-grid/types';

/** The grid's width for a column without `initialWidth`, at least (`DEFAULT_COLUMN_WIDTH`, `body-base.ts`). */
const GRID_DEFAULT_COLUMN_WIDTH = 100;

/** `@rowHeight` as the grid's row heights (6.4). */
const ROW_HEIGHTS: Record<SheetRowHeight, EuiDataGridRowHeightsOptions> = {
  short: {},
  medium: { defaultHeight: { lineCount: 2 } },
  tall: { defaultHeight: { lineCount: 4 } },
  extraTall: { defaultHeight: { lineCount: 6 } }
};

export default class SheetGridOptions<T extends object> {
  sheet: EuiSheet<T>;

  constructor(sheet: EuiSheet<T>) {
    this.sheet = sheet;
  }

  /** The row height without `@onRowHeightChange`; null: `@rowHeight`. */
  @tracked localRowHeight: SheetRowHeight | null = null;

  /**
   * Scrolled sideways without frozen fields: the add rows' "+ Add record"
   * is pinned to the left edge (`AddPinned`), as a group header's label is.
   * With frozen fields the row numbers and the first field stay anyway.
   */
  get pinsAddRow(): boolean {
    return (
      this.sheet.scroll.scrolledX &&
      this.sheet.frozen.frozenCount === 0 &&
      this.sheet.rows.hasAddRow
    );
  }

  /* Row height (6.4) */

  get rowHeight(): SheetRowHeight {
    const given = this.sheet.args.rowHeight ?? 'short';
    if (this.sheet.args.onRowHeightChange) return given;
    return this.localRowHeight ?? given;
  }

  setRowHeight = (rowHeight: SheetRowHeight): void => {
    const handler = this.sheet.args.onRowHeightChange;
    if (handler) {
      if (rowHeight !== this.rowHeight)
        this.sheet.fields.expectUpdate('rowHeight');
      handler(rowHeight);
      return;
    }
    this.localRowHeight = rowHeight;
  };

  @cached
  get rowHeightsOptions(): EuiDataGridRowHeightsOptions | undefined {
    const options = ROW_HEIGHTS[this.rowHeight];
    return options.defaultHeight ? options : undefined;
  }

  /**
   * The custom properties on the grid's container: the frozen header
   * cells' `left`s and, while grouped, the header label's width bounds
   * (V03 9.1): at least the row numbers and the first field, at most the
   * grid's visible width once measured.
   */
  @cached
  get gridVars(): ReturnType<typeof htmlSafe> | undefined {
    const frozen = this.sheet.frozen.frozenStyle;
    if (!this.sheet.rows.isGrouped && !this.pinsAddRow) return frozen;
    const plus = this.sheet.colOffset
      ? this.sheet.gridColumns.rowColumnWidth
      : 0;
    const min = plus + this.firstColumnWidth;
    const max = this.groupMaxWidth;
    const vars = [
      `--euiSheetGroupMin:${min}px`,
      `--euiSheetGroupMax:${max ? `${max}px` : 'none'}`,
      `--euiSheetAddPlus:${plus}px`
    ].join(';');
    return htmlSafe(frozen ? `${String(frozen)};${vars}` : vars);
  }

  /**
   * The width the grid gives the first field's column: a resize, else its
   * `initialWidth`, else the grid's default for a column without one
   * (`defaultColumnWidth` in the grid's `body-base.ts`: the visible width
   * left by the sized columns, shared, at least 100).
   */
  get firstColumnWidth(): number {
    const field = this.sheet.fields.visibleFields[0];
    const column = this.sheet.gridColumns.columns[0];
    if (!field || !column) return 0;
    const resized = this.sheet.gridColumns.resizedWidths;
    const kept =
      resized && resized.columns === this.sheet.gridColumns.columns
        ? resized.widths[field.id]
        : undefined;
    if (kept !== undefined) return kept;
    if (column.initialWidth !== undefined) return column.initialWidth;
    const visible = this.groupMaxWidth;
    if (!visible) return GRID_DEFAULT_COLUMN_WIDTH;
    const controls =
      (this.sheet.colOffset ? this.sheet.gridColumns.rowColumnWidth : 0) +
      (this.sheet.gridColumns.hasAddFieldColumn ? ADD_FIELD_WIDTH : 0);
    let sized = 0;
    let unsized = 0;
    for (const each of this.sheet.gridColumns.columns) {
      if (each.initialWidth === undefined) unsized++;
      else sized += each.initialWidth;
    }
    return Math.max(
      (visible - controls - sized) / Math.max(unsized, 1),
      GRID_DEFAULT_COLUMN_WIDTH
    );
  }

  /** The grid's visible width while grouped (`measureGroupWidth`); 0 before it is measured. */
  @tracked groupMaxWidth = 0;

  /** While grouped: the scroll element's client width, for `--euiSheetGroupMax`. */
  measureGroupWidth = modifier((element: HTMLElement, [grouped]: [boolean]) => {
    if (!grouped || typeof ResizeObserver === 'undefined') return;
    const observer = new ResizeObserver(() => {
      if (isDestroying(this.sheet) || isDestroyed(this.sheet)) return;
      const width = this.sheet.scroll.scrollElement()?.clientWidth ?? 0;
      if (width && width !== this.groupMaxWidth) this.groupMaxWidth = width;
    });
    observer.observe(element);
    return () => observer.disconnect();
  });

  /** While a field is frozen every column of a rendered row is rendered (9.1): a frozen cell must not unmount. */
  @cached
  get virtualizationOptions(): EuiDataGridVirtualizationOptions | undefined {
    if (!this.sheet.frozen.frozenCount) return undefined;
    return {
      overscanColumnCount:
        this.sheet.fields.visibleFields.length +
        this.sheet.colOffset +
        (this.sheet.gridColumns.hasAddFieldColumn ? 1 : 0)
    };
  }

  /** The add row's class, and each group header row's (V03 9.1). */
  @cached
  get gridStyle(): EuiDataGridStyle | undefined {
    const model = this.sheet.rows.rowModel;
    const rowClasses: Record<number, string> = {};
    const addRow = model.addRowOf(-1);
    if (addRow >= 0) rowClasses[addRow] = 'euiSheet__addRow';
    this.sheet.rows.groups.forEach((group, i) => {
      // each expanded leaf's add row looks like the sheet's (V03 8.4)
      const add = model.addRowOf(i);
      if (add >= 0) rowClasses[add] = 'euiSheet__addRow';
      const row = model.headerRowOf(i);
      if (row < 0) return;
      const depth = Math.max(0, Math.floor(group.depth));
      rowClasses[row] = `euiSheet__groupRow euiSheet__groupRow--depth${depth}`;
    });
    if (!Object.keys(rowClasses).length) return undefined;
    return { rowClasses };
  }
}
