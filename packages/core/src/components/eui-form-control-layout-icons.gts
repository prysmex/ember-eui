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

import type { EuiFormControlLayoutCustomIconSignature } from './eui-form-control-layout-custom-icon';

export const ICON_SIDES: ['left', 'right'] = ['left', 'right'];

export interface EuiFormControlLayoutIconsArgs {
  /** Which side of the control this group sits on. Defaults to `'left'`. */
  side?: (typeof ICON_SIDES)[number];
  /**
   * `'absolute'` overlays the control (its padding makes room);
   * `'static'` takes up space in the layout, as in EuiFormControlLayoutDelimited.
   * Defaults to `'absolute'`.
   */
  iconsPosition?: 'absolute' | 'static';
  /** The icon, see EuiFormControlLayout's `@icon`. */
  icon?: EuiFormControlLayoutCustomIconSignature['Args']['type'];
  /** Color of `@icon`. */
  iconColor?: EuiFormControlLayoutCustomIconSignature['Args']['color'];
  /** Extra styles composed last into `@icon`'s EuiIcon class. */
  iconCss?: EuiFormControlLayoutCustomIconSignature['Args']['iconCss'];
  /** @deprecated Use `@side`. */
  iconSide?: (typeof ICON_SIDES)[number];
  /** Shows a clear button calling this function. */
  clear?: (v: any) => void;
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
          @size="m"
          @label={{@clearLabel}}
          disabled={{@isDisabled}}
          {{on "click" @clear}}
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
          @type={{@icon}}
          @color={{@iconColor}}
          @iconCss={{@iconCss}}
          @disabled={{@isDisabled}}
        />
      {{/if}}
      {{#if @isDropdown}}
        <EuiFormControlLayoutCustomIcon
          @size="m"
          @type="arrowDown"
          @disabled={{@isDisabled}}
        />
      {{/if}}
    </div>
  </template>
}
