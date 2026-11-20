import { compareNumbers, finiteOrNull, numericSeries } from './numeric.ts';

import type { FieldType, RatingField } from '../types.ts';

const maxOf = (field: RatingField): number => field.max ?? 5;

/**
 * `rating`: a whole number from 1 to `max` (default 5), or `null` (no
 * stars). Text is a whole number from 0 to `max` (0 clears). In nav mode a
 * digit key sets it; the cell's stars are clicked.
 */
export const ratingFieldType: FieldType<number | null, RatingField> = {
  parse(text, field, { messages }) {
    const t = text.trim();
    if (t === '') return { value: null };
    if (!/^\d+$/.test(t)) return { error: messages.notANumber(text) };
    const n = Number(t);
    if (n > maxOf(field)) return { error: messages.max(maxOf(field)) };
    return { value: n === 0 ? null : n };
  },
  format: (value) => (value == null ? '' : String(value)),
  validate(value, field, { messages }) {
    if (typeof value !== 'number' || !Number.isInteger(value)) {
      return [messages.notANumber(String(value))];
    }
    if (value < 0) return [messages.min(0)];
    if (value > maxOf(field)) return [messages.max(maxOf(field))];
    return [];
  },
  navKey(key, _value, field) {
    if (!/^\d$/.test(key)) return undefined;
    const n = Number(key);
    if (n > maxOf(field)) return undefined;
    return { value: n === 0 ? null : n };
  },
  isEmpty: (value) => value == null || value === 0,
  compare: compareNumbers,
  toNumber: finiteOrNull,
  /** A constant step continues, kept within 1 and `max` (`4, 5` → `5, 5`). */
  series: (samples, count, field, direction) =>
    numericSeries(samples, count, direction)?.map((n) =>
      Math.min(maxOf(field), Math.max(1, Math.round(n)))
    ),
  /** Every star, set or not (16 px glyphs). */
  contentWidth: (_value, field) => maxOf(field) * 18
};
