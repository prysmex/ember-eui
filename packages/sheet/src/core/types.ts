/**
 * Types of the sheet's core: fields, field types, change sets and errors.
 * Plain TypeScript, no Ember (PACKAGE-DESIGN.md 5.1).
 */
import type { SheetMessages } from './messages.ts';

export type RecordId = string | number;

/** One option of a select-like field. */
export interface SheetOption {
  value: string | number;
  label: string;
  /** Anything EuiBadge's @color accepts: a named colour or a CSS colour. */
  color?: string;
}

/** A boolean, or a function of the record (the values accepted so far for a row being inserted). */
export type RecordFlag<T> = boolean | ((record: T) => boolean);

export interface EuiSheetField<T = any> {
  id: string;
  label?: string;
  /** Name in the registry. Default 'text'. */
  type?: string;
  readOnly?: RecordFlag<T>;
  required?: RecordFlag<T>;
  /** Extra sync rule for this field. Runs on non-empty values. */
  validate?: (value: unknown, record: T) => string | string[] | undefined;
  /** Shown as a tooltip in the column header and under the label in the expanded record. */
  description?: string;
  /** Default width in px; `@fieldWidths[id]` wins. */
  width?: number;
  /** Whether the header menu offers "Sort" (with `@onSortChange`). Default true. */
  sortable?: boolean;
  /** Whether the header menu offers "Hide". Default true; the first field is never hidden. */
  hideable?: boolean;
  /**
   * Whether the header menu offers Edit, Duplicate and Delete (with
   * `@onFieldUpdate`, `@onFieldCreate`, `@onFieldDelete`). Default true;
   * `false` for system fields (V03 6.2).
   */
  manageable?: boolean;
  /**
   * The header menu offers "Group by this field" (and, on the grouped
   * field, "Remove grouping") with `@onGroupByChange`. Default true;
   * `false` drops both (V03 4.4, 8.3).
   */
  groupable?: boolean;
  /** Options of the field's type (below) and of app types. */
  [option: string]: unknown;
}

export interface TextField<T = any> extends EuiSheetField<T> {
  type?: 'text';
  maxLength?: number;
  pattern?: RegExp;
  /** Message when `pattern` fails. Default messages.pattern(). */
  patternMessage?: string;
}

export interface NumberField<T = any> extends EuiSheetField<T> {
  type: 'number';
  min?: number;
  max?: number;
  /** Default '.'. The other of '.' and ',' is read as a thousands separator. */
  decimalSeparator?: '.' | ',';
}

export interface CheckboxField<T = any> extends EuiSheetField<T> {
  type: 'checkbox';
}

export interface SingleSelectField<T = any> extends EuiSheetField<T> {
  type: 'singleSelect';
  options: SheetOption[] | ((record: T) => SheetOption[]);
  /** A pasted text that matches no option becomes a new option. Default false. */
  createOnPaste?: boolean;
}

export interface MultiSelectField<T = any> extends EuiSheetField<T> {
  type: 'multiSelect';
  options: SheetOption[] | ((record: T) => SheetOption[]);
  /** A pasted part that matches no option becomes a new option. Default false. */
  createOnPaste?: boolean;
}

/** One linked record: the value of a `linkedRecord` field is an array of them. */
export interface SheetLinkedRecord {
  id: RecordId;
  label: string;
}

export interface LinkedRecordField<T = any> extends EuiSheetField<T> {
  type: 'linkedRecord';
  /** The records matching `query`, for the picker. `signal` is aborted when a newer search starts or the picker closes. */
  search: (
    query: string,
    context: { record: T | undefined; signal: AbortSignal }
  ) => Promise<SheetLinkedRecord[]>;
  /** More than one record per cell. Default true. */
  multiple?: boolean;
}

/** A user (a collaborator): the value of a `user` field, or an array with `multiple`. */
export interface SheetUser {
  id: RecordId;
  label: string;
  avatarUrl?: string;
  /** Matched by paste with `options`. Not shown. */
  email?: string;
}

export interface UserField<T = any> extends EuiSheetField<T> {
  type: 'user';
  /** A known list: pasted text matches a label or an email. */
  options?: SheetUser[];
  /** Without `options`: the users matching `query` (as `LinkedRecordField.search`). */
  search?: (
    query: string,
    context: { record: T | undefined; signal: AbortSignal }
  ) => Promise<SheetUser[]>;
  /** More than one user per cell (the value is then an array). Default false. */
  multiple?: boolean;
}

/** One file of an `attachment` field. */
export interface SheetAttachment {
  id: string;
  name: string;
  url: string;
  /** MIME type. `image/*` shows `url` as the thumbnail when there is no `thumbnailUrl`. */
  type?: string;
  size?: number;
  thumbnailUrl?: string;
}

export interface AttachmentField<T = any> extends EuiSheetField<T> {
  type: 'attachment';
  /** Stores the files and returns them as attachments. Without it the field has no file picker and no drop. */
  upload?: (
    files: File[],
    context: {
      record: T | undefined;
      field: AttachmentField<T>;
      signal: AbortSignal;
    }
  ) => Promise<SheetAttachment[]>;
  /** The file input's `accept`. */
  accept?: string;
  /** Files per cell; more are not uploaded. */
  maxFiles?: number;
}

export interface CurrencyField<T = any> extends EuiSheetField<T> {
  type: 'currency';
  /** ISO 4217 code, e.g. 'MXN'. */
  currency: string;
  /** BCP 47 locale of the display, e.g. 'es-MX'. Default: the browser's. */
  locale?: string;
  /** Decimals shown. Default 2. */
  precision?: number;
  min?: number;
  max?: number;
  /** Default: the locale's. The other of '.' and ',' is read as a thousands separator. */
  decimalSeparator?: '.' | ',';
}

export interface PercentField<T = any> extends EuiSheetField<T> {
  type: 'percent';
  /** Decimals shown. Default 0. */
  precision?: number;
  /** In stored units: fractions (0.5 is 50%). */
  min?: number;
  max?: number;
  /** Default '.'. */
  decimalSeparator?: '.' | ',';
}

export interface DurationField<T = any> extends EuiSheetField<T> {
  type: 'duration';
  /** Default 'h:mm'. */
  durationFormat?: 'h:mm' | 'h:mm:ss';
}

export interface RatingField<T = any> extends EuiSheetField<T> {
  type: 'rating';
  /** Stars. Default 5. */
  max?: number;
}

export interface LinkField<T = any> extends EuiSheetField<T> {
  type: 'url' | 'email' | 'phone';
  maxLength?: number;
}

export interface LongTextField<T = any> extends EuiSheetField<T> {
  type: 'longText';
  maxLength?: number;
}

export interface DateField<T = any> extends EuiSheetField<T> {
  type: 'date';
  /** Order of day and month in typed, pasted and displayed dates. Default 'dmy'. */
  dateOrder?: 'dmy' | 'mdy';
  /** ISO dates, inclusive. */
  min?: string;
  max?: string;
}

/**
 * A date with a time (V03 10.3, D9): the value is an instant, stored as a
 * UTC ISO string (`2026-11-19T15:30:00.000Z`) or `null`; it is shown and
 * typed in `timeZone`.
 */
export interface DateTimeField<T = any> extends EuiSheetField<T> {
  type: 'dateTime';
  /** The zone values are shown and typed in: 'local' (the browser's, default), 'utc', or an IANA name ('America/Mexico_City'). An unknown name is a validation error on every value. */
  timeZone?: 'local' | 'utc' | (string & {});
  /** Order of day and month, as `DateField`. Default 'dmy'. */
  dateOrder?: 'dmy' | 'mdy';
  /** 12-hour clock with am/pm. Default false. */
  hour12?: boolean;
  /** Show and keep seconds. Default false (minutes). */
  seconds?: boolean;
  /** Instants (the stored format), inclusive. */
  min?: string;
  max?: string;
}

/**
 * What the field editor produces (V03 6.4): plain values only. `id` is
 * absent: on create the owner assigns it, on update it is the field's.
 * The owner builds the field (`{ ...previous, ...draft }` on update,
 * `{ id, ...draft }` on create).
 */
export interface SheetFieldDraft {
  label: string;
  type: string;
  description?: string;
  required?: boolean;
  /** Type options: `options` of a select, `currency`, `precision`, `max`, `dateOrder`, `durationFormat`, … */
  [option: string]: unknown;
}

/** One level of the owner's group-by (V03 8.1). Outermost first. */
export interface SheetGroupBy {
  field: string;
  direction: 'asc' | 'desc';
}

/**
 * One group header (V03 8.1). `@groups` lists them depth-first, in display
 * order; the sheet places them by position (8.2): each header takes its
 * next `loaded` records of `@records`. Nothing is read from the records.
 */
export interface SheetGroup {
  /** The owner's id for the group: unique in `@groups`, the same after a re-query. */
  key: string;
  /** 0 for the outermost level; the group belongs to `@groupBy[depth]`. */
  depth: number;
  /** The value of `@groupBy[depth].field` its records share. A record added to the group, or dragged into it, gets it. */
  value: unknown;
  /** Default: `type.format(value)` of that field, or `messages.groupEmpty()` for an empty value. */
  label?: string;
  /** Records in the group in the owner's whole data (all pages, collapsed or not). */
  count: number;
  /** How many of `@records`, taken in order, are directly under this header. Default 0. */
  loaded?: number;
  /** Drawn closed. Its records are not in `@records` and its child groups are not in `@groups`. */
  collapsed?: boolean;
  /** Text per field id, drawn in the header row under that column. */
  summary?: Record<string, string>;
  /** The row number of its first loaded record. Default: one more than the record before it. */
  rowNumberStart?: number;
  /** The group began on an earlier page: the label says so. */
  continued?: boolean;
}

export interface TypeContext<T = any> {
  /** The record the cell belongs to. For a row being inserted: the values accepted so far. */
  record: T | undefined;
  messages: SheetMessages;
}

export interface ParseContext<T = any> extends TypeContext<T> {
  source: 'edit' | 'paste' | 'clear';
}

export type ParseResult<V> =
  | { value: V; newOption?: SheetOption; newOptions?: SheetOption[] }
  | { error: string }
  /** The text needs the owner's bulk resolve (`@onResolve`); without one it is a rejection. */
  | { unresolved: string };

export interface FieldType<
  V = unknown,
  F extends EuiSheetField = EuiSheetField
> {
  /** Text → value. `parse('')` with source 'clear' must return a value (the empty value). */
  parse(text: string, field: F, context: ParseContext): ParseResult<V>;
  /** Value → the text shown in the cell. */
  format(value: V | null | undefined, field: F, context: TypeContext): string;
  /** Value → the text put on the clipboard. Default: `format`. `parse(copyText(v))` must give `v`. */
  copyText?(
    value: V | null | undefined,
    field: F,
    context: TypeContext
  ): string;
  /** Rules on a stored, non-empty value. */
  validate?(value: V, field: F, context: TypeContext): string[];
  /** For owners that sort their records, and `summarize`'s min and max. The sheet never calls it. */
  compare?(a: V | null | undefined, b: V | null | undefined, field: F): number;
  /** The value as a number, for `summarize`'s sum, average, min and max; `null` when it has none. */
  toNumber?(value: V | null | undefined, field: F): number | null;
  /** Default: `value == null || value === ''`. */
  isEmpty?(value: unknown): boolean;
  /** A key pressed on the cell in nav mode that changes the value without an editor. */
  navKey?(
    key: string,
    value: V | null | undefined,
    field: F
  ): { value: V } | undefined;
  /**
   * Value equality, for "unchanged" checks (an edit, clear, paste or fill
   * that writes an equal value gives no patch; undo's conflict check).
   * Default `Object.is`. Types with array or object values need it.
   */
  equals?(a: V | null | undefined, b: V | null | undefined): boolean;
  /** For a type whose `parse` returns `{ unresolved }` (bulk resolve, `@onResolve`). */
  resolve?: {
    /** The texts of one cell to resolve. Default: `[unresolved]`. */
    parts(text: string, field: F, context: ParseContext): string[];
    /** The cell's value from its resolved parts (`value` null: no match). */
    combine(
      parts: Array<{ text: string; value: unknown | null }>,
      field: F,
      context: ParseContext
    ): ParseResult<V>;
  };
  /** The link a value opens (url, email, phone). The sheet opens only http:, https:, mailto: and tel:. */
  link?(value: V | null | undefined, field: F): string | undefined;
  /**
   * The fill handle's series (`fillRange`): continues `samples` (the
   * source cells, in sheet order) by `count` values, the first one next
   * to the samples (`direction` 1: after the last sample, down or right;
   * -1: before the first, up or left). `undefined` repeats the samples.
   * The built-in number, currency, percent, duration and rating types
   * continue a constant step; date also continues one date by a day.
   */
  series?(
    samples: Array<V | null | undefined>,
    count: number,
    field: F,
    direction: 1 | -1
  ): V[] | undefined;
}

export type FieldTypeRegistry = Readonly<Record<string, FieldType<any, any>>>;

export interface CellPatch {
  recordId: RecordId;
  fieldId: string;
  from: unknown;
  to: unknown;
}

export interface RecordInsert {
  tempId: string;
  /**
   * Position in the records the sheet was given (`@records`, which may be
   * one page of the owner's data): the record's index in the result, after
   * the set's deletes are applied and with inserts applied in ascending
   * `index` order. An index past the end appends.
   */
  index: number;
  values: Record<string, unknown>;
  /**
   * The neighbour in `@records` when the insert was made. Owners whose data
   * is larger than `@records` (paged, sorted elsewhere) position by this;
   * `applyChangeSet` uses it before `index`.
   */
  anchor?: { recordId: RecordId; position: 'before' | 'after' };
  /** Set when an undo re-creates a deleted record: its id and the object it was. */
  restore?: { recordId: RecordId; record: unknown };
  /** With `@groups`: the key of the group whose add row, menu item or paste made it. `values` already carry that group's values (V03 4.3). */
  groupKey?: string;
}

/** A record that changes place (V03 4.3): a row drag, its undo or redo. */
export interface RecordMove {
  recordId: RecordId;
  /** Where it goes: next to this record. Absent: into `groupKey` with no loaded record to anchor to. */
  anchor?: { recordId: RecordId; position: 'before' | 'after' };
  /** With `@groups`: the key of the group it lands in. */
  groupKey?: string;
  /** Where it was, for undo: the record before it (absent: it was first) and its group. */
  from: { after?: RecordId; groupKey?: string };
}

/** What a delete removed, so it can be undone. */
export interface RecordRemoval {
  recordId: RecordId;
  /** Index in `@records` when it was removed. */
  index: number;
  /** The neighbour before it in `@records` then, if any. */
  after?: RecordId;
  record: unknown;
}

/** A text that could not become a value. Exactly one of recordId / tempId is set. */
export interface CellRejection {
  recordId?: RecordId;
  tempId?: string;
  fieldId: string;
  text: string;
  message: string;
}

export interface NewOption {
  fieldId: string;
  option: SheetOption;
}

export interface ChangeSet {
  /**
   * What made it: an edit, a paste, a clear, a fill (Ctrl/Cmd+D), an insert
   * or a delete of records, a cut, a bulk resolve of pasted text, or an
   * undo / redo of one of those.
   */
  source:
    | 'edit'
    | 'paste'
    | 'clear'
    | 'fill'
    | 'undo'
    | 'redo'
    | 'insert'
    | 'delete'
    | 'cut'
    | 'resolve'
    | 'move';
  patches: CellPatch[];
  inserts: RecordInsert[];
  /**
   * Ids of records to remove: a user delete (with `removed`), its redo, or
   * an undo of inserted rows (their `tempId`s). Optional, so a change set
   * written by hand needs none; an id that matches no record is ignored.
   */
  deletes?: RecordId[];
  /** Present whenever `deletes` comes from a user delete or its redo: same order as `deletes`. */
  removed?: RecordRemoval[];
  /** Records that change place (V03 4.3): a row drag, its undo or redo. Optional; with patches when the drag crossed groups. */
  moves?: RecordMove[];
  rejected: CellRejection[];
  newOptions: NewOption[];
}

export interface Pos {
  row: number;
  col: number;
}

/** Inclusive on all sides. */
export interface Range {
  top: number;
  left: number;
  bottom: number;
  right: number;
}

export interface SheetContext<T> {
  records: readonly T[];
  /** Visible fields, display order. */
  fields: readonly EuiSheetField<T>[];
  getRecordId: (record: T) => RecordId;
  types: FieldTypeRegistry;
  messages: SheetMessages;
  /** Sheet-level @readOnly. */
  readOnly?: boolean;
}

/** Owner-supplied errors: recordId (as a string) → fieldId → message(s). */
export type CellErrors = Readonly<
  Record<string, Readonly<Record<string, string | string[]>>>
>;

/** What `@validate` gets (PACKAGE-DESIGN.md 9.4, layers 4–6). */
export interface ValidateContext<T> {
  records: readonly T[];
  /** Cells written since the last run; empty on the first run. */
  changed: Array<{ recordId: RecordId; fieldId: string }>;
  /** Aborted when a newer run starts or the sheet is destroyed. */
  signal: AbortSignal;
}

/** A cell waiting for the owner's bulk resolve (`@onResolve`): exactly one of recordId / tempId is set. */
export interface PendingCell {
  recordId?: RecordId;
  tempId?: string;
  fieldId: string;
  /** The cell's text as typed or pasted (shown while pending, and in a rejection). */
  text: string;
  /** The texts to resolve: `type.resolve.parts`, or the `unresolved` text. */
  parts: string[];
}

/** What `@onResolve` gets: one request per field. */
export interface ResolveRequest<T = any> {
  fieldId: string;
  /** Distinct texts to resolve for this field. */
  texts: string[];
  cells: Array<{
    text: string;
    recordId?: RecordId;
    tempId?: string;
    /** The record; for a row being inserted, the values accepted so far in it. */
    record: T | undefined;
  }>;
}

/** Per field id: text → the value to store, or `null` when nothing matches. */
export type ResolveResult = Record<string, Record<string, unknown | null>>;
