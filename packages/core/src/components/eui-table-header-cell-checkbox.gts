import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';

import { CELL_RESET, widthStyle } from '../-private/table.ts';
import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import { euiTableCellCheckboxStyles } from '../utils/eui/styles.generated.ts';

/** A header cell holding a checkbox, e.g. "select all rows". */
export interface EuiTableHeaderCellCheckboxSignature {
  Element: HTMLTableCellElement;
  Args: {
    /** Width, e.g. `32` (px). Defaults to the theme's checkbox column width. */
    width?: number | string;
    /** Min width, e.g. `32` (px). */
    minWidth?: number | string;
    /** Max width, e.g. `32` (px). */
    maxWidth?: number | string;
    /** `scope` of the `<th>`. Defaults to `'col'`. */
    scope?: string;
  };
  Blocks: {
    /** The checkbox. */
    default: [];
  };
}

export default class EuiTableHeaderCellCheckbox extends Component<EuiTableHeaderCellCheckboxSignature> {
  @cached
  get classes(): string {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiTableCellCheckboxStyles);
    return euiClass(context, CELL_RESET, styles.euiTableHeaderCellCheckbox);
  }

  @cached
  get style() {
    return widthStyle(this.args.width, this.args.minWidth, this.args.maxWidth);
  }

  <template>
    <th
      class="euiTableHeaderCellCheckbox {{this.classes}}"
      scope={{if @scope @scope "col"}}
      style={{this.style}}
      ...attributes
    >
      <div class="euiTableCellContent">{{yield}}</div>
    </th>
  </template>
}
