import Component from '@glimmer/component';
import { htmlSafe } from '@ember/template';

import EuiDataGridCell from './cell.gts';
// ember-eui extension (row-tree): treegrid row attributes
import { rowTreeRowAttributes } from './row-tree-hooks.ts';

import type EuiDataGrid from '../eui-data-grid.gts';
import type { EuiDataGridSignature } from '../eui-data-grid.gts';
import type EuiDataGridBody from './body.gts';

export interface EuiDataGridRowSignature {
  Args: {
    grid: EuiDataGrid;
    body: EuiDataGridBody;
    visibleRowIndex: number;
    hasCellPopoverBlock?: boolean;
  };
  Blocks: Pick<EuiDataGridSignature['Blocks'], 'cell' | 'cellPopover' | 'controlCell'>;
}

/**
 * A `div[role=row]` positioned at its row offset (upstream's row manager
 * creates the same element imperatively), rendering the cells of the
 * columns in the body's rendered window.
 */
export default class EuiDataGridRow extends Component<EuiDataGridRowSignature> {
  /** Row index from the data, not affected by sorting/pagination. */
  get rowIndex(): number {
    return this.args.grid.getCorrectRowIndex(this.args.visibleRowIndex);
  }

  get classes(): string {
    const rowClasses = this.args.grid.gridStyles.rowClasses;
    const extra = rowClasses?.[this.rowIndex];
    return [
      'euiDataGridRow',
      this.args.visibleRowIndex % 2 !== 0 && 'euiDataGridRow--striped',
      this.rowTree.className, // ember-eui extension (row-tree): group row class
      extra
    ]
      .filter(Boolean)
      .join(' ');
  }

  // ember-eui extension (row-tree): treegrid ARIA attributes and group class
  get rowTree() {
    return rowTreeRowAttributes(this.args.grid, this.args.visibleRowIndex);
  }

  get style() {
    const { body, visibleRowIndex } = this.args;
    const top = body.headerOffset + body.rowTop(visibleRowIndex);
    return htmlSafe(
      `position:absolute;left:0;right:0;top:${top}px;height:${body.rowHeight(visibleRowIndex)}px`
    );
  }

  <template>
    <div
      role="row"
      class={{this.classes}}
      style={{this.style}}
      data-grid-row-index={{this.rowIndex}}
      data-grid-visible-row-index={{@visibleRowIndex}}
      {{! ember-eui extension (row-tree): treegrid ARIA }}
      aria-level={{this.rowTree.level}}
      aria-expanded={{this.rowTree.expanded}}
      aria-setsize={{this.rowTree.setSize}}
      aria-posinset={{this.rowTree.posInSet}}
    >
      {{#each @body.renderedColumns key="@identity" as |colIndex|}}
        <EuiDataGridCell
          @grid={{@grid}}
          @body={{@body}}
          @colIndex={{colIndex}}
          @visibleRowIndex={{@visibleRowIndex}}
          @hasCellPopoverBlock={{@hasCellPopoverBlock}}
        >
          <:cell as |cell|>{{yield cell to="cell"}}</:cell>
          <:cellPopover as |popover|>{{yield popover to="cellPopover"}}</:cellPopover>
          <:controlCell as |cell|>{{yield cell to="controlCell"}}</:controlCell>
        </EuiDataGridCell>
      {{/each}}
    </div>
  </template>
}
