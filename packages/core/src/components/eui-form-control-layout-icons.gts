import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';
import { on } from '@ember/modifier';

import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { euiFormControlLayoutIconsStyles } from '../utils/eui/styles.generated.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import EuiFormControlLayoutClearButton from './eui-form-control-layout-clear-button.gts';
import EuiFormControlLayoutCustomIcon from './eui-form-control-layout-custom-icon.gts';
import EuiIcon from './eui-icon.gts';
import EuiLoadingSpinner from './eui-loading-spinner.gts';
import spreadAttributes from '../-private/eui-spread-attributes.ts';

import type { EuiFormControlLayoutCustomIconSignature } from './eui-form-control-layout-custom-icon';

export const ICON_SIDES: ['left', 'right'] = ['left', 'right'];

/**
 * Upstream `IconShape`: the icon as an object, `type` plus the props of the
 * icon element. With `onClick` the icon is a button. Other keys
 * (`aria-label`, `data-test-subj`, `tabIndex`, `title`, …) become attributes.
 */
export interface EuiFormControlLayoutIconShape {
  type: EuiFormControlLayoutCustomIconSignature['Args']['type'];
  side?: (typeof ICON_SIDES)[number];
  color?: EuiFormControlLayoutCustomIconSignature['Args']['color'];
  onClick?: (event: MouseEvent) => void;
  disabled?: boolean;
  [attribute: string]: unknown;
}

/**
 * Upstream `clear` props (`EuiFormControlLayoutClearButtonProps`): the clear
 * button's `onClick`, `disabled`, `size` and attributes (`data-test-subj`,
 * `aria-label`, …).
 */
export interface EuiFormControlLayoutClearProps {
  onClick?: (event: MouseEvent) => void;
  disabled?: boolean;
  size?: 's' | 'm';
  [attribute: string]: unknown;
}

/** Upstream `isIconShape`: an object with a `type`. */
export const isIconShape = (
  icon: unknown
): icon is EuiFormControlLayoutIconShape =>
  Boolean(icon) &&
  typeof icon === 'object' &&
  Object.prototype.hasOwnProperty.call(icon, 'type');

/** The side an `@icon` sits on: an icon shape's `side` wins. */
export const iconSideOf = (
  icon: unknown,
  side: string | undefined
): 'left' | 'right' => {
  const shapeSide = isIconShape(icon) ? icon.side : undefined;

  return (shapeSide ?? side) === 'right' ? 'right' : 'left';
};

/** Icon shape keys that are not attributes. */
const ICON_SHAPE_ARGS = ['type', 'side', 'color', 'onClick', 'disabled', 'size'];

/** Clear props keys that are not attributes. */
const CLEAR_ARGS = ['onClick', 'disabled', 'size'];

export interface EuiFormControlLayoutIconsArgs {
  /** Which side of the control this group sits on. Defaults to `'left'`. */
  side?: (typeof ICON_SIDES)[number];
  /**
   * `'absolute'` overlays the control (its padding makes room);
   * `'static'` takes up space in the layout, as in EuiFormControlLayoutDelimited.
   * Defaults to `'absolute'`.
   */
  iconsPosition?: 'absolute' | 'static';
  /**
   * The icon, see EuiFormControlLayout's `@icon`: a type, or an icon shape
   * object (upstream `IconShape`).
   */
  icon?:
    | EuiFormControlLayoutCustomIconSignature['Args']['type']
    | EuiFormControlLayoutIconShape;
  /** Color of `@icon`. */
  iconColor?: EuiFormControlLayoutCustomIconSignature['Args']['color'];
  /** Extra styles composed last into `@icon`'s EuiIcon class. */
  iconCss?: EuiFormControlLayoutCustomIconSignature['Args']['iconCss'];
  /** @deprecated Use `@side`. */
  iconSide?: (typeof ICON_SIDES)[number];
  /**
   * Shows a clear button calling this function, or with these props
   * (upstream `clear`: `onClick`, `data-test-subj`, …).
   */
  clear?: ((v: any) => void) | EuiFormControlLayoutClearProps;
  /** Accessible label of the clear button. */
  clearLabel?: string;
  /** Shows a spinner. */
  isLoading?: boolean;
  /** Shows the danger warning icon. */
  isInvalid?: boolean;
  /** Shows the dropdown arrow. */
  isDropdown?: boolean;
  /** Disabled color, and disables the clear button. */
  isDisabled?: boolean;
  /** Tighter placement, for compressed controls. */
  compressed?: boolean;
}

/**
 * @private One side's icons inside EuiFormControlLayout, in upstream order:
 * clear button, spinner, invalid icon, custom icon, dropdown arrow.
 */
export interface EuiFormControlLayoutIconsSignature {
  Element: HTMLDivElement;
  Args: EuiFormControlLayoutIconsArgs;
}

export default class EuiFormControlLayoutIcons extends Component<EuiFormControlLayoutIconsSignature> {
  get side(): 'left' | 'right' {
    return (this.args.side ?? this.args.iconSide) === 'right'
      ? 'right'
      : 'left';
  }
  get iconShape(): EuiFormControlLayoutIconShape | undefined {
    return isIconShape(this.args.icon) ? this.args.icon : undefined;
  }

  get iconType(): EuiFormControlLayoutCustomIconSignature['Args']['type'] {
    return (this.iconShape?.type ??
      this.args.icon) as EuiFormControlLayoutCustomIconSignature['Args']['type'];
  }

  get iconColor() {
    return this.iconShape?.color ?? this.args.iconColor;
  }

  /** Upstream spreads the shape after `disabled={isDisabled}`. */
  get iconDisabled(): boolean | undefined {
    return this.iconShape?.disabled ?? this.args.isDisabled;
  }

  get clearProps(): EuiFormControlLayoutClearProps | undefined {
    const clear = this.args.clear;

    return clear && typeof clear === 'object' ? clear : undefined;
  }

  get clearSize(): 's' | 'm' {
    return this.clearProps?.size ?? 'm';
  }

  get clearDisabled(): boolean | undefined {
    return this.clearProps?.disabled ?? this.args.isDisabled;
  }

  onClear = (event: MouseEvent) => {
    const clear = this.args.clear;

    if (typeof clear === 'function') clear(event);
    else clear?.onClick?.(event);
  };

  iconShapeArgs = ICON_SHAPE_ARGS;
  clearArgs = CLEAR_ARGS;

  @cached
  get classes() {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(
      context,
      euiFormControlLayoutIconsStyles
    );
    const compressed = Boolean(this.args.compressed);
    const position =
      this.args.iconsPosition === 'static'
        ? [
            styles.position.static.static,
            compressed
              ? styles.position.static.compressed
              : styles.position.static.uncompressed
          ]
        : [
            styles.position.absolute.absolute,
            (compressed
              ? styles.position.absolute.compressed
              : styles.position.absolute.uncompressed)[this.side]
          ];
    return euiClass(
      context,
      { boxSizing: 'border-box' },
      styles.euiFormControlLayoutIcons,
      compressed ? styles.compressed : styles.uncompressed,
      ...position,
      this.args.isDisabled && styles.disabled
    );
  }

  <template>
    <div class="euiFormControlLayoutIcons {{this.classes}}" ...attributes>
      {{#if @clear}}
        <EuiFormControlLayoutClearButton
          @size={{this.clearSize}}
          @label={{@clearLabel}}
          disabled={{this.clearDisabled}}
          {{on "click" this.onClear}}
          {{spreadAttributes this.clearProps this.clearArgs}}
        />
      {{/if}}
      {{#if @isLoading}}
        <EuiLoadingSpinner @size="m" />
      {{/if}}
      {{#if @isInvalid}}
        <EuiIcon @size="m" @color="danger" @type="warning" />
      {{/if}}
      {{#if @icon}}
        <EuiFormControlLayoutCustomIcon
          @size="m"
          @type={{this.iconType}}
          @color={{this.iconColor}}
          @iconCss={{@iconCss}}
          @disabled={{this.iconDisabled}}
          @onClick={{this.iconShape.onClick}}
          {{spreadAttributes this.iconShape this.iconShapeArgs}}
        />
      {{/if}}
      {{#if @isDropdown}}
        <EuiFormControlLayoutCustomIcon
          @size="m"
          @type="chevronSingleDown"
          @disabled={{@isDisabled}}
        />
      {{/if}}
    </div>
  </template>
}
