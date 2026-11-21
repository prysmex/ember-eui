/** The range outline, the copy mark and the flash (V03C-DESIGN.md 3.2). */
import { tracked } from '@glimmer/tracking';
import { isDestroyed, isDestroying } from '@ember/destroyable';

import { findRecords } from '../../core/record-lookup.ts';

import type EuiSheet from '../../components/eui-sheet.gts';
import type { ChangeSet, Range } from '../../core/index.ts';

const FLASH_MS = 600;

export default class SheetOutline<T extends object> {
  sheet: EuiSheet<T>;

  constructor(sheet: EuiSheet<T>) {
    this.sheet = sheet;
  }

  /** The range of the last copy or cut, marked dashed until Escape, a change or another copy (V03 batch 1). */
  @tracked copied: Range | null = null;
  /** Cells a paste, fill, undo or redo just changed: a fading tint (V03 batch 1). */
  @tracked flash: Range | null = null;
  flashTimer: ReturnType<typeof setTimeout> | null = null;

  /* The range outline (V03 batch 1, range feedback) */

  /** The range the outline is drawn for: more than one cell, no editor. */
  get rangeOutline(): Range | null {
    const range = this.sheet.selection.range;
    if (!range || this.sheet.edit.editing) return null;
    const records = this.sheet.rows.recordRange(range);
    if (!records) return null;
    // one record's cell (a header inside does not make it more)
    if (records.top === records.bottom && range.left === range.right) {
      return null;
    }
    return range;
  }

  /**
   * Puts the outline around the union of the range's rendered cells, in a
   * box clipped to the grid body's visible area (right of the frozen
   * columns when the range has none of them). A side whose row or column
   * is not rendered (virtualized) is put past the clip, so it is cut off.
   * Hidden when no cell of the range is in view.
   */
  placeRangeOutline(element: HTMLElement, range: Range): void {
    const wrapper = this.sheet.wrapper;
    const bounds = this.sheet.scroll.scrollBounds();
    const outline = element.firstElementChild as HTMLElement | null;
    const hide = (): void => {
      element.style.display = 'none';
    };
    if (!wrapper || !bounds || !outline) return hide();
    // the range's last record row
    const records = this.sheet.rows.recordRange(range);
    if (!records) return hide();
    const bottom = this.sheet.rows.gridRowOf(records.bottom);
    // grouped, one box per run of records (V03 8.5: the drawn selection is
    // the records; a header or an add row between two runs is not boxed)
    const grouped = this.sheet.rows.isGrouped;
    const boxes = new Map<
      number,
      {
        left: number;
        top: number;
        right: number;
        lower: number;
        minRow: number;
        maxRow: number;
        minCol: number;
        maxCol: number;
      }
    >();
    const cells = wrapper.querySelectorAll<HTMLElement>(
      '[role=gridcell][data-gridcell-visible-row-index]:not(.euiDataGridFooterCell)'
    );
    for (const cell of cells) {
      const row = Number(cell.dataset['gridcellVisibleRowIndex']);
      const col =
        Number(cell.dataset['gridcellColumnIndex']) - this.sheet.colOffset;
      if (row < range.top || row > bottom) continue;
      if (col < range.left || col > range.right) continue;
      if (grouped && !this.sheet.rows.isRecordRow(row)) continue;
      const run = grouped ? this.sheet.rows.rowModel.groupAt(row) : 0;
      const box = cell.getBoundingClientRect();
      const found = boxes.get(run);
      if (!found) {
        boxes.set(run, {
          left: box.left,
          top: box.top,
          right: box.right,
          lower: box.bottom,
          minRow: row,
          maxRow: row,
          minCol: col,
          maxCol: col
        });
        continue;
      }
      found.left = Math.min(found.left, box.left);
      found.top = Math.min(found.top, box.top);
      found.right = Math.max(found.right, box.right);
      found.lower = Math.max(found.lower, box.bottom);
      found.minRow = Math.min(found.minRow, row);
      found.maxRow = Math.max(found.maxRow, row);
      found.minCol = Math.min(found.minCol, col);
      found.maxCol = Math.max(found.maxCol, col);
    }
    if (!boxes.size) return hide();
    const clip = {
      left:
        bounds.frozenRight !== undefined &&
        range.left >= this.sheet.frozen.frozenCount
          ? bounds.frozenRight
          : bounds.left,
      top: bounds.top,
      right: bounds.right,
      bottom: bounds.bottom
    };
    const past = 8;
    const drawn: { left: number; top: number; right: number; lower: number }[] =
      [];
    for (const found of boxes.values()) {
      let { left, top, right, lower } = found;
      // the run's first and last rows inside the range
      let first = range.top;
      let last = bottom;
      if (grouped) {
        const run = this.sheet.rows.recordRunOf(found.minRow);
        first = Math.max(first, run.top);
        last = Math.min(last, run.bottom);
      }
      if (found.minRow > first) top = clip.top - past;
      if (found.maxRow < last) lower = clip.bottom + past;
      if (found.minCol > range.left) left = clip.left - past;
      if (found.maxCol < range.right) right = clip.right + past;
      if (
        right <= clip.left ||
        left >= clip.right ||
        lower <= clip.top ||
        top >= clip.bottom
      ) {
        continue;
      }
      drawn.push({ left, top, right, lower });
    }
    if (!drawn.length) return hide();
    const origin = wrapper.getBoundingClientRect();
    const scale = wrapper.offsetWidth ? origin.width / wrapper.offsetWidth : 1;
    element.style.display = '';
    element.style.left = `${(clip.left - origin.left) / scale}px`;
    element.style.top = `${(clip.top - origin.top) / scale}px`;
    element.style.width = `${Math.max(0, clip.right - clip.left) / scale}px`;
    element.style.height = `${Math.max(0, clip.bottom - clip.top) / scale}px`;
    // the first box is the template's; more runs get copies of it
    while (element.children.length > drawn.length) {
      element.lastElementChild!.remove();
    }
    drawn.forEach((box, i) => {
      let target = element.children[i] as HTMLElement | undefined;
      if (!target) {
        target = outline.cloneNode(false) as HTMLElement;
        element.appendChild(target);
      }
      target.style.left = `${(box.left - clip.left) / scale}px`;
      target.style.top = `${(box.top - clip.top) / scale}px`;
      target.style.width = `${(box.right - box.left) / scale}px`;
      target.style.height = `${(box.lower - box.top) / scale}px`;
    });
  }

  /** The copy mark and the flash are not drawn over an open editor. */
  get copiedOutline(): Range | null {
    return this.sheet.edit.editing ? null : this.copied;
  }

  get flashOutline(): Range | null {
    return this.sheet.edit.editing ? null : this.flash;
  }

  /**
   * The bounding range of a change set's patches (and inserts' first
   * field) in the rows of `@records` before the owner applies it, shown
   * for about 600 ms (V03 batch 1). Rows the owner adds later are not
   * known yet: an insert-only set flashes nothing.
   */
  flashCells(changeSet: ChangeSet): void {
    if (!changeSet.patches.length) return;
    const cols = new Map(
      this.sheet.fields.visibleFields.map((field, i) => [field.id, i])
    );
    const rows = findRecords(
      this.sheet.args.records,
      this.sheet.args.getRecordId,
      new Set(changeSet.patches.map((patch) => String(patch.recordId)))
    );
    let range: Range | null = null;
    for (const patch of changeSet.patches) {
      const col = cols.get(patch.fieldId);
      const row = rows.get(String(patch.recordId))?.row;
      if (col === undefined || row === undefined) continue;
      range = range
        ? {
            top: Math.min(range.top, row),
            bottom: Math.max(range.bottom, row),
            left: Math.min(range.left, col),
            right: Math.max(range.right, col)
          }
        : { top: row, bottom: row, left: col, right: col };
    }
    if (!range) return;
    // drawn in grid rows
    this.flash = {
      ...range,
      top: this.sheet.rows.gridRowOf(range.top),
      bottom: this.sheet.rows.gridRowOf(range.bottom)
    };
    if (this.flashTimer) clearTimeout(this.flashTimer);
    // a plain timer: tests' settled() does not wait for a decoration
    this.flashTimer = setTimeout(() => {
      this.flashTimer = null;
      if (!isDestroying(this.sheet) && !isDestroyed(this.sheet))
        this.flash = null;
    }, FLASH_MS);
  }
}
