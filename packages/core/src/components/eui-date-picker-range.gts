import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';

import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { euiDatePickerRangeStyles } from '../utils/eui/styles.generated.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import EuiFormControlLayoutDelimited from './eui-form-control-layout-delimited.gts';

const START = 'euiDatePicker euiDatePickerRange__start';
const END = 'euiDatePicker euiDatePickerRange__end';

/**
 * Two date inputs joined in one field with an arrow between them, for a
 * start and end date (upstream `EuiDatePickerRange`, built on
 * `EuiFormControlLayoutDelimited`). It only does the layout: put any date
 * input in the blocks (`EuiPikaday`, `EuiFlatpickr`, or
 * `<EuiFieldText type="date">`), rendered without their own frame
 * (`@controlOnly={{true}}`) and with the class each block yields.
 */
export interface EuiDatePickerRangeSignature {
  Element: HTMLDivElement;
  Args: {
    /** Takes the container's full width instead of 400px at most. */
    fullWidth?: boolean;
    /** Read-only look. */
    readOnly?: boolean;
    /** Shorter control (32px instead of 40px). */
    compressed?: boolean;
    /** Disabled look. Disable the inputs themselves too. */
    disabled?: boolean;
    /** Invalid look: danger outline, danger delimiter and a warning icon. */
    isInvalid?: boolean;
    /** Shows a spinner. */
    isLoading?: boolean;
    /**
     * Icon at the start: `true` (the default) shows `calendar`, `false`
     * hides it, or any `EuiIcon` type.
     */
    iconType?: boolean | string;
    /** Text between the inputs. Defaults to `'→'`. */
    delimiter?: string;
  };
  Blocks: {
    /** The start input; yields the classes to give it. */
    start: [className: string];
    /** The end input; yields the classes to give it. */
    end: [className: string];
    /** Anything else, instead of the start and end blocks. */
    default: [];
  };
}

export default class EuiDatePickerRange extends Component<EuiDatePickerRangeSignature> {
  @cached
  get classes() {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiDatePickerRangeStyles);
    return `euiDatePickerRange ${euiClass(
      context,
      { boxSizing: 'border-box' },
      styles.euiDatePickerRange
    )}`;
  }

  get icon(): string | undefined {
    const { iconType } = this.args;
    if (iconType === false) return undefined;
    if (iconType === undefined || iconType === true) return 'calendar';
    return iconType;
  }

  startClass = (inputClass: string) => `${START} ${inputClass}`;
  endClass = (inputClass: string) => `${END} ${inputClass}`;

  <template>
    <div class={{this.classes}} ...attributes>
      {{#if (has-block)}}
        {{yield}}
      {{else}}
        <EuiFormControlLayoutDelimited
          @icon={{this.icon}}
          @delimiter={{@delimiter}}
          @fullWidth={{@fullWidth}}
          @compressed={{@compressed}}
          @readOnly={{@readOnly}}
          @isDisabled={{@disabled}}
          @isInvalid={{@isInvalid}}
          @isLoading={{@isLoading}}
        >
          <:startControl as |inputClass|>
            {{yield (this.startClass inputClass) to="start"}}
          </:startControl>
          <:endControl as |inputClass|>
            {{yield (this.endClass inputClass) to="end"}}
          </:endControl>
        </EuiFormControlLayoutDelimited>
      {{/if}}
    </div>
  </template>
}
