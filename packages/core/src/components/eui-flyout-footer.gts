import type { TemplateOnlyComponent } from '@ember/component/template-only';

/** The bottom bar of an EuiFlyout, usually with its buttons. */
export interface EuiFlyoutFooterSignature {
  Element: HTMLDivElement;
  Blocks: {
    /** Usually an `EuiFlexGroup` with close/cancel and primary buttons. */
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
