/**
 * CSV in and out (v0.4 06, 07): `toCsv` writes records as CSV text for a
 * download. The sheet never calls these: the app does, from its own
 * toolbar.
 */
import { rangeMatrix } from './change-set.ts';
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
          quoteCsvCell(escape ? escapeFormula(text) : text, delimiter)
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

function quoteCsvCell(text: string, delimiter: string): string {
  if (
    !text.includes(delimiter) &&
    !text.includes('"') &&
    !text.includes('\n') &&
    !text.includes('\r')
  ) {
    return text;
  }
  return `"${text.replace(/"/g, '""')}"`;
}
