/** Row colours (V03 10.2, D10): a 4 px bar at a row's left edge, from `@rowColor`. */
import type EuiSheet from '../../components/eui-sheet.gts';
import type { SheetRowColor } from '../../types.ts';

/** The theme's named row colours: `--euiSheet-row<Name>` (4.6). */
const NAMED: ReadonlySet<string> = new Set([
  'primary',
  'accent',
  'success',
  'warning',
  'danger',
  'neutral'
]);

/** A CSS colour as given, unless it could leave the custom property. */
function cssColor(color: string): string | null {
  return /[;{}<>]/.test(color) ? null : color;
}

export default class SheetRowColors<T extends object> {
  sheet: EuiSheet<T>;

  constructor(sheet: EuiSheet<T>) {
    this.sheet = sheet;
  }

  /** `@rowColor(record)` of a grid row; undefined for a row that is not a record. */
  colorOf(row: number): SheetRowColor | undefined {
    const rowColor = this.sheet.args.rowColor;
    if (!rowColor) return undefined;
    const record = this.sheet.rows.recordAt(row);
    return record === undefined ? undefined : rowColor(record);
  }

  /**
   * The class and custom property that draw a row's bar on the cell at its
   * left edge: the row-number cell, or without row numbers the first
   * field's cell. A named colour is a class (`euiSheet__rowColor--danger`,
   * the theme's token); any other colour is set as given.
   */
  barProps(
    row: number
  ): { className: string; style: Record<string, string> } | null {
    const color = this.colorOf(row);
    if (!color) return null;
    if (NAMED.has(color)) {
      return {
        className: `euiSheet__rowColor euiSheet__rowColor--${color}`,
        style: {}
      };
    }
    const css = cssColor(color);
    if (!css) return null;
    return {
      className: 'euiSheet__rowColor',
      style: { '--euiSheetRowColor': css }
    };
  }
}
