import type { TemplateOnlyComponent } from '@ember/component/template-only';

export interface EuiPageContentHeaderSectionSignature {
  Element: HTMLDivElement;
  Blocks: {
    default: [];
  };
}

const EuiPageContentHeaderSection: TemplateOnlyComponent<EuiPageContentHeaderSectionSignature> =
  <template>
    <div class="euiPageContentHeaderSection" ...attributes>
      {{yield}}
    </div>
  </template>;

export default EuiPageContentHeaderSection;
