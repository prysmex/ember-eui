import type { FieldType, LongTextField } from '../types.ts';

/** `longText`: a string that may hold line breaks; never rejects a text. */
export const longTextFieldType: FieldType<string, LongTextField> = {
  parse: (text) => ({ value: text }),
  format: (value) => (value == null ? '' : String(value)),
  validate(value, field, { messages }) {
    return field.maxLength !== undefined &&
      String(value).length > field.maxLength
      ? [messages.maxLength(field.maxLength)]
      : [];
  },
  compare: (a, b) => String(a ?? '').localeCompare(String(b ?? ''))
};
