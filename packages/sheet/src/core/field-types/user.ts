import { joinList, splitList } from '../list.ts';
import { chipsWidth, PERSON_EXTRA } from './content-width.ts';
import { combineRecords, sameIds } from './linked-record.ts';

import type { FieldType, SheetUser, UserField } from '../types.ts';

type Value = SheetUser | SheetUser[] | null;

function users(value: unknown): SheetUser[] {
  if (Array.isArray(value)) return value as SheetUser[];
  return value && typeof value === 'object' ? [value as SheetUser] : [];
}

function matchUser(
  options: readonly SheetUser[],
  text: string
): SheetUser | undefined {
  const lower = text.toLowerCase();
  return (
    options.find((user) => user.label.trim().toLowerCase() === lower) ??
    options.find((user) => user.email?.trim().toLowerCase() === lower)
  );
}

/**
 * `user`: `{ id, label, avatarUrl? }` or `null`; with `multiple`, an array
 * (`[]` when empty). With `options`, text matches a label or an email (any
 * case); without, it needs the owner's bulk resolve (as `linkedRecord`).
 */
export const userFieldType: FieldType<Value, UserField> = {
  parse(text, field, { messages }) {
    const trimmed = text.trim();
    const empty = field.multiple ? [] : null;
    if (trimmed === '') return { value: empty };
    const parts = field.multiple ? splitList(trimmed) : [trimmed];
    if (!field.options) return { unresolved: trimmed };
    const found: SheetUser[] = [];
    for (const part of parts) {
      const user = matchUser(field.options, part);
      if (!user) return { error: messages.notAnOption(part) };
      if (!found.some((existing) => String(existing.id) === String(user.id))) {
        found.push(user);
      }
    }
    return { value: field.multiple ? found : found[0]! };
  },
  resolve: {
    parts: (text, field) =>
      field.multiple ? splitList(text) : text.trim() ? [text.trim()] : [],
    combine(parts, field, context) {
      const result = combineRecords<SheetUser>(parts, (text) =>
        context.messages.unresolved(text)
      );
      if (!('value' in result) || field.multiple) return result;
      return { value: result.value[0] ?? null };
    }
  },
  format: (value) =>
    users(value)
      .map((user) => user.label)
      .join(', '),
  copyText: (value, field) =>
    field.multiple
      ? joinList(users(value).map((user) => user.label))
      : (users(value)[0]?.label ?? ''),
  isEmpty: (value) => users(value).length === 0,
  equals: (a, b) => sameIds(users(a), users(b)),
  compare: (a, b) =>
    users(a)
      .map((user) => user.label)
      .join(', ')
      .localeCompare(
        users(b)
          .map((user) => user.label)
          .join(', ')
      ),
  /** An avatar and a name per user (three, then "+N"). */
  contentWidth: (value, _field, measure) =>
    chipsWidth(
      users(value).map((user) => user.label),
      measure,
      PERSON_EXTRA
    )
};
