/**
 * The range outline (V03 batch 1, range feedback): a 3 px border inside
 * the selected range's box when it has more than one cell, as Airtable
 * draws it; the selected tint alone is faint. The active cell's ring is
 * moved 4 px in while it shows (`euiSheet--ranged`), so the two stay apart. Drawn by the sheet beside the grid
 * like the fill handle (so it is above frozen cells), in a box clipped to
 * the grid body's visible area: it never covers the header, and the sides
 * of a range that runs past the view are cut off. No pointer events.
 */
import Component from '@glimmer/component';
import { schedule } from '@ember/runloop';
import { modifier } from 'ember-modifier';

import type EuiSheet from '../components/eui-sheet.gts';
import type { Range } from '../core/index.ts';

interface RangeOutlineSignature {
  Args: {
    sheet: EuiSheet<any>;
    range: Range;
    /** Changes when the grid scrolls or a column is resized. */
    tick: number;
    /** `@records`, the columns and the row height: cells may have moved. */
    records: unknown[];
    columns: unknown[];
    rowHeight: string;
    /** 'range' (default); 'copied': the dashed mark of a copy or cut; 'flash': changed cells, fading. */
    kind?: 'range' | 'copied' | 'flash' | 'fill';
  };
}

export default class RangeOutline extends Component<RangeOutlineSignature> {
  place = modifier(
    (
      element: HTMLElement,
      [range, tick, records, columns, rowHeight]: [
        Range,
        number,
        unknown[],
        unknown[],
        string
      ]
    ) => {
      void tick;
      void records;
      void columns;
      void rowHeight;
      // after the grid rendered the cells of this render
      schedule('afterRender', () => {
        if (this.isDestroying || this.isDestroyed) return;
        this.args.sheet.placeRangeOutline(element, range);
      });
    }
  );

  get kind(): string {
    return this.args.kind ?? 'range';
  }

  get testSubj(): string {
    return this.kind === 'range'
      ? 'euiSheetRangeOutline'
      : this.kind === 'copied'
        ? 'euiSheetCopiedOutline'
        : this.kind === 'fill'
          ? 'euiSheetFillOutline'
          : 'euiSheetFlash';
  }

  <template>
    <div
      class="euiSheet__rangeClip euiSheet__rangeClip--{{this.kind}}"
      data-test-subj={{this.testSubj}}
      aria-hidden="true"
      {{this.place @range @tick @records @columns @rowHeight}}
    ><div class="euiSheet__range euiSheet__range--{{this.kind}}"></div></div>
  </template>
}
