import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';

import { getEuiThemeContext } from '../../utils/emotion/consume.ts';
import { euiDatePickerRangeStyles } from '../../utils/eui/styles.generated.ts';
import { euiClass, useEuiBorealisStyles } from '../../utils/eui/styles.ts';
import EuiFormControlLayoutDelimited from '../eui-form-control-layout-delimited.gts';

import type { EuiCss } from '../../utils/eui/styles.ts';
import type { EuiFormControlLayoutSignature } from '../eui-form-control-layout';

/**
 * @private EuiSuperDatePicker's range: upstream `EuiDatePickerRange` with
 * `isCustom` (the controls are rendered as given), i.e. a wrapper around
 * `EuiFormControlLayoutDelimited`.
 */
export interface EuiDatePickerRangeSignature {
  Element: HTMLDivElement;
  Args: {
    /** Stretches to the container's width. */
    fullWidth?: boolean;
    /** Read-only styling. */
    readOnly?: boolean;
    /** Invalid styling (danger outline and warning icon). */
    isInvalid?: boolean;
    /** Disabled styling. */
    disabled?: boolean;
    /** Shorter control. */
    compressed?: boolean;
    /** Shows a spinner. */
    isLoading?: boolean;
    /** Icon of the control. */
    icon?: string;
    /** Side of `@icon` (upstream `iconSide`). Defaults to `'left'`. */
    iconSide?: 'left' | 'right';
    /**
     * Renders the `<:append>` block. Defaults to `true`; the picker passes
     * the block always and switches it here, so the range (and the quick
     * select popover in it) is not remounted.
     */
    isAppendProvided?: boolean;
    /** Text between the controls. Defaults to `'→'`. */
    delimiter?: string;
    /** Extra class(es). */
    className?: string;
    /** Extra styles composed last onto the wrapper's class. */
    css?: EuiCss;
  };
  Blocks: {
    /** Content before the controls (always rendered, like upstream's quick select). */
    prepend: EuiFormControlLayoutSignature['Blocks']['prepend'];
    startDateControl: [];
    endDateControl: [];
    /** Content after the controls (upstream `append`). */
    append: EuiFormControlLayoutSignature['Blocks']['append'];
  };
}

export default class EuiDatePickerRange extends Component<EuiDatePickerRangeSignature> {
  /**
   * Upstream composes the caller's `css` (passed as a class) before the
   * range's own styles.
   */
  @cached
  get classes() {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiDatePickerRangeStyles);
    return [
      'euiDatePickerRange',
      this.args.className,
      euiClass(
        context,
        { boxSizing: 'border-box' },
        this.args.css,
        styles.euiDatePickerRange
      )
    ]
      .filter(Boolean)
      .join(' ');
  }

  <template>
    <div class={{this.classes}} ...attributes>
      <EuiFormControlLayoutDelimited
        @icon={{@icon}}
        @iconSide={{@iconSide}}
        @isAppendProvided={{if (has-block "append") @isAppendProvided false}}
        @delimiter={{@delimiter}}
        @fullWidth={{@fullWidth}}
        @compressed={{@compressed}}
        @readOnly={{@readOnly}}
        @isDisabled={{@disabled}}
        @isInvalid={{@isInvalid}}
        @isLoading={{@isLoading}}
      >
        <:prepend as |classes|>
          {{yield classes to="prepend"}}
        </:prepend>
        <:startControl>
          {{yield to="startDateControl"}}
        </:startControl>
        <:endControl>
          {{yield to="endDateControl"}}
        </:endControl>
        <:append as |classes|>
          {{yield classes to="append"}}
        </:append>
      </EuiFormControlLayoutDelimited>
    </div>
  </template>
}
