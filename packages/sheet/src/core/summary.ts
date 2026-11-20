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

/** What `summarizeCells` computes over a selection (V03 11.2). */
export type SheetCellSummaryKind =
  'count' | 'filled' | 'sum' | 'average' | 'min' | 'max';

/**
 * One summary over every cell of a selection (the block's `selection`,
 * `api.getSelection()`, `@onSelectionChange`): Airtable's bar over a
 * rectangle. The sheet never calls it.
 *
 * - `count`: the cells (records × fields); `filled`: the non-empty ones
 *   (each type's `isEmpty`).
 * - `sum`, `average`, `min`, `max`: over each type's `toNumber` of the
 *   non-empty cells (types without it count for nothing). Formatted with
 *   the field's `format` when the selection is one field, else a plain
 *   number rounded to at most two decimals. `''` when no cell has a
 *   number.
 */
export function summarizeCells<T>(
  ctx: Pick<SheetContext<T>, 'types' | 'messages'>,
  selection: {
    readonly records: readonly T[];
    readonly fields: readonly EuiSheetField<T>[];
  },
  kind: SheetCellSummaryKind
): string {
  const { records, fields } = selection;
  if (kind === 'count') return String(records.length * fields.length);
  let filled = 0;
  const numbers: number[] = [];
  for (const field of fields) {
    const type = resolveType(ctx.types, field) as FieldType<unknown>;
    const values = records
      .map((record) => valueOf(record, field.id))
      .filter((value) => !isEmptyValue(type, value));
    filled += values.length;
    numbers.push(...(toNumbers(type, field, values) ?? []));
  }
  if (kind === 'filled') return String(filled);
  if (!numbers.length) return '';
  const sum = numbers.reduce((total, n) => total + n, 0);
  const result =
    kind === 'sum'
      ? sum
      : kind === 'average'
        ? sum / numbers.length
        : // no spread: a selection may hold more numbers than a call takes
          numbers.reduce((a, b) =>
            kind === 'min' ? Math.min(a, b) : Math.max(a, b)
          );
  const field = fields.length === 1 ? fields[0] : undefined;
  if (field) {
    const type = resolveType(ctx.types, field) as FieldType<unknown>;
    return type.format(result, field, {
      record: undefined,
      messages: ctx.messages
    });
  }
  return String(Math.round(result * 100) / 100);
}
