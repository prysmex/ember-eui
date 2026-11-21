/** The grid's columns, widths, sort and control columns (V03C-DESIGN.md 3.2). */
import { cached, tracked } from '@glimmer/tracking';

import { fieldWidth, resizerColumnId, textMeasure } from '../fit-width.ts';
import { headerDisplay } from './header-display.gts';
import { ADD_FIELD_COLUMN_ID, ADD_FIELD_WIDTH, ROW_COLUMN_ID } from './util.ts';

import type EuiSheet from '../../components/eui-sheet.gts';
import type { EuiSheetField } from '../../core/index.ts';
import type { EuiSheetFieldType, SheetSort } from '../../types.ts';
import type { FitChrome, Measure } from '../fit-width.ts';
import type {
  EuiDataGridColumn,
  EuiDataGridColumnActions,
  EuiDataGridControlColumn,
  EuiDataGridSorting,
  EuiDataGridSortingColumn
} from '@ember-eui/core/utils/data-grid/types';
import type { ComponentLike } from '@glint/template';

/** The row-number column's least width. */
const ROW_COLUMN_WIDTH = 64;
/**
 * The row-number cell's room around its label, in px: the cell's borders
 * (2) and padding (12), the checkbox (14) after a 4 px gap, the expand
 * icon (16) after the content's 4 px gap, and 2 to spare. On a touch
 * screen (`hover: none`) the label, the checkbox and the expand icon all
 * show; with a mouse the checkbox takes the label's place on hover, so
 * the room fits both.
 */
const ROW_CELL_ROOM = 54;
/**
 * A label character's width, in px: the grid's 14 px text, tabular digits
 * (Inter's are about 8.7 px, a fallback font's 9.1).
 */
const ROW_LABEL_CHAR_WIDTH = 9.5;
/** The row drag grip's room in the row-number column (V03 10.7): 12 px and a 4 px gap. */
const GRIP_WIDTH = 16;
/** A frozen field's width without `@fieldWidths` or `field.width`. */
const FROZEN_DEFAULT_WIDTH = 200;
/** The opener button's room at a cell's end: 20 px, 6 px from the edge, and a gap (v0.4 01). */
const OPENER_ROOM = 28;
/** A header's menu button (24 px) and drag icon (12 px), shown on hover or focus. */
const HEADER_BUTTON_ROOM = 24;
const DRAG_ICON_ROOM = 12;
/** The gap the header's row of parts gets when they show (Borealis size.xxs). */
const HEADER_PART_GAP = 2;

export default class SheetGridColumns<T extends object> {
  sheet: EuiSheet<T>;

  constructor(sheet: EuiSheet<T>) {
    this.sheet = sheet;
  }

  /**
   * The widths the grid keeps after a resize, until it gets new columns
   * (it drops them then, as this does): for the frozen offsets. Without
   * `@onFieldWidthChange` these are the only record of a resize (6.4:
   * "the grid keeps them").
   */
  @tracked resizedWidths: {
    columns: EuiDataGridColumn[];
    widths: Readonly<Record<string, number>>;
  } | null = null;
  /**
   * Every resize's width by field id, kept across new columns (V03 5.3,
   * X6): `columns` uses it when `@fieldWidths` and `field.width` give
   * none. Plain, so a resize does not rebuild the columns.
   */
  keptWidths = new Map<string, number>();
  /**
   * Bumped by a fit without `@onFieldWidthChange` (v0.4 01): `columns`
   * reads it, so the grid gets the fitted width as `initialWidth` (it has
   * no other way to take a width). Only a fit changes it.
   */
  @tracked fitEpoch = 0;

  /** `@headerLines` (V03 5.4): header labels wrap to 2 or 3 lines; the grid measures the taller header row. */
  get headerLinesClass(): string {
    const lines = this.sheet.args.headerLines ?? 1;
    return lines === 2 || lines === 3 ? `euiSheet--headerLines${lines}` : '';
  }

  /* Widths (6.4) */

  /** A field's width as given: `@fieldWidths`, else `field.width`. */
  givenWidth(field: EuiSheetField<T>): number | undefined {
    return this.sheet.args.fieldWidths?.[field.id] ?? field.width;
  }

  /** The width the grid shows a frozen field at (frozen fields always have one). */
  frozenWidth(field: EuiSheetField<T>): number {
    const resized = this.resizedWidths;
    const kept =
      resized && resized.columns === this.columns
        ? resized.widths[field.id]
        : undefined;
    return (
      kept ??
      this.keptWidth(field) ??
      this.givenWidth(field) ??
      FROZEN_DEFAULT_WIDTH
    );
  }

  /**
   * A bare sheet's own width of a resized or fitted field (X6, v0.4 01):
   * it wins over `@fieldWidths` and `field.width`, so a resize survives new
   * columns; none with `@onFieldWidthChange`.
   */
  keptWidth(field: EuiSheetField<T>): number | undefined {
    if (this.sheet.args.onFieldWidthChange) return undefined;
    return this.keptWidths.get(field.id);
  }

  onColumnResize = ({
    columnId,
    width
  }: {
    columnId: string;
    width: number;
  }): void => {
    // a press on the resize edge that moved nothing (each click of a
    // double-click, v0.4 01): no width changed
    if (this.isShownWidth(columnId, width)) return;
    const resized = this.resizedWidths;
    const widths =
      resized && resized.columns === this.columns ? resized.widths : {};
    this.resizedWidths = {
      columns: this.columns,
      widths: { ...widths, [columnId]: width }
    };
    // with the handler the sheet shows exactly `@fieldWidths` (V02 6.4)
    if (!this.sheet.args.onFieldWidthChange)
      this.keptWidths.set(columnId, width);
    // the fill handle measures again
    this.sheet.scroll.layoutTick++;
    const handler = this.sheet.args.onFieldWidthChange;
    if (!handler) return;
    this.sheet.fields.expectUpdate('fieldWidths');
    handler(columnId, width);
  };

  /** Whether the grid shows the column at this width now (its header's width, before the resize renders). */
  isShownWidth(columnId: string, width: number): boolean {
    const header = this.sheet.dom.headerElement(columnId);
    const shown = header ? parseFloat(header.style.width) : NaN;
    return Math.abs(shown - width) < 0.5;
  }

  /* Fit to content (v0.4 01) */

  /** Fits one visible field to its content; nothing for a field that is not shown. */
  fitField(fieldId: string): void {
    const field = this.sheet.fields.visibleFields.find((f) => f.id === fieldId);
    if (!field) return;
    this.applyWidths([[field.id, this.fitWidths([field])[0]!]]);
  }

  /** Fits every visible field. */
  fitFields(): void {
    const fields = this.sheet.fields.visibleFields;
    const widths = this.fitWidths(fields);
    this.applyWidths(fields.map((field, i) => [field.id, widths[i]!]));
  }

  /** A double-click on a column's resize edge fits that column. */
  onResizerDoubleClick = (event: MouseEvent): void => {
    const columnId = resizerColumnId(event.target);
    if (!columnId || !this.sheet.fields.visibleFieldIds.includes(columnId))
      return;
    event.preventDefault();
    event.stopPropagation();
    this.fitField(columnId);
  };

  /**
   * The fitted widths of `fields`, measured now (fonts that were still
   * loading at the first render are loaded by now): the cell font and
   * padding from a rendered cell, the header's from a rendered header.
   */
  fitWidths(fields: readonly EuiSheetField<T>[]): number[] {
    const ctx = this.sheet.context;
    const anyCell = this.sampleCell(null);
    const anyHeader = this.sampleHeader(null);
    return fields.map((field) => {
      const cell = this.sampleCell(field.id) ?? anyCell;
      const header = this.sampleHeader(field.id) ?? anyHeader;
      const cellParts = partsOf(cell, '[data-datagrid-cellcontent]');
      const headerParts = partsOf(header, '.euiDataGridHeaderCell__content');
      const type = this.sheet.fields.typeOf(field);
      const chrome: FitChrome = {
        header: headerParts.chrome,
        cell: cellParts.chrome,
        opener: this.hasOpener(field, type) ? OPENER_ROOM : 0
      };
      return fieldWidth(
        ctx,
        field,
        { cell: cellParts.measure, header: headerParts.measure },
        chrome
      );
    });
  }

  /** A rendered data cell of a field (not a control column), for its font and padding. */
  sampleCell(fieldId: string | null): HTMLElement | null {
    const ids = fieldId ? [fieldId] : this.sheet.fields.visibleFieldIds;
    for (const id of ids) {
      const cell = this.sheet.wrapper?.querySelector<HTMLElement>(
        `[role=gridcell][data-gridcell-column-id="${CSS.escape(id)}"]`
      );
      if (cell) return cell;
    }
    return null;
  }

  /** A rendered header of a field. */
  sampleHeader(fieldId: string | null): HTMLElement | null {
    const ids = fieldId ? [fieldId] : this.sheet.fields.visibleFieldIds;
    for (const id of ids) {
      const header = this.sheet.dom.headerElement(id);
      if (header) return header;
    }
    return null;
  }

  /** Whether the field's cells show the type's opener button (select, date). */
  hasOpener(field: EuiSheetField<T>, type: EuiSheetFieldType): boolean {
    if (!type.editor || this.sheet.args.readOnly || field.readOnly === true)
      return false;
    const opener = type.opener;
    return !!(typeof opener === 'function' ? opener(field) : opener);
  }

  /**
   * Gives the grid fitted widths, as a resize would: `@onFieldWidthChange`
   * once per field, or the sheet's own kept widths and new columns.
   */
  applyWidths(widths: ReadonlyArray<readonly [string, number]>): void {
    const handler = this.sheet.args.onFieldWidthChange;
    if (handler) {
      this.sheet.fields.expectUpdate('fieldWidths');
      for (const [fieldId, width] of widths) handler(fieldId, width);
    } else {
      for (const [fieldId, width] of widths)
        this.keptWidths.set(fieldId, width);
      this.fitEpoch++;
    }
    // the fill handle measures again
    this.sheet.scroll.layoutTick++;
  }

  /* Sort (6.3): drawn and emitted, never applied */

  @cached
  get sorting(): EuiDataGridSorting | undefined {
    if (!this.sheet.args.onSortChange) return undefined;
    return {
      columns: (this.sheet.args.sort ?? []).map(({ field, direction }) => ({
        id: field,
        direction
      })),
      onSort: this.onGridSort
    };
  }

  onGridSort = (columns: EuiDataGridSortingColumn[]): void => {
    this.setSort(
      columns.map(({ id, direction }) => ({ field: id, direction }))
    );
  };

  setSort = (sort: SheetSort[]): void => {
    this.sheet.args.onSortChange?.(sort);
  };

  /* Columns */

  /** Header components of fields with a description, by field id. */
  headerDisplays = new Map<
    string,
    { label: string; description: string; component: ComponentLike }
  >();

  displayFor(field: EuiSheetField<T>): ComponentLike | undefined {
    const description = field.description;
    if (!description) return undefined;
    const label = field.label ?? field.id;
    const cached = this.headerDisplays.get(field.id);
    if (cached && cached.label === label && cached.description === description)
      return cached.component;
    const component = headerDisplay(label, description);
    this.headerDisplays.set(field.id, { label, description, component });
    return component;
  }

  /**
   * The grid's columns. A new array makes the grid drop the widths it kept
   * from resizes (`body-base.ts`), so this depends only on the fields,
   * widths, the frozen count, which handlers exist and `orderEpoch`: not
   * on `@sort` or `@highlight`. The widths it dropped come back from
   * `keptWidths` (X6).
   */
  @cached
  get columns(): EuiDataGridColumn[] {
    // read: a bump gives the grid a new array (V03 5.3); a fit too (v0.4 01)
    void this.sheet.fields.orderEpoch;
    void this.fitEpoch;
    const frozen = this.sheet.frozen.frozenCount;
    const sortable = !!this.sheet.args.onSortChange;
    const filter = this.sheet.args.onFilterByField;
    const filterLabel = this.sheet.messages.filterByField();
    const fields = this.sheet.fields.visibleFields;
    return fields.map((field, index) => {
      const type = this.sheet.fields.typeOf(field);
      // a type without values (a button) has no sort (V03 10.3.1)
      const canSort = sortable && field.sortable !== false && !type.readOnly;
      const actions: EuiDataGridColumnActions = {
        showHide: index > 0 && field.hideable !== false,
        // the first field stays first (6.3)
        showMoveLeft: index > 1,
        showMoveRight: index > 0,
        showSortAsc: canSort,
        showSortDesc: canSort
      };
      const additional: NonNullable<EuiDataGridColumnActions['additional']> =
        [];
      if (filter) {
        additional.push({
          label: filterLabel,
          iconType: 'filter',
          color: 'text',
          onClick: () => this.sheet.args.onFilterByField?.(field.id),
          'data-test-subj': `euiSheetFilterByField-${field.id}`
        });
      }
      additional.push(...this.sheet.headerMenu.groupMenuItems(field));
      const fieldItems = this.sheet.headerMenu.fieldMenuItems(
        field,
        index,
        fields
      );
      // "Fit to content" joins a menu that is there anyway (v0.4 01): a
      // field with no other item keeps having no menu
      if (
        additional.length ||
        fieldItems.length ||
        Object.values(actions).some((shown) => shown === true)
      ) {
        additional.push(this.sheet.headerMenu.fitMenuItem(field));
      }
      additional.push(...fieldItems);
      if (additional.length) actions.additional = additional;
      const given = this.keptWidth(field) ?? this.givenWidth(field);
      const width = index < frozen ? (given ?? FROZEN_DEFAULT_WIDTH) : given;
      const column: EuiDataGridColumn = {
        id: field.id,
        displayAsText: field.label ?? field.id,
        isExpandable: false,
        isSortable: field.sortable !== false,
        actions
      };
      if (width !== undefined) column.initialWidth = width;
      if (type.schema) column.schema = type.schema;
      const display = this.displayFor(field);
      if (display) column.display = display;
      if (index < frozen) {
        column.displayHeaderCellProps = {
          className: this.sheet.frozen.frozenHeaderClass(
            index + this.sheet.colOffset
          )
        };
      }
      return column;
    });
  }

  /**
   * The row-number column: room for the longest label (the last record's
   * number, or `@rowLabel`'s longest) beside the checkbox and the expand
   * icon, at least `ROW_COLUMN_WIDTH`.
   */
  @cached
  get rowColumnWidth(): number {
    // the row drag's grip (V03 10.7)
    const grip = this.sheet.rowDrag.showsGrip ? GRIP_WIDTH : 0;
    const longest = this.longestRowLabel;
    const fit = Math.ceil(ROW_CELL_ROOM + ROW_LABEL_CHAR_WIDTH * longest);
    return Math.max(ROW_COLUMN_WIDTH, fit) + grip;
  }

  /** The longest row-number label's length in characters. */
  get longestRowLabel(): number {
    const records = this.sheet.args.records;
    const label = this.sheet.args.rowLabel;
    const rows = this.sheet.rows;
    if (label) {
      let longest = 0;
      records.forEach((record, i) => {
        longest = Math.max(longest, label(record, rows.numberOf(i)).length);
      });
      return longest;
    }
    if (!records.length) return 0;
    const numbers = rows.rowNumbers;
    if (!numbers) return String(rows.numberOf(records.length - 1)).length;
    // group starts (V03 8.4) may number a later record lower
    let max = numbers[0]!;
    let min = max;
    for (const number of numbers) {
      if (number > max) max = number;
      else if (number < min) min = number;
    }
    return Math.max(String(max).length, String(min).length);
  }

  /** The control columns last given to the grid, kept while they are the same. */
  #rowColumns: EuiDataGridControlColumn[] | undefined;

  @cached
  get leadingControlColumns(): EuiDataGridControlColumn[] | undefined {
    if (!this.sheet.showRowNumbers) return undefined;
    const column: EuiDataGridControlColumn = {
      id: ROW_COLUMN_ID,
      width: this.rowColumnWidth
    };
    if (this.sheet.frozen.frozenCount) {
      column.headerCellProps = {
        className: this.sheet.frozen.frozenHeaderClass(0)
      };
    }
    // the width follows the records: the same array for an edit that
    // keeps it, so the grid gets no new control columns
    const previous = this.#rowColumns?.[0];
    if (
      previous &&
      previous.width === column.width &&
      previous.headerCellProps?.className === column.headerCellProps?.className
    ) {
      return this.#rowColumns;
    }
    this.#rowColumns = [column];
    return this.#rowColumns;
  }

  /** The "+" add-field column (V03 6.3, W8): only with `@onFieldCreate`. */
  get hasAddFieldColumn(): boolean {
    return !!this.sheet.args.onFieldCreate;
  }

  @cached
  get trailingControlColumns(): EuiDataGridControlColumn[] | undefined {
    if (!this.hasAddFieldColumn) return undefined;
    return [
      {
        id: ADD_FIELD_COLUMN_ID,
        width: ADD_FIELD_WIDTH,
        headerCellProps: { className: 'euiSheet__addFieldHeader' }
      }
    ];
  }

  /** For the control blocks: whether a control cell is the "+" column's. */
  isAddFieldColumn = (columnId: string | undefined): boolean =>
    columnId === ADD_FIELD_COLUMN_ID;

  /** The grid column index of a column id (the "+" column after the fields). */
  gridIndexOf(columnId: string): number {
    if (columnId === ADD_FIELD_COLUMN_ID) {
      return this.sheet.fields.visibleFields.length + this.sheet.colOffset;
    }
    const index = this.sheet.fields.visibleFieldIds.indexOf(columnId);
    return index < 0 ? -1 : index + this.sheet.colOffset;
  }
}

/**
 * A rendered cell's or header's font (as a measure) and the room around
 * its content element's text (`chrome`): the element's own padding and
 * border, the content's padding, and 1 px for sub-pixel text. In layout
 * px (the test container and zoomed pages scale rects, not offsets).
 */
function partsOf(
  element: HTMLElement | null,
  contentSelector: string
): { measure: Measure; chrome: number } {
  const content = element?.querySelector<HTMLElement>(contentSelector) ?? null;
  const style = getComputedStyle(content ?? element ?? document.body);
  const font = `${style.fontStyle} ${style.fontWeight} ${style.fontSize} ${style.fontFamily}`;
  if (!element || !content) return { measure: textMeasure(font), chrome: 16 };
  const px = (value: string) => parseFloat(value) || 0;
  const inner =
    px(style.paddingLeft) +
    px(style.paddingRight) +
    px(style.borderLeftWidth) +
    px(style.borderRightWidth);
  let chrome = element.offsetWidth - content.offsetWidth + inner + 1;
  // a header's drag icon and menu button collapse until it is hovered or
  // focused (their negative margins): their room, and the gap before
  // each, when they show; measured as they are when they already show
  const collapsed = (selector: string, room: number) => {
    const part = element.querySelector<HTMLElement>(selector);
    if (!part || part.offsetWidth >= room) return 0;
    return room - part.offsetWidth + HEADER_PART_GAP;
  };
  chrome += collapsed('.euiDataGridHeaderCell__draggableIcon', DRAG_ICON_ROOM);
  chrome += collapsed(
    '[class*=euiDataGridHeaderCell__popover]',
    HEADER_BUTTON_ROOM
  );
  return { measure: textMeasure(font), chrome: Math.max(0, chrome) };
}
