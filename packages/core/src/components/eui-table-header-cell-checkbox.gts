import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';

import {
  CELL_RESET,
  StickyHeaderCellSync,
  stickyHeaderCopy,
  stickyHeaderOriginal,
  tableContext,
  widthStyle
} from '../-private/table.ts';
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
    /** Content after the cell's content (upstream `append`). */
    append: [];
  };
}

export default class EuiTableHeaderCellCheckbox extends Component<EuiTableHeaderCellCheckboxSignature> {
  stickySync = new StickyHeaderCellSync();

  get table() {
    return tableContext(this);
  }

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
      {{stickyHeaderOriginal this.stickySync (isPresent this.table.stickyHeaderRow)}}
    >
      <div class="euiTableCellContent">{{yield}}</div>
      {{yield to="append"~}}
      {{#if this.table.stickyHeaderRow}}
        {{! the copy in the table's sticky header }}
        {{#in-element this.table.stickyHeaderRow insertBefore=null}}<th
            class="euiTableHeaderCellCheckbox {{this.classes}}"
            scope={{if @scope @scope "col"}}
            style={{this.style}}
            ...attributes
            {{stickyHeaderCopy this.stickySync this.table this.style}}
          ><div class="euiTableCellContent">{{yield}}</div>{{yield to="append"}}</th>{{/in-element}}
      {{/if}}
    </th>
  </template>
}

function isPresent(value: unknown): boolean {
  return value != null;
}
