import { and, eq, not, notEq, or } from 'ember-truth-helpers';

import argOrDefault from '../helpers/arg-or-default.ts';
import classNames from '../helpers/class-names.ts';
import EuiButtonContent from './eui-button-content.gts';

import type {
  colorMapping,
  flushMapping,
  sizeMapping
} from '../utils/css-mappings/eui-button-empty.ts';
import type { EuiButtonContentSignature } from './eui-button-content';
import type { EuiIconSignature } from './eui-icon';
import type { TemplateOnlyComponent } from '@ember/component/template-only';

export interface EuiButtonEmptySignature {
  Element: HTMLAnchorElement | HTMLButtonElement;
  Args: {
    /** Shows a spinner instead of the icon and disables the button. */
    isLoading?: boolean;
    /** `'xs'`, `'s'` or `'m'`. Defaults to `'m'`. */
    size?: keyof typeof sizeMapping;
    /** Size of the icon. Defaults to `'m'` (`'s'` for `@size="xs"`). */
    iconSize?: EuiButtonContentSignature['Args']['iconSize'];
    /**
     * `'primary'`, `'danger'`, `'text'`, `'ghost'`, `'warning'` or
     * `'success'`. Defaults to `'primary'`.
     */
    color?: keyof typeof colorMapping;
    /** Icon next to the text; anything `EuiIcon`'s `@type` accepts. */
    iconType?: EuiIconSignature['Args']['type'];
    /** `'right'` puts the icon after the text. Defaults to the left side. */
    iconSide?: EuiButtonContentSignature['Args']['iconSide'];
    /** Extra classes for the icon. */
    iconClasses?: string;
    /** Classes for the element wrapping the text. */
    textClasses?: string;
    /** Classes for the element wrapping the icon and text. */
    contentClasses?: string;
    /**
     * Removes the padding on `'left'`, `'right'` or `'both'` sides, to align
     * the text with content above or below it.
     */
    flush?: keyof typeof flushMapping;
    /**
     * Renders an `<a>` link instead of a `<button>` (a disabled or loading
     * button stays a `<button>`).
     */
    href?: string;
    /** `target` of the `@href` link, e.g. `'_blank'`. */
    target?: string;
    /** Disables the button and greys it out. */
    isDisabled?: boolean;
    /** @deprecated Has no effect, see `EuiIcon`. */
    useSvg?: boolean;
    /** @deprecated Not needed: a component passed as `@iconType` is rendered. */
    useComponent?: boolean;
    /** `type` of the `<button>`, e.g. `'submit'`. Defaults to `'button'`. */
    type?: string;
    /**
     * For toggle buttons: sets `aria-pressed` to `"true"` / `"false"`. Leave
     * it undefined for regular buttons.
     */
    isSelected?: boolean;
    /** Same as `@isDisabled`. */
    disabled?: boolean;
  };
  Blocks: {
    /** The button's text. */
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
          aria-pressed={{if
            (notEq @isSelected undefined)
            (if @isSelected "true" "false")
          }}
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
