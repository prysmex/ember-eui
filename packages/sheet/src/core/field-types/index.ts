import { checkboxFieldType } from './checkbox.ts';
import { dateFieldType } from './date.ts';
import { numberFieldType } from './number.ts';
import { singleSelectFieldType } from './single-select.ts';
import { textFieldType } from './text.ts';

import type { FieldTypeRegistry } from '../types.ts';

export {
  checkboxFieldType,
  dateFieldType,
  numberFieldType,
  singleSelectFieldType,
  textFieldType
};
export { validIsoDate } from './date.ts';

/** `{ text, number, checkbox, singleSelect, date }`, without components. */
export const builtInFieldTypes: FieldTypeRegistry = {
  text: textFieldType,
  number: numberFieldType,
  checkbox: checkboxFieldType,
  singleSelect: singleSelectFieldType,
  date: dateFieldType
};

/** The built-ins plus `extra`; a type of `extra` with a built-in name replaces it. */
export function createRegistry(extra?: FieldTypeRegistry): FieldTypeRegistry {
  return { ...builtInFieldTypes, ...extra };
}
