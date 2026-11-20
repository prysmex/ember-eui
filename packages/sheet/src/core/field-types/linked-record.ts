import { joinList, splitList } from '../list.ts';
import { chipsWidth } from './content-width.ts';

import type {
  FieldType,
  LinkedRecordField,
  ParseResult,
  SheetLinkedRecord
} from '../types.ts';

type Value = SheetLinkedRecord[];

function list(value: unknown): Value {
  return Array.isArray(value) ? (value as Value) : [];
}

/** Values whose ids are in the same order. */
export function sameIds(
  a: readonly { id: unknown }[],
  b: readonly { id: unknown }[]
): boolean {
  return (
    a.length === b.length &&
    a.every((item, i) => String(item.id) === String(b[i]!.id))
  );
}

/**
 * The array of the resolved parts, without repeated ids; the first part
 * that matched nothing gives an error.
 */
export function combineRecords<V extends { id: unknown }>(
  parts: Array<{ text: string; value: unknown | null }>,
  unresolved: (text: string) => string
): ParseResult<V[]> {
  const value: V[] = [];
  for (const part of parts) {
    if (part.value == null) return { error: unresolved(part.text) };
    const item = part.value as V;
    if (!value.some((existing) => String(existing.id) === String(item.id))) {
      value.push(item);
    }
  }
  return { value };
}

/**
 * `linkedRecord`: an array of `{ id, label }` (`[]` when empty). Typed or
 * pasted text needs the owner's bulk resolve: `parse` answers
 * `{ unresolved }`, `resolve.parts` splits it on `,` (one part without
 * `multiple`), and `combine` builds the array.
 */
export const linkedRecordFieldType: FieldType<Value, LinkedRecordField> = {
  parse(text) {
    const trimmed = text.trim();
    if (trimmed === '') return { value: [] };
    return { unresolved: trimmed };
  },
  resolve: {
    parts(text, field) {
      if (field.multiple === false) {
        const trimmed = text.trim();
        return trimmed ? [splitList(trimmed)[0] ?? trimmed] : [];
      }
      return splitList(text);
    },
    combine(parts, _field, context) {
      return combineRecords<SheetLinkedRecord>(parts, (text) =>
        context.messages.unresolved(text)
      );
    }
  },
  format: (value) =>
    list(value)
      .map((item) => item.label)
      .join(', '),
  copyText: (value) => joinList(list(value).map((item) => item.label)),
  isEmpty: (value) => value == null || list(value).length === 0,
  equals: (a, b) => sameIds(list(a), list(b)),
  compare: (a, b) =>
    list(a)
      .map((item) => item.label)
      .join(', ')
      .localeCompare(
        list(b)
          .map((item) => item.label)
          .join(', ')
      ),
  /** A chip per linked record (three, then "+N"). */
  contentWidth: (value, _field, measure) =>
    chipsWidth(
      list(value).map((item) => item.label),
      measure
    )
};
