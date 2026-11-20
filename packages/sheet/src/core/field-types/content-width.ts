/**
 * `contentWidth` of the built-in types whose cells are not plain text
 * (v0.4 01, "Fit to content"). Internal: not exported from the core.
 */

/** The items a chip, person or file cell shows before "+N" (the cells' `MAX_CHIPS`). */
const SHOWN = 3;
/** The gap between two items of a cell (`.euiSheet__chips`). */
const GAP = 4;

/** A badge's padding and border around its label. */
export const CHIP_EXTRA = 24;
/** A person's avatar (size s) and its gap to the name. */
export const PERSON_EXTRA = 28;

/**
 * The width of a cell's row of items: the first three of `widths`, the
 * gaps between them, then "+N" for the rest.
 */
export function itemsWidth(
  widths: readonly number[],
  measure: (text: string) => number
): number {
  if (!widths.length) return 0;
  const shown = widths.slice(0, SHOWN);
  let width = shown.reduce((sum, item) => sum + item, 0);
  width += GAP * (shown.length - 1);
  const more = widths.length - shown.length;
  if (more > 0) width += GAP + measure(`+${more}`);
  return width;
}

/** Chips with these labels: each label plus a badge's padding. */
export function chipsWidth(
  labels: readonly string[],
  measure: (text: string) => number,
  extra = CHIP_EXTRA
): number {
  return itemsWidth(
    labels.map((label) => measure(label) + extra),
    measure
  );
}
