import type { TemplateOnlyComponent } from '@ember/component/template-only';

export interface EuiModalFooterSignature {
  Element: HTMLDivElement;
  Blocks: {
    default: [];
  };
}

const EuiModalFooter: TemplateOnlyComponent<EuiModalFooterSignature> =
  <template>
    <div class="euiModalFooter" ...attributes>
      {{yield}}
    </div>
  </template>;

export default EuiModalFooter;
