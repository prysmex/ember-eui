import { parseDelimited } from './delimited.ts';

import type { EuiSheetField } from './types.ts';

/**
 * TSV as Excel and Google Sheets write it (V02-DESIGN.md 4.2).
 *
 * A cell that starts with `"` is quoted up to the next `"` that is followed
 * by a tab, a line break or the end; inside, `""` is one `"`, and tabs and
 * line breaks are part of the cell (`\r\n` becomes `\n`). A cell that starts
 * with `"` and has no closing quote is read as plain text. A `"` elsewhere
 * is plain. Rows end at `\n` or `\r\n`; one trailing empty line is dropped.
 * `parseCsv` reads with the same rules (v0.4 07).
 */
export function parseTsv(text: string): string[][] {
  return parseDelimited(text, '\t');
}

/**
 * Cells joined with tabs, rows with `\n`. A cell is quoted when it has a
 * tab, `\n` or `\r`, or starts with `"`; a `"` inside a quoted cell is
 * doubled.
 */
export function toTsv(matrix: readonly (readonly string[])[]): string {
  return matrix.map((row) => row.map(quoteCell).join('\t')).join('\n');
}

function quoteCell(cell: string): string {
  if (!/[\t\n\r]/.test(cell) && !cell.startsWith('"')) return cell;
  return `"${cell.replace(/"/g, '""')}"`;
}

/**
 * The fields' names as a row of cells (v0.4 05, "Copy with field
 * names"): each field's `label`, else its id, in the given order. Put it
 * first in a matrix for `toTsv`.
 */
export function headerLine(fields: readonly EuiSheetField[]): string[] {
  return fields.map((field) => field.label ?? field.id);
}
