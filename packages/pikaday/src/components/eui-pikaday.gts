import Component from '@glimmer/component';
import { fn } from '@ember/helper';
import { on } from '@ember/modifier';
import { action } from '@ember/object';
import didInsert from '@ember/render-modifiers/modifiers/did-insert';
import { EuiFieldText } from '@ember-eui/core/components';
import { argOrDefault } from '@ember-eui/core/helpers';

import optional from 'ember-composable-helpers/helpers/optional';
import pikaday from 'ember-pikaday-prysmex/modifiers/pikaday';
import { and,not } from 'ember-truth-helpers';

import randomId from '../-private/random-id';

import type { EuiFieldTextSignature } from '@ember-eui/core/components/eui-field-text';

export interface EuiPikadaySignature {
  Element: EuiFieldTextSignature['Element'];
  Args: EuiFieldTextSignature['Args'] & {
    format?: string;
    value?: Date;
    yearRange?: string;
    i18n?: {
      t: (key: string) => string;
    };
    firstDay?: string;
    onClose?: () => void;
    onOpen?: () => void;
    onDraw?: () => void;
    onSelection?: (date: Date | null) => void;
    register?: (pikaday: any) => void;
    defaultDate?: Date;
    minDate?: Date;
    maxDate?: Date;
    theme?: string;
    container?: HTMLElement;
    bound?: boolean;
    moment?: any;
    isFakePrependBlock?: boolean;
    isFakeAppendBlock?: boolean;
  };
  Blocks: {
    prepend: EuiFieldTextSignature['Blocks']['prepend'];
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
    let i18n = this.args.i18n;

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
        @isFakePrependBlock={{hasPrepend}}
        @isFakeAppendBlock={{hasAppend}}
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
