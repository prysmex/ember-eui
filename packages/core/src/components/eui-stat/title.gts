import { hash } from '@ember/helper';

import { element } from 'ember-element-helper';
import style from 'ember-style-modifier/modifiers/style';

import EuiTitle from '../eui-title.gts';

import type { EuiTitleSignature } from '../eui-title';
import type { TemplateOnlyComponent } from '@ember/component/template-only';

/** @private The title of an EuiStat. */
export interface EuiStatTitleSignature {
  Element: any;
  Args: {
    /** Size, any `EuiTitle` size. */
    titleSize?: EuiTitleSignature['Args']['size'];
    /** A CSS color, when it is not one of the named colors. */
    titleColor?: string;
    /** Tag of the title. Defaults to `'p'`. */
    titleElement?: string;
    /** Whether `@titleColor` is a named color (a class). */
    isColorClass?: boolean;
  };
  Blocks: {
    /** The text. */
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
