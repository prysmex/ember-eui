import type { TemplateOnlyComponent } from '@ember/component/template-only';

export interface EuiDescriptionListTitleSignature {
  Element: HTMLElement;
  Blocks: {
    default: [];
  };
}

const EuiDescriptonListTitle: TemplateOnlyComponent<EuiDescriptionListTitleSignature> =
  <template>
    <dt class="euiDescriptionList__title" ...attributes>
      {{yield}}
    </dt>
  </template>;

export default EuiDescriptonListTitle;
