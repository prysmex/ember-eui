import { and, not, or } from 'ember-truth-helpers';

import argOrDefault from '../helpers/arg-or-default';
import classNames from '../helpers/class-names';
import EuiIcon from './eui-icon';

import type { IconSize } from './eui-icon';
import type { TemplateOnlyComponent } from '@ember/component/template-only';

export interface Signature {
  Element: HTMLButtonElement | HTMLAnchorElement;
  Args: {
    iconType?: string;
    iconSize?: IconSize;
    iconClasses?: string;
    href?: string;
    target?: string;
    isDisabled?: boolean;
    isSelected?: boolean;
    display?: 'fill' | 'empty';
    color?: 'primary' | 'danger' | 'text' | 'ghost' | 'icon';
    size?: 'xs' | 's' | 'm' | 'l';
    type?: 'button' | 'submit' | 'reset';
    useSvg?: boolean;
    useComponent?: boolean;
    disabled?: boolean;
  };
  Blocks: {
    default?: [];
  };
}

const EuiButtonIcon: TemplateOnlyComponent<Signature> = <template>
  {{#if (and @href (not @isDisabled))}}
    <a
      class={{classNames
        (if @isDisabled "euiButtonIcon-isDisabled")
        componentName="EuiButtonIcon"
        display=(argOrDefault @display "empty")
        color=(argOrDefault @color "primary")
        size=(argOrDefault
          @size "xs" configKey="@ember-eui/core.euiButtonIcon.size"
        )
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
        size=(argOrDefault
          @size "xs" configKey="@ember-eui/core.euiButtonIcon.size"
        )
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
</template>;

export default EuiButtonIcon;
