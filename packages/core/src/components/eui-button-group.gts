import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';

import { randomId } from '../-private/random-id.ts';
import screenReaderOnly from '../modifiers/screen-reader-only.ts';
import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import {
  euiButtonGroupButtonsStyles,
  euiButtonGroupStyles
} from '../utils/eui/styles.generated.ts';
import EuiButtonGroupButton from './eui-button-group-button.gts';

import type { EuiButtonGroupButtonSignature } from './eui-button-group-button';

export interface Option {
  /** Disables this option. Defaults to the group's `@isDisabled`. */
  isDisabled?: boolean;
  /** Icon of the option; required for `@isIconOnly` groups. */
  iconType?: EuiButtonGroupButtonSignature['Args']['iconType'];
  /** Value passed to `@onChange` (single selection only). */
  value?: EuiButtonGroupButtonSignature['Args']['value'];
  /**
   * Text of the option. Always set it: with `@isIconOnly` it is hidden but
   * read by screen readers.
   */
  label?: EuiButtonGroupButtonSignature['Args']['label'];
  /** Unique id of the option, used by `@idSelected` / `@idToSelectedMap`. */
  id: EuiButtonGroupButtonSignature['Args']['id'];
  /** Shows a spinner instead of the icon. */
  isLoading?: EuiButtonGroupButtonSignature['Args']['isLoading'];
  /** `'right'` puts the icon after the text. */
  iconSide?: EuiButtonGroupButtonSignature['Args']['iconSide'];
  /** Size of the icon. */
  iconSize?: EuiButtonGroupButtonSignature['Args']['iconSize'];
  /** Classes for the element wrapping the text. */
  textClasses?: EuiButtonGroupButtonSignature['Args']['textClasses'];
  /** Classes for the element wrapping the icon and text. */
  contentClasses?: EuiButtonGroupButtonSignature['Args']['contentClasses'];
  /** Extra classes for the icon. */
  iconClasses?: EuiButtonGroupButtonSignature['Args']['iconClasses'];
  /** `type` of the button (multi selection only). */
  type?: EuiButtonGroupButtonSignature['Args']['type'];
  /** Class for the option's button. */
  className?: string;
  /** Accessible label of the option's button. */
  'aria-label'?: string;
  /** Tooltip text shown on hover and focus of the option. */
  toolTipContent?: EuiButtonGroupButtonSignature['Args']['toolTipContent'];
  /** `EuiToolTip` `position`, `title` and `delay` for `toolTipContent`. */
  toolTipProps?: EuiButtonGroupButtonSignature['Args']['toolTipProps'];
}

export interface EuiButtonGroupSignature {
  Element: HTMLFieldSetElement;
  Args: {
    /**
     * `'s'`, `'m'`, or `'compressed'` (for forms, e.g. inside an
     * `EuiFormRow` with `@display="rowCompressed"`). Defaults to `'s'`.
     */
    buttonSize?: 's' | 'm' | 'compressed';
    /**
     * Color of the selected buttons: `'text'`, `'primary'`, `'accent'`,
     * `'accentSecondary'`, `'success'`, `'warning'`, `'danger'`,
     * `'neutral'` or `'risk'`. `'ghost'` is still accepted and renders as
     * `'text'` (latest EUI dropped it). Defaults to `'text'`.
     */
    color?:
      | 'text'
      | 'primary'
      | 'accent'
      | 'accentSecondary'
      | 'success'
      | 'warning'
      | 'danger'
      | 'neutral'
      | 'risk'
      | 'ghost';
    /** Stretches the group, and its buttons evenly, to its container's width. */
    isFullWidth?: boolean;
    /** Disables every option. */
    isDisabled?: boolean;
    /**
     * `'single'`: one option selected at a time, set with `@idSelected`
     * (radio buttons). `'multi'`: each option toggles, set with
     * `@idToSelectedMap`. Defaults to `'single'`.
     */
    type?: 'single' | 'multi';
    /**
     * Describes the group for screen readers (visually hidden legend).
     * Required for accessibility.
     */
    legend?: string;
    /** `name` of the radio inputs (single selection). Defaults to a random id. */
    name?: string;
    /** Extra class(es) for the fieldset. */
    className?: string;
    /** Shows only the options' icons; their labels stay for screen readers. */
    isIconOnly?: EuiButtonGroupButtonSignature['Args']['isIconOnly'];
    /**
     * Called with the clicked option's `id` (and its `value` for `'single'`).
     * Update `@idSelected` / `@idToSelectedMap` here.
     */
    onChange: EuiButtonGroupButtonSignature['Args']['onChange'];
    /** Id of the selected option (`@type="single"`). */
    idSelected?: Option['id'];
    /**
     * Selected state by option id, e.g. `{ bold: true, italic: false }`
     * (`@type="multi"`).
     */
    idToSelectedMap?: {
      [key: string]: EuiButtonGroupButtonSignature['Args']['isSelected'];
    };
    /** The buttons: `[{ id: 'left', label: 'Left', iconType: 'editorAlignLeft' }]`. */
    options?: Array<Option>;
  };
}

/** A group of toggle buttons: one selected option, or several. */
export default class EuiButtonGroup extends Component<EuiButtonGroupSignature> {
  defaultName = randomId();

  get context() {
    return getEuiThemeContext(this);
  }
  get buttonSize() {
    return this.args.buttonSize ?? 's';
  }
  get size(): 's' | 'm' {
    return this.buttonSize === 'm' ? 'm' : 's';
  }
  get color() {
    const color = this.args.color ?? 'text';
    // Compressed ghost groups were always text; latest EUI has no ghost.
    return color === 'ghost' ? 'text' : color;
  }
  get typeIsSingle() {
    return (this.args.type ?? 'single') === 'single';
  }
  get name() {
    return this.args.name ?? this.defaultName;
  }

  @cached
  get classes() {
    const context = this.context;
    return [
      'euiButtonGroup',
      this.args.isDisabled && 'euiButtonGroup-isDisabled',
      this.args.className,
      euiClass(
        context,
        // React's global reset for <fieldset>.
        {
          boxSizing: 'border-box',
          margin: 0,
          padding: 0,
          border: 'none',
          minInlineSize: 'auto'
        },
        euiButtonGroupStyles.euiButtonGroup,
        this.args.isFullWidth && euiButtonGroupStyles.fullWidth
      )
    ]
      .filter(Boolean)
      .join(' ');
  }

  @cached
  get buttonsClasses() {
    const context = this.context;
    const styles = useEuiBorealisStyles(context, euiButtonGroupButtonsStyles);
    return `euiButtonGroup__buttons ${euiClass(
      context,
      { boxSizing: 'border-box' },
      styles.euiButtonGroup__buttons,
      this.args.isFullWidth && styles.fullWidth,
      styles.size[this.size]
    )}`;
  }

  isSelected = (option: Option): boolean | undefined =>
    this.typeIsSingle
      ? option.id === this.args.idSelected
      : this.args.idToSelectedMap?.[option.id];

  optionDisabled = (option: Option): boolean | undefined =>
    option.isDisabled !== undefined ? option.isDisabled : this.args.isDisabled;

  <template>
    <fieldset
      class={{this.classes}}
      disabled={{@isDisabled}}
      ...attributes
    >
      <legend {{screenReaderOnly}}>{{@legend}}</legend>
      <div class={{this.buttonsClasses}}>
        {{#each @options as |option|}}
          <EuiButtonGroupButton
            @name={{this.name}}
            @isDisabled={{this.optionDisabled option}}
            @element={{if this.typeIsSingle "label" "button"}}
            @isSelected={{this.isSelected option}}
            @color={{this.color}}
            @size={{this.buttonSize}}
            @isIconOnly={{@isIconOnly}}
            @onChange={{@onChange}}
            @iconType={{option.iconType}}
            @value={{option.value}}
            @label={{option.label}}
            @id={{option.id}}
            @isLoading={{option.isLoading}}
            @iconSide={{option.iconSide}}
            @iconSize={{option.iconSize}}
            @textClasses={{option.textClasses}}
            @contentClasses={{option.contentClasses}}
            @iconClasses={{option.iconClasses}}
            @type={{option.type}}
            @toolTipContent={{option.toolTipContent}}
            @toolTipProps={{option.toolTipProps}}
            class={{option.className}}
            aria-label={{option.aria-label}}
          />
        {{/each}}
      </div>
    </fieldset>
  </template>
}

/** Named export kept for compatibility. */
export { EuiButtonGroup };
