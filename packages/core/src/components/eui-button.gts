import { concat } from '@ember/helper';
import { classify } from '@ember/string';

import { element } from 'ember-element-helper';
import { and, eq, not, or } from 'ember-truth-helpers';

import argOrDefault from '../helpers/arg-or-default.ts';
import classNames from '../helpers/class-names.ts';
import EuiButtonContent from './eui-button-content.gts';

import type { EuiButtonContentSignature } from './eui-button-content';
import type { TemplateOnlyComponent } from '@ember/component/template-only';

export interface EuiButtonSignature {
  Element: HTMLElement;
  Args: {
    /**
     * @private Class prefix, so other buttons can reuse this markup.
     * Defaults to `'euiButton'`.
     */
    baseClassName?: string;
    /**
     * `'primary'`, `'accent'`, `'success'`, `'warning'`, `'danger'`,
     * `'ghost'` (for dark backgrounds) or `'text'`. Defaults to `'primary'`.
     */
    color?: string;
    /** Classes for the element wrapping the icon and text. */
    contentClasses?: string;
    /** Same as `@isDisabled`. */
    disabled?: boolean;
    /**
     * Solid background, for the primary action of a page or form.
     * Defaults to `false` (light background).
     */
    fill?: boolean;
    /** Stretches the button to its container's width. */
    fullWidth?: boolean;
    /**
     * Renders an `<a>` link instead of a `<button>` (a disabled or loading
     * button stays a `<button>`).
     */
    href?: string;
    /** Extra classes for the icon. */
    iconClasses?: string;
    /** `'right'` puts the icon after the text. Defaults to the left side. */
    iconSide?: EuiButtonContentSignature['Args']['iconSide'];
    /** Size of the icon. Defaults to `'m'`. */
    iconSize?: EuiButtonContentSignature['Args']['iconSize'];
    /** Icon next to the text; anything `EuiIcon`'s `@type` accepts. */
    iconType?: EuiButtonContentSignature['Args']['iconType'];
    /** Shows a spinner instead of the icon and disables the button. */
    isLoading?: boolean;
    /** For toggle buttons: sets `aria-pressed="true"` while selected. */
    isSelected?: boolean;
    /** `'s'` or `'m'`. Defaults to `'m'`. */
    size?: string;
    /** `target` of the `@href` link, e.g. `'_blank'`. */
    target?: string;
    /** Classes for the element wrapping the text. */
    textClasses?: string;
    /**
     * `type` of the `<button>`, e.g. `'submit'` in a form.
     * Defaults to `'button'`.
     */
    type?: string;
    /** @deprecated Not needed: a component passed as `@iconType` is rendered. */
    useComponent?: boolean;
    /** @deprecated Has no effect, see `EuiIcon`. */
    useSvg?: boolean;
    /**
     * Tag to render, e.g. `'label'` for a file input trigger. Defaults to
     * `'a'` with `@href`, `'button'` otherwise.
     */
    element?: string;
    /** Disables the button and greys it out. */
    isDisabled?: boolean;
  };
  Blocks: {
    /** The button's text. */
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
        {{!@glint-expect-error}}
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
