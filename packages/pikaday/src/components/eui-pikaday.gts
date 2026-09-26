import Component from '@glimmer/component';
import { fn } from '@ember/helper';
import { on } from '@ember/modifier';
import { action } from '@ember/object';
import didInsert from '@ember/render-modifiers/modifiers/did-insert';
import { EuiFieldText } from '@ember-eui/core/components';
import { argOrDefault } from '@ember-eui/core/helpers';

import optional from '@nullvoxpopuli/ember-composable-helpers/helpers/optional';
import pikaday from 'ember-pikaday/modifiers/pikaday';
import { and, not } from 'ember-truth-helpers';

import randomId from '../-private/random-id.ts';

import type { EuiFieldTextSignature } from '@ember-eui/core/components/eui-field-text';

/**
 * A date input with a Pikaday calendar, styled as an EuiFieldText (its
 * args, like `@clear`, `@compressed` or `@isInvalid`, apply too). Load the
 * calendar's styles with `import '@ember-eui/pikaday/pikaday.css'`.
 */
export interface EuiPikadaySignature {
  Element: EuiFieldTextSignature['Element'];
  Args: EuiFieldTextSignature['Args'] & {
    /** moment format of the date in the input. Defaults to `'DD.MM.YYYY'`. */
    format?: string;
    /** The selected date. Update it in `@onSelection`. */
    value?: Date;
    /**
     * Years in the year dropdown: a number of years around the current one
     * (`'10'`, the default), or a range `'1990,2030'` (`'1990,currentYear'`
     * ends at this year).
     */
    yearRange?: string;
    /**
     * Translations: Pikaday's i18n object (`{ previousMonth, nextMonth,
     * months, weekdays, weekdaysShort }`), or `{ t }` with a function
     * looking these keys up (e.g. ember-intl's `t`, with comma separated
     * lists for months and weekdays).
     */
    i18n?: {
      t: (key: string) => string;
    };
    /** First day of the week, `'0'` (Sunday) to `'6'`. Defaults to `1` (Monday). */
    firstDay?: string;
    /** Called when the calendar closes. */
    onClose?: () => void;
    /** Called when the calendar opens. */
    onOpen?: () => void;
    /** Called when the calendar redraws (e.g. changing month). */
    onDraw?: () => void;
    /**
     * Called with the selected `Date`, or `null` when the input is cleared.
     * Update `@value` here.
     */
    onSelection?: (date: Date | null) => void;
    /** Called with the Pikaday instance, e.g. to call its methods. */
    register?: (pikaday: any) => void;
    /** Date shown when there is no `@value`. */
    defaultDate?: Date;
    /** Earliest selectable date. */
    minDate?: Date;
    /** Latest selectable date. */
    maxDate?: Date;
    /** Class added to the calendar, for custom themes. */
    theme?: string;
    /** Element to render the calendar in (instead of `<body>`). */
    container?: HTMLElement;
    /**
     * Positions the calendar under the input (`true`, the default) or
     * renders it inline where `@container` is.
     */
    bound?: boolean;
    /** The `moment` instance to parse and format dates with. */
    moment?: any;
    /** @private Ignore the `<:prepend>` block. */
    isFakePrependBlock?: boolean;
    /** @private Ignore the `<:append>` block. */
    isFakeAppendBlock?: boolean;
  };
  Blocks: {
    /** Content before the input; yields the class to put on it and the input id. */
    prepend: EuiFieldTextSignature['Blocks']['prepend'];
    /** Content after the input; yields the class to put on it and the input id. */
    append: EuiFieldTextSignature['Blocks']['append'];
  };
}

export default class EuiPikadayComponent extends Component<EuiPikadaySignature> {
  field: HTMLInputElement | null = null;
  pikaday?: any;

  get format() {
    return this.args.format || 'DD.MM.YYYY';
  }

  get value() {
    return this.args.value;
  }

  get yearRange() {
    const yearRange = this.args.yearRange;

    if (!yearRange) {
      return 10;
    }

    if (yearRange.indexOf(',') > -1) {
      const yearArray: (string | number)[] = yearRange.split(',');

      if (yearArray[1] === 'currentYear') {
        yearArray[1] = new Date().getFullYear();
      }

      return yearArray;
    } else {
      return yearRange;
    }
  }

  get i18n() {
    const i18n = this.args.i18n;

    if (!i18n) {
      return undefined;
    }

    if (!i18n.t) {
      return i18n;
    }

    return {
      previousMonth: i18n.t('previousMonth').toString(),
      nextMonth: i18n.t('nextMonth').toString(),
      months: i18n.t('months').toString().split(','),
      weekdays: i18n.t('weekdays').toString().split(','),
      weekdaysShort: i18n.t('weekdaysShort').toString().split(',')
    };
  }

  get firstDay() {
    return this.args.firstDay == null ? 1 : parseInt(this.args.firstDay, 10);
  }

  @action
  registerField(field: HTMLInputElement) {
    this.field = field;
  }

  @action
  registerPikaday(pikaday: any) {
    this.pikaday = pikaday;
    this.args.register?.(pikaday);
  }

  @action
  onClose() {
    if (this.isDestroying) {
      return;
    }

    if (!this.#heardValue) {
      this.onSelect(null);
    }

    this.args.onClose?.();
  }

  @action
  onOpen() {
    if (this.isDestroying) {
      return;
    }

    this.args.onOpen?.();
  }

  #heardValue?: any;

  @action
  onDraw() {
    // this is here because apparently the classic behavior is to pass no
    // arguments to the onDraw callback, but Pikaday's own ownDraw has an
    // argument.
    this.args.onDraw?.();
  }

  @action
  didChange(event: Event) {
    this.#heardValue = (event.target as HTMLInputElement).value;
  }

  @action
  onSelect(date: Date | null) {
    this.args.onSelection?.(date);
  }

  willDestroy(): void {
    super.willDestroy();

    this.field = null;
  }

  <template>
    {{#let
      (and (not (argOrDefault @isFakePrependBlock false)) (has-block "prepend"))
      (and (not (argOrDefault @isFakeAppendBlock false)) (has-block "append"))
      (argOrDefault @id (randomId))
      as |hasPrepend hasAppend inputId|
    }}
      <EuiFieldText
        @icon={{if @icon @icon "calendar"}}
        @fullWidth={{@fullWidth}}
        @isLoading={{@isLoading}}
        @readOnly={{@readOnly}}
        @inputRef={{@inputRef}}
        @controlOnly={{@controlOnly}}
        @compressed={{@compressed}}
        @id={{inputId}}
        @clear={{if @clear (fn (optional @clear) null)}}
        @isFakePrependBlock={{not hasPrepend}}
        @isFakeAppendBlock={{not hasAppend}}
        @disabled={{@disabled}}
        @isInvalid={{@isInvalid}}
        ...attributes
        {{pikaday
          value=this.value
          onSelect=this.onSelect
          setDefaultDate=true
          defaultDate=@defaultDate
          onOpen=this.onOpen
          onDraw=this.onDraw
          onClose=this.onClose
          format=this.format
          minDate=@minDate
          maxDate=@maxDate
          theme=@theme
          yearRange=this.yearRange
          i18n=this.i18n
          firstDay=this.firstDay
          container=@container
          bound=@bound
          register=this.registerPikaday
          moment=@moment
        }}
        {{on "change" this.didChange}}
        {{didInsert this.registerField}}
      >
        <:prepend as |classes inputId|>
          {{yield classes inputId to="prepend"}}
        </:prepend>
        <:append as |classes inputId|>
          {{yield classes inputId to="append"}}
        </:append>
      </EuiFieldText>
    {{/let}}
  </template>
}
