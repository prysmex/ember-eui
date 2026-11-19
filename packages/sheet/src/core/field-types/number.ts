import type { FieldType, NumberField } from '../types.ts';

function escape(char: string): string {
  return char === '.' ? '\\.' : char;
}

/**
 * `number`: a number or `null`. `1,234.5` is read with `,` as the thousands
 * separator (the other of `decimalSeparator`); no exponent, currency or
 * percent sign (PACKAGE-DESIGN.md 5.4).
 */
export const numberFieldType: FieldType<number | null, NumberField> = {
  parse(text, field, { messages }) {
    const trimmed = text.trim();
    if (trimmed === '') return { value: null };
    const d = field.decimalSeparator ?? '.';
    const g = d === '.' ? ',' : '.';
    let result = trimmed.replace(/\s+/g, '');
    if (result.includes(g)) {
      const grouped = new RegExp(
        `^[-+]?\\d{1,3}(${escape(g)}\\d{3})+(${escape(d)}\\d+)?$`
      );
      if (!grouped.test(result)) return { error: messages.notANumber(text) };
      result = result.split(g).join('');
    }
    result = result.replace(d, '.');
    if (!/^[-+]?(\d+\.?\d*|\.\d+)$/.test(result)) {
      return { error: messages.notANumber(text) };
    }
    return { value: Number(result) };
  },
  format(value, field) {
    if (value == null) return '';
    const d = field.decimalSeparator ?? '.';
    return String(value).replace('.', d);
  },
  validate(value, field, { messages }) {
    if (typeof value !== 'number' || !Number.isFinite(value)) {
      return [messages.notANumber(String(value))];
    }
    const errors: string[] = [];
    if (field.min !== undefined && value < field.min) {
      errors.push(messages.min(field.min));
    }
    if (field.max !== undefined && value > field.max) {
      errors.push(messages.max(field.max));
    }
    return errors;
  },
  compare(a, b) {
    if (a == null) return b == null ? 0 : -1;
    if (b == null) return 1;
    return a - b;
  }
};
