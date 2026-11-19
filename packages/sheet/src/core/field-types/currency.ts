import {
  compareNumbers,
  finiteOrNull,
  numericSeries,
  readNumber
} from './numeric.ts';

import type { CurrencyField, FieldType } from '../types.ts';

/** The locale's decimal separator ('.' when it cannot be read). */
function decimalOf(field: CurrencyField): '.' | ',' {
  if (field.decimalSeparator) return field.decimalSeparator;
  try {
    const part = new Intl.NumberFormat(field.locale)
      .formatToParts(1.5)
      .find((p) => p.type === 'decimal');
    return part?.value === ',' ? ',' : '.';
  } catch {
    return '.';
  }
}

function formatter(field: CurrencyField): Intl.NumberFormat | null {
  const precision = field.precision ?? 2;
  try {
    return new Intl.NumberFormat(field.locale, {
      style: 'currency',
      currency: field.currency,
      minimumFractionDigits: precision,
      maximumFractionDigits: precision
    });
  } catch {
    return null;
  }
}

/**
 * `currency`: a number or `null`, shown with `Intl.NumberFormat` (`currency`
 * is the ISO code). Text may carry the symbol, the code and spaces; the rest
 * is read as a number with the locale's decimal separator. Copies the plain
 * number.
 */
export const currencyFieldType: FieldType<number | null, CurrencyField> = {
  parse(text, field, { messages }) {
    if (text.trim() === '') return { value: null };
    // the code, then anything that is not part of a number
    const code = field.currency
      ? new RegExp(field.currency.replace(/[^A-Za-z]/g, ''), 'gi')
      : null;
    let stripped = code ? text.replace(code, '') : text;
    stripped = stripped.replace(/[^\d.,+-]/g, '');
    const value = readNumber(stripped, decimalOf(field));
    if (value == null) return { error: messages.notANumber(text) };
    return { value };
  },
  format(value, field) {
    if (value == null) return '';
    return formatter(field)?.format(value) ?? String(value);
  },
  copyText(value, field) {
    if (value == null) return '';
    return String(value).replace('.', decimalOf(field));
  },
  validate(value, field, { messages }) {
    if (typeof value !== 'number' || !Number.isFinite(value)) {
      return [messages.notANumber(String(value))];
    }
    const errors: string[] = [];
    const format = (n: number) => formatter(field)?.format(n) ?? String(n);
    if (field.min !== undefined && value < field.min) {
      errors.push(messages.min(format(field.min)));
    }
    if (field.max !== undefined && value > field.max) {
      errors.push(messages.max(format(field.max)));
    }
    return errors;
  },
  compare: compareNumbers,
  toNumber: finiteOrNull,
  series: (samples, count, _field, direction) =>
    numericSeries(samples, count, direction)
};
