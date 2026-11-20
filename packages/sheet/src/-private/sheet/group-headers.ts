/** The group headers: their titles, cells, toggle and focus (V03C-DESIGN.md 3.2). */
import { isEmptyValue } from '../../core/index.ts';
import { stop } from './util.ts';

import type EuiSheet from '../../components/eui-sheet.gts';
import type {
  EuiSheetField,
  SheetGroup,
  SheetGroupBy
} from '../../core/index.ts';

export default class SheetGroupHeaders<T extends object> {
  sheet: EuiSheet<T>;

  constructor(sheet: EuiSheet<T>) {
    this.sheet = sheet;
  }

  /** The block's `setGroupBy`: calls `@onGroupByChange`; nothing without it (V03 4.5). */
  setGroupBy = (groupBy: SheetGroupBy[]): void => {
    this.sheet.args.onGroupByChange?.(groupBy);
  };

  /** The block's `toggleGroup(key)`: `@onGroupToggle(key, !collapsed)` for that group of `@groups`; nothing without the handler or the group. */
  toggleGroupByKey = (key: string): void => {
    const index = this.sheet.rows.groups.findIndex(
      (group) => group.key === key
    );
    if (index >= 0) this.toggleGroup(index);
  };

  /** The group a grid row is the header of; undefined for any other row. */
  groupHeaderAt(row: number): SheetGroup | undefined {
    if (!this.sheet.rows.isGrouped) return undefined;
    const at = this.sheet.rows.rowModel.at(row);
    return at?.kind === 'group' ? this.sheet.rows.groups[at.group] : undefined;
  }

  /* Group headers (V03 8.3, 8.4) */

  /** The headers have a toggle: only with `@onGroupToggle` (D2). */
  get canToggleGroups(): boolean {
    return !!this.sheet.args.onGroupToggle;
  }

  /** The field of a group's level, `@groupBy[depth].field`, among every field (a hidden one too). */
  groupFieldOf(group: SheetGroup): EuiSheetField<T> | undefined {
    const by = this.sheet.args.groupBy?.[group.depth];
    return by
      ? this.sheet.fields.allFields.find((field) => field.id === by.field)
      : undefined;
  }

  /** A header's text: its `label`, else the field type's `format(value)`, or "(Empty)". */
  groupTitleOf(group: SheetGroup): string {
    if (group.label !== undefined) return group.label;
    const value = group.value;
    const field = this.groupFieldOf(group);
    if (field) {
      const type = this.sheet.fields.typeOf(field);
      if (isEmptyValue(type, value)) return this.sheet.messages.groupEmpty();
      return String(
        type.format(value, field, {
          record: undefined,
          messages: this.sheet.messages
        })
      );
    }
    // no `@groupBy` for this level: the value as it is
    if (value === null || value === undefined || value === '') {
      return this.sheet.messages.groupEmpty();
    }
    return typeof value === 'string' ||
      typeof value === 'number' ||
      typeof value === 'boolean'
      ? String(value)
      : '';
  }

  /**
   * The props of every cell of a header row (V03 8.6): what a screen reader
   * announces on whichever cell has focus ("Status: Open, 3") and,
   * with a toggle, `aria-expanded`.
   */
  groupCellProps(group: SheetGroup): Record<string, unknown> {
    const messages = this.sheet.messages;
    const field = this.groupFieldOf(group);
    const title = this.groupTitleOf(group);
    const parts = [
      field ? messages.groupLabel(field.label ?? field.id, title) : title,
      messages.groupCount(group.count)
    ];
    if (group.continued) parts.push(messages.groupContinued());
    const props: Record<string, unknown> = { 'aria-label': parts.join(', ') };
    if (this.canToggleGroups) {
      props['aria-expanded'] = group.collapsed ? 'false' : 'true';
    }
    return props;
  }

  /** Asks the owner to collapse or expand a group (`@onGroupToggle(key, collapsed)`). */
  toggleGroup(index: number): void {
    const group = this.sheet.rows.groups[index];
    const handler = this.sheet.args.onGroupToggle;
    if (!group || !handler) return;
    handler(group.key, !group.collapsed);
  }

  /**
   * The header cell that had focus last, by group key and grid column: a
   * header has no `anchor` or `head`, so this is how focus stays on it when
   * the owner's new `@groups` move it (V03 8.3, 4.2).
   */
  focusedGroup: { key: string; colIndex: number } | null = null;

  /** A header cell lost focus to nowhere in this run loop (a render removed its row). */
  groupFocusDropped = false;

  /** Notes (or forgets) the header a focused cell belongs to. */
  noteGroupFocus(cell: HTMLElement | null): void {
    if (!this.sheet.rows.isGrouped || !cell) {
      this.focusedGroup = null;
      return;
    }
    const group = this.groupHeaderAt(this.sheet.dom.rowIndexOf(cell));
    this.focusedGroup = group
      ? {
          key: group.key,
          colIndex: Number(cell.dataset['gridcellColumnIndex'])
        }
      : null;
  }

  /** After a render with new `@groups` or `@records`: focus follows the header it was on. */
  followGroupFocus(): void {
    const focused = this.focusedGroup;
    if (!focused) return;
    const index = this.sheet.rows.groups.findIndex(
      (group) => group.key === focused.key
    );
    if (index < 0) {
      this.focusedGroup = null;
      return;
    }
    const row = this.sheet.rows.rowModel.headerRowOf(index);
    const active = document.activeElement;
    const cell =
      this.sheet.dom.rowNumberCell(active) ?? this.sheet.dom.dataCell(active);
    if (cell) {
      if (this.sheet.dom.rowIndexOf(cell) === row) return;
    } else if (
      !this.groupFocusDropped ||
      (active && active !== document.body)
    ) {
      // focus went elsewhere (a click on the page), not away with the row
      return;
    }
    this.sheet.frozen.noteScrollLeft();
    this.sheet.gridApi?.setFocusedCell({
      rowIndex: row,
      colIndex: focused.colIndex
    });
  }

  /** Enter or Space on a header cell: the toggle; nothing without `@onGroupToggle` (V03 8.6). */
  onGroupKeyDown(event: KeyboardEvent, target: EventTarget | null): boolean {
    const cell =
      this.sheet.dom.rowNumberCell(target) ?? this.sheet.dom.dataCell(target);
    if (!cell || target !== cell) return false;
    const at = this.sheet.rows.rowModel.at(this.sheet.dom.rowIndexOf(cell));
    if (at?.kind !== 'group') return false;
    const plain =
      !event.ctrlKey && !event.metaKey && !event.altKey && !event.shiftKey;
    if (!plain || (event.key !== 'Enter' && event.key !== ' ')) return false;
    stop(event);
    this.toggleGroup(at.group);
    return true;
  }

  /** A click on a header's chevron or title: the toggle; true when handled. */
  onGroupToggleClick(target: Element): boolean {
    const toggle = target.closest('[data-eui-sheet-group-toggle]');
    if (!toggle || !this.sheet.wrapper?.contains(toggle)) return false;
    const cell =
      this.sheet.dom.rowNumberCell(toggle) ?? this.sheet.dom.dataCell(toggle);
    const at = cell
      ? this.sheet.rows.rowModel.at(this.sheet.dom.rowIndexOf(cell))
      : undefined;
    if (at?.kind !== 'group') return false;
    this.toggleGroup(at.group);
    return true;
  }

  /**
   * The values a record inserted into a group gets (V03 8.4): for the group
   * and each ancestor, `{ [@groupBy[depth].field]: group.value }`.
   */
  groupValuesOf(index: number): Record<string, unknown> {
    const groups = this.sheet.rows.groups;
    const groupBy = this.sheet.args.groupBy ?? [];
    const values: Record<string, unknown> = {};
    let depth = Infinity;
    for (let i = index; i >= 0; i--) {
      const group = groups[i]!;
      if (group.depth >= depth) continue;
      depth = group.depth;
      const by = groupBy[group.depth];
      if (by && !(by.field in values)) values[by.field] = group.value;
      if (depth <= 0) break;
    }
    return values;
  }

  /**
   * The group a record inserted next to grid row `row` goes into (V03
   * 8.4): its values (`groupValuesOf`) and `groupKey`; undefined without
   * groups.
   */
  groupInsertOf(
    row: number
  ): { values: Record<string, unknown>; groupKey: string } | undefined {
    if (!this.sheet.rows.isGrouped) return undefined;
    const group = this.sheet.rows.rowModel.groupAt(row);
    const key = this.sheet.rows.groups[group]?.key;
    if (key === undefined) return undefined;
    return { values: this.groupValuesOf(group), groupKey: key };
  }

  /**
   * Whether a copy is of the checked records: some are checked and the
   * event is on a row number or on the header checkbox, where focus is
   * after a checkbox click. A copy on a data cell copies the range.
   */
  /**
   * Whether a clipboard event is on a group header's cell (V03 9.1): the
   * sheet takes it with nothing in it, as on the add row, so the grid's
   * own handler does not copy the header's text.
   */
  isGroupHeaderTarget(target: EventTarget | null): boolean {
    if (!this.sheet.rows.isGrouped) return false;
    const cell =
      this.sheet.dom.dataCell(target) ?? this.sheet.dom.rowNumberCell(target);
    return (
      !!cell &&
      this.sheet.dom.isClipboardTarget(target, cell) &&
      this.sheet.rows.rowKind(this.sheet.dom.rowIndexOf(cell)) === 'group'
    );
  }
}
