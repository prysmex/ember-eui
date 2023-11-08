import { hash } from '@ember/helper';
import { element } from 'ember-element-helper';
import EuiText from '../eui-text.gts';

import type { TemplateOnlyComponent } from '@ember/component/template-only';

export interface EuiStatDescriptionSignature {
  Args: {
    /**
     * The element to use for the description. Defaults to `p`.
     */
    descriptionElement?: keyof HTMLElementTagNameMap;
  };
  Blocks: {
    default: [];
  };
}

const EuiStatDescription: TemplateOnlyComponent<EuiStatDescriptionSignature> =
  <template>
    {{#if @descriptionElement}}
      {{#let (element @descriptionElement) as |DescriptionElement|}}
        <EuiText class="euiStat__description" @size="s">
          <DescriptionElement aria-hidden="true">
            {{yield}}
          </DescriptionElement>
        </EuiText>
      {{/let}}

    {{else}}
      <EuiText class="euiStat__description" @size="s">
        <p aria-hidden="true">
          {{yield}}
        </p>
      </EuiText>
    {{/if}}
  </template>;

export default EuiStatDescription;
