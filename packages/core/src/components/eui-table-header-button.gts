import didInsert from '@ember/render-modifiers/modifiers/did-insert';

import EuiIcon from './eui-icon.gts';
import EuiInnerText from './eui-inner-text.gts';

import type { EuiIconSignature } from './eui-icon';
import type { TemplateOnlyComponent } from '@ember/component/template-only';

/** A button in a header cell, e.g. a column that opens a menu. */
export interface EuiTableHeaderButtonSignature {
  Element: HTMLButtonElement;
  Args: {
    /** Icon after the text, any `EuiIcon` type. */
    iconType?: EuiIconSignature['Args']['type'];
  };
  Blocks: {
    /** The text. */
    default: [];
  };
}

const EuiTableHeaderButton: TemplateOnlyComponent<EuiTableHeaderButtonSignature> = <template>
  <button type="button" class="euiTableHeaderButton" ...attributes>
    <EuiInnerText as |ref innerText|>
      <span title={{innerText}} {{didInsert ref}}>{{yield}}</span>
    </EuiInnerText>
    {{#if @iconType}}
      <EuiIcon
        class="euiTableHeaderButton__icon"
        @type={{@iconType}}
        @size="m"
        aria-hidden="true"
      />
    {{/if}}
  </button>
</template>;

export default EuiTableHeaderButton;
