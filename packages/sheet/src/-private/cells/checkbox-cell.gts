/**
 * The checkbox cell: a box drawn in CSS. Not focusable (P9): Space on the
 * cell (the type's navKey) or a click anywhere in the cell (the type's
 * onCellClick, handled by the sheet) toggles it.
 */
import type { TOC } from '@ember/component/template-only';

import type { SheetCellSignature } from '../../types.ts';

const CheckboxCell: TOC<SheetCellSignature<any, any>> = <template>
  <span
    class="euiSheet__checkbox {{if @value 'euiSheet__checkbox--checked'}}"
    role="img"
    aria-label={{if
      @messages
      (if @value (@messages.cellChecked) (@messages.cellUnchecked))
      @text
    }}
    data-test-subj="euiSheetCheckbox"
  ></span>
</template>;

export default CheckboxCell;
