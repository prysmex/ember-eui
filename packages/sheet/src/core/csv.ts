/**
 * CSV in and out (v0.4 06, 07): `toCsv` writes records as CSV text for a
 * download; `parseCsv` and `importMatrix` read a file into the rows and
 * field ids that `api.appendRows` takes, with `matchHeader` matching its
 * header line to the fields (also for the import screen, v0.4 10). The
 * sheet never calls these: the app does, from its own toolbar.
 */
import { rangeMatrix } from './change-set.ts';
import { parseDelimited, quoteDelimitedCell } from './delimited.ts';
import { headerLine } from './tsv.ts';

import type { EuiSheetField, SheetContext } from './types.ts';

export interface ToCsvOptions {
  /** Default `','`; `';'` for Excel in locales whose decimal mark is a comma. */
  delimiter?: string;
  /** A first line with the fields' labels (or ids). Default true. */
  headers?: boolean;
  /**
   * Default true: a cell whose text a spreadsheet would run as a formula
   * gets a leading `'` (a CSV injection guard). See `escapeFormula`.
   */
  escapeFormulas?: boolean;
}

/**
 * The records as CSV (RFC 4180): one line per record, one cell per field
 * in the given order, each the type's `copyText` (else `format`), the
 * text a copy gives. A cell with the delimiter, a `"`, `\r` or `\n` is
 * quoted, with `"` doubled; lines end with `\r\n` (no line break after
 * the last). `ctx.types` is the merged registry, as the sheet has it.
 */
export function toCsv<T>(
  ctx: Pick<SheetContext<T>, 'types' | 'messages'>,
  records: readonly T[],
  fields: readonly EuiSheetField<T>[],
  options: ToCsvOptions = {}
): string {
  const delimiter = options.delimiter ?? ',';
  const escape = options.escapeFormulas ?? true;
  const matrix = rangeMatrix(
    {
      types: ctx.types,
      messages: ctx.messages,
      records,
      fields,
      // not read by rangeMatrix
      getRecordId: () => ''
    },
    { top: 0, left: 0, bottom: records.length - 1, right: fields.length - 1 }
  );
  const lines =
    options.headers === false ? matrix : [headerLine(fields), ...matrix];
  return lines
    .map((line) =>
      line
        .map((text) =>
          quoteDelimitedCell(escape ? escapeFormula(text) : text, delimiter)
        )
        .join(delimiter)
    )
    .join('\r\n');
}

/** A number as written: digits, `.`, `,` and spaces, an optional sign and `%`. */
const NUMBER_AS_WRITTEN = /^[+-]?[\d.,\s]+%?$/;

/**
 * The text with a leading `'` when a spreadsheet would run it as a
 * formula: it starts with `=`, `@`, a tab or `\r`, or with `+` or `-` and
 * is not a number as written (`-5`, `+52 81 1234 5678`, `-12.5%` stay).
 * It looks only at the text, so it is the same for every type.
 */
function escapeFormula(text: string): string {
  const first = text[0];
  if (first === '=' || first === '@' || first === '\t' || first === '\r') {
    return `'${text}`;
  }
  if ((first === '+' || first === '-') && !NUMBER_AS_WRITTEN.test(text)) {
    return `'${text}`;
  }
  return text;
}

/* -------------------------------------------------------------------- */
/* Import (v0.4 07): parseCsv, importMatrix, matchHeader                 */
/* -------------------------------------------------------------------- */

export interface ParseCsvOptions {
  /** One character. Default: whichever of `,`, `;` and a tab appears most often in the first line, outside quotes (`,` on a tie or none). */
  delimiter?: string;
}

/**
 * CSV text as a matrix of texts (RFC 4180, read leniently): a leading
 * byte-order mark is dropped; a cell that starts with `"` is quoted up to
 * the `"` followed by the delimiter, a line break or the end (`""` inside
 * is one `"`, delimiters and line breaks inside are part of the cell);
 * lines end at `\n` or `\r\n`; one trailing empty line is dropped. The
 * same rules as `parseTsv`, which is this with a tab.
 */
export function parseCsv(
  text: string,
  options: ParseCsvOptions = {}
): string[][] {
  const body = text.charCodeAt(0) === 0xfeff ? text.slice(1) : text;
  return parseDelimited(body, options.delimiter ?? detectDelimiter(body));
}

const DELIMITERS = [',', ';', '\t'];

/**
 * The delimiter `parseCsv` uses when none is given: the most frequent of
 * `,` `;` and a tab in the first line, outside quotes; `,` on a tie or
 * none. A leading byte-order mark is ignored. The import screen shows it
 * (v0.4 10).
 */
export function detectDelimiter(text: string): string {
  const counts = new Map(DELIMITERS.map((d) => [d, 0]));
  let quoted = false;
  for (let i = 0; i < text.length; i++) {
    const char = text[i]!;
    if (char === '"') {
      quoted = !quoted;
      continue;
    }
    if (quoted) continue;
    if (char === '\n' || char === '\r') break;
    const count = counts.get(char);
    if (count !== undefined) counts.set(char, count + 1);
  }
  let best = ',';
  for (const d of DELIMITERS) {
    if (counts.get(d)! > counts.get(best)!) best = d;
  }
  return best;
}

/**
 * A header's text as `matchHeader` compares it: accents dropped (NFD),
 * lower case, `_` and `-` as spaces, runs of spaces as one, trimmed.
 * `Nombre_del  Producto ` and `nombre del producto` are the same.
 */
export function normalizeHeader(text: string): string {
  return text
    .normalize('NFD')
    .replace(/[̀-ͯ]/g, '')
    .toLowerCase()
    .replace(/[_-]/g, ' ')
    .replace(/\s+/g, ' ')
    .trim();
}

/** How a header matched its field. */
export type HeaderMatchKind = 'alias' | 'label' | 'id';

export interface HeaderMatch<T = any> {
  field: EuiSheetField<T>;
  by: HeaderMatchKind;
}

/**
 * The field a file's header names (v0.4 07, 10): first a field with the
 * header among its `importAliases`, then one with it as its label, then
 * as its id, each compared with `normalizeHeader`; the first field in
 * `fields` wins within each. `null` for an empty header or no match. It
 * does not know which fields other columns took: `importMatrix` (and the
 * import screen) give a field to at most one column.
 */
export function matchHeader<T>(
  header: string,
  fields: readonly EuiSheetField<T>[]
): HeaderMatch<T> | null {
  const key = normalizeHeader(header);
  if (!key) return null;
  const same = (text: unknown) =>
    typeof text === 'string' && normalizeHeader(text) === key;
  for (const field of fields) {
    if (field.importAliases?.some(same)) return { field, by: 'alias' };
  }
  for (const field of fields) {
    if (same(field.label)) return { field, by: 'label' };
  }
  for (const field of fields) {
    if (same(field.id)) return { field, by: 'id' };
  }
  return null;
}

export interface ImportMatrixOptions {
  /** The first line is the header line, matched to the fields. Default true. Without it, the columns go to `fields` by position. */
  headers?: boolean;
  /** Column index → field id, or `null` to drop it: overrides the match (an app's own "map columns" step). */
  mapping?: Readonly<Record<number, string | null>>;
}

export interface ImportMatrixResult {
  /** The lines (header line and blank lines removed), one text per entry of `fieldIds`; a short line gives a short row. */
  rows: string[][];
  /** The field each kept column goes to, in the file's column order. */
  fieldIds: string[];
  /** The header texts of the columns that go to no field, in the file's order. */
  unmatched: string[];
}

/**
 * Maps a parsed file to fields for `api.appendRows` (v0.4 07). With
 * `headers`, each header goes to `matchHeader`'s field, left to right; a
 * field takes at most one column (a later header that names a taken
 * field is unmatched). `mapping` wins for the columns it names, and the
 * fields it names are not matched again. `fields` may include hidden
 * fields. A column with no field is dropped; with headers its text is in
 * `unmatched`. Lines whose every cell is blank are dropped.
 */
export function importMatrix<T>(
  matrix: readonly (readonly string[])[],
  fields: readonly EuiSheetField<T>[],
  options: ImportMatrixOptions = {}
): ImportMatrixResult {
  const headers = options.headers ?? true;
  const mapping = options.mapping ?? {};
  const header = headers ? (matrix[0] ?? []) : [];
  const lines = headers ? matrix.slice(1) : matrix;
  let width = header.length;
  for (const line of lines) width = Math.max(width, line.length);
  const known = new Set(fields.map((field) => field.id));
  const mapped = (j: number) =>
    Object.prototype.hasOwnProperty.call(mapping, j);
  // the fields `mapping` names are taken before any header is matched,
  // each by the first column that names it
  const mappedTo = new Map<string, number>();
  for (let j = 0; j < width; j++) {
    const id = mapped(j) ? mapping[j] : null;
    if (id != null && known.has(id) && !mappedTo.has(id)) mappedTo.set(id, j);
  }
  const taken = new Set(mappedTo.keys());
  const columns: number[] = [];
  const fieldIds: string[] = [];
  const unmatched: string[] = [];
  for (let j = 0; j < width; j++) {
    let id: string | null = null;
    if (mapped(j)) {
      const given = mapping[j];
      id = given != null && mappedTo.get(given) === j ? given : null;
    } else if (headers) {
      const match = matchHeader(header[j] ?? '', fields);
      if (match && !taken.has(match.field.id)) {
        id = match.field.id;
        taken.add(id);
      }
    } else {
      const field = fields[j];
      if (field && !taken.has(field.id)) {
        id = field.id;
        taken.add(id);
      }
    }
    if (id === null) {
      if (headers && j < header.length) unmatched.push(header[j]!);
      continue;
    }
    columns.push(j);
    fieldIds.push(id);
  }
  const rows: string[][] = [];
  for (const line of lines) {
    if (line.every((text) => text.trim() === '')) continue;
    // `columns` ascend: the cells a short line has are a prefix
    rows.push(columns.filter((j) => j < line.length).map((j) => line[j]!));
  }
  return { rows, fieldIds, unmatched };
}
