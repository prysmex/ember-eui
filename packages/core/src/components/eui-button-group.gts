import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';
import { hash } from '@ember/helper';

import { randomId } from '../-private/random-id.ts';
import screenReaderOnly from '../modifiers/screen-reader-only.ts';
import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import {
  euiButtonGroupButtonsStyles,
  euiButtonGroupStyles
} from '../utils/eui/styles.generated.ts';
import EuiButton from './eui-button.gts';
import EuiButtonEmpty from './eui-button-empty.gts';
import EuiButtonGroupButton from './eui-button-group-button.gts';
import EuiButtonIcon from './eui-button-icon.gts';

import type { EuiButtonGroupButtonSignature } from './eui-button-group-button';
import type { EuiCss } from '../utils/eui/styles.ts';
import type {
  EuiButtonContext,
  EuiButtonSelectionProps
} from '../-private/eui-button-context.ts';
import type { WithBoundArgs } from '@glint/template';

/** Upstream `BUTTON_GROUP_GUTTER_SIZES`. */
export type EuiButtonGroupGutterSize = 'none' | 'xs' | 's' | 'm' | 'l' | 'xl';

export interface Option {
  /** Disables this option. Defaults to the group's `@isDisabled`. */
  isDisabled?: boolean;
  /**
   * Beta: renders this option's disabled state with `aria-disabled`.
   * Defaults to the group's `@hasAriaDisabled`.
   */
  hasAriaDisabled?: boolean;
  /**
   * Native browser tooltip of the option. Defaults to its label; pass `''`
   * to unset it.
   */
  title?: string;
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

/** The buttons a block `EuiButtonGroup` yields, wired to the group. */
export interface EuiButtonGroupBlockParams {
  Button: WithBoundArgs<typeof EuiButton, 'buttonContext'>;
  ButtonEmpty: WithBoundArgs<typeof EuiButtonEmpty, 'buttonContext'>;
  ButtonIcon: WithBoundArgs<typeof EuiButtonIcon, 'buttonContext'>;
}

export interface EuiButtonGroupSignature {
  /** A `<fieldset>` with `@options`, a `<div role="group">` with a block. */
  Element: HTMLFieldSetElement | HTMLDivElement;
  Args: {
    /**
     * Extra styles composed last into this component's class (like upstream's
     * `css` prop). Prefer this to an extra class when styling it from a parent.
     */
    css?: EuiCss;
    /**
     * `'s'`, `'m'`, or `'compressed'` (for forms, e.g. inside an
     * `EuiFormRow` with `@display="rowCompressed"`; renders as `'s'`).
     * With a block it sets the size of every yielded button. Defaults to
     * `'s'`.
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
    /** Disables every option (with a block: every yielded button). */
    isDisabled?: boolean;
    /**
     * Beta: renders the disabled state with `aria-disabled` instead of the
     * native `disabled` attribute, so the buttons stay focusable (e.g. for
     * tooltips) while clicks and key presses are blocked.
     */
    hasAriaDisabled?: boolean;
    /**
     * `'single'`: one option selected at a time, set with `@idSelected`
     * (radio buttons). `'multi'`: each option toggles, set with
     * `@idToSelectedMap`. Also applies to `@variant="selection"` blocks.
     * Defaults to `'single'`.
     */
    type?: 'single' | 'multi';
    /**
     * Describes the group for screen readers (visually hidden legend, or
     * the `aria-label` of the `role="group"` element with a block).
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
     * Update `@idSelected` / `@idToSelectedMap` here. Required with
     * `@options`; with a block it is only called by `@variant="selection"`.
     */
    onChange?: EuiButtonGroupButtonSignature['Args']['onChange'];
    /** Id of the selected option (`@type="single"`). */
    idSelected?: Option['id'];
    /**
     * Selected state by option id, e.g. `{ bold: true, italic: false }`
     * (`@type="multi"`).
     */
    idToSelectedMap?: {
      [key: string]: EuiButtonGroupButtonSignature['Args']['isSelected'];
    };
    /**
     * The buttons: `[{ id: 'left', label: 'Left', iconType: 'editorAlignLeft' }]`.
     * Without it, the group renders its block (the yielded buttons).
     */
    options?: Array<Option>;
    /**
     * Block only. `'default'`: a row of buttons spaced by `@gutterSize`.
     * `'segmented'`: one connected, inset control (only `Button` or only
     * `ButtonIcon` children). `'selection'`: segmented toggle buttons; give
     * each one an `@id` and use `@type`, `@idSelected` /
     * `@idToSelectedMap` and `@onChange`. Defaults to `'default'`.
     */
    variant?: 'default' | 'segmented' | 'selection';
    /**
     * Block with `@variant="default"` only: gap between the buttons,
     * `'none'`, `'xs'`, `'s'`, `'m'`, `'l'` or `'xl'`. Defaults to `'s'`.
     */
    gutterSize?: EuiButtonGroupGutterSize;
    /** Segmented and selection blocks only: lines between the buttons. */
    showDividers?: boolean;
    /**
     * Segmented and selection blocks only: `'vertical'` stacks the buttons
     * (use it with `ButtonIcon` children only). Defaults to `'horizontal'`.
     */
    layout?: 'horizontal' | 'vertical';
    /**
     * Segmented and selection blocks only: `false` shrinks (truncates)
     * the buttons instead of wrapping them. Defaults to `true`.
     */
    wrap?: boolean;
    /**
     * `@variant="selection"` only: `'regular'` (subdued toggle state),
     * `'highlighted'` (filled toggle state) or `'inverse'` (light toggle
     * state on a subdued background). Defaults to `'regular'`.
     */
    display?: 'regular' | 'highlighted' | 'inverse';
  };
  Blocks: {
    /**
     * Without `@options`: the buttons, as the yielded `Button`,
     * `ButtonEmpty` and `ButtonIcon` (they inherit `@buttonSize`,
     * `@isDisabled`, `@hasAriaDisabled` and the variant's styling). They can
     * be wrapped, e.g. in `EuiToolTip` or `EuiPopover`.
     */
    default: [EuiButtonGroupBlockParams];
  };
}

/**
 * A group of buttons. With `@options`: toggle buttons picking one option or
 * several. With a block: the yielded buttons in a row, a segmented control
 * or a selection control (upstream's children API).
 */
export default class EuiButtonGroup extends Component<EuiButtonGroupSignature> {
  defaultName = randomId();

  get context() {
    return getEuiThemeContext(this);
  }
  /** Upstream renders the `options` API when `options` is passed. */
  get isOptionsMode() {
    return Boolean(this.args.options);
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

  /** Options API: `disabled` on the fieldset, or `aria-disabled` instead. */
  get fieldsetDisabled() {
    return this.args.hasAriaDisabled ? undefined : this.args.isDisabled;
  }
  get fieldsetAriaDisabled() {
    return this.args.hasAriaDisabled
      ? String(Boolean(this.args.isDisabled))
      : undefined;
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
        this.args.isFullWidth && euiButtonGroupStyles.fullWidth,
        this.args.css
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

  optionHasAriaDisabled = (option: Option): boolean | undefined =>
    option.hasAriaDisabled !== undefined
      ? option.hasAriaDisabled
      : this.args.hasAriaDisabled;

  onChange = (id: string, value?: string) => {
    this.args.onChange?.(id, value);
  };

  // Children API (a block instead of `@options`).

  get variant() {
    return this.args.variant ?? 'default';
  }
  get isSegmented() {
    return this.variant === 'segmented';
  }
  get isSelection() {
    return this.variant === 'selection';
  }
  get hasSegmentedStyle() {
    return this.isSegmented || this.isSelection;
  }
  get layout() {
    return this.args.layout ?? 'horizontal';
  }
  get display() {
    return this.args.display ?? 'regular';
  }
  get gutterSize(): EuiButtonGroupGutterSize {
    return this.args.gutterSize ?? 's';
  }
  get dataDisplay() {
    return this.isSelection ? this.display : undefined;
  }
  get dataLayout() {
    return this.hasSegmentedStyle ? this.layout : undefined;
  }
  get dataDividers() {
    return this.hasSegmentedStyle && this.args.showDividers ? 'true' : undefined;
  }
  get ariaDisabled() {
    return this.args.isDisabled ? 'true' : undefined;
  }

  @cached
  get containerClasses() {
    const context = this.context;
    const styles = useEuiBorealisStyles(context, euiButtonGroupButtonsStyles);
    return `euiButtonGroup__container ${euiClass(
      context,
      { boxSizing: 'border-box' },
      styles.euiButtonGroup__container,
      this.args.isFullWidth && this.layout !== 'vertical' && styles.fullWidth
    )}`;
  }

  @cached
  get childrenButtonsClasses() {
    const context = this.context;
    const styles = useEuiBorealisStyles(context, euiButtonGroupButtonsStyles);
    const gutterSize = this.gutterSize;
    const hasGutterSize = this.variant === 'default' && gutterSize !== 'none';
    return `euiButtonGroup__buttons ${euiClass(
      context,
      { boxSizing: 'border-box' },
      styles.euiButtonGroup__buttons,
      hasGutterSize &&
        styles.gutterSize[gutterSize as Exclude<typeof gutterSize, 'none'>],
      this.hasSegmentedStyle && this.args.wrap === false && styles.noWrap
    )}`;
  }

  /** Upstream `useEuiButtonGroupSelection`: purely controlled by the args. */
  isIdSelected = (id: string): boolean =>
    this.args.type === 'multi'
      ? Boolean(this.args.idToSelectedMap?.[id])
      : id === this.args.idSelected;

  getSelectionProps = (
    id: string,
    isDisabled?: boolean
  ): EuiButtonSelectionProps => {
    const selected = this.isIdSelected(id);
    const isInverse = this.display === 'inverse';
    const hasFill =
      (selected && this.display === 'highlighted') ||
      Boolean(selected && isDisabled);
    return {
      isSelected: selected,
      fill: isInverse ? false : hasFill,
      display: isInverse ? 'base' : hasFill ? 'fill' : undefined,
      onSelect: () => this.args.onChange?.(id)
    };
  };

  /** Upstream `EuiButtonContext` value; its getters keep the args tracked. */
  buttonContext: EuiButtonContext = createButtonContext(this);

  <template>
    {{#if this.isOptionsMode}}
      <fieldset
        class={{this.classes}}
        disabled={{this.fieldsetDisabled}}
        aria-disabled={{this.fieldsetAriaDisabled}}
        ...attributes
      >
        <legend {{screenReaderOnly}}>{{@legend}}</legend>
        <div class={{this.buttonsClasses}}>
          {{#each @options as |option|}}
            <EuiButtonGroupButton
              @name={{this.name}}
              @isDisabled={{this.optionDisabled option}}
              @hasAriaDisabled={{this.optionHasAriaDisabled option}}
              @element={{if this.typeIsSingle "label" "button"}}
              @isSelected={{this.isSelected option}}
              @color={{this.color}}
              @size={{this.buttonSize}}
              @isIconOnly={{@isIconOnly}}
              @onChange={{this.onChange}}
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
              @title={{option.title}}
              @toolTipContent={{option.toolTipContent}}
              @toolTipProps={{option.toolTipProps}}
              class={{option.className}}
              aria-label={{option.aria-label}}
            />
          {{/each}}
        </div>
      </fieldset>
    {{else}}
      <div
        class={{this.classes}}
        role="group"
        data-variant={{this.variant}}
        data-size={{this.size}}
        data-display={{this.dataDisplay}}
        data-layout={{this.dataLayout}}
        data-dividers={{this.dataDividers}}
        aria-label={{@legend}}
        aria-disabled={{this.ariaDisabled}}
        ...attributes
      >
        <div class={{this.containerClasses}}>
          <div class={{this.childrenButtonsClasses}}>
            {{yield
              (hash
                Button=(component EuiButton buttonContext=this.buttonContext)
                ButtonEmpty=(component
                  EuiButtonEmpty buttonContext=this.buttonContext
                )
                ButtonIcon=(component
                  EuiButtonIcon buttonContext=this.buttonContext
                )
              )
            }}
          </div>
        </div>
      </div>
    {{/if}}
  </template>
}

function createButtonContext(group: EuiButtonGroup): EuiButtonContext {
  return {
    get size() {
      return group.size;
    },
    get isDisabled() {
      return group.args.isDisabled ? (true as const) : undefined;
    },
    get hasAriaDisabled() {
      return group.args.hasAriaDisabled ? (true as const) : undefined;
    },
    get fullWidth() {
      return Boolean(group.args.isFullWidth);
    },
    get color() {
      return group.hasSegmentedStyle ? 'text' : undefined;
    },
    get display() {
      return group.isSegmented ? ('base' as const) : undefined;
    },
    get fill() {
      return group.isSegmented ? false : undefined;
    },
    get getSelectionProps() {
      return group.isSelection ? group.getSelectionProps : undefined;
    },
    get wrapInItem() {
      return group.hasSegmentedStyle;
    }
  };
}

/** Named export kept for compatibility. */
export { EuiButtonGroup };
