import { eq, notEq, or, and } from 'ember-truth-helpers';
import EuiIcon from './eui-icon';
import classNames from '../helpers/class-names';
import argOrDefault from '../helpers/arg-or-default';
import screenReaderOnly from '../modifiers/screen-reader-only';

import type { TemplateOnlyComponent } from '@ember/component/template-only';

export interface EuiLinkSignature {
  Element: HTMLAnchorElement | HTMLButtonElement;
  Args: {
    color?: string;
    disabled?: boolean;
    external?: boolean;
    href?: string;
    target?: string;
    type?: string;
  };
  Blocks: {
    default: [];
  };
}

const EuiLink: TemplateOnlyComponent<EuiLinkSignature> = <template>
  {{#let (argOrDefault @color "primary") as |color|}}
    {{#if @href}}
      <a
        href={{@href}}
        class={{classNames
          (if @disabled "euiLink--disabled")
          componentName="EuiLink"
          color=(unless @disabled color)
        }}
        target={{@target}}
        disabled={{@disabled}}
        ...attributes
      >

        {{yield}}
        {{#if
          (or
            (and (eq @target "_blank") (notEq @external false))
            (eq @external true)
          )
        }}
          <EuiIcon
            @type="popout"
            aria-label="External link"
            @size="s"
            class="euiLink__externalIcon"
          />
        {{/if}}
        {{#if (eq @target "_blank")}}
          <span {{screenReaderOnly}}>
            (opens in a new tab or window)
          </span>
        {{/if}}
      </a>
    {{else}}
      <button
        type={{argOrDefault @type "button"}}
        class={{classNames
          (if @disabled "euiLink-disabled")
          componentName="EuiLink"
          color=(unless @disabled color)
        }}
        disabled={{@disabled}}
        ...attributes
      >
        {{yield}}
      </button>

    {{/if}}
  {{/let}}
</template>;

export default EuiLink;
