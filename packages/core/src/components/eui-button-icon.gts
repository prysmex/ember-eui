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
    /**
     * The icon; anything `EuiIcon`'s `@type` accepts. An icon-only button
     * has no visible text, so always pass an `aria-label="…"` describing the
     * action.
     */
    iconType?: EuiIconSignature['Args']['type'];
    /** Size of the icon. Defaults to `'m'`. */
    iconSize?: EuiIconSignature['Args']['size'];
    /** Extra classes for the icon. */
    iconClasses?: string;
    /** Renders an `<a>` link instead of a `<button>`. */
    href?: string;
    /** `target` of the `@href` link, e.g. `'_blank'`. */
    target?: string;
    /** Disables the button and greys it out. */
    isDisabled?: boolean;
    /** For toggle buttons: sets `aria-pressed="true"` while selected. */
    isSelected?: boolean;
    /**
     * `'empty'` (just the icon), `'base'` (light background) or `'fill'`
     * (solid background). Defaults to `'empty'`.
     */
    display?: keyof typeof displayMapping;
    /**
     * `'primary'`, `'accent'`, `'success'`, `'warning'`, `'danger'`,
     * `'ghost'` or `'text'`. Defaults to `'primary'`.
     */
    color?: keyof typeof colorMapping;
    /**
     * Size of the button: `'xs'`, `'s'` or `'m'`. Defaults to the
     * `euiButtonIcon.size` config, or `'xs'`.
     */
    size?: keyof typeof sizeMapping;
    /** `type` of the `<button>`. Defaults to `'button'`. */
    type?: 'button' | 'submit' | 'reset';
    /** @deprecated Has no effect, see `EuiIcon`. */
    useSvg?: boolean;
    /** @deprecated Not needed: a component passed as `@iconType` is rendered. */
    useComponent?: boolean;
    /** Same as `@isDisabled`. */
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
