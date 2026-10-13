import EuiCodeBlock from '../eui-code-block.gts';
import EuiText from '../eui-text.gts';

import type { TOC } from '@ember/component/template-only';
import type { ComponentLike } from '@glint/template';

/** Pretty-prints a JSON cell's text (upstream `JsonPopoverContent`). */
function formatJson(cellContentsElement: HTMLElement | null | undefined): string {
  const cellText = cellContentsElement?.innerText ?? '';
  try {
    return JSON.stringify(JSON.parse(cellText), null, 2);
  } catch {
    return cellText;
  }
}

const isJson = (schema: string | null | undefined): boolean => schema === 'json';

export interface EuiDataGridDefaultCellPopoverSignature {
  Args: {
    schema?: string | null;
    cellContentsElement?: HTMLElement | null;
    /** The cell actions footer to render after the content. */
    cellActions?: ComponentLike;
  };
  Blocks: {
    /** The cell content (upstream `children`). */
    default: [];
  };
}

/**
 * Upstream `DefaultCellPopover`: the cell content in `EuiText` (or the
 * cell's text pretty-printed in an `EuiCodeBlock` for the `json` schema),
 * followed by the cell actions. Passed to custom popover renderers as
 * `DefaultCellPopover` to fall back to the standard display.
 */
const EuiDataGridDefaultCellPopover: TOC<EuiDataGridDefaultCellPopoverSignature> = <template>
  {{#if (isJson @schema)}}
    <EuiCodeBlock
      @isCopyable={{true}}
      @transparentBackground={{true}}
      @paddingSize="none"
      @language="json"
    >{{formatJson @cellContentsElement}}</EuiCodeBlock>
  {{else}}
    <EuiText>{{yield}}</EuiText>
  {{/if}}
  {{#if @cellActions}}
    {{#let @cellActions as |CellActions|}}<CellActions />{{/let}}
  {{/if}}
</template>;

export default EuiDataGridDefaultCellPopover;
