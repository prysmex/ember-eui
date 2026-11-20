/** The grid's columns, widths, sort and control columns (V03C-DESIGN.md 3.2). */
import { cached, tracked } from '@glimmer/tracking';

import { headerDisplay } from './header-display.gts';
import { ADD_FIELD_COLUMN_ID, ADD_FIELD_WIDTH, ROW_COLUMN_ID } from './util.ts';

import type EuiSheet from '../../components/eui-sheet.gts';
import type { EuiSheetField } from '../../core/index.ts';
import type { SheetSort } from '../../types.ts';
import type {
  EuiDataGridColumn,
  EuiDataGridColumnActions,
  EuiDataGridControlColumn,
  EuiDataGridSorting,
  EuiDataGridSortingColumn
} from '@ember-eui/core/utils/data-grid/types';
import type { ComponentLike } from '@glint/template';

/** Its width without `@rowLabel`. */
const ROW_COLUMN_WIDTH = 64;
/** A frozen field's width without `@fieldWidths` or `field.width`. */
const FROZEN_DEFAULT_WIDTH = 200;

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
      this.givenWidth(field) ??
      this.keptWidth(field) ??
      FROZEN_DEFAULT_WIDTH
    );
  }

  /** A bare sheet's own width of a resized field (X6); none with `@onFieldWidthChange`. */
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
    this.sheet.layoutTick++;
    const handler = this.sheet.args.onFieldWidthChange;
    if (!handler) return;
    this.sheet.fields.expectUpdate('fieldWidths');
    handler(columnId, width);
  };

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
    // read: a bump gives the grid a new array (V03 5.3)
    void this.sheet.fields.orderEpoch;
    const frozen = this.sheet.frozen.frozenCount;
    const sortable = !!this.sheet.args.onSortChange;
    const filter = this.sheet.args.onFilterByField;
    const filterLabel = this.sheet.messages.filterByField();
    const fields = this.sheet.fields.visibleFields;
    return fields.map((field, index) => {
      const type = this.sheet.fields.typeOf(field);
      const canSort = sortable && field.sortable !== false;
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
      additional.push(
        ...this.sheet.headerMenu.fieldMenuItems(field, index, fields)
      );
      if (additional.length) actions.additional = additional;
      const given = this.givenWidth(field) ?? this.keptWidth(field);
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

  /** The row-number column: wider only for `@rowLabel` labels. */
  @cached
  get rowColumnWidth(): number {
    const label = this.sheet.args.rowLabel;
    if (!label) return ROW_COLUMN_WIDTH;
    let longest = 0;
    this.sheet.args.records.forEach((record, i) => {
      longest = Math.max(longest, label(record, this.sheet.numberOf(i)).length);
    });
    return Math.max(ROW_COLUMN_WIDTH, 24 + 8 * longest);
  }

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
    return [column];
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
