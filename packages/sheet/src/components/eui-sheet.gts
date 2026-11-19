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
import { assert, warn } from '@ember/debug';
import { isDestroyed, isDestroying } from '@ember/destroyable';
import { cancel, debounce, later, next, run, schedule } from '@ember/runloop';
import { service } from '@ember/service';
import { htmlSafe } from '@ember/template';
import { buildWaiter } from '@ember/test-waiters';
import { modifier } from 'ember-modifier';

import EuiDataGrid from '@ember-eui/core/components/eui-data-grid';
import EuiIconTip from '@ember-eui/core/components/eui-icon-tip';
import EuiProgress from '@ember-eui/core/components/eui-progress';
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
  deleteRecords,
  duplicateRecords,
  edgeTarget,
  fillDown,
  fillRange,
  fillRight,
  insertRecords,
  isReadOnly,
  mergeChangeSets,
  mergeErrors,
  parseTsv,
  pasteMatrix,
  planCommit,
  planPaste,
  rangeMatrix,
  redoChangeSet,
  resolveCells,
  resolveType,
  safeLink,
  sameFieldValue,
  tileMatrix,
  toRange,
  toTsv,
  undoChangeSet,
  validateCell,
  valueOf
} from '../core/index.ts';
import { builtInSheetFieldTypes } from '../field-types.ts';
import AutoScroll from '../-private/auto-scroll.ts';
import FillHandle from '../-private/fill-handle.gts';
import ImeCatcher from '../-private/ime-catcher.gts';
import EditorFrame, {
  EDITOR_SURFACE_SELECTOR
} from '../-private/editor-frame.gts';
import {
  composeIdMaps,
  remapChangeSet,
  remapId,
  toIdMap
} from '../-private/remap.ts';
import {
  clearRejections,
  remapRejections,
  restoreRejections
} from '../-private/rejections.ts';
import { RecordFlyout, RecordModal } from '../-private/record-shells.gts';
import RowMenu from '../-private/row-menu.gts';
import {
  RowNumberCell,
  RowNumberHeader
} from '../-private/row-number-cell.gts';
import SheetCell from '../-private/sheet-cell.gts';
import SheetFooterCell, {
  SheetControlFooterCell
} from '../-private/footer-cell.gts';
import { ensureStyles } from '../-private/styles.ts';
import { sheetThemeVars } from '../-private/theme.ts';

import type {
  CellErrors,
  ChangeSet,
  EuiSheetField,
  PendingCell,
  Pos,
  Range,
  RecordId,
  ResolvePlan,
  ResolveResult,
  SheetAttachment,
  SheetContext,
  RecordInsert,
  SheetMessages
} from '../core/index.ts';
import type { Rejection } from '../-private/rejections.ts';
import type { ScrollBounds } from '../-private/auto-scroll.ts';
import type { RowMenuItem } from '../-private/row-menu.gts';
import type {
  EuiSheetFieldType,
  EuiSheetSignature,
  SheetApi,
  SheetBlockApi,
  SheetEditorRect,
  SheetEditorResult,
  SheetRowHeight,
  SheetSort
} from '../types.ts';
import type EuiI18n from '@ember-eui/core/services/eui-i18n';
import type {
  EuiDataGridColumn,
  EuiDataGridColumnActions,
  EuiDataGridColumnVisibility,
  EuiDataGridControlColumn,
  EuiDataGridRefProps,
  EuiDataGridRowHeightsOptions,
  EuiDataGridSorting,
  EuiDataGridSortingColumn,
  EuiDataGridStyle,
  EuiDataGridVirtualizationOptions
} from '@ember-eui/core/utils/data-grid/types';
import type Owner from '@ember/owner';
import type { ComponentLike } from '@glint/template';

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
  /** Waiting for `@onResolve` or an upload: no errors shown until it settles. */
  pending: boolean;
  /** `type.link(value)` when its scheme is one the sheet opens. */
  link: string | undefined;
  /** Files dragged over the cell will be dropped on it. */
  dropTarget: boolean;
}

/**
 * A cell waiting for `@onResolve` (text: what was typed or pasted, shown
 * meanwhile) or for an upload (text: null, the value stays shown).
 */
interface PendingEntry {
  text: string | null;
  /** The call it waits for. */
  token: object;
  /** The cell to resolve; none for an upload. */
  cell?: PendingCell;
}

/** One `@onResolve` call or upload in flight. */
interface PendingCall {
  kind: 'resolve' | 'upload';
  controller: AbortController;
  waiter: unknown;
  /** The history entry of the paste or edit that asked for it: the resolve is merged into it. */
  entry: HistoryEntry | null;
}

/**
 * One undo entry: the change set a user action emitted, and the rejections
 * it stored (with the value each cell had then), which undo clears and
 * redo puts back.
 */
interface HistoryEntry {
  changeSet: ChangeSet;
  rejections: Rejection[];
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
  layout: 'cell' | 'panel' | 'expand';
  @tracked placement: 'below' | 'above';
  initialKey: string | null;
  draft: string;
  /** The editor's `@onUpload` (attachment fields with `upload`). */
  onUpload?: (files: File[]) => Promise<void>;

  constructor(init: {
    pos: Pos;
    recordId: RecordId;
    field: EuiSheetField;
    type: EuiSheetFieldType;
    rect: SheetEditorRect;
    layout: 'cell' | 'panel' | 'expand';
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

/** Keys that extend the range with Shift (V02-DESIGN.md 8.4). */
const RANGE_KEYS = new Set([...ARROWS, 'Home', 'End', 'PageUp', 'PageDown']);

const ARROW_DIRECTIONS = {
  ArrowUp: 'up',
  ArrowDown: 'down',
  ArrowLeft: 'left',
  ArrowRight: 'right'
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

/** A long press on a touch screen opens the row menu (8.5). */
const LONG_PRESS_MS = 500;
/** A touch that moves farther than this is a scroll, not a long press. */
const LONG_PRESS_SLOP = 10;
/** `@editIn="auto"`: the expanded record edits on a coarse pointer and a sheet narrower than this. */
const NARROW_SHEET = 600;

/** Whether the primary pointer is coarse (a touch screen). */
function coarsePointer(): boolean {
  return (
    typeof window !== 'undefined' &&
    typeof window.matchMedia === 'function' &&
    window.matchMedia('(pointer: coarse)').matches
  );
}

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

/** Id of the row-number control column. */
const ROW_COLUMN_ID = 'euiSheetRow';
/** Its width without `@rowLabel`. */
const ROW_COLUMN_WIDTH = 64;

/**
 * The frozen field (V02-DESIGN.md 9): above this many visible fields the
 * sheet stops freezing (it renders every column of the rendered rows while
 * a field is frozen).
 */
const FROZEN_MAX_COLUMNS = 50;
/** A frozen field's width without `@fieldWidths` or `field.width`. */
const FROZEN_DEFAULT_WIDTH = 200;

/** `@rowHeight` as the grid's row heights (6.4). */
const ROW_HEIGHTS: Record<SheetRowHeight, EuiDataGridRowHeightsOptions> = {
  short: {},
  medium: { defaultHeight: { lineCount: 2 } },
  tall: { defaultHeight: { lineCount: 4 } },
  extraTall: { defaultHeight: { lineCount: 6 } }
};

/** Where the frozen columns are: each one's `left`, by grid column index, and their right edge. */
interface FrozenLayout {
  lefts: Map<number, number>;
  /** The grid column index of the last frozen column. */
  last: number;
  /** The frozen columns' right edge, from the grid's left edge, in CSS px. */
  right: number;
}

/** The header of a field with a description: its label and an info tip (6.3). */
function headerDisplay(label: string, description: string): ComponentLike {
  return <template>
    <span class="euiSheet__headerTitle">{{label}}</span>
    <span
      class="euiSheet__headerTip"
      data-test-subj="euiSheetFieldDescription"
    ><EuiIconTip
        @content={{description}}
        @type="iInCircle"
        @size="s"
        @color="subdued"
      /></span>
  </template>;
}

/** What a range covers (V02-DESIGN.md 5.4). */
type RangeKind = 'cells' | 'rows' | 'columns';

/** The open row menu: the row it was opened on and where, in the wrapper. */
interface MenuState {
  row: number;
  /** The data column it was opened on; null on a row number. */
  col: number | null;
  top: number;
  left: number;
  /** The records it acts on, fixed when it opened. */
  records: unknown[];
}

/** Where the expanded record was opened from, to focus it again on close. */
interface ExpandedFrom {
  recordId: RecordId;
  /** null: the row-number cell. */
  fieldId: string | null;
}

/** Menu items whose action moves focus itself. */
const MENU_ITEMS_THAT_MOVE_FOCUS = new Set([
  'insertAbove',
  'insertBelow',
  'duplicate',
  'expand',
  'delete'
]);

/** Shift+F10 or the ContextMenu key: the row menu. */
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

/**
 * Writes text to the clipboard: `navigator.clipboard.writeText`, else (or
 * when it rejects) a hidden textarea and `execCommand('copy')`, appended to
 * the body, outside the grid (its document copy handlers).
 */
function writeClipboard(text: string): void {
  const fallback = () => {
    const area = document.createElement('textarea');
    area.value = text;
    area.setAttribute('readonly', '');
    area.style.position = 'fixed';
    area.style.opacity = '0';
    document.body.appendChild(area);
    area.select();
    try {
      document.execCommand('copy');
    } finally {
      area.remove();
    }
  };
  const clipboard = navigator.clipboard as Clipboard | undefined;
  if (clipboard?.writeText) {
    clipboard.writeText(text).catch(fallback);
  } else {
    fallback();
  }
}

/** Undo entries kept per sheet. */
const HISTORY_LIMIT = 100;

/** Debounce of `@validate` runs, in ms. */
const VALIDATE_DEBOUNCE = 50;

/** One counter per page: `localRecords` uses the tempId as the record id, so it is never reused. */
let tempIdCounter = 0;
const nextTempId = (): string => `new-${++tempIdCounter}`;

const validateWaiter = buildWaiter('@ember-eui/sheet:validate');
const resolveWaiter = buildWaiter('@ember-eui/sheet:resolve');

type UploadField = EuiSheetField & {
  upload?: (
    files: File[],
    context: { record: unknown; field: EuiSheetField; signal: AbortSignal }
  ) => Promise<SheetAttachment[]>;
  maxFiles?: number;
};

/** The field's `upload`, when it has one (attachment fields). */
function uploadOf(field: EuiSheetField): UploadField['upload'] {
  const upload = (field as UploadField).upload;
  return typeof upload === 'function' ? upload : undefined;
}

/** A drag that carries files. */
function hasFiles(event: DragEvent): boolean {
  return Array.from(event.dataTransfer?.types ?? []).includes('Files');
}

const EMPTY_CHANGE_SET: ChangeSet = {
  source: 'undo',
  patches: [],
  inserts: [],
  rejected: [],
  newOptions: []
};

function isModal(shell: string): boolean {
  return shell === 'modal';
}

function sameRange(a: Range, b: Range): boolean {
  return (
    a.top === b.top &&
    a.left === b.left &&
    a.bottom === b.bottom &&
    a.right === b.right
  );
}

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
  /** Field order without `@onFieldOrderChange`; null: the order of `@fields`. */
  @tracked localOrder: string[] | null = null;
  /**
   * Hidden or shown without `@onHiddenFieldsChange`, by field id: `true`
   * hides a field of `@fields`, `false` shows one of `@hiddenFields`.
   */
  @tracked localHidden: ReadonlyMap<string, boolean> = new Map();
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
  /** The row height without `@onRowHeightChange`; null: `@rowHeight`. */
  @tracked localRowHeight: SheetRowHeight | null = null;
  /** The grid is scrolled horizontally (the frozen edge's shadow). */
  @tracked scrolledX = false;
  /** The last applied `@validate` result. */
  @tracked validation: Validation | null = null;
  /** A drag over other cells is selecting a range (no text selection meanwhile). */
  @tracked dragging = false;
  /** What the range covers: cells, whole rows (row numbers) or whole columns (headers). */
  @tracked rangeKind: RangeKind = 'cells';
  /** Checked rows without `@onCheckedChange`: record ids as strings. */
  @tracked localChecked: ReadonlySet<string> = new Set();
  /** The expanded record without `@onExpandedRecordChange`. */
  @tracked localExpandedId: RecordId | null = null;
  /** The open row menu. */
  @tracked menu: MenuState | null = null;
  /** Cells waiting for `@onResolve` or an upload, by cellKey. */
  @tracked pendingCells: ReadonlyMap<string, PendingEntry> = new Map();
  /** The attachment cell files are dragged over. */
  @tracked dropPos: Pos | null = null;
  /** The `@onResolve` calls and uploads in flight, by token. */
  pendingCalls = new Map<object, PendingCall>();
  /**
   * An editor is open in the expanded record's form: the shell's focus
   * trap is paused, so focus can reach a surface the editor renders
   * outside the shell (a wormholed calendar; N3).
   */
  @tracked formEditorOpen = false;

  /* Batch 6: fill handle, auto-scroll, touch, composition (V02-DESIGN.md 8.4-8.6) */
  /** A fill drag: the range it fills from, and the range it fills now (the preview). */
  fillSource: Range | null = null;
  @tracked fillTarget: Range | null = null;
  /** Changes when the grid scrolls or its columns change: the fill handle measures again. */
  @tracked layoutTick = 0;
  /** The last pointer position of a drag, in viewport px. */
  dragPointer: { x: number; y: number } | null = null;
  /** The drags' auto-scroll loop. */
  autoScroll = new AutoScroll({
    bounds: () => this.scrollBounds(),
    scrollBy: (dx, dy) => this.scrollGridBy(dx, dy),
    onFrame: (x, y) => this.dragTo(x, y)
  });
  /** `pointerType` of the last press: touch presses do not drag a range. */
  lastPointerType = 'mouse';
  /** A touch long press in progress (its timer and where it started). */
  longPress: {
    timer: ReturnType<typeof later>;
    x: number;
    y: number;
    target: Element;
  } | null = null;
  /** A long press opened the menu: the click (and contextmenu) that follow are its own. */
  longPressOpened = false;
  /** The composition catcher (`ime-catcher.gts`) and the cell it is over. */
  imeInput: HTMLInputElement | null = null;
  imePos: Pos | null = null;
  imeComposing = false;
  @tracked imeActive = false;
  /** `@editIn` opened the expanded record to edit this field (8.5). */
  pendingFormEdit: { recordId: RecordId; fieldId: string } | null = null;

  /** The row whose checkbox was toggled last (Shift+click checks the rows between). */
  lastToggledRow: number | null = null;
  /** Where the expanded record was opened from. */
  expandedFrom: ExpandedFrom | null = null;
  /** Last row-number cell seen by `focusin`. */
  rowCursor: number | null = null;
  /** The next focus on a cell keeps the range (a press set it, or a right-click inside it). */
  keepRangeOnFocus = false;
  /** What a drag selects: cells, or rows (a press on a row number). */
  dragKind: 'cells' | 'rows' = 'cells';

  /** Plain: the last text (or value) the editor reported, and whether it reported one. */
  draft = '';
  draftDirty = false;
  draftValue: unknown = undefined;
  draftKind: 'text' | 'value' = 'text';

  /** The grid's API (not the sheet's: that is `sheetApi`). */
  gridApi: EuiDataGridRefProps | null = null;
  /** Last data cell seen by `focusin`. */
  domCursor: Pos | null = null;
  /** The next focus move extends the range. */
  extending = false;
  wrapper: HTMLElement | null = null;

  /* Undo and redo: the change sets this sheet emitted for user actions */
  undoStack: HistoryEntry[] = [];
  redoStack: HistoryEntry[] = [];

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
    clearHistory: () => this.clearHistory(),
    expandRecord: (recordId) => {
      if (recordId === null) this.closeExpanded();
      else this.expandRecord(recordId, null);
    },
    insertRecord: (options = {}) => this.insertFromApi(options),
    deleteRecords: (ids) => this.deleteRecordIds(ids, false)
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
    this.stopFillDrag();
    this.autoScroll.stop();
    this.cancelLongPress();
    document.removeEventListener('mousedown', this.onDocumentMouseDown, true);
    for (const token of [...this.pendingCalls.keys()]) this.endCall(token);
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

  /* -------------------------------------------------------------------- */
  /* Fields: visible, hidden, order (V02-DESIGN.md 3.5, 6.4)               */
  /* -------------------------------------------------------------------- */

  /**
   * The visible fields, in display order: `@fields` as given, with the
   * sheet's own hidden set and order applied for the parts the owner has
   * no handler for.
   */
  @cached
  get visibleFields(): EuiSheetField<T>[] {
    let fields = this.args.fields;
    if (!this.args.onHiddenFieldsChange && this.localHidden.size) {
      const local = this.localHidden;
      fields = [
        ...fields.filter((field) => local.get(field.id) !== true),
        ...(this.args.hiddenFields ?? []).filter(
          (field) => local.get(field.id) === false
        )
      ];
    }
    const order = this.args.onFieldOrderChange ? null : this.localOrder;
    if (order) {
      const rank = new Map(order.map((id, i) => [id, i]));
      fields = fields
        .map((field, i) => ({ field, i }))
        .sort(
          (a, b) =>
            (rank.get(a.field.id) ?? order.length + a.i) -
            (rank.get(b.field.id) ?? order.length + b.i)
        )
        .map(({ field }) => field);
    }
    return fields;
  }

  @cached
  get visibleFieldIds(): string[] {
    return this.visibleFields.map((field) => field.id);
  }

  /** The fields that are not shown: `@hiddenFields`, or the sheet's own hidden ones. */
  @cached
  get hiddenFields(): EuiSheetField<T>[] {
    const hidden = this.args.hiddenFields ?? [];
    if (this.args.onHiddenFieldsChange || !this.localHidden.size) return hidden;
    const visible = new Set(this.visibleFieldIds);
    return [...this.args.fields, ...hidden].filter(
      (field) => !visible.has(field.id)
    );
  }

  /** Whether the header menu and `hideField` may hide this field: never the first one. */
  canHide(fieldId: string): boolean {
    const index = this.visibleFieldIds.indexOf(fieldId);
    return index > 0 && this.visibleFields[index]!.hideable !== false;
  }

  /** "Hide": `@onHiddenFieldsChange`, or the sheet's own hidden set (C6). */
  hideField = (fieldId: string): void => {
    if (!this.canHide(fieldId)) return;
    this.hideFields([fieldId]);
  };

  hideFields(fieldIds: string[]): void {
    const handler = this.args.onHiddenFieldsChange;
    if (handler) {
      const ids = this.hiddenFields.map((field) => field.id);
      this.expectUpdate('hiddenFields');
      handler([...ids, ...fieldIds.filter((id) => !ids.includes(id))]);
      return;
    }
    const next = new Map(this.localHidden);
    for (const id of fieldIds) {
      if (this.args.fields.some((field) => field.id === id)) next.set(id, true);
      else next.delete(id);
    }
    this.localHidden = next;
  }

  /** A block's `showField`: `@onHiddenFieldsChange`, or the sheet's own hidden set. */
  showField = (fieldId: string): void => {
    if (!this.hiddenFields.some((field) => field.id === fieldId)) return;
    const handler = this.args.onHiddenFieldsChange;
    if (handler) {
      this.expectUpdate('hiddenFields');
      handler(
        this.hiddenFields
          .map((field) => field.id)
          .filter((id) => id !== fieldId)
      );
      return;
    }
    const next = new Map(this.localHidden);
    if (this.args.fields.some((field) => field.id === fieldId)) {
      next.delete(fieldId);
    } else {
      next.set(fieldId, false);
    }
    this.localHidden = next;
  };

  /** "Move left/right": `@onFieldOrderChange`, or the sheet's own order. */
  setFieldOrder(fieldIds: string[]): void {
    const handler = this.args.onFieldOrderChange;
    if (handler) {
      this.expectUpdate('fields');
      handler(fieldIds);
      return;
    }
    this.localOrder = fieldIds;
  }

  @cached
  get columnVisibility(): EuiDataGridColumnVisibility {
    return {
      visibleColumns: this.visibleFieldIds,
      setVisibleColumns: this.setVisibleColumns
    };
  }

  /**
   * The grid's "Hide column" and "Move left/right" call this with the new
   * visible ids: an id missing is a hide intent, another order an order
   * intent (6.3).
   */
  setVisibleColumns = (ids: string[]): void => {
    const current = this.visibleFieldIds;
    const removed = current.filter((id) => !ids.includes(id));
    if (removed.length) {
      const hideable = removed.filter((id) => this.canHide(id));
      if (hideable.length) this.hideFields(hideable);
      return;
    }
    const kept = ids.filter((id) => current.includes(id));
    if (!sameIds(kept, current)) this.setFieldOrder(kept);
  };

  /* Widths (6.4) */

  /** A field's width as given: `@fieldWidths`, else `field.width`. */
  givenWidth(field: EuiSheetField<T>): number | undefined {
    return this.args.fieldWidths?.[field.id] ?? field.width;
  }

  /** The width the grid shows a frozen field at (frozen fields always have one). */
  frozenWidth(field: EuiSheetField<T>): number {
    const resized = this.resizedWidths;
    const kept =
      resized && resized.columns === this.columns
        ? resized.widths[field.id]
        : undefined;
    return kept ?? this.givenWidth(field) ?? FROZEN_DEFAULT_WIDTH;
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
    // the fill handle measures again
    this.layoutTick++;
    const handler = this.args.onFieldWidthChange;
    if (!handler) return;
    this.expectUpdate('fieldWidths');
    handler(columnId, width);
  };

  /* Sort (6.3): drawn and emitted, never applied */

  @cached
  get sorting(): EuiDataGridSorting | undefined {
    if (!this.args.onSortChange) return undefined;
    return {
      columns: (this.args.sort ?? []).map(({ field, direction }) => ({
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
    this.args.onSortChange?.(sort);
  };

  /* Row height (6.4) */

  get rowHeight(): SheetRowHeight {
    const given = this.args.rowHeight ?? 'short';
    if (this.args.onRowHeightChange) return given;
    return this.localRowHeight ?? given;
  }

  setRowHeight = (rowHeight: SheetRowHeight): void => {
    const handler = this.args.onRowHeightChange;
    if (handler) {
      if (rowHeight !== this.rowHeight) this.expectUpdate('rowHeight');
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
   * widths, the frozen count and which handlers exist: not on `@sort` or
   * `@highlight`.
   */
  @cached
  get columns(): EuiDataGridColumn[] {
    const frozen = this.frozenCount;
    const sortable = !!this.args.onSortChange;
    const filter = this.args.onFilterByField;
    const filterLabel = this.messages.filterByField();
    return this.visibleFields.map((field, index) => {
      const type = this.typeOf(field);
      const canSort = sortable && field.sortable !== false;
      const actions: EuiDataGridColumnActions = {
        showHide: index > 0 && field.hideable !== false,
        // the first field stays first (6.3)
        showMoveLeft: index > 1,
        showMoveRight: index > 0,
        showSortAsc: canSort,
        showSortDesc: canSort
      };
      if (filter) {
        actions.additional = [
          {
            label: filterLabel,
            iconType: 'filter',
            color: 'text',
            onClick: () => this.args.onFilterByField?.(field.id),
            'data-test-subj': `euiSheetFilterByField-${field.id}`
          }
        ];
      }
      const width =
        index < frozen
          ? (this.givenWidth(field) ?? FROZEN_DEFAULT_WIDTH)
          : this.givenWidth(field);
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
          className: this.frozenHeaderClass(index + this.colOffset)
        };
      }
      return column;
    });
  }

  /* The frozen field (V02-DESIGN.md 6.7, 9.2) */

  /** How many leading fields are frozen: `@frozenFields` (default 1), 0 above FROZEN_MAX_COLUMNS fields. */
  @cached
  get frozenCount(): number {
    const count = this.visibleFields.length;
    const wanted = this.args.frozenFields ?? 1;
    if (wanted <= 0 || count === 0) return 0;
    if (count > FROZEN_MAX_COLUMNS) {
      warn(
        `EuiSheet: ${count} visible fields: frozen fields are off above ${FROZEN_MAX_COLUMNS} (every column of the rendered rows would be rendered).`,
        false,
        { id: 'ember-eui.sheet.frozen-fields-off' }
      );
      return 0;
    }
    return Math.min(wanted, count);
  }

  @cached
  get frozenLayout(): FrozenLayout | null {
    const frozen = this.frozenCount;
    if (!frozen) return null;
    const lefts = new Map<number, number>();
    let left = 0;
    if (this.colOffset) {
      lefts.set(0, 0);
      left += this.rowColumnWidth;
    }
    const fields = this.visibleFields;
    for (let i = 0; i < frozen; i++) {
      lefts.set(i + this.colOffset, left);
      left += this.frozenWidth(fields[i]!);
    }
    return { lefts, last: frozen - 1 + this.colOffset, right: left };
  }

  frozenHeaderClass(colIndex: number): string {
    const last = this.frozenCount - 1 + this.colOffset;
    return `euiSheet__frozenHeader euiSheet__frozenHeader--${colIndex}${colIndex === last ? ' euiSheet__frozenEdge' : ''}`;
  }

  /**
   * The style and class of a frozen body cell (`footer`: a footer cell),
   * or null: sticky at its `left`, floated so two sit side by side in the
   * absolute row; footer cells are flex items, so no float (9.2).
   */
  frozenCellProps(
    colIndex: number,
    footer = false
  ): { className: string; style: Record<string, string | number> } | null {
    const layout = this.frozenLayout;
    const left = layout?.lefts.get(colIndex);
    if (!layout || left === undefined) return null;
    const style: Record<string, string | number> = footer
      ? { position: 'sticky', left, zIndex: 2 }
      : { position: 'sticky', float: 'left', left, zIndex: 2 };
    const className =
      colIndex === layout.last
        ? 'euiSheet__cell--frozen euiSheet__frozenEdge'
        : 'euiSheet__cell--frozen';
    return { className, style };
  }

  /** The frozen header cells' `left`s, as custom properties on the grid's container. */
  @cached
  get frozenStyle(): ReturnType<typeof htmlSafe> | undefined {
    const layout = this.frozenLayout;
    if (!layout) return undefined;
    return htmlSafe(
      [...layout.lefts]
        .map(([index, left]) => `--euiSheetFrozenLeft-${index}:${left}px`)
        .join(';')
    );
  }

  /** While a field is frozen every column of a rendered row is rendered (9.1): a frozen cell must not unmount. */
  @cached
  get virtualizationOptions(): EuiDataGridVirtualizationOptions | undefined {
    if (!this.frozenCount) return undefined;
    return {
      overscanColumnCount: this.visibleFields.length + this.colOffset
    };
  }

  /**
   * The grid scrolls a focused cell into view by its own left edge, which
   * may leave it under the frozen columns (ArrowLeft). After the focus, the
   * sheet scrolls it clear (9.1).
   */
  clearFrozenOverlap(pos: Pos): void {
    const layout = this.frozenLayout;
    if (!layout || pos.col < this.frozenCount) return;
    const outer = this.scrollElement();
    const cell = this.cellElement(pos);
    if (!outer || !cell) return;
    const box = outer.getBoundingClientRect();
    const scale = outer.offsetWidth ? box.width / outer.offsetWidth : 1;
    const cellLeft =
      (cell.getBoundingClientRect().left - box.left) / scale - outer.clientLeft;
    const overlap = layout.right - cellLeft;
    if (overlap > 0.5) {
      this.gridApi?.scrollTo?.({
        scrollLeft: Math.max(0, outer.scrollLeft - overlap)
      });
    }
  }

  /**
   * The grid's horizontal scroll before a focus move made by a key, a press
   * or the sheet itself; null otherwise. A frozen cell is always in view,
   * but the grid scrolls to its column's left edge when it gets focus
   * (ArrowLeft into the first field, a click on it while scrolled): the
   * sheet puts the scroll back once (`keepFrozenScroll`).
   */
  scrollLeftBeforeFocus: number | null = null;
  /** A press is in progress: the grid scrolls the pressed cell into view on pointerup, so the click restores. */
  pressing = false;

  noteScrollLeft(): void {
    if (!this.frozenCount) return;
    this.scrollLeftBeforeFocus = this.scrollElement()?.scrollLeft ?? null;
  }

  keepFrozenScroll(): void {
    const before = this.scrollLeftBeforeFocus;
    this.scrollLeftBeforeFocus = null;
    if (before === null || !this.frozenCount) return;
    const outer = this.scrollElement();
    if (outer && Math.abs(outer.scrollLeft - before) > 0.5) {
      this.gridApi?.scrollTo?.({ scrollLeft: before });
    }
  }

  /** Focus reached a frozen cell (`gridCol`: the grid's column index). */
  onFrozenFocus(gridCol: number): void {
    if (!this.frozenLayout?.lefts.has(gridCol)) return;
    // a press restores on its click, after the grid's pointerup scroll
    if (this.pressing) return;
    afterRender(this, () => this.keepFrozenScroll());
  }

  /** The grid's scroll element. */
  scrollElement(): HTMLElement | null {
    return (
      this.wrapper?.querySelector<HTMLElement>('.euiDataGrid__virtualized') ??
      null
    );
  }

  /**
   * The grid body's visible area, in viewport px: inside the scroll bars,
   * below the sticky header and above the footer; `frozenRight` is where
   * the frozen columns end.
   */
  scrollBounds(): ScrollBounds | null {
    const outer = this.scrollElement();
    if (!outer) return null;
    const box = outer.getBoundingClientRect();
    const scale = outer.offsetWidth ? box.width / outer.offsetWidth : 1;
    const header = outer.querySelector<HTMLElement>(
      '[data-test-subj=dataGridHeader]'
    );
    const footer = outer.querySelector<HTMLElement>('.euiDataGridFooter');
    const left = box.left + outer.clientLeft * scale;
    const top = box.top + outer.clientTop * scale;
    const layout = this.frozenLayout;
    return {
      top: top + (header?.offsetHeight ?? 0) * scale,
      bottom: top + (outer.clientHeight - (footer?.offsetHeight ?? 0)) * scale,
      left,
      right: left + outer.clientWidth * scale,
      frozenRight: layout ? left + layout.right * scale : undefined
    };
  }

  /**
   * Whether a cell is rendered and in view: inside the body's visible area
   * and, unless it is frozen, not under the frozen columns (1 px slack).
   */
  cellInView(pos: Pos): HTMLElement | null {
    const cell = this.cellElement(pos);
    const bounds = cell && this.scrollBounds();
    if (!cell || !bounds) return null;
    const box = cell.getBoundingClientRect();
    const left =
      bounds.frozenRight !== undefined && pos.col >= this.frozenCount
        ? bounds.frozenRight
        : bounds.left;
    const inside =
      box.top >= bounds.top - 1 &&
      box.bottom <= bounds.bottom + 1 &&
      box.left >= left - 1 &&
      box.right <= bounds.right + 1;
    return inside ? cell : null;
  }

  /** Scrolls the grid by `dx`, `dy` px; whether it moved. */
  scrollGridBy(dx: number, dy: number): boolean {
    const outer = this.scrollElement();
    if (!outer || !this.gridApi?.scrollTo) return false;
    const { scrollLeft, scrollTop } = outer;
    run(() => {
      this.gridApi?.scrollTo?.({
        scrollLeft: Math.max(0, scrollLeft + dx),
        scrollTop: Math.max(0, scrollTop + dy)
      });
    });
    return (
      Math.abs(outer.scrollLeft - scrollLeft) > 0.5 ||
      Math.abs(outer.scrollTop - scrollTop) > 0.5
    );
  }

  /* Blocks (3.6) */

  @cached
  get blockApi(): SheetBlockApi<T> {
    return {
      api: this.sheetApi,
      fields: this.visibleFields,
      hiddenFields: this.hiddenFields,
      sort: this.args.sort ?? [],
      rowHeight: this.rowHeight,
      checkedRecords: this.checkedRecords,
      hideField: this.hideField,
      showField: this.showField,
      setRowHeight: this.setRowHeight,
      setSort: this.setSort
    };
  }

  get hasSummary(): boolean {
    return this.args.summary !== undefined;
  }

  /* A handler was called and its argument did not change (6.11) */

  warnedUnchanged = new Set<string>();

  /**
   * In development, warns once per argument when a presentation handler
   * was called and the argument is the same after the next render: the
   * owner passed the handler but does not update the argument, so nothing
   * changes on screen.
   */
  expectUpdate(
    name: 'fields' | 'hiddenFields' | 'fieldWidths' | 'rowHeight'
  ): void {
    if (this.warnedUnchanged.has(name)) return;
    const read = (): unknown =>
      name === 'hiddenFields'
        ? [this.args.fields, this.args.hiddenFields]
        : this.args[name];
    const before = read();
    next(() => {
      if (isDestroying(this) || isDestroyed(this)) return;
      const after = read();
      const same = Array.isArray(before)
        ? before.every((value, i) => value === (after as unknown[])[i])
        : before === after;
      if (!same || this.warnedUnchanged.has(name)) return;
      this.warnedUnchanged.add(name);
      warn(
        `EuiSheet: a handler for @${name} was called, but @${name} did not change. With the handler the sheet shows exactly the argument: update it.`,
        false,
        { id: 'ember-eui.sheet.controlled-argument' }
      );
    });
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

  get showRowNumbers(): boolean {
    return this.args.rowNumbers !== false;
  }

  get canInsert(): boolean {
    return this.args.canInsert ?? !this.args.readOnly;
  }

  get canDelete(): boolean {
    return this.args.canDelete ?? !this.args.readOnly;
  }

  /**
   * Leading control columns of the grid (V02-DESIGN.md 3.2): positions
   * (`anchor`, `head`, `Range`) use data columns, the grid's column index
   * is the data column plus this. One with row numbers.
   */
  get colOffset(): number {
    return this.showRowNumbers ? 1 : 0;
  }

  /** Whether the grid has an "add" row after the records. */
  get hasAddRow(): boolean {
    return this.canInsert;
  }

  isAddRow(row: number): boolean {
    return this.hasAddRow && row === this.args.records.length;
  }

  /** The visible fields, then the hidden ones: the expanded record, duplicate, undo. */
  @cached
  get allFields(): EuiSheetField<T>[] {
    return [...this.visibleFields, ...this.hiddenFields];
  }

  /** The row-number column: wider only for `@rowLabel` labels. */
  @cached
  get rowColumnWidth(): number {
    const label = this.args.rowLabel;
    if (!label) return ROW_COLUMN_WIDTH;
    let longest = 0;
    this.args.records.forEach((record, i) => {
      longest = Math.max(longest, label(record, this.positionOf(i)).length);
    });
    return Math.max(ROW_COLUMN_WIDTH, 24 + 8 * longest);
  }

  @cached
  get leadingControlColumns(): EuiDataGridControlColumn[] | undefined {
    if (!this.showRowNumbers) return undefined;
    const column: EuiDataGridControlColumn = {
      id: ROW_COLUMN_ID,
      width: this.rowColumnWidth
    };
    if (this.frozenCount) {
      column.headerCellProps = { className: this.frozenHeaderClass(0) };
    }
    return [column];
  }

  /** The add row's class. */
  @cached
  get gridStyle(): EuiDataGridStyle | undefined {
    if (!this.hasAddRow) return undefined;
    return { rowClasses: { [this.args.records.length]: 'euiSheet__addRow' } };
  }

  get rowNumberOffset(): number {
    return this.args.rowNumberOffset ?? 0;
  }

  /** The position a row shows: `@rowNumberOffset + row + 1`. */
  positionOf(row: number): number {
    return this.rowNumberOffset + row + 1;
  }

  /** What a row-number cell shows: `@rowLabel`, else the position. */
  rowLabelOf(row: number): string {
    const record = this.recordAt(row);
    if (record === undefined) return '';
    const position = this.positionOf(row);
    return this.args.rowLabel
      ? this.args.rowLabel(record, position)
      : String(position);
  }

  /** A row of a `'rows'` range (its row number is drawn selected). */
  isRowSelected(row: number): boolean {
    const range = this.range;
    return (
      this.rangeKind === 'rows' &&
      !!range &&
      row >= range.top &&
      row <= range.bottom
    );
  }

  /* Checked rows: controlled with `@onCheckedChange`, else local */

  @cached
  get checkedIds(): ReadonlySet<string> {
    if (!this.args.onCheckedChange) return this.localChecked;
    return new Set((this.args.checkedRecordIds ?? []).map(String));
  }

  isChecked(row: number): boolean {
    const record = this.recordAt(row);
    return (
      record !== undefined &&
      this.checkedIds.has(String(this.args.getRecordId(record)))
    );
  }

  /** The checked records of `@records`, in their order. */
  get checkedRecords(): T[] {
    const checked = this.checkedIds;
    if (!checked.size) return [];
    return this.args.records.filter((record) =>
      checked.has(String(this.args.getRecordId(record)))
    );
  }

  /** The header checkbox: every record of `@records` checked, some, or none. */
  get checkedState(): 'all' | 'some' | 'none' {
    const count = this.checkedRecords.length;
    if (!count) return 'none';
    return count === this.args.records.length ? 'all' : 'some';
  }

  /** Sets the checked ids (strings), through `@onCheckedChange` or locally. */
  setChecked(ids: ReadonlySet<string>): void {
    const handler = this.args.onCheckedChange;
    if (!handler) {
      this.localChecked = ids;
      return;
    }
    // the owner's ids keep their type: from `@records`, else as passed
    const known = new Map<string, RecordId>();
    for (const id of this.args.checkedRecordIds ?? [])
      known.set(String(id), id);
    for (const record of this.args.records) {
      const id = this.args.getRecordId(record);
      known.set(String(id), id);
    }
    handler([...ids].map((id) => known.get(id) ?? id));
  }

  /** Toggles a row's checkbox; with `shift`, the rows from the last toggled one get the same state. */
  toggleChecked(row: number, shift: boolean): void {
    const record = this.recordAt(row);
    if (record === undefined) return;
    const getId = this.args.getRecordId;
    const value = !this.checkedIds.has(String(getId(record)));
    const from =
      shift && this.lastToggledRow !== null
        ? clamp(this.lastToggledRow, 0, this.args.records.length - 1)
        : row;
    const next = new Set(this.checkedIds);
    for (let r = Math.min(from, row); r <= Math.max(from, row); r++) {
      const id = String(getId(this.args.records[r]!));
      if (value) next.add(id);
      else next.delete(id);
    }
    this.lastToggledRow = row;
    this.setChecked(next);
  }

  /** The header checkbox: checks every record, or none when all are checked. */
  toggleAllChecked(): void {
    const ids = this.args.records.map((record) =>
      String(this.args.getRecordId(record))
    );
    const next = new Set(this.checkedIds);
    if (this.checkedState === 'all') ids.forEach((id) => next.delete(id));
    else ids.forEach((id) => next.add(id));
    this.setChecked(next);
  }

  /** The records of the selection: the checked ones when any, else the range's rows. */
  selectionRecords(): T[] {
    const checked = this.checkedRecords;
    if (checked.length) return checked;
    const range = this.range;
    if (!range) return [];
    const records = this.args.records;
    return records.slice(
      Math.max(range.top, 0),
      Math.min(range.bottom, records.length - 1) + 1
    );
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
    return this.valueEquals(
      fieldId,
      rejection.seenValue,
      valueOf(record, fieldId)
    )
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
    const view = this.cellViewFor(record, field, this.isSelected(row, col));
    const drop = this.dropPos;
    if (drop && drop.row === row && drop.col === col) view.dropTarget = true;
    return view;
  }

  /** A record's field as a cell shows it: the grid's cells and the expanded record's boxes. */
  cellViewFor(record: T, field: EuiSheetField<T>, selected = false): CellView {
    const ctx = this.context;
    const type = this.typeOf(field);
    const value = valueOf(record, field.id);
    const recordId = ctx.getRecordId(record);
    const rejection = this.liveRejection(record, recordId, field.id);
    const pending = this.pendingCells.get(cellKey(recordId, field.id));
    const text =
      pending && pending.text !== null
        ? pending.text
        : rejection
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
      // a pending text is shown as text, like a rejected one
      rejected: !!rejection || (!!pending && pending.text !== null),
      errors: pending ? [] : errors,
      selected,
      readOnly: isReadOnly(ctx, field, record),
      pending: !!pending,
      link: this.linkOf(type, field, value),
      dropTarget: false
    };
  }

  /** `type.link(value)`, when it is a link the sheet opens. */
  linkOf(
    type: EuiSheetFieldType,
    field: EuiSheetField,
    value: unknown
  ): string | undefined {
    return type.link ? safeLink(type.link(value as never, field)) : undefined;
  }

  /** Opens a link in a new tab; only http:, https:, mailto: and tel: (checked again here). */
  openLink(href: string | undefined): boolean {
    const safe = safeLink(href);
    if (!safe) return false;
    window.open(safe, '_blank', 'noopener');
    return true;
  }

  /** The field's type's `equals`, else `Object.is` (by field id, visible or hidden). */
  valueEquals(fieldId: string, a: unknown, b: unknown): boolean {
    const field = this.allFields.find((f) => f.id === fieldId);
    if (!field) return Object.is(a, b);
    return sameFieldValue(this.typeOf(field), a, b);
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
    this.noteScrollLeft();
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
    // a pending cell whose record left `@records` (an owner's re-query) is
    // dropped; one on a row not inserted yet (an async owner) is kept
    if (previous && this.pendingCells.size) {
      const now = new Set(ids);
      const left = previousIds.filter((id) => !now.has(id));
      if (left.length) this.dropPending([], left);
    }
    if (
      previous &&
      !sameIds(previousIds, ids) &&
      !isOwnChange(previousIds, ids, pending)
    ) {
      this.followRecords(previousIds, ids);
    }
    // the expanded record left `@records` (deleted, or the owner re-queried)
    const expanded = this.expandedId;
    if (expanded !== null && !ids.includes(String(expanded))) {
      this.expandedFrom = null;
      this.setExpanded(null);
    }
    // a menu opened on rows that changed
    if (this.menu && previous && !sameIds(previousIds, ids)) this.menu = null;
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
      // the last record, or the add row when there is none
      const lastRow = ids.length ? ids.length - 1 : this.rowCount - 1;
      if (this.rowCount === 0) {
        this.anchor = null;
        this.head = null;
      } else {
        const pos = {
          row: found ?? clamp(head.row, 0, lastRow),
          col: head.col
        };
        this.anchor = pos;
        this.head = pos;
        this.rangeKind = 'cells';
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
    this.rangeKind = 'cells';
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

  /** The row-number cell an event belongs to, or null. */
  rowNumberCell(target: EventTarget | null): HTMLElement | null {
    if (!this.colOffset || !(target instanceof Element)) return null;
    const cell = target.closest<HTMLElement>(
      `[role=gridcell][data-gridcell-column-id="${ROW_COLUMN_ID}"]`
    );
    if (!cell || !this.wrapper?.contains(cell)) return null;
    if (cell.classList.contains('euiDataGridFooterCell')) return null;
    return cell;
  }

  /** The data column header an event belongs to, or null (not the control column's). */
  headerCell(target: EventTarget | null): HTMLElement | null {
    if (!(target instanceof Element)) return null;
    const header = target.closest<HTMLElement>('[role=columnheader]');
    if (!header || !this.wrapper?.contains(header)) return null;
    if (header.dataset['gridcellColumnId'] === ROW_COLUMN_ID) return null;
    return header;
  }

  /** The row of a grid cell (data or control), read from its markup. */
  rowIndexOf(cell: HTMLElement): number {
    return Number(cell.dataset['gridcellVisibleRowIndex']);
  }

  /** The rendered row-number cell of a row. */
  rowNumberElement(row: number): HTMLElement | null {
    return (
      this.wrapper?.querySelector<HTMLElement>(
        `[role=gridcell][data-gridcell-visible-row-index="${row}"][data-gridcell-column-id="${ROW_COLUMN_ID}"]`
      ) ?? null
    );
  }

  /** Focuses a row's row-number cell. */
  focusRowNumberCell(row: number): void {
    if (!this.colOffset) return;
    this.noteScrollLeft();
    this.gridApi?.setFocusedCell({ rowIndex: row, colIndex: 0 });
  }

  isInMenu(target: EventTarget | null): boolean {
    return (
      target instanceof Element && !!target.closest('[data-eui-sheet-menu]')
    );
  }

  /** A viewport point in the wrapper's CSS px. */
  pointInWrapper(x: number, y: number): { top: number; left: number } {
    const wrapper = this.wrapper;
    if (!wrapper) return { top: 0, left: 0 };
    const origin = wrapper.getBoundingClientRect();
    const scale = wrapper.offsetWidth ? origin.width / wrapper.offsetWidth : 1;
    return { top: (y - origin.top) / scale, left: (x - origin.left) / scale };
  }

  /* -------------------------------------------------------------------- */
  /* Records: insert, delete, duplicate, copy (V02-DESIGN.md 5.6)          */
  /* -------------------------------------------------------------------- */

  /** `@newRecordValues` for a record between `above` and `below`. */
  newValues(
    above: T | undefined,
    below: T | undefined
  ): Record<string, unknown> {
    return this.args.newRecordValues?.({ above, below }) ?? {};
  }

  /**
   * Emits the insert of one record at `index`, next to `anchor`; then, when
   * `focusFieldId` is given, focuses that field of the new row once it is
   * rendered.
   */
  insertOne(
    index: number,
    anchor: RecordInsert['anchor'] | undefined,
    values: Record<string, unknown>,
    focusFieldId: string | null
  ): void {
    const changeSet = insertRecords(this.context, {
      at: index,
      anchor,
      values: [values],
      nextTempId
    });
    if (this.editing) this.commit({ refocus: false });
    this.emit(changeSet, []);
    if (focusFieldId !== null) {
      this.pendingFocus = {
        id: changeSet.inserts[0]!.tempId,
        fieldId: focusFieldId
      };
      afterRender(this, () => this.applyPendingFocus());
    }
  }

  /** Insert above or below a row (Shift+Enter, the menu); focus goes to `fieldId` of the new row. */
  insertNear(
    row: number,
    position: 'before' | 'after',
    fieldId: string | null
  ): void {
    const records = this.args.records;
    const record = records[row];
    if (record === undefined) return;
    const recordId = this.args.getRecordId(record);
    const values =
      position === 'after'
        ? this.newValues(record, records[row + 1])
        : this.newValues(records[row - 1], record);
    this.insertOne(
      position === 'after' ? row + 1 : row,
      { recordId, position },
      values,
      fieldId ?? this.firstEditableField(values)
    );
  }

  /** The add row: a record at the end; focus goes to its first editable field. */
  appendRecord(): void {
    if (!this.canInsert) return;
    const records = this.args.records;
    const last = records[records.length - 1];
    const values = this.newValues(last, undefined);
    this.insertOne(
      records.length,
      last === undefined
        ? undefined
        : { recordId: this.args.getRecordId(last), position: 'after' },
      values,
      this.firstEditableField(values)
    );
  }

  /** The first visible field a new record with these values can edit. */
  firstEditableField(values: Record<string, unknown>): string | null {
    const fields = this.visibleFields;
    const field =
      fields.find((f) => !isReadOnly(this.context, f, values as T)) ??
      fields[0];
    return field?.id ?? null;
  }

  /** `SheetApi.insertRecord`: no focus change. */
  insertFromApi(options: {
    anchor?: RecordInsert['anchor'];
    values?: Record<string, unknown>;
  }): void {
    const records = this.args.records;
    const anchor = options.anchor;
    const row = anchor ? this.rowOf(anchor.recordId, 0) : -1;
    if (anchor && row >= 0) {
      const index = anchor.position === 'after' ? row + 1 : row;
      const values =
        options.values ?? this.newValues(records[index - 1], records[index]);
      this.insertOne(index, anchor, values, null);
      return;
    }
    const last = records[records.length - 1];
    this.insertOne(
      records.length,
      last === undefined
        ? undefined
        : { recordId: this.args.getRecordId(last), position: 'after' },
      options.values ?? this.newValues(last, undefined),
      null
    );
  }

  /**
   * Emits the delete of these records. With `refocus`, focus goes to that
   * field of the record after them (or before them, at the end).
   */
  deleteRecordIds(
    ids: readonly RecordId[],
    refocus: false | { fieldId: string | null }
  ): void {
    const records = this.args.records;
    const changeSet = deleteRecords(records, ids, this.args.getRecordId);
    if (!changeSet) return;
    if (this.editing) this.commit({ refocus: false });
    if (refocus) {
      const gone = new Set(changeSet.deletes!.map(String));
      const removed = changeSet.removed!;
      const lastIndex = removed[removed.length - 1]!.index;
      const firstIndex = removed[0]!.index;
      const keep = (record: T | undefined) =>
        record !== undefined &&
        !gone.has(String(this.args.getRecordId(record)));
      let neighbour: T | undefined;
      for (let i = lastIndex + 1; i < records.length && !neighbour; i++) {
        if (keep(records[i])) neighbour = records[i];
      }
      for (let i = firstIndex - 1; i >= 0 && !neighbour; i--) {
        if (keep(records[i])) neighbour = records[i];
      }
      const fieldId = refocus.fieldId ?? this.visibleFields[0]?.id;
      this.pendingFocus =
        neighbour && fieldId !== undefined
          ? { id: String(this.args.getRecordId(neighbour)), fieldId }
          : null;
      this.anchor = null;
      this.head = null;
      this.rangeKind = 'cells';
    }
    this.emit(changeSet, []);
  }

  /** A copy of each record right after it: every writable field, visible and hidden. */
  duplicate(records: readonly T[], fieldId: string | null): void {
    const all = this.args.records;
    const indexes = records
      .map((record) =>
        this.rowOf(this.args.getRecordId(record), all.indexOf(record))
      )
      .filter((index) => index >= 0);
    const changeSet = duplicateRecords(
      { ...this.context, fields: this.allFields, readOnly: false },
      indexes,
      { nextTempId }
    );
    if (!changeSet) return;
    const focusField = fieldId ?? this.visibleFields[0]?.id;
    this.emit(changeSet, []);
    if (focusField !== undefined) {
      this.pendingFocus = {
        id: changeSet.inserts[0]!.tempId,
        fieldId: focusField
      };
      afterRender(this, () => this.applyPendingFocus());
    }
  }

  /** Copies the records' visible fields as TSV. */
  copyRows(records: readonly T[]): void {
    if (!records.length) return;
    const matrix = rangeMatrix(
      { ...this.context, records },
      {
        top: 0,
        left: 0,
        bottom: records.length - 1,
        right: this.visibleFields.length - 1
      }
    );
    writeClipboard(toTsv(matrix));
  }

  /* -------------------------------------------------------------------- */
  /* The row menu                                                          */
  /* -------------------------------------------------------------------- */

  /** Opens the menu under a cell (Shift+F10, the ContextMenu key). */
  openMenuAt(row: number, col: number | null, cell: HTMLElement): void {
    const rect = this.rectOf(cell);
    if (!rect) return;
    // the keyboard path acts on the selection, or on this row
    if (
      col === null &&
      !this.isRowSelected(row) &&
      !this.checkedRecords.length
    ) {
      this.keepRangeOnFocus = true;
      this.selectRows(row, false);
    }
    this.openMenu(row, col, { top: rect.top + rect.height, left: rect.left });
  }

  openMenu(
    row: number,
    col: number | null,
    at: { top: number; left: number }
  ): void {
    if (this.editing) this.commit({ refocus: false });
    const records = this.selectionRecords();
    const record = this.recordAt(row);
    this.menu = {
      row,
      col,
      top: at.top,
      left: at.left,
      records: records.length ? records : record === undefined ? [] : [record]
    };
    document.addEventListener('mousedown', this.onDocumentMouseDown, true);
  }

  /** Closes the menu; `refocus` focuses the cell it was opened on. */
  closeMenu(refocus: boolean): void {
    const menu = this.menu;
    document.removeEventListener('mousedown', this.onDocumentMouseDown, true);
    if (!menu) return;
    this.menu = null;
    if (!refocus || menu.row >= this.rowCount) return;
    if (menu.col === null) {
      this.keepRangeOnFocus = true;
      this.focusRowNumberCell(menu.row);
    } else {
      // onFocusIn sees the cell it already knows and keeps the range
      this.domCursor = { row: menu.row, col: menu.col };
      this.focusGridCell({ row: menu.row, col: menu.col });
    }
  }

  /** A press outside the menu closes it. */
  onDocumentMouseDown = (event: MouseEvent): void => {
    if (this.isInMenu(event.target)) return;
    // the mouse events a browser sends after the long press that opened it
    if (this.longPressOpened) return;
    this.closeMenu(false);
  };

  get menuItems(): RowMenuItem[] {
    const menu = this.menu;
    if (!menu) return [];
    const records = menu.records as T[];
    const count = records.length;
    const messages = this.messages;
    const items: RowMenuItem[] = [];
    if (this.canInsert) {
      items.push(
        {
          id: 'insertAbove',
          label: messages.insertAbove(),
          icon: 'sortUp',
          onSelect: () =>
            this.insertNear(menu.row, 'before', this.menuFieldId(menu))
        },
        {
          id: 'insertBelow',
          label: messages.insertBelow(),
          icon: 'sortDown',
          onSelect: () =>
            this.insertNear(menu.row, 'after', this.menuFieldId(menu))
        },
        {
          id: 'duplicate',
          label:
            count > 1
              ? messages.duplicateRecords(count)
              : messages.duplicateRecord(),
          icon: 'copy',
          disabled: !count,
          onSelect: () => this.duplicate(records, this.menuFieldId(menu))
        }
      );
    }
    if (count === 1) {
      items.push({
        id: 'expand',
        label: messages.expandRecord(),
        icon: 'expand',
        onSelect: () => {
          const recordId = this.args.getRecordId(records[0]!);
          this.expandRecord(recordId, {
            recordId,
            fieldId: this.menuFieldId(menu)
          });
        }
      });
    }
    const link = this.menuLink(menu);
    if (link) {
      items.push({
        id: 'openLink',
        label: messages.openLink(),
        icon: 'popout',
        onSelect: () => this.openLink(link)
      });
    }
    items.push({
      id: 'copy',
      label: count > 1 ? messages.copyRows(count) : messages.copyRow(),
      icon: 'copyClipboard',
      disabled: !count,
      onSelect: () => this.copyRows(records)
    });
    for (const action of this.args.rowActions ?? []) {
      items.push({
        id: action.id,
        label: action.label,
        icon: action.icon,
        color: action.color,
        disabled: action.isDisabled?.(records) ?? false,
        onSelect: () => action.onSelect(records)
      });
    }
    if (this.canDelete) {
      items.push({
        id: 'delete',
        label:
          count > 1 ? messages.deleteRecords(count) : messages.deleteRecord(),
        icon: 'trash',
        color: 'danger',
        disabled: !count,
        onSelect: () =>
          this.deleteRecordIds(
            records.map((record) => this.args.getRecordId(record)),
            { fieldId: this.menuFieldId(menu) }
          )
      });
    }
    return items;
  }

  /** The link of the cell the menu was opened on, if it has one. */
  menuLink(menu: MenuState): string | undefined {
    if (menu.col === null) return undefined;
    const record = this.recordAt(menu.row);
    const field = this.visibleFields[menu.col];
    if (record === undefined || !field) return undefined;
    return this.linkOf(this.typeOf(field), field, valueOf(record, field.id));
  }

  /** The field the menu was opened on; the first one from a row number. */
  menuFieldId(menu: MenuState): string | null {
    const col = menu.col ?? 0;
    return this.visibleFields[col]?.id ?? this.visibleFields[0]?.id ?? null;
  }

  onMenuSelect = (item: RowMenuItem): void => {
    // focus goes back to the cell, unless the action moves it (to a new
    // row, a remaining row, the expanded record)
    this.closeMenu(!MENU_ITEMS_THAT_MOVE_FOCUS.has(item.id));
    item.onSelect();
  };

  /* -------------------------------------------------------------------- */
  /* The expanded record (V02-DESIGN.md 5.7)                               */
  /* -------------------------------------------------------------------- */

  /** Controlled with `@onExpandedRecordChange`, else local. */
  get expandedId(): RecordId | null {
    return this.args.onExpandedRecordChange
      ? (this.args.expandedRecordId ?? null)
      : this.localExpandedId;
  }

  setExpanded(id: RecordId | null): void {
    if (id === null && this.formEditorOpen) this.formEditorOpen = false;
    if (this.args.onExpandedRecordChange) this.args.onExpandedRecordChange(id);
    else this.localExpandedId = id;
  }

  /** The expanded record, while it is in `@records`. */
  get expandedRecordValue(): T | undefined {
    const id = this.expandedId;
    if (id === null) return undefined;
    return this.args.records[this.rowOf(id, 0)];
  }

  get expandedShell(): 'flyout' | 'modal' {
    return this.args.expandedRecord === 'modal' ? 'modal' : 'flyout';
  }

  /** Opens a record of `@records`; `from` is the cell focus returns to on close. */
  expandRecord(recordId: RecordId, from: ExpandedFrom | null): void {
    if (this.rowOf(recordId, this.head?.row ?? 0) < 0) return;
    if (this.editing) this.commit({ refocus: false });
    this.expandedFrom = from ?? this.expandedFrom;
    this.setExpanded(recordId);
  }

  /** Closes it and focuses the cell it was opened from, when that row still exists. */
  closeExpanded = (): void => {
    const from = this.expandedFrom;
    this.expandedFrom = null;
    this.setExpanded(null);
    if (!from) return;
    afterRender(this, () => {
      // a controlled owner may keep it open
      if (this.expandedId !== null) {
        this.expandedFrom ??= from;
        return;
      }
      const row = this.rowOf(from.recordId, this.head?.row ?? 0);
      if (row < 0) return;
      if (from.fieldId === null) {
        this.keepRangeOnFocus = true;
        this.focusRowNumberCell(row);
      } else {
        this.focusRecordCell({
          recordId: from.recordId,
          fieldId: from.fieldId
        });
      }
    });
  };

  /** The record `step` rows from the expanded one, or null at either end. */
  expandedStep(step: number): T | null {
    const id = this.expandedId;
    if (id === null) return null;
    const row = this.rowOf(id, 0);
    if (row < 0) return null;
    return this.args.records[row + step] ?? null;
  }

  stepExpanded(step: number): void {
    const record = this.expandedStep(step);
    if (record) this.setExpanded(this.args.getRecordId(record));
  }

  /** The expanded record's title: its first field's text, else "Record n". */
  recordTitleOf(record: T): string {
    const field = this.allFields[0];
    const text = field
      ? this.typeOf(field).format(valueOf(record, field.id), field, {
          record,
          messages: this.messages
        })
      : '';
    if (text.trim()) return text;
    const row = this.rowOf(this.args.getRecordId(record), 0);
    return this.messages.recordTitle(this.positionOf(Math.max(row, 0)));
  }

  /** A one-record context for the form: every field, visible and hidden. */
  formContext(record: T): { ctx: SheetContext<T>; record: T } | null {
    // the current object of the record: the form may hold an older one
    const row = this.rowOf(this.args.getRecordId(record), 0);
    const current = this.args.records[row];
    if (current === undefined) return null;
    return {
      ctx: { ...this.context, records: [current], fields: this.allFields },
      record: current
    };
  }

  /** A value saved from the form (a picked option, a toggled checkbox). */
  commitFormValue(record: T, field: EuiSheetField<T>, value: unknown): void {
    this.commitForm(record, field, (ctx, pos) => commitValue(ctx, pos, value));
  }

  /** A text typed in the form, parsed by the field's type. */
  commitFormText(record: T, field: EuiSheetField<T>, text: string): void {
    const form = this.formContext(record);
    if (!form) return;
    const col = this.allFields.indexOf(field);
    if (col < 0) return;
    this.emitText(form.ctx, { row: 0, col }, text, [
      { id: this.args.getRecordId(form.record), fieldId: field.id }
    ]);
  }

  /** Delete or Backspace on a box: the type's empty value. */
  clearFormField(record: T, field: EuiSheetField<T>): void {
    this.commitForm(record, field, (ctx, pos) =>
      clearRange(ctx, {
        top: pos.row,
        left: pos.col,
        bottom: pos.row,
        right: pos.col
      })
    );
  }

  commitForm(
    record: T,
    field: EuiSheetField<T>,
    build: (ctx: SheetContext<T>, pos: Pos) => ChangeSet | null
  ): void {
    const form = this.formContext(record);
    if (!form) return;
    const col = this.allFields.indexOf(field);
    if (col < 0) return;
    const changeSet = build(form.ctx, { row: 0, col });
    this.emit(changeSet, [
      { id: this.args.getRecordId(form.record), fieldId: field.id }
    ]);
  }

  /** Runs `fn` after the next render (the form focuses a box). */
  afterFormRender(fn: () => void): void {
    afterRender(this, fn);
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
    const keepRange = this.keepRangeOnFocus;
    this.keepRangeOnFocus = false;
    const rowCell = this.rowNumberCell(event.target);
    if (rowCell) {
      this.focused = null;
      if (this.frozenCount) this.onFrozenFocus(0);
      this.onRowNumberFocus(this.rowIndexOf(rowCell), keepRange);
      return;
    }
    const cell = this.dataCell(event.target);
    if (!cell) {
      this.scrollLeftBeforeFocus = null;
      // the header, a control or an editor: no error box (an open editor
      // hides it anyway)
      if (!this.isInEditor(event.target)) this.focused = null;
      return;
    }
    const pos = this.cursor(cell);
    this.rowCursor = null;
    this.trackFocusedCell(pos, cell);
    if (this.frozenCount) {
      if (pos.col < this.frozenCount)
        this.onFrozenFocus(pos.col + this.colOffset);
      else afterRender(this, () => this.clearFrozenOverlap(pos));
    }
    // the grid re-focuses the same cell when it re-mounts (scroll) and
    // after cancel(): that must not collapse a range
    if (samePos(pos, this.domCursor)) return;
    this.domCursor = pos;
    // a right-click inside the range keeps it for the menu
    if (keepRange) return;
    if (this.extending && this.anchor) {
      this.head = pos;
    } else {
      this.anchor = pos;
      this.head = pos;
    }
    this.rangeKind = 'cells';
  }

  /**
   * Focus on a row-number cell (C13): a press there already set the range
   * (`keepRange`); Shift+ArrowUp/Down extends a `'rows'` range; any other
   * keyboard focus clears the range, so Delete, copy and paste do nothing.
   */
  onRowNumberFocus(row: number, keepRange: boolean): void {
    // the grid re-focuses the same cell when it re-mounts (scroll)
    if (row === this.rowCursor) return;
    const from = this.rowCursor;
    this.rowCursor = row;
    this.domCursor = null;
    if (keepRange) return;
    const last = this.visibleFields.length - 1;
    if (this.extending && row < this.args.records.length) {
      if (this.rangeKind !== 'rows' || !this.anchor) {
        this.anchor = { row: from ?? row, col: 0 };
        this.rangeKind = 'rows';
      }
      this.head = { row, col: last };
      return;
    }
    this.anchor = null;
    this.head = null;
    this.rangeKind = 'cells';
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
    if (!focused || this.editing || this.menu || this.imeActive) return null;
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
    // the compatibility mouse events of the long press that opened the menu
    if (this.longPressOpened) return;
    this.extending = event.shiftKey;
    this.noteScrollLeft();
    this.pressing = true;
    const target = event.target as Element;
    // before the press moves focus: was this cell the focused one?
    const cell = this.dataCell(target);
    this.pressOnFocusedCell = !!cell && cell === document.activeElement;
    // a click after a drag that released outside the sheet never came
    this.suppressClick = false;
    this.endDrag();
    if (this.menu && !this.isInMenu(target)) this.closeMenu(false);

    const rowCell = this.rowNumberCell(target);
    if (rowCell) {
      // the range is the press's: focusin must not clear it
      this.keepRangeOnFocus = true;
      const row = this.rowIndexOf(rowCell);
      if (row >= this.args.records.length || event.button !== 0) return;
      // the checkbox and the expand icon are buttons, not a selection
      if (
        target.closest(
          '[data-eui-sheet-row-check], [data-eui-sheet-row-expand]'
        )
      ) {
        return;
      }
      this.selectRows(row, event.shiftKey);
      if (
        !event.shiftKey &&
        !this.editing &&
        this.lastPointerType !== 'touch'
      ) {
        this.dragFrom = { row, col: 0 };
        this.dragKind = 'rows';
        this.watchRelease();
      }
      return;
    }

    if (!cell) return;
    const pos = this.cursor(cell);
    if (event.button === 2) {
      // a right-click inside the range keeps it for the menu
      this.keepRangeOnFocus = this.isSelected(pos.row, pos.col);
      return;
    }
    // a press that may become a drag (Shift+click extends instead)
    // (a touch drag scrolls: no range drag by touch, 8.5)
    if (
      event.button === 0 &&
      !event.shiftKey &&
      !this.editing &&
      this.lastPointerType !== 'touch' &&
      pos.row < this.args.records.length &&
      !target.closest('[data-eui-sheet-opener]')
    ) {
      this.dragFrom = pos;
      this.dragKind = 'cells';
      this.watchRelease();
    }
  }

  /** A press that may become a select drag: its release, and the pointer for auto-scroll. */
  watchRelease(): void {
    document.addEventListener('mouseup', this.onRelease, true);
    document.addEventListener('mousemove', this.onDragMove, true);
  }

  /** The pointer during a select drag: auto-scroll near the grid's edges (8.4). */
  onDragMove = (event: MouseEvent): void => {
    if (!this.dragFrom) return;
    this.dragPointer = { x: event.clientX, y: event.clientY };
    this.feedAutoScroll(event.clientX, event.clientY, this.dragging);
  };

  /**
   * Passes the pointer to the auto-scroll loop once a drag is really
   * selecting (or filling), or the pointer left the grid's body: a plain
   * press near an edge, with a pixel of jitter, must not scroll.
   */
  feedAutoScroll(x: number, y: number, active: boolean): void {
    if (active || this.autoScroll.running) {
      this.autoScroll.update(x, y);
      return;
    }
    const bounds = this.scrollBounds();
    if (
      bounds &&
      (x < bounds.left ||
        x > bounds.right ||
        y < bounds.top ||
        y > bounds.bottom)
    ) {
      this.autoScroll.update(x, y);
    }
  }

  /**
   * An auto-scroll frame (or a fill drag's move): the cell under the
   * pointer, clamped inside the grid's body, is the drag's head. Rows the
   * scroll rendered under a pointer that did not move fire no `mouseover`.
   */
  dragTo(x: number, y: number): void {
    const element = document.elementFromPoint(x, y);
    if (this.fillSource) this.fillTo(element);
    else if (this.dragFrom) this.dragOver(element);
  }

  /** Selects whole rows: from `row`, or from the range's anchor with `extend`. */
  selectRows(row: number, extend: boolean): void {
    const last = this.visibleFields.length - 1;
    const anchorRow =
      extend && this.anchor
        ? clamp(this.anchor.row, 0, this.args.records.length - 1)
        : row;
    this.anchor = { row: anchorRow, col: 0 };
    this.head = { row, col: last };
    this.rangeKind = 'rows';
  }

  /** Selects whole columns of the records: from `col`, or from the range's anchor with `extend`. */
  selectColumns(col: number, extend: boolean): void {
    const lastRow = this.args.records.length - 1;
    if (lastRow < 0) return;
    const anchorCol =
      extend && this.anchor && this.rangeKind === 'columns'
        ? this.anchor.col
        : col;
    this.anchor = { row: 0, col: anchorCol };
    this.head = { row: lastRow, col };
    this.rangeKind = 'columns';
  }

  /**
   * Drag to select: once the pointer is over another data cell, the pressed
   * cell is the anchor and the hovered one the head. Nothing changes while
   * the pointer stays on the pressed cell, so a click is only a click. A
   * press on a row number drags whole rows.
   */
  @action
  onMouseOver(event: MouseEvent): void {
    this.dragOver(event.target);
  }

  /** A select drag reached `element` (a `mouseover`, or an auto-scroll frame). */
  dragOver(element: EventTarget | null): void {
    const from = this.dragFrom;
    if (!from) return;
    if (this.dragKind === 'rows') {
      const target = this.rowNumberCell(element) ?? this.dataCell(element);
      if (!target) return;
      const row = this.rowIndexOf(target);
      if (row >= this.args.records.length) return;
      if (!this.dragging) {
        if (row === from.row) return;
        this.dragging = true;
      }
      this.selectRows(row, true);
      window.getSelection()?.removeAllRanges();
      return;
    }
    const cell = this.dataCell(element);
    if (!cell) return;
    const pos = this.cursor(cell);
    // the add row is never part of a range
    if (pos.row >= this.args.records.length) return;
    if (!this.dragging) {
      if (samePos(pos, from)) return;
      this.dragging = true;
      this.anchor = from;
      this.rangeKind = 'cells';
    }
    if (!samePos(pos, this.head)) this.head = pos;
    // text the press may have started to select
    window.getSelection()?.removeAllRanges();
  }

  /** The release ends a drag (anywhere on the page): focus goes to the head, keeping the anchor. */
  onRelease = (): void => {
    const dragged = this.dragging;
    const kind = this.dragKind;
    const from = this.dragFrom;
    const before = this.scrollLeftBeforeFocus;
    this.endDrag();
    if (!dragged) return;
    // the grid scrolled the pressed cell into view on pointerup; a frozen
    // one is always in view, so the scroll goes back to the press's
    if (
      this.frozenCount &&
      (kind === 'rows' || (from !== null && from.col < this.frozenCount))
    ) {
      this.scrollLeftBeforeFocus = before;
      this.keepFrozenScroll();
    }
    const head = this.head;
    if (!head || samePos(head, this.anchor)) return;
    // the click that follows is the end of the drag, not a click on a cell
    this.suppressClick = true;
    // the head may not be rendered now (an auto-scroll took it away, or the
    // grid's pointerup scrolled back to the pressed cell), so its focus can
    // come after this release and after its click: the focus handlers must
    // see a cell they already know and keep the range
    if (kind === 'rows') {
      this.keepRangeOnFocus = true;
      this.rowCursor = head.row;
      this.focusRowNumberCell(head.row);
      return;
    }
    // onFocusIn keeps the anchor, so Shift+arrows continue from here
    this.extending = true;
    if (head.row < this.rowCount) {
      this.domCursor = head;
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
    document.removeEventListener('mousemove', this.onDragMove, true);
    if (!this.fillSource) {
      this.autoScroll.stop();
      this.dragPointer = null;
    }
  }

  /* -------------------------------------------------------------------- */
  /* The fill handle (V02-DESIGN.md 8.4)                                   */
  /* -------------------------------------------------------------------- */

  /** The range the fill handle is drawn for: cells, a writable sheet, no editor. */
  get fillHandleRange(): Range | null {
    const range = this.range;
    if (!range || this.args.readOnly || this.editing) return null;
    if (this.rangeKind !== 'cells') return null;
    if (range.top >= this.args.records.length) return null;
    return range;
  }

  /** Puts the handle at the corner of the range's last cell, or hides it while that corner is not in view. */
  placeFillHandle(element: HTMLElement, range: Range): void {
    const corner = {
      row: Math.min(range.bottom, this.args.records.length - 1),
      col: range.right
    };
    const cell = this.cellElement(corner);
    const bounds = cell && this.scrollBounds();
    const rect = cell && this.rectOf(cell);
    let shown = false;
    if (cell && bounds && rect) {
      const box = cell.getBoundingClientRect();
      const left =
        bounds.frozenRight !== undefined && corner.col >= this.frozenCount
          ? bounds.frozenRight
          : bounds.left;
      shown =
        box.right >= left &&
        box.right <= bounds.right + 1 &&
        box.bottom >= bounds.top &&
        box.bottom <= bounds.bottom + 1;
    }
    element.style.display = shown ? '' : 'none';
    if (shown && rect) {
      element.style.top = `${rect.top + rect.height - 4}px`;
      element.style.left = `${rect.left + rect.width - 4}px`;
    }
  }

  /** A press on the handle starts a fill drag; focus stays on the cell. */
  onFillHandlePress = (event: MouseEvent): void => {
    event.preventDefault();
    if (event.button !== 0) return;
    const range = this.fillHandleRange;
    if (!range) return;
    this.fillSource = range;
    this.fillTarget = range;
    this.dragPointer = { x: event.clientX, y: event.clientY };
    document.addEventListener('mousemove', this.onFillMove, true);
    document.addEventListener('mouseup', this.onFillRelease, true);
    document.addEventListener('keydown', this.onFillKeyDown, true);
  };

  onFillMove = (event: MouseEvent): void => {
    const source = this.fillSource;
    if (!source) return;
    this.dragPointer = { x: event.clientX, y: event.clientY };
    this.dragTo(event.clientX, event.clientY);
    const target = this.fillTarget;
    this.feedAutoScroll(
      event.clientX,
      event.clientY,
      !!target && !sameRange(target, source)
    );
  };

  /** The fill reaches the cell at `element`: the source extended along the dominant axis. */
  fillTo(element: Element | null): void {
    const source = this.fillSource;
    const cell = this.dataCell(element);
    if (!source || !cell) return;
    const pos = this.cursor(cell);
    // a fill never reaches the add row
    const row = Math.min(pos.row, this.args.records.length - 1);
    const down = row - source.bottom;
    const up = source.top - row;
    const right = pos.col - source.right;
    const left = source.left - pos.col;
    const dy = Math.max(down, up, 0);
    const dx = Math.max(right, left, 0);
    let target = source;
    if (dy > 0 && dy >= dx) {
      target = down > 0 ? { ...source, bottom: row } : { ...source, top: row };
    } else if (dx > 0) {
      target =
        right > 0
          ? { ...source, right: pos.col }
          : { ...source, left: pos.col };
    }
    const current = this.fillTarget;
    if (!current || !sameRange(current, target)) this.fillTarget = target;
  }

  /** The cells a fill writes: the target without the source. */
  fillWritten(source: Range, target: Range): Range {
    if (target.bottom > source.bottom) {
      return { ...target, top: source.bottom + 1 };
    }
    if (target.top < source.top) return { ...target, bottom: source.top - 1 };
    if (target.right > source.right) {
      return { ...target, left: source.right + 1 };
    }
    return { ...target, right: source.left - 1 };
  }

  /** The release fills (Ctrl or Alt held: copies, no series) and selects the union. */
  onFillRelease = (event: MouseEvent): void => {
    const source = this.fillSource;
    const target = this.fillTarget;
    this.stopFillDrag();
    this.pressing = false;
    // the press's scroll is not one to restore (a fill may auto-scroll)
    this.scrollLeftBeforeFocus = null;
    // the click that may follow is the end of the drag
    this.suppressClick = true;
    if (!source || !target || sameRange(source, target)) return;
    this.emit(
      fillRange(this.context, source, target, {
        copy: event.ctrlKey || event.altKey
      }),
      this.touchedIn(this.fillWritten(source, target), true)
    );
    // the union is the range; focus stays where it was when that cell is
    // one of its corners (a single cell filled down), else it moves to the
    // nearest corner
    const head = this.head ?? { row: source.top, col: source.left };
    const corners = [
      { row: target.top, col: target.left },
      { row: target.top, col: target.right },
      { row: target.bottom, col: target.left },
      { row: target.bottom, col: target.right }
    ];
    const distance = (pos: Pos) =>
      Math.abs(pos.row - head.row) + Math.abs(pos.col - head.col);
    const next = corners.reduce((best, pos) =>
      distance(pos) < distance(best) ? pos : best
    );
    this.anchor = {
      row: next.row === target.top ? target.bottom : target.top,
      col: next.col === target.left ? target.right : target.left
    };
    this.head = next;
    this.rangeKind = 'cells';
    // focus moves to the new corner, or back to the cell an auto-scroll
    // unmounted (focus left with it)
    const active = this.dataCell(document.activeElement);
    if (!active || !samePos(this.cursor(active), next)) {
      this.domCursor = next;
      this.focusGridCell(next);
    }
  };

  /** Escape during a fill drag cancels it. */
  onFillKeyDown = (event: KeyboardEvent): void => {
    if (event.key !== 'Escape') return;
    stop(event);
    this.stopFillDrag();
  };

  stopFillDrag(): void {
    document.removeEventListener('mousemove', this.onFillMove, true);
    document.removeEventListener('mouseup', this.onFillRelease, true);
    document.removeEventListener('keydown', this.onFillKeyDown, true);
    if (!this.fillSource) return;
    this.fillSource = null;
    this.autoScroll.stop();
    this.dragPointer = null;
    if (!isDestroying(this) && this.fillTarget) this.fillTarget = null;
  }

  /** Whether a cell is in the fill drag's preview (the target, not the source). */
  isFillPreview(row: number, col: number): boolean {
    const target = this.fillTarget;
    const source = this.fillSource;
    if (!target || !source) return false;
    const inside = (range: Range) =>
      row >= range.top &&
      row <= range.bottom &&
      col >= range.left &&
      col <= range.right;
    return inside(target) && !inside(source);
  }

  /* -------------------------------------------------------------------- */
  /* Touch (V02-DESIGN.md 8.5)                                             */
  /* -------------------------------------------------------------------- */

  /**
   * A press: its pointer type (touch presses do not drag a range); a touch
   * on a record's cell or row number starts the long-press timer.
   */
  @action
  onPointerDown(event: PointerEvent): void {
    this.lastPointerType = event.pointerType || 'mouse';
    this.longPressOpened = false;
    this.cancelLongPress();
    if (event.pointerType !== 'touch' || !event.isPrimary || this.editing) {
      return;
    }
    const target = event.target as Element;
    if (this.menuRowOf(target) < 0) return;
    this.longPress = {
      x: event.clientX,
      y: event.clientY,
      target,
      timer: later(this, this.onLongPress, LONG_PRESS_MS)
    };
  }

  /** A touch that moves is a scroll: no long press. */
  @action
  onPointerMove(event: PointerEvent): void {
    const press = this.longPress;
    if (!press || event.pointerType !== 'touch') return;
    const moved = Math.hypot(event.clientX - press.x, event.clientY - press.y);
    if (moved > LONG_PRESS_SLOP) this.cancelLongPress();
  }

  /** `pointerup` and `pointercancel` (a native pan) end a long press. */
  @action
  onPointerEnd(): void {
    this.cancelLongPress();
  }

  cancelLongPress(): void {
    const press = this.longPress;
    if (!press) return;
    cancel(press.timer);
    this.longPress = null;
  }

  /** The long press opens the row menu there, like a right-click; the click that follows is swallowed. */
  onLongPress(): void {
    const press = this.longPress;
    this.longPress = null;
    if (!press || this.editing) return;
    if (this.openContextMenu(press.target, press.x, press.y)) {
      this.longPressOpened = true;
    }
  }

  /** The click (and the compatibility events) after a long press are the press's own: no link, no star, no edit. */
  @action
  onClickCapture(event: MouseEvent): void {
    if (!this.longPressOpened || this.isInMenu(event.target)) return;
    this.longPressOpened = false;
    stop(event);
  }

  /** The record row of a data cell or a row-number cell; -1 elsewhere. */
  menuRowOf(target: Element): number {
    const rowCell = this.rowNumberCell(target);
    const cell = rowCell ? null : this.dataCell(target);
    const row = rowCell
      ? this.rowIndexOf(rowCell)
      : cell
        ? this.cursor(cell).row
        : -1;
    return row >= 0 && row < this.args.records.length ? row : -1;
  }

  /* -------------------------------------------------------------------- */
  /* Composition: dead keys and IMEs (V02-DESIGN.md 8.6)                   */
  /* -------------------------------------------------------------------- */

  /** Moves the catcher over the cell and focuses it, inside the `keydown`. */
  startIme(pos: Pos, cell: HTMLElement): void {
    const input = this.imeInput;
    const rect = this.rectOf(cell);
    if (!input || !rect) return;
    this.imePos = pos;
    this.imeComposing = false;
    input.value = '';
    this.placeIme(rect);
    input.classList.add('euiSheet__input', 'euiSheet__ime--active');
    input.focus({ preventScroll: true });
    this.imeActive = true;
  }

  /** Puts the catcher over a cell's box. */
  placeIme(rect: SheetEditorRect): void {
    const input = this.imeInput;
    if (!input) return;
    input.style.top = `${rect.top}px`;
    input.style.left = `${rect.left}px`;
    input.style.width = `${rect.width}px`;
    input.style.height = `${rect.height}px`;
  }

  onImeCompositionStart(): void {
    if (this.imePos) this.imeComposing = true;
  }

  onImeCompositionEnd(event: CompositionEvent): void {
    if (!this.imePos) return;
    this.imeComposing = false;
    this.finishIme(this.imeInput?.value || event.data || '');
  }

  /** A dead key that fires no composition events types its character as a plain `input`. */
  onImeInput(event: InputEvent): void {
    if (!this.imePos || event.isComposing || this.imeComposing) return;
    this.finishIme(this.imeInput?.value ?? '');
  }

  /** Escape (or Tab) outside a composition: back to the cell. */
  onImeKeyDown(event: KeyboardEvent): void {
    if (event.isComposing || event.keyCode === 229) return;
    if (event.key !== 'Escape' && event.key !== 'Tab') return;
    stop(event);
    const pos = this.imePos;
    this.endIme();
    if (pos) this.focusGridCell(pos);
  }

  /** Hides and clears the catcher (its own blur, a scroll, the end of a composition). */
  endIme(): void {
    const input = this.imeInput;
    this.imePos = null;
    this.imeComposing = false;
    if (input) {
      input.value = '';
      input.classList.remove('euiSheet__input', 'euiSheet__ime--active');
      input.removeAttribute('style');
    }
    if (this.imeActive) this.imeActive = false;
  }

  /**
   * The composed text opens the cell's editor with it (as a typed key
   * does); empty text, or a type whose `opensOnKey` refuses it: focus goes
   * back to the cell.
   */
  finishIme(text: string): void {
    const pos = this.imePos;
    this.endIme();
    if (!pos) return;
    const cell = this.cellElement(pos);
    const field = this.visibleFields[pos.col];
    const open =
      !!text &&
      !!cell &&
      !!field &&
      this.canEdit(pos) &&
      (this.typeOf(field).opensOnKey?.(text) ?? true);
    if (open) this.startEdit(pos, cell, text);
    else this.focusGridCell(pos);
  }

  /* -------------------------------------------------------------------- */
  /* @editIn (V02-DESIGN.md 8.5)                                           */
  /* -------------------------------------------------------------------- */

  /** Whether a click on the selected cell or Enter edits in the expanded record. */
  get editsInRecord(): boolean {
    const mode = this.args.editIn ?? 'auto';
    if (mode === 'record') return true;
    if (mode !== 'auto') return false;
    return (
      coarsePointer() && (this.wrapper?.offsetWidth ?? Infinity) < NARROW_SHEET
    );
  }

  /**
   * `@editIn`: opens the expanded record with the cell's field editing,
   * instead of the grid's editor. False when it does not apply.
   */
  editInRecord(pos: Pos): boolean {
    if (!this.editsInRecord || !this.canEdit(pos)) return false;
    const record = this.recordAt(pos.row);
    const field = this.visibleFields[pos.col];
    if (record === undefined || !field) return false;
    const recordId = this.args.getRecordId(record);
    this.pendingFormEdit = { recordId, fieldId: field.id };
    // the shell's focus trap waits for the editor (as for any form editor)
    this.formEditorOpen = true;
    this.expandRecord(recordId, { recordId, fieldId: field.id });
    afterRender(this, () => {
      // no form took it (a controlled owner kept the record closed)
      if (!this.pendingFormEdit) return;
      this.pendingFormEdit = null;
      this.formEditorOpen = false;
    });
    return true;
  }

  /** The expanded record's form asks which field to open on mount. */
  takePendingFormEdit(record: unknown): string | null {
    const pending = this.pendingFormEdit;
    if (!pending || record === undefined) return null;
    if (
      String(this.args.getRecordId(record as T)) !== String(pending.recordId)
    ) {
      return null;
    }
    this.pendingFormEdit = null;
    return pending.fieldId;
  }

  /**
   * Airtable-style clicks: the first click selects (the grid focuses the
   * cell); a click on the selected cell edits; the type's opener button
   * opens the editor in one click; a type with `onCellClick` (the checkbox)
   * saves on any click. Before those: the row-number column (checkbox,
   * expand icon), a column header (selects the column) and the add row.
   */
  @action
  onClick(event: MouseEvent): void {
    if (this.pressing) {
      this.pressing = false;
      const focused = document.activeElement;
      const frozen =
        (this.rowNumberCell(focused) && this.frozenCount) ||
        (this.dataCell(focused) &&
          this.cursor(this.dataCell(focused)!).col < this.frozenCount);
      if (frozen) this.keepFrozenScroll();
      else this.scrollLeftBeforeFocus = null;
    }
    const pressOnFocusedCell = this.pressOnFocusedCell;
    this.pressOnFocusedCell = false;
    this.keepRangeOnFocus = false;
    if (this.suppressClick) {
      this.suppressClick = false;
      return;
    }
    const target = event.target as Element;
    if (this.isInMenu(target)) return;
    if (this.onControlClick(event, target)) return;
    if (event.shiftKey || this.editing) return;
    const cell = this.dataCell(target);
    if (!cell) return;
    const pos = this.cursor(cell);
    if (this.isAddRow(pos.row)) {
      this.appendRecord();
      return;
    }
    const record = this.recordAt(pos.row);
    const field = this.visibleFields[pos.col];
    if (record === undefined || !field) return;
    const type = this.typeOf(field);
    // a click on the link text opens it (first click, no edit)
    if (target.closest('[data-eui-sheet-link]')) {
      if (this.openLink(this.linkOf(type, field, valueOf(record, field.id)))) {
        return;
      }
    }
    // a star click is the cell's own (`@onCommit`): no edit
    if (target.closest('[data-eui-sheet-star]')) return;
    if (target.closest('[data-eui-sheet-opener]')) {
      if (this.canEdit(pos) && !this.editInRecord(pos)) {
        this.startEdit(pos, cell, null);
      }
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
    if (pressOnFocusedCell && this.canEdit(pos) && !this.editInRecord(pos)) {
      this.startEdit(pos, cell, null);
    }
  }

  /** Clicks on the row-number column and the column headers; true when handled. */
  onControlClick(event: MouseEvent, target: Element): boolean {
    if (target.closest('[data-eui-sheet-row-check-all]')) {
      this.toggleAllChecked();
      return true;
    }
    const rowCell = this.rowNumberCell(target);
    if (rowCell) {
      const row = this.rowIndexOf(rowCell);
      if (this.isAddRow(row)) {
        this.appendRecord();
      } else if (target.closest('[data-eui-sheet-row-check]')) {
        this.toggleChecked(row, event.shiftKey);
      } else if (target.closest('[data-eui-sheet-row-expand]')) {
        const record = this.recordAt(row);
        if (record !== undefined) {
          const recordId = this.args.getRecordId(record);
          this.expandRecord(recordId, { recordId, fieldId: null });
        }
      }
      return true;
    }
    // a header's title (not its actions button or resizer) selects the column
    const header = this.headerCell(target);
    if (header && target.closest('.euiDataGridHeaderCell__content')) {
      const col =
        Number(header.dataset['gridcellColumnIndex']) - this.colOffset;
      if (col >= 0 && col < this.visibleFields.length) {
        this.selectColumns(col, event.shiftKey);
      }
      return true;
    }
    return false;
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
    if (this.canEdit(pos) && !this.editInRecord(pos)) {
      this.startEdit(pos, cell, null);
    }
  }

  /** Right-click on a data cell or a row number: the row menu. */
  @action
  onContextMenu(event: MouseEvent): void {
    const target = event.target as Element;
    // the ContextMenu key's own event, once focus is in the menu: not the
    // browser's menu over it; and a long press that already opened it
    if (this.isInMenu(target) || this.longPressOpened) {
      event.preventDefault();
      return;
    }
    this.cancelLongPress();
    if (this.openContextMenu(target, event.clientX, event.clientY)) {
      event.preventDefault();
    }
  }

  /** The row menu at a viewport point, for a right-click or a long press on `target`; whether it opened. */
  openContextMenu(target: Element, x: number, y: number): boolean {
    if (this.editing) return false;
    const rowCell = this.rowNumberCell(target);
    const cell = rowCell ? null : this.dataCell(target);
    const row = rowCell
      ? this.rowIndexOf(rowCell)
      : cell
        ? this.cursor(cell).row
        : -1;
    if (row < 0 || row >= this.args.records.length) return false;
    let col: number | null = null;
    if (rowCell) {
      if (!this.isRowSelected(row)) this.selectRows(row, false);
    } else if (cell) {
      const pos = this.cursor(cell);
      col = pos.col;
      if (!this.isSelected(pos.row, pos.col)) {
        this.anchor = pos;
        this.head = pos;
        this.rangeKind = 'cells';
      }
    }
    const rect = this.pointInWrapper(x, y);
    this.openMenu(row, col, rect);
    return true;
  }

  /* -------------------------------------------------------------------- */
  /* Keys and clipboard                                                    */
  /* -------------------------------------------------------------------- */

  @action
  onKeyDown(event: KeyboardEvent): void {
    this.extending = event.shiftKey && RANGE_KEYS.has(event.key);
    this.pressing = false;
    this.noteScrollLeft();
    this.keepRangeOnFocus = false;
    const target = event.target;
    // a composition in an editor or in the catcher is the IME's: Enter
    // confirms it there, it does not save
    if (
      (event.isComposing || event.keyCode === 229) &&
      this.isInEditor(target)
    ) {
      return;
    }
    if (this.editing && this.isInEditor(target)) {
      this.onEditKeyDown(event);
      return;
    }
    if (this.menu && this.isInMenu(target)) {
      // the panel has ArrowUp/Down and Enter; Escape is the sheet's
      if (event.key === 'Escape' || event.key === 'Tab') {
        stop(event);
        this.closeMenu(true);
      }
      return;
    }
    const rowCell = this.rowNumberCell(target);
    if (rowCell && target === rowCell) {
      this.onRowNumberKeyDown(event, this.rowIndexOf(rowCell));
      return;
    }
    const header = this.headerCell(target);
    if (header && target === header) {
      // a selected column: Delete clears it (other keys are the header's)
      if (
        this.rangeKind === 'columns' &&
        this.range &&
        (event.key === 'Delete' || event.key === 'Backspace')
      ) {
        stop(event);
        this.clearSelection();
      }
      return;
    }
    const cell = this.dataCell(target);
    if (!cell || target !== cell) return;
    const pos = this.cursor(cell);
    if (this.handleCommandKey(event)) return;
    if (this.handleNavKey(event, pos)) return;
    if (this.handleHomeKey(event, pos.row)) return;
    if (this.isAddRow(pos.row)) {
      this.onAddRowKeyDown(event);
      return;
    }
    const record = this.recordAt(pos.row);
    const field = this.visibleFields[pos.col];
    if (record === undefined || !field) return;
    const ctx = this.context;
    const type = this.typeOf(field);
    const readOnly = isReadOnly(ctx, field, record);
    const { key } = event;
    const plain = !event.ctrlKey && !event.metaKey && !event.altKey;

    if (isMenuKey(event)) {
      stop(event);
      this.openMenuAt(pos.row, pos.col, cell);
      return;
    }
    // a dead key or an IME: not prevented, the composition goes to the
    // catcher, focused now (8.6)
    if (startsComposition(event)) {
      if (type.editor && !readOnly) this.startIme(pos, cell);
      return;
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
      // C9: Space expands the record (also keeps the page from scrolling)
      stop(event);
      const recordId = this.args.getRecordId(record);
      this.expandRecord(recordId, { recordId, fieldId: field.id });
      return;
    }
    if (key === 'Enter' && event.shiftKey && plain && this.canInsert) {
      // C10: Shift+Enter inserts a record below
      stop(event);
      this.insertNear(pos.row, 'after', field.id);
      return;
    }
    if (key === 'Enter' || key === 'F2') {
      if (!type.editor || readOnly) return;
      stop(event);
      if (!this.editInRecord(pos)) this.startEdit(pos, cell, null);
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
      if (!this.range) return;
      stop(event);
      this.clearSelection();
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
      if (event.shiftKey) this.redo();
      else this.undo();
      return true;
    }
    if (letter === 'y' && event.ctrlKey && !event.shiftKey) {
      stop(event);
      this.redo();
      return true;
    }
    if (letter === 'd' && !event.shiftKey) {
      // also keeps the browser from bookmarking the page
      stop(event);
      this.fill();
      return true;
    }
    if (letter === 'r' && !event.shiftKey) {
      // C11: also keeps the browser from reloading the page
      stop(event);
      this.fillRightSelection();
      return true;
    }
    if (letter === 'a' && !event.shiftKey) {
      // every cell; focus stays where it is
      stop(event);
      this.anchor = { row: 0, col: 0 };
      this.head = {
        row: this.args.records.length - 1,
        col: this.visibleFields.length - 1
      };
      this.rangeKind = 'cells';
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
    const records = this.args.records.length;
    const lastCol = this.visibleFields.length - 1;
    let target: Pos;
    if (command && key in ARROW_DIRECTIONS) {
      const direction = ARROW_DIRECTIONS[key as keyof typeof ARROW_DIRECTIONS];
      target = edgeTarget(this.context, pos, direction);
    } else if (event.shiftKey && (key === 'Home' || key === 'End')) {
      target =
        key === 'Home'
          ? { row: command ? 0 : pos.row, col: 0 }
          : { row: command ? records - 1 : pos.row, col: lastCol };
    } else if ((key === 'PageDown' || key === 'PageUp') && !command) {
      const page = this.pageRows();
      const last = event.shiftKey ? records - 1 : this.rowCount - 1;
      target = {
        row: clamp(pos.row + (key === 'PageDown' ? page : -page), 0, last),
        col: pos.col
      };
    } else {
      return false;
    }
    stop(event);
    if (!records || target.row < 0) return true;
    this.moveFocus(target, event.shiftKey && !this.isAddRow(pos.row));
    return true;
  }

  /**
   * Focuses `target`, which may not be rendered (the grid scrolls to it):
   * the range is set here, so the focus that comes later keeps it.
   */
  moveFocus(target: Pos, extend: boolean): void {
    if (extend && this.anchor && !this.isAddRow(target.row)) {
      this.head = target;
    } else {
      this.anchor = target;
      this.head = target;
    }
    this.rangeKind = 'cells';
    // onFocusIn sees the cell it already knows and keeps the range
    this.domCursor = target;
    this.focusGridCell(target);
  }

  /** The rows fully in view: what PageUp and PageDown move by (at least 1). */
  pageRows(): number {
    const bounds = this.scrollBounds();
    if (!bounds || !this.wrapper) return 1;
    const rows = new Set<string>();
    for (const cell of this.wrapper.querySelectorAll<HTMLElement>(
      '[role=gridcell][data-gridcell-visible-row-index]'
    )) {
      if (cell.classList.contains('euiDataGridFooterCell')) continue;
      const row = cell.dataset['gridcellVisibleRowIndex']!;
      if (rows.has(row)) continue;
      const box = cell.getBoundingClientRect();
      if (box.top >= bounds.top - 1 && box.bottom <= bounds.bottom + 1) {
        rows.add(row);
      }
    }
    return Math.max(1, rows.size);
  }

  /**
   * C13: with row numbers, Home and Ctrl+Home on a data cell land on the
   * first field (the grid would go to the row-number column).
   */
  handleHomeKey(event: KeyboardEvent, row: number): boolean {
    if (event.key !== 'Home' || !this.colOffset) return false;
    if (event.altKey || event.shiftKey || event.metaKey) return false;
    stop(event);
    this.focusGridCell({ row: event.ctrlKey ? 0 : row, col: 0 });
    // Home also scrolls to the left edge (the frozen field is in view anyway)
    if (this.frozenCount) this.scrollLeftBeforeFocus = 0;
    return true;
  }

  /** The add row: Enter inserts; Space, typing and Delete do nothing (V02-DESIGN.md 5.5). */
  onAddRowKeyDown(event: KeyboardEvent): void {
    const plain = !event.ctrlKey && !event.metaKey && !event.altKey;
    if (event.key === 'Enter' && plain) {
      stop(event);
      this.appendRecord();
      return;
    }
    if (event.key === ' ' && plain) stop(event);
  }

  /** Keys of a row-number cell (V02-DESIGN.md 5.5). */
  onRowNumberKeyDown(event: KeyboardEvent, row: number): void {
    if (this.handleCommandKey(event)) return;
    if (this.isAddRow(row)) {
      this.onAddRowKeyDown(event);
      return;
    }
    const record = this.recordAt(row);
    if (record === undefined) return;
    const plain = !event.ctrlKey && !event.metaKey && !event.altKey;
    if (isMenuKey(event)) {
      stop(event);
      const cell = this.rowNumberElement(row);
      if (cell) this.openMenuAt(row, null, cell);
      return;
    }
    if (event.key === ' ' && plain) {
      stop(event);
      this.toggleChecked(row, event.shiftKey);
      return;
    }
    if (event.key === 'Enter' && plain && !event.shiftKey) {
      stop(event);
      const recordId = this.args.getRecordId(record);
      this.expandRecord(recordId, { recordId, fieldId: null });
      return;
    }
    if ((event.key === 'Delete' || event.key === 'Backspace') && this.range) {
      stop(event);
      this.clearSelection();
    }
  }

  /** Delete and Backspace: the range's writable cells get their empty value. */
  clearSelection(): void {
    const range = this.range;
    if (!range) return;
    this.emit(clearRange(this.context, range), this.touchedIn(range, true));
  }

  /** Ctrl/Cmd+R: fill the range right, or the cell from the one to its left. */
  fillRightSelection(): void {
    const range = this.range;
    if (!range || range.top >= this.args.records.length) return;
    const targets =
      range.right > range.left ? { ...range, left: range.left + 1 } : range;
    this.emit(fillRight(this.context, range), this.touchedIn(targets, true));
  }

  /** Ctrl/Cmd+D: fill the range down, or the cell from the one above. */
  fill(): void {
    const range = this.range;
    if (!range || range.top >= this.args.records.length) return;
    // the cells written: below the top row, or the row itself (from above)
    const targets =
      range.bottom > range.top ? { ...range, top: range.top + 1 } : range;
    this.emit(fillDown(this.context, range), this.touchedIn(targets, true));
  }

  /* -------------------------------------------------------------------- */
  /* Undo and redo                                                         */
  /* -------------------------------------------------------------------- */

  /** What undo and redo need besides the records: every field id, visible and hidden (a restored record's values). */
  get historyOptions(): {
    fieldIds: string[];
    equals: (fieldId: string, a: unknown, b: unknown) => boolean;
  } {
    return {
      fieldIds: this.allFields.map((field) => field.id),
      equals: (fieldId, a, b) => this.valueEquals(fieldId, a, b)
    };
  }

  /**
   * Emits the inverse of the last entry, without the cells changed since,
   * and clears the texts it rejected. `focus: false` keeps DOM focus where
   * it is (the expanded record's form).
   */
  undo({ focus = true }: { focus?: boolean } = {}): void {
    if (this.args.readOnly) return;
    const entry = this.undoStack.pop();
    if (!entry) return;
    this.redoStack.push(entry);
    // a resolve or upload still running for it is dropped (V02-RESULTS, batch 5)
    this.endCallsOf(entry);
    const applied = this.applyHistory(
      undoChangeSet(
        entry.changeSet,
        this.args.records,
        this.args.getRecordId,
        this.historyOptions
      ),
      entry,
      'undo',
      focus
    );
    // none of its records is in @records (another page of the owner's
    // data): skipped, and kept on the stack for when they are back (7.3)
    if (!applied && !this.touchesRecords(entry)) {
      this.redoStack.pop();
      this.undoStack.push(entry);
    }
  }

  /**
   * Emits the last undone entry again, without the cells changed since,
   * and shows its rejected texts again.
   */
  redo({ focus = true }: { focus?: boolean } = {}): void {
    if (this.args.readOnly) return;
    const entry = this.redoStack.pop();
    if (!entry) return;
    this.undoStack.push(entry);
    const applied = this.applyHistory(
      redoChangeSet(
        entry.changeSet,
        this.args.records,
        this.args.getRecordId,
        this.historyOptions
      ),
      entry,
      'redo',
      focus
    );
    if (!applied && !this.touchesRecords(entry)) {
      this.undoStack.pop();
      this.redoStack.push(entry);
    }
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
    this.rangeKind = 'cells';
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
    const remapEntry = (entry: HistoryEntry): HistoryEntry => ({
      changeSet: remapChangeSet(entry.changeSet, map),
      rejections: remapRejections(entry.rejections, (id) => remapId(id, map))
    });
    const remapTracked = (entry: HistoryEntry): HistoryEntry => {
      const next = remapEntry(entry);
      this.replaceEntry(entry, next);
      return next;
    };
    this.undoStack = this.undoStack.map(remapTracked);
    this.redoStack = this.redoStack.map(remapTracked);
    if (this.pendingCells.size) {
      const next = new Map<string, PendingEntry>();
      for (const [key, entry] of this.pendingCells) {
        const cell = entry.cell;
        if (!cell) {
          const at = key.indexOf('\u0000');
          const id = String(remapId(key.slice(0, at), map));
          next.set(cellKey(id, key.slice(at + 1)), entry);
          continue;
        }
        const id = remapId(cell.recordId ?? cell.tempId!, map);
        const moved: PendingCell = { ...cell, recordId: id };
        delete moved.tempId;
        next.set(cellKey(id, cell.fieldId), { ...entry, cell: moved });
      }
      this.pendingCells = next;
    }
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
    if ([...this.checkedIds].some((id) => map.has(id))) {
      this.setChecked(
        new Set([...this.checkedIds].map((id) => String(remapId(id, map))))
      );
    }
    if (this.localExpandedId !== null) {
      this.localExpandedId = remapId(this.localExpandedId, map);
    }
    if (this.expandedFrom) {
      this.expandedFrom = {
        ...this.expandedFrom,
        recordId: remapId(this.expandedFrom.recordId, map)
      };
    }
    // a `@records` that only carries the new ids is not a change of rows
    this.lastIds = this.lastIds.map((id) => String(remapId(id, map)));
    const deletes = [...this.pendingOwn.deletes].map((id) =>
      String(remapId(id, map))
    );
    this.pendingOwn = { ...this.pendingOwn, deletes: new Set(deletes) };
  }

  /**
   * Emits an undo or redo (if anything is left of it), clears (undo) or
   * restores (redo) the entry's rejected texts, and selects what changed.
   * An entry with only rejections emits nothing: the data does not change.
   */
  /**
   * Whether a record the entry changed, inserted or deleted is in
   * `@records`. An entry with none (the owner shows another page or query)
   * is kept on its stack when undo or redo finds nothing to do.
   */
  touchesRecords(entry: HistoryEntry): boolean {
    const { changeSet } = entry;
    const ids = new Set(
      this.args.records.map((record) => String(this.args.getRecordId(record)))
    );
    return (
      changeSet.patches.some((patch) => ids.has(String(patch.recordId))) ||
      changeSet.inserts.some((insert) => ids.has(insert.tempId)) ||
      (changeSet.deletes ?? []).some((id) => ids.has(String(id))) ||
      entry.rejections.some((rejection) => ids.has(String(rejection.id)))
    );
  }

  /** Returns whether it emitted a change set or changed the rejected texts shown. */
  applyHistory(
    changeSet: ChangeSet | null,
    entry: HistoryEntry,
    direction: 'undo' | 'redo',
    focus: boolean
  ): boolean {
    const before = this.args.records.length;
    let shown: Rejection[] = [];
    if (direction === 'undo' && entry.rejections.length) {
      const next = clearRejections(this.rejections, entry.rejections);
      if (next) {
        shown = entry.rejections.filter(
          (rejection) => !next.has(cellKey(rejection.id, rejection.fieldId))
        );
        this.rejections = next;
      }
    }
    if (changeSet) {
      this.emit(
        changeSet,
        changeSet.patches.map((patch) => ({
          id: patch.recordId,
          fieldId: patch.fieldId
        }))
      );
    }
    if (direction === 'redo' && entry.rejections.length) {
      // after emit: the owner may have put back the rows they are on
      const byId = new Map(
        this.args.records.map((record) => [
          String(this.args.getRecordId(record)),
          record
        ])
      );
      const next = restoreRejections(
        this.rejections,
        entry.rejections,
        (id, fieldId) => ({
          found: byId.has(id),
          value: valueOf(byId.get(id), fieldId)
        })
      );
      if (next) {
        shown = entry.rejections.filter((rejection) =>
          next.has(cellKey(rejection.id, rejection.fieldId))
        );
        this.rejections = next;
      }
    }
    if (!changeSet && !shown.length) return false;
    this.selectChanged(
      changeSet ?? { ...EMPTY_CHANGE_SET, source: direction },
      before,
      shown.map((rejection) => ({
        id: rejection.id,
        fieldId: rejection.fieldId
      })),
      focus
    );
    return true;
  }

  /**
   * Selects the bounding box of the patched cells and focuses its top-left
   * cell. Only rows that exist both before and after the change are used:
   * inserted rows are rendered only on the next render, and the grid throws
   * for a row past its last one. A change that only inserts (an undone
   * delete) focuses the first inserted record once it is rendered.
   */
  selectChanged(
    changeSet: ChangeSet,
    rowsBefore: number,
    extraCells: Touched = [],
    focusCell = true
  ): void {
    // the owner's records after it applied the change set, if it did at once
    const records = this.args.records;
    const rows = Math.min(rowsBefore, records.length);
    const indexOf = new Map(
      records.map((record, i) => [String(this.args.getRecordId(record)), i])
    );
    let box: Range | null = null;
    const cells: Touched = [
      ...changeSet.patches.map((patch) => ({
        id: patch.recordId,
        fieldId: patch.fieldId
      })),
      ...extraCells
    ];
    for (const { id, fieldId } of cells) {
      const row = indexOf.get(String(id));
      const col = this.visibleFields.findIndex((field) => field.id === fieldId);
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
      if (!field || !focusCell) return;
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
    if (!focusCell) return;
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
    if (!this.isRangeTarget(target)) return;
    const range = this.range;
    if (!range || !event.clipboardData) return;
    event.clipboardData.setData(
      'text/plain',
      toTsv(rangeMatrix(this.context, range))
    );
    // stopPropagation is required: the grid's document copy handlers
    stop(event);
  }

  /**
   * Ctrl/Cmd+X (V02-DESIGN.md 8.4): copies the range as TSV, like copy,
   * then clears it (source 'cut'). A cut is a write of every writable cell
   * even when nothing changes, so a pending resolve there is dropped. With
   * `@readOnly` it only copies.
   */
  @action
  onCut(event: ClipboardEvent): void {
    const target = event.target;
    if (this.editing && this.isInEditor(target)) return;
    if (!this.isRangeTarget(target)) return;
    const range = this.range;
    if (!range || !event.clipboardData) return;
    event.clipboardData.setData(
      'text/plain',
      toTsv(rangeMatrix(this.context, range))
    );
    // stopPropagation: the grid's document clipboard handlers
    stop(event);
    if (this.args.readOnly) return;
    this.emit(
      clearRange(this.context, range, { source: 'cut' }),
      this.touchedIn(range, true)
    );
  }

  @action
  onPaste(event: ClipboardEvent): void {
    if (this.args.readOnly) return;
    const target = event.target;
    if (this.editing && this.isInEditor(target)) return;
    if (!this.isRangeTarget(target)) return;
    const data = event.clipboardData;
    if (!data) return;
    // files on an attachment cell: uploaded to the range's first cell. A
    // spreadsheet's copy carries a picture of the cells besides its text
    // and HTML: then the text wins.
    const plain = data.getData('text/plain');
    const types = Array.from(data.types);
    if (
      data.files?.length &&
      (!plain.trim() || !types.includes('text/html')) &&
      this.range &&
      this.pasteFiles(data.files)
    ) {
      stop(event);
      return;
    }
    if (!Array.from(data.types).includes('text/plain')) return;
    const range = this.range;
    if (!range) return;
    stop(event);
    const anchor = { row: range.top, col: range.left };
    // a block that fits the selection a whole number of times fills it
    let matrix = tileMatrix(
      parseTsv(data.getData('text/plain')),
      range.bottom - range.top + 1,
      range.right - range.left + 1
    );
    // without inserting, lines past the last record are dropped (5.8)
    if (!this.canInsert) {
      matrix = matrix.slice(
        0,
        Math.max(this.args.records.length - anchor.row, 0)
      );
      if (!matrix.length) return;
    }
    const width = Math.max(...matrix.map((line) => line.length));
    const pasted = {
      top: anchor.row,
      left: anchor.col,
      bottom: anchor.row + matrix.length - 1,
      right: Math.min(anchor.col + width - 1, this.visibleFields.length - 1)
    };
    const touched = this.touchedIn(pasted, false);
    if (this.args.onResolve) {
      // V9: the synchronous part at once, the resolved part later
      const plan = planPaste(this.context, anchor, matrix, { nextTempId });
      const entry = this.emit(plan.changeSet, touched);
      this.startResolve(plan, entry);
    } else {
      this.emit(
        pasteMatrix(this.context, anchor, matrix, { nextTempId }),
        touched
      );
    }
    // no setFocusedCell: inserted rows exist only after the next render
    this.anchor = anchor;
    this.head = { row: pasted.bottom, col: pasted.right };
    this.rangeKind = 'cells';
  }

  /**
   * Whether a clipboard event is on the range: a data cell, a row number
   * while whole rows are selected, a header while whole columns are.
   */
  isRangeTarget(target: EventTarget | null): boolean {
    const cell = this.dataCell(target);
    if (cell) return this.isClipboardTarget(target, cell);
    const rowCell = this.rowNumberCell(target);
    if (rowCell) {
      return (
        this.rangeKind === 'rows' && this.isClipboardTarget(target, rowCell)
      );
    }
    const header = this.headerCell(target);
    if (header) {
      return (
        this.rangeKind === 'columns' && this.isClipboardTarget(target, header)
      );
    }
    return false;
  }

  @action
  onScroll(event: Event): void {
    // the editor scrolling its own content is not a grid scroll
    if (this.isInEditor(event.target)) return;
    const target = event.target;
    if (
      target instanceof HTMLElement &&
      target.classList.contains('euiDataGrid__virtualized')
    ) {
      const scrolledX = target.scrollLeft > 0;
      if (scrolledX !== this.scrolledX) this.scrolledX = scrolledX;
      // a key's focus move restored its scroll in the same task; a later
      // scroll (wheel, scrollbar) must not be undone by a stale value
      if (!this.pressing) this.scrollLeftBeforeFocus = null;
    }
    // an editor whose cell is still fully in view follows it (the grid's
    // scroll that brings a just-focused cell into view arrives a frame
    // later); else it saves and closes, before a stale position shows and
    // before the re-mounted focused cell can pull focus
    const editing = this.editing;
    if (editing) {
      const cell = this.cellInView(editing.pos);
      const rect = cell && this.rectOf(cell);
      if (rect) editing.rect = rect;
      else this.commit({ refocus: false });
    }
    // the catcher follows its cell the same way (the far column's late
    // scroll comes between a dead key and its character); out of view it
    // ends, and focus does not stay on a hidden input
    const imePos = this.imePos;
    if (imePos) {
      const cell = this.cellInView(imePos);
      const rect = cell && this.rectOf(cell);
      if (rect) {
        this.placeIme(rect);
      } else if (!this.imeComposing) {
        const input = this.imeInput;
        this.endIme();
        input?.blur();
      }
    }
    if (this.menu) this.closeMenu(false);
    this.layoutTick++;
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
    const upload = uploadOf(field);
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
    this.draftKind = 'text';
    this.draftValue = undefined;
    if (upload) {
      this.editing.onUpload = (files) =>
        this.uploadFiles(recordId, field, files);
    }
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
    const touched = [{ id: editing.recordId, fieldId: editing.field.id }];
    if (result && 'value' in result) {
      this.emit(commitValue(ctx, pos, result.value), touched);
    } else if (result && 'text' in result) {
      this.emitText(ctx, pos, result.text, touched);
    } else if (this.draftDirty && this.draftKind === 'value') {
      this.emit(commitValue(ctx, pos, this.draftValue), touched);
    } else if (this.draftDirty) {
      this.emitText(ctx, pos, this.draft, touched);
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
    this.draftKind = 'text';
  };

  onDraftValue = (value: unknown): void => {
    this.draftValue = value;
    this.draftDirty = true;
    this.draftKind = 'value';
  };

  /** The editor's `@onSave`: saves a value and keeps it open. */
  onEditorSave = (value: unknown): void => {
    const editing = this.editing;
    if (!editing) return;
    const row = this.rowOf(editing.recordId, editing.pos.row);
    if (row < 0) return;
    this.emit(commitValue(this.context, { row, col: editing.pos.col }, value), [
      { id: editing.recordId, fieldId: editing.field.id }
    ]);
  };

  /**
   * A typed text: with `@onResolve`, a text the type answers `{ unresolved }`
   * for is pending and resolved (`planCommit`); else `commitText`.
   */
  emitText(
    ctx: SheetContext<T>,
    pos: Pos,
    text: string,
    touched: Touched
  ): void {
    if (!this.args.onResolve) {
      this.emit(commitText(ctx, pos, text), touched);
      return;
    }
    const plan = planCommit(ctx, pos, text);
    const entry = this.emit(plan.changeSet, touched);
    this.startResolve(plan, entry);
  }

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
  emit(
    changeSet: ChangeSet | null,
    touched: Touched,
    options: { mergeInto?: HistoryEntry | null } = {}
  ): HistoryEntry | null {
    const next = new Map(this.rejections);
    let changed = false;
    for (const { id, fieldId } of touched) {
      if (next.delete(cellKey(id, fieldId))) changed = true;
    }
    // a newer write to a pending cell discards its result
    this.dropPending(
      touched.map(({ id, fieldId }) => cellKey(id, fieldId)),
      changeSet?.deletes ?? []
    );
    if (changeSet?.deletes?.length) {
      // the removed records' texts and checkboxes go with them
      const gone = new Set(changeSet.deletes.map(String));
      if ([...gone].some((id) => this.checkedIds.has(id))) {
        this.setChecked(
          new Set([...this.checkedIds].filter((id) => !gone.has(id)))
        );
      }
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
    const stored: Rejection[] = [];
    if (changeSet) {
      const byId = new Map(
        this.args.records.map((record) => [
          String(this.args.getRecordId(record)),
          record
        ])
      );
      for (const rejection of changeSet.rejected) {
        const id = String(rejection.recordId ?? rejection.tempId);
        const entry: Rejection = {
          id,
          fieldId: rejection.fieldId,
          text: rejection.text,
          message: rejection.message,
          seenValue: valueOf(byId.get(id), rejection.fieldId)
        };
        next.set(cellKey(id, rejection.fieldId), entry);
        stored.push(entry);
        changed = true;
      }
    }
    if (changed) this.rejections = next;
    if (!changeSet) return null;
    const entry = this.recordHistory(changeSet, stored, options.mergeInto);
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
    return entry;
  }

  /**
   * A user action's change set becomes an undo entry (not an undo or redo,
   * and not one with only new options), with the rejections it stored: a
   * paste whose every cell was rejected is undone too. A new entry clears
   * the redo stack. A bulk resolve (`'resolve'`) joins the last entry, the
   * paste that asked for it, so one undo reverts both.
   */
  recordHistory(
    changeSet: ChangeSet,
    rejections: Rejection[],
    mergeInto?: HistoryEntry | null
  ): HistoryEntry | null {
    if (changeSet.source === 'undo' || changeSet.source === 'redo') {
      return null;
    }
    if (
      !changeSet.patches.length &&
      !changeSet.inserts.length &&
      !changeSet.deletes?.length &&
      !rejections.length
    ) {
      return null;
    }
    const remap = (id: RecordId) => remapId(id, this.remapped);
    const entry: HistoryEntry = {
      changeSet: remapChangeSet(changeSet, this.remapped),
      rejections: remapRejections(rejections, remap)
    };
    // a resolve joins the entry of the paste or edit that asked for it
    const index = mergeInto ? this.undoStack.indexOf(mergeInto) : -1;
    if (entry.changeSet.source === 'resolve' && index >= 0) {
      const target = this.undoStack[index]!;
      // a resolved text is no longer a rejection of that entry
      const written = new Set(
        entry.changeSet.patches.map((patch) =>
          cellKey(patch.recordId, patch.fieldId)
        )
      );
      const merged: HistoryEntry = {
        changeSet: mergeChangeSets(target.changeSet, entry.changeSet),
        rejections: [
          ...target.rejections.filter(
            (rejection) =>
              !written.has(cellKey(rejection.id, rejection.fieldId))
          ),
          ...entry.rejections
        ]
      };
      this.undoStack[index] = merged;
      this.replaceEntry(target, merged);
      return merged;
    }
    this.undoStack.push(entry);
    if (this.undoStack.length > HISTORY_LIMIT) this.undoStack.shift();
    this.redoStack = [];
    return entry;
  }

  /** A history entry was replaced (merged, remapped): calls that point at it follow. */
  replaceEntry(from: HistoryEntry, to: HistoryEntry): void {
    for (const call of this.pendingCalls.values()) {
      if (call.entry === from) call.entry = to;
    }
  }

  /* -------------------------------------------------------------------- */
  /* Bulk resolve and uploads (V02-DESIGN.md 8.1, 8.2)                     */
  /* -------------------------------------------------------------------- */

  /**
   * Stores a plan's pending cells (after its synchronous change set was
   * emitted: that emit's `touched` covers them) and calls `@onResolve`
   * once, one request per field.
   */
  startResolve(plan: ResolvePlan<T>, entry: HistoryEntry | null): void {
    const onResolve = this.args.onResolve;
    if (!onResolve || !plan.pending.length) return;
    const token = {};
    const controller = new AbortController();
    const next = new Map(this.pendingCells);
    for (const cell of plan.pending) {
      next.set(cellKey(cell.recordId ?? cell.tempId!, cell.fieldId), {
        text: cell.text,
        token,
        cell
      });
    }
    this.pendingCells = next;
    this.pendingCalls.set(token, {
      kind: 'resolve',
      controller,
      waiter: resolveWaiter.beginAsync(),
      entry
    });
    let result: Promise<ResolveResult>;
    try {
      result = Promise.resolve(
        onResolve(plan.requests, { signal: controller.signal })
      );
    } catch (error) {
      result = Promise.reject(
        error instanceof Error ? error : new Error(String(error))
      );
    }
    result.then(
      (answers) => this.finishResolve(token, answers),
      () => this.finishResolve(token, null)
    );
  }

  /**
   * Writes the cells still pending under `token`: the resolved values (a
   * second change set, source 'resolve', merged into the paste's undo
   * entry), or, when the call failed (`null`), a rejection per cell.
   */
  finishResolve(token: object, answers: ResolveResult | null): void {
    const call = this.pendingCalls.get(token);
    if (!call || this.isDestroying || this.isDestroyed) return;
    const cells: PendingCell[] = [];
    const next = new Map(this.pendingCells);
    for (const [key, entry] of this.pendingCells) {
      if (entry.token !== token || !entry.cell) continue;
      cells.push(entry.cell);
      next.delete(key);
    }
    this.pendingCells = next;
    const mergeInto = call.entry;
    this.endCall(token, false);
    if (!cells.length) return;
    let changeSet: ChangeSet | null;
    if (answers) {
      changeSet = resolveCells(
        { ...this.context, fields: this.allFields },
        cells,
        answers
      );
    } else {
      changeSet = {
        source: 'resolve',
        patches: [],
        inserts: [],
        rejected: cells.map((cell) => {
          const message = this.messages.unresolved(cell.text);
          return cell.recordId !== undefined
            ? {
                recordId: cell.recordId,
                fieldId: cell.fieldId,
                text: cell.text,
                message
              }
            : {
                tempId: cell.tempId!,
                fieldId: cell.fieldId,
                text: cell.text,
                message
              };
        }),
        newOptions: []
      };
    }
    this.emit(
      changeSet,
      cells.map((cell) => ({
        id: cell.recordId ?? cell.tempId!,
        fieldId: cell.fieldId
      })),
      { mergeInto }
    );
  }

  /** Ends a call and its test waiter; aborts its signal unless it settled (`abort: false`). */
  endCall(token: object, abort = true): void {
    const call = this.pendingCalls.get(token);
    if (!call) return;
    this.pendingCalls.delete(token);
    if (abort) call.controller.abort();
    resolveWaiter.endAsync(call.waiter);
  }

  /** Ends the calls an undone entry asked for, and drops their cells. */
  endCallsOf(entry: HistoryEntry): void {
    const tokens = [...this.pendingCalls]
      .filter(([, call]) => call.entry === entry)
      .map(([token]) => token);
    if (!tokens.length) return;
    const next = new Map(this.pendingCells);
    for (const [key, pending] of this.pendingCells) {
      if (tokens.includes(pending.token)) next.delete(key);
    }
    this.pendingCells = next;
    for (const token of tokens) this.endCall(token);
  }

  /**
   * Drops pending resolve cells (by cellKey, or every cell of a record id);
   * a call none of whose cells is left pending is ended (its signal
   * aborted). Uploads are kept.
   */
  dropPending(
    keys: readonly string[],
    recordIds: readonly RecordId[] = []
  ): void {
    if (!this.pendingCells.size) return;
    const ids = new Set(recordIds.map(String));
    let next: Map<string, PendingEntry> | null = null;
    for (const [key, entry] of this.pendingCells) {
      // an upload is not undone by a write: its files are appended to the value then
      if (!entry.cell) continue;
      const id = String(entry.cell.recordId ?? entry.cell.tempId);
      if (!keys.includes(key) && !ids.has(id)) continue;
      next ??= new Map(this.pendingCells);
      next.delete(key);
    }
    if (!next) return;
    this.pendingCells = next;
    const live = new Set([...next.values()].map((entry) => entry.token));
    for (const [token, call] of [...this.pendingCalls]) {
      if (call.kind === 'resolve' && !live.has(token)) this.endCall(token);
    }
  }

  /** Files pasted on an attachment cell: uploaded to the range's first cell. True when handled. */
  pasteFiles(files: FileList): boolean {
    const range = this.range;
    if (!range) return false;
    const record = this.recordAt(range.top);
    const field = this.visibleFields[range.left];
    if (record === undefined || !field || !uploadOf(field)) return false;
    if (isReadOnly(this.context, field, record)) return true;
    void this.uploadFiles(this.args.getRecordId(record), field, [...files], {
      rejectOnFailure: true
    }).catch(() => undefined);
    return true;
  }

  /**
   * One upload pipeline for the editor, a drop and pasted files:
   * `field.upload(files, { record, field, signal })`, the cell pending
   * meanwhile, then the new files appended to the value read at that time
   * (`commitValue`, source 'edit'). On failure the promise rejects and,
   * with `rejectOnFailure`, the cell gets a rejection (`uploadFailed`).
   * Files past `maxFiles` are not uploaded.
   */
  uploadFiles(
    recordId: RecordId,
    field: EuiSheetField,
    files: File[],
    options: { rejectOnFailure?: boolean } = {}
  ): Promise<void> {
    const upload = uploadOf(field);
    const record = this.args.records[this.rowOf(recordId, 0)];
    if (!upload || record === undefined || !files.length) {
      return Promise.resolve();
    }
    const maxFiles = (field as UploadField).maxFiles;
    const current = valueOf(record, field.id);
    const room =
      maxFiles === undefined
        ? files.length
        : maxFiles - (Array.isArray(current) ? current.length : 0);
    const chosen = files.slice(0, Math.max(0, room));
    if (!chosen.length) return Promise.resolve();
    const token = {};
    const controller = new AbortController();
    const key = cellKey(recordId, field.id);
    const next = new Map(this.pendingCells);
    next.set(key, { text: null, token });
    this.pendingCells = next;
    this.pendingCalls.set(token, {
      kind: 'upload',
      controller,
      waiter: resolveWaiter.beginAsync(),
      entry: null
    });
    const settle = (): boolean => {
      const live = this.pendingCalls.has(token);
      if (this.pendingCells.get(key)?.token === token) {
        const rest = new Map(this.pendingCells);
        rest.delete(key);
        this.pendingCells = rest;
      }
      this.endCall(token, false);
      return live && !this.isDestroying && !this.isDestroyed;
    };
    return upload(chosen, { record, field, signal: controller.signal }).then(
      (added) => {
        if (!settle()) return;
        // the value now: another upload may have finished meanwhile
        const row = this.rowOf(recordId, 0);
        const now = this.args.records[row];
        if (now === undefined) return;
        const before = valueOf(now, field.id);
        let value = [...(Array.isArray(before) ? before : []), ...added];
        if (maxFiles !== undefined) value = value.slice(0, maxFiles);
        const ctx = { ...this.context, records: [now], fields: [field] };
        this.emit(commitValue(ctx, { row: 0, col: 0 }, value), [
          { id: recordId, fieldId: field.id }
        ]);
      },
      (error: unknown) => {
        if (!settle()) throw error;
        if (options.rejectOnFailure) {
          this.emit(
            {
              source: 'edit',
              patches: [],
              inserts: [],
              rejected: [
                {
                  recordId,
                  fieldId: field.id,
                  text: chosen.map((file) => file.name).join(', '),
                  message: this.messages.uploadFailed()
                }
              ],
              newOptions: []
            },
            [{ id: recordId, fieldId: field.id }]
          );
        }
        throw error;
      }
    );
  }

  /* Dragging files over an attachment cell */

  /** The attachment cell under a drag with files, if it can take them. */
  dropCellAt(
    target: EventTarget | null
  ): { pos: Pos; record: T; field: EuiSheetField<T> } | null {
    const cell = this.dataCell(target);
    if (!cell) return null;
    const pos = this.cursor(cell);
    const record = this.recordAt(pos.row);
    const field = this.visibleFields[pos.col];
    if (record === undefined || !field || !uploadOf(field)) return null;
    if (isReadOnly(this.context, field, record)) return null;
    return { pos, record, field };
  }

  @action
  onDragOver(event: DragEvent): void {
    if (!hasFiles(event)) return;
    const target = this.dropCellAt(event.target);
    if (!target) {
      if (this.dropPos) this.dropPos = null;
      return;
    }
    event.preventDefault();
    if (event.dataTransfer) event.dataTransfer.dropEffect = 'copy';
    if (!samePos(this.dropPos, target.pos)) this.dropPos = target.pos;
  }

  @action
  onDragLeave(event: DragEvent): void {
    const to = event.relatedTarget;
    if (to instanceof Node && this.wrapper?.contains(to)) return;
    if (this.dropPos) this.dropPos = null;
  }

  @action
  onDrop(event: DragEvent): void {
    if (!hasFiles(event)) return;
    this.dropPos = null;
    const target = this.dropCellAt(event.target);
    if (!target) return;
    event.preventDefault();
    event.stopPropagation();
    const files = [...(event.dataTransfer?.files ?? [])];
    void this.uploadFiles(
      this.args.getRecordId(target.record),
      target.field,
      files,
      { rejectOnFailure: true }
    ).catch(() => undefined);
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
        {{if this.dragging 'euiSheet--dragging'}}
        {{if this.fillTarget 'euiSheet--dragging euiSheet--filling'}}
        {{if this.scrolledX 'euiSheet--scrolledX'}}"
      data-test-subj="euiSheet"
      ...attributes
      {{this.setupWrapper}}
      {{this.watchRecords @records}}
      {{this.registerSheetApi}}
      {{on "keydown" this.onKeyDown capture=true}}
      {{on "copy" this.onCopy capture=true}}
      {{on "cut" this.onCut capture=true}}
      {{on "paste" this.onPaste capture=true}}
      {{on "scroll" this.onScroll capture=true}}
      {{on "mousedown" this.onMouseDown capture=true}}
      {{on "pointerdown" this.onPointerDown capture=true}}
      {{on "pointermove" this.onPointerMove}}
      {{on "pointerup" this.onPointerEnd}}
      {{on "pointercancel" this.onPointerEnd}}
      {{on "click" this.onClickCapture capture=true}}
      {{on "focusin" this.onFocusIn}}
      {{on "focusout" this.onFocusOut}}
      {{on "mouseover" this.onMouseOver}}
      {{on "click" this.onClick}}
      {{on "dblclick" this.onDoubleClick}}
      {{on "contextmenu" this.onContextMenu}}
      {{on "dragover" this.onDragOver capture=true}}
      {{on "dragleave" this.onDragLeave}}
      {{on "drop" this.onDrop capture=true}}
    >
      {{#if (has-block "toolbar")}}
        <div class="euiSheet__toolbar" data-test-subj="euiSheetToolbar">
          {{yield this.blockApi to="toolbar"}}
        </div>
      {{/if}}
      <div class="euiSheet__grid" style={{this.frozenStyle}}>
        {{#if @isLoading}}
          <EuiProgress
            @size="xs"
            @position="absolute"
            @color="primary"
            class="euiSheet__loading"
            data-test-subj="euiSheetLoading"
          />
        {{/if}}
        <EuiDataGrid
          aria-label={{this.ariaLabel}}
          @columns={{this.columns}}
          @columnVisibility={{this.columnVisibility}}
          @leadingControlColumns={{this.leadingControlColumns}}
          @gridStyle={{this.gridStyle}}
          @rowCount={{this.rowCount}}
          @renderCellValue={{SheetCell}}
          @renderFooterCellValue={{if this.hasSummary SheetFooterCell}}
          @cellContext={{this.cellContext}}
          @registerApi={{this.registerGridApi}}
          @toolbarVisibility={{false}}
          @height={{@height}}
          @sorting={{this.sorting}}
          @rowHeightsOptions={{this.rowHeightsOptions}}
          @onColumnResize={{this.onColumnResize}}
          @virtualizationOptions={{this.virtualizationOptions}}
        >
          <:controlHeaderCell><RowNumberHeader
              @sheet={{this}}
            /></:controlHeaderCell>
          <:controlCell as |cell|>
            <RowNumberCell
              @sheet={{this}}
              @rowIndex={{cell.rowIndex}}
              @setCellProps={{cell.setCellProps}}
            />
          </:controlCell>
          <:controlFooterCell as |cell|>
            <SheetControlFooterCell
              @sheet={{this}}
              @setCellProps={{cell.setCellProps}}
            />
          </:controlFooterCell>
        </EuiDataGrid>
      </div>
      {{#if this.fillHandleRange}}
        <FillHandle
          @sheet={{this}}
          @range={{this.fillHandleRange}}
          @tick={{this.layoutTick}}
          @records={{@records}}
          @rowHeight={{this.rowHeight}}
          @onPress={{this.onFillHandlePress}}
        />
      {{/if}}
      <ImeCatcher @sheet={{this}} />
      {{#if (has-block "footer")}}
        <div class="euiSheet__footer" data-test-subj="euiSheetFooter">
          {{yield this.blockApi to="footer"}}
        </div>
      {{/if}}
      {{#if this.menu}}
        <RowMenu
          @top={{this.menu.top}}
          @left={{this.menu.left}}
          @items={{this.menuItems}}
          @onSelect={{this.onMenuSelect}}
        />
      {{/if}}
      {{#if this.expandedRecordValue}}
        {{#if (isModal this.expandedShell)}}
          <RecordModal @sheet={{this}} @record={{this.expandedRecordValue}} />
        {{else}}
          <RecordFlyout @sheet={{this}} @record={{this.expandedRecordValue}} />
        {{/if}}
      {{/if}}
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
              @onDraftValue={{this.onDraftValue}}
              @onSave={{this.onEditorSave}}
              @onUpload={{editing.onUpload}}
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
