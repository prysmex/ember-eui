import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';

import { getEuiThemeContext } from '../../utils/emotion/consume.ts';
import { euiClass, useEuiBorealisStyles } from '../../utils/eui/styles.ts';
import { euiDataGridHeaderStyles } from '../../utils/eui/styles.generated.ts';
import EuiDataGridHeaderCell from './header-cell.gts';

import type EuiDataGrid from '../eui-data-grid.gts';
import type EuiDataGridBody from './body.gts';

export interface EuiDataGridHeaderRowSignature {
  Element: HTMLDivElement;
  Args: {
    grid: EuiDataGrid;
    body: EuiDataGridBody;
  };
  Blocks: {
    controlHeaderCell: [{ columnId: string }];
  };
}

/** The sticky header row: control and data column header cells. */
export default class EuiDataGridHeaderRow extends Component<EuiDataGridHeaderRowSignature> {
  @cached
  get classes(): string {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiDataGridHeaderStyles);
    const header = this.args.grid.gridStyles.header;
    return `euiDataGridHeader ${euiClass(context, styles.euiDataGridHeader, styles[header])}`;
  }

  get dataColumnOffset(): number {
    return this.args.grid.leadingControlColumns.length;
  }

  get trailingOffset(): number {
    return this.dataColumnOffset + this.args.grid.columns.length;
  }

  <template>
    <div role="row" class={{this.classes}} data-test-subj="dataGridHeader" ...attributes>
      {{#each @grid.leadingControlColumns key="id" as |controlColumn index|}}
        <EuiDataGridHeaderCell
          @grid={{@grid}}
          @body={{@body}}
          @index={{index}}
          @controlColumn={{controlColumn}}
        >
          <:controlHeaderCell as |cell|>{{yield cell to="controlHeaderCell"}}</:controlHeaderCell>
        </EuiDataGridHeaderCell>
      {{/each}}
      {{#each @grid.columns key="id" as |column index|}}
        <EuiDataGridHeaderCell
          @grid={{@grid}}
          @body={{@body}}
          @index={{add index this.dataColumnOffset}}
          @column={{column}}
        />
      {{/each}}
      {{#each @grid.trailingControlColumns key="id" as |controlColumn index|}}
        <EuiDataGridHeaderCell
          @grid={{@grid}}
          @body={{@body}}
          @index={{add index this.trailingOffset}}
          @controlColumn={{controlColumn}}
        >
          <:controlHeaderCell as |cell|>{{yield cell to="controlHeaderCell"}}</:controlHeaderCell>
        </EuiDataGridHeaderCell>
      {{/each}}
    </div>
  </template>
}

function add(a: number, b: number): number {
  return a + b;
}
