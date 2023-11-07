import type { TemplateOnlyComponent } from '@ember/component/template-only';

export interface EuiDescriptionListDescriptionSignature {
  Element: HTMLElement;
  Blocks: {
    default: [];
  };
}

const EuiDescriptionListDescription: TemplateOnlyComponent<EuiDescriptionListDescriptionSignature> =
  <template>
    <dd class="euiDescriptionList__description" ...attributes>
      {{yield}}
    </dd>
  </template>;

export default EuiDescriptionListDescription;
