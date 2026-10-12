import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';

import { splitButtonContext } from '../../-private/eui-split-button-context.ts';
import { getEuiThemeContext } from '../../utils/emotion/consume.ts';
import { splitButtonActionStyles } from '../../utils/eui/split-button.ts';
import EuiButtonIcon from '../eui-button-icon.gts';
import EuiPopover from '../eui-popover.gts';
import EuiToolTip from '../eui-tool-tip.gts';

import type { EuiCss } from '../../utils/eui/styles.ts';
import type { EuiButtonIconSignature } from '../eui-button-icon';
import type { EuiPopoverArgs } from '../eui-popover';
import type { EuiSplitButtonTooltipProps } from './eui-split-button-action-primary';

/** `EuiPopover` arguments for the secondary action (upstream `popoverProps`). */
export type EuiSplitButtonPopoverProps = Pick<EuiPopoverArgs, 'closePopover'> &
  Partial<
    Pick<
      EuiPopoverArgs,
      | 'isOpen'
      | 'anchorPosition'
      | 'panelPaddingSize'
      | 'ownFocus'
      | 'display'
      | 'hasArrow'
      | 'initialFocus'
      | 'ariaLabel'
      | 'ariaLabelledBy'
      | 'repositionOnScroll'
      | 'panelCss'
    >
  >;

export interface EuiSplitButtonActionSecondarySignature {
  Element: HTMLButtonElement | HTMLAnchorElement;
  Args: {
    /**
     * Icon; anything `EuiIcon`'s `@type` accepts. Always `chevronSingleDown`
     * with `@popoverProps`. Pass an `aria-label` describing the action.
     */
    iconType?: EuiButtonIconSignature['Args']['iconType'];
    /** Size of the icon. */
    iconSize?: EuiButtonIconSignature['Args']['iconSize'];
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
     * Anchors an `EuiPopover` to the action with these arguments (default
     * `anchorPosition`: `'downCenter'`); the block is its content.
     */
    popoverProps?: EuiSplitButtonPopoverProps;
    /**
     * Extra styles composed last into this component's class (like upstream's
     * `css` prop).
     */
    css?: EuiCss;
  };
  Blocks: {
    /** The popover content (with `@popoverProps`). */
    default: [];
  };
}

/**
 * The secondary icon action of an `EuiSplitButton` (upstream
 * `EuiSplitButton.ActionSecondary`), optionally opening a popover. The
 * divider before it is rendered here.
 */
export default class EuiSplitButtonActionSecondary extends Component<EuiSplitButtonActionSecondarySignature> {
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
  get display() {
    return this.split.fill ? 'fill' : 'base';
  }
  get iconType() {
    return this.args.popoverProps ? 'chevronSingleDown' : this.args.iconType;
  }

  @cached
  get css() {
    const styles = splitButtonActionStyles(
      getEuiThemeContext(this),
      this.split.size
    );
    return [styles.euiSplitButtonActionSecondary, this.args.css];
  }

  <template>
    {{#if this.split.dividerClass}}
      <div class={{this.split.dividerClass}} aria-hidden="true"></div>
    {{/if}}
    {{#if @popoverProps}}
      <EuiPopover
        @isOpen={{@popoverProps.isOpen}}
        @closePopover={{@popoverProps.closePopover}}
        @anchorPosition={{if
          @popoverProps.anchorPosition
          @popoverProps.anchorPosition
          "downCenter"
        }}
        @panelPaddingSize={{@popoverProps.panelPaddingSize}}
        @ownFocus={{@popoverProps.ownFocus}}
        @display={{@popoverProps.display}}
        @hasArrow={{@popoverProps.hasArrow}}
        @initialFocus={{@popoverProps.initialFocus}}
        @ariaLabel={{@popoverProps.ariaLabel}}
        @ariaLabelledBy={{@popoverProps.ariaLabelledBy}}
        @repositionOnScroll={{@popoverProps.repositionOnScroll}}
        @panelCss={{@popoverProps.panelCss}}
      >
        <:button>
          {{#if @tooltipProps}}
            <EuiToolTip
              @content={{@tooltipProps.content}}
              @title={{@tooltipProps.title}}
              @position={{@tooltipProps.position}}
              @delay={{@tooltipProps.delay}}
              @display={{@tooltipProps.display}}
              @anchorClassName={{@tooltipProps.anchorClassName}}
            >
              <EuiButtonIcon
                class="euiSplitButtonActionSecondary"
                @size={{this.split.size}}
                @color={{this.split.color}}
                @display={{this.display}}
                @iconType={{this.iconType}}
                @iconSize={{@iconSize}}
                @isDisabled={{this.isDisabled}}
                @isLoading={{this.isLoading}}
                @isSelected={{@isSelected}}
                @href={{@href}}
                @target={{@target}}
                @type={{@type}}
                @css={{this.css}}
                ...attributes
              />
            </EuiToolTip>
          {{else}}
            <EuiButtonIcon
              class="euiSplitButtonActionSecondary"
              @size={{this.split.size}}
              @color={{this.split.color}}
              @display={{this.display}}
              @iconType={{this.iconType}}
              @iconSize={{@iconSize}}
              @isDisabled={{this.isDisabled}}
              @isLoading={{this.isLoading}}
              @isSelected={{@isSelected}}
              @href={{@href}}
              @target={{@target}}
              @type={{@type}}
              @css={{this.css}}
              ...attributes
            />
          {{/if}}
        </:button>
        <:content>{{yield}}</:content>
      </EuiPopover>
    {{else if @tooltipProps}}
      <EuiToolTip
        @content={{@tooltipProps.content}}
        @title={{@tooltipProps.title}}
        @position={{@tooltipProps.position}}
        @delay={{@tooltipProps.delay}}
        @display={{@tooltipProps.display}}
        @anchorClassName={{@tooltipProps.anchorClassName}}
      >
        <EuiButtonIcon
          class="euiSplitButtonActionSecondary"
          @size={{this.split.size}}
          @color={{this.split.color}}
          @display={{this.display}}
          @iconType={{this.iconType}}
          @iconSize={{@iconSize}}
          @isDisabled={{this.isDisabled}}
          @isLoading={{this.isLoading}}
          @isSelected={{@isSelected}}
          @href={{@href}}
          @target={{@target}}
          @type={{@type}}
          @css={{this.css}}
          ...attributes
        />
      </EuiToolTip>
    {{else}}
      <EuiButtonIcon
        class="euiSplitButtonActionSecondary"
        @size={{this.split.size}}
        @color={{this.split.color}}
        @display={{this.display}}
        @iconType={{this.iconType}}
        @iconSize={{@iconSize}}
        @isDisabled={{this.isDisabled}}
        @isLoading={{this.isLoading}}
        @isSelected={{@isSelected}}
        @href={{@href}}
        @target={{@target}}
        @type={{@type}}
        @css={{this.css}}
        ...attributes
      />
    {{/if}}
  </template>
}
