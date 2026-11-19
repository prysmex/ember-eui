import type {
  EuiSheetField,
  FieldType,
  FieldTypeRegistry,
  RecordId,
  SheetContext,
  SheetOption
} from './types.ts';

/** The field's type: `types[field.type ?? 'text']`. Throws for an unknown name. */
export function resolveType(
  types: FieldTypeRegistry,
  field: EuiSheetField
): FieldType<any, any> {
  const name = field.type ?? 'text';
  const type = types[name];
  if (!type) {
    throw new Error(
      `EuiSheet: unknown field type "${name}" (field "${field.id}")`
    );
  }
  return type;
}

function flag<T>(
  value: EuiSheetField<T>['readOnly'],
  record: T | undefined
): boolean {
  return typeof value === 'function'
    ? value(record ?? ({} as T))
    : Boolean(value);
}

export function isReadOnly<T>(
  ctx: Pick<SheetContext<T>, 'readOnly'>,
  field: EuiSheetField<T>,
  record: T | undefined
): boolean {
  return Boolean(ctx.readOnly) || flag(field.readOnly, record);
}

export function isRequired<T>(
  field: EuiSheetField<T>,
  record: T | undefined
): boolean {
  return flag(field.required, record);
}

/** `field.options` as an array, or `field.options(record)`, or `[]`. */
export function fieldOptions<T>(
  field: EuiSheetField<T>,
  record: T | undefined
): SheetOption[] {
  const options = field['options'] as
    SheetOption[] | ((record: T) => SheetOption[]) | undefined;
  if (typeof options === 'function') return options(record ?? ({} as T));
  return Array.isArray(options) ? options : [];
}

export function isEmptyValue(
  type: FieldType<any, any>,
  value: unknown
): boolean {
  return type.isEmpty ? type.isEmpty(value) : value == null || value === '';
}

/** Whether two values of a field are the same: the type's `equals`, else `Object.is`. */
export function sameFieldValue(
  type: FieldType<any, any>,
  a: unknown,
  b: unknown
): boolean {
  return type.equals ? type.equals(a, b) : Object.is(a, b);
}

/** Key of one cell in maps: `${id}\u0000${fieldId}`. */
export function cellKey(id: RecordId | string, fieldId: string): string {
  return `${String(id)}\u0000${fieldId}`;
}

/** The value of `fieldId` in a record. */
export function valueOf(record: unknown, fieldId: string): unknown {
  return (record as Record<string, unknown> | undefined)?.[fieldId];
}
