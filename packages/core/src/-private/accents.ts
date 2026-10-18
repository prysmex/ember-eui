/** "Médico" -> "Medico": accents (any combining mark) off. */
export function removeAccents(text: string): string {
  return text.normalize('NFD').replace(/\p{M}/gu, '');
}

/**
 * `removeAccents` that remembers where each folded character came from, to
 * map a match in the folded text back to the original: `starts[i]` and
 * `ends[i]` are the original range of folded character `i`. A combining
 * mark (folded away) belongs to the character before it, so a match ending
 * on "e" of "é" takes the accent along.
 */
export function foldAccents(text: string): {
  folded: string;
  starts: number[];
  ends: number[];
} {
  let folded = '';
  const starts: number[] = [];
  const ends: number[] = [];
  let offset = 0;

  for (const char of text) {
    const end = offset + char.length;
    const fold = removeAccents(char);

    if (fold) {
      for (let i = 0; i < fold.length; i++) {
        starts.push(offset);
        ends.push(end);
      }
      folded += fold;
    } else if (ends.length) {
      ends[ends.length - 1] = end;
    }
    offset = end;
  }

  return { folded, starts, ends };
}
