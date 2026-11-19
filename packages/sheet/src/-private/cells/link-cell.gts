/**
 * The url, email and phone cell: the text, link-styled when the value has a
 * link (`@link`). A `<span role="link">`, never `<a href>` (an anchor is
 * tabbable, and the grid would add a focus trap, P9). The sheet opens the
 * link on a click on the span.
 */
import EuiHighlight from '@ember-eui/core/components/eui-highlight';

import type { TOC } from '@ember/component/template-only';
import type { SheetCellSignature } from '../../types.ts';

const LinkCell: TOC<SheetCellSignature<any, any>> = <template>
  {{#if @link}}
    <span
      class="euiSheet__link"
      role="link"
      data-eui-sheet-link
      data-test-subj="euiSheetLink"
    >{{#if @highlight}}<EuiHighlight
          @text={{@text}}
          @search={{@highlight}}
          @highlightAll={{true}}
        />{{else}}{{@text}}{{/if}}</span>
  {{else if @highlight}}
    <EuiHighlight
      @text={{@text}}
      @search={{@highlight}}
      @highlightAll={{true}}
    />
  {{else}}
    {{@text}}
  {{/if}}
</template>;

export default LinkCell;
