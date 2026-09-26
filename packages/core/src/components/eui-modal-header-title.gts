import type { TemplateOnlyComponent } from '@ember/component/template-only';

/** The title of an EuiModal. */
export interface EuiModalHeaderTitleSignature {
  Element: HTMLDivElement;
  Blocks: {
    /** The title text (wrap it in a heading, e.g. `<h1>`). */
    default: [];
  };
}

const EuiModalHeaderTitle: TemplateOnlyComponent<EuiModalHeaderTitleSignature> =
  <template>
    <div class="euiModalHeader__title" ...attributes>
      {{yield}}
    </div>
  </template>;

export default EuiModalHeaderTitle;
