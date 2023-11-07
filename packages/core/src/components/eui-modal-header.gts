import type { TemplateOnlyComponent } from '@ember/component/template-only';

export interface EuiModalHeaderSignature {
  Element: HTMLDivElement;
  Blocks: {
    default: [];
  };
}
const EuiModalHeader: TemplateOnlyComponent<EuiModalHeaderSignature> =
  <template>
    <div class="euiModalHeader" ...attributes>
      {{yield}}
    </div>
  </template>;

export default EuiModalHeader;
