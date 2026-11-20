import type { CheckboxField, FieldType } from '../types.ts';

const TRUE = new Set(['true', '1', 'yes', 'y', 'x', '✓', 'si', 'sí']);
const FALSE = new Set(['false', '0', 'no', 'n', '']);

/** `checkbox`: a boolean; Space toggles it in nav mode (PACKAGE-DESIGN.md 5.4, P7). */
export const checkboxFieldType: FieldType<boolean, CheckboxField> = {
  parse(text, _field, { messages }) {
    const word = text.trim().toLowerCase();
    if (TRUE.has(word)) return { value: true };
    if (FALSE.has(word)) return { value: false };
    return { error: messages.notACheckbox(text) };
  },
  format: (value) => (value === true ? 'true' : 'false'),
  isEmpty: (value) => value !== true,
  navKey: (key, value) => (key === ' ' ? { value: value !== true } : undefined),
  compare: (a, b) => Number(a === true) - Number(b === true),
  /** The box (14 px) and its room. */
  contentWidth: () => 24
};
