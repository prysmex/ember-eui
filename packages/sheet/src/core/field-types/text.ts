import type { FieldType, TextField } from '../types.ts';

/** `text`: a string; never rejects a text (PACKAGE-DESIGN.md 5.4). */
export const textFieldType: FieldType<string, TextField> = {
  parse: (text) => ({ value: text }),
  format: (value) => (value == null ? '' : String(value)),
  validate(value, field, { messages }) {
    const errors: string[] = [];
    const text = String(value);
    if (field.maxLength !== undefined && text.length > field.maxLength) {
      errors.push(messages.maxLength(field.maxLength));
    }
    if (field.pattern) {
      field.pattern.lastIndex = 0;
      if (!field.pattern.test(text)) {
        errors.push(field.patternMessage ?? messages.pattern());
      }
    }
    return errors;
  },
  compare: (a, b) => String(a ?? '').localeCompare(String(b ?? ''))
};
