import type { TOC } from '@ember/component/template-only';

interface EuiButtonGroupItemSignature {
  Args: { wrap: boolean | undefined };
  Blocks: { default: [] };
}

/**
 * Upstream's segmented and selection `EuiButtonGroup` wraps each child in a
 * `.euiButtonGroup__item` element for its inset styles. A block cannot wrap
 * its children, so the buttons a group yields render the wrapper themselves.
 */
const EuiButtonGroupItem: TOC<EuiButtonGroupItemSignature> = <template>
  {{#if @wrap}}
    <div class="euiButtonGroup__item">{{yield}}</div>
  {{else}}
    {{yield}}
  {{/if}}
</template>;

export default EuiButtonGroupItem;
