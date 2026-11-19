/**
 * EuiSheet: an Airtable-like data-entry grid on EuiDataGrid's public API
 * (PACKAGE-DESIGN.md 7). Controlled: `@records` in, `@onChange(changeSet)`
 * out. Capture listeners on a wrapper own the keys and clipboard events the
 * sheet handles; arrow navigation stays with the grid; the editor is a
 * sibling of the grid inside the wrapper.
 */
import Component from '@glimmer/component';
import { cached, tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { on } from '@ember/modifier';
import { assert } from '@ember/debug';
import { isDestroyed, isDestroying } from '@ember/destroyable';
import { cancel, debounce, next, schedule } from '@ember/runloop';
import { service } from '@ember/service';
import { htmlSafe } from '@ember/template';
import { buildWaiter } from '@ember/test-waiters';
import { modifier } from 'ember-modifier';

import EuiDataGrid from '@ember-eui/core/components/eui-data-grid';
import {
  euiClass,
  getEuiThemeContext,
  useEuiBorealisStyles
} from '@ember-eui/core/theming';

import {
  cellKey,
  clearRange,
  commitText,
  commitValue,
  createMessages,
  fillDown,
  isReadOnly,
  mergeChangeSets,
  mergeErrors,
  parseTsv,
  pasteMatrix,
  rangeMatrix,
  redoChangeSet,
  resolveType,
  tileMatrix,
  toRange,
  toTsv,
  undoChangeSet,
  validateCell,
  valueOf
} from '../core/index.ts';
import { builtInSheetFieldTypes } from '../field-types.ts';
import EditorFrame, {
  EDITOR_SURFACE_SELECTOR
} from '../-private/editor-frame.gts';
import {
  composeIdMaps,
  remapChangeSet,
  remapId,
  toIdMap
} from '../-private/remap.ts';
import SheetCell from '../-private/sheet-cell.gts';
import { ensureStyles } from '../-private/styles.ts';
import { sheetThemeVars } from '../-private/theme.ts';

import type {
  CellErrors,
  ChangeSet,
  EuiSheetField,
  Pos,
  Range,
  RecordId,
  SheetContext,
  SheetMessages
} from '../core/index.ts';
import type {
  EuiSheetFieldType,
  EuiSheetSignature,
  SheetApi,
  SheetEditorRect,
  SheetEditorResult
} from '../types.ts';
import type EuiI18n from '@ember-eui/core/services/eui-i18n';
import type {
  EuiDataGridColumn,
  EuiDataGridColumnVisibility,
  EuiDataGridRefProps
} from '@ember-eui/core/utils/data-grid/types';
import type Owner from '@ember/owner';

export type { EuiSheetSignature };

/** One cell as the renderer shows it (PACKAGE-DESIGN.md 7.3). */
export interface CellView {
  record: unknown;
  field: EuiSheetField;
  type: EuiSheetFieldType;
  value: unknown;
  /** The rejected text, else type.format(value). */
  text: string;
  rejected: boolean;
  errors: string[];
  selected: boolean;
  readOnly: boolean;
}

interface Rejection {
  /** recordId or tempId, as a string. */
  id: string;
  fieldId: string;
  text: string;
  message: string;
  /** The record's value when the rejection was stored; another value means the owner changed it. */
  seenValue: unknown;
}

/**
 * The open editor. One object per edit (the editor is keyed by it), so
 * when the owner moves the record (V02-DESIGN.md 3.2) its position and box
 * change in place and the editor keeps its draft.
 */
class Editing {
  @tracked pos: Pos;
  recordId: RecordId;
  field: EuiSheetField;
  type: EuiSheetFieldType;
  @tracked rect: SheetEditorRect;
  layout: 'cell' | 'panel';
  @tracked placement: 'below' | 'above';
  initialKey: string | null;
  draft: string;

  constructor(init: {
    pos: Pos;
    recordId: RecordId;
    field: EuiSheetField;
    type: EuiSheetFieldType;
    rect: SheetEditorRect;
    layout: 'cell' | 'panel';
    placement: 'below' | 'above';
    initialKey: string | null;
    draft: string;
  }) {
    this.pos = init.pos;
    this.recordId = init.recordId;
    this.field = init.field;
    this.type = init.type;
    this.rect = init.rect;
    this.layout = init.layout;
    this.placement = init.placement;
    this.initialKey = init.initialKey;
    this.draft = init.draft;
  }
}

/** A cell to focus once its record is rendered (V02-DESIGN.md 3.3). */
interface PendingFocus {
  /** The record's id, as a string. */
  id: string;
  fieldId: string;
}

/** What this sheet emitted that the owner has not applied yet, as far as `@records` shows. */
interface PendingOwn {
  deletes: Set<string>;
  inserts: number;
}

interface Validation {
  errors: CellErrors;
  /** The record objects the run started with, by id. */
  records: Map<string, unknown>;
}

type Touched = Array<{ id: RecordId; fieldId: string }>;

const ARROWS = new Set(['ArrowUp', 'ArrowDown', 'ArrowLeft', 'ArrowRight']);

/** A panel editor opens above the cell when less than this is free below it. */
const PANEL_SPACE = 280;

/** Room the focused cell's error box needs below the cell before it flips above. */
const CELL_ERROR_SPACE = 48;
/** The error box's widest size. */
const CELL_ERROR_MAX_WIDTH = 320;

/** A focused data cell and its box, relative to the wrapper. */
interface FocusedCell {
  pos: Pos;
  rect: SheetEditorRect;
  wrapperWidth: number;
  /** Viewport px between the cell's bottom and the window's bottom. */
  viewportBelow: number;
}

/** Undo entries kept per sheet. */
const HISTORY_LIMIT = 100;

/** Debounce of `@validate` runs, in ms. */
const VALIDATE_DEBOUNCE = 50;

/** One counter per page: `localRecords` uses the tempId as the record id, so it is never reused. */
let tempIdCounter = 0;
const nextTempId = (): string => `new-${++tempIdCounter}`;

const validateWaiter = buildWaiter('@ember-eui/sheet:validate');

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

function isPromise<V>(value: unknown): value is Promise<V> {
  return !!value && typeof (value as { then?: unknown }).then === 'function';
}

/** Runs `fn` after the current render (modifiers run inside it: no tracked writes there). */
function afterRender(owner: object, fn: () => void): void {
  schedule('afterRender', () => {
    if (isDestroying(owner) || isDestroyed(owner)) return;
    fn();
  });
}

function sameIds(a: readonly string[], b: readonly string[]): boolean {
  if (a.length !== b.length) return false;
  for (let i = 0; i < a.length; i++) if (a[i] !== b[i]) return false;
  return true;
}

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

export default class EuiSheet<T extends object> extends Component<
  EuiSheetSignature<T>
> {
  @service('eui-i18n') declare euiI18n: EuiI18n;

  /** Selection corners; `head` is where DOM focus is. */
  @tracked anchor: Pos | null = null;
  @tracked head: Pos | null = null;
  @tracked editing: Editing | null = null;
  /** The data cell that has DOM focus, for its error box; null when focus is elsewhere. */
  @tracked focused: FocusedCell | null = null;
  /** Texts a type could not read, by cellKey (PACKAGE-DESIGN.md 6, 7.5). */
  @tracked rejections: ReadonlyMap<string, Rejection> = new Map();
  /** Column order set through the grid; null: the order of `@fields`. */
  @tracked order: string[] | null = null;
  /** The last applied `@validate` result. */
  @tracked validation: Validation | null = null;
  /** A drag over other cells is selecting a range (no text selection meanwhile). */
  @tracked dragging = false;

  /** Plain: the last text the editor reported, and whether it reported one. */
  draft = '';
  draftDirty = false;

  /** The grid's API (not the sheet's: that is `sheetApi`). */
  gridApi: EuiDataGridRefProps | null = null;
  /** Last data cell seen by `focusin`. */
  domCursor: Pos | null = null;
  /** The next focus move extends the range. */
  extending = false;
  wrapper: HTMLElement | null = null;

  /* Undo and redo: the change sets this sheet emitted for user actions */
  undoStack: ChangeSet[] = [];
  redoStack: ChangeSet[] = [];

  /** The cell a left-button press started on, while it may become a drag. */
  dragFrom: Pos | null = null;
  /** The press ended a drag: its click is not a click on a cell. */
  suppressClick = false;

  /** Stable object: the grid passes it to every cell renderer. */
  cellContext = { sheet: this as unknown as EuiSheet<object> };

  /* Following `@records` (V02-DESIGN.md 3.2, 3.3) */
  /** A cell to focus once its record is rendered (inserted rows). */
  pendingFocus: PendingFocus | null = null;
  /** The `@records` of the last render, and their ids. */
  lastRecords: readonly T[] | null = null;
  lastIds: string[] = [];
  /** What emitted change sets insert and delete, until `@records` changes. */
  pendingOwn: PendingOwn = { deletes: new Set(), inserts: 0 };
  /** Every id `remapIds` was told about, old (as a string) → new. */
  remapped: Map<string, RecordId> = new Map();

  /** The sheet's API for its owner (`@registerApi`): one stable object. */
  sheetApi: SheetApi = {
    undo: () => this.undo(),
    redo: () => this.redo(),
    focusCell: (cell) => this.focusRecordCell(cell),
    remapIds: (ids) => this.remapIds(ids),
    clearHistory: () => this.clearHistory()
  };

  /* `@validate` runs */
  validateTimer: ReturnType<typeof debounce> | null = null;
  validateSeq = 0;
  validateController: AbortController | null = null;
  validateToken: unknown = null;
  changedSinceRun: Array<{ recordId: RecordId; fieldId: string }> = [];

  /** Messages through `eui-i18n` (each call looks its token up). */
  translatedMessages: SheetMessages = createMessages((token, def, values) =>
    this.euiI18n.lookupToken(token, def, values)
  );

  constructor(owner: Owner, args: EuiSheetSignature<T>['Args']) {
    super(owner, args);
    ensureStyles();
  }

  willDestroy(): void {
    super.willDestroy();
    if (this.validateTimer) cancel(this.validateTimer);
    this.validateController?.abort();
    this.endValidateWaiter();
    this.stopWatchingRelease();
  }

  /* -------------------------------------------------------------------- */
  /* Derived state                                                         */
  /* -------------------------------------------------------------------- */

  @cached
  get types(): Record<string, EuiSheetFieldType<any, any>> {
    return { ...builtInSheetFieldTypes, ...this.args.fieldTypes };
  }

  /** `@messages` over the `eui-i18n` translations over the English defaults. */
  @cached
  get messages(): SheetMessages {
    return { ...this.translatedMessages, ...this.args.messages };
  }

  @cached
  get columns(): EuiDataGridColumn[] {
    return this.args.fields.map((field) => ({
      id: field.id,
      displayAsText: field.label ?? field.id,
      isExpandable: false
    }));
  }

  @cached
  get visibleFieldIds(): string[] {
    const ids = this.args.fields.map((field) => field.id);
    if (!this.order) return ids;
    const kept = this.order.filter((id) => ids.includes(id));
    return [...kept, ...ids.filter((id) => !kept.includes(id))];
  }

  @cached
  get columnVisibility(): EuiDataGridColumnVisibility {
    return {
      visibleColumns: this.visibleFieldIds,
      setVisibleColumns: this.setVisibleColumns
    };
  }

  setVisibleColumns = (ids: string[]): void => {
    this.order = ids;
  };

  @cached
  get visibleFields(): EuiSheetField<T>[] {
    return this.visibleFieldIds
      .map((id) => this.args.fields.find((field) => field.id === id))
      .filter((field): field is EuiSheetField<T> => !!field);
  }

  get range(): Range | null {
    return this.anchor && this.head ? toRange(this.anchor, this.head) : null;
  }

  @cached
  get context(): SheetContext<T> {
    return {
      records: this.args.records,
      fields: this.visibleFields,
      getRecordId: this.args.getRecordId,
      types: this.types,
      messages: this.messages,
      readOnly: this.args.readOnly
    };
  }

  get ariaLabel(): string {
    return this.args.ariaLabel ?? 'Sheet';
  }

  /**
   * Leading control columns of the grid (V02-DESIGN.md 3.2): positions
   * (`anchor`, `head`, `Range`) use data columns, the grid's column index
   * is the data column plus this. None yet.
   */
  get colOffset(): number {
    return 0;
  }

  /** Whether the grid has an "add" row after the records. Not yet. */
  get hasAddRow(): boolean {
    return false;
  }

  get rowCount(): number {
    return this.args.records.length + (this.hasAddRow ? 1 : 0);
  }

  /** The record of a row; `undefined` for the add row. */
  recordAt(row: number): T | undefined {
    return this.args.records[row];
  }

  /** The class that defines the `--euiSheet-*` colours from the EUI theme. */
  @cached
  get themeClass(): string {
    const context = getEuiThemeContext(this);
    return euiClass(context, useEuiBorealisStyles(context, sheetThemeVars));
  }

  typeOf(field: EuiSheetField): EuiSheetFieldType {
    return resolveType(this.types, field) as EuiSheetFieldType;
  }

  /** The rejection of a cell, unless the owner changed the value since. */
  liveRejection(
    record: T,
    recordId: RecordId,
    fieldId: string
  ): Rejection | undefined {
    const rejection = this.rejections.get(cellKey(recordId, fieldId));
    if (!rejection) return undefined;
    return Object.is(rejection.seenValue, valueOf(record, fieldId))
      ? rejection
      : undefined;
  }

  /** `@validate`'s errors of a cell, unless its record changed since the run started. */
  validatedErrors(
    record: T,
    recordId: RecordId,
    fieldId: string
  ): string | string[] | undefined {
    const validation = this.validation;
    if (!validation) return undefined;
    const id = String(recordId);
    if (validation.records.get(id) !== record) return undefined;
    return validation.errors[id]?.[fieldId];
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

  cellView(row: number, col: number, fieldId: string): CellView | null {
    const record = this.recordAt(row);
    const field = this.visibleFields.find((f) => f.id === fieldId);
    if (record === undefined || !field) return null;
    const ctx = this.context;
    const type = this.typeOf(field);
    const value = valueOf(record, field.id);
    const recordId = ctx.getRecordId(record);
    const rejection = this.liveRejection(record, recordId, field.id);
    const text = rejection
      ? rejection.text
      : type.format(value, field, { record, messages: ctx.messages });
    // a rejected cell shows only its rejection and the owner's errors: the
    // other layers describe the old value (PACKAGE-DESIGN.md 6, 9.4)
    const errors = rejection
      ? mergeErrors(
          rejection.message,
          this.args.cellErrors?.[String(recordId)]?.[field.id]
        )
      : mergeErrors(
          validateCell(ctx, field, record),
          this.validatedErrors(record, recordId, field.id),
          this.args.cellErrors?.[String(recordId)]?.[field.id]
        );
    return {
      record,
      field,
      type,
      value,
      text,
      rejected: !!rejection,
      errors,
      selected: this.isSelected(row, col),
      readOnly: isReadOnly(ctx, field, record)
    };
  }

  /** A cell component's `@onCommit(value)`. */
  commitCellValue(row: number, col: number, value: unknown): void {
    const pos = { row, col };
    const touched = this.touchedAt(pos);
    this.emit(commitValue(this.context, pos, value), touched);
  }

  /* -------------------------------------------------------------------- */
  /* Grid wiring                                                           */
  /* -------------------------------------------------------------------- */

  registerGridApi = (api: EuiDataGridRefProps): void => {
    this.gridApi = api;
  };

  /** Focuses a cell by its position (data column). */
  focusGridCell(pos: Pos): void {
    this.gridApi?.setFocusedCell({
      rowIndex: pos.row,
      colIndex: pos.col + this.colOffset
    });
  }

  /** Gives the owner the sheet's API, once, after the first render. */
  registerSheetApi = modifier(() => {
    afterRender(this, () => this.args.registerApi?.(this.sheetApi));
  });

  setupWrapper = modifier((element: HTMLElement) => {
    this.wrapper = element;
    return () => {
      this.wrapper = null;
    };
  });

  /**
   * Whenever `@records` is a new array: schedules a `@validate` run and,
   * after the render, follows the records (`recordsRendered`).
   */
  watchRecords = modifier((_element: HTMLElement, [records]: [unknown]) => {
    void records;
    this.scheduleValidate();
    afterRender(this, () => this.recordsRendered());
  });

  /**
   * After a render with a new `@records` (V02-DESIGN.md 3.2, 3.3). A change
   * that is not the sheet's own (the owner re-sorted, re-queried, reloaded)
   * moves the selection, focus and an open editor to their record; then a
   * pending focus whose record is now rendered is applied.
   */
  recordsRendered(): void {
    const records = this.args.records;
    if (records === this.lastRecords) return;
    const previous = this.lastRecords;
    const previousIds = this.lastIds;
    const ids = records.map((record) => String(this.args.getRecordId(record)));
    const pending = this.pendingOwn;
    this.lastRecords = records;
    this.lastIds = ids;
    this.pendingOwn = { deletes: new Set(), inserts: 0 };
    if (
      previous &&
      !sameIds(previousIds, ids) &&
      !isOwnChange(previousIds, ids, pending)
    ) {
      this.followRecords(previousIds, ids);
    }
    this.applyPendingFocus();
  }

  /**
   * The owner replaced `@records`: the selection collapses to the head's
   * cell, found again by record id (or the same row, clamped, when that
   * record is gone); an open editor stays on its record, or is cancelled
   * without a change set when the record is gone; a drag ends. A data cell
   * that had focus is focused again at the new position.
   */
  followRecords(previousIds: readonly string[], ids: readonly string[]): void {
    const indexOf = new Map(ids.map((id, i) => [id, i]));
    const active = document.activeElement;
    // a data cell has focus, or had it until this render removed its row
    const hadCellFocus =
      !!this.dataCell(active) ||
      (this.focusDropped && (!active || active === document.body));
    let hadEditorFocus = false;
    if (this.dragging || this.dragFrom) this.endDrag();

    const editing = this.editing;
    if (editing) {
      const row = indexOf.get(String(editing.recordId));
      if (row === undefined) {
        hadEditorFocus = this.isInEditor(active);
        this.editing = null;
      } else {
        editing.pos = { row, col: editing.pos.col };
        const cell = this.cellElement(editing.pos);
        const rect = cell && this.rectOf(cell);
        if (rect) {
          editing.rect = rect;
        } else {
          // the row is not rendered: as on scroll
          this.commit({ refocus: false });
        }
      }
    }

    const head = this.head;
    if (head) {
      const id = previousIds[head.row];
      const found = id === undefined ? undefined : indexOf.get(id);
      if (this.rowCount === 0) {
        this.anchor = null;
        this.head = null;
      } else {
        const pos = {
          row: found ?? clamp(head.row, 0, this.rowCount - 1),
          col: head.col
        };
        this.anchor = pos;
        this.head = pos;
        if ((hadCellFocus || hadEditorFocus) && !this.editing) {
          // onFocusIn sees the cell it already knows and keeps the range
          this.domCursor = pos;
          this.focusGridCell(pos);
        }
      }
    }
    // the error box is placed again when its cell gets focus
    if (!hadCellFocus) this.focused = null;
  }

  /** Focuses the pending cell once its record is in `@records` (it is rendered by now). */
  applyPendingFocus(): void {
    const pending = this.pendingFocus;
    if (!pending) return;
    const row = this.lastIds.indexOf(pending.id);
    if (row < 0) return;
    this.pendingFocus = null;
    const col = Math.max(
      0,
      this.visibleFields.findIndex((field) => field.id === pending.fieldId)
    );
    const pos = { row, col };
    this.anchor = pos;
    this.head = pos;
    this.domCursor = pos;
    this.focusGridCell(pos);
  }

  /** The rendered grid cell at a position, if it is rendered. */
  cellElement(pos: Pos): HTMLElement | null {
    return (
      this.wrapper?.querySelector<HTMLElement>(
        `[role=gridcell][data-gridcell-visible-row-index="${pos.row}"][data-gridcell-column-index="${pos.col + this.colOffset}"]`
      ) ?? null
    );
  }

  /** The row of a record now, trying `hint` first; -1 when it is gone. */
  rowOf(recordId: RecordId, hint: number): number {
    const records = this.args.records;
    const getId = this.args.getRecordId;
    const id = String(recordId);
    const atHint = records[hint];
    if (atHint !== undefined && String(getId(atHint)) === id) return hint;
    return records.findIndex((record) => String(getId(record)) === id);
  }

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
    const col = Number(cell.dataset['gridcellColumnIndex']) - this.colOffset;
    // the sheet passes no sorting/pagination/row tree
    assert(
      'EuiSheet: data and visible row indexes differ',
      cell.dataset['gridcellRowIndex'] ===
        cell.dataset['gridcellVisibleRowIndex']
    );
    return { row, col };
  }

  touchedAt(pos: Pos): Touched {
    const record = this.recordAt(pos.row);
    const field = this.visibleFields[pos.col];
    if (record === undefined || !field) return [];
    return [{ id: this.args.getRecordId(record), fieldId: field.id }];
  }

  /** Every existing cell of a range (clamped), optionally only the writable ones. */
  touchedIn(range: Range, writableOnly: boolean): Touched {
    const touched: Touched = [];
    const records = this.args.records;
    const fields = this.visibleFields;
    for (
      let row = Math.max(range.top, 0);
      row <= Math.min(range.bottom, records.length - 1);
      row++
    ) {
      const record = records[row]!;
      for (
        let col = Math.max(range.left, 0);
        col <= Math.min(range.right, fields.length - 1);
        col++
      ) {
        const field = fields[col]!;
        if (writableOnly && isReadOnly(this.context, field, record)) continue;
        touched.push({ id: this.args.getRecordId(record), fieldId: field.id });
      }
    }
    return touched;
  }

  /* -------------------------------------------------------------------- */
  /* Focus tracking                                                        */
  /* -------------------------------------------------------------------- */

  @action
  onFocusIn(event: FocusEvent): void {
    const cell = this.dataCell(event.target);
    if (!cell) {
      // the header, a control or an editor: no error box (an open editor
      // hides it anyway)
      if (!this.isInEditor(event.target)) this.focused = null;
      return;
    }
    const pos = this.cursor(cell);
    this.trackFocusedCell(pos, cell);
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

  /**
   * A data cell lost focus to nowhere in this run loop: a render removed
   * it (the owner dropped its row), or a click outside. `followRecords`
   * re-focuses the grid only in the first case.
   */
  focusDropped = false;

  /** Focus leaving the grid's data cells hides the error box. */
  @action
  onFocusOut(event: FocusEvent): void {
    const to = event.relatedTarget;
    if (this.dataCell(to) || this.isInEditor(to)) return;
    this.focused = null;
    if (!to && this.dataCell(event.target)) {
      this.focusDropped = true;
      next(() => (this.focusDropped = false));
    }
  }

  trackFocusedCell(pos: Pos, cell: HTMLElement): void {
    const rect = this.rectOf(cell);
    if (!rect || !this.wrapper) return;
    this.focused = {
      pos,
      rect,
      wrapperWidth: this.wrapper.offsetWidth,
      viewportBelow: window.innerHeight - cell.getBoundingClientRect().bottom
    };
  }

  /**
   * The focused cell's errors, shown next to it while it has focus and no
   * editor is open (the cell's `title` has them too, on hover).
   */
  get cellError(): {
    messages: string[];
    placement: 'below' | 'above';
    style: ReturnType<typeof htmlSafe>;
  } | null {
    const focused = this.focused;
    if (!focused || this.editing) return null;
    const field = this.visibleFields[focused.pos.col];
    if (!field) return null;
    const view = this.cellView(focused.pos.row, focused.pos.col, field.id);
    if (!view || view.errors.length === 0) return null;
    const { rect, wrapperWidth, viewportBelow } = focused;
    // the box may hang below the sheet; it flips only near the window's bottom
    const placement = viewportBelow < CELL_ERROR_SPACE ? 'above' : 'below';
    const vertical =
      placement === 'above'
        ? `bottom:${rect.wrapperHeight - rect.top + 2}px;`
        : `top:${rect.top + rect.height + 2}px;`;
    const left = Math.max(
      0,
      Math.min(rect.left, wrapperWidth - CELL_ERROR_MAX_WIDTH)
    );
    return {
      messages: view.errors,
      placement,
      style: htmlSafe(
        `left:${left}px;max-width:${CELL_ERROR_MAX_WIDTH}px;${vertical}`
      )
    };
  }

  /** The press started on the cell that already had focus (a second click edits). */
  pressOnFocusedCell = false;

  @action
  onMouseDown(event: MouseEvent): void {
    this.extending = event.shiftKey;
    // before the press moves focus: was this cell the focused one?
    const cell = this.dataCell(event.target);
    this.pressOnFocusedCell = !!cell && cell === document.activeElement;
    // a click after a drag that released outside the sheet never came
    this.suppressClick = false;
    this.endDrag();
    // a press that may become a drag (Shift+click extends instead)
    if (
      cell &&
      event.button === 0 &&
      !event.shiftKey &&
      !this.editing &&
      !(event.target as Element).closest('[data-eui-sheet-opener]')
    ) {
      this.dragFrom = this.cursor(cell);
      document.addEventListener('mouseup', this.onRelease, true);
    }
  }

  /**
   * Drag to select: once the pointer is over another data cell, the pressed
   * cell is the anchor and the hovered one the head. Nothing changes while
   * the pointer stays on the pressed cell, so a click is only a click.
   */
  @action
  onMouseOver(event: MouseEvent): void {
    const from = this.dragFrom;
    if (!from) return;
    const cell = this.dataCell(event.target);
    if (!cell) return;
    const pos = this.cursor(cell);
    if (!this.dragging) {
      if (samePos(pos, from)) return;
      this.dragging = true;
      this.anchor = from;
    }
    if (!samePos(pos, this.head)) this.head = pos;
    // text the press may have started to select
    window.getSelection()?.removeAllRanges();
  }

  /** The release ends a drag (anywhere on the page): focus goes to the head, keeping the anchor. */
  onRelease = (): void => {
    const dragged = this.dragging;
    this.endDrag();
    if (!dragged) return;
    const head = this.head;
    if (!head || samePos(head, this.anchor)) return;
    // the click that follows is the end of the drag, not a click on a cell
    this.suppressClick = true;
    // onFocusIn keeps the anchor, so Shift+arrows continue from here
    this.extending = true;
    if (head.row < this.rowCount) {
      // the head is rendered (it was hovered): the grid focuses it at once
      this.focusGridCell(head);
    }
    this.extending = false;
  };

  endDrag(): void {
    this.stopWatchingRelease();
    this.dragFrom = null;
    if (this.dragging) this.dragging = false;
  }

  stopWatchingRelease(): void {
    document.removeEventListener('mouseup', this.onRelease, true);
  }

  /**
   * Airtable-style clicks: the first click selects (the grid focuses the
   * cell); a click on the selected cell edits; the type's opener button
   * opens the editor in one click; a type with `onCellClick` (the checkbox)
   * saves on any click.
   */
  @action
  onClick(event: MouseEvent): void {
    const pressOnFocusedCell = this.pressOnFocusedCell;
    this.pressOnFocusedCell = false;
    if (this.suppressClick) {
      this.suppressClick = false;
      return;
    }
    if (event.shiftKey || this.editing) return;
    const cell = this.dataCell(event.target);
    if (!cell) return;
    const pos = this.cursor(cell);
    const record = this.recordAt(pos.row);
    const field = this.visibleFields[pos.col];
    if (record === undefined || !field) return;
    const type = this.typeOf(field);
    const target = event.target as Element;
    if (target.closest('[data-eui-sheet-opener]')) {
      if (this.canEdit(pos)) this.startEdit(pos, cell, null);
      return;
    }
    if (type.onCellClick) {
      if (isReadOnly(this.context, field, record)) return;
      const result = type.onCellClick(
        valueOf(record, field.id) as never,
        field,
        record
      );
      if (result) this.commitCellValue(pos.row, pos.col, result.value);
      return;
    }
    if (pressOnFocusedCell && this.canEdit(pos)) {
      this.startEdit(pos, cell, null);
    }
  }

  /** Whether the cell at `pos` opens an editor. */
  canEdit(pos: Pos): boolean {
    const record = this.recordAt(pos.row);
    const field = this.visibleFields[pos.col];
    if (record === undefined || !field) return false;
    return (
      !!this.typeOf(field).editor && !isReadOnly(this.context, field, record)
    );
  }

  @action
  onDoubleClick(event: MouseEvent): void {
    // the double-click's second click already opened the editor
    if (this.editing) return;
    const cell = this.dataCell(event.target);
    if (!cell) return;
    const pos = this.cursor(cell);
    if (this.canEdit(pos)) this.startEdit(pos, cell, null);
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
    const pos = this.cursor(cell);
    const record = this.recordAt(pos.row);
    const field = this.visibleFields[pos.col];
    if (record === undefined || !field) return;
    const ctx = this.context;
    const type = this.typeOf(field);
    const readOnly = isReadOnly(ctx, field, record);
    const { key } = event;
    const plain = !event.ctrlKey && !event.metaKey && !event.altKey;

    if ((event.ctrlKey || event.metaKey) && !event.altKey) {
      // with Shift, `key` is upper case
      const letter = key.toLowerCase();
      if (letter === 'z') {
        stop(event);
        if (event.shiftKey) this.redo();
        else this.undo();
        return;
      }
      if (letter === 'y' && event.ctrlKey && !event.shiftKey) {
        stop(event);
        this.redo();
        return;
      }
      if (letter === 'd' && !event.shiftKey) {
        // also keeps the browser from bookmarking the page
        stop(event);
        this.fill();
        return;
      }
      if (letter === 'a' && !event.shiftKey) {
        // every cell; focus stays where it is
        stop(event);
        this.anchor = { row: 0, col: 0 };
        this.head = {
          row: this.args.records.length - 1,
          col: this.visibleFields.length - 1
        };
        return;
      }
    }

    // navKey first: a checkbox's Space (PACKAGE-DESIGN.md 7.4)
    if (plain && !readOnly && type.navKey) {
      const result = type.navKey(key, valueOf(record, field.id), field);
      if (result) {
        stop(event);
        this.emit(commitValue(ctx, pos, result.value), this.touchedAt(pos));
        return;
      }
    }
    if (key === ' ' && plain) {
      // reserved (P8); also keeps the page from scrolling
      stop(event);
      return;
    }
    if (key === 'Enter' || key === 'F2') {
      if (!type.editor || readOnly) return;
      stop(event);
      this.startEdit(pos, cell, null);
      return;
    }
    if (key.length === 1 && plain && !event.isComposing) {
      if (!type.editor || readOnly) return;
      if (!(type.opensOnKey?.(key) ?? true)) return;
      // preventDefault keeps the character from being typed twice
      stop(event);
      this.startEdit(pos, cell, key);
      return;
    }
    if (key === 'Delete' || key === 'Backspace') {
      const range = this.range;
      if (!range) return;
      stop(event);
      this.emit(clearRange(ctx, range), this.touchedIn(range, true));
    }
    // arrows, Home/End, PageUp/Down (with or without Shift), Tab, Escape,
    // Ctrl/Meta combos: the grid's own handling
  }

  /** Ctrl/Cmd+D: fill the range down, or the cell from the one above. */
  fill(): void {
    const range = this.range;
    if (!range) return;
    // the cells written: below the top row, or the row itself (from above)
    const targets =
      range.bottom > range.top ? { ...range, top: range.top + 1 } : range;
    this.emit(fillDown(this.context, range), this.touchedIn(targets, true));
  }

  /* -------------------------------------------------------------------- */
  /* Undo and redo                                                         */
  /* -------------------------------------------------------------------- */

  /** What undo and redo need besides the records: every field id (a restored record's values). */
  get historyOptions(): { fieldIds: string[] } {
    return { fieldIds: this.args.fields.map((field) => field.id) };
  }

  /** Emits the inverse of the last entry, without the cells changed since. */
  undo(): void {
    if (this.args.readOnly) return;
    const entry = this.undoStack.pop();
    if (!entry) return;
    this.redoStack.push(entry);
    this.applyHistory(
      undoChangeSet(
        entry,
        this.args.records,
        this.args.getRecordId,
        this.historyOptions
      )
    );
  }

  /** Emits the last undone entry again, without the cells changed since. */
  redo(): void {
    if (this.args.readOnly) return;
    const entry = this.redoStack.pop();
    if (!entry) return;
    this.undoStack.push(entry);
    this.applyHistory(
      redoChangeSet(
        entry,
        this.args.records,
        this.args.getRecordId,
        this.historyOptions
      )
    );
  }

  clearHistory(): void {
    this.undoStack = [];
    this.redoStack = [];
  }

  /** `SheetApi.focusCell`. */
  focusRecordCell({
    recordId,
    fieldId
  }: {
    recordId: RecordId;
    fieldId: string;
  }): void {
    const row = this.rowOf(recordId, this.head?.row ?? 0);
    const col = this.visibleFields.findIndex((field) => field.id === fieldId);
    if (row < 0 || col < 0) return;
    const pos = { row, col };
    this.anchor = pos;
    this.head = pos;
    this.domCursor = pos;
    this.focusGridCell(pos);
  }

  /**
   * `SheetApi.remapIds`: rewrites the history, the rejections, a pending
   * focus, an open editor's record and the ids of the last `@records`.
   */
  remapIds(ids: Record<string, RecordId>): void {
    const map = toIdMap(ids);
    if (!map.size) return;
    this.remapped = composeIdMaps(this.remapped, map);
    this.undoStack = this.undoStack.map((entry) => remapChangeSet(entry, map));
    this.redoStack = this.redoStack.map((entry) => remapChangeSet(entry, map));
    if (this.rejections.size) {
      const next = new Map<string, Rejection>();
      for (const entry of this.rejections.values()) {
        const id = String(remapId(entry.id, map));
        next.set(cellKey(id, entry.fieldId), { ...entry, id });
      }
      this.rejections = next;
    }
    if (this.pendingFocus) {
      this.pendingFocus = {
        ...this.pendingFocus,
        id: String(remapId(this.pendingFocus.id, map))
      };
    }
    if (this.editing) {
      this.editing.recordId = remapId(this.editing.recordId, map);
    }
    // a `@records` that only carries the new ids is not a change of rows
    this.lastIds = this.lastIds.map((id) => String(remapId(id, map)));
    const deletes = [...this.pendingOwn.deletes].map((id) =>
      String(remapId(id, map))
    );
    this.pendingOwn = { ...this.pendingOwn, deletes: new Set(deletes) };
  }

  /** Emits an undo or redo (if anything is left of it) and selects what it changed. */
  applyHistory(changeSet: ChangeSet | null): void {
    if (!changeSet) return;
    const before = this.args.records.length;
    this.emit(
      changeSet,
      changeSet.patches.map((patch) => ({
        id: patch.recordId,
        fieldId: patch.fieldId
      }))
    );
    this.selectChanged(changeSet, before);
  }

  /**
   * Selects the bounding box of the patched cells and focuses its top-left
   * cell. Only rows that exist both before and after the change are used:
   * inserted rows are rendered only on the next render, and the grid throws
   * for a row past its last one. A change that only inserts (an undone
   * delete) focuses the first inserted record once it is rendered.
   */
  selectChanged(changeSet: ChangeSet, rowsBefore: number): void {
    // the owner's records after it applied the change set, if it did at once
    const records = this.args.records;
    const rows = Math.min(rowsBefore, records.length);
    const indexOf = new Map(
      records.map((record, i) => [String(this.args.getRecordId(record)), i])
    );
    let box: Range | null = null;
    for (const patch of changeSet.patches) {
      const row = indexOf.get(String(patch.recordId));
      const col = this.visibleFields.findIndex(
        (field) => field.id === patch.fieldId
      );
      if (row === undefined || row >= rows || col < 0) continue;
      box = box
        ? {
            top: Math.min(box.top, row),
            left: Math.min(box.left, col),
            bottom: Math.max(box.bottom, row),
            right: Math.max(box.right, col)
          }
        : { top: row, left: col, bottom: row, right: col };
    }
    let focus: Pos;
    if (box) {
      focus = { row: box.top, col: box.left };
      this.anchor = { row: box.bottom, col: box.right };
    } else if (changeSet.inserts.length) {
      const field = this.visibleFields[this.head?.col ?? 0];
      if (!field) return;
      this.pendingFocus = {
        id: changeSet.inserts[0]!.tempId,
        fieldId: field.id
      };
      // the owner may have applied it already; else the next render does
      afterRender(this, () => this.applyPendingFocus());
      return;
    } else {
      // nothing patched (an undo that only removed rows): keep focus on a
      // row that still exists
      const head = this.head;
      if (!head || head.row < rows || rows === 0) return;
      focus = { row: rows - 1, col: head.col };
      this.anchor = focus;
    }
    this.head = focus;
    // onFocusIn sees the cell it already knows and keeps the range
    this.domCursor = focus;
    this.focusGridCell(focus);
  }

  onEditKeyDown(event: KeyboardEvent): void {
    // a key the editor claims is the editor's: no prevent, no stop, no action
    if (this.editing?.type.handlesKey?.(event)) return;
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
      // anything else: the editor handles it
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
    // stopPropagation is required: the grid's document copy handlers
    stop(event);
  }

  @action
  onPaste(event: ClipboardEvent): void {
    if (this.args.readOnly) return;
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
    // a block that fits the selection a whole number of times fills it
    const matrix = tileMatrix(
      parseTsv(data.getData('text/plain')),
      range.bottom - range.top + 1,
      range.right - range.left + 1
    );
    const width = Math.max(...matrix.map((line) => line.length));
    const pasted = {
      top: anchor.row,
      left: anchor.col,
      bottom: anchor.row + matrix.length - 1,
      right: Math.min(anchor.col + width - 1, this.visibleFields.length - 1)
    };
    this.emit(
      pasteMatrix(this.context, anchor, matrix, { nextTempId }),
      this.touchedIn(pasted, false)
    );
    // no setFocusedCell: inserted rows exist only after the next render
    this.anchor = anchor;
    this.head = { row: pasted.bottom, col: pasted.right };
  }

  @action
  onScroll(event: Event): void {
    // the editor scrolling its own content is not a grid scroll
    if (this.isInEditor(event.target)) return;
    // removes the editor before a stale position shows, and before the
    // re-mounted focused cell can pull focus
    if (this.editing) this.commit({ refocus: false });
    // the error box follows its cell, or hides while the cell is not rendered
    const focused = this.focused;
    if (focused) {
      const cell = this.dataCell(document.activeElement);
      if (cell && samePos(this.cursor(cell), focused.pos)) {
        this.trackFocusedCell(focused.pos, cell);
      } else {
        this.focused = null;
      }
    }
  }

  /* -------------------------------------------------------------------- */
  /* Edit lifecycle                                                        */
  /* -------------------------------------------------------------------- */

  /** A cell's box relative to the wrapper, in the wrapper's CSS px. */
  rectOf(cell: HTMLElement): SheetEditorRect | null {
    const wrapper = this.wrapper;
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

  startEdit(pos: Pos, cell: HTMLElement, initialKey: string | null): void {
    const wrapper = this.wrapper;
    const record = this.recordAt(pos.row);
    const field = this.visibleFields[pos.col];
    if (!wrapper || record === undefined || !field) return;
    const type = this.typeOf(field);
    const recordId = this.args.getRecordId(record);
    const rect = this.rectOf(cell);
    if (!rect) return;
    const layout = type.editorLayout ?? 'cell';
    const below = rect.wrapperHeight - (rect.top + rect.height);
    const placement =
      layout === 'panel' && below < PANEL_SPACE && rect.top > below
        ? 'above'
        : 'below';
    const rejection = this.liveRejection(record, recordId, field.id);
    const draft =
      initialKey ??
      rejection?.text ??
      type.format(valueOf(record, field.id), field, {
        record,
        messages: this.messages
      });
    this.draft = draft;
    this.draftDirty = false;
    this.editing = new Editing({
      pos,
      recordId,
      field,
      type,
      rect,
      layout,
      placement,
      initialKey,
      draft
    });
  }

  /**
   * The open editor as a one-item list, rendered with `{{#each}}` keyed by
   * identity: each edit gets its own editor instance, and an editor's args
   * stay those of its own edit while it is torn down (EuiSelectable reads
   * its options from a scheduled blur handler after the edit ended).
   */
  @cached
  get editingList(): Editing[] {
    return this.editing ? [this.editing] : [];
  }

  /** The edited record, by id: the owner may have moved it (V02-DESIGN.md 3.2). */
  editorRecord = (editing: Editing): T | undefined =>
    this.args.records[this.rowOf(editing.recordId, editing.pos.row)];

  editorValue = (editing: Editing): unknown =>
    valueOf(this.editorRecord(editing), editing.field.id);

  commit({
    move = [0, 0],
    refocus = true,
    result
  }: {
    move?: [number, number];
    refocus?: boolean;
    result?: SheetEditorResult<unknown>;
  } = {}): void {
    const editing = this.editing;
    if (!editing) return;
    // first: the re-entrancy guard. The focusout caused below (or by the
    // editor leaving the DOM) finds editing === null and returns.
    this.editing = null;
    // the edited record's row now; gone: nothing to save
    const row = this.rowOf(editing.recordId, editing.pos.row);
    if (row < 0) return;
    const pos = { row, col: editing.pos.col };
    const ctx = this.context;
    let ran = true;
    let changeSet: ChangeSet | null = null;
    if (result && 'value' in result) {
      changeSet = commitValue(ctx, pos, result.value);
    } else if (result && 'text' in result) {
      changeSet = commitText(ctx, pos, result.text);
    } else if (this.draftDirty) {
      changeSet = commitText(ctx, pos, this.draft);
    } else {
      ran = false;
    }
    if (ran) {
      this.emit(changeSet, [
        { id: editing.recordId, fieldId: editing.field.id }
      ]);
    }
    if (refocus) {
      // synchronous is safe: the target row already exists
      this.focusGridCell({
        row: clamp(pos.row + move[0], 0, this.args.records.length - 1),
        col: clamp(pos.col + move[1], 0, this.visibleFields.length - 1)
      });
    }
  }

  cancel = (): void => {
    const editing = this.editing;
    if (!editing) return;
    this.editing = null;
    const row = this.rowOf(editing.recordId, editing.pos.row);
    if (row < 0) return;
    this.focusGridCell({ row, col: editing.pos.col });
  };

  /* Editor callbacks, bound once */

  onDraftChange = (text: string): void => {
    this.draft = text;
    this.draftDirty = true;
  };

  onEditorCommit = (
    result?: SheetEditorResult<unknown>,
    options?: { move?: [number, number] }
  ): void => {
    this.commit({ result, move: options?.move });
  };

  onEditorFocusOut = (): void => {
    // no refocus: a clicked cell must keep focus
    if (this.editing) this.commit({ refocus: false });
  };

  /* -------------------------------------------------------------------- */
  /* Emitting change sets                                                  */
  /* -------------------------------------------------------------------- */

  /**
   * Updates the rejections (drops the touched cells and entries whose record
   * is gone, adds the change set's), then calls `@onChange`.
   */
  emit(changeSet: ChangeSet | null, touched: Touched): void {
    const next = new Map(this.rejections);
    let changed = false;
    for (const { id, fieldId } of touched) {
      if (next.delete(cellKey(id, fieldId))) changed = true;
    }
    if (changeSet?.deletes?.length) {
      // the removed records' texts go with them
      const gone = new Set(changeSet.deletes.map(String));
      for (const [key, entry] of next) {
        if (gone.has(entry.id)) {
          next.delete(key);
          changed = true;
        }
      }
    }
    if (next.size) {
      const ids = new Set(
        this.args.records.map((record) => String(this.args.getRecordId(record)))
      );
      for (const [key, entry] of next) {
        if (!ids.has(entry.id)) {
          next.delete(key);
          changed = true;
        }
      }
    }
    if (changeSet) {
      const byId = new Map(
        this.args.records.map((record) => [
          String(this.args.getRecordId(record)),
          record
        ])
      );
      for (const rejection of changeSet.rejected) {
        const id = String(rejection.recordId ?? rejection.tempId);
        next.set(cellKey(id, rejection.fieldId), {
          id,
          fieldId: rejection.fieldId,
          text: rejection.text,
          message: rejection.message,
          seenValue: valueOf(byId.get(id), rejection.fieldId)
        });
        changed = true;
      }
    }
    if (changed) this.rejections = next;
    if (!changeSet) return;
    this.recordHistory(changeSet);
    // the rows the owner's next `@records` gains or loses because of it
    if (changeSet.inserts.length || changeSet.deletes?.length) {
      this.pendingOwn.inserts += changeSet.inserts.length;
      for (const id of changeSet.deletes ?? []) {
        this.pendingOwn.deletes.add(String(id));
      }
    }
    for (const patch of changeSet.patches) {
      this.changedSinceRun.push({
        recordId: patch.recordId,
        fieldId: patch.fieldId
      });
    }
    for (const insert of changeSet.inserts) {
      for (const fieldId of Object.keys(insert.values)) {
        this.changedSinceRun.push({ recordId: insert.tempId, fieldId });
      }
    }
    this.args.onChange(changeSet);
    this.scheduleValidate();
  }

  /**
   * A user action's change set becomes an undo entry (not an undo or redo,
   * and not one with only rejections or new options); a new entry clears
   * the redo stack. A bulk resolve (`'resolve'`) joins the last entry, the
   * paste that asked for it, so one undo reverts both.
   */
  recordHistory(changeSet: ChangeSet): void {
    if (changeSet.source === 'undo' || changeSet.source === 'redo') return;
    if (
      !changeSet.patches.length &&
      !changeSet.inserts.length &&
      !changeSet.deletes?.length
    ) {
      return;
    }
    const entry = remapChangeSet(changeSet, this.remapped);
    const last = this.undoStack[this.undoStack.length - 1];
    if (entry.source === 'resolve' && last) {
      this.undoStack[this.undoStack.length - 1] = mergeChangeSets(last, entry);
      return;
    }
    this.undoStack.push(entry);
    if (this.undoStack.length > HISTORY_LIMIT) this.undoStack.shift();
    this.redoStack = [];
  }

  /* -------------------------------------------------------------------- */
  /* @validate (PACKAGE-DESIGN.md 9.4, layers 4-6)                         */
  /* -------------------------------------------------------------------- */

  scheduleValidate(): void {
    if (!this.args.validate) return;
    this.validateTimer = debounce(this, this.runValidate, VALIDATE_DEBOUNCE);
  }

  endValidateWaiter(): void {
    if (this.validateToken !== null) {
      validateWaiter.endAsync(this.validateToken);
      this.validateToken = null;
    }
  }

  runValidate(): void {
    this.validateTimer = null;
    const validate = this.args.validate;
    if (!validate || this.isDestroying || this.isDestroyed) return;
    // a newer run supersedes the previous one
    this.validateController?.abort();
    this.endValidateWaiter();
    const seq = ++this.validateSeq;
    const controller = new AbortController();
    this.validateController = controller;
    const records = this.args.records;
    const snapshot = new Map<string, unknown>(
      records.map((record) => [String(this.args.getRecordId(record)), record])
    );
    const changed = this.changedSinceRun;
    this.changedSinceRun = [];
    const isCurrent = () =>
      seq === this.validateSeq &&
      !controller.signal.aborted &&
      !this.isDestroying &&
      !this.isDestroyed;

    const result = validate({ records, changed, signal: controller.signal });
    if (!isPromise<CellErrors>(result)) {
      this.validation = { errors: result, records: snapshot };
      return;
    }
    const token = validateWaiter.beginAsync();
    this.validateToken = token;
    const end = () => {
      if (this.validateToken === token) this.endValidateWaiter();
    };
    result.then(
      (errors) => {
        if (isCurrent()) this.validation = { errors, records: snapshot };
        end();
      },
      (error: unknown) => {
        end();
        // an aborted or superseded run's failure (an AbortError) is expected
        if (isCurrent()) throw error;
      }
    );
  }

  <template>
    <div
      class="euiSheet
        {{this.themeClass}}
        {{if this.dragging 'euiSheet--dragging'}}"
      data-test-subj="euiSheet"
      ...attributes
      {{this.setupWrapper}}
      {{this.watchRecords @records}}
      {{this.registerSheetApi}}
      {{on "keydown" this.onKeyDown capture=true}}
      {{on "copy" this.onCopy capture=true}}
      {{on "paste" this.onPaste capture=true}}
      {{on "scroll" this.onScroll capture=true}}
      {{on "mousedown" this.onMouseDown capture=true}}
      {{on "focusin" this.onFocusIn}}
      {{on "focusout" this.onFocusOut}}
      {{on "mouseover" this.onMouseOver}}
      {{on "click" this.onClick}}
      {{on "dblclick" this.onDoubleClick}}
    >
      <EuiDataGrid
        aria-label={{this.ariaLabel}}
        @columns={{this.columns}}
        @columnVisibility={{this.columnVisibility}}
        @rowCount={{this.rowCount}}
        @renderCellValue={{SheetCell}}
        @cellContext={{this.cellContext}}
        @registerApi={{this.registerGridApi}}
        @toolbarVisibility={{false}}
        @height={{@height}}
      />
      {{#each this.editingList key="@identity" as |editing|}}
        <EditorFrame
          @rect={{editing.rect}}
          @layout={{editing.layout}}
          @placement={{editing.placement}}
          @onFocusOut={{this.onEditorFocusOut}}
        >
          {{#if editing.type.editor}}
            <editing.type.editor
              @value={{this.editorValue editing}}
              @field={{editing.field}}
              @record={{this.editorRecord editing}}
              @draft={{editing.draft}}
              @initialKey={{editing.initialKey}}
              @onDraftChange={{this.onDraftChange}}
              @onCommit={{this.onEditorCommit}}
              @onCancel={{this.cancel}}
              @messages={{this.messages}}
              @themeClass={{this.themeClass}}
            />
          {{/if}}
        </EditorFrame>
      {{/each}}
      {{! always rendered, so a screen reader announces an error when it appears }}
      <div class="euiSheet__cellErrorRegion" role="status">
        {{#if this.cellError}}
          <div
            class="euiSheet__cellError euiSheet__cellError--{{this.cellError.placement}}"
            data-test-subj="euiSheetCellError"
            style={{this.cellError.style}}
          >
            {{#each this.cellError.messages as |message|}}
              <div>{{message}}</div>
            {{/each}}
          </div>
        {{/if}}
      </div>
    </div>
  </template>
}
