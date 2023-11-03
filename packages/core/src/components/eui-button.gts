import { concat } from '@ember/helper';

import classify from 'ember-cli-string-helpers/helpers/classify';
import { element } from 'ember-element-helper';
import { and, eq, not, or } from 'ember-truth-helpers';

import argOrDefault from '../helpers/arg-or-default';
import classNames from '../helpers/class-names';
import EuiButtonContent from './eui-button-content.gts';
import type { EuiButtonContentSignature } from './eui-button-content.gts';

import type { TemplateOnlyComponent } from '@ember/component/template-only';

export interface EuiButtonSignature {
  Element: Element;
  Args: {
    baseClassName?: string;
    color?: string;
    contentClasses?: string;
    disabled?: boolean;
    fill?: boolean;
    fullWidth?: boolean;
    href?: string;
    iconClasses?: string;
    iconSide?: EuiButtonContentSignature['Args']['iconSide'];
    iconSize?: EuiButtonContentSignature['Args']['iconSize'];
    iconType?: EuiButtonContentSignature['Args']['iconType'];
    isLoading?: boolean;
    isSelected?: boolean;
    size?: string;
    target?: string;
    textClasses?: string;
    type?: string;
    useComponent?: boolean;
    useSvg?: boolean;
    element?: string;
    isDisabled?: boolean;
  };
  Blocks: {
    default: [];
  };
}

const EuiButton: TemplateOnlyComponent<EuiButtonSignature> = <template>
  {{#let
    (argOrDefault @baseClassName "euiButton")
    (if
      @element
      @element
      (if (and @href (not (or @isLoading @isDisabled))) "a" "button")
    )
    as |baseClassName theElement|
  }}
    {{#let (element theElement) as |Element|}}
      <Element
        class={{classNames
          (if @fill (concat baseClassName "--fill"))
          (if @fullWidth (concat baseClassName "--fullWidth"))
          (if
            (or @isLoading @isDisabled @disabled)
            (concat baseClassName "-isDisabled")
          )
          componentName=(classify baseClassName)
          color=(argOrDefault @color "primary")
          size=@size
        }}
        disabled={{or @isLoading @isDisabled @disabled}}
        href={{@href}}
        target={{@target}}
        aria-pressed={{if @isSelected "true" null}}
        type={{if (eq theElement "button") (argOrDefault @type "button") null}}
        ...attributes
      >
        <EuiButtonContent
          class={{classNames "euiButton__content" @contentClasses}}
          @isLoading={{@isLoading}}
          @iconType={{@iconType}}
          @iconSize={{@iconSize}}
          @iconSide={{@iconSide}}
          @iconClasses={{@iconClasses}}
          @useSvg={{@useSvg}}
          @useComponent={{@useComponent}}
          @textClasses={{classNames "euiButton__text" @textClasses}}
        >
          {{yield}}
        </EuiButtonContent>
      </Element>
    {{/let}}
  {{/let}}
</template>;

export default EuiButton;
