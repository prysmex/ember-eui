import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';
import { fn } from '@ember/helper';
import { on } from '@ember/modifier';
import didInsert from '@ember/render-modifiers/modifiers/did-insert';

import { randomId } from '../-private/random-id.ts';
import screenReaderOnly from '../modifiers/screen-reader-only.ts';
import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { euiButtonGroupButtonStyles } from '../utils/eui/buttons-misc.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import {
  euiButtonDisplayStyles,
  euiButtonDisplaysColors,
  euiFocusRing
} from '../utils/eui/styles.generated.ts';
import EuiButtonContent from './eui-button-content.gts';
import EuiInnerText from './eui-inner-text.gts';
import EuiToolTip from './eui-tool-tip.gts';

import type { EuiButtonSignature } from './eui-button';
import type { EuiButtonContentSignature } from './eui-button-content';
import type { EuiTooltipArgs } from './eui-tool-tip';
import type { TOC } from '@ember/component/template-only';

/** Upstream `EuiButtonGroup` colors (`BUTTON_COLORS`). */
const COLORS = new Set([
  'text',
  'accent',
  'accentSecondary',
  'primary',
  'success',
  'warning',
  'danger',
  'neutral',
  'risk'
]);

export interface EuiButtonGroupButtonSignature {
  Element: EuiButtonSignature['Element'];
  Args: {
    /** Id of the option, passed to `@onChange`. */
    id: string;
    /** Value of the option, passed to `@onChange` for single selection. */
    value?: string;
    /**
     * `'label'` wraps a visually hidden radio input (single selection
     * groups), `'button'` renders a toggle button (multi selection groups).
     * Defaults to `'button'`. A disabled option always renders a button.
     */
    element?: 'label' | 'button';
    /** `name` of the radio input, shared by the group's buttons. */
    name?: string;
    /** The button's text (visually hidden with `@isIconOnly`). */
    label?: string;
    /** Disables the button. */
    isDisabled?: boolean;
    /** Whether the option is selected. */
    isSelected?: boolean;
    /** Shows only the icon; the label is kept for screen readers. */
    isIconOnly?: boolean;
    /** `'s'`, `'m'` or `'compressed'` (same height as `'s'`). */
    size?: 's' | 'm' | 'compressed';
    /** Color of the selected button, see `EuiButtonGroup`. */
    color?: string;
    /** Classes for the element wrapping the icon and text. */
    contentClasses?: string;
    /** `'right'` puts the icon after the text. */
    iconSide?: EuiButtonContentSignature['Args']['iconSide'];
    /** Icon of the button; anything `EuiIcon`'s `@type` accepts. */
    iconType?: EuiButtonContentSignature['Args']['iconType'];
    /** Size of the icon. */
    iconSize?: EuiButtonContentSignature['Args']['iconSize'];
    /** Extra classes for the icon. */
    iconClasses?: string;
    /** Shows a spinner instead of the icon. */
    isLoading?: boolean;
    /** Classes for the element wrapping the text. */
    textClasses?: string;
    /** `type` of the button (multi selection only). */
    type?: string;
    /** Tooltip text shown on hover and focus. */
    toolTipContent?: string;
    /** `EuiToolTip` options for `@toolTipContent`. */
    toolTipProps?: Pick<EuiTooltipArgs, 'position' | 'title' | 'delay'>;
    /**
     * Called with the option's `id` (and `value` for single selection) when
     * it is clicked.
     */
    onChange: (id: string, value?: string) => void;
  };
}

interface GroupButtonElementSignature {
  Element: EuiButtonGroupButtonSignature['Element'];
  Args: { button: EuiButtonGroupButton };
}

/** The option's element, rendered with or without a tooltip anchor. */
const GroupButtonElement: TOC<GroupButtonElementSignature> = <template>
  {{#let @button.args @button.inputId as |args inputId|}}
    {{#let (element @button.tagName) as |Tag|}}
      <EuiInnerText as |setInnerTextRef innerText|>
        <Tag
          class={{@button.classes}}
          disabled={{if @button.isButton args.isDisabled}}
          aria-pressed={{@button.pressed}}
          type={{@button.type}}
          for={{if @button.isButton undefined inputId}}
          id={{if @button.isButton inputId}}
          title={{innerText}}
          {{on "click" @button.onClick}}
          {{didInsert setInnerTextRef}}
          ...attributes
        >
          {{#unless @button.isButton}}
            <input
              id={{inputId}}
              name={{args.name}}
              checked={{args.isSelected}}
              value={{args.value}}
              type="radio"
              {{screenReaderOnly}}
              {{on "change" (fn args.onChange args.id args.value)}}
            />
          {{/unless}}
          <EuiButtonContent
            class={{args.contentClasses}}
            @size={{@button.size}}
            @isDisabled={{args.isDisabled}}
            @isLoading={{args.isLoading}}
            @iconType={{args.iconType}}
            @iconSide={{args.iconSide}}
            @iconSize={{args.iconSize}}
            @iconClasses={{args.iconClasses}}
            @textClasses="euiButtonGroupButton__text {{args.textClasses}}"
            @textCss={{@button.textCss}}
            @textDataText={{innerText}}
          >{{args.label}}</EuiButtonContent>
        </Tag>
      </EuiInnerText>
    {{/let}}
  {{/let}}
</template>;

/** One option of an `EuiButtonGroup`. */
export default class EuiButtonGroupButton extends Component<EuiButtonGroupButtonSignature> {
  inputId = randomId();

  get context() {
    return getEuiThemeContext(this);
  }
  get isLabel() {
    return this.args.element === 'label';
  }
  get tagName() {
    return this.isLabel && !this.args.isDisabled ? 'label' : 'button';
  }
  get isButton() {
    return this.tagName === 'button';
  }
  get size(): 's' | 'm' {
    return this.args.size === 'm' ? 'm' : 's';
  }
  get color() {
    const color = this.args.color === 'ghost' ? 'text' : this.args.color;
    return color && COLORS.has(color) ? color : 'primary';
  }
  get pressed() {
    return this.isLabel || this.args.isSelected === undefined
      ? undefined
      : String(this.args.isSelected);
  }
  get type() {
    return this.isButton ? (this.args.type ?? 'button') : undefined;
  }

  @cached
  get classes() {
    const context = this.context;
    const theme = context.upstream.euiTheme;
    const display = useEuiBorealisStyles(context, euiButtonDisplayStyles);
    const group = useEuiBorealisStyles(context, euiButtonGroupButtonStyles);
    const colors = useEuiBorealisStyles(context, euiButtonDisplaysColors);
    const { isDisabled, isSelected, isIconOnly } = this.args;
    const size = this.size;
    const color = isDisabled ? 'disabled' : this.color;
    const displayName = isSelected && color !== 'text' ? 'fill' : 'empty';
    const css = euiClass(
      context,
      // React's global reset, scoped (`border` comes from the group styles).
      {
        boxSizing: 'border-box',
        margin: 0,
        padding: 0,
        fontFamily: theme.font.family,
        textDecoration: 'none'
      },
      `&:focus { ${euiFocusRing(context.upstream)} }`,
      // A single selection option is a <label> around a hidden radio: show
      // the focus ring of the radio on the label.
      `&:has(> input:focus-visible) { outline: ${theme.focus.width} solid ${theme.focus.color}; outline-style: auto; outline-offset: 0; }`,
      display.euiButtonDisplay,
      display[size],
      isDisabled && display.isDisabled,
      group.euiButtonGroupButton,
      isIconOnly && group.iconOnly.iconOnly,
      isIconOnly && group.iconOnly[size],
      group[size],
      isSelected && color === 'text' && group.isSelected,
      isDisabled && isSelected
        ? group.disabledAndSelected
        : colors[displayName]![color]
    );
    return [
      'euiButtonGroupButton',
      isSelected && 'euiButtonGroupButton-isSelected',
      isIconOnly && 'euiButtonGroupButton-isIconOnly',
      css
    ]
      .filter(Boolean)
      .join(' ');
  }

  @cached
  get textCss() {
    const group = useEuiBorealisStyles(this.context, euiButtonGroupButtonStyles);
    return this.args.isIconOnly
      ? group.text.euiButtonGroupButton__iconOnly
      : group.text.euiButtonGroupButton__text;
  }

  @cached
  get toolTipAnchorClass() {
    const group = useEuiBorealisStyles(this.context, euiButtonGroupButtonStyles);
    return [
      'euiButtonGroup__tooltipWrapper',
      this.args.isSelected && 'euiButtonGroup__tooltipWrapper-isSelected',
      euiClass(this.context, group.tooltipWrapper)
    ]
      .filter(Boolean)
      .join(' ');
  }

  onClick = () => {
    if (!this.isLabel) this.args.onChange(this.args.id);
  };

  <template>
    {{#if @toolTipContent}}
      <EuiToolTip
        @content={{@toolTipContent}}
        @position={{@toolTipProps.position}}
        @title={{@toolTipProps.title}}
        @delay={{@toolTipProps.delay}}
        @anchorClassName={{this.toolTipAnchorClass}}
      >
        <GroupButtonElement @button={{this}} ...attributes />
      </EuiToolTip>
    {{else}}
      <GroupButtonElement @button={{this}} ...attributes />
    {{/if}}
  </template>
}
