/**
 * Comma-separated lists in one cell (multi-select labels, linked records,
 * users): a part in double quotes keeps its commas, `""` inside it is a
 * quote.
 */

/** The trimmed, non-empty parts of `text`. */
export function splitList(text: string): string[] {
  const parts: string[] = [];
  let i = 0;
  const n = text.length;
  while (i < n) {
    while (i < n && /\s/.test(text[i]!)) i++;
    let part = '';
    if (text[i] === '"') {
      i++;
      while (i < n) {
        if (text[i] === '"') {
          if (text[i + 1] === '"') {
            part += '"';
            i += 2;
            continue;
          }
          i++;
          break;
        }
        part += text[i];
        i++;
      }
      // anything after the closing quote, up to the comma, is kept
      while (i < n && text[i] !== ',') part += text[i++];
    } else {
      while (i < n && text[i] !== ',') part += text[i++];
    }
    i++; // the comma
    const trimmed = part.trim();
    if (trimmed) parts.push(trimmed);
  }
  return parts;
}

/** Labels joined by `, `; a label with a comma or a leading quote is quoted. */
export function joinList(labels: readonly string[]): string {
  return labels
    .map((label) =>
      /,|^\s*"/.test(label) ? `"${label.replace(/"/g, '""')}"` : label
    )
    .join(', ');
}
