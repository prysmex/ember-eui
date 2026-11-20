/** Keys: the sheet's key handling and the shortcut list (V03C-DESIGN.md 3.2). */
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

import {
  commitValue,
  edgeTarget,
  isReadOnly,
  valueOf
} from '../../core/index.ts';
import { clamp, samePos, stop } from './util.ts';

import type EuiSheet from '../../components/eui-sheet.gts';
import type { Pos } from '../../core/index.ts';
import type { ShortcutContext } from '../shortcuts.ts';

const ARROWS = new Set(['ArrowUp', 'ArrowDown', 'ArrowLeft', 'ArrowRight']);

/** Keys that extend the range with Shift (V02-DESIGN.md 8.4). */
const RANGE_KEYS = new Set([...ARROWS, 'Home', 'End', 'PageUp', 'PageDown']);

const ARROW_DIRECTIONS = {
  ArrowUp: 'up',
  ArrowDown: 'down',
  ArrowLeft: 'left',
  ArrowRight: 'right'
} as const;

/** Row and column steps of the arrows (Shift+arrows move the range's head). */
const ARROW_STEPS = {
  ArrowUp: [-1, 0],
  ArrowDown: [1, 0],
  ArrowLeft: [0, -1],
  ArrowRight: [0, 1]
} as const;

/** A key that starts a composition: a dead key or an IME (8.6). */
function startsComposition(event: KeyboardEvent): boolean {
  return (
    event.key === 'Dead' ||
    event.key === 'Process' ||
    event.keyCode === 229 ||
    event.isComposing
  );
}

/** Ctrl/Cmd+/ (V03 5.5; D11: not `?`). Shift allowed: `/` is Shift+7 on Spanish layouts. */
function isShortcutListKey(event: KeyboardEvent): boolean {
  return (event.ctrlKey || event.metaKey) && !event.altKey && event.key === '/';
}

function isMenuKey(event: KeyboardEvent): boolean {
  return (
    event.key === 'ContextMenu' ||
    (event.key === 'F10' &&
      event.shiftKey &&
      !event.ctrlKey &&
      !event.metaKey &&
      !event.altKey)
  );
}

export default class SheetKeys<T extends object> {
  sheet: EuiSheet<T>;

  constructor(sheet: EuiSheet<T>) {
    this.sheet = sheet;
  }

  /** The shortcut list is open (V03 5.5). */
  @tracked shortcutsOpen = false;

  /* -------------------------------------------------------------------- */
  /* Keys and clipboard                                                    */
  /* -------------------------------------------------------------------- */

  @action
  onKeyDown(event: KeyboardEvent): void {
    this.sheet.focus.extending = event.shiftKey && RANGE_KEYS.has(event.key);
    this.sheet.frozen.pressing = false;
    this.sheet.frozen.noteScrollLeft();
    this.sheet.focus.keepRangeOnFocus = false;
    const target = event.target;
    // a composition in an editor or in the catcher is the IME's: Enter
    // confirms it there, it does not save
    if (
      (event.isComposing || event.keyCode === 229) &&
      this.sheet.dom.isInEditor(target)
    ) {
      return;
    }
    if (this.sheet.edit.editing && this.sheet.dom.isInEditor(target)) {
      this.onEditKeyDown(event);
      return;
    }
    // the field editor's keys are its own (its focus trap has Escape)
    if (this.sheet.dom.isInFieldEditor(target)) return;
    if (this.sheet.rowMenu.menu && this.sheet.dom.isInMenu(target)) {
      // the panel has ArrowUp/Down and Enter; Escape is the sheet's
      if (event.key === 'Escape' || event.key === 'Tab') {
        stop(event);
        this.sheet.rowMenu.closeMenu(true);
      }
      return;
    }
    if (this.sheet.focus.isParked(target)) {
      if (isShortcutListKey(event)) {
        stop(event);
        this.showShortcuts();
        return;
      }
      this.onParkedKeyDown(event);
      return;
    }
    // Ctrl/Cmd+/ on a cell, a row number or a header (V03 5.5, X5)
    if (
      isShortcutListKey(event) &&
      !this.sheet.edit.editing &&
      this.sheet.dom.isInGrid(target)
    ) {
      stop(event);
      this.showShortcuts();
      return;
    }
    // Enter or Space on a group header's cell, row number or data (V03 8.6)
    if (
      this.sheet.rows.isGrouped &&
      this.sheet.groupHeaders.onGroupKeyDown(event, target)
    )
      return;
    const rowCell = this.sheet.dom.rowNumberCell(target);
    if (rowCell && target === rowCell) {
      this.onRowNumberKeyDown(event, this.sheet.dom.rowIndexOf(rowCell));
      return;
    }
    // the "+" header (V03 6.3): Enter or Space opens the field editor
    const addHeader = this.sheet.dom.addFieldHeader(target);
    if (addHeader && target === addHeader) {
      const plain = !event.ctrlKey && !event.metaKey && !event.altKey;
      if (plain && (event.key === 'Enter' || event.key === ' ')) {
        stop(event);
        this.sheet.fieldEditor.addField();
      }
      return;
    }
    const header = this.sheet.dom.headerCell(target);
    if (header && target === header) {
      // a selected column: Delete clears it (other keys are the header's)
      if (
        this.sheet.selection.rangeKind === 'columns' &&
        this.sheet.selection.range &&
        (event.key === 'Delete' || event.key === 'Backspace')
      ) {
        stop(event);
        this.sheet.selection.clearSelection();
      }
      return;
    }
    const cell = this.sheet.dom.dataCell(target);
    if (!cell || target !== cell) return;
    const pos = this.sheet.dom.cursor(cell);
    if (this.handleCommandKey(event)) return;
    if (this.handleNavKey(event, pos)) return;
    if (this.handleHomeKey(event, pos.row)) return;
    if (this.handleLastFieldKey(event, pos.row, pos.col)) return;
    if (this.handleGroupedEndKey(event)) return;
    // Escape ends the copy mark first (V03 batch 1)
    if (event.key === 'Escape' && this.sheet.outline.copied) {
      stop(event);
      this.sheet.outline.copied = null;
      return;
    }
    // Escape collapses a range to the active cell (V03 batch 1)
    if (
      event.key === 'Escape' &&
      !event.shiftKey &&
      this.sheet.selection.anchor &&
      this.sheet.selection.head &&
      !samePos(this.sheet.selection.anchor, this.sheet.selection.head)
    ) {
      stop(event);
      this.sheet.selection.anchor = pos;
      this.sheet.selection.head = pos;
      this.sheet.selection.rangeKind = 'cells';
      return;
    }
    if (this.sheet.rows.isAddRow(pos.row)) {
      this.onAddRowKeyDown(event, pos.row);
      return;
    }
    const record = this.sheet.rows.recordAt(pos.row);
    const field = this.sheet.fields.visibleFields[pos.col];
    if (record === undefined || !field) return;
    const ctx = this.sheet.context;
    const type = this.sheet.fields.typeOf(field);
    const readOnly = isReadOnly(ctx, field, record);
    const { key } = event;
    const plain = !event.ctrlKey && !event.metaKey && !event.altKey;

    if (isMenuKey(event)) {
      stop(event);
      this.sheet.rowMenu.openMenuAt(pos.row, pos.col, cell);
      return;
    }
    // a dead key or an IME: not prevented, the composition goes to the
    // catcher, focused now (8.6)
    if (startsComposition(event)) {
      if (type.editor && !readOnly) this.sheet.ime.startIme(pos, cell);
      return;
    }
    // navKey first: a checkbox's Space (PACKAGE-DESIGN.md 7.4)
    if (plain && !readOnly && type.navKey) {
      const result = type.navKey(key, valueOf(record, field.id), field);
      if (result) {
        stop(event);
        this.sheet.changes.emit(
          commitValue(ctx, this.sheet.rows.recordPos(pos), result.value),
          this.sheet.selection.touchedAt(pos)
        );
        return;
      }
    }
    if (key === ' ' && plain) {
      // C9: Space expands the record (also keeps the page from scrolling)
      stop(event);
      const recordId = this.sheet.args.getRecordId(record);
      this.sheet.expanded.expandRecord(recordId, {
        recordId,
        fieldId: field.id
      });
      return;
    }
    if (key === 'Enter' && event.shiftKey && plain && this.sheet.canInsert) {
      // C10: Shift+Enter inserts a record below
      stop(event);
      this.sheet.records.insertNear(pos.row, 'after', field.id);
      return;
    }
    if (key === 'Enter' || key === 'F2') {
      // read-only: the cue, and the key goes on as before (not taken)
      if (readOnly) {
        this.sheet.focus.readOnlyCue = pos;
        return;
      }
      if (!type.editor) return;
      stop(event);
      if (!this.sheet.edit.editInRecord(pos))
        this.sheet.edit.startEdit(pos, cell, null);
      return;
    }
    if (key.length === 1 && plain && !event.isComposing) {
      if (readOnly) {
        // not a silent no-op (V03 batch 2); the key is not taken
        this.sheet.focus.readOnlyCue = pos;
        return;
      }
      if (!type.editor) return;
      if (!(type.opensOnKey?.(key) ?? true)) return;
      // preventDefault keeps the character from being typed twice
      stop(event);
      this.sheet.edit.startEdit(pos, cell, key);
      return;
    }
    if (key === 'Delete' || key === 'Backspace') {
      if (!this.sheet.selection.range) return;
      stop(event);
      const range = this.sheet.selection.range;
      if (
        readOnly &&
        range.top === range.bottom &&
        range.left === range.right
      ) {
        this.sheet.focus.readOnlyCue = pos;
        return;
      }
      this.sheet.selection.clearSelection();
    }
    // arrows, End, PageUp/Down (with or without Shift), Tab, Escape,
    // Ctrl/Meta combos: the grid's own handling
  }

  /** Ctrl/Cmd+Z, Ctrl/Cmd+Shift+Z, Ctrl+Y, Ctrl/Cmd+D, Ctrl/Cmd+A on a cell or row number; true when handled. */
  handleCommandKey(event: KeyboardEvent): boolean {
    if (!(event.ctrlKey || event.metaKey) || event.altKey) return false;
    // with Shift, `key` is upper case
    const letter = event.key.toLowerCase();
    if (letter === 'z') {
      stop(event);
      if (event.shiftKey) this.sheet.history.redo();
      else this.sheet.history.undo();
      return true;
    }
    if (letter === 'y' && event.ctrlKey && !event.shiftKey) {
      stop(event);
      this.sheet.history.redo();
      return true;
    }
    if (letter === 'd' && !event.shiftKey) {
      // also keeps the browser from bookmarking the page
      stop(event);
      this.sheet.filling.fill();
      return true;
    }
    if (letter === 'r' && !event.shiftKey) {
      // C11: also keeps the browser from reloading the page
      stop(event);
      this.sheet.filling.fillRightSelection();
      return true;
    }
    if (letter === 'a' && !event.shiftKey) {
      // every cell; focus stays where it is
      stop(event);
      const model = this.sheet.rows.rowModel;
      // grouped: all the records (V03 8.5); with none, nothing to select
      if (this.sheet.rows.isGrouped && model.firstRecordRow < 0) return true;
      this.sheet.selection.anchor = {
        row: Math.max(model.firstRecordRow, 0),
        col: 0
      };
      this.sheet.selection.head = {
        row: model.lastRecordRow,
        col: this.sheet.fields.visibleFields.length - 1
      };
      this.sheet.selection.rangeKind = 'cells';
      return true;
    }
    return false;
  }

  /**
   * Keys the sheet moves focus for itself (V02-DESIGN.md 8.4): Ctrl/Cmd+
   * arrow jumps to the edge of the data (`edgeTarget`), Shift+Home/End and
   * Ctrl/Cmd+Shift+Home/End extend to the row's or the records' first or
   * last cell (the grid would go to the row-number column or the add row),
   * PageUp/PageDown move by the rows in view. With Shift each extends the
   * range. True when handled.
   */
  handleNavKey(event: KeyboardEvent, pos: Pos): boolean {
    if (event.altKey) return false;
    const { key } = event;
    const command = event.ctrlKey || event.metaKey;
    const records = this.sheet.args.records.length;
    const lastCol = this.sheet.fields.visibleFields.length - 1;
    // with Shift the range's head moves and focus stays on the active cell
    // (V03 batch 1): every target is computed from the head
    const extend = event.shiftKey && this.sheet.rows.isRecordRow(pos.row);
    const from =
      extend &&
      this.sheet.selection.head &&
      this.sheet.selection.anchor &&
      this.sheet.selection.rangeKind === 'cells'
        ? this.sheet.selection.head
        : pos;
    const model = this.sheet.rows.rowModel;
    let target: Pos;
    if (command && key in ARROW_DIRECTIONS) {
      const direction = ARROW_DIRECTIONS[key as keyof typeof ARROW_DIRECTIONS];
      if (this.sheet.rows.isGrouped && !this.sheet.rows.isRecordRow(from.row)) {
        // a header or a group's add row: an empty cell between two records
        target = this.sheet.rows.edgeFromGap(from, direction);
      } else {
        // in record rows; the add row is the row after the records above it
        const core = {
          row: this.sheet.rows.coreRowOf(from.row),
          col: from.col
        };
        const edge = edgeTarget(this.sheet.context, core, direction);
        target =
          edge.row === core.row
            ? { row: from.row, col: edge.col }
            : this.sheet.rows.gridPos(edge);
      }
    } else if (extend && key in ARROW_DIRECTIONS) {
      const [dRow, dCol] = ARROW_STEPS[key as keyof typeof ARROW_STEPS];
      const row = clamp(
        from.row + dRow,
        model.firstRecordRow,
        model.lastRecordRow
      );
      target = {
        // a header or an add row in the way is stepped over (3b)
        row: this.sheet.rows.isRecordRow(row)
          ? row
          : model.nearestRecordRow(row, dRow < 0 ? -1 : 1),
        col: clamp(from.col + dCol, 0, lastCol)
      };
    } else if (event.shiftKey && (key === 'Home' || key === 'End')) {
      target =
        key === 'Home'
          ? { row: command ? model.firstRecordRow : from.row, col: 0 }
          : { row: command ? model.lastRecordRow : from.row, col: lastCol };
    } else if ((key === 'PageDown' || key === 'PageUp') && !command) {
      const page = this.sheet.scroll.pageRows();
      const last = event.shiftKey ? model.lastRecordRow : model.length - 1;
      let row = clamp(from.row + (key === 'PageDown' ? page : -page), 0, last);
      // grouped: never on a header; with Shift on a record (V03 8.6)
      if (this.sheet.rows.isGrouped) {
        row = this.sheet.rows.landingRow(
          row,
          key === 'PageDown' ? 1 : -1,
          event.shiftKey
        );
      }
      target = { row, col: from.col };
    } else {
      return false;
    }
    stop(event);
    if (!records || target.row < 0) return true;
    if (extend) this.sheet.selection.extendHead(target);
    else this.sheet.selection.moveFocus(target, false);
    return true;
  }

  /** Keys while focus is parked: extend and clear the range; anything else brings the active cell back first. */
  onParkedKeyDown(event: KeyboardEvent): void {
    const anchor = this.sheet.selection.anchor;
    if (!anchor) return;
    if (this.handleCommandKey(event)) return;
    if (this.handleNavKey(event, anchor)) return;
    if (event.key === 'Delete' || event.key === 'Backspace') {
      stop(event);
      this.sheet.selection.clearSelection();
      return;
    }
    if (
      event.key === 'Shift' ||
      event.key === 'Control' ||
      event.key === 'Meta' ||
      event.key === 'Alt'
    )
      return;
    stop(event);
    if (event.key === 'Escape') this.sheet.selection.head = anchor;
    this.sheet.focus.domCursor = anchor;
    this.sheet.dom.focusGridCell(anchor);
  }

  /**
   * C13: with row numbers, Home and Ctrl+Home on a data cell land on the
   * first field (the grid would go to the row-number column).
   */
  /**
   * With the "+" column (V03 6.3): ArrowRight on the last field stays
   * there, End and Ctrl/Cmd+End land on the last field (the grid would go
   * on to the "+" cell). `col` null: a row-number cell.
   */
  handleLastFieldKey(
    event: KeyboardEvent,
    row: number,
    col: number | null
  ): boolean {
    if (!this.sheet.gridColumns.hasAddFieldColumn) return false;
    if (event.altKey || event.shiftKey) return false;
    const lastCol = this.sheet.fields.visibleFields.length - 1;
    const command = event.ctrlKey || event.metaKey;
    if (event.key === 'ArrowRight' && !command && col === lastCol) {
      stop(event);
      return true;
    }
    if (event.key !== 'End' || lastCol < 0) return false;
    stop(event);
    const last = command ? this.sheet.rows.lastLandingRow() : row;
    if (last < 0 && this.sheet.rows.isGrouped) return true;
    this.sheet.selection.moveFocus({ row: last, col: lastCol }, false);
    return true;
  }

  /**
   * Grouped, without the "+" column: Ctrl+End lands on the last row that
   * is not a header (the grid would go to a collapsed last group's header).
   */
  handleGroupedEndKey(event: KeyboardEvent): boolean {
    if (!this.sheet.rows.isGrouped || this.sheet.gridColumns.hasAddFieldColumn)
      return false;
    if (event.key !== 'End' || !event.ctrlKey) return false;
    if (event.altKey || event.shiftKey || event.metaKey) return false;
    const lastCol = this.sheet.fields.visibleFields.length - 1;
    if (lastCol < 0) return false;
    stop(event);
    const last = this.sheet.rows.lastLandingRow();
    if (last >= 0)
      this.sheet.selection.moveFocus({ row: last, col: lastCol }, false);
    return true;
  }

  handleHomeKey(event: KeyboardEvent, row: number): boolean {
    if (event.key !== 'Home') return false;
    if (event.altKey || event.shiftKey || event.metaKey) return false;
    // grouped, Ctrl+Home is the sheet's also without row numbers: the
    // grid would go to row 0, a header
    if (!this.sheet.colOffset && !(this.sheet.rows.isGrouped && event.ctrlKey))
      return false;
    stop(event);
    // Ctrl+Home: the first record (the add row when there is none)
    const first = this.sheet.rows.firstLandingRow();
    if (event.ctrlKey && first < 0) return true;
    this.sheet.dom.focusGridCell({ row: event.ctrlKey ? first : row, col: 0 });
    // Home also scrolls to the left edge (the frozen field is in view anyway)
    if (this.sheet.frozen.frozenCount)
      this.sheet.frozen.scrollLeftBeforeFocus = 0;
    return true;
  }

  /** The add row: Enter inserts; Space, typing and Delete do nothing (V02-DESIGN.md 5.5). */
  onAddRowKeyDown(event: KeyboardEvent, row: number): void {
    const plain = !event.ctrlKey && !event.metaKey && !event.altKey;
    if (event.key === 'Enter' && plain) {
      stop(event);
      this.sheet.records.appendRecord(row);
      return;
    }
    if (event.key === ' ' && plain) stop(event);
  }

  /**
   * Grouped, on a row-number cell: the page keys and Ctrl+Home/End land
   * as on a data cell, never on a header (V03 8.5, 3.2a). PageUp and
   * PageDown move by the rows in view and Ctrl+Home goes to the first
   * record, both staying in the row-number column; with Shift a page key
   * lands on a record and extends whole rows. Ctrl+End is the data
   * cells' (`handleGroupedEndKey`). True when handled.
   */
  handleGroupedRowNumberKey(event: KeyboardEvent, row: number): boolean {
    if (!this.sheet.rows.isGrouped || event.altKey || event.metaKey)
      return false;
    const { key } = event;
    if ((key === 'PageDown' || key === 'PageUp') && !event.ctrlKey) {
      stop(event);
      const step = key === 'PageDown' ? 1 : -1;
      const target = this.sheet.rows.landingRow(
        row + step * this.sheet.scroll.pageRows(),
        step,
        event.shiftKey
      );
      if (target >= 0 && target !== row)
        this.sheet.dom.focusRowNumberCell(target);
      return true;
    }
    if (key === 'Home' && event.ctrlKey && !event.shiftKey) {
      stop(event);
      const first = this.sheet.rows.firstLandingRow();
      if (first >= 0) this.sheet.dom.focusRowNumberCell(first);
      return true;
    }
    return this.handleGroupedEndKey(event);
  }

  /** Keys of a row-number cell (V02-DESIGN.md 5.5). */
  onRowNumberKeyDown(event: KeyboardEvent, row: number): void {
    if (this.handleCommandKey(event)) return;
    if (this.handleLastFieldKey(event, row, null)) return;
    if (this.handleGroupedRowNumberKey(event, row)) return;
    if (this.sheet.rows.isAddRow(row)) {
      this.onAddRowKeyDown(event, row);
      return;
    }
    const record = this.sheet.rows.recordAt(row);
    if (record === undefined) return;
    const plain = !event.ctrlKey && !event.metaKey && !event.altKey;
    if (isMenuKey(event)) {
      stop(event);
      const cell = this.sheet.dom.rowNumberElement(row);
      if (cell) this.sheet.rowMenu.openMenuAt(row, null, cell);
      return;
    }
    if (event.key === ' ' && plain) {
      stop(event);
      this.sheet.checked.toggleChecked(row, event.shiftKey);
      return;
    }
    if (event.key === 'Enter' && plain && !event.shiftKey) {
      stop(event);
      const recordId = this.sheet.args.getRecordId(record);
      this.sheet.expanded.expandRecord(recordId, { recordId, fieldId: null });
      return;
    }
    if (
      (event.key === 'Delete' || event.key === 'Backspace') &&
      this.sheet.selection.range
    ) {
      stop(event);
      this.sheet.selection.clearSelection();
    }
  }

  onEditKeyDown(event: KeyboardEvent): void {
    // a key the editor claims is the editor's: no prevent, no stop, no action
    if (this.sheet.edit.editing?.type.handlesKey?.(event)) return;
    switch (event.key) {
      case 'Enter':
        stop(event);
        this.sheet.edit.commit({ move: [1, 0] });
        break;
      case 'Tab':
        stop(event);
        this.sheet.edit.commit({ move: [0, event.shiftKey ? -1 : 1] });
        break;
      case 'Escape':
        stop(event);
        this.sheet.edit.cancel();
        break;
      // anything else: the editor handles it
    }
  }

  /** `api.showShortcuts()`, the block's `showShortcuts()` and Ctrl/Cmd+/. */
  showShortcuts = (): void => {
    if (this.sheet.edit.editing) this.sheet.edit.commit({ refocus: false });
    this.sheet.rowMenu.closeMenu(false);
    this.shortcutsOpen = true;
  };

  closeShortcuts = (): void => {
    this.shortcutsOpen = false;
  };

  /** What decides which rows the list shows. */
  get shortcutContext(): ShortcutContext {
    return {
      readOnly: !!this.sheet.args.readOnly,
      canInsert: this.sheet.canInsert,
      rowNumbers: this.sheet.showRowNumbers,
      fieldDrag: this.sheet.fields.fieldDrag
    };
  }
}
