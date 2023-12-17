import type { TemplateOnlyComponent } from '@ember/component/template-only';

export interface EuiModalHeaderTitleSignature {
  Element: HTMLDivElement;
  Blocks: {
    default: [];
  };
}

const EuiModalHeaderTitle: TemplateOnlyComponent<EuiModalHeaderTitleSignature> =
  <template>
    <div class="euiModalHeader__title" ...attributes>
      {{yield}}
    </div>
  </template>;

export default EuiModalHeaderTitle;
