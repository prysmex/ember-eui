/**
 * The import screen's pure helpers (v0.4 10, stage 1): decode a file,
 * guess a column's type, match columns to fields, and read the file's
 * lines with a plan (per column: its target, transform and built-in
 * options), for the preview, the dry run and the import. The screen
 * (`<EuiSheetImport>`) is a view over these; an app can use them without
 * it, for a sheet (`rows` and `fieldIds` for `api.appendRows`) or for any
 * target described by fields (`values`).
 *
 * Every text is read by its field's type's own `parse` (`source:
 * 'paste'`), as `api.appendRows` reads it, so the preview shows what the
 * import writes.
 */
import { normalizeHeader, matchHeader } from './csv.ts';
import { quoteDelimitedCell } from './delimited.ts';
import {
  CREATABLE_FIELD_TYPES,
  resolveType,
  sameFieldValue
} from './fields.ts';

import type { HeaderMatchKind } from './csv.ts';
import type {
  EuiSheetField,
  FieldType,
  ParseResult,
  SheetContext,
  SheetFieldDraft,
  SheetOption
} from './types.ts';

/* -------------------------------------------------------------------- */
/* Types                                                                 */
/* -------------------------------------------------------------------- */

/** What the helpers read with: the merged type registry and the messages, as the sheet has them. */
export type SheetImportTypeContext = Pick<
  SheetContext<unknown>,
  'types' | 'messages'
>;

/** The helpers' context: the types and messages, and the target fields (hidden ones included). */
export interface SheetImportContext<T = any> extends SheetImportTypeContext {
  fields: readonly EuiSheetField<T>[];
}

/**
 * A field to create from a column (`@onCreateFields`): the field editor's
 * draft (label, type and the type's options, no id; V03 6.4).
 */
export type SheetImportFieldDraft = SheetFieldDraft;

/** Where a file column goes: an existing field (by id), a new field, or nowhere. */
export type SheetImportTarget =
  { field: string } | { newField: SheetImportFieldDraft } | 'skip';

/**
 * A named transform the app defines (v0.4 10): text in, text out. The
 * target type still reads the result, so the preview shows what the
 * import writes.
 */
export interface SheetImportTransform {
  id: string;
  label: string;
  description?: string;
  /** Text in, text out. `null` is an empty cell. Throwing marks the cell as an error with the message (its row text is `''`). */
  apply(
    text: string,
    context: {
      /** The line's index in the file's matrix (the header line is 0). */
      line: number;
      header: string;
      /** The line's texts by header (every column, as in the file), for transforms that combine columns. */
      row: Record<string, string>;
    }
  ): string | null;
}

/**
 * One file column of a plan: its target, its transform and its built-in
 * options. An option that does not apply to the target's type is ignored.
 */
export interface SheetImportColumn {
  /** The column's index in the file's lines. */
  index: number;
  /** Its header text (`''` without a header line). */
  header: string;
  target: SheetImportTarget;
  /** How `matchColumns` found the target: the saved mapping, or the header (`matchHeader`). */
  matchedBy?: 'saved' | HeaderMatchKind;
  /** The field the header names when an earlier column took it: this column stays unmapped. */
  taken?: string;
  /** A `SheetImportTransform` id; an id not in the transforms given is no transform. */
  transform?: string | null;
  /** Trim the text first. Default true. */
  trim?: boolean;
  /**
   * An empty text (after the transform and the value map) is no value:
   * `values` has `null` and its type's `parse` is not called. Default
   * true; false gives the type's `parse('')` (`''` for text). `rows`
   * carry `''` either way, and the sheet reads it with the type.
   */
  emptyIsNull?: boolean;
  /** Date and dateTime targets: read with a copy of the field with this order. */
  dateOrder?: 'dmy' | 'mdy';
  /** Number, currency and percent targets: read with a copy of the field with this separator. */
  decimalSeparator?: '.' | ',';
  /**
   * Select and checkbox targets: a text (after trim and the transform) →
   * the value to write (an option's value, an array of them for a
   * multi-select, `true`/`false`; `null` for none). It is written as a
   * text the column's field reads back as that value. Texts not in the
   * map are left as they are.
   */
  valueMap?: Readonly<Record<string, unknown>>;
}

/** The import screen's state, as data: one entry per file column. */
export interface SheetImportPlan {
  /** The file's first line is its header line. Default true. */
  headers?: boolean;
  columns: SheetImportColumn[];
}

/**
 * A plan to save and pass back (`@savedMapping`): its columns, keyed by
 * `signature`, the file's normalised header line (`importSignature`).
 * Targets are field ids, not labels.
 */
export interface SheetImportMapping {
  signature: string;
  columns: SheetImportColumn[];
}

/** A type the column could have, with the share of its sample that type reads, and the options of a new field of it. */
export interface SheetColumnGuess {
  type: string;
  /** 0 to 1: the share of the sample (up to 200 non-empty texts) read. */
  share: number;
  /** The new field's type options: `dateOrder`, `decimalSeparator`, a select's `options`. */
  options: Record<string, unknown>;
}

/** One cell of the preview: the value as the target type formats it, or its state. */
export type SheetImportCell =
  | { state: 'value'; text: string; value: unknown; display: string }
  /** A select value that creates an option on import. */
  | {
      state: 'newOption';
      text: string;
      value: unknown;
      display: string;
      options: SheetOption[];
    }
  /** Linked on import (a linked record or user: the preview has no `@onResolve`). */
  | { state: 'linked'; text: string }
  /** The type's (or the transform's) message. */
  | { state: 'error'; text: string; message: string };

export interface SheetImportPreview {
  /** The plan columns read (every one but `'skip'` and unknown fields), as file column indexes. */
  columns: number[];
  /** The field each of those columns is read with: the target, a per-column copy, or a new field's draft with its placeholder id. */
  fields: EuiSheetField[];
  /** The previewed lines' indexes in the matrix. */
  lines: number[];
  /** `cells[i][k]`: line `lines[i]`, column `columns[k]`. */
  cells: SheetImportCell[][];
}

/** A cell that cannot be read. `line` is its index in the matrix, `column` its file column. */
export interface SheetImportError {
  line: number;
  column: number;
  fieldId: string;
  text: string;
  message: string;
}

/** A cell that needs the owner's resolve (`@onResolve`); without one it is a rejection. */
export interface SheetImportUnresolved {
  line: number;
  column: number;
  fieldId: string;
  text: string;
}

export interface SheetImportRun {
  /** One entry per line kept, one text per entry of `fieldIds`: what `api.appendRows` takes. A cell whose transform threw is `''`. */
  rows: string[][];
  /** The field each column goes to; a new field's column has its placeholder id (`importFieldId`) until it is created. */
  fieldIds: string[];
  /**
   * The field each column was read with (per-column copies and new
   * fields' drafts included): pass them as `appendRows`' `fields` so the
   * sheet reads the texts the same way.
   */
  fields: EuiSheetField[];
  /** Each row's line index in the matrix. */
  lines: number[];
  /** What `parse` gives, for targets that are not a sheet: `undefined` for an error or unresolved cell. */
  values: unknown[][];
  errors: SheetImportError[];
  unresolved: SheetImportUnresolved[];
  /** With `skipLinesWithErrors`: the lines left out of `rows`, `lines` and `values`. */
  skippedLines: number[];
}

/* -------------------------------------------------------------------- */
/* decodeText, importSignature, matchColumns                             */
/* -------------------------------------------------------------------- */

/** Strips a BOM; strict UTF-8, else windows-1252 (Excel's CSV on Windows). */
export function decodeText(bytes: ArrayBuffer | Uint8Array): {
  text: string;
  encoding: 'utf-8' | 'windows-1252';
} {
  let view = bytes instanceof Uint8Array ? bytes : new Uint8Array(bytes);
  const bom = view[0] === 0xef && view[1] === 0xbb && view[2] === 0xbf;
  if (bom) view = view.subarray(3);
  try {
    const text = new TextDecoder('utf-8', {
      fatal: true,
      ignoreBOM: true
    }).decode(view);
    return { text, encoding: 'utf-8' };
  } catch {
    if (bom) {
      // the BOM says UTF-8: its bad bytes become U+FFFD
      return {
        text: new TextDecoder('utf-8', { ignoreBOM: true }).decode(view),
        encoding: 'utf-8'
      };
    }
    return {
      text: new TextDecoder('windows-1252').decode(view),
      encoding: 'windows-1252'
    };
  }
}

/** A mapping's key: the file's header line, each header normalised (`normalizeHeader`). */
export function importSignature(headers: readonly string[]): string {
  return JSON.stringify(headers.map((header) => normalizeHeader(header)));
}

/** The id a new field's column is read with until the field exists (`'new:<column index>'`). */
export function importFieldId(column: number): string {
  return `new:${column}`;
}

/**
 * A proposed plan's columns, one per header: the saved mapping's column
 * when its signature is this header line's (its target, transform and
 * options), then `matchHeader` (alias, label, id). The fields the saved
 * mapping names are taken first; a field takes at most one column, and a
 * header whose field is taken stays `'skip'` with `taken` (no fallback to
 * another field). With `headers: false` the columns go to `fields` by
 * position, as `importMatrix` does. Unmatched columns are `'skip'`.
 */
export function matchColumns<T>(
  headers: readonly string[],
  fields: readonly EuiSheetField<T>[],
  saved?: SheetImportMapping | null,
  options: { headers?: boolean } = {}
): SheetImportColumn[] {
  const known = new Set(fields.map((field) => field.id));
  const usable =
    saved && saved.signature === importSignature(headers) ? saved : null;
  const savedOf = new Map<number, SheetImportColumn>();
  for (const column of usable?.columns ?? []) {
    if (!savedOf.has(column.index)) savedOf.set(column.index, column);
  }
  // the saved mapping's fields first, each by its first column
  const taken = new Set<string>();
  const fromSaved = new Map<number, SheetImportTarget>();
  headers.forEach((_header, j) => {
    const target = savedOf.get(j)?.target;
    if (target === undefined) return;
    if (target === 'skip' || 'newField' in target) {
      fromSaved.set(j, target);
    } else if (known.has(target.field) && !taken.has(target.field)) {
      taken.add(target.field);
      fromSaved.set(j, { field: target.field });
    }
  });
  return headers.map((header, j) => {
    const saved = savedOf.get(j);
    const target = fromSaved.get(j);
    if (saved && target !== undefined) {
      // its transform and options; this header line's index and text
      const column: SheetImportColumn = {
        ...saved,
        index: j,
        header,
        target,
        matchedBy: 'saved'
      };
      delete column.taken;
      return column;
    }
    const column: SheetImportColumn = { index: j, header, target: 'skip' };
    if (options.headers === false) {
      const field = fields[j];
      if (field && !taken.has(field.id)) {
        taken.add(field.id);
        column.target = { field: field.id };
      }
      return column;
    }
    const match = matchHeader(header, fields);
    if (!match) return column;
    if (taken.has(match.field.id)) {
      column.taken = match.field.id;
      return column;
    }
    taken.add(match.field.id);
    column.target = { field: match.field.id };
    column.matchedBy = match.by;
    return column;
  });
}

/* -------------------------------------------------------------------- */
/* guessColumn                                                           */
/* -------------------------------------------------------------------- */

const SAMPLE = 200;
const SHARE = 0.95;

/** A `%` at the end: plain numbers are numbers, not percents. */
const PERCENT = /%\s*$/;
/** A number with a currency sign or a three-letter code before or after it, and nothing else. */
const CURRENCY =
  /^(?:[+-]?\s*(?:\p{Sc}|[A-Z]{3})\s*[+-]?[\d.,\s]*\d[\d.,\s]*|[+-]?[\d.,\s]*\d[\d.,\s]*(?:\p{Sc}|[A-Z]{3}))$/u;

/** A time of day after a date (`2026-11-19T10:30`, `19/11/2026 10:30`). */
const TIME = /\d[T\s]+\d{1,2}:\d{2}/;

/**
 * Digits written as a phone number: only digits, spaces, `-`, `( )` and
 * a `+` first, 7 digits or more, and a `+` first, parentheses, or groups
 * split by spaces or dashes; not thousands split by spaces (`1 234 567`).
 */
function phoneFormatted(text: string): boolean {
  const t = text.trim();
  if (!/^\+?[\d\s()-]+$/.test(t)) return false;
  if ((t.match(/\d/g)?.length ?? 0) < 7) return false;
  if (/^\d{1,3}(?: \d{3})+$/.test(t)) return false;
  return t.startsWith('+') || /[()]/.test(t) || /\d[\s-]+\d/.test(t);
}

/** Whether `field`'s type reads `text`: `parse` gives a value and the type's `validate` passes on it. */
function reads(
  ctx: SheetImportTypeContext,
  type: FieldType<any, any>,
  field: EuiSheetField,
  text: string
): boolean {
  const context = { record: {}, messages: ctx.messages };
  const result = type.parse(text, field, { ...context, source: 'paste' });
  if (!('value' in result)) return false;
  const value: unknown = result.value;
  if (value == null || value === '') return true;
  return !type.validate || type.validate(value, field, context).length === 0;
}

function shareOf(
  ctx: SheetImportTypeContext,
  field: EuiSheetField,
  texts: readonly string[],
  evidence?: (text: string) => boolean
): number {
  const type = resolveType(ctx.types, field);
  let read = 0;
  for (const text of texts) {
    if ((!evidence || evidence(text)) && reads(ctx, type, field, text)) read++;
  }
  return read / texts.length;
}

/** The distinct texts (case-insensitive, trimmed) with their first spelling and count, in order. */
function distinctTexts(
  texts: readonly string[]
): Map<string, [string, number]> {
  const seen = new Map<string, [string, number]>();
  for (const text of texts) {
    const key = text.trim().toLowerCase();
    const entry = seen.get(key);
    if (entry) entry[1]++;
    else seen.set(key, [text.trim(), 1]);
  }
  return seen;
}

/**
 * The types a column could have, most likely first (v0.4 10, "Guessing a
 * type"): the first is the guess. Over a sample of up to 200 non-empty
 * texts, each candidate type's own `parse` (`source: 'paste'`) is run
 * with a draft field of that type; a type is listed when it reads at
 * least 95% of the sample. Candidates, most specific first: `checkbox`,
 * `date`, `dateTime`, `percent`, `currency`, `number` (`.`, then `,`),
 * `email`, `url`, `phone`, `singleSelect`, `longText`, `text`; only those
 * in `candidates` (default `CREATABLE_FIELD_TYPES`) and in `ctx.types`.
 * When a text has a time of day, `dateTime` comes before `date` (whose
 * `parse` drops the time); when 95% are written as phone numbers (a `+`
 * first, parentheses, or digit groups split by spaces or dashes, 7
 * digits or more, not `1 234 567`), `phone` comes before `number`.
 * Dates are D/M/Y unless a text proves M/D/Y (it reads only as M/D/Y)
 * and none proves D/M/Y. `singleSelect` is a candidate with at most 20
 * distinct texts each used twice or more (its options are those texts);
 * `longText` when a text has a line break or is over 200 characters. An
 * empty sample gives `text` alone.
 */
export function guessColumn(
  ctx: SheetImportTypeContext,
  texts: readonly string[],
  candidates: readonly string[] = CREATABLE_FIELD_TYPES
): SheetColumnGuess[] {
  const allowed = new Set(candidates.filter((name) => ctx.types[name]));
  const sample: string[] = [];
  for (const text of texts) {
    if (text.trim() === '') continue;
    sample.push(text);
    if (sample.length === SAMPLE) break;
  }
  if (!sample.length) {
    return allowed.has('text') ? [{ type: 'text', share: 1, options: {} }] : [];
  }
  const guesses: SheetColumnGuess[] = [];
  const draft = (type: string, options: Record<string, unknown> = {}) => ({
    id: 'guess',
    type,
    ...options
  });
  const tryType = (
    type: string,
    variants: Array<Record<string, unknown>>,
    evidence?: (text: string) => boolean
  ) => {
    if (!allowed.has(type)) return;
    for (const options of variants) {
      const share = shareOf(ctx, draft(type, options), sample, evidence);
      if (share >= SHARE) {
        guesses.push({ type, share, options });
        return;
      }
    }
  };
  /** The order the sample proves for a date-like type: M/D/Y when a text reads only so and none only as D/M/Y. */
  const orderOf = (type: string): 'dmy' | 'mdy' => {
    const typeOf = ctx.types[type]!;
    const dmy = draft(type, { dateOrder: 'dmy' });
    const mdy = draft(type, { dateOrder: 'mdy' });
    let mdyOnly = false;
    for (const text of sample) {
      const asDmy = reads(ctx, typeOf, dmy, text);
      const asMdy = reads(ctx, typeOf, mdy, text);
      if (asDmy && !asMdy) return 'dmy';
      if (asMdy && !asDmy) mdyOnly = true;
    }
    return mdyOnly ? 'mdy' : 'dmy';
  };
  const decimals = [{ decimalSeparator: '.' }, { decimalSeparator: ',' }];

  tryType('checkbox', [{}]);
  // a time in a text: `dateTime` first (`date` reads `2026-11-19T10:30`
  // too, and drops the time)
  const dateTypes = sample.some((text) => TIME.test(text))
    ? ['dateTime', 'date']
    : ['date', 'dateTime'];
  for (const type of dateTypes) {
    if (allowed.has(type)) tryType(type, [{ dateOrder: orderOf(type) }]);
  }
  tryType('percent', decimals, (text) => PERCENT.test(text));
  tryType('currency', decimals, (text) => CURRENCY.test(text.trim()));
  // written as phone numbers: `phone` before `number` (which reads
  // `81 1234 5678` by dropping the spaces); plain digits stay numbers
  const phoneFirst =
    allowed.has('phone') &&
    sample.filter(phoneFormatted).length / sample.length >= SHARE;
  if (phoneFirst) tryType('phone', [{}]);
  tryType('number', decimals);
  tryType('email', [{}]);
  // `url`'s own rule wants a site's host (a date or a number is not one)
  tryType('url', [{}]);
  if (!phoneFirst) tryType('phone', [{}]);
  if (allowed.has('singleSelect')) {
    const distinct = distinctTexts(sample);
    if (
      distinct.size <= 20 &&
      [...distinct.values()].every(([, count]) => count >= 2)
    ) {
      const options: SheetOption[] = [...distinct.values()].map(([text]) => ({
        value: text,
        label: text
      }));
      tryType('singleSelect', [{ options }]);
    }
  }
  if (sample.some((text) => /[\r\n]/.test(text) || text.length > 200)) {
    tryType('longText', [{}]);
  }
  tryType('text', [{}]);
  return guesses;
}

/* -------------------------------------------------------------------- */
/* The value map's prefill                                               */
/* -------------------------------------------------------------------- */

const YES = new Set(['sí', 'si', 'yes', 'true', '1', 'x']);
const NO = new Set(['no', 'false', '0', '']);
const VALUE_MAP_SIZE = 50;

/**
 * The value map's table for a column going to `field` (a select or a
 * checkbox; v0.4 10, "Built-in column options"): the column's distinct
 * texts, trimmed, in order (up to 50), and the map prefilled where a text
 * matches an option's label (case and accents ignored) or, for a
 * checkbox, a common yes/no word (`sí`, `si`, `yes`, `true`, `1`, `x`;
 * `no`, `false`, `0`, empty). A multi-select's entry is an array of one
 * value. Other types: no texts.
 */
export function suggestValueMap(
  texts: readonly string[],
  field: EuiSheetField
): { texts: string[]; map: Record<string, unknown> } {
  const type = field.type ?? 'text';
  const map: Record<string, unknown> = {};
  if (
    type !== 'checkbox' &&
    type !== 'singleSelect' &&
    type !== 'multiSelect'
  ) {
    return { texts: [], map };
  }
  const distinct: string[] = [];
  const seen = new Set<string>();
  for (const text of texts) {
    const trimmed = text.trim();
    if (seen.has(trimmed)) continue;
    seen.add(trimmed);
    distinct.push(trimmed);
    if (distinct.length === VALUE_MAP_SIZE) break;
  }
  const options = Array.isArray(field['options'])
    ? (field['options'] as SheetOption[])
    : [];
  for (const text of distinct) {
    if (type === 'checkbox') {
      const word = text.toLowerCase();
      if (YES.has(word)) map[text] = true;
      else if (NO.has(word)) map[text] = false;
      continue;
    }
    const key = normalizeHeader(text);
    const option = key
      ? options.find((o) => normalizeHeader(o.label) === key)
      : undefined;
    if (option)
      map[text] = type === 'multiSelect' ? [option.value] : option.value;
  }
  return { texts: distinct, map };
}

/* -------------------------------------------------------------------- */
/* Reading a file with a plan: previewImport, runImport                  */
/* -------------------------------------------------------------------- */

type CellRead =
  | { kind: 'value'; text: string; value: unknown; created: SheetOption[] }
  | { kind: 'unresolved'; text: string }
  | { kind: 'error'; text: string; message: string };

interface Reader {
  column: SheetImportColumn;
  field: EuiSheetField;
  /** The id the rows carry: the target's (the copy keeps it), or a new field's placeholder. */
  fieldId: string;
  type: FieldType<any, any>;
  transform: SheetImportTransform | undefined;
  /** The value map's entries as texts the field reads back. */
  mapped: Map<string, string> | null;
}

const DATE_TYPES = new Set(['date', 'dateTime']);
const DECIMAL_TYPES = new Set(['number', 'currency', 'percent']);

function errorMessage(error: unknown): string {
  if (error instanceof Error) return error.message;
  return typeof error === 'string' ? error : String(error);
}

/** The text `field` reads back as `value`: its `copyText` (else `format`), else the value as text; `''` for none. */
function textFor(
  ctx: SheetImportTypeContext,
  type: FieldType<any, any>,
  field: EuiSheetField,
  value: unknown
): string {
  if (value == null) return '';
  const context = { record: {}, messages: ctx.messages };
  const back = (text: string) => {
    const result = type.parse(text, field, { ...context, source: 'paste' });
    return 'value' in result && sameFieldValue(type, result.value, value);
  };
  const written = type.copyText
    ? type.copyText(value, field, context)
    : type.format(value, field, context);
  if (back(written)) return written;
  // an option's value (its label may be another option's value)
  if (typeof value === 'string' || typeof value === 'number') {
    const plain = String(value);
    if (back(plain)) return plain;
  }
  return written;
}

/** The plan's columns that are read, each with its field (a per-column copy, or a new field's draft). */
function readersOf(
  ctx: SheetImportContext,
  plan: SheetImportPlan,
  transforms: readonly SheetImportTransform[]
): Reader[] {
  const byId = new Map(ctx.fields.map((field) => [field.id, field]));
  const readers: Reader[] = [];
  for (const column of plan.columns) {
    const target = column.target;
    if (target === 'skip') continue;
    let field: EuiSheetField | undefined;
    if ('field' in target) {
      field = byId.get(target.field);
    } else {
      field = { ...target.newField, id: importFieldId(column.index) };
    }
    if (!field) continue;
    const name = field.type ?? 'text';
    if (column.dateOrder && DATE_TYPES.has(name)) {
      field = { ...field, dateOrder: column.dateOrder };
    }
    if (column.decimalSeparator && DECIMAL_TYPES.has(name)) {
      field = { ...field, decimalSeparator: column.decimalSeparator };
    }
    const type = resolveType(ctx.types, field);
    let mapped: Map<string, string> | null = null;
    if (column.valueMap) {
      mapped = new Map();
      for (const [text, value] of Object.entries(column.valueMap)) {
        mapped.set(text, textFor(ctx, type, field, value));
      }
    }
    readers.push({
      column,
      field,
      fieldId: field.id,
      type,
      transform: column.transform
        ? transforms.find((t) => t.id === column.transform)
        : undefined,
      mapped
    });
  }
  return readers;
}

/** The data lines: their indexes in the matrix, without the header line and lines whose every cell is blank. */
function dataLines(
  matrix: readonly (readonly string[])[],
  plan: SheetImportPlan,
  limit = Infinity
): number[] {
  const lines: number[] = [];
  for (
    let i = plan.headers === false ? 0 : 1;
    i < matrix.length && lines.length < limit;
    i++
  ) {
    if (!matrix[i]!.every((text) => text.trim() === '')) lines.push(i);
  }
  return lines;
}

/** Reads one line's cells, one per reader: transform, value map, then the type's `parse` with the line's values so far as the record. */
function readLine(
  ctx: SheetImportContext,
  plan: SheetImportPlan,
  readers: readonly Reader[],
  cells: readonly string[],
  line: number
): { texts: string[]; reads: CellRead[] } {
  let row: Record<string, string> | undefined;
  const rowOf = () => {
    if (!row) {
      row = {};
      for (const column of plan.columns) {
        if (!(column.header in row)) {
          row[column.header] = cells[column.index] ?? '';
        }
      }
    }
    return row;
  };
  const record: Record<string, unknown> = {};
  const texts: string[] = [];
  const reads: CellRead[] = [];
  for (const reader of readers) {
    const { column } = reader;
    let text = cells[column.index] ?? '';
    if (column.trim !== false) text = text.trim();
    if (reader.transform) {
      try {
        text =
          reader.transform.apply(text, {
            line,
            header: column.header,
            row: rowOf()
          }) ?? '';
      } catch (error) {
        // the row writes nothing for it: the text it failed on is not the
        // column's text (a text field would store it)
        texts.push('');
        reads.push({ kind: 'error', text, message: errorMessage(error) });
        continue;
      }
    }
    text = reader.mapped?.get(text) ?? text;
    texts.push(text);
    if (text.trim() === '' && column.emptyIsNull !== false) {
      reads.push({ kind: 'value', text, value: null, created: [] });
      continue;
    }
    const result: ParseResult<unknown> = reader.type.parse(text, reader.field, {
      record,
      messages: ctx.messages,
      source: 'paste'
    });
    if ('value' in result) {
      record[reader.fieldId] = result.value;
      reads.push({
        kind: 'value',
        text,
        value: result.value,
        created: [
          ...(result.newOption ? [result.newOption] : []),
          ...(result.newOptions ?? [])
        ]
      });
    } else if ('unresolved' in result) {
      reads.push({ kind: 'unresolved', text });
    } else {
      reads.push({ kind: 'error', text, message: result.error });
    }
  }
  return { texts, reads };
}

/**
 * The parsed result of the first `size` data lines (default 20), cell by
 * cell, with the target fields as columns: each cell's value as its type
 * formats it, or its state (an error with the type's or the transform's
 * message, "linked on import" for an unresolved text, "new option" for a
 * select value that creates one). Lines whose every cell is blank are
 * left out, as `runImport` and `importMatrix` do.
 */
export function previewImport(
  ctx: SheetImportContext,
  matrix: readonly (readonly string[])[],
  plan: SheetImportPlan,
  transforms: readonly SheetImportTransform[] = [],
  options: { size?: number } = {}
): SheetImportPreview {
  const readers = readersOf(ctx, plan, transforms);
  const lines = dataLines(matrix, plan, options.size ?? 20);
  const cells = lines.map((i) => {
    const { reads } = readLine(ctx, plan, readers, matrix[i]!, i);
    const record: Record<string, unknown> = {};
    return reads.map((read, k): SheetImportCell => {
      const reader = readers[k]!;
      if (read.kind === 'error') {
        return { state: 'error', text: read.text, message: read.message };
      }
      if (read.kind === 'unresolved')
        return { state: 'linked', text: read.text };
      record[reader.fieldId] = read.value;
      const display = reader.type.format(read.value, reader.field, {
        record,
        messages: ctx.messages
      });
      return read.created.length
        ? {
            state: 'newOption',
            text: read.text,
            value: read.value,
            display,
            options: read.created
          }
        : { state: 'value', text: read.text, value: read.value, display };
    });
  });
  return {
    columns: readers.map((reader) => reader.column.index),
    fields: readers.map((reader) => reader.field),
    lines,
    cells
  };
}

/**
 * Every data line (the dry run, and the import): the texts to append
 * (each column's text after trim, its transform and its value map), the
 * fields to read them with, what `parse` gives, and the cells that would
 * fail. An unresolved text (a linked record, a user) is not an error: it
 * is resolved on import (`@onResolve`). With `skipLinesWithErrors`, the
 * lines with an error are left out of `rows` and listed in
 * `skippedLines`.
 */
export function runImport(
  ctx: SheetImportContext,
  matrix: readonly (readonly string[])[],
  plan: SheetImportPlan,
  transforms: readonly SheetImportTransform[] = [],
  options: { skipLinesWithErrors?: boolean } = {}
): SheetImportRun {
  const readers = readersOf(ctx, plan, transforms);
  const result: SheetImportRun = {
    rows: [],
    fieldIds: readers.map((reader) => reader.fieldId),
    fields: readers.map((reader) => reader.field),
    lines: [],
    values: [],
    errors: [],
    unresolved: [],
    skippedLines: []
  };
  for (const i of dataLines(matrix, plan)) {
    const { texts, reads } = readLine(ctx, plan, readers, matrix[i]!, i);
    let failed = false;
    const unresolved: SheetImportUnresolved[] = [];
    const values = reads.map((read, k) => {
      const reader = readers[k]!;
      if (read.kind === 'value') return read.value;
      const cell = {
        line: i,
        column: reader.column.index,
        fieldId: reader.fieldId,
        text: read.text
      };
      if (read.kind === 'error') {
        failed = true;
        result.errors.push({ ...cell, message: read.message });
      } else {
        unresolved.push(cell);
      }
      return undefined;
    });
    if (failed && options.skipLinesWithErrors) {
      result.skippedLines.push(i);
      continue;
    }
    result.unresolved.push(...unresolved);
    result.rows.push(texts);
    result.lines.push(i);
    result.values.push(values);
  }
  return result;
}

/**
 * The lines with an error as CSV, for the user to fix and import again:
 * the file's header line first (with `headers`, default true), then each
 * failed line once, in file order, as the file has it. `delimiter`
 * defaults to `,`.
 */
export function errorsCsv(
  matrix: readonly (readonly string[])[],
  errors: readonly Pick<SheetImportError, 'line'>[],
  options: { headers?: boolean; delimiter?: string } = {}
): string {
  const delimiter = options.delimiter ?? ',';
  const failed = [...new Set(errors.map((error) => error.line))].sort(
    (a, b) => a - b
  );
  const lines = [
    ...(options.headers === false || !matrix.length ? [] : [matrix[0]!]),
    ...failed.map((i) => matrix[i]).filter((line) => line !== undefined)
  ];
  return lines
    .map((line) =>
      line.map((text) => quoteDelimitedCell(text, delimiter)).join(delimiter)
    )
    .join('\r\n');
}
