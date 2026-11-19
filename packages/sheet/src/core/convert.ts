/**
 * Values on a field's type change (V03 6.5): the sheet changes no value
 * itself; an owner that wants the stored values converted applies this
 * change set. It is the paste path, so what converts is exactly what could
 * be pasted.
 */
import {
  cellKey,
  isEmptyValue,
  resolveType,
  sameFieldValue,
  valueOf
} from './fields.ts';

import type {
  CellPatch,
  CellRejection,
  ChangeSet,
  EuiSheetField,
  NewOption,
  SheetContext
} from './types.ts';

/**
 * The change set that rewrites `from`'s values as `to`'s (source
 * `'paste'`). Per record: the old type's `copyText(value)` (default
 * `format`), then the new type's `parse(text, to, { source: 'paste' })`.
 * A value gives a patch of `to.id` (none when it equals the stored value);
 * an error or an unresolved text gives a patch to the new type's empty
 * value and a `rejected` entry with the text and the message, so the owner
 * can report what was lost. Options a parse creates (`createOnPaste`) are
 * collected once each in `newOptions`. Empty values give nothing.
 */
export function convertField<T>(
  ctx: Pick<SheetContext<T>, 'types' | 'messages' | 'getRecordId'>,
  records: readonly T[],
  from: EuiSheetField<T>,
  to: EuiSheetField<T>
): ChangeSet {
  const fromType = resolveType(ctx.types, from);
  const toType = resolveType(ctx.types, to);
  const patches: CellPatch[] = [];
  const rejected: CellRejection[] = [];
  const newOptions: NewOption[] = [];
  const seen = new Set<string>();
  let empty: { value: unknown } | null = null;
  const emptyValue = (record: T): unknown => {
    if (!empty) {
      const result = toType.parse('', to, {
        record,
        messages: ctx.messages,
        source: 'clear'
      });
      empty = { value: 'value' in result ? result.value : null };
    }
    return empty.value;
  };

  for (const record of records) {
    const value = valueOf(record, from.id);
    if (isEmptyValue(fromType, value)) continue;
    const context = { record, messages: ctx.messages };
    const text = fromType.copyText
      ? fromType.copyText(value, from, context)
      : fromType.format(value, from, context);
    const recordId = ctx.getRecordId(record);
    // what the patch replaces: the same cell, unless `to` is another field
    const current = to.id === from.id ? value : valueOf(record, to.id);
    const result = toType.parse(text, to, { ...context, source: 'paste' });
    if (!('value' in result)) {
      const message =
        'error' in result
          ? result.error
          : ctx.messages.unresolved(result.unresolved);
      rejected.push({ recordId, fieldId: to.id, text, message });
      const cleared = emptyValue(record);
      if (!sameFieldValue(toType, current, cleared)) {
        patches.push({ recordId, fieldId: to.id, from: current, to: cleared });
      }
      continue;
    }
    for (const option of [
      ...(result.newOption ? [result.newOption] : []),
      ...(result.newOptions ?? [])
    ]) {
      const key = cellKey(String(option.value), to.id);
      if (seen.has(key)) continue;
      seen.add(key);
      newOptions.push({ fieldId: to.id, option });
    }
    if (sameFieldValue(toType, current, result.value)) continue;
    patches.push({ recordId, fieldId: to.id, from: current, to: result.value });
  }
  return { source: 'paste', patches, inserts: [], rejected, newOptions };
}
