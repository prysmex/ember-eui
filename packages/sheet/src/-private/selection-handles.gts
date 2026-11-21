/**
 * The selection handles (V03 11.3): after a touch press, a circle at the
 * range's top-left and one at its bottom-right corner, drawn beside the
 * grid like the fill handle (so they are above frozen cells too) and
 * re-placed on the same renders. Dragging one moves its corner; the sheet
 * owns the drag (`selectionHandles`). Each hides while its corner is not
 * in view.
 */
import Component from '@glimmer/component';
import { fn } from '@ember/helper';
import { on } from '@ember/modifier';
import { schedule } from '@ember/runloop';
import { modifier } from 'ember-modifier';

import type EuiSheet from '../components/eui-sheet.gts';
import type { Range } from '../core/index.ts';
import type { HandleCorner } from './sheet/selection-handles.ts';

interface SelectionHandlesSignature {
  Args: {
    sheet: EuiSheet<any>;
    range: Range;
    /** Changes when the grid's columns change (a scroll places them through `scroll.placeOnScroll`). */
    tick: number;
    /** `@records` and the row height: rows may have moved. */
    records: unknown[];
    rowHeight: string;
  };
}

export default class SelectionHandles extends Component<SelectionHandlesSignature> {
  place = modifier(
    (
      element: HTMLElement,
      [corner, range, tick, records, rowHeight]: [
        HandleCorner,
        Range,
        number,
        unknown[],
        string
      ]
    ) => {
      void tick;
      void records;
      void rowHeight;
      const place = () => {
        if (this.isDestroying || this.isDestroyed) return;
        this.args.sheet.selectionHandles.place(element, range, corner);
      };
      // after the grid rendered the cells of this render
      schedule('afterRender', place);
      // and after each scroll's
      return this.args.sheet.scroll.placeOnScroll(place);
    }
  );

  get title(): string {
    return this.args.sheet.messages.selectionHandle();
  }

  <template>
    <div
      class="euiSheet__selectionHandle euiSheet__selectionHandle--start"
      data-test-subj="euiSheetSelectionHandle"
      data-eui-sheet-handle="start"
      title={{this.title}}
      aria-hidden="true"
      {{this.place "start" @range @tick @records @rowHeight}}
      {{on "pointerdown" (fn @sheet.selectionHandles.onHandleDown "start")}}
    ></div>
    <div
      class="euiSheet__selectionHandle euiSheet__selectionHandle--end"
      data-test-subj="euiSheetSelectionHandle"
      data-eui-sheet-handle="end"
      title={{this.title}}
      aria-hidden="true"
      {{this.place "end" @range @tick @records @rowHeight}}
      {{on "pointerdown" (fn @sheet.selectionHandles.onHandleDown "end")}}
    ></div>
  </template>
}
