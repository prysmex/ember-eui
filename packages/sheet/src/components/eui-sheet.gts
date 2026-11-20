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
import { guidFor } from '@ember/object/internals';
import { cancel } from '@ember/runloop';
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
  isReadOnly,
  parseTsv,
  pasteMatrix,
  planPaste,
  rangeMatrix,
  tileMatrix,
  toTsv,
  valueOf
} from '../core/index.ts';
import type { PasteInsert } from '../core/index.ts';
import { builtInSheetFieldTypes } from '../field-types.ts';
import FieldEditor from '../-private/field-editor.gts';
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
  afterRender,
  clamp,
  nextTempId,
  samePos,
  stop
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
import SheetEdit from '../-private/sheet/edit.ts';
import SheetExpanded from '../-private/sheet/expanded.ts';
import SheetFieldEditor from '../-private/sheet/field-editor.ts';
import SheetRowMenu from '../-private/sheet/row-menu.ts';
import SheetFollow from '../-private/sheet/follow.ts';
import SheetDrag from '../-private/sheet/drag.ts';
import SheetTouch from '../-private/sheet/touch.ts';
import SheetClicks from '../-private/sheet/clicks.ts';
import SheetFilling from '../-private/sheet/filling.ts';

import type { Pos, Range, SheetContext, SheetMessages } from '../core/index.ts';
import type { ShortcutContext } from '../-private/shortcuts.ts';
import type {
  EuiSheetFieldType,
  EuiSheetSignature,
  SheetApi,
  SheetBlockApi
} from '../types.ts';
import type EuiI18n from '@ember-eui/core/services/eui-i18n';
import type { EuiDataGridRefProps } from '@ember-eui/core/utils/data-grid/types';
import type Owner from '@ember/owner';
import type { CellView } from '../-private/sheet/types.ts';

export type { EuiSheetSignature };
export type { CellView };

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
  readonly edit = new SheetEdit<T>(this);
  readonly expanded = new SheetExpanded<T>(this);
  readonly fieldEditor = new SheetFieldEditor<T>(this);
  readonly rowMenu = new SheetRowMenu<T>(this);
  readonly follow = new SheetFollow<T>(this);
  readonly drag = new SheetDrag<T>(this);
  readonly touch = new SheetTouch<T>(this);
  readonly clicks = new SheetClicks<T>(this);
  readonly filling = new SheetFilling<T>(this);
  /** The shortcut list is open (V03 5.5). */
  @tracked shortcutsOpen = false;

  /** The grid's API (not the sheet's: that is `sheetApi`). */
  gridApi: EuiDataGridRefProps | null = null;
  wrapper: HTMLElement | null = null;

  /** Stable object: the grid passes it to every cell renderer. */
  cellContext = { sheet: this as unknown as EuiSheet<object> };

  /** The sheet's API for its owner (`@registerApi`): one stable object. */
  sheetApi: SheetApi = {
    undo: () => this.history.undo(),
    redo: () => this.history.redo(),
    focusCell: (cell) => this.selection.focusRecordCell(cell),
    remapIds: (ids) => this.history.remapIds(ids),
    clearHistory: () => this.history.clearHistory(),
    expandRecord: (recordId) => {
      if (recordId === null) this.expanded.closeExpanded();
      else this.expanded.expandRecord(recordId, null);
    },
    insertRecord: (options = {}) => this.records.insertFromApi(options),
    deleteRecords: (ids) => this.records.deleteRecordIds(ids, false),
    showShortcuts: () => this.showShortcuts(),
    editField: (fieldId) => this.fieldEditor.editField(fieldId),
    addField: (options = {}) => this.fieldEditor.addField(options.index)
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
    this.drag.stopWatchingRelease();
    this.filling.stopFillDrag();
    this.drag.autoScroll.stop();
    this.touch.cancelLongPress();
    document.removeEventListener(
      'mousedown',
      this.rowMenu.onDocumentMouseDown,
      true
    );
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
      addField: () => this.fieldEditor.addField(),
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
    if (this.edit.editing && this.dom.isInEditor(target)) {
      this.onEditKeyDown(event);
      return;
    }
    // the field editor's keys are its own (its focus trap has Escape)
    if (this.dom.isInFieldEditor(target)) return;
    if (this.rowMenu.menu && this.dom.isInMenu(target)) {
      // the panel has ArrowUp/Down and Enter; Escape is the sheet's
      if (event.key === 'Escape' || event.key === 'Tab') {
        stop(event);
        this.rowMenu.closeMenu(true);
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
      !this.edit.editing &&
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
        this.fieldEditor.addField();
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
      this.rowMenu.openMenuAt(pos.row, pos.col, cell);
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
      this.expanded.expandRecord(recordId, { recordId, fieldId: field.id });
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
      if (!this.edit.editInRecord(pos)) this.edit.startEdit(pos, cell, null);
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
      this.edit.startEdit(pos, cell, key);
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
      this.filling.fill();
      return true;
    }
    if (letter === 'r' && !event.shiftKey) {
      // C11: also keeps the browser from reloading the page
      stop(event);
      this.filling.fillRightSelection();
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
      if (cell) this.rowMenu.openMenuAt(row, null, cell);
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
      this.expanded.expandRecord(recordId, { recordId, fieldId: null });
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

  onEditKeyDown(event: KeyboardEvent): void {
    // a key the editor claims is the editor's: no prevent, no stop, no action
    if (this.edit.editing?.type.handlesKey?.(event)) return;
    switch (event.key) {
      case 'Enter':
        stop(event);
        this.edit.commit({ move: [1, 0] });
        break;
      case 'Tab':
        stop(event);
        this.edit.commit({ move: [0, event.shiftKey ? -1 : 1] });
        break;
      case 'Escape':
        stop(event);
        this.edit.cancel();
        break;
      // anything else: the editor handles it
    }
  }

  @action
  onCopy(event: ClipboardEvent): void {
    const target = event.target;
    if (this.edit.editing && this.dom.isInEditor(target)) return;
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
    if (this.edit.editing && this.dom.isInEditor(target)) return;
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
    if (this.edit.editing && this.dom.isInEditor(target)) return;
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

  /* The empty state (V03 batch 1) */

  /** No records and not loading: a message under the grid (the add row stays the action). */
  get showEmpty(): boolean {
    return this.args.records.length === 0 && !this.args.isLoading;
  }

  /** `api.showShortcuts()`, the block's `showShortcuts()` and Ctrl/Cmd+/. */
  showShortcuts = (): void => {
    if (this.edit.editing) this.edit.commit({ refocus: false });
    this.rowMenu.closeMenu(false);
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

  <template>
    <div
      class="euiSheet
        {{this.themeClass}}
        {{if this.drag.dragging 'euiSheet--dragging'}}
        {{if this.filling.fillTarget 'euiSheet--dragging euiSheet--filling'}}
        {{if this.scroll.scrolledX 'euiSheet--scrolledX'}}
        {{if this.gridOptions.pinsAddRow 'euiSheet--pinAddRow'}}
        {{this.gridColumns.headerLinesClass}}
        {{if this.outline.rangeOutline 'euiSheet--ranged'}}
        {{if this.fieldEditor.addingField 'euiSheet--addingField'}}"
      data-test-subj="euiSheet"
      data-eui-sheet-id={{this.sheetId}}
      ...attributes
      {{this.setupWrapper}}
      {{this.follow.watchRecords @records @groups}}
      {{this.fieldEditor.watchFields @fields @hiddenFields}}
      {{this.registerSheetApi}}
      {{on "keydown" this.onKeyDown capture=true}}
      {{on "copy" this.onCopy capture=true}}
      {{on "cut" this.onCut capture=true}}
      {{on "paste" this.onPaste capture=true}}
      {{on "scroll" this.scroll.onScroll capture=true}}
      {{on "mousedown" this.drag.onMouseDown capture=true}}
      {{on "pointerdown" this.touch.onPointerDown capture=true}}
      {{on "pointermove" this.touch.onPointerMove}}
      {{on "pointerup" this.touch.onPointerEnd}}
      {{on "pointercancel" this.touch.onPointerEnd}}
      {{on "click" this.touch.onClickCapture capture=true}}
      {{on "focusin" this.focus.onFocusIn}}
      {{on "focusout" this.focus.onFocusOut}}
      {{on "mouseover" this.drag.onMouseOver}}
      {{on "click" this.clicks.onClick}}
      {{on "dblclick" this.clicks.onDoubleClick}}
      {{on "contextmenu" this.rowMenu.onContextMenu}}
      {{on "dragstart" this.edit.onDragStart capture=true}}
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
      {{#if this.filling.fillTarget}}
        {{! the fill drag's target area, dashed (V03 batch 1) }}
        <RangeOutline
          @sheet={{this}}
          @range={{this.filling.fillTarget}}
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
      {{#if this.filling.fillHandleRange}}
        <FillHandle
          @sheet={{this}}
          @range={{this.filling.fillHandleRange}}
          @tick={{this.scroll.layoutTick}}
          @records={{@records}}
          @rowHeight={{this.gridOptions.rowHeight}}
          @onPress={{this.filling.onFillHandlePress}}
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
      {{#if this.rowMenu.menu}}
        <RowMenu
          @sheet={{this}}
          @anchor={{this.rowMenu.menuAnchor}}
          @items={{this.rowMenu.menuItems}}
          @onSelect={{this.rowMenu.onMenuSelect}}
        />
      {{/if}}
      {{#each this.fieldEditor.fieldEditorList key="@identity" as |state|}}
        <FieldEditor @sheet={{this}} @state={{state}} />
      {{/each}}
      {{#if this.expanded.expandedRecordValue}}
        {{#if (isModal this.expanded.expandedShell)}}
          <RecordModal
            @sheet={{this}}
            @record={{this.expanded.expandedRecordValue}}
          />
        {{else}}
          <RecordFlyout
            @sheet={{this}}
            @record={{this.expanded.expandedRecordValue}}
          />
        {{/if}}
      {{/if}}
      {{#each this.edit.editingList key="@identity" as |editing|}}
        <EditorFrame
          @sheet={{this}}
          @rect={{editing.rect}}
          @grow={{this.edit.growOf editing}}
          @layout={{editing.layout}}
          @onFocusOut={{this.edit.onEditorFocusOut}}
        >
          {{#if editing.type.editor}}
            <editing.type.editor
              @value={{this.edit.editorValue editing}}
              @field={{editing.field}}
              @record={{this.edit.editorRecord editing}}
              @draft={{editing.draft}}
              @initialKey={{editing.initialKey}}
              @onDraftChange={{this.edit.onDraftChange}}
              @onDraftValue={{this.edit.onDraftValue}}
              @onSave={{this.edit.onEditorSave}}
              @onUpload={{editing.onUpload}}
              @onCommit={{this.edit.onEditorCommit}}
              @onCancel={{this.edit.cancel}}
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
