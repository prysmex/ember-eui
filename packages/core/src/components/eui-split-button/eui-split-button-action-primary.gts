import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';

import { splitButtonContext } from '../../-private/eui-split-button-context.ts';
import { getEuiThemeContext } from '../../utils/emotion/consume.ts';
import { splitButtonActionStyles } from '../../utils/eui/split-button.ts';
import EuiButton from '../eui-button.gts';
import EuiButtonIcon from '../eui-button-icon.gts';
import EuiToolTip from '../eui-tool-tip.gts';

import type { EuiCss } from '../../utils/eui/styles.ts';
import type { EuiButtonSignature } from '../eui-button';
import type { EuiToolTipSignature } from '../eui-tool-tip';

/** `EuiToolTip` arguments for an action (upstream `tooltipProps`). */
export type EuiSplitButtonTooltipProps = Partial<
  Pick<
    EuiToolTipSignature['Args'],
    'content' | 'title' | 'position' | 'delay' | 'display' | 'anchorClassName'
  >
>;

export interface EuiSplitButtonActionPrimarySignature {
  Element: EuiButtonSignature['Element'];
  Args: {
    /** Renders an `EuiButtonIcon` (pass an `aria-label`). */
    isIconOnly?: boolean;
    /** Icon; anything `EuiIcon`'s `@type` accepts. */
    iconType?: EuiButtonSignature['Args']['iconType'];
    /** `'right'` puts the icon after the text. */
    iconSide?: EuiButtonSignature['Args']['iconSide'];
    /** Size of the icon. */
    iconSize?: EuiButtonSignature['Args']['iconSize'];
    /** Disables this action (the split button's `@isDisabled` also does). */
    isDisabled?: boolean;
    /** Same as `@isDisabled`. */
    disabled?: boolean;
    /** Shows a spinner and disables this action. */
    isLoading?: boolean;
    /** For toggle buttons: sets `aria-pressed`. */
    isSelected?: boolean;
    /** Renders an `<a>` link. */
    href?: string;
    /** `target` of the `@href` link. */
    target?: string;
    /** `type` of the `<button>`. Defaults to `'button'`. */
    type?: 'button' | 'submit' | 'reset';
    /** Wraps the action in an `EuiToolTip` with these arguments. */
    tooltipProps?: EuiSplitButtonTooltipProps;
    /**
     * Extra styles composed last into this component's class (like upstream's
     * `css` prop).
     */
    css?: EuiCss;
  };
  Blocks: {
    /** The button's text. */
    default: [];
  };
}

/**
 * The main action of an `EuiSplitButton` (upstream
 * `EuiSplitButton.ActionPrimary`): an `EuiButton`, or an `EuiButtonIcon`
 * with `@isIconOnly`. Size, color and fill come from the split button.
 */
export default class EuiSplitButtonActionPrimary extends Component<EuiSplitButtonActionPrimarySignature> {
  get split() {
    return splitButtonContext(this);
  }
  get isLoading() {
    return Boolean(this.split.isLoading || this.args.isLoading);
  }
  get isDisabled() {
    return Boolean(
      this.split.isDisabled ||
        this.args.isDisabled ||
        this.args.disabled ||
        this.isLoading
    );
  }
  get buttonSize() {
    // EuiButton has no `xs`: the action is inset anyway (its height comes
    // from the split button styles).
    return this.split.size === 'm' ? 'm' : 's';
  }
  get display() {
    return this.split.fill ? 'fill' : 'base';
  }

  @cached
  get css() {
    const styles = splitButtonActionStyles(
      getEuiThemeContext(this),
      this.split.size
    );
    return [styles.euiSplitButtonActionPrimary, this.args.css];
  }

  <template>
    {{#if @tooltipProps}}
      <EuiToolTip
        @content={{@tooltipProps.content}}
        @title={{@tooltipProps.title}}
        @position={{@tooltipProps.position}}
        @delay={{@tooltipProps.delay}}
        @display={{@tooltipProps.display}}
        @anchorClassName={{@tooltipProps.anchorClassName}}
      >
        {{#if @isIconOnly}}
          <EuiButtonIcon
            class="euiSplitButtonActionPrimary"
            @size={{this.split.size}}
            @color={{this.split.color}}
            @display={{this.display}}
            @iconType={{@iconType}}
            @iconSize={{@iconSize}}
            @isDisabled={{this.isDisabled}}
            @hasAriaDisabled={{this.split.hasAriaDisabled}}
            @isLoading={{this.isLoading}}
            @isSelected={{@isSelected}}
            @href={{@href}}
            @target={{@target}}
            @type={{@type}}
            @css={{this.css}}
            ...attributes
          />
        {{else}}
          <EuiButton
            class="euiSplitButtonActionPrimary"
            @size={{this.buttonSize}}
            @color={{this.split.color}}
            @fill={{this.split.fill}}
            @iconType={{@iconType}}
            @iconSide={{@iconSide}}
            @iconSize={{@iconSize}}
            @isDisabled={{this.isDisabled}}
            @hasAriaDisabled={{this.split.hasAriaDisabled}}
            @isLoading={{this.isLoading}}
            @isSelected={{@isSelected}}
            @href={{@href}}
            @target={{@target}}
            @type={{@type}}
            @css={{this.css}}
            ...attributes
          >{{yield}}</EuiButton>
        {{/if}}
      </EuiToolTip>
    {{else if @isIconOnly}}
      <EuiButtonIcon
        class="euiSplitButtonActionPrimary"
        @size={{this.split.size}}
        @color={{this.split.color}}
        @display={{this.display}}
        @iconType={{@iconType}}
        @iconSize={{@iconSize}}
        @isDisabled={{this.isDisabled}}
        @hasAriaDisabled={{this.split.hasAriaDisabled}}
        @isLoading={{this.isLoading}}
        @isSelected={{@isSelected}}
        @href={{@href}}
        @target={{@target}}
        @type={{@type}}
        @css={{this.css}}
        ...attributes
      />
    {{else}}
      <EuiButton
        class="euiSplitButtonActionPrimary"
        @size={{this.buttonSize}}
        @color={{this.split.color}}
        @fill={{this.split.fill}}
        @iconType={{@iconType}}
        @iconSide={{@iconSide}}
        @iconSize={{@iconSize}}
        @isDisabled={{this.isDisabled}}
        @hasAriaDisabled={{this.split.hasAriaDisabled}}
        @isLoading={{this.isLoading}}
        @isSelected={{@isSelected}}
        @href={{@href}}
        @target={{@target}}
        @type={{@type}}
        @css={{this.css}}
        ...attributes
      >{{yield}}</EuiButton>
    {{/if}}
  </template>
}
