/**
 * The delimited-text reader behind `parseTsv` and `parseCsv` (v0.4 07):
 * the quoting rules of V02-DESIGN.md 4.2 with the delimiter as a
 * parameter. Not exported from the core's index.
 *
 * A cell that starts with `"` is quoted up to the next `"` that is followed
 * by the delimiter, a line break or the end; inside, `""` is one `"`, and
 * delimiters and line breaks are part of the cell (`\r\n` becomes `\n`). A
 * cell that starts with `"` and has no closing quote is read as plain text.
 * A `"` elsewhere is plain. Rows end at `\n` or `\r\n`; one trailing empty
 * line is dropped.
 */
export function parseDelimited(text: string, delimiter: string): string[][] {
  const length = text.length;
  // the last `"` that could close a quoted cell: a cell that starts after
  // it cannot be closed, so it is plain without scanning to the end
  let lastCloser = -1;
  for (let i = length - 1; i >= 0; i--) {
    if (text[i] === '"' && isCellEnd(text, i + 1, delimiter)) {
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
      const quoted = readQuoted(text, i, delimiter);
      if (quoted) {
        cell = quoted.cell;
        i = quoted.end;
      }
    }
    if (cell === null) {
      let end = i;
      while (end < length && text[end] !== delimiter && text[end] !== '\n')
        end++;
      cell = text.slice(i, end);
      // `\r\n` ends the row: the `\r` is not part of the cell
      if (text[end] === '\n' && cell.endsWith('\r')) cell = cell.slice(0, -1);
      i = end;
    }
    row.push(cell);
    if (i >= length) break;
    if (text[i] === delimiter) {
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

/** Whether a cell can end at `i`: the delimiter, `\n`, `\r\n`, or the end of the text. */
function isCellEnd(text: string, i: number, delimiter: string): boolean {
  if (i >= text.length) return true;
  const char = text[i];
  return (
    char === delimiter ||
    char === '\n' ||
    (char === '\r' && text[i + 1] === '\n')
  );
}

/** The quoted cell that starts at `start` (a `"`), or null when it never closes. */
function readQuoted(
  text: string,
  start: number,
  delimiter: string
): { cell: string; end: number } | null {
  let cell = '';
  let i = start + 1;
  while (i < text.length) {
    const char = text[i]!;
    if (char === '"') {
      // `""` first: it is one `"`, even before a delimiter
      if (text[i + 1] === '"') {
        cell += '"';
        i += 2;
        continue;
      }
      if (isCellEnd(text, i + 1, delimiter)) return { cell, end: i + 1 };
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
