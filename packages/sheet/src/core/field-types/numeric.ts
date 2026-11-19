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

/**
 * `FieldType.series` for numbers: two or more finite samples with a
 * constant step continue it (`1, 2` → `3, 4`); anything else is
 * `undefined` (the fill repeats the samples). Values are in fill order,
 * the first one next to the samples: after the last sample going down or
 * right (`direction` 1), before the first going up or left (-1).
 */
export function numericSeries(
  samples: readonly unknown[],
  count: number,
  direction: 1 | -1
): number[] | undefined {
  if (samples.length < 2) return undefined;
  if (!samples.every((v) => typeof v === 'number' && Number.isFinite(v))) {
    return undefined;
  }
  const values = samples as number[];
  const step = clean(values[1]! - values[0]!);
  const tolerance = 1e-9 * Math.max(1, Math.abs(step));
  for (let i = 2; i < values.length; i++) {
    if (Math.abs(clean(values[i]! - values[i - 1]!) - step) > tolerance) {
      return undefined;
    }
  }
  const start = direction === 1 ? values[values.length - 1]! : values[0]!;
  return Array.from({ length: count }, (_, k) =>
    clean(start + direction * step * (k + 1))
  );
}
