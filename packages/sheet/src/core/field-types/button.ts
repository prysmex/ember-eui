/**
 * `button` (V03 10.3.1, D17): a cell that runs an action of the app on its
 * record. It stores no value: every cell is read-only (`readOnly`), so a
 * paste, fill, clear or cut skips the column, and a text never parses.
 * The cell shows, and copies, the button's text.
 */
import type { ButtonField, FieldType } from '../types.ts';

/** The button's text for a record: `buttonLabel` (or its function's), else the field's label. */
export function buttonText(field: ButtonField, record: unknown): string {
  const label = field.buttonLabel;
  if (typeof label === 'function') {
    return record === undefined ? (field.label ?? field.id) : label(record);
  }
  return label ?? field.label ?? field.id;
}

export const buttonFieldType: FieldType<null, ButtonField> = {
  readOnly: true,
  parse(text, _field, { messages, source }) {
    // the empty value a clear asks for (the column is read-only anyway)
    if (source === 'clear' && text === '') return { value: null };
    return { error: messages.buttonNoValue() };
  },
  format: (_value, field, { record }) => buttonText(field, record),
  copyText: (_value, field, { record }) => buttonText(field, record),
  isEmpty: () => true
};
