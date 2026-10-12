import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';

import { getEuiThemeContext } from '../../utils/emotion/consume.ts';
import { euiClass, useEuiBorealisStyles } from '../../utils/eui/styles.ts';
import { euiDataGridFooterStyles } from '../../utils/eui/styles.generated.ts';
import EuiDataGridCell from './cell.gts';

import type EuiDataGrid from '../eui-data-grid.gts';
import type { EuiDataGridSignature } from '../eui-data-grid.gts';
import type EuiDataGridBody from './body.gts';

export interface EuiDataGridFooterRowSignature {
  Element: HTMLDivElement;
  Args: {
    grid: EuiDataGrid;
    body: EuiDataGridBody;
    hasCellPopoverBlock?: boolean;
  };
  Blocks: Pick<EuiDataGridSignature['Blocks'], 'footerCell' | 'cellPopover' | 'controlFooterCell'>;
}

/** The (sticky) footer row rendered after the virtualized rows. */
export default class EuiDataGridFooterRow extends Component<EuiDataGridFooterRowSignature> {
  /** The footer is the row after the page's last visible row. */
  get rowIndex(): number {
    return this.args.grid.visibleRows.visibleRowCount;
  }

  @cached
  get classes(): string {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiDataGridFooterStyles);
    const { stickyFooter, footer } = this.args.grid.gridStyles;
    return `euiDataGridFooter ${euiClass(
      context,
      styles.euiDataGridFooter,
      stickyFooter && styles.sticky,
      footer === 'striped'
        ? this.rowIndex % 2 !== 0 && styles.striped
        : styles[footer as 'shade' | 'overline']
    )}`;
  }

  get columnIndexes(): number[] {
    return Array.from({ length: this.args.grid.visibleColCount }, (_, i) => i);
  }

  <template>
    <div
      role="row"
      class={{this.classes}}
      data-test-subj="dataGridRow dataGridFooterRow"
      ...attributes
    >
      {{#each this.columnIndexes key="@identity" as |colIndex|}}
        <EuiDataGridCell
          @grid={{@grid}}
          @body={{@body}}
          @colIndex={{colIndex}}
          @visibleRowIndex={{this.rowIndex}}
          @isFooter={{true}}
          @hasCellPopoverBlock={{@hasCellPopoverBlock}}
        >
          <:footerCell as |cell|>{{yield cell to="footerCell"}}</:footerCell>
          <:cellPopover as |popover|>{{yield popover to="cellPopover"}}</:cellPopover>
          <:controlFooterCell as |cell|>{{yield cell to="controlFooterCell"}}</:controlFooterCell>
        </EuiDataGridCell>
      {{/each}}
    </div>
  </template>
}
