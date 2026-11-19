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

export interface DateField<T = any> extends EuiSheetField<T> {
  type: 'date';
  /** Order of day and month in typed, pasted and displayed dates. Default 'dmy'. */
  dateOrder?: 'dmy' | 'mdy';
  /** ISO dates, inclusive. */
  min?: string;
  max?: string;
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
  | { value: V; newOption?: SheetOption }
  | { error: string }
  /** Reserved (PACKAGE-DESIGN.md 9.2): the text needs the owner's bulk resolve. v0.1 treats it as an error. */
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
  /** For owners that sort their records. The sheet does not call it in v0.1. */
  compare?(a: V | null | undefined, b: V | null | undefined, field: F): number;
  /** Default: `value == null || value === ''`. */
  isEmpty?(value: unknown): boolean;
  /** A key pressed on the cell in nav mode that changes the value without an editor. */
  navKey?(
    key: string,
    value: V | null | undefined,
    field: F
  ): { value: V } | undefined;
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
    | 'resolve';
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
