/**
 * Range fill: fill down (Ctrl/Cmd+D) and tiling a pasted block over a
 * larger selection, both Excel-style.
 */
import { isReadOnly, resolveType, sameFieldValue, valueOf } from './fields.ts';

import type { CellPatch, ChangeSet, Range, SheetContext } from './types.ts';

/**
 * Fill down. A range of several rows: each column's top value is copied to
 * the cells below it in the range. A range of one row (a single cell): each
 * cell gets the value of the cell above it. Values are copied as they are
 * (no parsing). Read-only cells are skipped and unchanged values give no
 * patch. `null` when nothing changes. Source 'fill'.
 */
export function fillDown<T>(
  ctx: SheetContext<T>,
  range: Range
): ChangeSet | null {
  const top = Math.max(range.top, 0);
  const bottom = Math.min(range.bottom, ctx.records.length - 1);
  const left = Math.max(range.left, 0);
  const right = Math.min(range.right, ctx.fields.length - 1);
  if (bottom < top || right < left) return null;
  // one row: the row above is the source, the row itself the target
  const sourceRow = bottom > top ? top : top - 1;
  const firstTarget = bottom > top ? top + 1 : top;
  const source = ctx.records[sourceRow];
  if (source === undefined) return null;

  const patches: CellPatch[] = [];
  for (let col = left; col <= right; col++) {
    const field = ctx.fields[col]!;
    const type = resolveType(ctx.types, field);
    const value = valueOf(source, field.id);
    for (let row = firstTarget; row <= bottom; row++) {
      const record = ctx.records[row]!;
      if (isReadOnly(ctx, field, record)) continue;
      const from = valueOf(record, field.id);
      if (sameFieldValue(type, from, value)) continue;
      patches.push({
        recordId: ctx.getRecordId(record),
        fieldId: field.id,
        from,
        to: value
      });
    }
  }
  if (!patches.length) return null;
  return {
    source: 'fill',
    patches,
    inserts: [],
    rejected: [],
    newOptions: []
  };
}

/**
 * The block to paste into a selection of `height` × `width` cells. When the
 * block is rectangular (every line as wide) and the selection's height and
 * width are whole multiples of the block's, the block repeated over the
 * whole selection (a 1×1 block always fills it). Otherwise the block itself:
 * it is pasted at the selection's top-left, sized by the block.
 */
export function tileMatrix(
  matrix: readonly (readonly string[])[],
  height: number,
  width: number
): readonly (readonly string[])[] {
  const blockHeight = matrix.length;
  const blockWidth = matrix[0]?.length ?? 0;
  if (!blockHeight || !blockWidth) return matrix;
  if (matrix.some((line) => line.length !== blockWidth)) return matrix;
  if (height % blockHeight !== 0 || width % blockWidth !== 0) return matrix;
  if (height === blockHeight && width === blockWidth) return matrix;
  return Array.from({ length: height }, (_, i) =>
    Array.from(
      { length: width },
      (_, j) => matrix[i % blockHeight]![j % blockWidth]!
    )
  );
}
