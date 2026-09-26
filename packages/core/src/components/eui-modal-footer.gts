import type { TemplateOnlyComponent } from '@ember/component/template-only';

/** The bottom of an EuiModal, with its buttons (right aligned). */
export interface EuiModalFooterSignature {
  Element: HTMLDivElement;
  Blocks: {
    /** The buttons, e.g. an `EuiButtonEmpty` to cancel and an `EuiButton @fill={{true}}`. */
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
