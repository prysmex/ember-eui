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
import { cancel, debounce } from '@ember/runloop';
import { service } from '@ember/service';
import { buildWaiter } from '@ember/test-waiters';
import { modifier } from 'ember-modifier';

import EuiDataGrid from '@ember-eui/core/components/eui-data-grid';

import {
  cellKey,
  clearRange,
  commitText,
  commitValue,
  createMessages,
  isReadOnly,
  mergeErrors,
  parseTsv,
  pasteMatrix,
  rangeMatrix,
  resolveType,
  toRange,
  toTsv,
  validateCell,
  valueOf
} from '../core/index.ts';
import { builtInSheetFieldTypes } from '../field-types.ts';
import EditorFrame, {
  EDITOR_SURFACE_SELECTOR
} from '../-private/editor-frame.gts';
import SheetCell from '../-private/sheet-cell.gts';
import { ensureStyles } from '../-private/styles.ts';

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
  text: string;
  message: string;
  /** The record's value when the rejection was stored; another value means the owner changed it. */
  seenValue: unknown;
}

interface Editing {
  pos: Pos;
  recordId: RecordId;
  field: EuiSheetField;
  type: EuiSheetFieldType;
  rect: SheetEditorRect;
  layout: 'cell' | 'panel';
  placement: 'below' | 'above';
  initialKey: string | null;
  draft: string;
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

export default class EuiSheet<T extends object> extends Component<
  EuiSheetSignature<T>
> {
  @service('eui-i18n') declare euiI18n: EuiI18n;

  /** Selection corners; `head` is where DOM focus is. */
  @tracked anchor: Pos | null = null;
  @tracked head: Pos | null = null;
  @tracked editing: Editing | null = null;
  /** Texts a type could not read, by cellKey (PACKAGE-DESIGN.md 6, 7.5). */
  @tracked rejections: ReadonlyMap<string, Rejection> = new Map();
  /** Column order set through the grid; null: the order of `@fields`. */
  @tracked order: string[] | null = null;
  /** The last applied `@validate` result. */
  @tracked validation: Validation | null = null;

  /** Plain: the last text the editor reported, and whether it reported one. */
  draft = '';
  draftDirty = false;

  api: EuiDataGridRefProps | null = null;
  /** Last data cell seen by `focusin`. */
  domCursor: Pos | null = null;
  /** The next focus move extends the range. */
  extending = false;
  wrapper: HTMLElement | null = null;

  /** Stable object: the grid passes it to every cell renderer. */
  cellContext = { sheet: this as unknown as EuiSheet<object> };

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
    const record = this.args.records[row];
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

  registerApi = (api: EuiDataGridRefProps): void => {
    this.api = api;
  };

  setupWrapper = modifier((element: HTMLElement) => {
    this.wrapper = element;
    return () => {
      this.wrapper = null;
    };
  });

  /** Schedules a `@validate` run whenever `@records` is a new array (and on insert). */
  watchRecords = modifier((_element: HTMLElement, [records]: [unknown]) => {
    void records;
    this.scheduleValidate();
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

  /** The cell's position, read from its markup. */
  cursor(cell: HTMLElement): Pos {
    const row = Number(cell.dataset['gridcellVisibleRowIndex']);
    const col = Number(cell.dataset['gridcellColumnIndex']);
    // the sheet passes no sorting/pagination/row tree
    assert(
      'EuiSheet: data and visible row indexes differ',
      cell.dataset['gridcellRowIndex'] ===
        cell.dataset['gridcellVisibleRowIndex']
    );
    return { row, col };
  }

  touchedAt(pos: Pos): Touched {
    const record = this.args.records[pos.row];
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
    if (!cell) return;
    const pos = this.cursor(cell);
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

  /** Whether the cell at `pos` opens an editor. */
  canEdit(pos: Pos): boolean {
    const record = this.args.records[pos.row];
    const field = this.visibleFields[pos.col];
    if (record === undefined || !field) return false;
    return (
      !!this.typeOf(field).editor && !isReadOnly(this.context, field, record)
    );
  }

  @action
  onDoubleClick(event: MouseEvent): void {
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
    const record = this.args.records[pos.row];
    const field = this.visibleFields[pos.col];
    if (record === undefined || !field) return;
    const ctx = this.context;
    const type = this.typeOf(field);
    const readOnly = isReadOnly(ctx, field, record);
    const { key } = event;
    const plain = !event.ctrlKey && !event.metaKey && !event.altKey;

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
    const matrix = parseTsv(data.getData('text/plain'));
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
  }

  /* -------------------------------------------------------------------- */
  /* Edit lifecycle                                                        */
  /* -------------------------------------------------------------------- */

  startEdit(pos: Pos, cell: HTMLElement, initialKey: string | null): void {
    const wrapper = this.wrapper;
    const record = this.args.records[pos.row];
    const field = this.visibleFields[pos.col];
    if (!wrapper || record === undefined || !field) return;
    const type = this.typeOf(field);
    const recordId = this.args.getRecordId(record);
    const box = cell.getBoundingClientRect();
    const origin = wrapper.getBoundingClientRect();
    // client rects are in screen px; an ancestor transform (the test
    // container is scaled to 50%) makes them differ from the CSS px the
    // editor is positioned in
    const scale = wrapper.offsetWidth ? origin.width / wrapper.offsetWidth : 1;
    const rect: SheetEditorRect = {
      top: (box.top - origin.top) / scale,
      left: (box.left - origin.left) / scale,
      width: box.width / scale,
      height: box.height / scale,
      wrapperHeight: wrapper.offsetHeight
    };
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
    this.editing = {
      pos,
      recordId,
      field,
      type,
      rect,
      layout,
      placement,
      initialKey,
      draft
    };
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

  editorRecord = (editing: Editing): T | undefined =>
    this.args.records[editing.pos.row];

  editorValue = (editing: Editing): unknown =>
    valueOf(this.args.records[editing.pos.row], editing.field.id);

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
    const { pos } = editing;
    this.editing = null;
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
      // synchronous is safe: the target row already exists
      this.api?.setFocusedCell({ rowIndex, colIndex });
    }
  }

  cancel = (): void => {
    const editing = this.editing;
    if (!editing) return;
    this.editing = null;
    this.api?.setFocusedCell({
      rowIndex: editing.pos.row,
      colIndex: editing.pos.col
    });
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
          text: rejection.text,
          message: rejection.message,
          seenValue: valueOf(byId.get(id), rejection.fieldId)
        });
        changed = true;
      }
    }
    if (changed) this.rejections = next;
    if (!changeSet) return;
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
      class="euiSheet"
      data-test-subj="euiSheet"
      ...attributes
      {{this.setupWrapper}}
      {{this.watchRecords @records}}
      {{on "keydown" this.onKeyDown capture=true}}
      {{on "copy" this.onCopy capture=true}}
      {{on "paste" this.onPaste capture=true}}
      {{on "scroll" this.onScroll capture=true}}
      {{on "mousedown" this.onMouseDown capture=true}}
      {{on "focusin" this.onFocusIn}}
      {{on "dblclick" this.onDoubleClick}}
    >
      <EuiDataGrid
        aria-label={{this.ariaLabel}}
        @columns={{this.columns}}
        @columnVisibility={{this.columnVisibility}}
        @rowCount={{@records.length}}
        @renderCellValue={{SheetCell}}
        @cellContext={{this.cellContext}}
        @registerApi={{this.registerApi}}
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
            />
          {{/if}}
        </EditorFrame>
      {{/each}}
    </div>
  </template>
}
