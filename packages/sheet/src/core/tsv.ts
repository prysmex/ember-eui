import type { EuiSheetField } from './types.ts';

/**
 * TSV as Excel and Google Sheets write it (V02-DESIGN.md 4.2).
 *
 * A cell that starts with `"` is quoted up to the next `"` that is followed
 * by a tab, a line break or the end; inside, `""` is one `"`, and tabs and
 * line breaks are part of the cell (`\r\n` becomes `\n`). A cell that starts
 * with `"` and has no closing quote is read as plain text. A `"` elsewhere
 * is plain. Rows end at `\n` or `\r\n`; one trailing empty line is dropped.
 */
export function parseTsv(text: string): string[][] {
  const length = text.length;
  // the last `"` that could close a quoted cell: a cell that starts after
  // it cannot be closed, so it is plain without scanning to the end
  let lastCloser = -1;
  for (let i = length - 1; i >= 0; i--) {
    if (text[i] === '"' && isCellEnd(text, i + 1)) {
      lastCloser = i;
      break;
    }
  }

  const rows: string[][] = [];
  let row: string[] = [];
  let i = 0;
  for (;;) {
    let cell: string | null = null;
    if (text[i] === '"' && lastCloser > i) {
      const quoted = readQuoted(text, i);
      if (quoted) {
        cell = quoted.cell;
        i = quoted.end;
      }
    }
    if (cell === null) {
      let end = i;
      while (end < length && text[end] !== '\t' && text[end] !== '\n') end++;
      cell = text.slice(i, end);
      // `\r\n` ends the row: the `\r` is not part of the cell
      if (text[end] === '\n' && cell.endsWith('\r')) cell = cell.slice(0, -1);
      i = end;
    }
    row.push(cell);
    if (i >= length) break;
    if (text[i] === '\t') {
      i++;
      continue;
    }
    // a line break: `\n`, or `\r\n` after a quoted cell
    i += text[i] === '\r' ? 2 : 1;
    rows.push(row);
    row = [];
  }
  rows.push(row);
  // the empty line after a trailing line break
  if (rows.length > 1 && text.endsWith('\n')) rows.pop();
  return rows;
}

/** Whether a cell can end at `i`: a tab, `\n`, `\r\n`, or the end of the text. */
function isCellEnd(text: string, i: number): boolean {
  if (i >= text.length) return true;
  const char = text[i];
  return (
    char === '\t' || char === '\n' || (char === '\r' && text[i + 1] === '\n')
  );
}

/** The quoted cell that starts at `start` (a `"`), or null when it never closes. */
function readQuoted(
  text: string,
  start: number
): { cell: string; end: number } | null {
  let cell = '';
  let i = start + 1;
  while (i < text.length) {
    const char = text[i]!;
    if (char === '"') {
      // `""` first: it is one `"`, even before a tab
      if (text[i + 1] === '"') {
        cell += '"';
        i += 2;
        continue;
      }
      if (isCellEnd(text, i + 1)) return { cell, end: i + 1 };
      cell += '"';
      i++;
      continue;
    }
    if (char === '\r' && text[i + 1] === '\n') {
      cell += '\n';
      i += 2;
      continue;
    }
    cell += char;
    i++;
  }
  return null;
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
