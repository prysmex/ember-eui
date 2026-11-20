/**
 * `barcode` (V03 10.3.2, D18): a text shown as a code, typed, pasted or
 * scanned. The value is a plain string (what a scanner or a backend
 * gives) or `null`; the symbology is not stored.
 */
import type { BarcodeField, FieldType } from '../types.ts';

const patterns = new Map<string, RegExp | null>();

/** `field.pattern` as a RegExp; null when it is not a valid one. */
function patternOf(pattern: string): RegExp | null {
  if (!patterns.has(pattern)) {
    let regexp: RegExp | null;
    try {
      regexp = new RegExp(pattern);
    } catch {
      regexp = null;
    }
    patterns.set(pattern, regexp);
  }
  return patterns.get(pattern)!;
}

export const barcodeFieldType: FieldType<string | null, BarcodeField> = {
  parse(text) {
    const trimmed = text.trim();
    return { value: trimmed === '' ? null : trimmed };
  },
  format: (value) => (value == null ? '' : String(value)),
  copyText: (value) => (value == null ? '' : String(value)),
  /** `pattern` as text fields have it (`RegExp.test`: anchor it with `^…$` for a whole match). */
  validate(value, field, { messages }) {
    if (typeof field.pattern !== 'string' || field.pattern === '') return [];
    const regexp = patternOf(field.pattern);
    if (!regexp || regexp.test(String(value))) return [];
    return [
      typeof field['patternMessage'] === 'string'
        ? field['patternMessage']
        : messages.pattern()
    ];
  },
  compare(a, b) {
    if (a == null || a === '') return b == null || b === '' ? 0 : -1;
    if (b == null || b === '') return 1;
    return a < b ? -1 : a > b ? 1 : 0;
  }
};
