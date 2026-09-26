import type { TemplateOnlyComponent } from '@ember/component/template-only';

/** The scrolling content of an EuiModal. */
export interface EuiModalBodySignature {
  Element: HTMLDivElement;
  Blocks: {
    /** The content. */
    default: [];
  };
}

const EuiModalBody: TemplateOnlyComponent<EuiModalBodySignature> = <template>
  <div class="euiModalBody" ...attributes>
    <div class="euiModalBody__overflow">
      {{yield}}
    </div>
  </div>
</template>;

export default EuiModalBody;
