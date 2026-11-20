/**
 * The records on screen, for `@onVisibleRangeChange` (v0.4 09): the
 * grid's visible rows as positions in `@records`. Pure: no sheet, no DOM.
 */
import type { RowModel } from '../core/index.ts';
import type { SheetVisibleRange } from '../types.ts';

/** The grid rows the grid reports as visible, first and last (inclusive). */
export interface RenderedRows {
  start: number;
  stop: number;
}

/**
 * The records among the visible grid rows: `first` is the first record
 * row at or after `start`, `last` the last at or before `stop` (group
 * headers and add rows are skipped). Null when no record is on screen.
 */
export function toRecordRange(
  rendered: RenderedRows,
  rowModel: RowModel,
  count: number
): SheetVisibleRange | null {
  const range = rowModel.recordRange({
    top: rendered.start,
    left: 0,
    bottom: rendered.stop,
    right: 0
  });
  if (!range) return null;
  return { first: range.top, last: range.bottom, count };
}

/** Whether `next` differs from the range last reported (none: it does). */
export function changed(
  previous: SheetVisibleRange | null,
  next: SheetVisibleRange
): boolean {
  return (
    !previous ||
    previous.first !== next.first ||
    previous.last !== next.last ||
    previous.count !== next.count
  );
}
