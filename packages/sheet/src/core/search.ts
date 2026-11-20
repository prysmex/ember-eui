/**
 * `findMatches` (V03 11.1): the cells whose shown text contains a term,
 * for an owner that holds every record and steps through them with
 * `@currentMatch`. The sheet never calls it (it does not search); an owner
 * that pages gets its matches from its backend instead.
 */
import { resolveType, valueOf } from './fields.ts';

import type { EuiSheetField, RecordId, SheetContext } from './types.ts';

/** Lower case, without accents: what `@highlight` (EuiHighlight) compares. */
function fold(text: string): string {
  return text.normalize('NFD').replace(/\p{M}/gu, '').toLowerCase();
}

/**
 * The cells whose shown text contains `term`, by row then field.
 *
 * It matches what `@highlight` marks: the type's `format` text (a select's
 * label, a date as shown), without case and accents. An empty term has no
 * matches.
 */
export function findMatches<T>(
  ctx: Pick<SheetContext<T>, 'types' | 'messages' | 'getRecordId'>,
  records: readonly T[],
  fields: readonly EuiSheetField<T>[],
  term: string
): Array<{ recordId: RecordId; fieldId: string }> {
  const wanted = fold(term);
  if (!wanted) return [];
  const columns = fields.map((field) => ({
    field,
    type: resolveType(ctx.types, field)
  }));
  const matches: Array<{ recordId: RecordId; fieldId: string }> = [];
  for (const record of records) {
    for (const { field, type } of columns) {
      const text = type.format(valueOf(record, field.id), field, {
        record,
        messages: ctx.messages
      });
      if (text && fold(text).includes(wanted)) {
        matches.push({ recordId: ctx.getRecordId(record), fieldId: field.id });
      }
    }
  }
  return matches;
}
