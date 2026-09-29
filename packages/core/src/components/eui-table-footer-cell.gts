import { alignClasses, widthStyle } from '../-private/table.ts';

import type { TableAlignment } from '../-private/table.ts';
import type { TemplateOnlyComponent } from '@ember/component/template-only';

/** A cell of an `EuiTableFooter`, e.g. a column's total. */
export interface EuiTableFooterCellSignature {
  Element: HTMLTableCellElement;
  Args: {
    /** `'left'`, `'right'` (numbers) or `'center'`. Defaults to `'left'`. */
    align?: TableAlignment;
    /** Width, e.g. `100` (px) or `'20%'`. */
    width?: number | string;
  };
  Blocks: {
    /** The content. */
    default: [];
  };
}

const EuiTableFooterCell: TemplateOnlyComponent<EuiTableFooterCellSignature> = <template>
  <td class="euiTableFooterCell" style={{widthStyle @width}} ...attributes>
    <div class="euiTableCellContent {{alignClasses @align}}">
      <span class="euiTableCellContent__text">{{yield}}</span>
    </div>
  </td>
</template>;

export default EuiTableFooterCell;
