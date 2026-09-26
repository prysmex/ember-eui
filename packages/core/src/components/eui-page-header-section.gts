import type { TemplateOnlyComponent } from '@ember/component/template-only';

/** A section of an EuiPageHeader built by hand (inside its default block). */
export interface EuiPageHeaderSectionSignature {
  Element: HTMLDivElement;
  Blocks: {
    /** The section's content. */
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
