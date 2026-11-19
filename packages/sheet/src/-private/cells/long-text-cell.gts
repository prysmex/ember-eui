/** The long text cell: the text with its line breaks, clamped to the row height. */
import EuiHighlight from '@ember-eui/core/components/eui-highlight';

import type { TOC } from '@ember/component/template-only';
import type { SheetCellSignature } from '../../types.ts';

const LongTextCell: TOC<SheetCellSignature<any, any>> = <template>
  <span class="euiSheet__longText" data-test-subj="euiSheetLongText">{{#if
      @highlight
    }}<EuiHighlight
        @text={{@text}}
        @search={{@highlight}}
        @highlightAll={{true}}
      />{{else}}{{@text}}{{/if}}</span>
</template>;

export default LongTextCell;
