import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';

import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import {
  euiDatePickerRangeInlineStyles,
  euiDatePickerRangeStyles
} from '../utils/eui/styles.generated.ts';
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
    /** Text between the inputs. Defaults to an arrow icon labelled "to". */
    delimiter?: string;
    /**
     * For two calendars displayed in the page (e.g. inline flatpickr or
     * pikaday calendars in the blocks): drops the field frame, the icon
     * and `@fullWidth`/`@compressed`, lays the blocks out side by side and
     * stacks them when the container is too narrow. Pass the inline option
     * to your calendars too.
     */
    inline?: boolean;
    /**
     * With `@inline`: tells the range that the calendars show a time list
     * (react-datepicker's `showTimeSelect`), so they stack below a wider
     * container (2 × 374px + the delimiter instead of 2 × 268px). Upstream
     * reads `showTimeSelect` from its start and end controls; blocks can't
     * be inspected, so pass it here.
     */
    showTimeSelect?: boolean;
    /** With `@inline`: a shadow around both calendars. Defaults to `true`. */
    shadow?: boolean;
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
  get shadow() {
    return this.args.shadow ?? true;
  }

  /** `@fullWidth` and `@compressed` don't apply to inline pickers. */
  get fullWidth() {
    return this.args.fullWidth && !this.args.inline;
  }

  get compressed() {
    return this.args.compressed && !this.args.inline;
  }

  @cached
  get classes() {
    const context = getEuiThemeContext(this);

    if (!this.args.inline) {
      const styles = useEuiBorealisStyles(context, euiDatePickerRangeStyles);
      return `euiDatePickerRange ${euiClass(
        context,
        { boxSizing: 'border-box' },
        styles.euiDatePickerRange
      )}`;
    }

    const inline = useEuiBorealisStyles(
      context,
      euiDatePickerRangeInlineStyles
    );
    // Upstream puts `formLayout` on the delimited layout itself, unless
    // disabled (the disabled background wins); here it is nested.
    const formLayout = this.args.disabled
      ? undefined
      : {
          '.euiFormControlLayoutDelimited': this.shadow
            ? inline.formLayout.shadow
            : inline.formLayout.noShadow
        };
    return `euiDatePickerRange ${euiClass(
      context,
      { boxSizing: 'border-box' },
      inline.euiDatePickerRangeInline,
      // Upstream: the container query depends on the time list's width.
      this.args.showTimeSelect
        ? inline.responsiveWithTimeSelect
        : inline.responsive,
      this.shadow && inline.shadow,
      formLayout
    )}`;
  }

  get icon(): string | undefined {
    if (this.args.inline) return undefined;
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
          @fullWidth={{this.fullWidth}}
          @compressed={{this.compressed}}
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
