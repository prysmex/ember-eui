import { widthStyle } from '../-private/table.ts';

import type { TemplateOnlyComponent } from '@ember/component/template-only';

/** A header cell holding a checkbox, e.g. "select all rows". */
export interface EuiTableHeaderCellCheckboxSignature {
  Element: HTMLTableCellElement;
  Args: {
    /** Width, e.g. `32` (px). */
    width?: number | string;
    /** `scope` of the `<th>`. Defaults to `'col'`. */
    scope?: string;
  };
  Blocks: {
    /** The checkbox. */
    default: [];
  };
}

const EuiTableHeaderCellCheckbox: TemplateOnlyComponent<EuiTableHeaderCellCheckboxSignature> =
  <template>
    <th
      class="euiTableHeaderCellCheckbox"
      scope={{if @scope @scope "col"}}
      style={{widthStyle @width}}
      ...attributes
    >
      <div class="euiTableCellContent">{{yield}}</div>
    </th>
  </template>;

export default EuiTableHeaderCellCheckbox;
