import type { TemplateOnlyComponent } from '@ember/component/template-only';

/** The top of an EuiModal. */
export interface EuiModalHeaderSignature {
  Element: HTMLDivElement;
  Blocks: {
    /** An `EuiModalHeaderTitle`. */
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
