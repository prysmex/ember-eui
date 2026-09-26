import type { TemplateOnlyComponent } from '@ember/component/template-only';

/** The description (`<dd>`) of the term before it, in an EuiDescriptionList. */
export interface EuiDescriptionListDescriptionSignature {
  Element: HTMLElement;
  Blocks: {
    /** The text. */
    default: [];
  };
}

const EuiDescriptionListDescription: TemplateOnlyComponent<EuiDescriptionListDescriptionSignature> =
  <template>
    <dd class="euiDescriptionList__description" ...attributes>
      {{yield}}
    </dd>
  </template>;

export default EuiDescriptionListDescription;
