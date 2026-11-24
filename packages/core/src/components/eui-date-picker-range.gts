import Component from '@glimmer/component';
import { cached, tracked } from '@glimmer/tracking';
import { schedule } from '@ember/runloop';

import { provide } from 'ember-provide-consume-context';

import { EUI_DATE_PICKER_RANGE_CONTEXT } from '../-private/eui-date-picker-range-context.ts';
import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import {
  euiDatePickerRangeInlineStyles,
  euiDatePickerRangeStyles
} from '../utils/eui/styles.generated.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import EuiFormControlLayoutDelimited from './eui-form-control-layout-delimited.gts';

import type { EuiDatePickerRangeContext } from '../-private/eui-date-picker-range-context.ts';

const START = 'euiDatePicker euiDatePickerRange__start';
const END = 'euiDatePicker euiDatePickerRange__end';

/**
 * Two date inputs joined in one field with an arrow between them, for a
 * start and end date (upstream `EuiDatePickerRange`, built on
 * `EuiFormControlLayoutDelimited`). An `EuiDatePicker` in the `<:start>`
 * or `<:end>` block takes the range's states by itself, as upstream's
 * `startDateControl` and `endDateControl`: no frame of its own, no icon,
 * `@inline`, `@compressed`, `@fullWidth`, `@readOnly`, `@disabled` and
 * `@isInvalid`, and the end opens its calendar `downRight`. Any other date
 * input works too (`EuiFlatpickr`, `EuiPikaday`,
 * `<EuiFieldText type="date">`): render it with `@controlOnly={{true}}`
 * and the class its block yields.
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
    /**
     * Side of `@iconType`: `'left'` (default) or `'right'`. Applies only
     * to an icon type, not to the default `calendar` (`@iconType={{true}}`).
     */
    iconSide?: 'left' | 'right';
    /**
     * Custom controls: the `<:start>` / `<:end>` blocks yield only the
     * delimited input class, without the date picker range classes, and an
     * `EuiDatePicker` in them takes nothing from the range (upstream
     * doesn't add its props to the controls).
     */
    isCustom?: boolean;
    /** Text between the inputs. Defaults to an arrow icon labelled "to". */
    delimiter?: string;
    /**
     * Two calendars displayed in the page: drops the field frame, the icon
     * and `@fullWidth`/`@compressed`, lays the blocks out side by side and
     * stacks them when the container is too narrow. An `EuiDatePicker` in
     * a block becomes inline by itself; pass the inline option to other
     * calendars (`EuiFlatpickr`, `EuiPikaday`).
     */
    inline?: boolean;
    /**
     * With `@inline`: the calendars show a time list, so they stack below
     * a wider container (2 × 374px + the delimiter instead of 2 × 268px).
     * An `EuiDatePicker` with `@showTimeSelect` tells the range by itself,
     * as upstream reads it from its controls; pass it for other calendars.
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
    /**
     * Content before the inputs, e.g. an `EuiFormLabel` (upstream
     * `prepend`); yields the class to put on it. Not rendered `@inline`.
     */
    prepend: [className: string];
    /**
     * Content after the inputs (upstream `append`); yields the class to put
     * on it. Not rendered `@inline`.
     */
    append: [className: string];
    /** Anything else, instead of the start and end blocks. */
    default: [];
  };
}

/**
 * Provides the range context to the pickers of one block (DESIGN 4.5).
 * Renders nothing of its own.
 */
class EuiDatePickerRangeSide extends Component<{
  Args: { range: EuiDatePickerRange; side: 'start' | 'end' };
  Blocks: { default: [] };
}> {
  @provide(EUI_DATE_PICKER_RANGE_CONTEXT)
  get rangeContext(): EuiDatePickerRangeContext {
    const { range, side } = this.args;
    return {
      side,
      controlOnly: true,
      showIcon: false,
      get inline() {
        return Boolean(range.args.inline);
      },
      get compressed() {
        return Boolean(range.compressed);
      },
      get fullWidth() {
        return Boolean(range.fullWidth);
      },
      get readOnly() {
        return Boolean(range.args.readOnly);
      },
      get disabled() {
        return Boolean(range.args.disabled);
      },
      get isInvalid() {
        return Boolean(range.args.isInvalid);
      },
      reportTimeSelect: range.reportTimeSelect
    };
  }

  <template>{{yield}}</template>
}

export default class EuiDatePickerRange extends Component<EuiDatePickerRangeSignature> {
  /** The pickers in the blocks that show a time list (DESIGN 4.5). */
  private timeSelectPickers = new Set<object>();
  @tracked private timeSelectCount = 0;

  /**
   * A picker's `showTimeSelect`, reported while it renders: the count the
   * classes read is written after the render, never during it.
   */
  reportTimeSelect = (picker: object, showTimeSelect: boolean) => {
    if (showTimeSelect === this.timeSelectPickers.has(picker)) return;
    if (showTimeSelect) this.timeSelectPickers.add(picker);
    else this.timeSelectPickers.delete(picker);
    schedule('afterRender', () => {
      if (this.isDestroying || this.isDestroyed) return;
      const count = this.timeSelectPickers.size;
      if (count !== this.timeSelectCount) this.timeSelectCount = count;
    });
  };

  /** `@showTimeSelect`, or a picker in a block with a time list. */
  get showTimeSelect(): boolean {
    return Boolean(this.args.showTimeSelect) || this.timeSelectCount > 0;
  }

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
      this.showTimeSelect ? inline.responsiveWithTimeSelect : inline.responsive,
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

  /** Upstream passes `icon.side` only for an icon type, not the default calendar. */
  get iconSide(): 'left' | 'right' | undefined {
    const { iconType } = this.args;
    return typeof iconType === 'string' ? this.args.iconSide : undefined;
  }

  startClass = (inputClass: string) =>
    this.args.isCustom ? inputClass : `${START} ${inputClass}`;
  endClass = (inputClass: string) =>
    this.args.isCustom ? inputClass : `${END} ${inputClass}`;

  /** Upstream drops `prepend` and `append` from inline pickers. */
  sideProvided = (hasBlock: boolean) => hasBlock && !this.args.inline;

  <template>
    <div class={{this.classes}} ...attributes>
      {{#if (has-block)}}
        {{yield}}
      {{else}}
        <EuiFormControlLayoutDelimited
          @icon={{this.icon}}
          @iconSide={{this.iconSide}}
          @delimiter={{@delimiter}}
          @fullWidth={{this.fullWidth}}
          @compressed={{this.compressed}}
          @readOnly={{@readOnly}}
          @isDisabled={{@disabled}}
          @isInvalid={{@isInvalid}}
          @isLoading={{@isLoading}}
          @isPrependProvided={{this.sideProvided (has-block "prepend")}}
          @isAppendProvided={{this.sideProvided (has-block "append")}}
        >
          <:prepend as |prependClass|>
            {{yield prependClass to="prepend"}}
          </:prepend>
          <:startControl as |inputClass|>
            {{#if @isCustom}}
              {{yield (this.startClass inputClass) to="start"}}
            {{else}}
              <EuiDatePickerRangeSide @range={{this}} @side="start">
                {{yield (this.startClass inputClass) to="start"}}
              </EuiDatePickerRangeSide>
            {{/if}}
          </:startControl>
          <:endControl as |inputClass|>
            {{#if @isCustom}}
              {{yield (this.endClass inputClass) to="end"}}
            {{else}}
              <EuiDatePickerRangeSide @range={{this}} @side="end">
                {{yield (this.endClass inputClass) to="end"}}
              </EuiDatePickerRangeSide>
            {{/if}}
          </:endControl>
          <:append as |appendClass|>
            {{yield appendClass to="append"}}
          </:append>
        </EuiFormControlLayoutDelimited>
      {{/if}}
    </div>
  </template>
}
