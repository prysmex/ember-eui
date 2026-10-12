import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';

import { getEuiThemeContext } from '../../utils/emotion/consume.ts';
import { euiClass, useEuiBorealisStyles } from '../../utils/eui/styles.ts';
import { euiDataGridToolbarStyles } from '../../utils/eui/styles.generated.ts';

import type EuiDataGrid from '../eui-data-grid.gts';

export interface EuiDataGridToolbarSignature {
  Args: { grid: EuiDataGrid };
  Blocks: { leftControlsPrepend: []; leftControlsAppend: []; rightControls: [] };
}

export default class EuiDataGridToolbar extends Component<EuiDataGridToolbarSignature> {
  @cached
  get classes() {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiDataGridToolbarStyles);
    return {
      controls: `euiDataGrid__controls ${euiClass(context, styles.euiDataGrid__controls)}`,
      left: `euiDataGrid__leftControls ${euiClass(context, styles.euiDataGrid__leftControls)}`,
      right: `euiDataGrid__rightControls ${euiClass(context, styles.euiDataGrid__rightControls)}`
    };
  }

  <template>
    <div class={{this.classes.controls}} data-test-subj="dataGridControls">
      <div class={{this.classes.left}}>
        {{yield to="leftControlsPrepend"}}
        {{yield to="leftControlsAppend"}}
      </div>
      <div class={{this.classes.right}}>
        {{yield to="rightControls"}}
      </div>
    </div>
  </template>
}
