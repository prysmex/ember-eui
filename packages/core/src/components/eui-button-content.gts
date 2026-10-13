import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';

import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import {
  euiButtonDisplayContentStyles,
  euiTextTruncate
} from '../utils/eui/styles.generated.ts';
import euiApplyProps from '../-private/eui-apply-props.ts';
import EuiIcon from './eui-icon.gts';
import EuiLoadingSpinner from './eui-loading-spinner.gts';

import type { EuiElementProps } from '../-private/eui-apply-props.ts';
import type { EuiCss } from '../utils/eui/styles.ts';
import type { EuiIconSignature } from './eui-icon';
import type { EuiLoadingSpinnerSignature } from './eui-loading-spinner';

export interface EuiButtonContentSignature {
  Element: HTMLSpanElement;
  Args: {
    /** `'right'` puts the icon after the text. Defaults to the left side. */
    iconSide?: 'left' | 'right';
    /** Replaces the icon with a loading spinner. */
    isLoading?: boolean;
    /** Icon before (or after) the text; anything `EuiIcon`'s `@type` accepts. */
    iconType?: EuiIconSignature['Args']['type'];
    /** Size of the icon (and spinner). Defaults to `'m'`. */
    iconSize?: EuiIconSignature['Args']['size'];
    /** Extra classes for the icon. */
    iconClasses?: string;
    /** @deprecated Has no effect, see `EuiIcon`. */
    useSvg?: boolean;
    /** @deprecated Not needed: a component passed as `@iconType` is rendered. */
    useComponent?: boolean;
    /** Classes for the element wrapping the text. */
    textClasses?: string;
    /**
     * HTML attributes for the element wrapping the text (upstream's
     * `textProps`); `class`/`className`/`css` are handled by the owner.
     */
    textProps?: EuiElementProps | false;
    /**
     * Button size (`'xs'`, `'s'` or `'m'`). When set, the content styles
     * itself with upstream `EuiButtonDisplayContent` styles: a centered flex
     * row with an `xs` gap, the icon placed after the text for
     * `@iconSide="right"`, and a padded, truncated text wrapper. Without it
     * the caller styles the content (legacy contract of `EuiButton` and
     * `EuiButtonEmpty`, which pass their own classes).
     */
    size?: 'xs' | 's' | 'm';
    /**
     * The owning button is disabled: like upstream, the loading spinner then
     * takes the text color (`border: currentcolor`). Only used with `@size`.
     */
    isDisabled?: boolean;
    /** Extra styles composed last into the text wrapper's class (`@size` only). */
    textCss?: EuiCss;
    /** `data-text` of the text wrapper, for `euiTextShift` (`@size` only). */
    textDataText?: string;
  };
  Blocks: {
    /** The button's text. */
    default: [];
  };
}

const DISABLED_SPINNER: EuiLoadingSpinnerSignature['Args']['color'] = {
  border: 'currentcolor'
};

/**
 * The icon/spinner and text of a button: upstream
 * `EuiButtonDisplayContent`.
 */
export default class EuiButtonContent extends Component<EuiButtonContentSignature> {
  get styled() {
    return this.args.size !== undefined;
  }
  get iconSize() {
    return this.args.iconSize ?? 'm';
  }
  get spinnerSize(): EuiLoadingSpinnerSignature['Args']['size'] {
    const size = this.iconSize;
    return size === 's' ||
      size === 'm' ||
      size === 'l' ||
      size === 'xl' ||
      size === 'xxl'
      ? size
      : 'm';
  }
  get iconAfter() {
    return this.styled && this.args.iconSide === 'right';
  }
  get spinnerColor() {
    return this.styled && this.args.isDisabled ? DISABLED_SPINNER : undefined;
  }
  @cached
  get classes() {
    if (!this.styled) return 'euiButtonContent';
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiButtonDisplayContentStyles);
    return `euiButtonContent ${euiClass(
      context,
      { boxSizing: 'border-box' },
      styles.euiButtonDisplayContent
    )}`;
  }
  @cached
  get textClasses() {
    if (!this.styled) return this.args.textClasses;
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiButtonDisplayContentStyles);
    const size = this.args.size ?? 'm';
    return [
      'eui-textTruncate',
      this.args.textClasses,
      euiClass(
        context,
        styles.content[size] ?? styles.content.m,
        euiTextTruncate(),
        this.args.textCss
      )
    ]
      .filter(Boolean)
      .join(' ');
  }

  <template>
    <span class={{this.classes}} ...attributes>
      {{#unless this.iconAfter}}
        {{#if @isLoading}}
          <EuiLoadingSpinner
            class="euiButtonContent__spinner"
            @size={{this.spinnerSize}}
            @color={{this.spinnerColor}}
          />
        {{else if @iconType}}
          <EuiIcon
            @iconClasses="euiButtonContent__icon {{@iconClasses}}"
            @type={{@iconType}}
            @size={{this.iconSize}}
            @useSvg={{@useSvg}}
            @useComponent={{@useComponent}}
            @color="inherit"
          />
        {{/if}}
      {{/unless}}
      <span
        class={{this.textClasses}}
        data-text={{@textDataText}}
        {{euiApplyProps @textProps}}
      >{{yield}}</span>
      {{#if this.iconAfter}}
        {{#if @isLoading}}
          <EuiLoadingSpinner
            class="euiButtonContent__spinner"
            @size={{this.spinnerSize}}
            @color={{this.spinnerColor}}
          />
        {{else if @iconType}}
          <EuiIcon
            @iconClasses="euiButtonContent__icon {{@iconClasses}}"
            @type={{@iconType}}
            @size={{this.iconSize}}
            @useSvg={{@useSvg}}
            @useComponent={{@useComponent}}
            @color="inherit"
          />
        {{/if}}
      {{/if}}
    </span>
  </template>
}
