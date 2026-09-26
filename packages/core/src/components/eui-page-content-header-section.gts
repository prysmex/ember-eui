import type { TemplateOnlyComponent } from '@ember/component/template-only';

/** One side of an EuiPageContentHeader. */
export interface EuiPageContentHeaderSectionSignature {
  Element: HTMLDivElement;
  Blocks: {
    /** E.g. an `EuiTitle`, or buttons. */
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
