/**
 * The fill handle (V02-DESIGN.md 8.4): a small square at the bottom-right
 * corner of the range's last cell, drawn by the sheet beside the grid (so
 * it is above frozen cells too). Pressing and dragging it fills; the sheet
 * owns the drag. Mouse only: Ctrl/Cmd+D and Ctrl/Cmd+R are the keyboard's
 * fills. Its place is measured after each render that changes the range or
 * scrolls; it hides while that corner is not in view.
 */
import Component from '@glimmer/component';
import { on } from '@ember/modifier';
import { schedule } from '@ember/runloop';
import { modifier } from 'ember-modifier';

import type EuiSheet from '../components/eui-sheet.gts';
import type { Range } from '../core/index.ts';

interface FillHandleSignature {
  Args: {
    sheet: EuiSheet<any>;
    range: Range;
    /** Changes when the grid scrolls or its columns change. */
    tick: number;
    /** `@records` and the row height: rows may have moved. */
    records: unknown[];
    rowHeight: string;
    onPress: (event: MouseEvent) => void;
  };
}

export default class FillHandle extends Component<FillHandleSignature> {
  place = modifier(
    (
      element: HTMLElement,
      [range, tick, records, rowHeight]: [Range, number, unknown[], string]
    ) => {
      void tick;
      void records;
      void rowHeight;
      // after the grid rendered the cells of this render
      schedule('afterRender', () => {
        if (this.isDestroying || this.isDestroyed) return;
        this.args.sheet.placeFillHandle(element, range);
      });
    }
  );

  <template>
    <div
      class="euiSheet__fillHandle"
      data-test-subj="euiSheetFillHandle"
      aria-hidden="true"
      {{this.place @range @tick @records @rowHeight}}
      {{on "mousedown" @onPress}}
    ></div>
  </template>
}
