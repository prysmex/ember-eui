import { and, not, or } from 'ember-truth-helpers';

import argOrDefault from '../helpers/arg-or-default.ts';
import classNames from '../helpers/class-names.ts';
import getEuiConfig from '../helpers/get-eui-config.ts';
import EuiIcon from './eui-icon.gts';

import type {
  colorMapping,
  displayMapping,
  sizeMapping
} from '../utils/css-mappings/eui-button-icon.ts';
import type { EuiIconSignature } from './eui-icon';
import type { TemplateOnlyComponent } from '@ember/component/template-only';

export interface EuiButtonIconSignature {
  Element: HTMLButtonElement | HTMLAnchorElement;
  Args: {
    iconType?: EuiIconSignature['Args']['type'];
    iconSize?: EuiIconSignature['Args']['size'];
    iconClasses?: string;
    href?: string;
    target?: string;
    isDisabled?: boolean;
    isSelected?: boolean;
    display?: keyof typeof displayMapping;
    color?: keyof typeof colorMapping;
    size?: keyof typeof sizeMapping;
    type?: 'button' | 'submit' | 'reset';
    useSvg?: boolean;
    useComponent?: boolean;
    disabled?: boolean;
  };
}

const EuiButtonIcon: TemplateOnlyComponent<EuiButtonIconSignature> = <template>
  {{#let (getEuiConfig "euiButtonIcon.size") as |buttonSizeConfig|}}
    {{#if (and @href (not @isDisabled))}}
      <a
        class={{classNames
          (if @isDisabled "euiButtonIcon-isDisabled")
          componentName="EuiButtonIcon"
          display=(argOrDefault @display "empty")
          color=(argOrDefault @color "primary")
          size=(argOrDefault @size (if buttonSizeConfig buttonSizeConfig "xs"))
        }}
        href={{@href}}
        target={{@target}}
        ...attributes
      >
        {{#if @iconType}}
          <EuiIcon
            @iconClasses="euiButtonIcon__icon {{@iconClasses}}"
            @type={{@iconType}}
            @size={{argOrDefault @iconSize "m"}}
            @useSvg={{@useSvg}}
            @useComponent={{@useComponent}}
            @color="inherit"
            aria-hidden="true"
          />
        {{/if}}
      </a>
    {{else}}
      <button
        class={{classNames
          (if @isDisabled "euiButtonIcon-isDisabled")
          componentName="EuiButtonIcon"
          display=(argOrDefault @display "empty")
          color=(argOrDefault @color "primary")
          size=(argOrDefault @size (if buttonSizeConfig buttonSizeConfig "xs"))
        }}
        disabled={{or @isDisabled @disabled}}
        aria-pressed={{if @isSelected "true" "false"}}
        type={{if @type @type "button"}}
        ...attributes
      >
        {{#if @iconType}}
          <EuiIcon
            @iconClasses="euiButtonIcon__icon {{@iconClasses}}"
            @type={{@iconType}}
            @size={{argOrDefault @iconSize "m"}}
            @useSvg={{@useSvg}}
            @color="inherit"
            @useComponent={{@useComponent}}
            aria-hidden="true"
          />
        {{/if}}
      </button>
    {{/if}}
  {{/let}}
</template>;

export default EuiButtonIcon;
