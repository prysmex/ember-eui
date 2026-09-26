import { and,eq, notEq, or } from 'ember-truth-helpers';

import argOrDefault from '../helpers/arg-or-default.ts';
import classNames from '../helpers/class-names.ts';
import screenReaderOnly from '../modifiers/screen-reader-only.ts';
import EuiIcon from './eui-icon.gts';

import type { TemplateOnlyComponent } from '@ember/component/template-only';

/**
 * A text link: an `<a>` with `@href`, otherwise a `<button>` styled as a
 * link (add `{{on "click" …}}`).
 */
export interface EuiLinkSignature {
  Element: HTMLAnchorElement | HTMLButtonElement;
  Args: {
    /**
     * `'primary'`, `'subdued'`, `'success'`, `'accent'`, `'danger'`,
     * `'warning'`, `'ghost'` or `'text'`. Defaults to `'primary'`.
     */
    color?: string;
    /** Disables the link. */
    disabled?: boolean;
    /**
     * Shows the external link icon. Defaults to `true` for
     * `@target="_blank"`.
     */
    external?: boolean;
    /** Where it links to; without it the link is a button. */
    href?: string;
    /**
     * `target` of the link. `'_blank'` also adds the external icon and a
     * screen reader note that it opens a new tab.
     */
    target?: string;
    /** `type` of the button (without `@href`). Defaults to `'button'`. */
    type?: string;
  };
  Blocks: {
    /** The link's text. */
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
            @aria-label="External link"
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
