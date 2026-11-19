import { clean, compareNumbers, finiteOrNull, readNumber } from './numeric.ts';

import type { FieldType, PercentField } from '../types.ts';

function text(value: number, field: PercentField, precision?: number): string {
  const percent = clean(value * 100);
  const shown =
    precision === undefined ? String(percent) : percent.toFixed(precision);
  return `${shown.replace('.', field.decimalSeparator ?? '.')}%`;
}

/**
 * `percent`: a fraction or `null` (`0.25` shows `25%`, Q12). Text `25%` or
 * `25` is `0.25`. Shown with `precision` decimals (default 0); copied
 * without rounding, so a paste gives the value back.
 */
export const percentFieldType: FieldType<number | null, PercentField> = {
  parse(input, field, { messages }) {
    const value = readNumber(
      input.trim().replace(/%$/, ''),
      field.decimalSeparator ?? '.'
    );
    if (value === undefined) return { error: messages.notANumber(input) };
    return { value: value === null ? null : clean(value / 100) };
  },
  format(value, field) {
    if (value == null) return '';
    return text(value, field, field.precision ?? 0);
  },
  copyText(value, field) {
    if (value == null) return '';
    return text(value, field);
  },
  validate(value, field, { messages }) {
    if (typeof value !== 'number' || !Number.isFinite(value)) {
      return [messages.notANumber(String(value))];
    }
    const errors: string[] = [];
    if (field.min !== undefined && value < field.min) {
      errors.push(messages.min(text(field.min, field)));
    }
    if (field.max !== undefined && value > field.max) {
      errors.push(messages.max(text(field.max, field)));
    }
    return errors;
  },
  compare: compareNumbers,
  toNumber: finiteOrNull
};
