/** Following `@records` and `@groups`: keeping the cursor, range and editor on their records (V03C-DESIGN.md 3.2). */
import { modifier } from 'ember-modifier';

import { afterRender, clamp, sameIds, sameLayout } from './util.ts';

import type EuiSheet from '../../components/eui-sheet.gts';
import type { RowModel, SheetGroup } from '../../core/index.ts';
import type { PendingOwn } from './types.ts';

/**
 * Whether `next` is `previous` with only what this sheet emitted applied:
 * the ids kept in the same order, the pending deletes gone, and no more
 * new ids than the pending inserts (an owner may give them other ids).
 */
function isOwnChange(
  previous: readonly string[],
  next: readonly string[],
  pending: PendingOwn
): boolean {
  if (!pending.inserts && !pending.deletes.size) return false;
  const before = new Set(previous);
  const kept = previous.filter((id) => !pending.deletes.has(id));
  let k = 0;
  let added = 0;
  for (const id of next) {
    if (!before.has(id)) {
      added++;
      continue;
    }
    if (kept[k] !== id) return false;
    k++;
  }
  return k === kept.length && added <= pending.inserts;
}

export default class SheetFollow<T extends object> {
  sheet: EuiSheet<T>;

  constructor(sheet: EuiSheet<T>) {
    this.sheet = sheet;
  }

  /** The `@records` of the last render, and their ids. */
  lastRecords: readonly T[] | null = null;
  lastIds: string[] = [];
  /** The row model of that render: the stored positions are its grid rows. */
  lastRowModel: RowModel | null = null;
  /** `@groups` of that render (V03 4.2): what a stored add row or header row belongs to. */
  lastGroups: readonly SheetGroup[] = [];
  lastGroupsArg: readonly SheetGroup[] | undefined = undefined;

  /**
   * Whenever `@records` is a new array: schedules a `@validate` run and,
   * after the render, follows the records (`recordsRendered`).
   */
  watchRecords = modifier(
    (_element: HTMLElement, [records, groups]: [unknown, unknown]) => {
      void groups;
      // V03 4.2: `@groups` can change while `@records` stays the same array
      if (records !== this.lastRecords) this.sheet.validate.scheduleValidate();
      afterRender(this.sheet, () => {
        this.recordsRendered();
        // a row drag's rows, at their new place (V03 10.1)
        this.sheet.rowDrag.applyPendingSelect();
      });
    }
  );

  /**
   * After a render with a new `@records` (V02-DESIGN.md 3.2, 3.3). A change
   * that is not the sheet's own (the owner re-sorted, re-queried, reloaded)
   * moves the selection, focus and an open editor to their record; then a
   * pending focus whose record is now rendered is applied.
   */
  recordsRendered(): void {
    const records = this.sheet.args.records;
    if (records === this.lastRecords) {
      if (this.sheet.args.groups !== this.lastGroupsArg) this.groupsRendered();
      return;
    }
    const previous = this.lastRecords;
    const previousIds = this.lastIds;
    const previousModel = this.lastRowModel;
    const previousGroups = this.lastGroups;
    const ids = records.map((record) =>
      String(this.sheet.args.getRecordId(record))
    );
    const pending = this.sheet.changes.pendingOwn;
    this.lastRecords = records;
    this.lastIds = ids;
    this.lastRowModel = this.sheet.rows.rowModel;
    this.lastGroups = this.sheet.rows.groups;
    this.lastGroupsArg = this.sheet.args.groups;
    this.sheet.changes.pendingOwn = { deletes: new Set(), inserts: 0 };
    // grouped, the rows moved: what holds grid rows across renders ends (V03 7.4)
    const regrouped =
      !!previousModel &&
      (previousGroups.length > 0 || this.sheet.rows.isGrouped) &&
      !sameLayout(
        previousModel,
        previousGroups,
        this.sheet.rows.rowModel,
        this.sheet.rows.groups
      );
    const imeFocus = regrouped && this.endTransients();
    // a pending cell whose record left `@records` (an owner's re-query) is
    // dropped; one on a row not inserted yet (an async owner) is kept
    if (previous && this.sheet.resolve.pendingCells.size) {
      const now = new Set(ids);
      const left = previousIds.filter((id) => !now.has(id));
      if (left.length) this.sheet.resolve.dropPending([], left);
    }
    if (
      previous &&
      !sameIds(previousIds, ids) &&
      !isOwnChange(previousIds, ids, pending)
    ) {
      this.followRecords(
        previousIds,
        ids,
        previousModel ?? this.sheet.rows.rowModel,
        previousGroups
      );
    } else if (regrouped && previousModel) {
      if (sameIds(previousIds, ids)) {
        // a new array of the same records under new groups (a re-query
        // with new headers): the stored positions follow, as on new @groups
        this.followRecords(previousIds, ids, previousModel, previousGroups);
      } else {
        // the sheet's own insert or delete in a group: the rows after it moved
        this.followRows(previousIds, ids, previousModel, previousGroups);
      }
    }
    if (imeFocus && this.sheet.selection.head)
      this.sheet.dom.focusGridCell(this.sheet.selection.head);
    // the expanded record left `@records` (deleted, or the owner re-queried)
    const expanded = this.sheet.expanded.expandedId;
    if (expanded !== null && !ids.includes(String(expanded))) {
      this.sheet.expanded.expandedFrom = null;
      this.sheet.expanded.setExpanded(null);
    }
    // a menu opened on rows that changed
    if (this.sheet.rowMenu.menu && previous && !sameIds(previousIds, ids)) {
      this.sheet.rowMenu.closeMenu(false);
    }
    this.sheet.records.applyPendingFocus();
    if (this.sheet.rows.isGrouped || previousGroups.length)
      this.sheet.groupHeaders.followGroupFocus();
  }

  /**
   * After a render with new `@groups` and the same `@records` (V03 4.2, 7.4
   * "Stored positions"): when the rows moved, the stored positions are
   * found again by record id or group key, and a drag, a fill, a
   * composition, a drop target and an open menu end; focus on a header
   * follows its key.
   */
  groupsRendered(): void {
    const previousModel = this.lastRowModel;
    const previousGroups = this.lastGroups;
    this.lastRowModel = this.sheet.rows.rowModel;
    this.lastGroups = this.sheet.rows.groups;
    this.lastGroupsArg = this.sheet.args.groups;
    if (
      !previousModel ||
      sameLayout(
        previousModel,
        previousGroups,
        this.sheet.rows.rowModel,
        this.sheet.rows.groups
      )
    ) {
      return;
    }
    const imeFocus = this.endTransients();
    this.followRecords(
      this.lastIds,
      this.lastIds,
      previousModel,
      previousGroups
    );
    if (imeFocus && this.sheet.selection.head && !this.sheet.edit.editing)
      this.sheet.dom.focusGridCell(this.sheet.selection.head);
    this.sheet.records.applyPendingFocus();
    this.sheet.groupHeaders.followGroupFocus();
  }

  /**
   * Ends what holds grid rows across renders when grouped rows move
   * (V03 7.4, GR23): a select drag, a fill drag, a composition, a file-drop
   * target and the row menu. True when focus was in what ended (the
   * composition catcher or the menu), so the caller focuses the active cell.
   */
  endTransients(): boolean {
    if (this.sheet.drag.dragging || this.sheet.drag.dragFrom)
      this.sheet.drag.endDrag();
    if (this.sheet.rowDrag.press) this.sheet.rowDrag.end();
    this.sheet.filling.stopFillDrag();
    const imeFocus =
      !!this.sheet.ime.imePos &&
      document.activeElement === this.sheet.ime.imeInput;
    if (this.sheet.ime.imePos || this.sheet.ime.imeActive)
      this.sheet.ime.endIme();
    if (this.sheet.uploads.dropPos) this.sheet.uploads.dropPos = null;
    // the menu's items can re-render first and drop the focused one: focus
    // then fell to the page
    const active = document.activeElement;
    const menuFocus =
      !!this.sheet.rowMenu.menu &&
      (this.sheet.dom.isInMenu(active) || !active || active === document.body);
    if (this.sheet.rowMenu.menu) this.sheet.rowMenu.closeMenu(false);
    return imeFocus || menuFocus;
  }

  /**
   * A grid row of the previous render in this one (V03 4.2): a record's
   * row by its id, an add row or a header by its group's key; -1 when it
   * is gone.
   */
  refindRow(
    row: number,
    previousIds: readonly string[],
    indexOf: ReadonlyMap<string, number>,
    previousModel: RowModel,
    previousGroups: readonly SheetGroup[]
  ): number {
    const at = previousModel.at(row);
    if (!at) return -1;
    if (at.kind === 'record') {
      const id = previousIds[at.record];
      const found = id === undefined ? undefined : indexOf.get(id);
      return found === undefined ? -1 : this.sheet.rows.gridRowOf(found);
    }
    if (at.group < 0) return this.sheet.rows.rowModel.addRowOf(-1);
    const key = previousGroups[at.group]?.key;
    const index = this.sheet.rows.groups.findIndex(
      (group) => group.key === key
    );
    if (index < 0) return -1;
    return at.kind === 'add'
      ? this.sheet.rows.rowModel.addRowOf(index)
      : this.sheet.rows.rowModel.headerRowOf(index);
  }

  /**
   * Grouped: the rows the checkbox Shift range and the row-number focus
   * remember (`lastToggledRow`, `rowCursor`) follow their record (V03 7.4).
   */
  followRows(
    previousIds: readonly string[],
    ids: readonly string[],
    previousModel: RowModel,
    previousGroups: readonly SheetGroup[]
  ): void {
    const indexOf = new Map(ids.map((id, i) => [id, i]));
    const refind = (row: number | null): number | null => {
      if (row === null) return null;
      const found = this.refindRow(
        row,
        previousIds,
        indexOf,
        previousModel,
        previousGroups
      );
      return found < 0 ? null : found;
    };
    this.sheet.checked.lastToggledRow = refind(
      this.sheet.checked.lastToggledRow
    );
    this.sheet.focus.rowCursor = refind(this.sheet.focus.rowCursor);
  }

  /**
   * The owner replaced `@records`: the selection collapses to the head's
   * cell, found again by record id (or the same row, clamped, when that
   * record is gone); an open editor stays on its record, or is cancelled
   * without a change set when the record is gone; a drag ends. A data cell
   * that had focus is focused again at the new position.
   */
  followRecords(
    previousIds: readonly string[],
    ids: readonly string[],
    previousModel: RowModel,
    previousGroups: readonly SheetGroup[] = []
  ): void {
    const indexOf = new Map(ids.map((id, i) => [id, i]));
    const grouped = previousGroups.length > 0 || this.sheet.rows.isGrouped;
    if (grouped)
      this.followRows(previousIds, ids, previousModel, previousGroups);
    const active = document.activeElement;
    // a data cell has focus, or had it until this render removed its row
    const hadCellFocus =
      !!this.sheet.dom.dataCell(active) ||
      (this.sheet.focus.focusDropped && (!active || active === document.body));
    let hadEditorFocus = false;
    if (this.sheet.drag.dragging || this.sheet.drag.dragFrom)
      this.sheet.drag.endDrag();

    const editing = this.sheet.edit.editing;
    if (editing) {
      const row = indexOf.get(String(editing.recordId));
      if (row === undefined) {
        hadEditorFocus = this.sheet.dom.isInEditor(active);
        this.sheet.edit.editing = null;
      } else {
        editing.pos = {
          row: this.sheet.rows.gridRowOf(row),
          col: editing.pos.col
        };
        const cell = this.sheet.dom.cellElement(editing.pos);
        const rect = cell && this.sheet.dom.rectOf(cell);
        if (rect) {
          editing.rect = rect;
        } else {
          // the row is not rendered: as on scroll
          this.sheet.edit.commit({ refocus: false });
        }
      }
    }

    // the active cell: the anchor of a cell range (V03 batch 1), else the head
    const head =
      this.sheet.selection.rangeKind === 'cells' && this.sheet.selection.anchor
        ? this.sheet.selection.anchor
        : this.sheet.selection.head;
    // the copy mark's cells are other records now
    if (this.sheet.outline.copied) this.sheet.outline.copied = null;
    if (head) {
      const id = previousIds[previousModel.recordRowAt(head.row)];
      let found = id === undefined ? undefined : indexOf.get(id);
      // grouped: an add row by its group's key (V03 4.2)
      let foundRow = -1;
      if (found === undefined && grouped) {
        foundRow = this.refindRow(
          head.row,
          previousIds,
          indexOf,
          previousModel,
          previousGroups
        );
        if (foundRow >= 0) found = this.sheet.rows.recordRowAt(foundRow);
      }
      // the last record, or the add row when there is none
      const model = this.sheet.rows.rowModel;
      const lastRow =
        model.lastRecordRow >= 0 ? model.lastRecordRow : model.length - 1;
      let row =
        foundRow >= 0
          ? foundRow
          : found === undefined
            ? clamp(head.row, 0, lastRow)
            : this.sheet.rows.gridRowOf(found);
      // grouped, the clamp of a lost head: a record (the nearest above
      // first), else an add row, never a header (V03 8.6)
      if (
        model.length &&
        this.sheet.rows.isGrouped &&
        found === undefined &&
        foundRow < 0
      ) {
        row = this.sheet.rows.clampToRecordRow(
          row,
          this.sheet.rows.landingRow(row, 1, false)
        );
      }
      if (model.length === 0 || row < 0) {
        this.sheet.selection.anchor = null;
        this.sheet.selection.head = null;
      } else {
        const pos = { row, col: head.col };
        this.sheet.selection.anchor = pos;
        this.sheet.selection.head = pos;
        this.sheet.selection.rangeKind = 'cells';
        if ((hadCellFocus || hadEditorFocus) && !this.sheet.edit.editing) {
          // onFocusIn sees the cell it already knows and keeps the range
          this.sheet.focus.domCursor = pos;
          this.sheet.dom.focusGridCell(pos);
        }
      }
    }
    // the error box is placed again when its cell gets focus
    if (!hadCellFocus) this.sheet.focus.focused = null;
  }
}
