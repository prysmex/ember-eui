import { hash } from '@ember/helper';

import { element } from 'ember-element-helper';
import style from 'ember-style-modifier/modifiers/style';

import EuiTitle from '../eui-title.gts';

import type { EuiTitleSignature } from '../eui-title';
import type { TemplateOnlyComponent } from '@ember/component/template-only';

export interface EuiStatTitleSignature {
  Element: any;
  Args: {
    titleSize?: EuiTitleSignature['Args']['size'];
    titleColor?: string;
    titleElement?: string;
    isColorClass?: boolean;
  };
  Blocks: {
    default: [];
  };
}

const EuiStatTitle: TemplateOnlyComponent<EuiStatTitleSignature> = <template>
  {{#if @titleElement}}
    {{#let (element @titleElement) as |TitleElement|}}
      <EuiTitle @size={{@titleSize}} ...attributes>
        <TitleElement
          aria-hidden="true"
          {{style (if @isColorClass (hash color=@titleColor))}}
        >
          {{yield}}
        </TitleElement>
      </EuiTitle>
    {{/let}}
  {{else}}
    <EuiTitle @size={{@titleSize}} ...attributes>
      <p
        aria-hidden="true"
        {{style (if @isColorClass (hash color=@titleColor))}}
      >
        {{yield}}
      </p>
    </EuiTitle>
  {{/if}}
</template>;

export default EuiStatTitle;
