import type { TemplateOnlyComponent } from '@ember/component/template-only';

/** A term (`<dt>`) in an EuiDescriptionList. */
export interface EuiDescriptionListTitleSignature {
  Element: HTMLElement;
  Blocks: {
    /** The text. */
    default: [];
  };
}

const EuiDescriptonListTitle: TemplateOnlyComponent<EuiDescriptionListTitleSignature> =
  <template>
    <dt class="euiDescriptionList__title" ...attributes>
      {{yield}}
    </dt>
  </template>;

export default EuiDescriptonListTitle;
