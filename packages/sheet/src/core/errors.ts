/** Validation of stored values (PACKAGE-DESIGN.md 6, 9.4 layers 2 and 3). */
import { isEmptyValue, isRequired, resolveType, valueOf } from './fields.ts';

import type {
  EuiSheetField,
  FieldTypeRegistry,
  SheetContext
} from './types.ts';

/** Concatenates, drops duplicates and empty strings. */
export function mergeErrors(
  ...lists: (readonly string[] | string | undefined)[]
): string[] {
  const out: string[] = [];
  for (const list of lists) {
    if (list === undefined) continue;
    for (const message of typeof list === 'string' ? [list] : list) {
      if (message && !out.includes(message)) out.push(message);
    }
  }
  return out;
}

/** Errors of one stored value, in order: required, type.validate, field.validate. */
export function validateCell<T>(
  ctx: SheetContext<T>,
  field: EuiSheetField<T>,
  record: T
): string[] {
  const type = resolveType(ctx.types, field);
  const value = valueOf(record, field.id);
  if (isEmptyValue(type, value)) {
    return isRequired(field, record) ? [ctx.messages.required()] : [];
  }
  const context = { record, messages: ctx.messages };
  return mergeErrors(
    type.validate?.(value, field, context),
    field.validate?.(value, record)
  );
}

/** The type's `compare`, for owners that sort their records. 0 without one. */
export function compareValues(
  types: FieldTypeRegistry,
  field: EuiSheetField,
  a: unknown,
  b: unknown
): number {
  return resolveType(types, field).compare?.(a, b, field) ?? 0;
}
