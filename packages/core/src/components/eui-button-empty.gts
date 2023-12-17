import { and, eq,not, or } from 'ember-truth-helpers';

import argOrDefault from '../helpers/arg-or-default';
import classNames from '../helpers/class-names';
import EuiButtonContent from './eui-button-content.gts';

import type {
  colorMapping,
  flushMapping,
  sizeMapping
} from '../utils/css-mappings/eui-button-empty';
import type { EuiButtonContentSignature } from './eui-button-content';
import type { TemplateOnlyComponent } from '@ember/component/template-only';

export interface EuiButtonEmptySignature {
  Element: HTMLAnchorElement | HTMLButtonElement;
  Args: {
    isLoading?: boolean;
    size?: keyof typeof sizeMapping;
    iconSize?: EuiButtonContentSignature['Args']['iconSize'];
    color?: keyof typeof colorMapping;
    iconType?: string;
    iconSide?: EuiButtonContentSignature['Args']['iconSide'];
    iconClasses?: string;
    textClasses?: string;
    contentClasses?: string;
    flush?: keyof typeof flushMapping;
    href?: string;
    target?: string;
    isDisabled?: boolean;
    useSvg?: boolean;
    useComponent?: boolean;
    type?: string;
    isSelected?: boolean;
    disabled?: boolean;
  };
  Blocks: {
    default: [];
  };
}

const EuiButtonEmpty: TemplateOnlyComponent<EuiButtonEmptySignature> =
  <template>
    {{#let
      (argOrDefault @size "m") (argOrDefault @iconSize "m")
      as |size iconSize|
    }}
      {{#if (and @href (not (or @isLoading @isDisabled)))}}
        <a
          class={{classNames
            (if (or @isLoading @isDisabled) "euiButtonEmpty-isDisabled")
            componentName="EuiButtonEmpty"
            color=(argOrDefault @color "primary")
            size=size
            flush=@flush
          }}
          href={{@href}}
          target={{@target}}
          ...attributes
        >
          <EuiButtonContent
            class="euiButtonEmpty__content {{@contentClasses}}"
            @isLoading={{@isLoading}}
            @iconType={{@iconType}}
            @iconSide={{@iconSide}}
            @iconSize={{if (eq size "xs") "s" iconSize}}
            @iconClasses={{@iconClasses}}
            @useSvg={{@useSvg}}
            @useComponent={{@useComponent}}
            @textClasses={{classNames "euiButtonEmpty__text" @textClasses}}
          >
            {{yield}}
          </EuiButtonContent>
        </a>
      {{else}}
        <button
          class={{classNames
            (if (or @isLoading @isDisabled) "euiButtonEmpty-isDisabled")
            componentName="EuiButtonEmpty"
            color=(argOrDefault @color "primary")
            size=size
            flush=@flush
          }}
          disabled={{or @isLoading @isDisabled @disabled}}
          type={{if @type @type "button"}}
          aria-pressed={{@isSelected}}
          ...attributes
        >
          <EuiButtonContent
            class="euiButtonEmpty__content {{@contentClasses}}"
            @isLoading={{@isLoading}}
            @iconType={{@iconType}}
            @iconSide={{@iconSide}}
            @iconSize={{if (eq size "xs") "s" iconSize}}
            @iconClasses={{@iconClasses}}
            @useSvg={{@useSvg}}
            @useComponent={{@useComponent}}
            @textClasses={{classNames "euiButtonEmpty__text" @textClasses}}
          >
            {{yield}}
          </EuiButtonContent>
        </button>
      {{/if}}
    {{/let}}
  </template>;

export default EuiButtonEmpty;
