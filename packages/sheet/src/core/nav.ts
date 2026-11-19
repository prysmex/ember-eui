/** Keyboard navigation the grid does not do: Ctrl/Cmd+arrow edge jumps. */
import { isEmptyValue, resolveType, valueOf } from './fields.ts';

import type { Pos, SheetContext } from './types.ts';

const STEPS = {
  up: [-1, 0],
  down: [1, 0],
  left: [0, -1],
  right: [0, 1]
} as const;

/**
 * The cell Ctrl/Cmd+arrow jumps to, Excel's rule: from a non-empty cell
 * whose neighbour is non-empty, the last non-empty cell of that block;
 * otherwise the next non-empty cell; when there is none, the last cell in
 * that direction. Only the records and fields of `ctx` count (a position
 * outside them, the add row, is empty). At the edge: `pos`.
 */
export function edgeTarget<T>(
  ctx: SheetContext<T>,
  pos: Pos,
  direction: 'up' | 'down' | 'left' | 'right'
): Pos {
  const [dr, dc] = STEPS[direction];
  const rows = ctx.records.length;
  const cols = ctx.fields.length;
  const inside = (row: number, col: number) =>
    row >= 0 && row < rows && col >= 0 && col < cols;
  const empty = (row: number, col: number): boolean => {
    if (!inside(row, col)) return true;
    const field = ctx.fields[col]!;
    return isEmptyValue(
      resolveType(ctx.types, field),
      valueOf(ctx.records[row], field.id)
    );
  };
  let row = pos.row + dr;
  let col = pos.col + dc;
  if (!inside(row, col)) return pos;
  if (!empty(pos.row, pos.col) && !empty(row, col)) {
    // to the end of this block
    while (inside(row + dr, col + dc) && !empty(row + dr, col + dc)) {
      row += dr;
      col += dc;
    }
    return { row, col };
  }
  // to the next non-empty cell, else the edge
  while (empty(row, col) && inside(row + dr, col + dc)) {
    row += dr;
    col += dc;
  }
  return { row, col };
}
