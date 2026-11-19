import { fieldOptions } from '../fields.ts';
import { joinList, splitList } from '../list.ts';

import type {
  FieldType,
  MultiSelectField,
  SheetOption,
  TypeContext
} from '../types.ts';

type Value = SheetOption['value'];

function labelOf(
  field: MultiSelectField,
  context: TypeContext,
  value: Value
): string {
  return (
    fieldOptions(field, context.record).find((option) => option.value === value)
      ?.label ?? String(value)
  );
}

function list(value: unknown): Value[] {
  return Array.isArray(value) ? (value as Value[]) : [];
}

/**
 * `multiSelect`: an array of option values (`[]` when empty). Text is split
 * on `,` (a part in double quotes keeps its commas); each part matches a
 * label (any case), then a value. A part that matches nothing is a new
 * option on paste with `createOnPaste`, else an error.
 */
export const multiSelectFieldType: FieldType<Value[], MultiSelectField> = {
  parse(text, field, context) {
    const parts = splitList(text);
    const options = fieldOptions(field, context.record);
    const value: Value[] = [];
    const newOptions: SheetOption[] = [];
    for (const part of parts) {
      const lower = part.toLowerCase();
      const match =
        options.find((option) => option.label.trim().toLowerCase() === lower) ??
        options.find((option) => String(option.value) === part) ??
        newOptions.find((option) => option.label.toLowerCase() === lower);
      if (match) {
        if (!value.includes(match.value)) value.push(match.value);
        continue;
      }
      if (field.createOnPaste && context.source === 'paste') {
        const option = { value: part, label: part };
        newOptions.push(option);
        value.push(part);
        continue;
      }
      return { error: context.messages.notAnOption(part) };
    }
    return newOptions.length ? { value, newOptions } : { value };
  },
  format(value, field, context) {
    return list(value)
      .map((v) => labelOf(field, context, v))
      .join(', ');
  },
  copyText(value, field, context) {
    return joinList(list(value).map((v) => labelOf(field, context, v)));
  },
  validate(value, field, context) {
    const options = fieldOptions(field, context.record);
    const errors: string[] = [];
    for (const v of list(value)) {
      if (!options.some((option) => option.value === v)) {
        errors.push(context.messages.notAnOption(String(v)));
      }
    }
    return errors;
  },
  isEmpty: (value) => value == null || list(value).length === 0,
  equals(a, b) {
    const x = list(a);
    const y = list(b);
    return x.length === y.length && x.every((v, i) => Object.is(v, y[i]));
  },
  compare(a, b, field) {
    // option by option, in the order of the options as given
    const options = Array.isArray(field.options) ? field.options : [];
    const index = (value: unknown) => {
      const i = options.findIndex((option) => option.value === value);
      return i === -1 ? Number.POSITIVE_INFINITY : i;
    };
    const x = list(a);
    const y = list(b);
    for (let i = 0; i < Math.min(x.length, y.length); i++) {
      const d = index(x[i]) - index(y[i]);
      if (d) return d < 0 ? -1 : 1;
    }
    return x.length - y.length;
  }
};
