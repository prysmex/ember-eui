import type { TemplateOnlyComponent } from '@ember/component/template-only';

export interface EuiFlyoutFooterSignature {
  Element: HTMLDivElement;
  Blocks: {
    default: [];
  };
}

const EuiFlyoutFooter: TemplateOnlyComponent<EuiFlyoutFooterSignature> =
  <template>
    <div class="euiFlyoutFooter" ...attributes>
      {{yield}}
    </div>
  </template>;

export default EuiFlyoutFooter;
