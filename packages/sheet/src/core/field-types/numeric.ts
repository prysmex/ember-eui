/** Number reading shared by number, currency and percent. */
function escape(char: string): string {
  return char === '.' ? '\\.' : char;
}

/**
 * The number in `text` (spaces removed), `null` for `''`, `undefined` when
 * it is not a number. `,` is a thousands separator when `decimal` is `.`,
 * and the other way round.
 */
export function readNumber(
  text: string,
  decimal: '.' | ','
): number | null | undefined {
  const trimmed = text.trim();
  if (trimmed === '') return null;
  const g = decimal === '.' ? ',' : '.';
  let result = trimmed.replace(/\s+/g, '');
  if (result.includes(g)) {
    const grouped = new RegExp(
      `^[-+]?\\d{1,3}(${escape(g)}\\d{3})+(${escape(decimal)}\\d+)?$`
    );
    if (!grouped.test(result)) return undefined;
    result = result.split(g).join('');
  }
  result = result.replace(decimal, '.');
  if (!/^[-+]?(\d+\.?\d*|\.\d+)$/.test(result)) return undefined;
  return Number(result);
}

/** A float without its binary noise (`0.07 * 100` is 7.000000000000001). */
export function clean(n: number): number {
  return Number(n.toPrecision(15));
}

export const compareNumbers = (
  a: number | null | undefined,
  b: number | null | undefined
): number => {
  if (a == null) return b == null ? 0 : -1;
  if (b == null) return 1;
  return a - b;
};

export const finiteOrNull = (value: unknown): number | null =>
  typeof value === 'number' && Number.isFinite(value) ? value : null;
