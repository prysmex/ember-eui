/**
 * EuiSheet spike (internal/spikes/sheet/DESIGN.md, section 5.4/5.5): an
 * Airtable-like editable grid built on EuiDataGrid's public API. Capture
 * listeners on a wrapper own the keys and clipboard events the sheet
 * handles; arrow navigation stays with the grid; the editor is a sibling of
 * the grid inside the wrapper.
 */
import Component from '@glimmer/component';
import { cached, tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { on } from '@ember/modifier';
import { assert } from '@ember/debug';
import { modifier } from 'ember-modifier';

import EuiDataGrid from '#src/components/eui-data-grid.gts';

import SheetCellValue from './sheet-cell-value.gts';
import SheetEditor from './sheet-editor.gts';
import {
  clearRange,
  commitPatch,
  formatValue,
  parseTsv,
  pasteMatrix,
  rangeMatrix,
  toRange,
  toTsv
} from './change-set.ts';

import type {
  EuiDataGridColumn,
  EuiDataGridColumnVisibility,
  EuiDataGridRefProps
} from '#src/utils/data-grid/types.ts';
import type {
  ChangeSet,
  EuiSheetField,
  Pos,
  Range,
  RecordId,
  SheetContext
} from './change-set.ts';
import type { SheetEditorRect } from './sheet-editor.gts';

export type CursorSource = 'api' | 'dom';

export interface EuiSheetSignature<T> {
  Args: {
    records: T[];
    fields: EuiSheetField[];
    getRecordId: (record: T) => RecordId;
    onChange: (changeSet: ChangeSet) => void;
    height?: number | string;
    /** Spike only (DESIGN.md section 1, H0): where the focused cell is read from. */
    cursorSource?: CursorSource;
  };
}

/** The part of the API the `api` cursor source needs (cell-api extension, optional). */
interface FocusedCellLocation {
  rowIndex: number;
  colIndex: number;
  visibleRowIndex: number;
}
type SheetGridApi = EuiDataGridRefProps & {
  getFocusedCell?: () => FocusedCellLocation | undefined;
};

const ARROWS = new Set(['ArrowUp', 'ArrowDown', 'ArrowLeft', 'ArrowRight']);

function samePos(a: Pos | null, b: Pos | null): boolean {
  return !!a && !!b && a.row === b.row && a.col === b.col;
}

function clamp(value: number, min: number, max: number): number {
  return Math.max(min, Math.min(max, value));
}

/** "Stop": the event is the sheet's. */
function stop(event: Event): void {
  event.preventDefault();
  event.stopPropagation();
}

export default class EuiSheet<T extends object> extends Component<
  EuiSheetSignature<T>
> {
  /** Selection corners; `head` is where DOM focus is. */
  @tracked anchor: Pos | null = null;
  @tracked head: Pos | null = null;
  /** Cell being edited and the overlay box, relative to the wrapper. */
  @tracked editing: { pos: Pos; rect: SheetEditorRect } | null = null;
  @tracked draft = '';
  /** Controlled column order. */
  @tracked visibleFieldIds: string[] = this.args.fields.map(
    (field) => field.id
  );

  api: SheetGridApi | null = null;
  /** Last data cell seen by `focusin`. */
  domCursor: Pos | null = null;
  /** The next focus move extends the range. */
  extending = false;
  wrapper: HTMLElement | null = null;

  /** Stable object: the grid passes it to every cell renderer. */
  cellContext = { sheet: this };

  /**
   * `dom` by default: the cell-api hook was dropped (RESULTS.md section 7).
   * `api` needs `internal/spikes/sheet/cell-api.patch` applied.
   */
  get source(): CursorSource {
    return this.args.cursorSource ?? 'dom';
  }

  @cached
  get columns(): EuiDataGridColumn[] {
    return this.args.fields.map((field) => ({
      id: field.id,
      displayAsText: field.label ?? field.id,
      isExpandable: field.isExpandable ?? false
    }));
  }

  @cached
  get columnVisibility(): EuiDataGridColumnVisibility {
    return {
      visibleColumns: this.visibleFieldIds,
      setVisibleColumns: this.setVisibleColumns
    };
  }

  setVisibleColumns = (ids: string[]): void => {
    this.visibleFieldIds = ids;
  };

  get visibleFields(): EuiSheetField[] {
    return this.visibleFieldIds
      .map((id) => this.args.fields.find((field) => field.id === id))
      .filter((field): field is EuiSheetField => !!field);
  }

  get range(): Range | null {
    return this.anchor && this.head ? toRange(this.anchor, this.head) : null;
  }

  get context(): SheetContext<T> {
    return {
      records: this.args.records,
      fields: this.visibleFields,
      getRecordId: this.args.getRecordId
    };
  }

  /* -------------------------------------------------------------------- */
  /* Called by the cell renderer                                           */
  /* -------------------------------------------------------------------- */

  isSelected(row: number, col: number): boolean {
    const range = this.range;
    return (
      !!range &&
      row >= range.top &&
      row <= range.bottom &&
      col >= range.left &&
      col <= range.right
    );
  }

  displayValue(row: number, fieldId: string): string {
    const record = this.args.records[row];
    const field = this.args.fields.find((f) => f.id === fieldId);
    if (record === undefined || !field) return '';
    return formatValue(field, (record as Record<string, unknown>)[fieldId]);
  }

  /* -------------------------------------------------------------------- */
  /* Grid wiring                                                           */
  /* -------------------------------------------------------------------- */

  registerApi = (api: EuiDataGridRefProps): void => {
    this.api = api;
  };

  setupWrapper = modifier((element: HTMLElement) => {
    this.wrapper = element;
    return () => {
      this.wrapper = null;
    };
  });

  /** The data cell an event belongs to, or null (header, footer, control column, toolbar, editor). */
  dataCell(target: EventTarget | null): HTMLElement | null {
    if (!(target instanceof Element)) return null;
    const cell = target.closest<HTMLElement>(
      '[role=gridcell][data-gridcell-visible-row-index]'
    );
    if (!cell || !this.wrapper?.contains(cell)) return null;
    if (
      cell.classList.contains('euiDataGridFooterCell') ||
      cell.classList.contains('euiDataGridRowCell--controlColumn')
    ) {
      return null;
    }
    return cell;
  }

  /**
   * Whether a clipboard event on `target` belongs to the sheet. Real copy and
   * paste events are dispatched where the browser's selection is, which after
   * a click is the cell's content element, not the cell (found with trusted
   * events in Chromium). Interactive children of a cell keep their own
   * clipboard behaviour.
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
      target instanceof Element && !!target.closest('.euiSheetSpike__editor')
    );
  }

  /** The focused position, from the grid API (`api`) or the event's cell markup (`dom`). */
  cursor(event: Event): Pos | null {
    if (this.source === 'api') {
      const focused = this.api?.getFocusedCell?.();
      if (!focused || focused.visibleRowIndex < 0) return null;
      return { row: focused.visibleRowIndex, col: focused.colIndex };
    }
    const cell = this.dataCell(event.target);
    if (!cell) return null;
    const row = Number(cell.dataset['gridcellVisibleRowIndex']);
    const col = Number(cell.dataset['gridcellColumnIndex']);
    // the sheet passes no sorting/pagination/row tree (DESIGN.md 5.1)
    assert(
      'EuiSheet: data and visible row indexes differ',
      cell.dataset['gridcellRowIndex'] ===
        cell.dataset['gridcellVisibleRowIndex']
    );
    return { row, col };
  }

  /* -------------------------------------------------------------------- */
  /* Focus tracking                                                        */
  /* -------------------------------------------------------------------- */

  @action
  onFocusIn(event: FocusEvent): void {
    if (!this.dataCell(event.target)) return;
    const pos = this.cursor(event);
    if (!pos) return;
    // the grid re-focuses the same cell when it re-mounts (scroll) and
    // after cancel(): that must not collapse a range
    if (samePos(pos, this.domCursor)) return;
    if (this.extending && this.anchor) {
      this.head = pos;
    } else {
      this.anchor = pos;
      this.head = pos;
    }
    this.domCursor = pos;
  }

  @action
  onMouseDown(event: MouseEvent): void {
    this.extending = event.shiftKey;
  }

  @action
  onDoubleClick(event: MouseEvent): void {
    const cell = this.dataCell(event.target);
    if (!cell) return;
    const pos = this.cursor(event);
    const field = pos && this.visibleFields[pos.col];
    if (!pos || !field || field.readOnly) return;
    this.startEdit(pos, this.displayValue(pos.row, field.id), cell);
  }

  /* -------------------------------------------------------------------- */
  /* Keys and clipboard                                                    */
  /* -------------------------------------------------------------------- */

  @action
  onKeyDown(event: KeyboardEvent): void {
    this.extending = event.shiftKey && ARROWS.has(event.key);
    const target = event.target;
    if (this.editing && this.isInEditor(target)) {
      this.onEditKeyDown(event);
      return;
    }
    const cell = this.dataCell(target);
    if (!cell || target !== cell) return;
    const pos = this.cursor(event);
    if (!pos) return;
    const field = this.visibleFields[pos.col];
    const { key } = event;

    if (key === 'Enter' || key === 'F2') {
      if (!field || field.readOnly) return;
      stop(event);
      this.startEdit(pos, this.displayValue(pos.row, field.id), cell);
      return;
    }
    if (
      key.length === 1 &&
      !event.ctrlKey &&
      !event.metaKey &&
      !event.altKey &&
      !event.isComposing
    ) {
      if (!field || field.readOnly) return;
      // preventDefault keeps the character from being typed twice
      stop(event);
      this.startEdit(pos, key, cell);
      return;
    }
    if (key === 'Delete' || key === 'Backspace') {
      const range = this.range;
      if (!range) return;
      stop(event);
      this.emit(clearRange(this.context, range));
    }
    // arrows, Home/End, PageUp/Down (with or without Shift), Tab, Escape,
    // Ctrl/Meta combos: the grid's own handling
  }

  onEditKeyDown(event: KeyboardEvent): void {
    switch (event.key) {
      case 'Enter':
        stop(event);
        this.commit({ move: [1, 0] });
        break;
      case 'Tab':
        stop(event);
        this.commit({ move: [0, event.shiftKey ? -1 : 1] });
        break;
      case 'Escape':
        stop(event);
        this.cancel();
        break;
      // anything else: the input handles it
    }
  }

  @action
  onCopy(event: ClipboardEvent): void {
    const target = event.target;
    if (this.editing && this.isInEditor(target)) return;
    const cell = this.dataCell(target);
    if (!cell || !this.isClipboardTarget(target, cell)) return;
    const range = this.range;
    if (!range || !event.clipboardData) return;
    event.clipboardData.setData(
      'text/plain',
      toTsv(rangeMatrix(this.context, range))
    );
    // stopPropagation is required: the grid's document copy handlers (F5)
    stop(event);
  }

  @action
  onPaste(event: ClipboardEvent): void {
    const target = event.target;
    if (this.editing && this.isInEditor(target)) return;
    const cell = this.dataCell(target);
    if (!cell || !this.isClipboardTarget(target, cell)) return;
    const data = event.clipboardData;
    if (!data || !Array.from(data.types).includes('text/plain')) return;
    const range = this.range;
    if (!range) return;
    stop(event);
    const anchor = { row: range.top, col: range.left };
    const matrix = parseTsv(data.getData('text/plain'));
    this.emit(pasteMatrix(this.context, anchor, matrix));
    const width = Math.max(...matrix.map((line) => line.length));
    // no setFocusedCell: inserted rows exist only after the next render (F2)
    this.anchor = anchor;
    this.head = {
      row: anchor.row + matrix.length - 1,
      col: Math.min(anchor.col + width - 1, this.visibleFields.length - 1)
    };
  }

  @action
  onScroll(event: Event): void {
    // the input scrolling its own text is not a grid scroll
    if (this.isInEditor(event.target)) return;
    // removes the overlay before a stale position shows, and before the
    // re-mounted focused cell can pull focus (R2)
    if (this.editing) this.commit({ refocus: false });
  }

  /* -------------------------------------------------------------------- */
  /* Edit lifecycle                                                        */
  /* -------------------------------------------------------------------- */

  startEdit(pos: Pos, text: string, cell: HTMLElement): void {
    const wrapper = this.wrapper;
    if (!wrapper) return;
    const box = cell.getBoundingClientRect();
    const origin = wrapper.getBoundingClientRect();
    // client rects are in screen px; an ancestor transform (the test
    // container is scaled to 50%) makes them differ from the CSS px the
    // overlay is positioned in
    const scale = wrapper.offsetWidth ? origin.width / wrapper.offsetWidth : 1;
    this.draft = text;
    this.editing = {
      pos,
      rect: {
        top: (box.top - origin.top) / scale,
        left: (box.left - origin.left) / scale,
        width: box.width / scale,
        height: box.height / scale
      }
    };
  }

  setDraft = (value: string): void => {
    this.draft = value;
  };

  commit({
    move = [0, 0],
    refocus = true
  }: { move?: [number, number]; refocus?: boolean } = {}): void {
    const editing = this.editing;
    if (!editing) return;
    // first: the re-entrancy guard. The blur caused below (or by the input
    // leaving the DOM) finds editing === null and returns.
    const { pos } = editing;
    this.editing = null;
    this.emit(commitPatch(this.context, pos, this.draft));
    if (refocus) {
      const rowIndex = clamp(
        pos.row + move[0],
        0,
        this.args.records.length - 1
      );
      const colIndex = clamp(
        pos.col + move[1],
        0,
        this.visibleFields.length - 1
      );
      // synchronous is safe: the target row already exists (F2)
      this.api?.setFocusedCell({ rowIndex, colIndex });
    }
  }

  cancel(): void {
    const editing = this.editing;
    if (!editing) return;
    this.editing = null;
    this.api?.setFocusedCell({
      rowIndex: editing.pos.row,
      colIndex: editing.pos.col
    });
  }

  @action
  onEditorBlur(): void {
    // no refocus: a clicked cell must keep focus
    if (this.editing) this.commit({ refocus: false });
  }

  emit(changeSet: ChangeSet | null): void {
    if (changeSet) this.args.onChange(changeSet);
  }

  <template>
    <style>
      .euiSheetSpike__cell--selected {
        background: rgba(0, 119, 204, 0.12);
      }
    </style>
    <div
      class="euiSheetSpike"
      style="position:relative"
      data-test-subj="euiSheet"
      {{this.setupWrapper}}
      {{on "keydown" this.onKeyDown capture=true}}
      {{on "copy" this.onCopy capture=true}}
      {{on "paste" this.onPaste capture=true}}
      {{on "scroll" this.onScroll capture=true}}
      {{on "mousedown" this.onMouseDown capture=true}}
      {{on "focusin" this.onFocusIn}}
      {{on "dblclick" this.onDoubleClick}}
    >
      <EuiDataGrid
        aria-label="Sheet"
        @columns={{this.columns}}
        @columnVisibility={{this.columnVisibility}}
        @rowCount={{@records.length}}
        @renderCellValue={{SheetCellValue}}
        @cellContext={{this.cellContext}}
        @registerApi={{this.registerApi}}
        @toolbarVisibility={{false}}
        @height={{@height}}
      />
      {{#if this.editing}}
        <SheetEditor
          @rect={{this.editing.rect}}
          @value={{this.draft}}
          @onInput={{this.setDraft}}
          @onBlur={{this.onEditorBlur}}
        />
      {{/if}}
    </div>
  </template>
}
