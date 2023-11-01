import type { TemplateOnlyComponent } from '@ember/component/template-only';

export interface EuiPageHeaderSectionSignature {
  Element: HTMLDivElement;
  Blocks: {
    default: [];
  };
}

const EuiPageHederSection: TemplateOnlyComponent<EuiPageHeaderSectionSignature> =
  <template>
    <div class="euiPageHeaderSection" ...attributes>
      {{yield}}
    </div>
  </template>;

export default EuiPageHederSection;
