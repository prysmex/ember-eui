/** Ember-layer types: field types with components, and the signatures (PACKAGE-DESIGN.md 9.1). */
import type {
  CellErrors,
  ChangeSet,
  EuiSheetField,
  FieldType,
  RecordId,
  RecordInsert,
  ResolveRequest,
  ResolveResult,
  SheetFieldDraft,
  SheetGroup,
  SheetGroupBy,
  SheetMessages,
  ValidateContext
} from './core/index.ts';
import type { ComponentLike } from '@glint/template';

export interface EuiSheetFieldType<
  V = unknown,
  F extends EuiSheetField = EuiSheetField
> extends FieldType<V, F> {
  /** Display component. Default: the formatted text. */
  cell?: ComponentLike<SheetCellSignature<V, F>>;
  /** Editor component. Without one the type has no edit mode (navKey and the cell's @onCommit still work). */
  editor?: ComponentLike<SheetEditorSignature<V, F>>;
  /**
   * 'cell': the editor covers the cell. 'panel': a panel under (or above)
   * the cell. 'expand': starts at the cell's box and grows (long text).
   * Default 'cell'.
   */
  editorLayout?: 'cell' | 'panel' | 'expand';
  /** Whether a printable key opens the editor. Default: yes. Space never does. */
  opensOnKey?: (key: string) => boolean;
  /** Keys the editor handles itself while it is open. Default: none. */
  handlesKey?: (event: KeyboardEvent) => boolean;
  /**
   * An EUI icon type (e.g. `'arrowDown'`, `'calendar'`) shown at the end of
   * the hovered or selected cell; a click on it opens the editor at once.
   * Default: none (a second click on the selected cell opens it).
   */
  opener?: string;
  /**
   * A click anywhere in the cell saves the value it returns (the checkbox
   * toggles), instead of selecting then editing. `undefined`: nothing.
   */
  onCellClick?: (
    value: V | null | undefined,
    field: F,
    record: unknown
  ) => { value: V | null } | undefined;
  /**
   * The grid schema of the column (`'numeric'`, `'datetime'`, `'boolean'`,
   * `'currency'`): the header menu's sort labels ("Sort Low-High") and the
   * header's alignment. Default: none.
   */
  schema?: string;
  /** The type's name in the field editor's type select (V03 6.4). Default: `messages.fieldType_<name>`, else the name. */
  label?: string;
  /**
   * The type's own part of the field editor: its options (a select's
   * options, a currency's code). It gets the draft and patches it.
   */
  fieldOptions?: ComponentLike<SheetFieldOptionsSignature>;
}

/** What a type's `fieldOptions` component gets (V03 6.4). */
export interface SheetFieldOptionsSignature {
  Args: {
    draft: SheetFieldDraft;
    /** The field being edited; absent on create. A part that is a function there (`options(record)`) is not editable: hide it. */
    field?: EuiSheetField;
    /** Merges these keys into the draft. */
    onChange: (patch: Record<string, unknown>) => void;
    messages: SheetMessages;
  };
}

/** One type the field editor offers. */
export interface SheetFieldEditorType {
  name: string;
  label: string;
  /** The type's `fieldOptions`, for an app editor that wants to show it. */
  fieldOptions?: ComponentLike<SheetFieldOptionsSignature>;
}

/**
 * What `@fieldEditor` gets (V03 6.4): it replaces the field editor's
 * content; the sheet keeps the frame, its position, focus return and the
 * saving state.
 */
export interface SheetFieldEditorSignature<T = any> {
  Args: {
    mode: 'create' | 'edit';
    /** The field being edited; absent on create. */
    field?: EuiSheetField<T>;
    /** The starting values. */
    draft: SheetFieldDraft;
    /** The types it may offer, in order (`@creatableFieldTypes`; on edit also the field's own). */
    types: SheetFieldEditorType[];
    /** The handler's promise is pending. */
    isSaving: boolean;
    /** The message of the handler's rejected promise. */
    error?: string;
    onSave: (draft: SheetFieldDraft) => void;
    onCancel: () => void;
    messages: SheetMessages;
    themeClass?: string;
  };
}

export interface SheetCellSignature<
  V = unknown,
  F extends EuiSheetField = EuiSheetField,
  T = any
> {
  Args: {
    value: V | null | undefined;
    /** type.format(value). */
    text: string;
    field: F;
    record: T;
    errors: string[];
    readOnly: boolean;
    /** Saves a value from the cell itself (a checkbox, a rating star). */
    onCommit: (value: V) => void;
    /** The sheet's `@highlight`: a cell that shows text may mark it (`EuiHighlight`). */
    highlight?: string;
    /** `type.link(value)` when its scheme is one the sheet opens: draw the text as a link (`[data-eui-sheet-link]`). */
    link?: string;
  };
}

export type SheetEditorResult<V> = { value: V } | { text: string };

export interface SheetEditorSignature<
  V = unknown,
  F extends EuiSheetField = EuiSheetField,
  T = any
> {
  Args: {
    value: V | null | undefined;
    field: F;
    record: T;
    /** Initial text: the typed character, else the cell's rejected text, else type.format(value). */
    draft: string;
    /** The printable key that opened the editor, or null (Enter, F2, double-click). */
    initialKey: string | null;
    /** Reports the text to parse if the editor is closed by blur, scroll, or a key the sheet handles. */
    onDraftChange: (text: string) => void;
    /**
     * Reports a value to save as is if the editor is closed that way (a
     * multi-select's toggled options): the last of `onDraftChange` and
     * `onDraftValue` called wins. Optional for wrappers; the sheet always
     * passes it.
     */
    onDraftValue?: (value: V) => void;
    /** Saves a value and keeps the editor open (a removed file). The sheet always passes it. */
    onSave?: (value: V) => void;
    /**
     * Attachment fields: uploads files through `field.upload` and appends
     * them to the value read when the upload ends; the promise rejects
     * when the upload fails. The sheet passes it when the field has `upload`.
     */
    onUpload?: (files: File[]) => Promise<void>;
    /** Closes the editor. `{ value }` is saved as is, `{ text }` goes through type.parse, nothing saves the reported draft. `move` is [rows, cols]; default [0, 0]. */
    onCommit: (
      result?: SheetEditorResult<V>,
      options?: { move?: [number, number] }
    ) => void;
    /** Closes the editor without a change and focuses the cell. */
    onCancel: () => void;
    messages: SheetMessages;
    /**
     * The class that defines the sheet's theme colours (`--euiSheet-*`). An
     * editor that renders a surface outside the sheet (a wormholed list or
     * calendar) adds it to that surface, which otherwise gets the light
     * fallbacks. Optional, so a wrapper that renders a built-in editor
     * itself (`SheetInputEditor`) keeps working; the sheet always passes it.
     */
    themeClass?: string;
  };
}

/**
 * What `@registerApi` gives the owner: one stable object, passed once,
 * after the first render.
 */
export interface SheetApi {
  /** Ctrl/Cmd+Z: emits the undo of the last change made in the sheet. */
  undo(): void;
  /** Ctrl/Cmd+Shift+Z: emits the last undone change again. */
  redo(): void;
  /** Focuses a cell by record and field. No-op when the record is not in `@records` or the field is not shown. */
  focusCell(cell: { recordId: RecordId; fieldId: string }): void;
  /**
   * Tells the sheet the ids the owner gave to inserted (or restored)
   * records: `{ [tempId or old id]: newId }`. The undo history, the
   * rejected texts and a pending focus are rewritten, so undo still finds
   * them. Call it before (or with) the `@records` that carry the new ids.
   */
  remapIds(ids: Record<string, RecordId>): void;
  /** Drops the undo and redo stacks (call it when your data changed wholesale). */
  clearHistory(): void;
  /** Opens the expanded record of a record in `@records` (`null` closes it). */
  expandRecord(recordId: RecordId | null): void;
  /**
   * Emits the insert of one record: next to `anchor` when given (a record
   * in `@records`), else at the end. `values` default to `@newRecordValues`.
   */
  insertRecord(options?: {
    anchor?: RecordInsert['anchor'];
    values?: Record<string, unknown>;
  }): void;
  /** Emits the delete of these records (ids not in `@records` are ignored). */
  deleteRecords(ids: RecordId[]): void;
  /** Opens the shortcut list (as Ctrl/Cmd+/ on the grid). */
  showShortcuts(): void;
  /** Opens the field editor on a field (also a hidden one). Needs `@onFieldUpdate`. */
  editField(fieldId: string): void;
  /** Opens the field editor to create a field at `index` among the visible fields (default: the end). Needs `@onFieldCreate`. */
  addField(options?: { index?: number }): void;
}

/** An app item of the row menu (`@rowActions`). */
export interface SheetRowAction<T = any> {
  id: string;
  label: string;
  /** An EUI icon type. */
  icon?: string;
  color?: 'danger';
  /** Disables the item for these records. */
  isDisabled?: (records: T[]) => boolean;
  /** The records of the selection: the checked ones when any is checked, else the selected rows. */
  onSelect: (records: T[]) => void;
}

/** One sort key. The same shape as EmberSearchUi's `SortItem`. */
export interface SheetSort {
  field: string;
  direction: 'asc' | 'desc';
}

/** Row heights: one line, then 2, 4 and 6 lines. */
export type SheetRowHeight = 'short' | 'medium' | 'tall' | 'extraTall';

/** What the `<:toolbar>` and `<:footer>` blocks yield (V02-DESIGN.md 3.6). */
export interface SheetBlockApi<T = any> {
  api: SheetApi;
  /** The visible fields, in display order. */
  fields: EuiSheetField<T>[];
  /** The fields that are not shown. */
  hiddenFields: EuiSheetField<T>[];
  /** `@sort`, or `[]`. */
  sort: SheetSort[];
  rowHeight: SheetRowHeight;
  /** The checked records of `@records`, in their order. */
  checkedRecords: T[];
  /** Each calls the matching handler, or changes the sheet's own state without one. */
  hideField(fieldId: string): void;
  showField(fieldId: string): void;
  setRowHeight(rowHeight: SheetRowHeight): void;
  /** Calls `@onSortChange`; nothing without it. */
  setSort(sort: SheetSort[]): void;
  /** Opens the shortcut list: for a toolbar button. */
  showShortcuts(): void;
  /** Opens the field editor to add a field at the end (with `@onFieldCreate`; nothing without it). */
  addField(): void;
}

/** The cell's box relative to the sheet's wrapper, in CSS px. */
export interface SheetEditorRect {
  top: number;
  left: number;
  width: number;
  height: number;
  /** The wrapper's height, for a panel placed above the cell. */
  wrapperHeight: number;
}

export interface EuiSheetSignature<T> {
  Element: HTMLDivElement;
  Args: {
    fields: EuiSheetField<T>[];
    records: T[];
    getRecordId: (record: T) => RecordId;
    onChange: (changeSet: ChangeSet) => void;
    /** Owner errors: recordId (as a string) → fieldId → message(s). Shown last. */
    cellErrors?: CellErrors;
    height?: number | string;
    /** App field types, merged over the built-ins. Keep the object stable (not created in a template). */
    fieldTypes?: Record<string, EuiSheetFieldType<any, any>>;
    /** Every field read-only. */
    readOnly?: boolean;
    /** Overrides of the built-in messages; wins over `eui-i18n` translations. */
    messages?: Partial<SheetMessages>;
    /** The grid's aria-label. Default 'Sheet'. */
    ariaLabel?: string;
    /**
     * Record, cross-row and async rules (PACKAGE-DESIGN.md 9.4, layers 4–6).
     * Runs (debounced) on first render, when `@records` changes and after
     * each emitted change set. A newer run aborts `signal`; a stale result
     * is discarded, and an error is dropped for a record that changed since
     * its run started.
     */
    validate?: (
      context: ValidateContext<T>
    ) => CellErrors | Promise<CellErrors>;
    /** Receives the sheet's API (`undo`, `redo`, `focusCell`, `remapIds`, `clearHistory`, `expandRecord`, `insertRecord`, `deleteRecords`, `showShortcuts`, `editField`, `addField`) once, after the first render. */
    registerApi?: (api: SheetApi) => void;
    /**
     * Fields that exist but are not shown in the grid: listed in the
     * expanded record after `@fields`, copied by duplicate, restored by
     * undo, given to the blocks (`showField`).
     */
    hiddenFields?: EuiSheetField<T>[];
    /**
     * The ids of the hidden fields after a "Hide" (header menu, block
     * `hideField`) or a block's `showField`: the ids of `@hiddenFields`
     * plus or minus one. With it the sheet shows exactly `@fields`; update
     * `@fields` and `@hiddenFields`. Without it the sheet hides and shows
     * fields itself.
     */
    onHiddenFieldsChange?: (fieldIds: string[]) => void;
    /** The visible ids in their new order after a "Move left/right" or a header drag (the first field stays first). With it, update `@fields`; without it the sheet keeps its own order. */
    onFieldOrderChange?: (fieldIds: string[]) => void;
    /** Drag a header to reorder the fields (with the pointer, or Space and the arrows on a focused header); emits `@onFieldOrderChange`. Default true. */
    fieldDrag?: boolean;
    /** Lines a header label may wrap to. Default 1. */
    headerLines?: 1 | 2 | 3;
    /**
     * Add a field (V03 6.2): the "+" column, the header menu's "Insert
     * left/right" and "Duplicate field". `position.index` is among the
     * visible fields; `after` is the visible field before it; `copyOf` is
     * set by a duplicate. Build the field (`{ id, ...draft }`) and pass the
     * new `@fields`. A returned promise keeps the editor open, busy; a
     * rejection shows its message there.
     */
    onFieldCreate?: (
      draft: SheetFieldDraft,
      position: { index: number; after?: string; copyOf?: string }
    ) => void | Promise<void>;
    /** "Edit field" in the header menu: `{ ...previous, ...draft }`. The sheet changes no value on a type change (`convertField`). */
    onFieldUpdate?: (
      fieldId: string,
      draft: SheetFieldDraft,
      context: { previous: EuiSheetField<T> }
    ) => void | Promise<void>;
    /** "Delete field" in the header menu, after a confirmation. Not undoable from the sheet. */
    onFieldDelete?: (fieldId: string) => void | Promise<void>;
    /** Replaces the field editor's content (the sheet keeps its frame). */
    fieldEditor?: ComponentLike<SheetFieldEditorSignature<T>>;
    /** The types the field editor offers, in order. Default: text, longText, number, currency, percent, checkbox, singleSelect, multiSelect, date, duration, rating, url, email, phone. */
    creatableFieldTypes?: string[];
    /** Column widths in px by field id; wins over `field.width`. */
    fieldWidths?: Record<string, number>;
    /** Called after a column is resized. Without it the sheet keeps the width itself. */
    onFieldWidthChange?: (fieldId: string, width: number) => void;
    /** Row height. Default `'short'` (one line). */
    rowHeight?: SheetRowHeight;
    /** With it the sheet shows exactly `@rowHeight`; without it a block's `setRowHeight` changes it locally. */
    onRowHeightChange?: (rowHeight: SheetRowHeight) => void;
    /** The owner's sort, drawn as header arrows (only with `@onSortChange`). The sheet never sorts. */
    sort?: SheetSort[];
    /** The header menu's "Sort" items call it with the whole new sort. Without it there are no sort items and no arrows. */
    onSortChange?: (sort: SheetSort[]) => void;
    /** The header menu's "Filter by this field" (shown only with it). */
    onFilterByField?: (fieldId: string) => void;
    /** A term the owner searched for: matching text is highlighted in cells. */
    highlight?: string;
    /** Shows a thin progress bar over the grid; the grid stays usable. */
    isLoading?: boolean;
    /** Text per field id for the summary bar (`''`: the row-number column). Passing it, even `{}`, shows the bar. */
    summary?: Record<string, string>;
    /** Leading fields kept in view on horizontal scroll (the row numbers with them). Default 0 (off); 1 freezes the first field. Costs rendering every column of the rows in view. */
    frozenFields?: number;
    /** The leading row-number column (position, checkbox, expand icon). Default true. */
    rowNumbers?: boolean;
    /** What the row-number cell shows. Default: the position, `rowNumberOffset + index + 1`. */
    rowLabel?: (record: T, position: number) => string;
    /** Position of the first record (paged data): row numbers start at offset + 1. Default 0. */
    rowNumberOffset?: number;
    /**
     * Group headers (V03 8.1, 8.2), depth-first in display order: each
     * takes its next `loaded` records of `@records`, in order. Absent or
     * empty: no groups.
     */
    groups?: SheetGroup[];
    /** The owner's group-by (V03 8.1): drawn in the header menu and given to the blocks. */
    groupBy?: SheetGroupBy[];
    /** Shows "Group by this field" / "Remove grouping" in the header menu. */
    onGroupByChange?: (groupBy: SheetGroupBy[]) => void;
    /** Shows the header's toggle; the owner drops or restores the group's records. */
    onGroupToggle?: (key: string, collapsed: boolean) => void;
    /** Inserting records (the add row, Shift+Enter, the menu). Default `!@readOnly`. */
    canInsert?: boolean;
    /** Deleting records (the menu). Default `!@readOnly`. */
    canDelete?: boolean;
    /** Values of a new record, from its neighbours. Default `{}`. */
    newRecordValues?: (context: {
      above: T | undefined;
      below: T | undefined;
    }) => Record<string, unknown>;
    /** Checked rows. With `@onCheckedChange` the sheet shows exactly these; without it, it keeps its own. */
    checkedRecordIds?: RecordId[];
    onCheckedChange?: (ids: RecordId[]) => void;
    /** The expanded record. With `@onExpandedRecordChange` the sheet shows exactly this; without it, it keeps its own. */
    expandedRecordId?: RecordId | null;
    onExpandedRecordChange?: (id: RecordId | null) => void;
    /** How the expanded record is shown. Default 'flyout'. */
    expandedRecord?: 'flyout' | 'modal';
    /** Extra items of the row menu, before "Delete". */
    rowActions?: SheetRowAction<T>[];
    /**
     * Bulk resolve (V02-DESIGN.md 8.2): typed or pasted text a type answers
     * `{ unresolved }` for (linked records, users, an app's own types) is
     * shown as pending and sent here, once per paste or typed commit, one
     * request per field. The resolved cells arrive as a second change set
     * (source 'resolve'), one undo entry with the paste. Without it such
     * text is rejected. `signal` is aborted when none of the call's cells
     * is still pending (the user wrote over them) or the sheet is destroyed.
     */
    onResolve?: (
      requests: ResolveRequest<T>[],
      options: { signal: AbortSignal }
    ) => Promise<ResolveResult>;
    /**
     * Where a click on the selected cell, or Enter, edits (V02-DESIGN.md
     * 8.5): `'cell'`, the editor over the cell; `'record'`, the expanded
     * record with that field's editor open; `'auto'` (default), the record
     * on a coarse pointer (a phone) when the sheet is narrower than 600 px,
     * else the cell. Typing on a cell always edits in the cell.
     */
    editIn?: 'cell' | 'record' | 'auto';
  };
  Blocks: {
    /** Above the grid, inside the sheet: your own controls (field picker, search, sort). */
    toolbar: [SheetBlockApi<T>];
    /** Below the grid: paging, counts. */
    footer: [SheetBlockApi<T>];
    /** Replaces the "No records" message shown under the grid when `@records` is empty and not loading. */
    empty: [SheetBlockApi<T>];
  };
}
