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
import { isDestroyed, isDestroying } from '@ember/destroyable';
import { guidFor } from '@ember/object/internals';
import { cancel, later } from '@ember/runloop';
import { service } from '@ember/service';
import { modifier } from 'ember-modifier';

import EuiDataGrid from '@ember-eui/core/components/eui-data-grid';
import EuiIcon from '@ember-eui/core/components/eui-icon';
import EuiProgress from '@ember-eui/core/components/eui-progress';
import {
  euiClass,
  getEuiThemeContext,
  useEuiBorealisStyles
} from '@ember-eui/core/theming';

import {
  clearRange,
  commitValue,
  createMessages,
  edgeTarget,
  fillDown,
  fillRange,
  fillRight,
  isReadOnly,
  parseTsv,
  pasteMatrix,
  planPaste,
  rangeMatrix,
  tileMatrix,
  toTsv,
  valueOf,
  withoutField
} from '../core/index.ts';
import type { PasteInsert, RowModel } from '../core/index.ts';
import { builtInSheetFieldTypes } from '../field-types.ts';
import AutoScroll from '../-private/auto-scroll.ts';
import FieldEditor, {
  draftOf,
  FIELD_EDITOR_WIDTH
} from '../-private/field-editor.gts';
import FillHandle from '../-private/fill-handle.gts';
import ImeCatcher from '../-private/ime-catcher.gts';
import EditorFrame from '../-private/editor-frame.gts';
import { RecordFlyout, RecordModal } from '../-private/record-shells.gts';
import RangeOutline from '../-private/range-outline.gts';
import RowMenu from '../-private/row-menu.gts';
import ShortcutList from '../-private/shortcut-list.gts';
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
import {
  ADD_FIELD_COLUMN_ID,
  afterRender,
  clamp,
  nextTempId,
  sameIds,
  sameLayout,
  samePos,
  sameRange,
  stop,
  uploadOf
} from '../-private/sheet/util.ts';
import SheetFields from '../-private/sheet/fields.ts';
import SheetGridColumns from '../-private/sheet/grid-columns.ts';
import SheetHeaderMenu from '../-private/sheet/header-menu.ts';
import SheetFrozen from '../-private/sheet/frozen.ts';
import SheetGridOptions from '../-private/sheet/grid-options.ts';
import SheetDom from '../-private/sheet/dom.ts';
import SheetRows from '../-private/sheet/rows.ts';
import SheetGroupHeaders from '../-private/sheet/group-headers.ts';
import SheetChecked from '../-private/sheet/checked.ts';
import SheetCells from '../-private/sheet/cells.ts';
import SheetSelection from '../-private/sheet/selection.ts';
import SheetOutline from '../-private/sheet/outline.ts';
import SheetScroll from '../-private/sheet/scroll.ts';
import SheetIme from '../-private/sheet/ime.ts';
import SheetFocus from '../-private/sheet/focus.ts';
import SheetChanges from '../-private/sheet/changes.ts';
import SheetValidate from '../-private/sheet/validate.ts';
import SheetResolve from '../-private/sheet/resolve.ts';
import SheetUploads from '../-private/sheet/uploads.ts';
import SheetHistory from '../-private/sheet/history.ts';
import SheetRecords from '../-private/sheet/records.ts';

import type {
  ChangeSet,
  EuiSheetField,
  Pos,
  Range,
  RecordId,
  SheetContext,
  SheetFieldDraft,
  SheetGroup,
  SheetMessages
} from '../core/index.ts';
import type { RowMenuItem } from '../-private/row-menu.gts';
import type { LayerAnchor } from '../-private/layer.gts';
import type { ShortcutContext } from '../-private/shortcuts.ts';
import type {
  EuiSheetFieldType,
  EuiSheetSignature,
  SheetApi,
  SheetFieldEditorType,
  SheetBlockApi,
  SheetEditorRect,
  SheetEditorResult
} from '../types.ts';
import type EuiI18n from '@ember-eui/core/services/eui-i18n';
import type { EuiDataGridRefProps } from '@ember-eui/core/utils/data-grid/types';
import type Owner from '@ember/owner';
import type {
  CellView,
  ExpandedFrom,
  HistoryEntry,
  MenuState,
  PendingOwn,
  WrapperBox
} from '../-private/sheet/types.ts';

export type { EuiSheetSignature };
export type { CellView };

/**
 * The open field editor (V03 6.4): what it edits, where it is, and the
 * handler's promise state.
 */
export class FieldEditorState {
  mode: 'create' | 'edit' | 'delete';
  /** The field edited or deleted. */
  fieldId?: string;
  /** Where a created field goes. */
  position?: { index: number; after?: string };
  draft: SheetFieldDraft;
  /** Its anchor, relative to the wrapper: the header (or the header row's right end). */
  anchor: WrapperBox;
  /** The header focused when it closes: by column id, else by grid column index. */
  returnTo: { columnId: string; index: number };
  @tracked isSaving = false;
  @tracked error: string | undefined = undefined;

  constructor(init: {
    mode: FieldEditorState['mode'];
    fieldId?: string;
    position?: FieldEditorState['position'];
    draft: SheetFieldDraft;
    anchor: WrapperBox;
    returnTo: FieldEditorState['returnTo'];
  }) {
    this.mode = init.mode;
    this.fieldId = init.fieldId;
    this.position = init.position;
    this.draft = init.draft;
    this.anchor = init.anchor;
    this.returnTo = init.returnTo;
  }
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
    initialKey: string | null;
    draft: string;
  }) {
    this.pos = init.pos;
    this.recordId = init.recordId;
    this.field = init.field;
    this.type = init.type;
    this.rect = init.rect;
    this.layout = init.layout;
    this.initialKey = init.initialKey;
    this.draft = init.draft;
  }
}

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

/** The types the field editor offers without `@creatableFieldTypes`: the built-ins a draft can fully describe (V03 6.4). */
const CREATABLE_FIELD_TYPES = [
  'text',
  'longText',
  'number',
  'currency',
  'percent',
  'checkbox',
  'singleSelect',
  'multiSelect',
  'date',
  'duration',
  'rating',
  'url',
  'email',
  'phone'
];

/** The message of a rejected field handler: `error.message`, else the value as text. */
function errorMessage(error: unknown): string {
  if (error instanceof Error) return error.message;
  return typeof error === 'string' ? error : String(error);
}

/** A field's type name. */
const typeName = (field: EuiSheetField): string => field.type ?? 'text';

/** Menu items whose action moves focus itself. */
const MENU_ITEMS_THAT_MOVE_FOCUS = new Set([
  'insertAbove',
  'insertBelow',
  'duplicate',
  'expand',
  'delete'
]);

/** The fill handle's drawn size in px: a 10 px square and its 2 px ring (`styles.ts`). */
const FILL_HANDLE_SIZE = 14;

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

function isModal(shell: string): boolean {
  return shell === 'modal';
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

  /* The feature modules (V03C-DESIGN.md 3.2): each owns its state. */
  readonly fields = new SheetFields<T>(this);
  readonly gridColumns = new SheetGridColumns<T>(this);
  readonly headerMenu = new SheetHeaderMenu<T>(this);
  readonly frozen = new SheetFrozen<T>(this);
  readonly gridOptions = new SheetGridOptions<T>(this);
  readonly dom = new SheetDom<T>(this);
  readonly rows = new SheetRows<T>(this);
  readonly groupHeaders = new SheetGroupHeaders<T>(this);
  readonly checked = new SheetChecked<T>(this);
  readonly cells = new SheetCells<T>(this);
  readonly selection = new SheetSelection<T>(this);
  readonly outline = new SheetOutline<T>(this);
  readonly scroll = new SheetScroll<T>(this);
  readonly ime = new SheetIme<T>(this);
  readonly focus = new SheetFocus<T>(this);
  readonly changes = new SheetChanges<T>(this);
  readonly validate = new SheetValidate<T>(this);
  readonly resolve = new SheetResolve<T>(this);
  readonly uploads = new SheetUploads<T>(this);
  readonly history = new SheetHistory<T>(this);
  readonly records = new SheetRecords<T>(this);
  @tracked editing: Editing | null = null;
  /** A drag over other cells is selecting a range (no text selection meanwhile). */
  @tracked dragging = false;
  /** The expanded record without `@onExpandedRecordChange`. */
  @tracked localExpandedId: RecordId | null = null;
  /** The open row menu. */
  @tracked menu: MenuState | null = null;
  /** The shortcut list is open (V03 5.5). */
  @tracked shortcutsOpen = false;
  /** The open field editor (V03 6.4). */
  @tracked fieldEditorState: FieldEditorState | null = null;
  /** Every field id of the last render (`@fields` and `@hiddenFields`) and its type: what `watchFields` compares with. */
  lastFieldTypes: Map<string, string> | null = null;
  /** A created field without `@onFieldOrderChange` goes into the sheet's own order after this field (V03 6.8). */
  createdAfter: { after: string | undefined } | null = null;
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
  /** The last pointer position of a drag, in viewport px. */
  dragPointer: { x: number; y: number } | null = null;
  /** The drags' auto-scroll loop. */
  autoScroll = new AutoScroll({
    bounds: () => this.scroll.scrollBounds(),
    scrollBy: (dx, dy) => this.scroll.scrollGridBy(dx, dy),
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
  /** `@editIn` opened the expanded record to edit this field (8.5). */
  pendingFormEdit: { recordId: RecordId; fieldId: string } | null = null;
  /** Where the expanded record was opened from. */
  expandedFrom: ExpandedFrom | null = null;
  /** What a drag selects: cells, or rows (a press on a row number). */
  dragKind: 'cells' | 'rows' = 'cells';

  /** Plain: the last text (or value) the editor reported, and whether it reported one. */
  draft = '';
  draftDirty = false;
  draftValue: unknown = undefined;
  draftKind: 'text' | 'value' = 'text';

  /** The grid's API (not the sheet's: that is `sheetApi`). */
  gridApi: EuiDataGridRefProps | null = null;
  wrapper: HTMLElement | null = null;

  /** The cell a left-button press started on, while it may become a drag. */
  dragFrom: Pos | null = null;
  /** The press ended a drag: its click is not a click on a cell. */
  suppressClick = false;

  /** Stable object: the grid passes it to every cell renderer. */
  cellContext = { sheet: this as unknown as EuiSheet<object> };
  /** The `@records` of the last render, and their ids. */
  lastRecords: readonly T[] | null = null;
  lastIds: string[] = [];
  /** The row model of that render: the stored positions are its grid rows. */
  lastRowModel: RowModel | null = null;
  /** `@groups` of that render (V03 4.2): what a stored add row or header row belongs to. */
  lastGroups: readonly SheetGroup[] = [];
  lastGroupsArg: readonly SheetGroup[] | undefined = undefined;

  /** The sheet's API for its owner (`@registerApi`): one stable object. */
  sheetApi: SheetApi = {
    undo: () => this.history.undo(),
    redo: () => this.history.redo(),
    focusCell: (cell) => this.selection.focusRecordCell(cell),
    remapIds: (ids) => this.history.remapIds(ids),
    clearHistory: () => this.history.clearHistory(),
    expandRecord: (recordId) => {
      if (recordId === null) this.closeExpanded();
      else this.expandRecord(recordId, null);
    },
    insertRecord: (options = {}) => this.records.insertFromApi(options),
    deleteRecords: (ids) => this.records.deleteRecordIds(ids, false),
    showShortcuts: () => this.showShortcuts(),
    editField: (fieldId) => this.editField(fieldId),
    addField: (options = {}) => this.addField(options.index)
  };

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
    if (this.outline.flashTimer) clearTimeout(this.outline.flashTimer);
    if (this.validate.validateTimer) cancel(this.validate.validateTimer);
    this.validate.validateController?.abort();
    this.validate.endValidateWaiter();
    this.stopWatchingRelease();
    this.stopFillDrag();
    this.autoScroll.stop();
    this.cancelLongPress();
    document.removeEventListener('mousedown', this.onDocumentMouseDown, true);
    for (const token of [...this.resolve.pendingCalls.keys()])
      this.resolve.endCall(token);
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

  /* Blocks (3.6) */

  @cached
  get blockApi(): SheetBlockApi<T> {
    return {
      api: this.sheetApi,
      fields: this.fields.visibleFields,
      hiddenFields: this.fields.hiddenFields,
      sort: this.args.sort ?? [],
      rowHeight: this.gridOptions.rowHeight,
      checkedRecords: this.checked.checkedRecords,
      hideField: this.fields.hideField,
      showField: this.fields.showField,
      setRowHeight: this.gridOptions.setRowHeight,
      setSort: this.gridColumns.setSort,
      showShortcuts: this.showShortcuts,
      addField: () => this.addField(),
      groupBy: this.args.groupBy ?? [],
      groups: this.args.groups ?? [],
      setGroupBy: this.groupHeaders.setGroupBy,
      toggleGroup: this.groupHeaders.toggleGroupByKey
    };
  }

  get hasSummary(): boolean {
    return this.args.summary !== undefined;
  }

  @cached
  get context(): SheetContext<T> {
    return {
      records: this.args.records,
      fields: this.fields.visibleFields,
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

  /** Identifies this sheet's own `<style>` rules. */
  sheetId = guidFor(this);

  /** The class that defines the `--euiSheet-*` colours from the EUI theme. */
  @cached
  get themeClass(): string {
    const context = getEuiThemeContext(this);
    return euiClass(context, useEuiBorealisStyles(context, sheetThemeVars));
  }

  /* -------------------------------------------------------------------- */
  /* Grid wiring                                                           */
  /* -------------------------------------------------------------------- */

  registerGridApi = (api: EuiDataGridRefProps): void => {
    this.gridApi = api;
  };

  /** Gives the owner the sheet's API, once, after the first render. */
  registerSheetApi = modifier(() => {
    afterRender(this, () => this.args.registerApi?.(this.sheetApi));
  });

  setupWrapper = modifier((element: HTMLElement) => {
    this.wrapper = element;
    document.addEventListener('mousedown', this.focus.onPagePress, true);
    document.addEventListener('pointerdown', this.focus.onPagePress, true);
    return () => {
      document.removeEventListener('mousedown', this.focus.onPagePress, true);
      document.removeEventListener('pointerdown', this.focus.onPagePress, true);
      this.wrapper = null;
    };
  });

  /**
   * Whenever `@records` is a new array: schedules a `@validate` run and,
   * after the render, follows the records (`recordsRendered`).
   */
  watchRecords = modifier(
    (_element: HTMLElement, [records, groups]: [unknown, unknown]) => {
      void groups;
      // V03 4.2: `@groups` can change while `@records` stays the same array
      if (records !== this.lastRecords) this.validate.scheduleValidate();
      afterRender(this, () => this.recordsRendered());
    }
  );

  /**
   * After a render with a new `@records` (V02-DESIGN.md 3.2, 3.3). A change
   * that is not the sheet's own (the owner re-sorted, re-queried, reloaded)
   * moves the selection, focus and an open editor to their record; then a
   * pending focus whose record is now rendered is applied.
   */
  recordsRendered(): void {
    const records = this.args.records;
    if (records === this.lastRecords) {
      if (this.args.groups !== this.lastGroupsArg) this.groupsRendered();
      return;
    }
    const previous = this.lastRecords;
    const previousIds = this.lastIds;
    const previousModel = this.lastRowModel;
    const previousGroups = this.lastGroups;
    const ids = records.map((record) => String(this.args.getRecordId(record)));
    const pending = this.changes.pendingOwn;
    this.lastRecords = records;
    this.lastIds = ids;
    this.lastRowModel = this.rows.rowModel;
    this.lastGroups = this.rows.groups;
    this.lastGroupsArg = this.args.groups;
    this.changes.pendingOwn = { deletes: new Set(), inserts: 0 };
    // grouped, the rows moved: what holds grid rows across renders ends (V03 7.4)
    const regrouped =
      !!previousModel &&
      (previousGroups.length > 0 || this.rows.isGrouped) &&
      !sameLayout(
        previousModel,
        previousGroups,
        this.rows.rowModel,
        this.rows.groups
      );
    const imeFocus = regrouped && this.endTransients();
    // a pending cell whose record left `@records` (an owner's re-query) is
    // dropped; one on a row not inserted yet (an async owner) is kept
    if (previous && this.resolve.pendingCells.size) {
      const now = new Set(ids);
      const left = previousIds.filter((id) => !now.has(id));
      if (left.length) this.resolve.dropPending([], left);
    }
    if (
      previous &&
      !sameIds(previousIds, ids) &&
      !isOwnChange(previousIds, ids, pending)
    ) {
      this.followRecords(
        previousIds,
        ids,
        previousModel ?? this.rows.rowModel,
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
    if (imeFocus && this.selection.head)
      this.dom.focusGridCell(this.selection.head);
    // the expanded record left `@records` (deleted, or the owner re-queried)
    const expanded = this.expandedId;
    if (expanded !== null && !ids.includes(String(expanded))) {
      this.expandedFrom = null;
      this.setExpanded(null);
    }
    // a menu opened on rows that changed
    if (this.menu && previous && !sameIds(previousIds, ids)) {
      this.closeMenu(false);
    }
    this.records.applyPendingFocus();
    if (this.rows.isGrouped || previousGroups.length)
      this.groupHeaders.followGroupFocus();
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
    this.lastRowModel = this.rows.rowModel;
    this.lastGroups = this.rows.groups;
    this.lastGroupsArg = this.args.groups;
    if (
      !previousModel ||
      sameLayout(
        previousModel,
        previousGroups,
        this.rows.rowModel,
        this.rows.groups
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
    if (imeFocus && this.selection.head && !this.editing)
      this.dom.focusGridCell(this.selection.head);
    this.records.applyPendingFocus();
    this.groupHeaders.followGroupFocus();
  }

  /**
   * Ends what holds grid rows across renders when grouped rows move
   * (V03 7.4, GR23): a select drag, a fill drag, a composition, a file-drop
   * target and the row menu. True when focus was in what ended (the
   * composition catcher or the menu), so the caller focuses the active cell.
   */
  endTransients(): boolean {
    if (this.dragging || this.dragFrom) this.endDrag();
    this.stopFillDrag();
    const imeFocus =
      !!this.ime.imePos && document.activeElement === this.ime.imeInput;
    if (this.ime.imePos || this.ime.imeActive) this.ime.endIme();
    if (this.uploads.dropPos) this.uploads.dropPos = null;
    // the menu's items can re-render first and drop the focused one: focus
    // then fell to the page
    const active = document.activeElement;
    const menuFocus =
      !!this.menu &&
      (this.dom.isInMenu(active) || !active || active === document.body);
    if (this.menu) this.closeMenu(false);
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
      return found === undefined ? -1 : this.rows.gridRowOf(found);
    }
    if (at.group < 0) return this.rows.rowModel.addRowOf(-1);
    const key = previousGroups[at.group]?.key;
    const index = this.rows.groups.findIndex((group) => group.key === key);
    if (index < 0) return -1;
    return at.kind === 'add'
      ? this.rows.rowModel.addRowOf(index)
      : this.rows.rowModel.headerRowOf(index);
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
    this.checked.lastToggledRow = refind(this.checked.lastToggledRow);
    this.focus.rowCursor = refind(this.focus.rowCursor);
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
    const grouped = previousGroups.length > 0 || this.rows.isGrouped;
    if (grouped)
      this.followRows(previousIds, ids, previousModel, previousGroups);
    const active = document.activeElement;
    // a data cell has focus, or had it until this render removed its row
    const hadCellFocus =
      !!this.dom.dataCell(active) ||
      (this.focus.focusDropped && (!active || active === document.body));
    let hadEditorFocus = false;
    if (this.dragging || this.dragFrom) this.endDrag();

    const editing = this.editing;
    if (editing) {
      const row = indexOf.get(String(editing.recordId));
      if (row === undefined) {
        hadEditorFocus = this.dom.isInEditor(active);
        this.editing = null;
      } else {
        editing.pos = { row: this.rows.gridRowOf(row), col: editing.pos.col };
        const cell = this.dom.cellElement(editing.pos);
        const rect = cell && this.dom.rectOf(cell);
        if (rect) {
          editing.rect = rect;
        } else {
          // the row is not rendered: as on scroll
          this.commit({ refocus: false });
        }
      }
    }

    // the active cell: the anchor of a cell range (V03 batch 1), else the head
    const head =
      this.selection.rangeKind === 'cells' && this.selection.anchor
        ? this.selection.anchor
        : this.selection.head;
    // the copy mark's cells are other records now
    if (this.outline.copied) this.outline.copied = null;
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
        if (foundRow >= 0) found = this.rows.recordRowAt(foundRow);
      }
      // the last record, or the add row when there is none
      const model = this.rows.rowModel;
      const lastRow =
        model.lastRecordRow >= 0 ? model.lastRecordRow : model.length - 1;
      let row =
        foundRow >= 0
          ? foundRow
          : found === undefined
            ? clamp(head.row, 0, lastRow)
            : this.rows.gridRowOf(found);
      // grouped, the clamp of a lost head: a record (the nearest above
      // first), else an add row, never a header (V03 8.6)
      if (
        model.length &&
        this.rows.isGrouped &&
        found === undefined &&
        foundRow < 0
      ) {
        row = this.rows.clampToRecordRow(
          row,
          this.rows.landingRow(row, 1, false)
        );
      }
      if (model.length === 0 || row < 0) {
        this.selection.anchor = null;
        this.selection.head = null;
      } else {
        const pos = { row, col: head.col };
        this.selection.anchor = pos;
        this.selection.head = pos;
        this.selection.rangeKind = 'cells';
        if ((hadCellFocus || hadEditorFocus) && !this.editing) {
          // onFocusIn sees the cell it already knows and keeps the range
          this.focus.domCursor = pos;
          this.dom.focusGridCell(pos);
        }
      }
    }
    // the error box is placed again when its cell gets focus
    if (!hadCellFocus) this.focus.focused = null;
  }

  /** The row menu's anchor in the viewport (the layer reads it at every placement). */
  menuAnchor = (): LayerAnchor | null =>
    this.menu ? this.dom.toViewport(this.menu.anchor) : null;

  /** Copies the records' visible fields as TSV. */
  copyRows(records: readonly T[]): void {
    if (!records.length) return;
    writeClipboard(this.rowsTsv(records));
  }

  /** The records' visible fields as TSV, in the given order. */
  rowsTsv(records: readonly T[]): string {
    return toTsv(
      rangeMatrix(
        { ...this.context, records },
        {
          top: 0,
          left: 0,
          bottom: records.length - 1,
          right: this.fields.visibleFields.length - 1
        }
      )
    );
  }

  /* -------------------------------------------------------------------- */
  /* The row menu                                                          */
  /* -------------------------------------------------------------------- */

  /** Opens the menu under a cell (Shift+F10, the ContextMenu key). */
  openMenuAt(row: number, col: number | null, cell: HTMLElement): void {
    const rect = this.dom.rectOf(cell);
    if (!rect) return;
    // the keyboard path acts on the selection, or on this row
    if (
      col === null &&
      !this.selection.isRowSelected(row) &&
      !this.checked.checkedRecords.length
    ) {
      this.focus.keepRangeOnFocus = true;
      this.selection.selectRows(row, false);
    }
    this.openMenu(row, col, rect);
  }

  openMenu(row: number, col: number | null, anchor: WrapperBox): void {
    if (this.editing) this.commit({ refocus: false });
    const records = this.selection.selectionRecords();
    const record = this.rows.recordAt(row);
    this.menu = {
      row,
      col,
      anchor: {
        top: anchor.top,
        left: anchor.left,
        width: anchor.width,
        height: anchor.height
      },
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
    if (!refocus || menu.row >= this.rows.rowCount) return;
    if (menu.col === null) {
      this.focus.keepRangeOnFocus = true;
      this.dom.focusRowNumberCell(menu.row);
    } else {
      // onFocusIn sees the cell it already knows and keeps the range
      this.focus.domCursor = { row: menu.row, col: menu.col };
      this.dom.focusGridCell({ row: menu.row, col: menu.col });
    }
  }

  /** A press outside the menu closes it. */
  onDocumentMouseDown = (event: MouseEvent): void => {
    if (this.dom.isInMenu(event.target)) return;
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
            this.records.insertNear(menu.row, 'before', this.menuFieldId(menu))
        },
        {
          id: 'insertBelow',
          label: messages.insertBelow(),
          icon: 'sortDown',
          onSelect: () =>
            this.records.insertNear(menu.row, 'after', this.menuFieldId(menu))
        },
        {
          id: 'duplicate',
          label:
            count > 1
              ? messages.duplicateRecords(count)
              : messages.duplicateRecord(),
          icon: 'copy',
          disabled: !count,
          onSelect: () =>
            this.records.duplicate(records, this.menuFieldId(menu))
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
        onSelect: () => this.cells.openLink(link)
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
          this.records.deleteRecordIds(
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
    const record = this.rows.recordAt(menu.row);
    const field = this.fields.visibleFields[menu.col];
    if (record === undefined || !field) return undefined;
    return this.cells.linkOf(
      this.fields.typeOf(field),
      field,
      valueOf(record, field.id)
    );
  }

  /** The field the menu was opened on; the first one from a row number. */
  menuFieldId(menu: MenuState): string | null {
    const col = menu.col ?? 0;
    return (
      this.fields.visibleFields[col]?.id ??
      this.fields.visibleFields[0]?.id ??
      null
    );
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
    return this.args.records[this.rows.rowOf(id, 0)];
  }

  get expandedShell(): 'flyout' | 'modal' {
    return this.args.expandedRecord === 'modal' ? 'modal' : 'flyout';
  }

  /** Opens a record of `@records`; `from` is the cell focus returns to on close. */
  expandRecord(recordId: RecordId, from: ExpandedFrom | null): void {
    if (
      this.rows.rowOf(recordId, this.rows.hintOf(this.selection.head?.row)) < 0
    )
      return;
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
      const row = this.rows.rowOf(
        from.recordId,
        this.rows.hintOf(this.selection.head?.row)
      );
      if (row < 0) return;
      if (from.fieldId === null) {
        this.focus.keepRangeOnFocus = true;
        this.dom.focusRowNumberCell(this.rows.gridRowOf(row));
      } else {
        this.selection.focusRecordCell({
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
    const row = this.rows.rowOf(id, 0);
    if (row < 0) return null;
    return this.args.records[row + step] ?? null;
  }

  stepExpanded(step: number): void {
    const record = this.expandedStep(step);
    if (record) this.setExpanded(this.args.getRecordId(record));
  }

  /** The expanded record's title: its first field's text, else "Record n". */
  recordTitleOf(record: T): string {
    const field = this.fields.allFields[0];
    const text = field
      ? this.fields.typeOf(field).format(valueOf(record, field.id), field, {
          record,
          messages: this.messages
        })
      : '';
    if (text.trim()) return text;
    const row = this.rows.rowOf(this.args.getRecordId(record), 0);
    return this.messages.recordTitle(this.rows.numberOf(Math.max(row, 0)));
  }

  /** A one-record context for the form: every field, visible and hidden. */
  formContext(record: T): { ctx: SheetContext<T>; record: T } | null {
    // the current object of the record: the form may hold an older one
    const row = this.rows.rowOf(this.args.getRecordId(record), 0);
    const current = this.args.records[row];
    if (current === undefined) return null;
    return {
      ctx: {
        ...this.context,
        records: [current],
        fields: this.fields.allFields
      },
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
    const col = this.fields.allFields.indexOf(field);
    if (col < 0) return;
    this.changes.emitText(form.ctx, { row: 0, col }, text, [
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
    const col = this.fields.allFields.indexOf(field);
    if (col < 0) return;
    const changeSet = build(form.ctx, { row: 0, col });
    this.changes.emit(changeSet, [
      { id: this.args.getRecordId(form.record), fieldId: field.id }
    ]);
  }

  /** Runs `fn` after the next render (the form focuses a box). */
  afterFormRender(fn: () => void): void {
    afterRender(this, fn);
  }

  /** The press started on the cell that already had focus (a second click edits). */
  pressOnFocusedCell = false;

  @action
  onMouseDown(event: MouseEvent): void {
    // the compatibility mouse events of the long press that opened the menu
    if (this.longPressOpened) return;
    this.focus.extending = event.shiftKey;
    this.frozen.noteScrollLeft();
    this.frozen.pressing = true;
    const target = event.target as Element;
    // before the press moves focus: was this cell the focused one?
    const cell = this.dom.dataCell(target);
    this.pressOnFocusedCell = !!cell && cell === document.activeElement;
    // the active cell stays focused through a range (V03 batch 1): a plain
    // press on it collapses the range, as a press on another cell would,
    // and is not a second click that edits
    if (
      this.pressOnFocusedCell &&
      event.button === 0 &&
      !event.shiftKey &&
      this.selection.anchor &&
      this.selection.head &&
      !samePos(this.selection.anchor, this.selection.head)
    ) {
      this.pressOnFocusedCell = false;
      const pos = this.dom.cursor(cell!);
      this.selection.anchor = pos;
      this.selection.head = pos;
      this.selection.rangeKind = 'cells';
    }
    // a click after a drag that released outside the sheet never came
    this.suppressClick = false;
    this.endDrag();
    if (this.menu && !this.dom.isInMenu(target)) this.closeMenu(false);

    const rowCell = this.dom.rowNumberCell(target);
    if (rowCell) {
      // the range is the press's: focusin must not clear it
      this.focus.keepRangeOnFocus = true;
      const row = this.dom.rowIndexOf(rowCell);
      // a group header keeps no range (V03 8.6), also after a press on
      // its row number with a range elsewhere: a paste there writes nothing
      if (this.rows.isGrouped && this.rows.rowKind(row) === 'group') {
        this.focus.keepRangeOnFocus = false;
      }
      if (!this.rows.isRecordRow(row) || event.button !== 0) return;
      // the checkbox and the expand icon are buttons, not a selection
      if (
        target.closest(
          '[data-eui-sheet-row-check], [data-eui-sheet-row-expand]'
        )
      ) {
        return;
      }
      this.selection.selectRows(row, event.shiftKey);
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
    const pos = this.dom.cursor(cell);
    if (event.button === 2) {
      // a right-click inside the range keeps it for the menu
      this.focus.keepRangeOnFocus = this.selection.isSelected(pos.row, pos.col);
      return;
    }
    // Shift+click extends the range; focus stays on the active cell (the
    // anchor), so the press must not move it (V03 batch 1)
    if (
      event.button === 0 &&
      event.shiftKey &&
      !this.editing &&
      this.selection.rangeKind === 'cells' &&
      this.rows.isRecordRow(pos.row) &&
      this.dom.dataCell(document.activeElement)
    ) {
      event.preventDefault();
      this.selection.extendHead(pos);
      return;
    }
    // a press that may become a drag (Shift+click extends instead)
    // (a touch drag scrolls: no range drag by touch, 8.5)
    if (
      event.button === 0 &&
      !event.shiftKey &&
      !this.editing &&
      this.lastPointerType !== 'touch' &&
      this.rows.isRecordRow(pos.row) &&
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
    const bounds = this.scroll.scrollBounds();
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
      const target =
        this.dom.rowNumberCell(element) ?? this.dom.dataCell(element);
      if (!target) return;
      const row = this.dom.rowIndexOf(target);
      if (!this.rows.isRecordRow(row)) return;
      if (!this.dragging) {
        if (row === from.row) return;
        this.dragging = true;
      }
      this.selection.selectRows(row, true);
      window.getSelection()?.removeAllRanges();
      return;
    }
    const cell = this.dom.dataCell(element);
    if (!cell) return;
    const pos = this.dom.cursor(cell);
    // the add row is never part of a range
    if (!this.rows.isRecordRow(pos.row)) return;
    if (!this.dragging) {
      if (samePos(pos, from)) return;
      this.dragging = true;
      this.selection.anchor = from;
      this.selection.rangeKind = 'cells';
    }
    if (!samePos(pos, this.selection.head)) this.selection.head = pos;
    // text the press may have started to select
    window.getSelection()?.removeAllRanges();
  }

  /** The release ends a drag (anywhere on the page): focus stays on the anchor, the active cell (V03 batch 1). */
  onRelease = (): void => {
    const dragged = this.dragging;
    const kind = this.dragKind;
    const from = this.dragFrom;
    const before = this.frozen.scrollLeftBeforeFocus;
    this.endDrag();
    if (!dragged) return;
    // the grid scrolled the pressed cell into view on pointerup; a frozen
    // one is always in view, so the scroll goes back to the press's
    if (
      this.frozen.frozenCount &&
      (kind === 'rows' || (from !== null && from.col < this.frozen.frozenCount))
    ) {
      this.frozen.scrollLeftBeforeFocus = before;
      this.frozen.keepFrozenScroll();
    }
    const head = this.selection.head;
    if (!head || samePos(head, this.selection.anchor)) return;
    // the click that follows is the end of the drag, not a click on a cell
    this.suppressClick = true;
    // the head may not be rendered now (an auto-scroll took it away, or the
    // grid's pointerup scrolled back to the pressed cell), so its focus can
    // come after this release and after its click: the focus handlers must
    // see a cell they already know and keep the range
    if (kind === 'rows') {
      const row = this.selection.anchor?.row ?? head.row;
      this.focus.keepRangeOnFocus = true;
      this.focus.rowCursor = row;
      this.dom.focusRowNumberCell(row);
      return;
    }
    // the press focused the anchor and the grid scrolled it back into view
    // on pointerup; focus it again only if something took focus away.
    // onFocusIn sees the cell it knows and keeps the range
    const anchor = this.selection.anchor;
    if (anchor && anchor.row < this.rows.rowCount) {
      this.focus.domCursor = anchor;
      const active = this.dom.dataCell(document.activeElement);
      if (!active || !samePos(this.dom.cursor(active), anchor)) {
        this.dom.focusGridCell(anchor);
      }
    }
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
    const range = this.selection.range;
    if (!range || this.args.readOnly || this.editing) return null;
    if (this.selection.rangeKind !== 'cells') return null;
    if (!this.rows.recordRange(range)) return null;
    return range;
  }

  /** Puts the handle at the corner of the range's last cell, or hides it while that corner is not in view. */
  placeFillHandle(element: HTMLElement, range: Range): void {
    // the range's last record row
    const records = this.rows.recordRange(range);
    const corner = {
      row: records ? this.rows.gridRowOf(records.bottom) : -1,
      col: range.right
    };
    const cell = records ? this.dom.cellElement(corner) : null;
    const bounds = cell && this.scroll.scrollBounds();
    const rect = cell && this.dom.rectOf(cell);
    let shown = false;
    let box: DOMRect | undefined;
    if (cell && bounds && rect) {
      box = cell.getBoundingClientRect();
      const left =
        bounds.frozenRight !== undefined &&
        corner.col >= this.frozen.frozenCount
          ? bounds.frozenRight
          : bounds.left;
      shown =
        box.right >= left &&
        box.right <= bounds.right + 1 &&
        box.bottom >= bounds.top &&
        box.bottom <= bounds.bottom + 1;
    }
    element.style.display = shown ? '' : 'none';
    if (shown && rect && box && bounds) {
      // centred on the corner (14 px drawn: `styles.ts`), moved in so it is
      // whole at the grid body's right and bottom edges
      const half = FILL_HANDLE_SIZE / 2;
      const pastRight = Math.max(0, box.right + half - bounds.right);
      const pastBottom = Math.max(0, box.bottom + half - bounds.bottom);
      element.style.top = `${rect.top + rect.height - half - pastBottom}px`;
      element.style.left = `${rect.left + rect.width - half - pastRight}px`;
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
    const cell = this.dom.dataCell(element);
    if (!source || !cell) return;
    const pos = this.dom.cursor(cell);
    let row: number;
    let down: number;
    let up: number;
    if (this.rows.isGrouped) {
      // measured in records (V03 8.5): a header or an add row counts for
      // nothing, and stands for the record on the source's side of it
      const records = this.rows.recordRange(source);
      if (!records) return;
      row = this.rows.isRecordRow(pos.row)
        ? pos.row
        : this.rows.rowModel.nearestRecordRow(
            pos.row,
            pos.row > this.rows.gridRowOf(records.bottom) ? -1 : 1
          );
      if (row < 0) return;
      const r = this.rows.recordRowAt(row);
      down = r - records.bottom;
      up = records.top - r;
    } else {
      // a fill never reaches the add row
      row = this.rows.clampToRecordRow(pos.row, pos.row);
      down = row - source.bottom;
      up = source.top - row;
    }
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
    this.frozen.pressing = false;
    // the press's scroll is not one to restore (a fill may auto-scroll)
    this.frozen.scrollLeftBeforeFocus = null;
    // the click that may follow is the end of the drag
    this.suppressClick = true;
    if (!source || !target || sameRange(source, target)) return;
    const recordSource = this.rows.recordRange(source);
    const recordTarget = this.rows.recordRange(target);
    if (!recordSource || !recordTarget) return;
    this.changes.emit(
      fillRange(this.context, recordSource, recordTarget, {
        copy: event.ctrlKey || event.altKey
      }),
      this.selection.touchedIn(this.fillWritten(source, target), true)
    );
    // the union is the range; focus stays where it was when that cell is
    // one of its corners (a single cell filled down), else it moves to the
    // nearest corner
    const head = this.selection.head ?? { row: source.top, col: source.left };
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
    this.selection.anchor = {
      row: next.row === target.top ? target.bottom : target.top,
      col: next.col === target.left ? target.right : target.left
    };
    this.selection.head = next;
    this.selection.rangeKind = 'cells';
    // focus moves to the new corner, or back to the cell an auto-scroll
    // unmounted (focus left with it)
    const active = this.dom.dataCell(document.activeElement);
    if (!active || !samePos(this.dom.cursor(active), next)) {
      this.focus.domCursor = next;
      this.dom.focusGridCell(next);
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
    // grouped: a header or an add row inside the target is not filled
    if (this.rows.isGrouped && !this.rows.isRecordRow(row)) return false;
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
    if (!this.longPressOpened || this.dom.isInMenu(event.target)) return;
    this.longPressOpened = false;
    stop(event);
  }

  /** The grid row of a data cell or a row-number cell on a record; -1 elsewhere. */
  menuRowOf(target: Element): number {
    const rowCell = this.dom.rowNumberCell(target);
    const cell = rowCell ? null : this.dom.dataCell(target);
    const row = rowCell
      ? this.dom.rowIndexOf(rowCell)
      : cell
        ? this.dom.cursor(cell).row
        : -1;
    return this.rows.isRecordRow(row) ? row : -1;
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
    if (!this.editsInRecord || !this.cells.canEdit(pos)) return false;
    const record = this.rows.recordAt(pos.row);
    const field = this.fields.visibleFields[pos.col];
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
    if (this.frozen.pressing) {
      this.frozen.pressing = false;
      const focused = document.activeElement;
      const frozen =
        (this.dom.rowNumberCell(focused) && this.frozen.frozenCount) ||
        (this.dom.dataCell(focused) &&
          this.dom.cursor(this.dom.dataCell(focused)!).col <
            this.frozen.frozenCount);
      if (frozen) this.frozen.keepFrozenScroll();
      else this.frozen.scrollLeftBeforeFocus = null;
    }
    const pressOnFocusedCell = this.pressOnFocusedCell;
    this.pressOnFocusedCell = false;
    this.focus.keepRangeOnFocus = false;
    if (this.suppressClick) {
      this.suppressClick = false;
      return;
    }
    const target = event.target as Element;
    if (this.dom.isInMenu(target)) return;
    // a header's chevron or title (V03 8.3), on a data or row-number cell
    if (this.rows.isGrouped && this.groupHeaders.onGroupToggleClick(target))
      return;
    if (this.onControlClick(event, target)) return;
    if (event.shiftKey || this.editing) return;
    const cell = this.dom.dataCell(target);
    if (!cell) return;
    const pos = this.dom.cursor(cell);
    if (this.rows.isAddRow(pos.row)) {
      this.records.appendRecord(pos.row);
      return;
    }
    const record = this.rows.recordAt(pos.row);
    const field = this.fields.visibleFields[pos.col];
    if (record === undefined || !field) return;
    const type = this.fields.typeOf(field);
    // a click on the link text opens it (first click, no edit)
    if (target.closest('[data-eui-sheet-link]')) {
      if (
        this.cells.openLink(
          this.cells.linkOf(type, field, valueOf(record, field.id))
        )
      ) {
        return;
      }
    }
    // a star click is the cell's own (`@onCommit`): no edit
    if (target.closest('[data-eui-sheet-star]')) return;
    if (target.closest('[data-eui-sheet-opener]')) {
      if (this.cells.canEdit(pos) && !this.editInRecord(pos)) {
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
      if (result) this.cells.commitCellValue(pos.row, pos.col, result.value);
      return;
    }
    if (
      pressOnFocusedCell &&
      this.cells.canEdit(pos) &&
      !this.editInRecord(pos)
    ) {
      this.startEdit(pos, cell, null);
    }
  }

  /** Clicks on the row-number column and the column headers; true when handled. */
  onControlClick(event: MouseEvent, target: Element): boolean {
    // the "+" header (V03 6.3)
    if (this.dom.addFieldHeader(target)) {
      this.addField();
      return true;
    }
    if (target.closest('[data-eui-sheet-row-check-all]')) {
      this.checked.toggleAllChecked();
      return true;
    }
    const rowCell = this.dom.rowNumberCell(target);
    if (rowCell) {
      const row = this.dom.rowIndexOf(rowCell);
      if (this.rows.isAddRow(row)) {
        this.records.appendRecord(row);
      } else if (target.closest('[data-eui-sheet-row-check]')) {
        this.checked.toggleChecked(row, event.shiftKey);
      } else if (target.closest('[data-eui-sheet-row-expand]')) {
        const record = this.rows.recordAt(row);
        if (record !== undefined) {
          const recordId = this.args.getRecordId(record);
          this.expandRecord(recordId, { recordId, fieldId: null });
        }
      }
      return true;
    }
    // a header's title (not its actions button or resizer) selects the column
    const header = this.dom.headerCell(target);
    if (header && target.closest('.euiDataGridHeaderCell__content')) {
      const col =
        Number(header.dataset['gridcellColumnIndex']) - this.colOffset;
      if (col >= 0 && col < this.fields.visibleFields.length) {
        this.selection.selectColumns(col, event.shiftKey);
      }
      return true;
    }
    return false;
  }

  @action
  onDoubleClick(event: MouseEvent): void {
    // the double-click's second click already opened the editor
    if (this.editing) return;
    const cell = this.dom.dataCell(event.target);
    if (!cell) return;
    const pos = this.dom.cursor(cell);
    if (this.cells.canEdit(pos) && !this.editInRecord(pos)) {
      this.startEdit(pos, cell, null);
    }
  }

  /** Right-click on a data cell or a row number: the row menu. */
  @action
  onContextMenu(event: MouseEvent): void {
    const target = event.target as Element;
    // the ContextMenu key's own event, once focus is in the menu: not the
    // browser's menu over it; and a long press that already opened it
    if (this.dom.isInMenu(target) || this.longPressOpened) {
      event.preventDefault();
      return;
    }
    this.cancelLongPress();
    // a header's menu is a popover that closes on a press outside it: where
    // the browser fires contextmenu on the press (Linux, macOS), the release
    // that follows would close it at once, so it opens after the release
    if ((event.buttons & 2) !== 0 && this.dom.headerCell(target)) {
      event.preventDefault();
      const open = (): void => {
        window.removeEventListener('mouseup', onUp, true);
        clearTimeout(timer);
        requestAnimationFrame(() => {
          if (!this.isDestroying && !this.isDestroyed) {
            this.openContextMenu(target, event.clientX, event.clientY);
          }
        });
      };
      const onUp = (up: MouseEvent): void => {
        if (up.button === 2) open();
      };
      window.addEventListener('mouseup', onUp, true);
      // a release outside the window never comes
      const timer = setTimeout(open, 1000);
      return;
    }
    if (this.openContextMenu(target, event.clientX, event.clientY)) {
      event.preventDefault();
    }
  }

  /** The row menu at a viewport point, for a right-click or a long press on `target`; whether it opened. */
  openContextMenu(target: Element, x: number, y: number): boolean {
    if (this.editing) return false;
    // a header: its own menu, as its "⋯" button opens it (V03 batch 1)
    const header = this.dom.headerCell(target);
    if (header) {
      const button = header.querySelector<HTMLElement>(
        '[data-test-subj^=dataGridHeaderCellActionButton-]'
      );
      if (!button) return false;
      button.click();
      return true;
    }
    const rowCell = this.dom.rowNumberCell(target);
    const cell = rowCell ? null : this.dom.dataCell(target);
    const row = rowCell
      ? this.dom.rowIndexOf(rowCell)
      : cell
        ? this.dom.cursor(cell).row
        : -1;
    if (!this.rows.isRecordRow(row)) return false;
    let col: number | null = null;
    if (rowCell) {
      if (!this.selection.isRowSelected(row))
        this.selection.selectRows(row, false);
    } else if (cell) {
      const pos = this.dom.cursor(cell);
      col = pos.col;
      if (!this.selection.isSelected(pos.row, pos.col)) {
        this.selection.anchor = pos;
        this.selection.head = pos;
        this.selection.rangeKind = 'cells';
      }
    }
    const point = this.dom.pointInWrapper(x, y);
    this.openMenu(row, col, { ...point, width: 0, height: 0 });
    return true;
  }

  /* -------------------------------------------------------------------- */
  /* Keys and clipboard                                                    */
  /* -------------------------------------------------------------------- */

  @action
  onKeyDown(event: KeyboardEvent): void {
    this.focus.extending = event.shiftKey && RANGE_KEYS.has(event.key);
    this.frozen.pressing = false;
    this.frozen.noteScrollLeft();
    this.focus.keepRangeOnFocus = false;
    const target = event.target;
    // a composition in an editor or in the catcher is the IME's: Enter
    // confirms it there, it does not save
    if (
      (event.isComposing || event.keyCode === 229) &&
      this.dom.isInEditor(target)
    ) {
      return;
    }
    if (this.editing && this.dom.isInEditor(target)) {
      this.onEditKeyDown(event);
      return;
    }
    // the field editor's keys are its own (its focus trap has Escape)
    if (this.dom.isInFieldEditor(target)) return;
    if (this.menu && this.dom.isInMenu(target)) {
      // the panel has ArrowUp/Down and Enter; Escape is the sheet's
      if (event.key === 'Escape' || event.key === 'Tab') {
        stop(event);
        this.closeMenu(true);
      }
      return;
    }
    if (this.focus.isParked(target)) {
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
      !this.editing &&
      this.dom.isInGrid(target)
    ) {
      stop(event);
      this.showShortcuts();
      return;
    }
    // Enter or Space on a group header's cell, row number or data (V03 8.6)
    if (this.rows.isGrouped && this.groupHeaders.onGroupKeyDown(event, target))
      return;
    const rowCell = this.dom.rowNumberCell(target);
    if (rowCell && target === rowCell) {
      this.onRowNumberKeyDown(event, this.dom.rowIndexOf(rowCell));
      return;
    }
    // the "+" header (V03 6.3): Enter or Space opens the field editor
    const addHeader = this.dom.addFieldHeader(target);
    if (addHeader && target === addHeader) {
      const plain = !event.ctrlKey && !event.metaKey && !event.altKey;
      if (plain && (event.key === 'Enter' || event.key === ' ')) {
        stop(event);
        this.addField();
      }
      return;
    }
    const header = this.dom.headerCell(target);
    if (header && target === header) {
      // a selected column: Delete clears it (other keys are the header's)
      if (
        this.selection.rangeKind === 'columns' &&
        this.selection.range &&
        (event.key === 'Delete' || event.key === 'Backspace')
      ) {
        stop(event);
        this.selection.clearSelection();
      }
      return;
    }
    const cell = this.dom.dataCell(target);
    if (!cell || target !== cell) return;
    const pos = this.dom.cursor(cell);
    if (this.handleCommandKey(event)) return;
    if (this.handleNavKey(event, pos)) return;
    if (this.handleHomeKey(event, pos.row)) return;
    if (this.handleLastFieldKey(event, pos.row, pos.col)) return;
    if (this.handleGroupedEndKey(event)) return;
    // Escape ends the copy mark first (V03 batch 1)
    if (event.key === 'Escape' && this.outline.copied) {
      stop(event);
      this.outline.copied = null;
      return;
    }
    // Escape collapses a range to the active cell (V03 batch 1)
    if (
      event.key === 'Escape' &&
      !event.shiftKey &&
      this.selection.anchor &&
      this.selection.head &&
      !samePos(this.selection.anchor, this.selection.head)
    ) {
      stop(event);
      this.selection.anchor = pos;
      this.selection.head = pos;
      this.selection.rangeKind = 'cells';
      return;
    }
    if (this.rows.isAddRow(pos.row)) {
      this.onAddRowKeyDown(event, pos.row);
      return;
    }
    const record = this.rows.recordAt(pos.row);
    const field = this.fields.visibleFields[pos.col];
    if (record === undefined || !field) return;
    const ctx = this.context;
    const type = this.fields.typeOf(field);
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
      if (type.editor && !readOnly) this.ime.startIme(pos, cell);
      return;
    }
    // navKey first: a checkbox's Space (PACKAGE-DESIGN.md 7.4)
    if (plain && !readOnly && type.navKey) {
      const result = type.navKey(key, valueOf(record, field.id), field);
      if (result) {
        stop(event);
        this.changes.emit(
          commitValue(ctx, this.rows.recordPos(pos), result.value),
          this.selection.touchedAt(pos)
        );
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
      this.records.insertNear(pos.row, 'after', field.id);
      return;
    }
    if (key === 'Enter' || key === 'F2') {
      // read-only: the cue, and the key goes on as before (not taken)
      if (readOnly) {
        this.focus.readOnlyCue = pos;
        return;
      }
      if (!type.editor) return;
      stop(event);
      if (!this.editInRecord(pos)) this.startEdit(pos, cell, null);
      return;
    }
    if (key.length === 1 && plain && !event.isComposing) {
      if (readOnly) {
        // not a silent no-op (V03 batch 2); the key is not taken
        this.focus.readOnlyCue = pos;
        return;
      }
      if (!type.editor) return;
      if (!(type.opensOnKey?.(key) ?? true)) return;
      // preventDefault keeps the character from being typed twice
      stop(event);
      this.startEdit(pos, cell, key);
      return;
    }
    if (key === 'Delete' || key === 'Backspace') {
      if (!this.selection.range) return;
      stop(event);
      const range = this.selection.range;
      if (
        readOnly &&
        range.top === range.bottom &&
        range.left === range.right
      ) {
        this.focus.readOnlyCue = pos;
        return;
      }
      this.selection.clearSelection();
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
      if (event.shiftKey) this.history.redo();
      else this.history.undo();
      return true;
    }
    if (letter === 'y' && event.ctrlKey && !event.shiftKey) {
      stop(event);
      this.history.redo();
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
      const model = this.rows.rowModel;
      // grouped: all the records (V03 8.5); with none, nothing to select
      if (this.rows.isGrouped && model.firstRecordRow < 0) return true;
      this.selection.anchor = {
        row: Math.max(model.firstRecordRow, 0),
        col: 0
      };
      this.selection.head = {
        row: model.lastRecordRow,
        col: this.fields.visibleFields.length - 1
      };
      this.selection.rangeKind = 'cells';
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
    const lastCol = this.fields.visibleFields.length - 1;
    // with Shift the range's head moves and focus stays on the active cell
    // (V03 batch 1): every target is computed from the head
    const extend = event.shiftKey && this.rows.isRecordRow(pos.row);
    const from =
      extend &&
      this.selection.head &&
      this.selection.anchor &&
      this.selection.rangeKind === 'cells'
        ? this.selection.head
        : pos;
    const model = this.rows.rowModel;
    let target: Pos;
    if (command && key in ARROW_DIRECTIONS) {
      const direction = ARROW_DIRECTIONS[key as keyof typeof ARROW_DIRECTIONS];
      if (this.rows.isGrouped && !this.rows.isRecordRow(from.row)) {
        // a header or a group's add row: an empty cell between two records
        target = this.rows.edgeFromGap(from, direction);
      } else {
        // in record rows; the add row is the row after the records above it
        const core = { row: this.rows.coreRowOf(from.row), col: from.col };
        const edge = edgeTarget(this.context, core, direction);
        target =
          edge.row === core.row
            ? { row: from.row, col: edge.col }
            : this.rows.gridPos(edge);
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
        row: this.rows.isRecordRow(row)
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
      const page = this.scroll.pageRows();
      const last = event.shiftKey ? model.lastRecordRow : model.length - 1;
      let row = clamp(from.row + (key === 'PageDown' ? page : -page), 0, last);
      // grouped: never on a header; with Shift on a record (V03 8.6)
      if (this.rows.isGrouped) {
        row = this.rows.landingRow(
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
    if (extend) this.selection.extendHead(target);
    else this.selection.moveFocus(target, false);
    return true;
  }

  /** Keys while focus is parked: extend and clear the range; anything else brings the active cell back first. */
  onParkedKeyDown(event: KeyboardEvent): void {
    const anchor = this.selection.anchor;
    if (!anchor) return;
    if (this.handleCommandKey(event)) return;
    if (this.handleNavKey(event, anchor)) return;
    if (event.key === 'Delete' || event.key === 'Backspace') {
      stop(event);
      this.selection.clearSelection();
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
    if (event.key === 'Escape') this.selection.head = anchor;
    this.focus.domCursor = anchor;
    this.dom.focusGridCell(anchor);
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
    if (!this.gridColumns.hasAddFieldColumn) return false;
    if (event.altKey || event.shiftKey) return false;
    const lastCol = this.fields.visibleFields.length - 1;
    const command = event.ctrlKey || event.metaKey;
    if (event.key === 'ArrowRight' && !command && col === lastCol) {
      stop(event);
      return true;
    }
    if (event.key !== 'End' || lastCol < 0) return false;
    stop(event);
    const last = command ? this.rows.lastLandingRow() : row;
    if (last < 0 && this.rows.isGrouped) return true;
    this.selection.moveFocus({ row: last, col: lastCol }, false);
    return true;
  }

  /**
   * Grouped, without the "+" column: Ctrl+End lands on the last row that
   * is not a header (the grid would go to a collapsed last group's header).
   */
  handleGroupedEndKey(event: KeyboardEvent): boolean {
    if (!this.rows.isGrouped || this.gridColumns.hasAddFieldColumn)
      return false;
    if (event.key !== 'End' || !event.ctrlKey) return false;
    if (event.altKey || event.shiftKey || event.metaKey) return false;
    const lastCol = this.fields.visibleFields.length - 1;
    if (lastCol < 0) return false;
    stop(event);
    const last = this.rows.lastLandingRow();
    if (last >= 0) this.selection.moveFocus({ row: last, col: lastCol }, false);
    return true;
  }

  handleHomeKey(event: KeyboardEvent, row: number): boolean {
    if (event.key !== 'Home') return false;
    if (event.altKey || event.shiftKey || event.metaKey) return false;
    // grouped, Ctrl+Home is the sheet's also without row numbers: the
    // grid would go to row 0, a header
    if (!this.colOffset && !(this.rows.isGrouped && event.ctrlKey))
      return false;
    stop(event);
    // Ctrl+Home: the first record (the add row when there is none)
    const first = this.rows.firstLandingRow();
    if (event.ctrlKey && first < 0) return true;
    this.dom.focusGridCell({ row: event.ctrlKey ? first : row, col: 0 });
    // Home also scrolls to the left edge (the frozen field is in view anyway)
    if (this.frozen.frozenCount) this.frozen.scrollLeftBeforeFocus = 0;
    return true;
  }

  /** The add row: Enter inserts; Space, typing and Delete do nothing (V02-DESIGN.md 5.5). */
  onAddRowKeyDown(event: KeyboardEvent, row: number): void {
    const plain = !event.ctrlKey && !event.metaKey && !event.altKey;
    if (event.key === 'Enter' && plain) {
      stop(event);
      this.records.appendRecord(row);
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
    if (!this.rows.isGrouped || event.altKey || event.metaKey) return false;
    const { key } = event;
    if ((key === 'PageDown' || key === 'PageUp') && !event.ctrlKey) {
      stop(event);
      const step = key === 'PageDown' ? 1 : -1;
      const target = this.rows.landingRow(
        row + step * this.scroll.pageRows(),
        step,
        event.shiftKey
      );
      if (target >= 0 && target !== row) this.dom.focusRowNumberCell(target);
      return true;
    }
    if (key === 'Home' && event.ctrlKey && !event.shiftKey) {
      stop(event);
      const first = this.rows.firstLandingRow();
      if (first >= 0) this.dom.focusRowNumberCell(first);
      return true;
    }
    return this.handleGroupedEndKey(event);
  }

  /** Keys of a row-number cell (V02-DESIGN.md 5.5). */
  onRowNumberKeyDown(event: KeyboardEvent, row: number): void {
    if (this.handleCommandKey(event)) return;
    if (this.handleLastFieldKey(event, row, null)) return;
    if (this.handleGroupedRowNumberKey(event, row)) return;
    if (this.rows.isAddRow(row)) {
      this.onAddRowKeyDown(event, row);
      return;
    }
    const record = this.rows.recordAt(row);
    if (record === undefined) return;
    const plain = !event.ctrlKey && !event.metaKey && !event.altKey;
    if (isMenuKey(event)) {
      stop(event);
      const cell = this.dom.rowNumberElement(row);
      if (cell) this.openMenuAt(row, null, cell);
      return;
    }
    if (event.key === ' ' && plain) {
      stop(event);
      this.checked.toggleChecked(row, event.shiftKey);
      return;
    }
    if (event.key === 'Enter' && plain && !event.shiftKey) {
      stop(event);
      const recordId = this.args.getRecordId(record);
      this.expandRecord(recordId, { recordId, fieldId: null });
      return;
    }
    if (
      (event.key === 'Delete' || event.key === 'Backspace') &&
      this.selection.range
    ) {
      stop(event);
      this.selection.clearSelection();
    }
  }

  /** Ctrl/Cmd+R: fill the range right, or the cell from the one to its left. */
  fillRightSelection(): void {
    const range =
      this.selection.range && this.rows.recordRange(this.selection.range);
    if (!range) return;
    const targets =
      range.right > range.left ? { ...range, left: range.left + 1 } : range;
    this.changes.emit(
      fillRight(this.context, range),
      this.selection.touchedInRecords(targets, true)
    );
  }

  /** Ctrl/Cmd+D: fill the range down, or the cell from the one above. */
  fill(): void {
    const range =
      this.selection.range && this.rows.recordRange(this.selection.range);
    if (!range) return;
    // the cells written: below the top record, or the record itself (from above)
    const targets =
      range.bottom > range.top ? { ...range, top: range.top + 1 } : range;
    this.changes.emit(
      fillDown(this.context, range),
      this.selection.touchedInRecords(targets, true)
    );
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
    if (this.editing && this.dom.isInEditor(target)) return;
    if (this.checked.isCheckedRowsTarget(target)) {
      if (!event.clipboardData) return;
      event.clipboardData.setData(
        'text/plain',
        this.rowsTsv(this.checked.checkedRecords)
      );
      stop(event);
      return;
    }
    if (this.groupHeaders.isGroupHeaderTarget(target)) {
      event.clipboardData?.setData('text/plain', '');
      stop(event);
      return;
    }
    if (!this.isRangeTarget(target)) return;
    const range = this.selection.range;
    if (!range || !event.clipboardData) return;
    event.clipboardData.setData('text/plain', this.rangeTsv(range));
    // stopPropagation is required: the grid's document copy handlers
    stop(event);
    this.outline.copied = range;
  }

  /** The records of a grid range as TSV; '' when it holds none (the add row). */
  rangeTsv(range: Range): string {
    const records = this.rows.recordRange(range);
    return toTsv(records ? rangeMatrix(this.context, records) : []);
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
    if (this.editing && this.dom.isInEditor(target)) return;
    if (this.groupHeaders.isGroupHeaderTarget(target)) {
      event.clipboardData?.setData('text/plain', '');
      stop(event);
      return;
    }
    if (!this.isRangeTarget(target)) return;
    const range = this.selection.range;
    if (!range || !event.clipboardData) return;
    event.clipboardData.setData('text/plain', this.rangeTsv(range));
    // stopPropagation: the grid's document clipboard handlers
    stop(event);
    if (this.args.readOnly) {
      this.outline.copied = range;
      return;
    }
    const records = this.rows.recordRange(range);
    if (records) {
      this.changes.emit(
        clearRange(this.context, records, { source: 'cut' }),
        this.selection.touchedInRecords(records, true)
      );
    }
    // after the emit, which clears the mark of an older copy
    this.outline.copied = range;
  }

  @action
  onPaste(event: ClipboardEvent): void {
    if (this.args.readOnly) return;
    const target = event.target;
    if (this.editing && this.dom.isInEditor(target)) return;
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
      this.selection.range &&
      this.uploads.pasteFiles(data.files)
    ) {
      stop(event);
      return;
    }
    if (!Array.from(data.types).includes('text/plain')) return;
    const range = this.selection.range;
    if (!range) return;
    // a header is never pasted over (V03 8.5); its row has no range anyway
    if (this.rows.isGrouped && this.rows.rowKind(range.top) === 'group') return;
    stop(event);
    const anchor = { row: range.top, col: range.left };
    const records = this.args.records;
    // a group's add row: every line is an insert into that group (V03 8.5)
    const addGroup = this.rows.addRowGroupAt(anchor.row);
    // the core's anchor: its record row, or `records.length` on an add row
    const at = {
      row: addGroup >= 0 ? records.length : this.rows.coreRowOf(anchor.row),
      col: anchor.col
    };
    // grouped, the lines past the records: into the add row's group, or
    // into the last record's group, with its values and `groupKey`
    const insert = this.rows.isGrouped ? this.pasteInsert(addGroup) : undefined;
    // a block that fits the selection a whole number of times fills it
    // (its records: a header or an add row inside is no line)
    const selection = this.rows.recordRange(range);
    let matrix = tileMatrix(
      parseTsv(data.getData('text/plain')),
      selection ? selection.bottom - selection.top + 1 : 1,
      range.right - range.left + 1
    );
    // without inserting, lines past the last record are dropped (5.8)
    if (!this.canInsert) {
      matrix = matrix.slice(0, Math.max(this.args.records.length - at.row, 0));
      if (!matrix.length) return;
    }
    const width = Math.max(...matrix.map((line) => line.length));
    const right = Math.min(
      anchor.col + width - 1,
      this.fields.visibleFields.length - 1
    );
    // in record rows: the records written (inserted ones are not there yet)
    const pasted = {
      top: at.row,
      left: anchor.col,
      bottom: at.row + matrix.length - 1,
      right
    };
    const touched = this.selection.touchedInRecords(pasted, false);
    const options = insert ? { nextTempId, insert } : { nextTempId };
    if (this.args.onResolve) {
      // V9: the synchronous part at once, the resolved part later
      const plan = planPaste(this.context, at, matrix, options);
      const entry = this.changes.emit(plan.changeSet, touched);
      this.resolve.startResolve(plan, entry);
    } else {
      this.changes.emit(
        pasteMatrix(this.context, at, matrix, options),
        touched
      );
    }
    // no setFocusedCell: inserted rows exist only after the next render
    this.selection.anchor = anchor;
    this.selection.head = {
      row: this.pasteHeadRow(anchor.row, at.row, matrix.length, addGroup),
      col: right
    };
    this.selection.rangeKind = 'cells';
  }

  /**
   * Grouped (V03 8.5, D14): where a paste's lines past the records go. On
   * a group's add row, into that group after its last loaded record (no
   * anchor for an empty group); from a record, into the last record's
   * group, after it. Each with the group's values and `groupKey`.
   */
  pasteInsert(addGroup: number): PasteInsert | undefined {
    const model = this.rows.rowModel;
    const group = addGroup >= 0 ? addGroup : model.groupAt(model.lastRecordRow);
    const key = this.rows.groups[group]?.key;
    if (key === undefined) return undefined;
    const insert: PasteInsert = {
      values: this.groupHeaders.groupValuesOf(group),
      groupKey: key
    };
    if (addGroup >= 0) {
      const row = model.addRowOf(addGroup);
      // the group's last loaded record is the row above its add row
      const last = this.rows.recordRowAt(row - 1);
      const above = last >= 0 ? this.args.records[last] : undefined;
      insert.index = last >= 0 ? last + 1 : this.rows.coreRowOf(row);
      insert.anchor =
        above === undefined
          ? null
          : { recordId: this.args.getRecordId(above), position: 'after' };
    }
    return insert;
  }

  /**
   * The grid row of a paste's last line (the range's head): a record's
   * row, or past the last record's row for the inserted lines (they follow
   * it, in its group, once rendered). On a group's add row the inserts
   * take the add row's place and the rows after it.
   */
  pasteHeadRow(
    anchorRow: number,
    at: number,
    lines: number,
    addGroup: number
  ): number {
    if (addGroup >= 0) return anchorRow + lines - 1;
    const last = at + lines - 1;
    const count = this.args.records.length;
    if (last < count) return this.rows.gridRowOf(last);
    const lastRow = count ? this.rows.gridRowOf(count - 1) : -1;
    return lastRow + last - (count - 1);
  }

  /**
   * Whether a clipboard event is on the range: a data cell, a row number
   * while whole rows are selected, a header while whole columns are.
   */
  isRangeTarget(target: EventTarget | null): boolean {
    if (this.focus.isParked(target)) return true;
    const cell = this.dom.dataCell(target);
    if (cell) return this.dom.isClipboardTarget(target, cell);
    const rowCell = this.dom.rowNumberCell(target);
    if (rowCell) {
      return (
        this.selection.rangeKind === 'rows' &&
        this.dom.isClipboardTarget(target, rowCell)
      );
    }
    const header = this.dom.headerCell(target);
    if (header) {
      return (
        this.selection.rangeKind === 'columns' &&
        this.dom.isClipboardTarget(target, header)
      );
    }
    return false;
  }

  startEdit(pos: Pos, cell: HTMLElement, initialKey: string | null): void {
    // an edit ends the copy mark (V03 batch 1)
    if (this.outline.copied) this.outline.copied = null;
    const wrapper = this.wrapper;
    const record = this.rows.recordAt(pos.row);
    const field = this.fields.visibleFields[pos.col];
    if (!wrapper || record === undefined || !field) return;
    const type = this.fields.typeOf(field);
    const recordId = this.args.getRecordId(record);
    const rect = this.dom.rectOf(cell);
    if (!rect) return;
    const layout = type.editorLayout ?? 'cell';
    const upload = uploadOf(field);
    const rejection = this.cells.liveRejection(record, recordId, field.id);
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
      initialKey,
      draft
    });
    this.draftKind = 'text';
    this.draftValue = undefined;
    if (upload) {
      this.editing.onUpload = (files) =>
        this.uploads.uploadFiles(recordId, field, files);
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
    this.args.records[
      this.rows.rowOf(editing.recordId, this.rows.hintOf(editing.pos.row))
    ];

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
    const row = this.rows.rowOf(
      editing.recordId,
      this.rows.hintOf(editing.pos.row)
    );
    if (row < 0) return;
    const pos = { row, col: editing.pos.col };
    const ctx = this.context;
    const touched = [{ id: editing.recordId, fieldId: editing.field.id }];
    if (result && 'value' in result) {
      this.changes.emit(commitValue(ctx, pos, result.value), touched);
    } else if (result && 'text' in result) {
      this.changes.emitText(ctx, pos, result.text, touched);
    } else if (this.draftDirty && this.draftKind === 'value') {
      this.changes.emit(commitValue(ctx, pos, this.draftValue), touched);
    } else if (this.draftDirty) {
      this.changes.emitText(ctx, pos, this.draft, touched);
    }
    if (refocus) {
      // synchronous is safe: the target row already exists
      const model = this.rows.rowModel;
      const from = this.rows.gridRowOf(pos.row);
      let row = clamp(
        from + move[0],
        model.firstRecordRow,
        model.lastRecordRow
      );
      // grouped: over a header or an add row to the next record (V03 8.6)
      if (this.rows.isGrouped && !this.rows.isRecordRow(row)) {
        const next = model.nearestRecordRow(row, move[0] < 0 ? -1 : 1);
        row = next >= 0 ? next : from;
      }
      this.dom.focusGridCell({
        row,
        col: clamp(pos.col + move[1], 0, this.fields.visibleFields.length - 1)
      });
    }
  }

  cancel = (): void => {
    const editing = this.editing;
    if (!editing) return;
    this.editing = null;
    const row = this.rows.rowOf(
      editing.recordId,
      this.rows.hintOf(editing.pos.row)
    );
    if (row < 0) return;
    this.dom.focusGridCell({
      row: this.rows.gridRowOf(row),
      col: editing.pos.col
    });
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
    const row = this.rows.rowOf(
      editing.recordId,
      this.rows.hintOf(editing.pos.row)
    );
    if (row < 0) return;
    this.changes.emit(
      commitValue(this.context, { row, col: editing.pos.col }, value),
      [{ id: editing.recordId, fieldId: editing.field.id }]
    );
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

  /* The empty state (V03 batch 1) */

  /** No records and not loading: a message under the grid (the add row stays the action). */
  get showEmpty(): boolean {
    return this.args.records.length === 0 && !this.args.isLoading;
  }

  /** The field editor is open from the "+" header: it shows as open. */
  get addingField(): boolean {
    return this.fieldEditorState?.returnTo.columnId === ADD_FIELD_COLUMN_ID;
  }

  /** The open field editor, as a list keyed by its state (a new one starts a new form). */
  get fieldEditorList(): FieldEditorState[] {
    return this.fieldEditorState ? [this.fieldEditorState] : [];
  }

  /**
   * The types the field editor offers: `@creatableFieldTypes` (default
   * `CREATABLE_FIELD_TYPES`) that exist, and on edit the field's own type
   * first when it is not one of them (a linked record field keeps its type).
   */
  fieldEditorTypes(
    field: EuiSheetField<T> | undefined,
    mode: FieldEditorState['mode']
  ): SheetFieldEditorType[] {
    const names = [...(this.args.creatableFieldTypes ?? CREATABLE_FIELD_TYPES)];
    if (field && mode !== 'create' && !names.includes(typeName(field))) {
      names.unshift(typeName(field));
    }
    const messages = this.messages as unknown as Record<
      string,
      (() => string) | undefined
    >;
    const types: SheetFieldEditorType[] = [];
    for (const name of names) {
      const type = this.types[name];
      if (!type) continue;
      const entry: SheetFieldEditorType = {
        name,
        label: type.label ?? messages[`fieldType_${name}`]?.() ?? name
      };
      if (type.fieldOptions) entry.fieldOptions = type.fieldOptions;
      types.push(entry);
    }
    return types;
  }

  /**
   * Where the field editor goes: under the header of `columnId` (else the
   * "+" header), its left edge kept inside the wrapper; without either, at
   * the wrapper's top right, under the header row (a hidden field, V03
   * 6.8). The layer places it in the viewport from there (below, or above
   * when there is no room below; clamped, then scrolling).
   */
  fieldEditorPlace(columnId: string): { anchor: WrapperBox } {
    const width = this.wrapper?.offsetWidth ?? FIELD_EDITOR_WIDTH;
    const maxLeft = Math.max(0, width - FIELD_EDITOR_WIDTH);
    const header =
      this.dom.headerElement(columnId) ??
      (this.gridColumns.hasAddFieldColumn
        ? this.dom.headerElement(ADD_FIELD_COLUMN_ID)
        : null);
    const rect = header && this.dom.rectOf(header);
    if (rect) {
      return {
        anchor: {
          top: rect.top,
          left: clamp(rect.left, 0, maxLeft),
          width: rect.width,
          height: rect.height
        }
      };
    }
    const any = this.wrapper?.querySelector<HTMLElement>('[role=columnheader]');
    const anyRect = any && this.dom.rectOf(any);
    return {
      anchor: {
        top: anyRect ? anyRect.top : 0,
        left: maxLeft,
        width: 0,
        height: anyRect ? anyRect.height : 0
      }
    };
  }

  openFieldEditor(
    init: ConstructorParameters<typeof FieldEditorState>[0]
  ): void {
    if (this.editing) this.commit({ refocus: false });
    if (this.menu) this.closeMenu(false);
    this.fieldEditorState = new FieldEditorState(init);
  }

  /**
   * `api.addField`, the "+" column, "Insert left/right": the editor to
   * create a field at `index` among the visible fields (default the end;
   * never before the first field), under `columnId`'s header.
   */
  addField(index?: number, columnId?: string, after?: string): void {
    if (!this.args.onFieldCreate) return;
    const fields = this.fields.visibleFields;
    const count = fields.length;
    const at = clamp(index ?? count, count ? 1 : 0, count);
    const afterId = after ?? fields[at - 1]?.id;
    const anchor =
      columnId ??
      (this.gridColumns.hasAddFieldColumn
        ? ADD_FIELD_COLUMN_ID
        : (afterId ?? ''));
    const position: { index: number; after?: string } = { index: at };
    if (afterId !== undefined) position.after = afterId;
    const types = this.fieldEditorTypes(undefined, 'create');
    const type = types.some((entry) => entry.name === 'text')
      ? 'text'
      : (types[0]?.name ?? 'text');
    this.openFieldEditor({
      mode: 'create',
      position,
      draft: { label: '', type },
      ...this.fieldEditorPlace(anchor),
      returnTo: {
        columnId: anchor,
        index: this.gridColumns.gridIndexOf(anchor)
      }
    });
  }

  /** `api.editField` and "Edit field": the editor on a field, also a hidden one. */
  editField(fieldId: string): void {
    if (!this.args.onFieldUpdate) return;
    const field = this.fields.fieldById(fieldId);
    if (!field || field.manageable === false) return;
    const columnId = this.fields.visibleFieldIds.includes(fieldId)
      ? fieldId
      : ADD_FIELD_COLUMN_ID;
    this.openFieldEditor({
      mode: 'edit',
      fieldId,
      draft: draftOf(field),
      ...this.fieldEditorPlace(columnId),
      returnTo: { columnId, index: this.gridColumns.gridIndexOf(columnId) }
    });
  }

  /** "Duplicate field": `@onFieldCreate` at once, with a copy of the field's draft next to it. */
  duplicateField(fieldId: string): void {
    const handler = this.args.onFieldCreate;
    const index = this.fields.visibleFieldIds.indexOf(fieldId);
    const field = this.fields.visibleFields[index];
    if (!handler || !field || field.manageable === false) return;
    const draft: SheetFieldDraft = {
      ...draftOf(field),
      label: this.messages.duplicateFieldLabel(field.label ?? field.id)
    };
    this.noteCreatedAfter(field.id);
    void handler(draft, {
      index: index + 1,
      after: field.id,
      copyOf: field.id
    });
  }

  /** "Delete field": the confirmation, in the editor's frame (V03 6.6). */
  askDeleteField(fieldId: string): void {
    const field = this.fields.fieldById(fieldId);
    if (!this.args.onFieldDelete || !field || field.manageable === false) {
      return;
    }
    if (this.fields.visibleFieldIds[0] === fieldId) return;
    this.openFieldEditor({
      mode: 'delete',
      fieldId,
      draft: draftOf(field),
      ...this.fieldEditorPlace(fieldId),
      returnTo: {
        columnId: fieldId,
        index: this.gridColumns.gridIndexOf(fieldId)
      }
    });
  }

  /** Save in the editor: `@onFieldCreate` or `@onFieldUpdate`. */
  saveFieldEditor(draft: SheetFieldDraft): void {
    const state = this.fieldEditorState;
    if (!state || state.isSaving) return;
    if (state.mode === 'create') {
      const handler = this.args.onFieldCreate;
      if (!handler) return;
      const position = { ...state.position! };
      this.noteCreatedAfter(position.after);
      this.runFieldHandler(state, () => handler(draft, position));
      return;
    }
    const handler = this.args.onFieldUpdate;
    const previous = this.fields.fieldById(state.fieldId);
    if (!handler || !previous || state.mode !== 'edit') return;
    this.runFieldHandler(state, () =>
      handler(previous.id, draft, { previous })
    );
  }

  /** The delete confirmation's button: `@onFieldDelete`. */
  confirmDeleteField(): void {
    const state = this.fieldEditorState;
    const handler = this.args.onFieldDelete;
    if (!state || state.isSaving || state.mode !== 'delete' || !handler) return;
    const fieldId = state.fieldId!;
    this.runFieldHandler(state, () => handler(fieldId));
  }

  /**
   * Calls a field handler (V03 6.2): without a promise the editor closes
   * at once; with one it stays open, busy, and closes when it resolves or
   * shows the rejection's message.
   */
  runFieldHandler(
    state: FieldEditorState,
    call: () => void | Promise<void>
  ): void {
    state.error = undefined;
    let result: unknown;
    try {
      result = call();
    } catch (error) {
      state.error = errorMessage(error);
      return;
    }
    if (!result || typeof (result as Promise<void>).then !== 'function') {
      this.closeFieldEditor(true);
      return;
    }
    state.isSaving = true;
    (result as Promise<void>).then(
      () => {
        if (isDestroying(this) || isDestroyed(this)) return;
        state.isSaving = false;
        if (this.fieldEditorState === state) this.closeFieldEditor(true);
      },
      (error: unknown) => {
        if (isDestroying(this) || isDestroyed(this)) return;
        state.isSaving = false;
        state.error = errorMessage(error);
      }
    );
  }

  /**
   * Closes the field editor; `refocus` focuses the header it belongs to.
   * Not while its handler's promise is pending: Escape, Cancel, a click
   * outside or a scroll then do nothing, so a rejection is still shown
   * (V03 6.2).
   */
  closeFieldEditor(refocus: boolean): void {
    const state = this.fieldEditorState;
    if (!state || state.isSaving) return;
    this.fieldEditorState = null;
    if (!refocus) return;
    afterRender(this, () => this.dom.focusHeader(state.returnTo));
  }

  /** Without `@onFieldOrderChange` but with the sheet's own order, a created field goes after this one (V03 6.8). */
  noteCreatedAfter(after: string | undefined): void {
    this.createdAfter =
      this.fields.localOrder && !this.args.onFieldOrderChange
        ? { after }
        : null;
  }

  /** Whenever `@fields` or `@hiddenFields` is a new array: after the render, `fieldsRendered`. */
  watchFields = modifier(
    (_element: HTMLElement, [fields, hidden]: [unknown, unknown]) => {
      void fields;
      void hidden;
      afterRender(this, () => this.fieldsRendered());
    }
  );

  /**
   * After `@fields` or `@hiddenFields` changed (V03 6.6): a field that is
   * gone from both, or whose type changed, is forgotten (its undo
   * entries, rejected texts, pending cells, an editor on it); a created
   * field is placed in the sheet's own order; the selection is clamped.
   * A hide moves a field between the two lists and is not a loss.
   */
  fieldsRendered(): void {
    const all = [...this.args.fields, ...(this.args.hiddenFields ?? [])];
    const now = new Map(all.map((field) => [field.id, typeName(field)]));
    const before = this.lastFieldTypes;
    this.lastFieldTypes = now;
    if (!before) return;
    const gone: string[] = [];
    for (const [id, type] of before) {
      if (now.get(id) !== type) gone.push(id);
    }
    const created = this.createdAfter;
    if (created) {
      const added = [...now.keys()].filter((id) => !before.has(id));
      if (added.length) {
        this.createdAfter = null;
        this.placeCreated(added, created.after);
      }
    }
    if (gone.length) this.forgetFields(gone);
    this.selection.clampSelection();
  }

  /** Puts created fields into the sheet's own order after `after`. */
  placeCreated(ids: string[], after: string | undefined): void {
    const order = this.fields.localOrder;
    if (!order || this.args.onFieldOrderChange) return;
    const rest = order.filter((id) => !ids.includes(id));
    const at = after === undefined ? 0 : rest.indexOf(after) + 1;
    if (after !== undefined && at === 0) rest.push(...ids);
    else rest.splice(at, 0, ...ids);
    this.fields.localOrder = rest;
  }

  /** Drops what the sheet keeps per field for fields the owner deleted or retyped (V03 6.6). */
  forgetFields(fieldIds: string[]): void {
    const ids = new Set(fieldIds);
    const prune = (entries: HistoryEntry[]): HistoryEntry[] => {
      const kept: HistoryEntry[] = [];
      for (const entry of entries) {
        let changeSet: ChangeSet | null = entry.changeSet;
        for (const id of fieldIds) {
          if (changeSet) changeSet = withoutField(changeSet, id);
        }
        const rejections = entry.rejections.filter(
          (rejection) => !ids.has(rejection.fieldId)
        );
        if (!changeSet) continue;
        if (
          changeSet === entry.changeSet &&
          rejections.length === entry.rejections.length
        ) {
          kept.push(entry);
          continue;
        }
        const next = { changeSet, rejections };
        this.history.replaceEntry(entry, next);
        kept.push(next);
      }
      return kept;
    };
    this.history.undoStack = prune(this.history.undoStack);
    this.history.redoStack = prune(this.history.redoStack);
    if ([...this.cells.rejections.values()].some((r) => ids.has(r.fieldId))) {
      this.cells.rejections = new Map(
        [...this.cells.rejections].filter(([, r]) => !ids.has(r.fieldId))
      );
    }
    const pendingKeys = [...this.resolve.pendingCells]
      .filter(([, entry]) => entry.cell && ids.has(entry.cell.fieldId))
      .map(([key]) => key);
    const uploadKeys = [...this.resolve.pendingCells.keys()].filter((key) =>
      ids.has(key.slice(key.indexOf('\u0000') + 1))
    );
    const keys = [...new Set([...pendingKeys, ...uploadKeys])];
    if (keys.length) this.resolve.dropPending(keys);
    if (this.editing && ids.has(this.editing.field.id)) this.editing = null;
    const state = this.fieldEditorState;
    // our own save in flight closes the editor itself
    if (state?.fieldId && ids.has(state.fieldId) && !state.isSaving) {
      this.closeFieldEditor(false);
    }
  }

  /** `api.showShortcuts()`, the block's `showShortcuts()` and Ctrl/Cmd+/. */
  showShortcuts = (): void => {
    if (this.editing) this.commit({ refocus: false });
    this.closeMenu(false);
    this.shortcutsOpen = true;
  };

  closeShortcuts = (): void => {
    this.shortcutsOpen = false;
  };

  /** What decides which rows the list shows. */
  get shortcutContext(): ShortcutContext {
    return {
      readOnly: !!this.args.readOnly,
      canInsert: this.canInsert,
      rowNumbers: this.showRowNumbers,
      fieldDrag: this.fields.fieldDrag
    };
  }

  /**
   * How far a cell editor grows past its cell (V03 batch 1): 2 px on each
   * side, less where the grid body's visible area ends (the header, the
   * frozen edge, the scroll bars), so it is not cut off.
   */
  growOf = (
    editing: Editing
  ): {
    top: number;
    right: number;
    bottom: number;
    left: number;
  } => {
    const rect = editing.rect;
    const wrapper = this.wrapper;
    const bounds = this.scroll.scrollBounds();
    const side = (room: number) => clamp(Math.floor(room), 0, 2);
    if (!wrapper || !bounds) return { top: 0, right: 0, bottom: 0, left: 0 };
    const origin = wrapper.getBoundingClientRect();
    const scale = wrapper.offsetWidth ? origin.width / wrapper.offsetWidth : 1;
    const clipLeft =
      bounds.frozenRight !== undefined &&
      editing.pos.col >= this.frozen.frozenCount
        ? bounds.frozenRight
        : bounds.left;
    const toWrapper = (x: number, from: number) => (x - from) / scale;
    return {
      top: side(rect.top - toWrapper(bounds.top, origin.top)),
      left: side(rect.left - toWrapper(clipLeft, origin.left)),
      right: side(
        toWrapper(bounds.right, origin.left) - rect.left - rect.width
      ),
      bottom: side(
        toWrapper(bounds.bottom, origin.top) - rect.top - rect.height
      )
    };
  };

  /** A header drag starting (V03 5.3, CD9) saves the open editor first. */
  @action
  onDragStart(): void {
    if (this.editing) this.commit({ refocus: false });
  }

  <template>
    <div
      class="euiSheet
        {{this.themeClass}}
        {{if this.dragging 'euiSheet--dragging'}}
        {{if this.fillTarget 'euiSheet--dragging euiSheet--filling'}}
        {{if this.scroll.scrolledX 'euiSheet--scrolledX'}}
        {{if this.gridOptions.pinsAddRow 'euiSheet--pinAddRow'}}
        {{this.gridColumns.headerLinesClass}}
        {{if this.outline.rangeOutline 'euiSheet--ranged'}}
        {{if this.addingField 'euiSheet--addingField'}}"
      data-test-subj="euiSheet"
      data-eui-sheet-id={{this.sheetId}}
      ...attributes
      {{this.setupWrapper}}
      {{this.watchRecords @records @groups}}
      {{this.watchFields @fields @hiddenFields}}
      {{this.registerSheetApi}}
      {{on "keydown" this.onKeyDown capture=true}}
      {{on "copy" this.onCopy capture=true}}
      {{on "cut" this.onCut capture=true}}
      {{on "paste" this.onPaste capture=true}}
      {{on "scroll" this.scroll.onScroll capture=true}}
      {{on "mousedown" this.onMouseDown capture=true}}
      {{on "pointerdown" this.onPointerDown capture=true}}
      {{on "pointermove" this.onPointerMove}}
      {{on "pointerup" this.onPointerEnd}}
      {{on "pointercancel" this.onPointerEnd}}
      {{on "click" this.onClickCapture capture=true}}
      {{on "focusin" this.focus.onFocusIn}}
      {{on "focusout" this.focus.onFocusOut}}
      {{on "mouseover" this.onMouseOver}}
      {{on "click" this.onClick}}
      {{on "dblclick" this.onDoubleClick}}
      {{on "contextmenu" this.onContextMenu}}
      {{on "dragstart" this.onDragStart capture=true}}
      {{on "dragover" this.uploads.onDragOver capture=true}}
      {{on "dragleave" this.uploads.onDragLeave}}
      {{on "drop" this.uploads.onDrop capture=true}}
    >
      <style data-eui-sheet-marks>
        {{this.selection.headerMarkCss}}
      </style>
      {{#if (has-block "toolbar")}}
        <div class="euiSheet__toolbar" data-test-subj="euiSheetToolbar">
          {{yield this.blockApi to="toolbar"}}
        </div>
      {{/if}}
      <div
        class="euiSheet__grid"
        style={{this.gridOptions.gridVars}}
        {{this.gridOptions.measureGroupWidth this.rows.isGrouped}}
      >
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
          @columns={{this.gridColumns.columns}}
          @columnVisibility={{this.fields.columnVisibility}}
          @leadingControlColumns={{this.gridColumns.leadingControlColumns}}
          @trailingControlColumns={{this.gridColumns.trailingControlColumns}}
          @gridStyle={{this.gridOptions.gridStyle}}
          @rowCount={{this.rows.rowCount}}
          @renderCellValue={{SheetCell}}
          @renderFooterCellValue={{if this.hasSummary SheetFooterCell}}
          @cellContext={{this.cellContext}}
          @registerApi={{this.registerGridApi}}
          @toolbarVisibility={{false}}
          @height={{@height}}
          @sorting={{this.gridColumns.sorting}}
          @rowHeightsOptions={{this.gridOptions.rowHeightsOptions}}
          @onColumnResize={{this.gridColumns.onColumnResize}}
          @virtualizationOptions={{this.gridOptions.virtualizationOptions}}
        >
          <:controlHeaderCell as |header|>
            {{#if (this.gridColumns.isAddFieldColumn header.columnId)}}
              {{! the "+" column (V03 6.3): a span, the header cell is the grid's focusable header }}
              <span
                class="euiSheet__addField"
                title={{(this.messages.addField)}}
                data-test-subj="euiSheetAddField"
              ><EuiIcon @type="plus" aria-hidden="true" /><span
                  class="euiSheet__srOnly"
                >{{this.messages.addField}}</span></span>
            {{else}}
              <RowNumberHeader @sheet={{this}} />
            {{/if}}
          </:controlHeaderCell>
          <:controlCell as |cell|>
            {{! the "+" column's body cells are empty and inert }}
            {{#unless (this.gridColumns.isAddFieldColumn cell.columnId)}}
              <RowNumberCell
                @sheet={{this}}
                @rowIndex={{cell.rowIndex}}
                @setCellProps={{cell.setCellProps}}
              />
            {{/unless}}
          </:controlCell>
          <:controlFooterCell as |cell|>
            {{#unless (this.gridColumns.isAddFieldColumn cell.columnId)}}
              <SheetControlFooterCell
                @sheet={{this}}
                @setCellProps={{cell.setCellProps}}
              />
            {{/unless}}
          </:controlFooterCell>
        </EuiDataGrid>
      </div>
      {{#if this.outline.copiedOutline}}
        <RangeOutline
          @sheet={{this}}
          @range={{this.outline.copiedOutline}}
          @tick={{this.scroll.layoutTick}}
          @records={{@records}}
          @columns={{this.gridColumns.columns}}
          @rowHeight={{this.gridOptions.rowHeight}}
          @kind="copied"
        />
      {{/if}}
      {{#if this.fillTarget}}
        {{! the fill drag's target area, dashed (V03 batch 1) }}
        <RangeOutline
          @sheet={{this}}
          @range={{this.fillTarget}}
          @tick={{this.scroll.layoutTick}}
          @records={{@records}}
          @columns={{this.gridColumns.columns}}
          @rowHeight={{this.gridOptions.rowHeight}}
          @kind="fill"
        />
      {{/if}}
      {{#if this.outline.flashOutline}}
        <RangeOutline
          @sheet={{this}}
          @range={{this.outline.flashOutline}}
          @tick={{this.scroll.layoutTick}}
          @records={{@records}}
          @columns={{this.gridColumns.columns}}
          @rowHeight={{this.gridOptions.rowHeight}}
          @kind="flash"
        />
      {{/if}}
      {{#if this.outline.rangeOutline}}
        {{! before the fill handle, which stays on top }}
        <RangeOutline
          @sheet={{this}}
          @range={{this.outline.rangeOutline}}
          @tick={{this.scroll.layoutTick}}
          @records={{@records}}
          @columns={{this.gridColumns.columns}}
          @rowHeight={{this.gridOptions.rowHeight}}
        />
      {{/if}}
      {{#if this.showEmpty}}
        <div class="euiSheet__empty" data-test-subj="euiSheetEmpty">
          {{#if (has-block "empty")}}
            {{yield this.blockApi to="empty"}}
          {{else}}
            {{! the add row above is the action when inserting is allowed }}
            <span role="status">{{this.messages.noRecords}}</span>
          {{/if}}
        </div>
      {{/if}}
      {{#if this.fillHandleRange}}
        <FillHandle
          @sheet={{this}}
          @range={{this.fillHandleRange}}
          @tick={{this.scroll.layoutTick}}
          @records={{@records}}
          @rowHeight={{this.gridOptions.rowHeight}}
          @onPress={{this.onFillHandlePress}}
        />
      {{/if}}
      <ImeCatcher @sheet={{this}} />
      {{#if (has-block "footer")}}
        <div class="euiSheet__footer" data-test-subj="euiSheetFooter">
          {{yield this.blockApi to="footer"}}
        </div>
      {{/if}}
      {{#if this.shortcutsOpen}}
        <ShortcutList @sheet={{this}} />
      {{/if}}
      {{#if this.menu}}
        <RowMenu
          @sheet={{this}}
          @anchor={{this.menuAnchor}}
          @items={{this.menuItems}}
          @onSelect={{this.onMenuSelect}}
        />
      {{/if}}
      {{#each this.fieldEditorList key="@identity" as |state|}}
        <FieldEditor @sheet={{this}} @state={{state}} />
      {{/each}}
      {{#if this.expandedRecordValue}}
        {{#if (isModal this.expandedShell)}}
          <RecordModal @sheet={{this}} @record={{this.expandedRecordValue}} />
        {{else}}
          <RecordFlyout @sheet={{this}} @record={{this.expandedRecordValue}} />
        {{/if}}
      {{/if}}
      {{#each this.editingList key="@identity" as |editing|}}
        <EditorFrame
          @sheet={{this}}
          @rect={{editing.rect}}
          @grow={{this.growOf editing}}
          @layout={{editing.layout}}
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
        {{#if this.focus.cellError}}
          <div
            class="euiSheet__cellError euiSheet__cellError--{{this.focus.cellError.placement}}
              {{if this.focus.cellError.notice 'euiSheet__cellError--notice'}}"
            data-test-subj="euiSheetCellError"
            style={{this.focus.cellError.style}}
          >
            {{#if this.focus.cellError.notice}}
              <div class="euiSheet__cellNotice"><EuiIcon
                  @type="lock"
                  @size="s"
                  aria-hidden="true"
                />{{this.messages.cellReadOnly}}</div>
            {{else}}
              {{#each this.focus.cellError.messages as |message|}}
                <div>{{message}}</div>
              {{/each}}
            {{/if}}
          </div>
        {{/if}}
      </div>
    </div>
  </template>
}
