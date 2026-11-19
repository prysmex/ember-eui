/** Splits on `\r?\n` (one trailing empty line dropped), then on `\t`. No quoted cells. */
export function parseTsv(text: string): string[][] {
  const lines = text.split(/\r?\n/);
  if (lines.length > 1 && lines[lines.length - 1] === '') lines.pop();
  return lines.map((line) => line.split('\t'));
}

export function toTsv(matrix: readonly (readonly string[])[]): string {
  return matrix.map((row) => row.join('\t')).join('\n');
}
