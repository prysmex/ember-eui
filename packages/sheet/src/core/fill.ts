/**
 * Range fill: fill down (Ctrl/Cmd+D), fill right (Ctrl/Cmd+R), the fill
 * handle (`fillRange`, with series) and tiling a pasted block over a
 * larger selection, all Excel-style.
 */
import { isReadOnly, resolveType, sameFieldValue, valueOf } from './fields.ts';

import type {
  CellPatch,
  CellRejection,
  ChangeSet,
  EuiSheetField,
  Range,
  SheetContext
} from './types.ts';

/** A range clamped to the records and fields; null when nothing is left. */
function clampRange<T>(ctx: SheetContext<T>, range: Range): Range | null {
  const clamped = {
    top: Math.max(range.top, 0),
    bottom: Math.min(range.bottom, ctx.records.length - 1),
    left: Math.max(range.left, 0),
    right: Math.min(range.right, ctx.fields.length - 1)
  };
  return clamped.bottom < clamped.top || clamped.right < clamped.left
    ? null
    : clamped;
}

const typeName = (field: EuiSheetField): string => field.type ?? 'text';

/** Collects a fill's patches and rejections, cell by cell. */
class FillWriter<T> {
  patches: CellPatch[] = [];
  rejected: CellRejection[] = [];

  constructor(private ctx: SheetContext<T>) {}

  /**
   * Writes `value`, read from a cell of `from`, into a cell of `to`. Same
   * type: the value itself (by reference). Another type: through the
   * source's copy text and the target's `parse`, like a paste; a text it
   * cannot read is a rejection. Read-only cells and equal values: nothing.
   */
  write(
    row: number,
    to: EuiSheetField<T>,
    from: EuiSheetField<T>,
    value: unknown
  ): void {
    const ctx = this.ctx;
    const record = ctx.records[row];
    if (record === undefined || isReadOnly(ctx, to, record)) return;
    const type = resolveType(ctx.types, to);
    let next = value;
    if (typeName(from) !== typeName(to)) {
      const source = resolveType(ctx.types, from);
      const context = { record, messages: ctx.messages };
      const text = source.copyText
        ? source.copyText(value, from, context)
        : source.format(value, from, context);
      const result = type.parse(text, to, { ...context, source: 'paste' });
      const recordId = ctx.getRecordId(record);
      if ('error' in result || 'unresolved' in result) {
        this.rejected.push({
          recordId,
          fieldId: to.id,
          text,
          message:
            'error' in result
              ? result.error
              : ctx.messages.unresolved(result.unresolved)
        });
        return;
      }
      next = result.value;
    }
    const current = valueOf(record, to.id);
    if (sameFieldValue(type, current, next)) return;
    this.patches.push({
      recordId: ctx.getRecordId(record),
      fieldId: to.id,
      from: current,
      to: next
    });
  }

  result(): ChangeSet | null {
    if (!this.patches.length && !this.rejected.length) return null;
    return {
      source: 'fill',
      patches: this.patches,
      inserts: [],
      rejected: this.rejected,
      newOptions: []
    };
  }
}

/**
 * Fill right, the mirror of `fillDown`. A range of several columns: each
 * row's leftmost value is copied to the cells right of it in the range. A
 * range of one column: each cell gets the value of the cell to its left.
 * Same-type values are copied as they are; across types they go through
 * text, like a paste (a text the target cannot read is a rejection).
 * Read-only cells are skipped and unchanged values give no patch. `null`
 * when nothing changes. Source 'fill'.
 */
export function fillRight<T>(
  ctx: SheetContext<T>,
  range: Range
): ChangeSet | null {
  const box = clampRange(ctx, range);
  if (!box) return null;
  const sourceCol = box.right > box.left ? box.left : box.left - 1;
  const firstTarget = box.right > box.left ? box.left + 1 : box.left;
  const from = ctx.fields[sourceCol];
  if (!from) return null;
  const writer = new FillWriter(ctx);
  for (let row = box.top; row <= box.bottom; row++) {
    const value = valueOf(ctx.records[row], from.id);
    for (let col = firstTarget; col <= box.right; col++) {
      writer.write(row, ctx.fields[col]!, from, value);
    }
  }
  return writer.result();
}

/** The index of the sample the `k`-th cell away from the samples repeats (k from 1). */
function repeatIndex(count: number, k: number, direction: 1 | -1): number {
  return direction === 1 ? (k - 1) % count : (count - (k % count)) % count;
}

/**
 * The fill handle: fills `target`, which contains `source` and extends it
 * along one axis (down, up, right or left), from `source`. Per column (a
 * vertical fill) or per row (a horizontal one), the source values are the
 * samples: the type's `series` continues them (a number step, a date step)
 * unless `copy` is set; else, or when it returns `undefined`, they repeat
 * in order. A horizontal series needs every field of the row to have the
 * same type. Values are copied by reference; across types they go
 * through text, as in `fillRight`. Rows past the last record are dropped.
 * Read-only cells are skipped (the series still counts them) and equal
 * values give no patch. `null` when nothing changes. Source 'fill'.
 */
export function fillRange<T>(
  ctx: SheetContext<T>,
  source: Range,
  target: Range,
  options: { copy?: boolean } = {}
): ChangeSet | null {
  const from = clampRange(ctx, source);
  const to = clampRange(ctx, target);
  if (!from || !to) return null;
  const writer = new FillWriter(ctx);
  const vertical = to.bottom > from.bottom || to.top < from.top;
  const direction: 1 | -1 = vertical
    ? to.bottom > from.bottom
      ? 1
      : -1
    : to.right > from.right
      ? 1
      : -1;
  if (vertical) {
    const count = direction === 1 ? to.bottom - from.bottom : from.top - to.top;
    for (let col = from.left; col <= from.right; col++) {
      const field = ctx.fields[col]!;
      const type = resolveType(ctx.types, field);
      const samples: unknown[] = [];
      for (let row = from.top; row <= from.bottom; row++) {
        samples.push(valueOf(ctx.records[row], field.id));
      }
      const series = options.copy
        ? undefined
        : type.series?.(samples, count, field, direction);
      for (let k = 1; k <= count; k++) {
        const row = direction === 1 ? from.bottom + k : from.top - k;
        const value =
          series && series.length >= count
            ? series[k - 1]
            : samples[repeatIndex(samples.length, k, direction)];
        writer.write(row, field, field, value);
      }
    }
    return writer.result();
  }
  if (to.right === from.right && to.left === from.left) return null;
  const count = direction === 1 ? to.right - from.right : from.left - to.left;
  const sourceFields = ctx.fields.slice(from.left, from.right + 1);
  const targetCol = (k: number) =>
    direction === 1 ? from.right + k : from.left - k;
  const targetFields = Array.from(
    { length: count },
    (_, i) => ctx.fields[targetCol(i + 1)]!
  );
  const name = typeName(sourceFields[0]!);
  const oneType = [...sourceFields, ...targetFields].every(
    (field) => typeName(field) === name
  );
  for (let row = from.top; row <= from.bottom; row++) {
    const record = ctx.records[row];
    const samples = sourceFields.map((field) => valueOf(record, field.id));
    const first = sourceFields[0]!;
    const series =
      options.copy || !oneType
        ? undefined
        : resolveType(ctx.types, first).series?.(
            samples,
            count,
            first,
            direction
          );
    for (let k = 1; k <= count; k++) {
      const field = targetFields[k - 1]!;
      if (series && series.length >= count) {
        writer.write(row, field, field, series[k - 1]);
        continue;
      }
      const index = repeatIndex(samples.length, k, direction);
      writer.write(row, field, sourceFields[index]!, samples[index]);
    }
  }
  return writer.result();
}

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
