import { fieldOptions } from '../fields.ts';
import { chipsWidth } from './content-width.ts';

import type {
  FieldType,
  SheetOption,
  SingleSelectField,
  TypeContext
} from '../types.ts';

type Value = SheetOption['value'];

function optionOf(
  field: SingleSelectField,
  context: TypeContext,
  value: unknown
): SheetOption | undefined {
  return fieldOptions(field, context.record).find(
    (option) => option.value === value
  );
}

/**
 * `singleSelect`: the `value` of one of `field.options` (an array, or a
 * function of the record), or `null`. Text matches a label (case-insensitive),
 * then a value (PACKAGE-DESIGN.md 5.4).
 */
export const singleSelectFieldType: FieldType<Value | null, SingleSelectField> =
  {
    parse(text, field, context) {
      const trimmed = text.trim();
      if (trimmed === '') return { value: null };
      const options = fieldOptions(field, context.record);
      const lower = trimmed.toLowerCase();
      const match =
        options.find((option) => option.label.trim().toLowerCase() === lower) ??
        options.find((option) => String(option.value) === trimmed);
      if (match) return { value: match.value };
      if (field.createOnPaste && context.source === 'paste') {
        return {
          value: trimmed,
          newOption: { value: trimmed, label: trimmed }
        };
      }
      return { error: context.messages.notAnOption(text) };
    },
    format(value, field, context) {
      if (value == null || value === '') return '';
      return optionOf(field, context, value)?.label ?? String(value);
    },
    validate(value, field, context) {
      return optionOf(field, context, value)
        ? []
        : [context.messages.notAnOption(String(value))];
    },
    compare(a, b, field) {
      // the order of the options as given (a function of the record: unknown)
      const options = Array.isArray(field.options) ? field.options : [];
      const index = (value: unknown) => {
        const i = options.findIndex((option) => option.value === value);
        return i === -1 ? Number.POSITIVE_INFINITY : i;
      };
      const ia = index(a);
      const ib = index(b);
      return ia === ib ? 0 : ia < ib ? -1 : 1;
    },
    /** One chip. */
    contentWidth(value, field, measure, context) {
      if (value == null || value === '') return 0;
      const label = optionOf(field, context, value)?.label ?? String(value);
      return chipsWidth([label], measure);
    }
  };
