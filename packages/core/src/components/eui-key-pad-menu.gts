import EuiFormLabel from './eui-form-label.gts';

import type { TemplateOnlyComponent } from '@ember/component/template-only';

const KeyComponent: TemplateOnlyComponent<{
  Blocks: {
    default: [];
  };
}> = <template><li>{{yield}}</li></template>;

export interface EuiKeyPadMenuSignature {
  Element: HTMLUListElement | HTMLFieldSetElement;
  Args: {
    checkable?: {
      legend?: string;
      ariaLegend?: string;
    };
    iconType?: string;
  };
  Blocks: {
    default: [typeof KeyComponent?];
  };
}

const EuiKeyPadMenu: TemplateOnlyComponent<EuiKeyPadMenuSignature> = <template>
  {{#if @checkable.legend}}
    <fieldset
      class="euiKeyPadMenu"
      aria-label={{@checkable.ariaLegend}}
      ...attributes
    >
      <EuiFormLabel @type="legend">
        {{@checkable.legend}}
      </EuiFormLabel>
      {{yield}}
    </fieldset>
  {{else}}
    <ul class="euiKeyPadMenu" ...attributes>
      {{yield KeyComponent}}
    </ul>
  {{/if}}
</template>;

export default EuiKeyPadMenu;
