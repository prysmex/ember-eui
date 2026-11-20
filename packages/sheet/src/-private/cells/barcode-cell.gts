/**
 * The barcode cell (V03 10.3.2): the text in the monospace font after a
 * small barcode mark (drawn by CSS, no icon), highlighted with `@highlight`.
 */
import EuiHighlight from '@ember-eui/core/components/eui-highlight';

import type { TOC } from '@ember/component/template-only';
import type { SheetCellSignature } from '../../types.ts';

const BarcodeCell: TOC<SheetCellSignature<any, any>> = <template>
  {{#if @text}}
    <span class="euiSheet__barcode" data-test-subj="euiSheetBarcode"><span
        class="euiSheet__barcodeMark"
        aria-hidden="true"
      ></span><span class="euiSheet__barcodeText">{{#if
          @highlight
        }}<EuiHighlight
            @text={{@text}}
            @search={{@highlight}}
            @highlightAll={{true}}
          />{{else}}{{@text}}{{/if}}</span></span>
  {{/if}}
</template>;

export default BarcodeCell;
