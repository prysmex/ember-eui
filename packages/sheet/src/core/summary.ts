/**
 * `summarize`: the text of one summary of a field over records
 * (V02-DESIGN.md 6.6). The sheet never calls it: it shows the texts the
 * owner passes as `@summary`. An owner that has every record (a local
 * store) can compute them with this; one that pages takes them from its
 * backend's aggregations instead, since a summary of the loaded page alone
 * would be wrong.
 */
import { isEmptyValue, resolveType, valueOf } from './fields.ts';

import type { EuiSheetField, FieldType, SheetContext } from './types.ts';

export type SheetSummaryKind =
  | 'count'
  | 'filled'
  | 'empty'
  | 'percentFilled'
  | 'unique'
  | 'sum'
  | 'average'
  | 'min'
  | 'max'
  | 'checked'
  | 'unchecked';

/**
 * - `count`: the number of records; `filled` / `empty`: of non-empty and
 *   empty values (the type's `isEmpty`); `percentFilled`: filled of count,
 *   as a whole percent; `unique`: of distinct non-empty values (by the
 *   type's `copyText`).
 * - `sum`, `average`: over the type's `toNumber` of non-empty values,
 *   formatted with the type's `format`; `''` for a type without `toNumber`.
 * - `min`, `max`: by `toNumber` when the type has it, else by `compare`
 *   (dates, text), formatted with `format`; `''` without either.
 * - `checked` / `unchecked`: of values that are / are not `true`.
 *
 * `''` when there is nothing to summarize (no non-empty value for sum,
 * average, min, max).
 */
export function summarize<T>(
  ctx: Pick<SheetContext<T>, 'types' | 'messages'>,
  records: readonly T[],
  field: EuiSheetField<T>,
  kind: SheetSummaryKind
): string {
  const type = resolveType(ctx.types, field) as FieldType<unknown>;
  const typeContext = { record: undefined, messages: ctx.messages };
  const values = records.map((record) => valueOf(record, field.id));
  const filled = values.filter((value) => !isEmptyValue(type, value));
  switch (kind) {
    case 'count':
      return String(values.length);
    case 'filled':
      return String(filled.length);
    case 'empty':
      return String(values.length - filled.length);
    case 'percentFilled':
      return values.length
        ? `${Math.round((filled.length / values.length) * 100)}%`
        : '';
    case 'unique': {
      const text = type.copyText ?? type.format;
      return String(
        new Set(filled.map((value) => text(value, field, typeContext))).size
      );
    }
    case 'checked':
      return String(values.filter((value) => value === true).length);
    case 'unchecked':
      return String(values.filter((value) => value !== true).length);
    case 'sum':
    case 'average': {
      const numbers = toNumbers(type, field, filled);
      if (!numbers || !numbers.length) return '';
      const sum = numbers.reduce((total, n) => total + n, 0);
      const result = kind === 'sum' ? sum : sum / numbers.length;
      return type.format(result, field, typeContext);
    }
    case 'min':
    case 'max': {
      const sign = kind === 'min' ? -1 : 1;
      const numbers = toNumbers(type, field, filled);
      if (numbers) {
        if (!numbers.length) return '';
        const best = sign < 0 ? Math.min(...numbers) : Math.max(...numbers);
        return type.format(best, field, typeContext);
      }
      const compare = type.compare;
      if (!compare || !filled.length) return '';
      const best = filled.reduce((a, b) =>
        sign * compare(b, a, field) > 0 ? b : a
      );
      return type.format(best, field, typeContext);
    }
  }
  return '';
}

/** The type's numbers of these values (those it has one for), or null when it has no `toNumber`. */
function toNumbers(
  type: FieldType<unknown>,
  field: EuiSheetField,
  values: unknown[]
): number[] | null {
  const toNumber = type.toNumber;
  if (!toNumber) return null;
  const numbers: number[] = [];
  for (const value of values) {
    const n = toNumber(value, field);
    if (n !== null && Number.isFinite(n)) numbers.push(n);
  }
  return numbers;
}
