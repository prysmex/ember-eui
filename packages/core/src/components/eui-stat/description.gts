import EuiText from '../eui-text.gts';

import type { TemplateOnlyComponent } from '@ember/component/template-only';

/** @private The description of an EuiStat. */
export interface EuiStatDescriptionSignature {
  Args: {
    /**
     * The element to use for the description. Defaults to `p`.
     */
    descriptionElement?: keyof HTMLElementTagNameMap;
  };
  Blocks: {
    /** The text. */
    default: [];
  };
}

/** Upstream: `<EuiText size="s" className="euiStat__description">` around the element. */
const EuiStatDescription: TemplateOnlyComponent<EuiStatDescriptionSignature> =
  <template>
    {{#let
      (element (if @descriptionElement @descriptionElement "p"))
      as |DescriptionElement|
    }}
      <EuiText class="euiStat__description" @size="s">
        <DescriptionElement>{{yield}}</DescriptionElement>
      </EuiText>
    {{/let}}
  </template>;

export default EuiStatDescription;
